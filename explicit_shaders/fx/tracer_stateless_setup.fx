#include "fx/tracer_core.fxh"
#include "fx/tracer_memexport.fxh"
#include "fx/tracer_function_evaluation.fxh"


#if !defined(pc) || (DX_VERSION == 11)
// Take the index from the vertex input semantic and translate it into the actual lookup 
// index in the vertex buffer.
int ProfileIndexToBufferIndex(int profileIndex)
{
	int tracerRow = round(profileIndex / k_profilesPerRow);
	int profileIndexWithinRow = floor((profileIndex + 0.5) % k_profilesPerRow);
	int bufferRow = vs_tracerStrip.row[tracerRow];
	
	return bufferRow * k_profilesPerRow + profileIndexWithinRow;
}

void TracerMain(TracerVertex input)
{
	TracerProfileState state;
	
	// Lame non-stateless fields
	state.velocity = float3(0.0f, 0.0f, 0.0f);
	state.lifespan = 0.0f;
	state.age = 0.0f;
	state.initialColor = float4(1.0f, 1.0f, 1.0f, 1.0f);
	state.initialAlpha = 1.0f;
	state.random = float4(0.0f, 0.0f, 0.0f, 0.0f);

	state.percentile = (input.index == vs_tracerOverallState.numProfiles - 1)
		? 1.0f
		: input.index * vs_tracerOverallState.percentileStep;
		
	state.length = state.percentile * vs_tracerOverallState.cappedLength;
			
	float preevaluatedScalar[eTP_count] = PreevaluateTracerFunctions(state);

	// Update pos
	state.position = vs_tracerOverallState.origin + vs_tracerOverallState.direction * (vs_tracerOverallState.offset + vs_tracerOverallState.cappedLength * state.percentile);
	state.offset = TracerMapToVector2dRange(eTP_profileOffset, preevaluatedScalar[eTP_profileOffset]);

	// Compute color (will be clamped [0,1] and compressed to 8-bit upon export)
	state.color.xyz = TracerMapToColorRange(eTP_profileColor, preevaluatedScalar[eTP_profileColor]);
	state.color.w = preevaluatedScalar[eTP_profileAlpha] * preevaluatedScalar[eTP_profileAlpha2];
		
	// Update rotation (only stored as [0,1], and "frac" is necessary to avoid clamping)
	state.rotation = frac(preevaluatedScalar[eTP_profileRotation]);
	
	// Compute misc fields (better to do once here than multiple times in render)
	state.size = preevaluatedScalar[eTP_profileSize];
	state.offset = TracerMapToVector2dRange(eTP_profileOffset, preevaluatedScalar[eTP_profileOffset]);
	state.intensity = preevaluatedScalar[eTP_profileIntensity];
	state.blackPoint = frac(preevaluatedScalar[eTP_profileBlackPoint]);
	state.palette = frac(preevaluatedScalar[eTP_profilePalette]);

	// return 
	WriteTracerProfileState(state, ProfileIndexToBufferIndex(input.index));
}
#endif	// !defined(pc)

// For EDRAM method, the main work must go in the pixel shader, since only 
// pixel shaders can write to EDRAM.
// For the MemExport method, we don't need a pixel shader at all.
// This is signalled by a "void" return type or "multipass" config?

#if DX_VERSION == 11

[numthreads(CS_TRACER_UPDATE_THREADS,1,1)]
void DefaultCS(uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + cs_tracer_index_range.x;
	if (index < cs_tracer_index_range.y)
	{
		TracerVertex input;
		input.index = index;
		input.address.x = 0;
		input.address.y = 0;
		
		TracerMain(input);	
	}
}

#elif defined(pc)
float4 DefaultVS(TracerVertex IN) : SV_Position
{
	return float4(1, 2, 3, 4);
}
#else
void DefaultVS(TracerVertex IN)
{
	TracerMain(IN);
}
#endif

// Should never be executed
float4 DefaultPS() : SV_Target0
{
	return float4(0,1,2,3);
}

BEGIN_TECHNIQUE
{
	pass tracer
	{
#if DX_VERSION == 11
		SET_COMPUTE_SHADER(DefaultCS());
#else
		SET_VERTEX_SHADER(DefaultVS());
		SET_PIXEL_SHADER(DefaultPS());
#endif
	}
}