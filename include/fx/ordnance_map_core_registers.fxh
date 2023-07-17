#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, psMapSampler, s7);

DECLARE_PARAMETER(float4, vsWholeMapBounds, c22); // hack arbitrary number wooo!
DECLARE_PARAMETER(float4, vsVisibleScreenBounds, c23); // (min-x, min-y, extents-x, extents-y)
DECLARE_PARAMETER(float4, vsZBounds, c24); // (min-z, extent-z, min-depth-for-color, max-depth-for-color)

#elif DX_VERSION == 11

CBUFFER_BEGIN(OrdnanceMapCoreVS)
	CBUFFER_CONST(OrdnanceMapCoreVS,		float4, 	vsWholeMapBounds, 			k_vs_ordnance_map_core_whole_map_bounds)
	CBUFFER_CONST(OrdnanceMapCoreVS,		float4, 	vsVisibleScreenBounds, 		k_vs_ordnance_map_core_visible_screen_bounds)
	CBUFFER_CONST(OrdnanceMapCoreVS,		float4, 	vsZBounds, 					k_vs_ordnance_map_core_z_bounds)
CBUFFER_END
	
PIXEL_TEXTURE_AND_SAMPLER(_2D,	psMapSampler, 		k_ps_ordnance_map_core_map_sampler,		7)

#endif