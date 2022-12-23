#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, 	ps_texture_sampler,			s0);

DECLARE_PARAMETER(float, 	ps_constant_blur_threshold,		c0);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ForgeLightmapPostprocessPS)
	CBUFFER_CONST(ForgeLightmapPostprocessPS,		float,		ps_constant_blur_threshold,			k_ps_forge_lightmap_postprocess_blur_threshold)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_texture_sampler,		k_ps_forge_lightmap_postprocess_texture_sampler,		0)

#endif
