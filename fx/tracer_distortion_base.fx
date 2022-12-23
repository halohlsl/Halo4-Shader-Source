#define RENDER_DISTORTION

#include "fx/tracer_core.fxh"

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

float4 PixelComputeDisplacement(
	in TracerInterpolatedValues tracerValues)
{
	float4 color = sample2D(basemap, tracerValues.texcoord);

	return color;
}

#include "fx/tracer_techniques.fxh"
