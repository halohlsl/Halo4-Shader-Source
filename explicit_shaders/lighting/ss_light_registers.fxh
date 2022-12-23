#if DX_VERSION == 9

#define ps_screen_space_light_constants ps_lighting_constants
#define ps_screen_space_shadow_rotation ps_shadow_rotation
#define ps_screen_space_light_rotation ps_light_rotation

#else

CBUFFER_BEGIN(ScreenSpaceLightPS)
	CBUFFER_CONST_ARRAY(ScreenSpaceLightPS,		float4,		ps_screen_space_light_constants, [14],		k_ps_screen_space_light_constants)
CBUFFER_END

#define _PS_SHADOW_ROTATION_VALUE transpose(float3x3(ps_screen_space_light_constants[10].xyz, ps_screen_space_light_constants[11].xyz, ps_screen_space_light_constants[12].xyz))
SHADER_CONST_ALIAS(ScreenSpaceLightPS,	float3x3,		ps_screen_space_shadow_rotation,		_PS_SHADOW_ROTATION_VALUE,		k_ps_screen_space_shadow_rotation,	k_ps_screen_space_light_constants, (10*16))

#define _PS_LIGHT_ROTATION_VALUE transpose(float3x4(ps_screen_space_light_constants[7], ps_screen_space_light_constants[8], ps_screen_space_light_constants[9]))
SHADER_CONST_ALIAS(ScreenSpaceLightPS,	float4x3,		ps_screen_space_light_rotation,			_PS_LIGHT_ROTATION_VALUE,		k_ps_screen_space_light_rotation,	k_ps_screen_space_light_constants, (7*16))

#endif
