#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_glow_color k_cui_pixel_shader_color0
#define k_source_transform k_cui_pixel_shader_color1
#define k_innerglow_choke k_cui_pixel_shader_scalar0
#define k_useEdgeSource k_cui_pixel_shader_bool0

float4 baseTex2D(in texture_sampler_2d source_sampler, in float4 sampler_transform, in float2 texcoord)
{
	float4 color = sample2D(source_sampler, texcoord);

	// For the purposes of filtering, we want to use the color in non-premultiplied alpha form; so for textures
	// that use premultiplied alpha, we convert to non-premultiplied alpha.
	color.a = color.a * (-1 * sampler_transform.x) + (1 - sampler_transform.y);
	return color;
}


float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	// Sample the blurred and non-blurred textures. Read the baseAlpha value as non-premultiplied and
	// the blurred alpha value we know to not be premultiplied.
	float baseAlpha = baseTex2D(source_sampler0, k_cui_sampler0_transform, input.texcoord).a;
	float blurAlpha = sample2D(source_sampler1, input.texcoord).a;

	// Mask the glow intensity to only cover the interior of the shape
	float glowIntensity = blurAlpha * baseAlpha;

	// The default alpha value will be correct for 'useEdgeSource'. If the user has requested
	// 'center' as the source, we need to invert the glowIntensity.
	if (!k_useEdgeSource)
	{
		glowIntensity = 1.0 - glowIntensity;
	}

	// Apply the choke
	glowIntensity = pow(glowIntensity, k_innerglow_choke);

	float4 color = cui_linear_to_gamma2(k_glow_color * k_cui_pixel_shader_tint * input.color * glowIntensity);

	// Convert to premultiplied alpha
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
