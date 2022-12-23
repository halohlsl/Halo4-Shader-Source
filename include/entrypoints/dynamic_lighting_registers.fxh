#if DX_VERSION == 9

DECLARE_PARAMETER(float4x4,	vs_shadow_projection, c242);

#elif DX_VERSION == 11

CBUFFER_BEGIN(DynamicLightingVS)
	CBUFFER_CONST(DynamicLightingVS,		float4x4,	vs_shadow_projection, 		k_vs_dynamic_lighting_shadow_projection)
CBUFFER_END

#endif
