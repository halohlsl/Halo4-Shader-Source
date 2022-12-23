#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

float4 filterTex2D(in texture_sampler_2d source_sampler, in float4 sampler_transform, in float2 texcoord)
{
	float4 color = sample2D(source_sampler, texcoord);

	// For the purposes of filtering, we want to use the color in non-premultiplied alpha form; so for textures
	// that use premultiplied alpha, we convert to non-premultiplied alpha.
	color.a = color.a * (-1 * sampler_transform.x) + (1 - sampler_transform.y);

	// Convert from gamma2 to linear space
	color.rgb = color.rgb * color.rgb;

	return color;
}

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	// Calculate the sample position for the resolved render target texture
	float2 sourceTexCoord = (input.screenPos - k_cui_pixel_shader_color0.xy) / k_cui_pixel_shader_color0.zw;

	// Note that the Photoshop 'Overlay" filter uses favoritism to favor the layer below the 'Overlay'
	// filtered layer. In order to get the output of this shader to match Photoshop, we need to do the
	// same thing. Consequently, 'color0' is sampled from source_sampler0, and 'color1' is sampled
	// from source_sampler2. This causes the same favoritism that Photoshop uses.
	// See 'http://www.photoshopessentials.com/photo-editing/layer-blend-modes/page-4.php' for more info.
	float4 color1 = filterTex2D(source_sampler2, k_cui_sampler2_transform, sourceTexCoord);
	float4 color0 = filterTex2D(source_sampler0, k_cui_sampler0_transform, input.texcoord);

	///////////////////////////////////
	// Screen filtering (lighten image for color1 values over 0.5)
	///////////////////////////////////

	const float3 screenFilterTheta = saturate((color1.rgb - 0.5) * 2.0);
	const float3 screenFilteredColor = lerp(color0.rgb, float3(1,1,1), screenFilterTheta);

	///////////////////////////////////
	// Multiply filtering (darken image for color1 values below 0.5)
	///////////////////////////////////
	const float3 multiplyFilterTheta = saturate(color1.rgb * 2.0);
	const float3 multiplyFilteredColor = color0.rgb * multiplyFilterTheta;

	///////////////////////////////////
	// Use either Multiplied or Screened result based on the intensity of each color channel
	///////////////////////////////////
	const float3 filterDecision = step(float3(0.5,0.5,0.5), color1.rgb);
	float4 color = float4(
		lerp(multiplyFilteredColor, screenFilteredColor, filterDecision),
		color1.a);

	// Convert to premultiplied alpha form
	color.rgb = color.rgb * color.a;
	color.a = 1.0 - color.a;

	color = cui_tint(cui_linear_to_gamma2(color), cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color));
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
