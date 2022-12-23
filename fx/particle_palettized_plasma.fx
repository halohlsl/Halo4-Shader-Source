#define PARTICLE_EXTRA_INTERPOLATOR

#include "fx/particle_core.fxh"

DECLARE_SAMPLER_2D_ARRAY(alphaMap, "Alpha Texture", "Alpha Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(paletteMap, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(noiseMapA, "Noise Map A", "Noise Map A", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(noiseMapB, "Noise Map B", "Noise Map B", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(noiseASlideU, "Noise Map A Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noiseASlideV, "Noise Map A Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noiseBSlideU, "Noise Map B Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noiseBSlideV, "Noise Map B Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(paletteValueMultiplier, "Palette Value Multiplier", "", 0, 5, float(1.0));
#include "used_float.fxh"

DECLARE_BOOL_WITH_DEFAULT(depthFadeAsPaletteV, "Depth Fade as Palette V", "", false);
#include "next_bool_parameter.fxh"

DECLARE_VERTEX_BOOL_WITH_DEFAULT(distortion_map_random_offset, "Distortion Random Offset", "", true);
#include "next_vertex_bool_parameter.fxh"

// do the color shuffle
float4 pixel_compute_color(
	in s_particle_interpolated_values particleValues,
	in float2 sphereWarp,
	in float depthFade)
{
	float4 color;

	float noiseA = sample2D(noiseMapA, transform_texcoord(particleValues.texcoord_billboard, noiseMapA_transform) + (particleValues.custom_value2.xy + float2(noiseASlideU, noiseASlideV) * ps_time.x)).r;
	float noiseB = sample2D(noiseMapB, transform_texcoord(particleValues.texcoord_billboard, noiseMapB_transform) + (particleValues.custom_value2.zw + float2(noiseBSlideU, noiseBSlideV) * ps_time.x)).r;
	
	float alpha;
	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particleValues.texcoord_billboard, alphaMap_transform), particleValues.texcoord_sprite0.x);
#if DX_VERSION == 11
		alpha = sampleArrayWith3DCoordsGamma(alphaMap, texcoord).a;
#else
		alpha = sample3DGamma(alphaMap, texcoord).a;
#endif
	}
	else
	{
		// old-school
		float3 texcoord = float3(transform_texcoord(particleValues.texcoord_sprite0, alphaMap_transform), 0.0);
		alpha = sample3DGamma(alphaMap, texcoord).a;
	}
	
	float paletteCoord = depthFadeAsPaletteV ?
		abs(noiseA - noiseB) :
		(saturate(abs(noiseA - noiseB) + (1 - alpha * depthFade * particleValues.color.a) * paletteValueMultiplier));

	color = sample2D(paletteMap, float2(paletteCoord, depthFadeAsPaletteV ? depthFade : particleValues.palette));
	color.a = alpha;

	return color;
}

void FillExtraInterpolator(
	in s_particle_memexported_state state,
	inout s_particle_interpolated_values particleValues)
{
	particleValues.custom_value2 = (distortion_map_random_offset ? state.m_random2 : float4(0.0f, 0.0f, 0.0f, 0.0f));
}

#include "fx/particle_techniques.fxh"