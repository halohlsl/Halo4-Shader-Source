#if !defined(__ENTRYPOINTS_TRACER_FXH)
#define __ENTRYPOINTS_TRACER_FXH

#include "core/core_vertex_types.fxh"

#if defined(xenon) || (DX_VERSION == 11)

// BEGIN LARGELY UNCHANGED BUNGIE STUFF

// Match with TracerDefinition::_profileShape
// enum ProfileShape
#define ePS_ribbon 0
#define ePS_cross 1
#define ePS_ngon 2
#define ePS_horizontal 3
#define ePS_vertical 4
#define ePS_count 5

// Match with TracerDefinition::_appearanceFlag
// enum AppearanceFlag
#define eAF_tintFromLightmap 0
#define eAF_doubleSided 1
#define eAF_profileOpacityFromScaleA 2
#define eAF_randomUOffset 3
#define eAF_randomVOffset 4
#define eAF_canBeLowRes 5
#define eAF_originFaded 6
#define eAF_edgeFaded 7
#define eAF_fogged 8
#define eAF_angleFaded 9
#define eAF_count 10

// Take the index from the vertex input semantic and translate it into the actual lookup 
// index in the vertex buffer.
int ProfileIndexToBufferIndex(int profileIndex)
{
	int tracerRow = round(profileIndex / k_profilesPerRow);
	int profileIndexWithinRow = floor((profileIndex + 0.5) % k_profilesPerRow);
	int bufferRow = vs_tracerStrip.row[tracerRow];
	
	return bufferRow * k_profilesPerRow + profileIndexWithinRow;
}

// Take the index from the vertex input semantic and translate it into strip, index, and offset.
void CalcStripProfileAndOffset(in int index, out int stripIndex, out int bufferIndex, out int offset)
{
	float vertsPerStrip = vs_tracerOverallState.numProfiles * 2;
	stripIndex = floor((index + 0.5f) / vertsPerStrip);
	float indexWithinStrip = index - stripIndex * vertsPerStrip;
	bufferIndex = floor((indexWithinStrip + 0.5f) / 2);
	offset = indexWithinStrip - bufferIndex * 2;
	
	if (vs_tracerOverallState.profileShape == ePS_vertical)
	{
		stripIndex = 1; // pretend it's actually the second strip in this case
	}
}

float2 StripAndOffsetToCrossSectionalOffset(int stripIndex, int offset)
{
	if (vs_tracerOverallState.profileShape != ePS_ngon)
	{
		static float2x2 shift[2]= {{{-0.5f, 0.0f}, {0.5f, 0.0f}, }, {{0.0f, -0.5f}, {0.0f, 0.5f}, }, };
		return shift[stripIndex][offset];
	}
	else //if (vs_tracerOverallState.profileShape== ePS_ngon)
	{
		float radians = (2 * pi) * (stripIndex + offset) / vs_tracerOverallState.ngonSides;
		return 0.5f * float2(cos(radians), -sin(radians));	// the '-' causes inward-facing sides to be backface-culled.
	}
}

// Calculate the direction of the tracer at the profile by sampling the position of 
// a neighboring profile.
float3 ProfileDirection(int profileIndex, float3 position)
{
	bool offTheEnd = (profileIndex >= vs_tracerOverallState.numProfiles - 1);
	int nextProfileIndex = profileIndex + (offTheEnd ? -1 : 1);
	TracerProfileState state = VSReadTracerProfileState(ProfileIndexToBufferIndex(nextProfileIndex));
	
	return (offTheEnd ? -1.0f : 1.0f) * (state.position - position);
}

// Plane perpendicular to tracer with basis[0] horizontal in world space.
float2x3 CrossSectionWorldBasis (float3 direction)
{
	float2x3 basis;
	
	static float3 up = {0.0f, 0.0f, 1.0f};
	basis[0] = safe_normalize(cross(direction, up));
	basis[1] = safe_normalize(cross(basis[0], direction));
	
	return basis;
}

// Plane perpendicular to tracer with basis[0] parallel to screen.
float2x3 CrossSectionBillboardBasis (float3 position, float3 direction)
{
	float2x3 basis;

	basis[0] = safe_normalize(cross(position - vs_view_camera_position, direction));
	basis[1] = safe_normalize(cross(basis[0], direction));
	
	return basis;
}

