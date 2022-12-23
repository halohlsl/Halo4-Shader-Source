#if DX_VERSION == 9

DECLARE_PARAMETER(float4x4, vs_shadow_projection, c242);

// sampler for the depth data
DECLARE_PARAMETER(sampler2D, depth_sampler, s0);
DECLARE_PARAMETER(sampler2D, accum_sampler, s1);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ParticleizeVS)
	CBUFFER_CONST(ParticleizeVS,		float4x4,		vs_shadow_projection,		k_vs_particleize_shadow_projection)
CBUFFER_END

VERTEX_TEXTURE_AND_SAMPLER(_2D,	depth_sampler, 		k_vs_particleize_depth_sampler,		0)
VERTEX_TEXTURE_AND_SAMPLER(_2D,	accum_sampler, 		k_vs_particleize_accum_sampler,		1)

#endif
