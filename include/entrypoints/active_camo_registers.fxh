#if DX_VERSION == 9

float4 ps_activeCamoFactor : register(c221); // x: transparency scale, yz: screenspace distortion mult, w: texture distortion multiplier
float4 ps_distortionTextureTransform : register(c222);

bool distortionTextureEnabled : register(b100);

sampler sceneTexture : register(s12);
sampler distortionTexture : register(s13);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ActiveCamoPS)
	CBUFFER_CONST(ActiveCamoPS,	float4,		ps_activeCamoFactor,			k_ps_active_camo_factor)
	CBUFFER_CONST(ActiveCamoPS,	float4,		ps_distortionTextureTransform,	k_ps_active_camo_distortion_texture_transform)
	CBUFFER_CONST(ActiveCamoPS,	bool,		distortionTextureEnabled,		k_ps_active_camo_bool_distortion_texture_enabled)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	sceneTexture,			k_ps_active_camo_scene_texture,			12)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	distortionTexture,		k_ps_active_camo_distortion_texture,	13)

#endif
