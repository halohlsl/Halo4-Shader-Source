#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader


// k_dynamicThresholds.x is the minimum value at which the black backdrop starts rendering.
// k_dynamicThresholds.y is the maximum value at which the black backdrop becomes fully opaque.
// k_dynamicThresholds.z is the maximum value allowed from the bloom buffer.
#define k_dynamicThresholds		k_cui_pixel_shader_color0	// {x:min, y:max, z:clamp, w:unused}

float4 filterTex2D(in texture_sampler_2d sourceSampler, in float4 samplerTransform, in float2 texcoord)
{
	float4 color = sample2D(sourceSampler, texcoord);

	// we need alpha to be inverted so that 1.0 is transparent.  Multiply-add a scale and an offset.
	color.a = color.a * -samplerTransform.x + (1.0 - samplerTransform.y);

	// If transform.z is 0 then the sample is not alpha-premultiplied, and we don't need to do anything.
	// If transform.z is 1 then the sample is alpha-premultiplied, and we need divide by the alpha.
	color.rgb /= max(max(color.a, 0.001), 1.0 - samplerTransform.z);

	return color;
}

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	// Read the source color and bloom color
	float4 color = filterTex2D(source_sampler0, k_cui_sampler0_transform, input.texcoord);
	float2 bloomCoord = input.screenPos.xy * float2(0.5, -0.5) + float2(0.5, 0.5);
	float4 bloomSample = sample2D(source_sampler2, transform_texcoord(bloomCoord, psBloomTransform));

	// Tint and premultiply the source color
	color *= cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color);
	color.rgb *= color.a;

	// Calculate a blend factor which can be used to darken the dest color. All cui shaders output premultiplied alpha
	// so we can darken the dest color simply by modifying the a channel.
	// The blend factor is calculated by comparing the bloom buffer sample with a predetermined range. The blend
	// factor ranges from 0.0 to '> 1.0', based on the predetermined range.
	float blendFactor = max((min(bloomSample.a, k_dynamicThresholds.z) - k_dynamicThresholds.x) / (k_dynamicThresholds.y-k_dynamicThresholds.x), 0.0f);
	color.a *= blendFactor;

	color.a = 1.0 - color.a;
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
