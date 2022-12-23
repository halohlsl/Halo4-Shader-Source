#if DX_VERSION == 9

// Tessellation parameters
DECLARE_PARAMETER(float4, vs_water_memexport_address, c130);
DECLARE_PARAMETER(float4, vs_water_index_offset, c131);
DECLARE_PARAMETER(float4, k_vs_tess_camera_position, c132);
DECLARE_PARAMETER(float4, k_vs_tess_camera_forward, c133);
DECLARE_PARAMETER(float4, k_vs_tess_camera_diagonal, c134);


#elif DX_VERSION == 11
/*
CBUFFER_BEGIN(WaterTessellationVS)
	CBUFFER_CONST(WaterTessellationVS,		float4, 		vs_water_memexport_address,			k_vs_water_tessellation_memexport_address)
	CBUFFER_CONST(WaterTessellationVS,		float4, 		vs_water_index_offset, 				k_vs_water_tessellation_index_offset)
	CBUFFER_CONST(WaterTessellationVS,		float4, 		k_vs_tess_camera_position, 			k_vs_water_tessellation_camera_position)
	CBUFFER_CONST(WaterTessellationVS,		float4, 		k_vs_tess_camera_forward, 			k_vs_water_tessellation_camera_forward)
	CBUFFER_CONST(WaterTessellationVS,		float4, 		k_vs_tess_camera_diagonal, 			k_vs_water_tessellation_camera_diagonal)
CBUFFER_END
*/
#endif
