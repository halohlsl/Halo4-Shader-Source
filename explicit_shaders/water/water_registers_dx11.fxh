#if !defined( WATER_TYPES_DX11_FXH)
#	include "water_types_dx11.fxh"
#endif

// tesselation constants
CBUFFER_BEGIN(WaterTessCS)
	CBUFFER_CONST(WaterTessCS,	float4, k_vs_tess_camera_position, k_vs_water_tessellation_camera_position)
	CBUFFER_CONST(WaterTessCS,	float4, k_vs_tess_camera_forward, k_vs_water_tessellation_camera_forward)
	CBUFFER_CONST(WaterTessCS,	float4, k_vs_tess_camera_diagonal, k_vs_water_tessellation_camera_diagonal)
	CBUFFER_CONST(WaterTessCS, int, water_index_offset, k_vs_water_tess_index_offset)
	CBUFFER_CONST(WaterTessCS, int, num_input_triangles, k_water_tess_cs_num_triangles)
	CBUFFER_CONST(WaterTessCS, int, wave_tessellation_level, k_cs_wave_tessellation_level)
CBUFFER_END

// tesselation buffers/textures
STRUCTURED_BUFFER(		inputTriangles, 	k_inputTrangles, 	s_water_in_triangle, 4 )
RW_STRUCTURED_BUFFER(	outputVertices, 	k_outputVertices, 	s_water_render_vertex_out, 0)
RW_BUFFER( outputIndirect, k_outputIndirect, uint, 1)

