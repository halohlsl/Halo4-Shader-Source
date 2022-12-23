// vertex shader/constant decl for all chud shaders


#if DX_VERSION == 9

#undef VERTEX_CONSTANT
#undef PIXEL_CONSTANT
#ifdef VERTEX_SHADER
	#define VERTEX_CONSTANT(type, name, register_index)   type name : register(register_index);
	#define PIXEL_CONSTANT(type, name, register_index)   type name;
#else
	#define VERTEX_CONSTANT(type, name, register_index)   type name;
	#define PIXEL_CONSTANT(type, name, register_index)   type name : register(register_index);
#endif

// global constants
VERTEX_CONSTANT(float4, chud_screen_size, c19); // final_size_x, final_size_y, virtual_size_x, virtual_size_y
VERTEX_CONSTANT(float4, chud_basis_01, c20);
VERTEX_CONSTANT(float4, chud_basis_23, c21);
VERTEX_CONSTANT(float4, chud_basis_45, c22);
VERTEX_CONSTANT(float4, chud_basis_67, c23);
VERTEX_CONSTANT(float4, chud_basis_8, c24);
VERTEX_CONSTANT(float4, chud_screen_scale_and_offset, c25); // screen_offset_x, screen_half_scale_x, screen_offset_y, screen_half_scale_y
VERTEX_CONSTANT(float4, chud_project_scale_and_offset, c26); // x_scale, y_scale, offset_z, z_value_scale
VERTEX_CONSTANT(float4, chud_screenshot_info, c27); // <scale_x, scale_y, offset_x, offset_y>

// per widget constants
VERTEX_CONSTANT(float4, chud_widget_offset, c28);
VERTEX_CONSTANT(float4, chud_widget_transform1, c29);
VERTEX_CONSTANT(float4, chud_widget_transform2, c30);
VERTEX_CONSTANT(float4, chud_widget_transform3, c31);
VERTEX_CONSTANT(float4, chud_texture_transform, c32); // <scale_x, scale_y, offset_x, offset_y>

VERTEX_CONSTANT(float4, chud_widget_mirror, c33); // <mirror_x, mirror_y, 0, 0>

// global constants
PIXEL_CONSTANT(float4, chud_savedfilm_data1, c24); // <record_min, buffered_theta, bar_theta, 0.0>
PIXEL_CONSTANT(float4, chud_savedfilm_chap1, c25); // <chap0..3>
PIXEL_CONSTANT(float4, chud_savedfilm_chap2, c26); // <chap4..7>
PIXEL_CONSTANT(float4, chud_savedfilm_chap3, c27); // <chap8,9,-1,-1>

// per widget constants
PIXEL_CONSTANT(float4, chud_color_output_A, c28);
PIXEL_CONSTANT(float4, chud_color_output_B, c29);
PIXEL_CONSTANT(float4, chud_color_output_C, c30);
PIXEL_CONSTANT(float4, chud_color_output_D, c31);
PIXEL_CONSTANT(float4, chud_color_output_E, c32);
PIXEL_CONSTANT(float4, chud_color_output_F, c33);
PIXEL_CONSTANT(float4, chud_scalar_output_ABCD, c34);// [a, b, c, d]
PIXEL_CONSTANT(float4, chud_scalar_output_EF, c35);// [e, f, 0, global_hud_alpha]
PIXEL_CONSTANT(float4, chud_texture_bounds, c36); // <x0, x1, y0, y1>
PIXEL_CONSTANT(float4, chud_widget_transform1_ps, c37);
PIXEL_CONSTANT(float4, chud_widget_transform2_ps, c38);
PIXEL_CONSTANT(float4, chud_widget_transform3_ps, c39);

PIXEL_CONSTANT(float4, chud_widget_mirror_ps, c40);

