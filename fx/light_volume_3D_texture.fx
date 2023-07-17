// make some special case code happen on the VS
#define LIGHT_VOLUME_3D_TEXTURE

#include "fx/light_volume_core.fxh"

DECLARE_SAMPLER_3D(volumeMap, "Volume Texture", "Volume Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in LightVolumeInterpolatedValues lightVolumeValues)
{
	float3 texcoord = float3(lightVolumeValues.texcoord, lightVolumeValues.volumeTexcoordZ);
	float4 color = sample3DGamma(volumeMap, texcoord);

	if (texcoord.x > 1 || texcoord.x < 0 ||
		texcoord.y > 1 || texcoord.y < 0 ||
		texcoord.z > 1 || texcoord.z < 0)
	{
		color.a = 0.0f;
	}

	return color;
}

#include "fx/light_volume_techniques.fxh"