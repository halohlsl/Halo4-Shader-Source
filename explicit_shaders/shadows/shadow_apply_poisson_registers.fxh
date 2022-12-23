#define MAX_TAPS 12

#if DX_VERSION == 9

float4  ps_midgraph_poisson_shadow_info: register(c229);
float4  ps_midgraph_poisson_shadow_taps[MAX_TAPS] : register(c230);

sampler poisson_sampler : register(s3);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShadowApplyPoissonPS)
	CBUFFER_CONST(ShadowApplyPoissonPS,			float4,		ps_midgraph_poisson_shadow_info,				k_ps_midgraph_poisson_shadow_info)
	CBUFFER_CONST_ARRAY(ShadowApplyPoissonPS,		float4,		ps_midgraph_poisson_shadow_taps, [MAX_TAPS],	k_ps_midgraph_poisson_shadow_taps)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	poisson_sampler,		k_ps_midgraph_poisson_sampler,		3)

#endif
