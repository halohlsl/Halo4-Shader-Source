#if DX_VERSION == 9

DECLARE_PARAMETER(float4, color, c2);

#elif DX_VERSION == 11

CBUFFER_BEGIN(DebugLightPS)
	CBUFFER_CONST(DebugLightPS,	float4,		color,		k_ps_debug_light_color)
CBUFFER_END

#endif
