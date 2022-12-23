#include "fx/tracer_core.fxh"
#include "fx/tracer_memexport.fxh"
#include "fx/tracer_function_evaluation.fxh"


#if !defined(pc) || (DX_VERSION == 11)
void TracerMain(TracerVertex input)
{
	TracerProfileState state;

	state = ReadTracerProfileState(input.index);

	float preevaluatedScalar[eTP_count] = PreevaluateTracerFunctions(state);
		
	if (state.age < 1.0f)
	{
		// Update timer
		state.age += vs_deltaTime / state.lifespan;

		// Update pos
		state.position.xyz += (state.velocity.xyz * vs_deltaTime) + vs_tracerOverallState.localSpaceOffset_gameTime.xyz;

		// Update velocity
		state.velocity +=
			TracerMapToVector3dRange(eTP_profileSelfAcceleration, preevaluatedScalar[eTP_profileSelfAcceleration]) *
			vs_deltaTime;
		
		// Update rotation (only stored as [0,1], and "frac" is necessary to avoid clamping)
		state.rotation = frac(preevaluatedScalar[eTP_profileRotation]);
		
		// Compute color (will be clamped [0,1] and compressed to 8-bit upon export)
		state.color.xyz = TracerMapToColorRange(eTP_profileColor, preevaluatedScalar[eTP_profileColor]);
		state.color.w = preevaluatedScalar[eTP_profileAlpha] * preevaluatedScalar[eTP_profileAlpha2];
			
		// Compute misc fields (better to do once here than multiple times in render)
		state.size = preevaluatedScalar[eTP_profileSize];
		state.offset = TracerMapToVector2dRange(eTP_profileOffset, preevaluatedScalar[eTP_profileOffset]);
		state.intensity = preevaluatedScalar[eTP_profileIntensity];
		state.blackPoint = frac(preevaluatedScalar[eTP_profileBlackPoint]);
		state.palette = frac(preevaluatedScalar[eTP_profilePalette]);
		
		state.percentile = (input.index == vs_tracerOverallState.numProfiles - 1) 
			? 1.0f 
			: input.index * vs_tracerOverallState.percentileStep;	
	}

	// return 
	WriteTracerProfileState(state, input.index);
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
		uint address = cs_tracer_address_buffer[index];

		TracerVertex input;
		input.index = index;
		input.address.x = address & 0xffff;
		input.address.y = address >> 16;
		
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