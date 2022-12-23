#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, ps_source_sampler0, s0);
DECLARE_PARAMETER(sampler2D, ps_source_sampler1, s1);

DECLARE_PARAMETER(float4, vs_texcoord_xform0,	c8);
DECLARE_PARAMETER(float4, vs_texcoord_xform1,	c9);

#elif DX_VERSION == 11

CBUFFER_BEGIN(AntialiasBlurCombineVS)
	CBUFFER_CONST(AntialiasBlurCombineVS,	float4,		vs_texcoord_xform0,		k_vs_antialias_blur_combine_xform0)
	CBUFFER_CONST(AntialiasBlurCombineVS,	float4,		vs_texcoord_xform1,		k_vs_antialias_blur_combine_xform1)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler0, 		k_ps_antialias_blur_combine_source_sampler0,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler1, 		k_ps_antialias_blur_combine_source_sampler1,		1)

#endif
