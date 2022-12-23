#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

[reduceTempRegUsage(2)]
float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 color = cui_linear_to_gamma2_tex2D(input.texcoord);

	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color));

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
