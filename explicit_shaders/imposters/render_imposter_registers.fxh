#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, k_ps_texture_vmf_diffuse, s0);
DECLARE_PARAMETER(sampler, k_ps_texture_cloud, s1);

DECLARE_PARAMETER(float4, k_ps_imposter_blend_alpha, c181);
DECLARE_PARAMETER(float4, k_ps_imposter_adjustment_constants, c182);

DECLARE_PARAMETER(float4, k_vs_big_battle_squad_constants, c232);
DECLARE_PARAMETER(float4, k_vs_hidden_from_compiler, c248);

// PC only constants
#if !defined(xenon)
DECLARE_PARAMETER(float4, k_vs_big_battle_squad_positon_scale, c233);
DECLARE_PARAMETER(float4, k_vs_big_battle_squad_foward, c234);
DECLARE_PARAMETER(float4, k_vs_big_battle_squad_left, c235);
DECLARE_PARAMETER(float4, k_vs_big_battle_squad_velocity, c236);
#endif

#elif DX_VERSION == 11

CBUFFER_BEGIN(RenderImposterVS)
	CBUFFER_CONST(RenderImposterVS,		float4, 	k_vs_big_battle_squad_constants, 		k_vs_render_imposter_big_battle_squad_constants)
	CBUFFER_CONST(RenderImposterVS,		float4, 	k_vs_hidden_from_compiler, 				k_vs_render_imposter_hidden_from_compiler)
	CBUFFER_CONST(RenderImposterVS,		float4, 	k_vs_big_battle_squad_positon_scale, 	k_vs_render_imposter_big_battle_squad_position_scale)
	CBUFFER_CONST(RenderImposterVS,		float4, 	k_vs_big_battle_squad_foward, 			k_vs_render_imposter_big_battle_squad_forward)
	CBUFFER_CONST(RenderImposterVS,		float4, 	k_vs_big_battle_squad_left, 			k_vs_render_imposter_big_battle_squad_left)
	CBUFFER_CONST(RenderImposterVS,		float4, 	k_vs_big_battle_squad_velocity, 		k_vs_render_imposter_big_battle_squad_velocity)
CBUFFER_END

CBUFFER_BEGIN(RenderImposterPS)
	CBUFFER_CONST(RenderImposterPS,		float4, 	k_ps_imposter_blend_alpha, 				k_ps_render_imposter_blend_alpha)
	CBUFFER_CONST(RenderImposterPS,		float4, 	k_ps_imposter_adjustment_constants, 	k_ps_render_imposter_adjustment_constants)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_texture_vmf_diffuse, 		k_ps_render_imposter_texture_vmf_diffuse,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_texture_cloud, 			k_ps_render_imposter_texture_cloud,				1)

#endif
