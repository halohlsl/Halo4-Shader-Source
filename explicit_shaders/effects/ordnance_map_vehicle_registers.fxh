#if DX_VERSION == 9

DECLARE_PARAMETER(float3, vsVehiclePosition, c17); // hack arbitrary number wooo!
DECLARE_PARAMETER(float3, vsVehicleFacing, c18); // hack arbitrary number wooo!
DECLARE_PARAMETER(float2, vsVehicleSize, c19); // hack arbitrary number wooo!

DECLARE_PARAMETER(sampler2D, alpha_map, s8);

#elif DX_VERSION == 11

CBUFFER_BEGIN(OrdnanceMapVehicleVS)
	CBUFFER_CONST(OrdnanceMapVehicleVS,		float3,		vsVehiclePosition,		k_vs_ordnance_map_vehicle_position)
	CBUFFER_CONST(OrdnanceMapVehicleVS,		float,		vsVehiclePosition_pad,	k_vs_ordnance_map_vehicle_position_pad)
	CBUFFER_CONST(OrdnanceMapVehicleVS,		float3,		vsVehicleFacing,		k_vs_ordnance_map_vehicle_facing)
	CBUFFER_CONST(OrdnanceMapVehicleVS,		float,		vsVehicleFacing_pad,	k_vs_ordnance_map_vehicle_facing_pad)
	CBUFFER_CONST(OrdnanceMapVehicleVS,		float2,		vsVehicleSize,			k_vs_ordnance_map_vehicle_size)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	alpha_map,		k_ps_ordnance_map_vehicle_alpha_map,		8)

#endif
