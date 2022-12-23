#if !defined(__ENTRYPOINTS_LIGHT_VOLUME_FXH)
#define __ENTRYPOINTS_LIGHT_VOLUME_FXH

#include "core/core_vertex_types.fxh"

#include "depth_fade.fxh"

// BEGIN LARGELY UNCHANGED BUNGIE STUFF

#if !defined(LIGHT_VOLUME_3D_TEXTURE)

LightVolumeInterpolatedValues DoSomeBungieStuff(in LightVolumeVertex input)
{
	LightVolumeInterpolatedValues outValues;
#if (! defined(pc)) || (DX_VERSION == 11)
	// Break the input index into a prim index and a vert index within the primitive.
	int2 indexAndOffset = int2(round(input.index / 4), round(input.index % 4));
	indexAndOffset.x = ProfileIndexToBufferIndex(indexAndOffset.x);
	ProfileMemexportedState state = ReadProfileMemexportedState(indexAndOffset.x);
	
	// Compute some useful quantities
	float3 cameraToProfile = normalize(state.position - vs_view_camera_position);
	float sinViewAngle = length(cross(vs_lightVolumeOverallState.direction, normalize(cameraToProfile)));
	
	// Profiles have aspect ratio 1 from head-on, but not from the side
	float profileLength = lerp(state.thickness, vs_lightVolumeOverallState.profileLength, sinViewAngle);
	
	// Compute the vertex position within the plane of the sprite
	float4x2 shift = {{0.0f, 0.0f}, {1.0f, 0.0f}, {1.0f, 1.0f}, {0.0f, 1.0f}, };
	float2 billboardPos = (shift[indexAndOffset.y] * 1.0f - 0.5f) * float2(profileLength, state.thickness);
	
	// Transform from profile space to world space. 
	// Basis is facing camera, but rotated based on light volume direction
	float2x3 billboardBasis;
	billboardBasis[1] = safe_normalize(cross(cameraToProfile, vs_lightVolumeOverallState.direction));
	billboardBasis[0] = cross(cameraToProfile, billboardBasis[1]);
	float3 worldPos = state.position + mul(billboardPos, billboardBasis);
	
	// Transform from world space to clip space. 
	outValues.position = mul(float4(worldPos, 1.0f), vs_view_view_projection_matrix);
	
	// Compute vertex texcoord
	outValues.texcoord = float2(1.0f, 1.0f) - shift[indexAndOffset.y];

	// Compute profile color
	outValues.color = state.color * state.intensity;
	
	// Total intensity at a pixel should be approximately the same from all angles and any profile density.
	// Reduce alpha by the expected overdraw factor.
	float spacing = vs_lightVolumeOverallState.profileDistance * sinViewAngle;
	float overdraw = min(vs_lightVolumeOverallState.numProfiles, profileLength / spacing);
	outValues.color.a *= lerp(vs_lightVolumeOverallState.brightnessRatio, 1.0f, sinViewAngle) / overdraw;
	
	float depth = dot(vs_view_camera_backward, vs_view_camera_position - worldPos.xyz);
	outValues.depth = depth;
	
	outValues.screenCoord = (outValues.position.xy / outValues.position.w) * float2(0.5, -0.5) + float2(0.5, 0.5);
	
#else //#ifndef pc
	// Doesn't work on PC!!!  (This just makes it compile.)
	outValues.position = float4(0.0f, 0.0f, 0.0f, 1.0f);
	outValues.color = float4(0.0f, 0.0f, 0.0f, 0.0f);// Doesn't work on PC!!!  (This just makes it compile.)
	outValues.depth = 0.0f;
	outValues.texcoord = float3(0.0f, 0.0f, 0.0f);
	outValues.screenCoord = float2(0.0f, 0.0f);
#endif //#ifndef pc

    return outValues;
}
// END BUNGIE STUFF

void DefaultLightVolumeVS(
#if DX_VERSION == 11
	in uint instance_id : SV_InstanceID,
	in uint vertex_id : SV_VertexID,
#else
	in LightVolumeVertex input,
#endif
	out LightVolumeInterpolatorsInternal outInterpolators)
{
#if DX_VERSION == 11
	uint quad_index = (vertex_id ^ ((vertex_id & 2) >> 1));
	
	LightVolumeVertex input;
	input.index = (instance_id * 4) + quad_index;
	input.address = 0;	
#endif

	LightVolumeInterpolatedValues lightVolumeValues = DoSomeBungieStuff(input);
	
	lightVolumeValues.color.rgb *= vs_bungie_additive_scale_and_exposure.y;

  outInterpolators = WriteLightVolumeInterpolators(lightVolumeValues);
}

#else // !defined(LIGHT_VOLUME_3D_TEXTURE)