// damage flash constants
PIXEL_CONSTANT(float4, chud_screen_flash0_color, c41); // rgb, alpha
PIXEL_CONSTANT(float4, chud_screen_flash0_data, c42); // virtual_x, virtual_y, center size, offscreen size
PIXEL_CONSTANT(float4, chud_screen_flash0_scale, c43); // center alpha, offscreen alpha, inner alpha, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash1_color, c44); // rgb, inner alpha
PIXEL_CONSTANT(float4, chud_screen_flash1_data, c45); // virtual_x, virtual_y, center size, offscreen size
PIXEL_CONSTANT(float4, chud_screen_flash1_scale, c46); // center alpha, offscreen alpha, inner alpha, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash2_color, c47); // rgb, inner alpha
PIXEL_CONSTANT(float4, chud_screen_flash2_data, c48); // virtual_x, virtual_y, center size, offscreen size
PIXEL_CONSTANT(float4, chud_screen_flash2_scale, c49); // center alpha, offscreen alpha, inner alpha, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash3_color, c50); // rgb, inner alpha
PIXEL_CONSTANT(float4, chud_screen_flash3_data, c51); // virtual_x, virtual_y, center size, offscreen size
PIXEL_CONSTANT(float4, chud_screen_flash3_scale, c52); // center alpha, offscreen alpha, inner alpha, outer alpha
PIXEL_CONSTANT(float4, chud_screen_flash_center, c53); // crosshair_x, crosshair_y, unused, unused
PIXEL_CONSTANT(float4, chud_screen_flash_scale, c54); // scale, falloff, inner_alpha, outer_alpha

PIXEL_CONSTANT(bool, chud_comp_colorize_enabled, b8);

sampler2D basemap_sampler : register(s0);

#ifndef pc
sampler2D noise_sampler : register(s2);
#endif // pc

#elif DX_VERSION == 11

CBUFFER_BEGIN(CHUDGlobalVS)
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_screen_size,				k_chud_vertex_shader_constant_global_screen_size) // final_size_x, final_size_y, virtual_size_x, virtual_size_y
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_basis_01,					k_chud_vertex_shader_constant_global_basis01)
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_basis_23,					k_chud_vertex_shader_constant_global_basis23)
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_basis_45,					k_chud_vertex_shader_constant_global_basis45)
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_basis_67,					k_chud_vertex_shader_constant_global_basis67)
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_basis_8,					k_chud_vertex_shader_constant_global_basis8)
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_screen_scale_and_offset,	k_chud_vertex_shader_constant_global_screen_scale_and_offset) // screen_offset_x, screen_half_scale_x, screen_offset_y, screen_half_scale_y
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_project_scale_and_offset,	k_chud_vertex_shader_constant_global_project_scale_and_offset) // x_scale, y_scale, offset_z, z_value_scale
	CBUFFER_CONST(CHUDGlobalVS,	float4,		chud_screenshot_info,			k_chud_vertex_shader_constant_global_screenshot_info) // <scale_x, scale_y, offset_x, offset_y>
CBUFFER_END

CBUFFER_BEGIN(CHUDWidgetVS)
	CBUFFER_CONST(CHUDWidgetVS,	float4,		chud_widget_offset,				_chud_vertex_shader_constant_widget_offset)
	CBUFFER_CONST(CHUDWidgetVS,	float4,		chud_widget_transform1,			_chud_vertex_shader_constant_widget_transform0)
	CBUFFER_CONST(CHUDWidgetVS,	float4,		chud_widget_transform2,			_chud_vertex_shader_constant_widget_transform1)
	CBUFFER_CONST(CHUDWidgetVS,	float4,		chud_widget_transform3,			_chud_vertex_shader_constant_widget_transform2)
	CBUFFER_CONST(CHUDWidgetVS,	float4,		chud_texture_transform,			_chud_vertex_shader_constant_widget_texture_transform) // <scale_x, scale_y, offset_x, offset_y>
	CBUFFER_CONST(CHUDWidgetVS,	float4,		chud_widget_mirror,				k_chud_vertex_shader_constant_widget_mirror) // <mirror_x, mirror_y, 0, 0>
CBUFFER_END

