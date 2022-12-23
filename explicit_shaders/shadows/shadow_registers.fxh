#if DX_VERSION == 9

sampler zbuffer : register(s0);
sampler shadow : register(s1);
sampler normal_buffer : register(s2);

DECLARE_PARAMETER(float4, ps_shadow_parameters[10], c176);
DECLARE_PARAMETER(float4x4, k_ps_view_xform_inverse, c213);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShadowPS)
	CBUFFER_CONST_ARRAY(ShadowPS,		float4,		ps_shadow_parameters, [10],		_ps_shadow_parameters_first)
	CBUFFER_CONST(ShadowPS,			float4x4,	k_ps_view_xform_inverse,		_ps_view_transform_inverse)
CBUFFER_END

SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_0,		ps_shadow_parameters[0],	_ps_shadow_parameters_0,	_ps_shadow_parameters_first, 0)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_1,		ps_shadow_parameters[1],	_ps_shadow_parameters_1,	_ps_shadow_parameters_first, 16)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_2,		ps_shadow_parameters[2],	_ps_shadow_parameters_2,	_ps_shadow_parameters_first, 32)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_3,		ps_shadow_parameters[3],	_ps_shadow_parameters_3,	_ps_shadow_parameters_first, 48)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_4,		ps_shadow_parameters[4],	_ps_shadow_parameters_4,	_ps_shadow_parameters_first, 64)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_5,		ps_shadow_parameters[5],	_ps_shadow_parameters_5,	_ps_shadow_parameters_first, 80)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_6,		ps_shadow_parameters[6],	_ps_shadow_parameters_6,	_ps_shadow_parameters_first, 96)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_7,		ps_shadow_parameters[7],	_ps_shadow_parameters_7,	_ps_shadow_parameters_first, 112)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_8,		ps_shadow_parameters[8],	_ps_shadow_parameters_8,	_ps_shadow_parameters_first, 128)
SHADER_CONST_ALIAS(ShadowPS,	float4,		ps_shadow_parameters_9,		ps_shadow_parameters[9],	_ps_shadow_parameters_9,	_ps_shadow_parameters_first, 144)

PIXEL_TEXTURE_AND_SAMPLER(_2D,	zbuffer,			k_ps_shadow_zbuffer_sampler,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	shadow,				k_ps_shadow_shadow_sampler,			1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	normal_buffer,		k_ps_shadow_normal_buffer_sampler,	2)

#endif
