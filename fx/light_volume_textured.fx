#include "fx/light_volume_core.fxh"

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in LightVolumeInterpolatedValues lightVolumeValues)
{
	float4 color = sample2DGamma(basemap, lightVolumeValues.texcoord);
	return color;
}

#include "fx/light_volume_techniques.fxh"