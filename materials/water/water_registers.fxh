#if DX_VERSION == 9

/* water only*/
DECLARE_PARAMETER(sampler2D, tex_ripple_buffer_slope_height_vs, s1);
DECLARE_PARAMETER(sampler2D, tex_ripple_buffer_slope_height_ps, s11);

// underwater only
DECLARE_PARAMETER(sampler2D, tex_ldr_buffer, s12);
DECLARE_PARAMETER(sampler2D, tex_depth_buffer, s14);

// share constants
DECLARE_PARAMETER(float, k_ripple_buffer_radius, c133);
DECLARE_PARAMETER(float2, k_view_dependent_buffer_center_shifting, c134);

DECLARE_PARAMETER(float4x4, k_ps_water_view_xform_inverse, c213);
DECLARE_PARAMETER(float4, k_ps_water_player_view_constant, c218);

#elif DX_VERSION == 11

CBUFFER_BEGIN(WaterVS)
	CBUFFER_CONST(WaterVS,		float, 		k_ripple_buffer_radius, 					k_vs_water_ripple_buffer_radius)
	CBUFFER_CONST(WaterVS,		float3, 	k_ripple_buffer_radius_pad, 				k_vs_water_ripple_buffer_radius_pad)
	CBUFFER_CONST(WaterVS,		float2, 	k_view_dependent_buffer_center_shifting, 	k_vs_water_view_dependent_buffer_center_shifting)
CBUFFER_END

CBUFFER_BEGIN(WaterPS)
	CBUFFER_CONST(WaterPS,		float4x4, 	k_ps_water_view_xform_inverse, 				k_ps_water_view_xform_inverse)
	CBUFFER_CONST(WaterPS,		float4, 	k_ps_water_player_view_constant, 			k_ps_water_player_view_constant)
CBUFFER_END

VERTEX_TEXTURE_AND_SAMPLER(_2D,	tex_ripple_buffer_slope_height_vs, 		k_vs_water_ripple_buffer_slope_height,		2)

PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex_ripple_buffer_slope_height_ps, 		k_ps_water_ripple_buffer_slope_height,		11)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex_ldr_buffer, 						k_ps_water_ldr_buffer,						12)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex_depth_buffer, 						k_ps_water_depth_buffer,					13)


#endif
