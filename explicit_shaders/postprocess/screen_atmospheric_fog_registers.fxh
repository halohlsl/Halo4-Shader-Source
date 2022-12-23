#if DX_VERSION == 9

DECLARE_PARAMETER(			float4x4,	ps_view_transform_inverse,												c213);
DECLARE_PARAMETER(			float4, 	vs_near_fog_projected_depth,											c28);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenAtmosphericFogVS)
	CBUFFER_CONST(ScreenAtmosphericFogVS,		float4, 	vs_near_fog_projected_depth,		k_vs_screen_atmospheric_fog_near_fog_projected_depth)	
CBUFFER_END

CBUFFER_BEGIN(ScreenAtmosphericFogPS)
	CBUFFER_CONST(ScreenAtmosphericFogPS,			float4x4,	ps_view_transform_inverse,			k_ps_screen_atmospheric_fog_view_transform_inverse)
CBUFFER_END

#endif
