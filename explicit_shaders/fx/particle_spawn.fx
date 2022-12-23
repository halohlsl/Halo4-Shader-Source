#include "core/core.fxh"
#include "fx/particle_types.fxh"
#include "fx/particle_memexport.fxh"
#include "fx/particle_index_registers.fxh"

#if DX_VERSION == 9

void default_vs()
{
}

float4 default_ps() : SV_Target
{
	return 0;
}

#elif DX_VERSION == 11

[numthreads(CS_PARTICLE_SPAWN_THREADS,1,1)]
void default_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + particle_index_range.x;
	if (index < particle_index_range.y)
	{
		//test
		uint packed_address = cs_particle_address_buffer[index];
		uint2 address = uint2(packed_address & 0xffff, packed_address >> 16);	
		uint out_index = address.x + (address.y * 16);	
		cs_particle_state_buffer[out_index] = cs_particle_state_spawn_buffer[index];
	}
}

#endif

BEGIN_TECHNIQUE _default
{
	pass particle
	{
#if DX_VERSION == 9	
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
#elif DX_VERSION == 11
		SET_COMPUTE_SHADER(default_cs());
#endif
	}
}