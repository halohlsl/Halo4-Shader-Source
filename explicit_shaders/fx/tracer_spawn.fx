#include "fx/tracer_core.fxh"
#include "fx/tracer_memexport.fxh"
#include "fx/tracer_function_evaluation.fxh"

#if !defined(pc)

float4 TracerMain(TracerVertex input) : SV_Position
{
	TracerProfileState state = ReadTracerProfileState(input.index);
	int outIndex = input.address.x + input.address.y * k_profilesPerRow;
	WriteTracerProfileState(state, outIndex);
	return 0;
}

#elif DX_VERSION == 11

[numthreads(CS_TRACER_SPAWN_THREADS,1,1)]
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
		
		TracerProfileState state = UnpackTracerProfileState(cs_tracer_profile_state_spawn_buffer[input.index]);
		
		int outIndex = input.address.x + input.address.y * k_profilesPerRow;
		WriteTracerProfileState(state, outIndex);
	}
}

#elif defined(pc)

float4 DefaultVS(TracerVertex input) : SV_Position
{
	return float4(1, 2, 3, 4);
}

#else

void DefaultVS(TracerVertex input)
{
	TracerMain(input);
}

#endif

// Should never be executed
float4 DefaultPS( void ) :SV_Target0
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