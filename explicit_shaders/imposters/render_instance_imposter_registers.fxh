#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, k_ps_texture_vmf_diffuse, s0);
DECLARE_PARAMETER(sampler, k_ps_texture_imposter_atlas, s2);

DECLARE_PARAMETER(float4, k_vs_atlas_tile_texcoord_scalar, c252);
DECLARE_PARAMETER(float4, brightness, c130);

float4 camera_normal_x : register(c150);
float4 camera_normal_y : register(c151);
float4 camera_normal_z : register(c152);

#elif DX_VERSION == 11

CBUFFER_BEGIN(RenderInstanceImposterVS)
	CBUFFER_CONST(RenderInstanceImposterVS,	float4,		k_vs_atlas_tile_texcoord_scalar,	k_vs_render_instance_imposter_atlas_tile_texcoord_scalar)
	CBUFFER_CONST(RenderInstanceImposterVS,	float4,		brightness,							k_vs_render_instance_imposter_brightness)
CBUFFER_END

CBUFFER_BEGIN(RenderInstanceImposterPS)
	CBUFFER_CONST(RenderInstanceImposterPS,	float4,		camera_normal_x,	k_ps_render_instance_imposter_camera_normal_x)
	CBUFFER_CONST(RenderInstanceImposterPS,	float4,		camera_normal_y,	k_ps_render_instance_imposter_camera_normal_y)
	CBUFFER_CONST(RenderInstanceImposterPS,	float4,		camera_normal_z,	k_ps_render_instance_imposter_camera_normal_z)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_texture_vmf_diffuse, 			k_ps_render_instance_imposter_texture_vmf_diffuse,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_texture_imposter_atlas, 		k_ps_render_instance_imposter_texture_imposter_atlas,	2)

#endif
