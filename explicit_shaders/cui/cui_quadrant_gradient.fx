#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader


#define top_left_color k_cui_pixel_shader_color0
#define top_right_color k_cui_pixel_shader_color1
#define bottom_left_color k_cui_pixel_shader_color2
#define bottom_right_color k_cui_pixel_shader_color3

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 color = cui_tex2D(input.texcoord);

	float2 gradientTexcoord = saturate(
		(input.texcoord - k_cui_pixel_shader_authored_bounds.xy) /
		(k_cui_pixel_shader_authored_bounds.zw - k_cui_pixel_shader_authored_bounds.xy));

	float4 top_color = top_left_color*(1-gradientTexcoord.x) + top_right_color*gradientTexcoord.x;
	float4 bottom_color = bottom_left_color*(1-gradientTexcoord.x) + bottom_right_color*gradientTexcoord.x;
	float4 gradient_color = top_color*(1-gradientTexcoord.y) + bottom_color*gradientTexcoord.y;

	color = cui_tint(color,
		cui_linear_to_gamma2(gradient_color),
		cui_linear_to_gamma2(k_cui_pixel_shader_tint));

	return color * ps_scale;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE curved_cui
{
	pass screen
	{
		SET_VERTEX_SHADER(curved_cui_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
