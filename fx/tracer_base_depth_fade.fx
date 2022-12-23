#define TRACER_DEPTH

#include "fx/tracer_core.fxh"
#include "depth_fade.fxh"

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in TracerInterpolatedValues tracerValues,
	float2 fragmentPosition)
{
	float4 color = sample2DGamma(basemap, tracerValues.texcoord);

#if defined(xenon)
	float depthFade = ComputeDepthFade(fragmentPosition * psDepthConstants.z, tracerValues.depth);
	color.a *= depthFade;
#endif

	return color;
}

#include "fx/tracer_techniques.fxh"