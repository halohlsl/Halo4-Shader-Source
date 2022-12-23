#if !defined(__PARTICLE_INDEX_REGISTERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __PARTICLE_INDEX_REGISTERS_FXH
#endif

#if DX_VERSION == 11

CBUFFER_BEGIN(ParticleIndex)
	CBUFFER_CONST(ParticleIndex,			uint2,				particle_index_range,				k_particle_index_range)
CBUFFER_END

#endif

#endif
