#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader


[reduceTempRegUsage(4)]
float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 color0= cui_linear_to_gamma2_tex2D(input.texcoord);

	float2 maskTexcoord = (input.texcoord - k_cui_pixel_shader_authored_bounds.xy) /
		(k_cui_pixel_shader_authored_bounds.zw - k_cui_pixel_shader_authored_bounds.xy);

	float4 color1= cui_tex2D_secondary(maskTexcoord);

	float4 color = color0 * color1;
	color.a = 1 - (1 - color0.a) * (1 - color1.a);

	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint));

	return color*ps_scale;
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
