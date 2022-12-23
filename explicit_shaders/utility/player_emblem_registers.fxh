#if !defined(__PLAYER_EMBLEM_REGISTERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __PLAYER_EMBLEM_REGISTERS_FXH
#endif

#if DX_VERSION == 9

DECLARE_PARAMETER(float4,	foreground_color,		c32);
DECLARE_PARAMETER(float4,	midground_color,		c33);
DECLARE_PARAMETER(float4,	background_color,		c34);

DECLARE_PARAMETER(float3x2,	foreground_xform[2],	c36);
DECLARE_PARAMETER(float4,	foreground_params[2],	c40);

DECLARE_PARAMETER(float3x2,	midground_xform[2],		c42);
DECLARE_PARAMETER(float4,	midground_params[2],	c46);

DECLARE_PARAMETER(float3x2,	background_xform[2],	c48);
DECLARE_PARAMETER(float4,	background_params[2],	c52);

DECLARE_PARAMETER(sampler,	foreground0_sampler,	s5);
DECLARE_PARAMETER(sampler,	foreground1_sampler,	s6);
DECLARE_PARAMETER(sampler,	midground0_sampler,		s7);
DECLARE_PARAMETER(sampler,	midground1_sampler,		s8);
DECLARE_PARAMETER(sampler,	background0_sampler,	s9);
DECLARE_PARAMETER(sampler,	background1_sampler,	s10);

#elif DX_VERSION == 11

CBUFFER_BEGIN(EmblemPS)
	CBUFFER_CONST(EmblemPS,			float4,		foreground_color,		k_ps_emblem_foreground_color)
	CBUFFER_CONST(EmblemPS,			float4,		midground_color,		k_ps_emblem_midground_color)
	CBUFFER_CONST(EmblemPS,			float4,		background_color,		k_ps_emblem_background_color)
	CBUFFER_CONST(EmblemPS,			float4,		type_flags,			k_ps_emblem_type_flags)

	CBUFFER_CONST_ARRAY(EmblemPS,		float3x2,	foreground_xform, [2],	k_ps_emblem_foreground_xform)
	CBUFFER_CONST_ARRAY(EmblemPS,		float4,		foreground_params, [2],	k_ps_emblem_foreground_params)		// vector_sharpness, antialias_tweak, expand, mix weight

	CBUFFER_CONST_ARRAY(EmblemPS,		float3x2,	midground_xform, [2],	k_ps_emblem_midground_xform)
	CBUFFER_CONST_ARRAY(EmblemPS,		float4,		midground_params, [2],	k_ps_emblem_midground_params)			// vector_sharpness, antialias_tweak, expand, mix weight

	CBUFFER_CONST_ARRAY(EmblemPS,		float3x2,	background_xform, [2],	k_ps_emblem_background_xform)
	CBUFFER_CONST_ARRAY(EmblemPS,		float4,		background_params, [2],	k_ps_emblem_background_params)		// vector_sharpness, antialias_tweak, expand, mix weight
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	foreground0_sampler,		k_ps_emblem_foreground0_sampler,	5)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	foreground1_sampler,		k_ps_emblem_foreground1_sampler,	6)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	midground0_sampler,			k_ps_emblem_midground0_sampler,		7)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	midground1_sampler,			k_ps_emblem_midground1_sampler,		8)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	background0_sampler,		k_ps_emblem_background0_sampler,	9)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	background1_sampler,		k_ps_emblem_background1_sampler,	10)

#endif

#endif // __PLAYER_EMBLEM_REGISTERS_FXH
