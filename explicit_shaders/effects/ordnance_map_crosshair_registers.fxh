#if DX_VERSION == 9

DECLARE_PARAMETER(float2, vsCrosshairPosition, c17); // hack arbitrary number wooo!

#elif DX_VERSION == 11

CBUFFER_BEGIN(OrdnanceMapCrosshairVS)
	CBUFFER_CONST(OrdnanceMapCrosshairVS,	float2,		vsCrosshairPosition,		k_vs_ordnance_map_crosshair_position)
CBUFFER_END

#endif
