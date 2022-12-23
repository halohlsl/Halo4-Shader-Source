#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_glow_color k_cui_pixel_shader_color0
#define k_source_transform k_cui_pixel_shader_color1
#define k_outerglow_spread k_cui_pixel_shader_scalar0

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	// Sample the blurred and non-blurred alphas. Leave the baseAlpha in premultiplied form, because the glowIntensity
	// calculation needs the base alpha value to be inverted in order to apply it as a mask.
	float baseAlpha = sample2D(source_sampler0, input.texcoord).a;
	float blurAlpha = sample2D(source_sampler1, input.texcoord).a;

	// Apply the spread and mask the glow to not cover the base image
	float glowIntensity = pow(blurAlpha, k_outerglow_spread) * baseAlpha;

	// Apply color tint and convert to premultiplied alpha
	float4 color = cui_linear_to_gamma2(k_glow_color * k_cui_pixel_shader_tint * input.color * glowIntensity);
	color.rgb *= color.a;
	color.a = 1.0 - color.a;

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
