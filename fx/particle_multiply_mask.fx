#include "fx/particle_core.fxh"

DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(maskA, "Mask A", "Mask A", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(maskB, "Mask B", "Mask B", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(basemapSlideU, "Base Texture Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(basemapSlideV, "Base Texture Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskASlideU, "Mask A Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskASlideV, "Mask A Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskBSlideU, "Mask B Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskBSlideV, "Mask B Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"

// do the color shuffle
float4 pixel_compute_color(
	in s_particle_interpolated_values particle_values,
	in float2 sphereWarp,
	in float depthFade)
{
	float4 color;
	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_billboard + sphereWarp, basemap_transform) + (float2(basemapSlideU, basemapSlideV) * ps_time.x), particle_values.texcoord_sprite0.x);
#if DX_VERSION == 11
		color = sampleArrayWith3DCoordsGamma(basemap, texcoord);
#else
		color = sample3DGamma(basemap, texcoord);
#endif
	}
	else
	{
		// old-school
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_sprite0 + sphereWarp, basemap_transform) + (float2(basemapSlideU, basemapSlideV) * ps_time.x), 0.0);
		color = sample3DGamma(basemap, texcoord);
	}

	color.a *= sample2D(maskA, transform_texcoord(particle_values.texcoord_billboard, maskA_transform) + (float2(maskASlideU, maskASlideV) * ps_time.x)).r;
	color.a *= sample2D(maskB, transform_texcoord(particle_values.texcoord_billboard, maskB_transform) + (float2(maskBSlideU, maskBSlideV) * ps_time.x)).r;

	return color;
}

#include "fx/particle_techniques.fxh"