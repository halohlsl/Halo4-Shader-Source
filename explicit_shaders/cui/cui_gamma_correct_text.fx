#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_intensityRange (223.0 / 255.0)
#define k_intensityMin (32.0 / 255.0)

[reduceTempRegUsage(2)]
float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float4 color = sample2D(source_sampler0, input.texcoord);

	// This sqrt() applies a gamma curve to the rgb. In addition, it removes the curve which was applied to the alpha channel
	// in the font importer. The alpha curve is intended to preserve as much accuracy near white as possible.
	color = sqrt(color);

	// Scale and bias the alpha because the font importer discards all values below 32, and rescales the font value accordingly
	color.a = ((color.a * k_intensityRange) + k_intensityMin) * step(k_intensityMin, color.a);

	// Convert to premultiplied alpha
	color.rgb *= max(color.a, k_cui_sampler0_transform.z);
	color.a = color.a * k_cui_sampler0_transform.x + k_cui_sampler0_transform.y;

	// Apply cui widget tint
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
