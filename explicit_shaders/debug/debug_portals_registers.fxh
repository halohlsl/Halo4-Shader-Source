#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, vector_map, s0);

DECLARE_PARAMETER(float4, color, c2);

#elif DX_VERSION == 11

CBUFFER_BEGIN(DebugPortalsPS)
	CBUFFER_CONST(DebugPortalsPS,		float4,		color,		k_ps_debug_portals_color)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	vector_map, 	k_ps_debug_portals_vector_map,		0)

#endif