CBUFFER_BEGIN(CHUDGlobalPS)
	CBUFFER_CONST(CHUDGlobalPS,	float4,		chud_savedfilm_data1,			k_chud_pixel_shader_constant_global_savedfilm_data0) // <record_min, buffered_theta, bar_theta, 0.0>
	CBUFFER_CONST(CHUDGlobalPS,	float4,		chud_savedfilm_chap1,			k_chud_pixel_shader_constant_global_savedfilm_data1) // <chap0..3>
	CBUFFER_CONST(CHUDGlobalPS,	float4,		chud_savedfilm_chap2,			k_chud_pixel_shader_constant_global_savedfilm_data2) // <chap4..7>
	CBUFFER_CONST(CHUDGlobalPS,	float4,		chud_savedfilm_chap3,			k_chud_pixel_shader_constant_global_savedfilm_data3) // <chap8,9,-1,-1>
CBUFFER_END

CBUFFER_BEGIN(CHUDWidgetPS)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_color_output_A,			_chud_pixel_shader_constant_widget_color_output_a)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_color_output_B,			_chud_pixel_shader_constant_widget_color_output_b)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_color_output_C,			_chud_pixel_shader_constant_widget_color_output_c)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_color_output_D,			_chud_pixel_shader_constant_widget_color_output_d)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_color_output_E,			_chud_pixel_shader_constant_widget_color_output_e)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_color_output_F,			_chud_pixel_shader_constant_widget_color_output_f)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_scalar_output_ABCD,		_chud_pixel_shader_constant_widget_scalar_output_abcd) // [a, b, c, d]
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_scalar_output_EF,			_chud_pixel_shader_constant_widget_scalar_output_ef) // [e, f, 0, global_hud_alpha]
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_texture_bounds,			_chud_pixel_shader_constant_widget_texture_bounds) // <x0, x1, y0, y1>
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_widget_transform1_ps,		_chud_pixel_shader_constant_widget_transform1)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_widget_transform2_ps,		_chud_pixel_shader_constant_widget_transform2)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_widget_transform3_ps,		_chud_pixel_shader_constant_widget_transform3)
	CBUFFER_CONST(CHUDWidgetPS,	float4,		chud_widget_mirror_ps,			k_chud_pixel_shader_constant_widget_mirror)
CBUFFER_END

CBUFFER_BEGIN(CHUDDamageFlashPS)
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash0_color,		k_chud_pixel_shader_constant_screen_flash_color0) // rgb, alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash0_data,		k_chud_pixel_shader_constant_screen_flash_data0) // virtual_x, virtual_y, center size, offscreen size
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash0_scale,		k_chud_pixel_shader_constant_screen_flash_scale0) // center alpha, offscreen alpha, inner alpha, outer alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash1_color,		k_chud_pixel_shader_constant_screen_flash_color1) // rgb, inner alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash1_data,		k_chud_pixel_shader_constant_screen_flash_data1) // virtual_x, virtual_y, center size, offscreen size
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash1_scale,		k_chud_pixel_shader_constant_screen_flash_scale1) // center alpha, offscreen alpha, inner alpha, outer alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash2_color,		k_chud_pixel_shader_constant_screen_flash_color2) // rgb, inner alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash2_data,		k_chud_pixel_shader_constant_screen_flash_data2) // virtual_x, virtual_y, center size, offscreen size
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash2_scale,		k_chud_pixel_shader_constant_screen_flash_scale2) // center alpha, offscreen alpha, inner alpha, outer alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash3_color,		k_chud_pixel_shader_constant_screen_flash_color3) // rgb, inner alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash3_data,		k_chud_pixel_shader_constant_screen_flash_data3) // virtual_x, virtual_y, center size, offscreen size
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash3_scale,		k_chud_pixel_shader_constant_screen_flash_scale3) // center alpha, offscreen alpha, inner alpha, outer alpha
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash_center,		k_chud_pixel_shader_constant_screen_flash_center) // crosshair_x, crosshair_y, unused, unused
	CBUFFER_CONST(CHUDDamageFlashPS,	float4, chud_screen_flash_scale,		k_chud_pixel_shader_constant_screen_flash_scale) // scale, falloff, inner_alpha, outer_alpha
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D, 	basemap_sampler,		k_chud_basemap_sampler,		0)
#ifndef pc
PIXEL_TEXTURE_AND_SAMPLER(_2D,	noise_sampler,			k_chud_noise_sampler,		2)
#endif // pc

#endif

