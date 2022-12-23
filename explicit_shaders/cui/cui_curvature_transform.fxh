#if !defined(__CUI_CURVATURE_TRANSFORM_FXH)
#define __CUI_CURVATURE_TRANSFORM_FXH

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "cui_registers.fxh"

// Bit of nastiness to make generic shader constants more readable
#define k_cui_screen_size k_cui_vertex_shader_constant0

#define k_cui_curvature_basis_0 k_cui_vertex_shader_constant1
#define k_cui_curvature_basis_1 k_cui_vertex_shader_constant2
#define k_cui_curvature_basis_2 k_cui_vertex_shader_constant3
#define k_cui_curvature_basis_3 k_cui_vertex_shader_constant4
#define k_cui_curvature_basis_4 k_cui_vertex_shader_constant5

#define k_cui_screen_scale_and_offset k_cui_vertex_shader_constant6
#define k_cui_screenshot_info k_cui_vertex_shader_constant7

float2 chud_transform(float2 input)
{
	input.xy = 2.0 * input.xy - 1.0;
	input.y = -input.y;
	float2 input_squared = input.xy*input.xy;
	float2 intermediate =
		  k_cui_curvature_basis_0.xy * input_squared.x * input_squared.y
		+ k_cui_curvature_basis_0.zw * input_squared.x * input.y
		+ k_cui_curvature_basis_1.xy * input_squared.x
		+ k_cui_curvature_basis_1.zw * input.x * input_squared.y
		+ k_cui_curvature_basis_2.xy * input.x * input.y
		+ k_cui_curvature_basis_2.zw * input.x
		+ k_cui_curvature_basis_3.xy * input_squared.y
		+ k_cui_curvature_basis_3.zw * input.y
		+ k_cui_curvature_basis_4.xy;

	float2 result;
	result = float2(
		k_cui_screen_scale_and_offset.x + k_cui_screen_scale_and_offset.y + k_cui_screen_scale_and_offset.y*intermediate.x,
		k_cui_screen_scale_and_offset.z + k_cui_screen_scale_and_offset.w + k_cui_screen_scale_and_offset.w*intermediate.y);

#ifndef IGNORE_SCREENSHOT_TILING
	// handle screenshots
	result.xy = result.xy * k_cui_screenshot_info.xy + k_cui_screenshot_info.zw;
#endif // IGNORE_SCREENSHOT_TILING

	// Convert to [-0.5 .. +0.5] space
	result.x= ( result.x - k_cui_screen_size.x / 2.0) / k_cui_screen_size.x;
	result.y= (-result.y + k_cui_screen_size.y / 2.0) / k_cui_screen_size.y;
	// Scale to [-1.0 .. +1.0] space
	result *= 2.0f;

	return result;
}

float4 chud_virtual_to_screen(float2 virtual_position)
{
	float2 transformed_position_scaled = float2(
		virtual_position.x / k_cui_screen_size.z,
		1.0f - virtual_position.y / k_cui_screen_size.w);

	transformed_position_scaled = chud_transform(transformed_position_scaled);

	// Transform from authored 1280x720 window size to current window size, anchoring to
	// the top-left of the window.
	transformed_position_scaled += float2(1.0f, -1.0f);
	transformed_position_scaled *= k_cui_screen_size.zw / k_cui_screen_size.xy;
	transformed_position_scaled -= float2(1.0f, -1.0f);

	return float4(transformed_position_scaled, 0.0f, 1.0f);
}

#endif	// __CUI_CURVATURE_TRANSFORM_FXH
