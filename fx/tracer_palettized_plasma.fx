#include "fx/tracer_core.fxh"

DECLARE_SAMPLER(alpha_mask_map, "Alpha Mask Map", "Alpha Mask Map", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER(noise_a_map, "Noise Map A", "Noise Map A", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER(noise_b_map, "Noise Map B", "Noise Map B", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in TracerInterpolatedValues tracerValues)
{
	float alpha = sample2D(alpha_mask_map, tracerValues.texcoord.xy).a;
	float noiseA = sample2D(noise_a_map, transform_texcoord(tracerValues.texcoord.xy, noise_a_map_transform)).r;
	float noiseB = sample2D(noise_b_map, transform_texcoord(tracerValues.texcoord.xy, noise_b_map_transform)).r;

	float diff = abs(noiseA - noiseB);

	// lame -- we don't do this yet on tracers
	float depthAlpha = 1.0;

	float coordinate = saturate(diff + (1 - alpha * depthAlpha));
	float2 paletteCoord= float2(coordinate, tracerValues.palette);

	float4 color = float4(sample2DGamma(palette, paletteCoord).rgb, alpha);
	return color;
}

#include "fx/tracer_techniques.fxh"