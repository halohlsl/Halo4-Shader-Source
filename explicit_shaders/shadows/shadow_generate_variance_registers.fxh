#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, 	ps_texture_sampler,			s0);

DECLARE_PARAMETER(float4, ps_gaussian_parameters[2], c0);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShadowGenerateVariancePS)
	CBUFFER_CONST_ARRAY(ShadowGenerateVariancePS,		float4,		ps_gaussian_parameters, [2],		k_ps_shadow_generate_variance_gaussian_parameters)
CBUFFER_END

SHADER_CONST_ALIAS(ShadowGenerateVariancePS,	float4,		ps_horizontal_weights,		ps_gaussian_parameters[0],		k_ps_shadow_generate_variance_horizontal_weights,	k_ps_shadow_generate_variance_gaussian_parameters, 0)
SHADER_CONST_ALIAS(ShadowGenerateVariancePS,	float4,		ps_vertical_weights,		ps_gaussian_parameters[1],		k_ps_shadow_generate_variance_vertical_weights,		k_ps_shadow_generate_variance_gaussian_parameters, 16)

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_texture_sampler,			k_ps_shadow_generate_variance_texture_sampler,			0)

#endif

