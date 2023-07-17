#if DX_VERSION == 9

DECLARE_PARAMETER(float3, vsBipedPosition, c17); // hack arbitrary number wooo!
DECLARE_PARAMETER(float3, vsBipedFacing, c18); // hack arbitrary number wooo!

#elif DX_VERSION == 11

CBUFFER_BEGIN(OrdnanceMapBipedVS)
	CBUFFER_CONST(OrdnanceMapBipedVS,	float3,		vsBipedPosition, 		k_vs_ordnance_map_biped_position)
	CBUFFER_CONST(OrdnanceMapBipedVS,	float,		vsBipedPosition_pad, 	k_vs_ordnance_map_biped_position_pad)
	CBUFFER_CONST(OrdnanceMapBipedVS,	float3,		vsBipedFacing, 			k_vs_ordnance_map_biped_facing)
	CBUFFER_CONST(OrdnanceMapBipedVS,	float,		vsBipedFacing_pad, 		k_vs_ordnance_map_biped_facing_pad)
CBUFFER_END

#endif
