#define PARTICLE_EXTRA_INTERPOLATOR
#define RENDER_DISTORTION

#include "fx/particle_core.fxh"

DECLARE_SAMPLER(alpha_map, "Alpha Texture", "Alpha Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(distortion_map_a, "Distortion Map A", "Noise Map A", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(distortion_map_b, "Distortion Map B", "Noise Map B", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(distortion_a_slide_u, "Distortion Map A Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distortion_a_slide_v, "Distortion Map A Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distortion_b_slide_u, "Distortion Map B Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distortion_b_slide_v, "Distortion Map B Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"

DECLARE_VERTEX_BOOL_WITH_DEFAULT(distortion_map_random_offset, "Distortion Random Offset", "", true);
#include "next_vertex_bool_parameter.fxh"

float4 PixelComputeDisplacement(
	in s_particle_interpolated_values particleValues)
{
	float4 color;

	float4 distortionA = sample2D(distortion_map_a,
	 transform_texcoord(particleValues.texcoord_billboard, distortion_map_a_transform) + (particleValues.custom_value2.xy + float2(distortion_a_slide_u, distortion_a_slide_v) * ps_time.x));
	float4 distortionB = sample2D(distortion_map_b,
	 transform_texcoord(particleValues.texcoord_billboard, distortion_map_b_transform) + (particleValues.custom_value2.zw + float2(distortion_b_slide_u, distortion_b_slide_v) * ps_time.x));
	
	float alpha = sample2D(alpha_map, transform_texcoord(particleValues.texcoord_billboard, alpha_map_transform)).a;
	
	color = (distortionA + distortionB) / 2.0f;
	float4 neutral = float4(0.0f, 0.0f, 0.0f, 0.0f);
	color = lerp(neutral, color, alpha);

	return color;
}

void FillExtraInterpolator(
	in s_particle_memexported_state state,
	inout s_particle_interpolated_values particleValues)
{
	particleValues.custom_value2 = (distortion_map_random_offset ? state.m_random2 : float4(0.0f, 0.0f, 0.0f, 0.0f));
}

#include "fx/particle_techniques.fxh"