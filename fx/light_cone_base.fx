#include "core/core.fxh"

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in float2 texcoord)
{
	float4 color;
	
	color = sample2DGamma(basemap, transform_texcoord(texcoord, basemap_transform));

	return color;
}

#include "fx/light_cone_techniques.fxh"