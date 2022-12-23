#if DX_VERSION == 9

sampler depth_sampler : register(s0);
sampler albedo_sampler : register(s1);
sampler normal_sampler : register(s2);
sampler specular_curve_sampler : register(s3);
sampler gel_sampler : register(s4);

DECLARE_PARAMETER(float4x4, screen_light_shadow_matrix, c200);
DECLARE_PARAMETER(float4, screen_light_shadow_aux_constant_0, c204);
DECLARE_PARAMETER(float4, screen_light_shadow_aux_constant_1, c205);

#elif DX_VERSION == 11

CBUFFER_BEGIN(LightApplyBasePS)
	CBUFFER_CONST(LightApplyBasePS,		float4x4,		screen_light_shadow_matrix,				k_ps_light_apply_base_screen_light_shadow_matrix)
	CBUFFER_CONST(LightApplyBasePS,		float4,			screen_light_shadow_aux_constant_0,		k_ps_light_apply_base_screen_light_shadow_aux_constant_0)
	CBUFFER_CONST(LightApplyBasePS,		float4,			screen_light_shadow_aux_constant_1,		k_ps_light_apply_base_screen_light_shadow_aux_constant_1)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_sampler,				k_ps_light_apply_base_depth_sampler,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	albedo_sampler,				k_ps_light_apply_base_albedo_sampler,			1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	normal_sampler,				k_ps_light_apply_base_normal_sampler,			2)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	specular_curve_sampler,		k_ps_light_apply_base_specular_curve_sampler,	3)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	gel_sampler,				k_ps_light_apply_base_gel_sampler,				4)

#endif
