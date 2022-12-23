#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, ps_basemap_sampler, s0);

DECLARE_PARAMETER(float4, vs_lighting, c229);

#elif DX_VERSION == 11

CBUFFER_BEGIN(AlphaTestExplicitVS)
	CBUFFER_CONST(AlphaTestExplicitVS,		float4,		vs_lighting,		k_vs_alpha_test_explicit_lighting)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_basemap_sampler,		k_ps_alpha_test_explicit_basemap_sampler,	0)

#endif
