#include "fx/tracer_core.fxh"

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in TracerInterpolatedValues tracerValues)
{
	float4 color = sample2DGamma(basemap, tracerValues.texcoord);

	return color;
}

#include "fx/tracer_techniques.fxh"