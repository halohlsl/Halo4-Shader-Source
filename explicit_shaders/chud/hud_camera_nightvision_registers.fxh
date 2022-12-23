#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, ps_source_sampler,		s0);
DECLARE_PARAMETER(sampler2D, ps_depth_sampler, s0);
DECLARE_PARAMETER(sampler2D, ps_color_sampler, s1);
DECLARE_PARAMETER(sampler2D, ps_mask_sampler, s2);

DECLARE_PARAMETER(float4, ps_falloff, c94);
DECLARE_PARAMETER(float4x4, ps_screen_to_world, c95);
DECLARE_PARAMETER(float4, ps_ping, c99);
DECLARE_PARAMETER(float4, ps_colors[4][2], c100);

#elif DX_VERSION == 11

CBUFFER_BEGIN(HUDCameraNightvisionPS)
	CBUFFER_CONST(HUDCameraNightvisionPS,			float4,		ps_falloff,				k_ps_hud_camera_nightvision_falloff)
	CBUFFER_CONST(HUDCameraNightvisionPS,			float4x4,	ps_screen_to_world,		k_ps_hud_camera_nightvision_screen_to_world)
	CBUFFER_CONST(HUDCameraNightvisionPS,			float4,		ps_ping,				k_ps_hud_camera_nightvision_ping)
	CBUFFER_CONST_ARRAY(HUDCameraNightvisionPS,	float4,		ps_colors, [4][2],		k_ps_hud_camera_nightvision_colors)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler,		k_ps_hud_camera_nightvision_source_sampler,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_depth_sampler,		k_ps_hud_camera_nightvision_depth_sampler,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_colour_sampler,		k_ps_hud_camera_nightvision_colour_sampler,		1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_mask_sampler,		k_ps_hud_camera_nightvision_mask_sampler,		2)

#endif
