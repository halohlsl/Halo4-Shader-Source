#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_shearIntensity k_cui_pixel_shader_scalar0
#define k_shearPaneHeight k_cui_pixel_shader_scalar1
#define k_noiseOffset k_cui_pixel_shader_scalar2
#define k_noiseSparsity k_cui_pixel_shader_scalar3
#define k_noiseTiling k_cui_pixel_shader_scalar4

#define k_noiseSampler source_sampler1

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	const float normalizedShearHeight = k_shearPaneHeight / k_cui_pixel_shader_pixel_size.y;
	float2 noiseCoord = float2(
		k_noiseOffset,
		floor(input.texcoord.y * k_noiseTiling / normalizedShearHeight) * normalizedShearHeight);
	float3 noiseSample = sample2D(k_noiseSampler, frac(noiseCoord));

	float noise = (noiseSample.r - 0.5) *
		step(k_noiseSparsity, noiseSample.r) *
		(k_shearIntensity / k_cui_pixel_shader_pixel_size.x);

	// Apply shearing
	float2 texcoord = input.texcoord + float2(noise, 0.0);

	// Sample from interface texture, and fade the sample based on the green channel from the noise
	float shearAlpha = lerp(1.0f, noiseSample.g, saturate(k_shearIntensity));
	float4 color = cui_tex2D(texcoord) * float4(shearAlpha.xxx, 1.0);
	color.a = 1.0 - ((1.0 - color.a) * shearAlpha);
	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color));
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
