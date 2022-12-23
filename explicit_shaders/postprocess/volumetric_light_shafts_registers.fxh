#if DX_VERSION == 9

float4 vs_near_mask_depth : register(c28);

float4 ps_screen_sun_pos : register(c7);
float4 ps_screen_sun_col : register(c8);
float4 ps_screen_maximum_range : register(c9);

#elif DX_VERSION == 11

CBUFFER_BEGIN(VolumetricLightShaftsVS)
	CBUFFER_CONST(VolumetricLightShaftsVS,	float4,		vs_near_mask_depth,			k_vs_volmetric_light_shafts_near_mask_depth)
CBUFFER_END

CBUFFER_BEGIN(VolumetricLightShaftsPS)
	CBUFFER_CONST(VolumetricLightShaftsPS,	float4,		ps_screen_sun_pos,			k_ps_volumetric_light_shafts_screen_sun_pos)
	CBUFFER_CONST(VolumetricLightShaftsPS,	float4,		ps_screen_sun_col,			k_ps_volumetric_light_shafts_screen_sun_col)
	CBUFFER_CONST(VolumetricLightShaftsPS,	float4,		ps_screen_maximum_range,	k_ps_volumetric_light_shafts_screen_maximum_range)
CBUFFER_END

#endif