LightVolumeInterpolatedValues Compute3DFXVolumeValues(in LightVolumeVertex input)
{
	LightVolumeInterpolatedValues outValues;
#if (! defined(pc)) || (DX_VERSION == 11)
	// Break the input index into a prim index and a vert index within the primitive.
	int2 indexAndOffset = int2(round(input.index / 4), round(input.index % 4));
	indexAndOffset.x = ProfileIndexToBufferIndex(indexAndOffset.x);
	ProfileMemexportedState state = ReadProfileMemexportedState(indexAndOffset.x);

	// Get our camera's incident vector
	float3 cameraToVolume = normalize(vs_lightVolumeOverallState.origin - vs_view_camera_position);

	// x is along cameraToVolume, y is left, z is up
	float3 maxDimensions = float3(1.44225, 1.44225, 1.44225); // cubed root of 3

	// compute the profile's center position
	float3 profileCenterPosition = vs_lightVolumeOverallState.origin + (state.percentile - 0.5) * cameraToVolume * maxDimensions.x;

	// Compute the vertex position within the plane of the sprite
	float4x2 shift = {{0.0f, 0.0f}, {1.0f, 0.0f}, {1.0f, 1.0f}, {0.0f, 1.0f}, };
	float2 billboardPos = (shift[indexAndOffset.y] * 1.0f - 0.5f) * maxDimensions.yz;
	
	// Transform from profile space to world space. 
	// Basis is facing camera, but rotated based on light volume direction
	float2x3 billboardBasis;
	billboardBasis[1] = safe_normalize(cross(cameraToVolume, vs_lightVolumeOverallState.direction));
	billboardBasis[0] = cross(cameraToVolume, billboardBasis[1]);
	float3 worldPos = profileCenterPosition + mul(billboardPos, billboardBasis);
	
	// Transform from world space to clip space. 
	outValues.position = mul(float4(worldPos, 1.0f), vs_view_view_projection_matrix);

	// Compute vertex texcoord
	float3 relativePos = worldPos - vs_lightVolumeOverallState.origin;

	float3x3 volumeBasis;
	volumeBasis[0] = vs_lightVolumeOverallState.direction;
	volumeBasis[1] = safe_normalize(cross(volumeBasis[0], abs(volumeBasis[0].z < .99f) ? float3(0, 0, 1) : float3(0, 1, 0)));
	volumeBasis[2] = cross(volumeBasis[1], volumeBasis[0]);

	float3 volumeCoord = mul(relativePos, volumeBasis) + float3(0.5, 0.5, 0.5);
	outValues.texcoord = volumeCoord.yz;
	outValues.volumeTexcoordZ = volumeCoord.x;

	// Compute profile color
	outValues.color = state.color * state.intensity;
	
	// Total intensity at a pixel should be approximately the same from all angles and any profile density.
	// Reduce alpha by the expected overdraw factor.
	outValues.color.a /= vs_lightVolumeOverallState.numProfiles;
	
	float depth = dot(vs_view_camera_backward, vs_view_camera_position - worldPos.xyz);
	outValues.depth = depth;
	
	outValues.screenCoord = (outValues.position.xy / outValues.position.w) * float2(0.5, -0.5) + float2(0.5, 0.5);
	
#else //#ifndef pc
	// Doesn't work on PC!!!  (This just makes it compile.)
	outValues.position = float4(0.0f, 0.0f, 0.0f, 1.0f);
	outValues.color = float4(0.0f, 0.0f, 0.0f, 0.0f);// Doesn't work on PC!!!  (This just makes it compile.)
	outValues.depth = 0.0f;
	outValues.texcoord = float2(0.0f, 0.0f);
	outValues.volumeTexcoordZ = 0.0f;
	outValues.screenCoord = float2(0.0f, 0.0f);
#endif //#ifndef pc

    return outValues;
}
// END BUNGIE STUFF

void DefaultLightVolumeVS(
#if DX_VERSION == 11
	in uint instance_id : SV_InstanceID,
	in uint vertex_id : SV_VertexID,
#else
	in LightVolumeVertex input,
#endif
	out LightVolumeInterpolatorsInternal outInterpolators)
{
#if DX_VERSION == 11
	uint quad_index = (vertex_id ^ ((vertex_id & 2) >> 1));
	
	LightVolumeVertex input;
	input.index = (instance_id * 4) + quad_index;
	input.address = 0;	
#endif

	LightVolumeInterpolatedValues lightVolumeValues = Compute3DFXVolumeValues(input);
	
	lightVolumeValues.color = vs_apply_exposure(lightVolumeValues.color);

    outInterpolators = WriteLightVolumeInterpolators(lightVolumeValues);
}

#endif // !defined(LIGHT_VOLUME_3D_TEXTURE)

void DefaultDefaultPS(
	in LightVolumeInterpolatorsInternal inInterpolators,
	SCREEN_POSITION_INPUT(fragment_position),
	out float4 outColor: SV_Target0)
{
	LightVolumeInterpolatedValues lightVolumeValues = ReadLightVolumeInterpolators(inInterpolators);
	outColor = PixelComputeColor(lightVolumeValues);
	
	fragment_position.xy += ps_tiling_vpos_offset.xy;

	[branch]
	if (DepthFadeRange > 0.0f)
	{
		outColor.a *= ComputeDepthFade(fragment_position * psDepthConstants.z, lightVolumeValues.depth);
	}
	
	outColor = ps_apply_exposure(outColor, lightVolumeValues.color, float3(0, 0, 0), 0);
}

#endif 	// !defined(__ENTRYPOINTS_LIGHT_VOLUME_FXH)