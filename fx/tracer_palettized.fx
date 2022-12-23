#include "fx/tracer_core.fxh"

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
	
DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(paletteTextureSuppliesAlpha, "Palette Texture Supplies Alpha", "", false);
#include "next_bool_parameter.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in TracerInterpolatedValues tracerValues)
{
	float4 color = sample2DPalettizedScrolling(basemap, palette, tracerValues.texcoord, tracerValues.palette, paletteTextureSuppliesAlpha);

	return color;
}

#include "fx/tracer_techniques.fxh"