float2 ProfileOffsetToTexcoord(int stripIndex, int offset, float cumulativeLength)
{
	float v_shift; // number from -0.5f to 0.5f ranging across/around the cross-section
	if (vs_tracerOverallState.profileShape != ePS_ngon)
	{
		v_shift = offset - 0.5f;
	}
	else //if (vs_tracerOverallState.profileShape == ePS_ngon)
	{
		v_shift = (stripIndex + offset) / vs_tracerOverallState.ngonSides - 0.5f;
	}
	return float2(cumulativeLength, v_shift) * vs_tracerOverallState.uvTilingRate +
		float2(0.0f, 0.5f) +
		vs_tracerOverallState.localSpaceOffset_gameTime.w * vs_tracerOverallState.uvScrollRate +
		vs_tracerOverallState.uvOffset;
}

TracerInterpolatedValues DoSomeBungieStuff(in TracerVertex input)
{
	TracerInterpolatedValues outValues;
	// Break the input index into a strip index, a profile index and an {0,1}-offset.
	int stripIndex, profileIndex, offset;
	CalcStripProfileAndOffset(input.index, stripIndex, profileIndex, offset);
	TracerProfileState state = VSReadTracerProfileState(ProfileIndexToBufferIndex(profileIndex));
	
	// Kill timed-outValues profiles...
	// Should be using oPts.z kill, but that's hard to do in hlsl.  
	// XDS says equivalent to set position to NaN?
	if (state.age >= 1.0f)
	{
		outValues.position = vs_hiddenFromCompilerNaN.xxxx;
		outValues.texcoord = float2(0.0f, 0.0f);
		outValues.blackPoint = 0.0f;
		outValues.palette = 0.0f;
		outValues.color = float4(0.0f, 0.0f, 0.0f, 0.0f);
		
#if defined(RENDER_DISTORTION)
		outValues.tangent = float3(0.0f, 0.0f, 0.0f);
		outValues.binormal = float3(0.0f, 0.0f, 0.0f);
		outValues.depth = 0.0f;
#elif defined(TRACER_DEPTH)
		outValues.depth = 0.0f;
#endif
	}
	else
	{
		// Compute the direction by sampling the position of the next profile (!)
		float3 direction = ProfileDirection(profileIndex, state.position);
		
		// Compute the vertex position within the cross-sectional plane of the profile
		float2 crossSectionPos = StripAndOffsetToCrossSectionalOffset(stripIndex, offset) * state.size;
			
		// Transform from cross-section plane to world space.
		float2x3 worldBasis = CrossSectionWorldBasis(direction);
		float2x3 billboardBasis = (vs_tracerOverallState.profileShape == ePS_ribbon) ? CrossSectionBillboardBasis(state.position, direction) : worldBasis;
		float rotation = state.rotation;
		float rotSin, rotCos;
		sincos((2 * pi) * rotation, rotSin, rotCos);
		float2x2 rotMat = {{rotCos, rotSin}, {-rotSin, rotCos}, };
		billboardBasis = mul(rotMat, billboardBasis);
		float3 worldPos = state.position + mul(crossSectionPos, billboardBasis) + mul(state.offset, worldBasis);
		
		// Transform from world space to clip space. 
		outValues.position= mul(float4(worldPos, 1.0f), vs_view_view_projection_matrix);
		
#if defined(RENDER_DISTORTION)
		outValues.tangent = billboardBasis[0]; // corresponds to direction of increasing u
		outValues.binormal = billboardBasis[1]; // corresponds to direction of increasing v
		outValues.depth= dot(vs_view_camera_backward, vs_view_camera_position - worldPos);
#elif defined(TRACER_DEPTH)
		outValues.depth= dot(vs_view_camera_backward, vs_view_camera_position - worldPos);
#endif
		
		// Compute vertex texcoord
		outValues.texcoord= ProfileOffsetToTexcoord(stripIndex, offset, state.length);

		// Compute profile color
		outValues.color = state.color * state.intensity;
		outValues.color.xyz *= state.initialColor.xyz * exp2(state.initialColor.w);
		outValues.color.w *= state.initialAlpha;

		if (TEST_BIT(vs_tracerOverallState.appearanceFlags, eAF_originFaded))
		{
			outValues.color.w *= saturate(vs_tracerOverallState.fade.originRange * 
				(state.length - vs_tracerOverallState.fade.originCutoff));
		}
		if (TEST_BIT(vs_tracerOverallState.appearanceFlags, eAF_edgeFaded))
		{
			// Fade to transparent when profile plane is parallel to screen plane
			float3 profileNormal = safe_normalize(cross(billboardBasis[0], billboardBasis[1]));
			float profileAngle = acos(abs(dot(-vs_view_camera_backward, profileNormal)));
			outValues.color.w *= saturate(vs_tracerOverallState.fade.edgeRange * (profileAngle - vs_tracerOverallState.fade.edgeCutoff));
		}

		// Compute profile black point
		outValues.blackPoint = state.blackPoint;
		outValues.palette = state.palette;
	}

	return outValues;
}

