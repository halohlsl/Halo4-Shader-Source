#if !defined(__TRACER_MEMEXPORT_FXH)
#define __TRACER_MEMEXPORT_FXH


// I don't want to stick those defines in tracer_memexport_parameters.fxh, so I do them before the includes

#include "fx/bonobo_function_types.fxh"
#include "fx/tracer_memexport_parameters.fxh"
#include "fx/bonobo_function_evaluation.fxh"

#if defined(xenon)

// The including file must define the strideOffset and streamConstant registers.
void WriteTracerProfileState(TracerProfileState state, int index)
{
	static float4 streamHelper = {0, 1, 0, 0};
	float4 export[eMS_count];

	// This code basically compiles away, since it's absorbed into the
	// compiler's register mapping.
	export[eMS_pos] = float4(state.position, state.age);
	export[eMS_vel] = float4(state.velocity, state.initialAlpha);
	export[eMS_rnd] = float4(state.random);
	export[eMS_misc4x16f] = float4(state.size, state.intensity, state.offset);
	export[eMS_misc4x16un] = float4(state.rotation, state.blackPoint, state.palette, state.percentile);
	export[eMS_misc2x16f] = float4(state.length, state.lifespan, 0.0f, 0.0f);
	export[eMS_col] = float4(state.color);
	export[eMS_col2] = float4(state.initialColor);

    // Store result.  Some of these writes are not needed by all clients
    // (eg. rnd should only be written by spawn, not update).
    for (int state = 0; state < eMS_count; ++state)
    {
		int stateIndex = index * vs_memexportProperties[state].strideOffset.x + vs_memexportProperties[state].strideOffset.y;
		float4 streamConstant = vs_memexportProperties[state].streamConstant;
		float4 export = export[state];
		asm {
		alloc export=1
			mad eA, stateIndex, streamHelper, streamConstant
			mov eM0, export
		};
    }
}

#elif DX_VERSION == 11

void WriteTracerProfileState(TracerProfileState state, int index)
{
	cs_tracer_profile_state_buffer[index] = PackTracerProfileState(state);
}

#endif

#endif 	// !defined(__TRACER_MEMEXPORT_FXH)