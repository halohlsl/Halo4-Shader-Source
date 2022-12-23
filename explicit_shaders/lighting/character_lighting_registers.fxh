#if DX_VERSION == 9

DECLARE_PARAMETER(float4x4, screen_to_relative_world, c144);		// p_lighting_constant_0 - p_lighting_constant_3,	maps (pixel, depth) to world space coordinates with the origin at the light center

sampler depth_sampler : register(s0);
sampler albedo_sampler : register(s1);
sampler normal_sampler : register(s2);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CharacterLightingPS)
	CBUFFER_CONST(CharacterLightingPS,		float4x4, 		screen_to_relative_world, 		k_character_lighting_screen_to_relative_world)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_sampler,		k_character_lighting_depth_sampler,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	albedo_sampler,		k_character_lighting_albedo_sampler,	1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	normal_sampler,		k_character_lighting_normal_sampler,	2)

#endif