// END BUNGIE STUFF

void DefaultTracerVS(
#if DX_VERSION == 11
	in uint raw_index : SV_VertexID,
	in uint instance_index : SV_InstanceID,
#else
	in TracerVertex input,
#endif
	out TracerInterpolatorsInternal outInterpolators)
{
#if DX_VERSION == 11
	TracerVertex input;
	input.index = (instance_index * uint(vs_tracerOverallState.numProfiles) * 2) + raw_index;
	input.address = 0;
#endif

	TracerInterpolatedValues tracerValues = DoSomeBungieStuff(input);
	
	tracerValues.color = vs_apply_exposure(tracerValues.color);

    outInterpolators = WriteTracerInterpolators(tracerValues);
}

void DefaultDefaultPS(
	in TracerInterpolatorsInternal inInterpolators,
	out float4 outColor: SV_Target0
#if defined(TRACER_DEPTH) || (DX_VERSION == 11)
	, SCREEN_POSITION_INPUT(fragment_position)
#endif
	)
{
	TracerInterpolatedValues tracerValues = ReadTracerInterpolators(inInterpolators);
	
#if defined(RENDER_DISTORTION)
	float2 displacement = PixelComputeDisplacement(tracerValues);
	
	displacement.y = -displacement.y;
	displacement *= psDistortionScreenConstants.z * tracerValues.color.a;

	float2x2 billboardBasis = float2x2(tracerValues.tangent.xy, tracerValues.binormal.xy);
	float2 frameDisplacement = mul(billboardBasis, displacement) / tracerValues.depth;
	
	// At this point, displacement is in units of frame widths/heights.  I don't think pixel kill gains anything here.
	// We now require pixel kill for correctness, because we don't use depth test.
	clip(dot(frameDisplacement, frameDisplacement) == 0.0f ? -1 : 1);

	// Now use full positive range of render target [0.0,32.0)
	float2 distortion = DistortionStrength * frameDisplacement;
	
	outColor = float4(distortion * psDistortionScreenConstants, 1.0f, 1.0f);
#else // defined(RENDER_DISTORTION)

#if defined(TRACER_DEPTH)
	outColor = PixelComputeColor(tracerValues, fragment_position);
#else
	outColor = PixelComputeColor(tracerValues);
#endif

	[branch]
	if (tracerValues.blackPoint > 0.0f)
	{
		const float whitePoint = 1.0f;
		outColor.a = ApplyBlackPointAndWhitePoint(tracerValues.blackPoint, whitePoint, outColor.a);
	}
	
	outColor = ps_apply_exposure(outColor, tracerValues.color, float3(0, 0, 0), 0);
#endif // defined(RENDER_DISTORTION)
}

#else // defined(xenon)

float4 DefaultTracerVS() : SV_Position0
{
	return float4(0, 0, 0, 1);
}

float4 DefaultDefaultPS() : SV_Target0
{
	return float4(0, 0, 0, 0);
}

#endif // defined(xenon)

#endif 	// !defined(__ENTRYPOINTS_TRACER_FXH)