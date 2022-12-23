#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_texture1TintColor k_cui_pixel_shader_color0
#define k_texture2TintColor k_cui_pixel_shader_color1
#define k_hasValidTexture2 k_cui_pixel_shader_scalar0
#define k_texture1TintOpacity k_cui_pixel_shader_scalar1
#define k_texture2TintOpacity k_cui_pixel_shader_scalar2

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	// Read color from texture and tint
	float4 color1 = cui_tex2D(source_sampler0, k_cui_sampler0_transform, input.texcoord);
	float4 color2 = cui_tex2D(source_sampler1, k_cui_sampler1_transform, input.texcoord);

	color2 = lerp(color1, color2, step(0.9, k_hasValidTexture2));

	float4 tintColor = float4(k_texture1TintColor.rgb, k_texture1TintColor.a * k_texture1TintOpacity);
	color1 = cui_tint(color1, cui_linear_to_gamma2(tintColor));

	tintColor = float4(k_texture2TintColor.rgb, k_texture2TintColor.a * k_texture2TintOpacity);
	color2 = cui_tint(color2, cui_linear_to_gamma2(tintColor));

	float4 color = float4(color1.rgb + color2.rgb, color1.a);
	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint * input.color));
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
