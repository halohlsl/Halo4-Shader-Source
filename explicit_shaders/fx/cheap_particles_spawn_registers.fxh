#if DX_VERSION == 9

DECLARE_PARAMETER(float3, vs_positions[16], c160);
DECLARE_PARAMETER(float3, vs_velocities[16], c176);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CheapParticlesSpawnVS)
	CBUFFER_CONST_ARRAY(CheapParticlesSpawnVS,		float4,		vs_positions, [16],		k_vs_cheap_particles_spawn_positions)
	CBUFFER_CONST_ARRAY(CheapParticlesSpawnVS,		float4,		vs_velocities, [16],	k_vs_cheap_particles_spawn_velocities)
CBUFFER_END

#endif
