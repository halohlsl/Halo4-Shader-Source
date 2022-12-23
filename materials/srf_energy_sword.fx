//
// File:	 srf_energy_sword.fx
// Author:	 willclar
// Date:	 02/28/12
//
// Surface Shader - Mimicking Reach's energy sword material by brute force
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME
#define DISABLE_VERTEX_COLOR

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"


DECLARE_SAMPLER(alpha_mask_map, "Alpha Mask Map", "Alpha Mask Map", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(noise_a_map, "Noise Map A", "Noise Map A", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(noise_b_map, "Noise Map B", "Noise Map B", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(palette_map, "Palette Map", "Palette Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(palette_v_coordinate, "Palette V-Coordinate", "", 0, 1, float(0.5));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_modulation_factor, "Alpha Modulation Factor", "", 0, 1, float(0.1));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(self_illum_color, "Self Illum Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(self_illum_intensity, "Self Illum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER(overlay_map, "Overlay Map", "Overlay Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(overlay_multiply_map, "Overlay Multiply Map", "Overlay Multiply Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(overlay_detail_map, "Overlay Detail Map", "Overlay Detail Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(overlay_tint, "Overlay Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay_intensity, "Overlay Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

#define DETAIL_MULTIPLIER 4.59479f

struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
}

float4 pixel_lighting(
	in s_pixel_shader_input pixel_shader_input,
	inout s_shader_data shader_data)
{
	float2 texcoord = frac(float2(1, 0) + pixel_shader_input.texcoord.xy);
	
	float noiseA = sample2D(noise_a_map, transform_texcoord(texcoord, noise_a_map_transform)).r;
	float noiseB = sample2D(noise_b_map, transform_texcoord(texcoord, noise_b_map_transform)).r;
	float index = abs(noiseA - noiseB);

	float alpha = sample2D(alpha_mask_map, transform_texcoord(texcoord, alpha_mask_map_transform)).a;

	index = saturate(index + (1 - alpha) * alpha_modulation_factor);

	float4 paletteValue = sample2D(palette_map, float2(index, palette_v_coordinate));

	float3 outputColor = paletteValue.rgb * self_illum_color.rgb * self_illum_intensity;

	float4 overlay = sample2D(overlay_map, transform_texcoord(texcoord, overlay_map_transform));
	float4 overlayDetail = sample2D(overlay_detail_map, transform_texcoord(texcoord, overlay_detail_map_transform));

	outputColor += overlay.rgb * overlayDetail.rgb * DETAIL_MULTIPLIER * overlay_tint.rgb * overlay_intensity;
	
	outputColor.rgb *= sample2D(overlay_multiply_map, transform_texcoord(texcoord, overlay_multiply_map_transform)).rgb;
	
	shader_data.common.selfIllumIntensity = self_illum_intensity;

	return float4(outputColor, 1.0);
}


#include "techniques.fxh"