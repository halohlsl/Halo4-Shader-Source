//
// File:	 srf_micron_halogram.fx
// Author:	 micron
// Date:	 10/30/11
//
// Surface Shader - Halogram - Generic
//
// Copyright (c) 343 Industries. All rights reserved.
//
//
//

// Libraries
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Samplers
DECLARE_SAMPLER(base_map, "Base Map", "Base Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

DECLARE_BOOL_WITH_DEFAULT(uv_space_mask_1_enabled, "UV-Space Mask 1 Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(uv_space_mask_1, "UV-Space Mask 1", "uv_space_mask_1_enabled", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(uv_space_mask_2_enabled, "UV-Space Mask 2 Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(uv_space_mask_2, "UV-Space Mask 2", "uv_space_mask_2_enabled", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_BOOL_WITH_DEFAULT(world_space_mask_1_enabled, "World-Space Mask 1 Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(world_space_mask_1, "World-Space Mask 1", "world_space_mask_1_enabled", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(world_space_mask_1_v_coordinate, "World-Space Mask 1 V-Coordinate", "world_space_mask_1_enabled", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_BOOL_WITH_DEFAULT(world_space_mask_2_enabled, "World-Space Mask 2 Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(world_space_mask_2, "World-Space Mask 2", "world_space_mask_2_enabled", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(world_space_mask_2_v_coordinate, "World-Space Mask 2 V-Coordinate", "world_space_mask_2_enabled", 0, 1, float(0.1));
#include "used_float.fxh"

DECLARE_BOOL_WITH_DEFAULT(screen_space_mask_1_enabled, "Screen-Space Mask 1 Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(screen_space_mask_1, "Screen-Space Mask 1", "screen_space_mask_1_enabled", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(screen_space_mask_2_enabled, "Screen-Space Mask 2 Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(screen_space_mask_2, "Screen-Space Mask 2", "screen_space_mask_2_enabled", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(tint,"Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensity, "Intensity", "", 0, 5, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(fresnel_color,"Fresnel Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,"Fresnel Intensity", "", 0, 1, float(0.25));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,"Fresnel Power", "", 0, 20, float(1));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_multiplier,"Alpha Multiplier", "", 0, 1, float(1));
#include "used_float.fxh"

struct s_shader_data {
	s_common_shader_data common;
	SCREEN_POSITION_INPUT(vPos);
};

float SampleUvSpace(texture_sampler_2d map, float4 transform, in s_pixel_shader_input pixel_shader_input)
{
	return sample2D(map, transform_texcoord(pixel_shader_input.texcoord.xy, transform)).r;
}

float SampleWorldSpace(texture_sampler_2d map, float4 transform, in s_shader_data shader_data)
{
	return sample2D(map, transform_texcoord(float2(shader_data.common.position.z, 0.0f), transform)).r;
}

float SampleScreenSpace(texture_sampler_2d map, float4 transform, in s_shader_data shader_data)
{
#if defined(xenon) || (DX_VERSION == 11)
	return sample2D(map, transform_texcoord(shader_data.common.platform_input.fragment_position.xy / 1000.0, transform)).r;
#else // defined(xenon)
	return 1;
#endif // defined(xenon)
}

#if defined(cgfx)
#define BRANCH
#else
#define BRANCH [branch]
#endif

// pre lighting
void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	float2 base_map_uv = transform_texcoord(uv, base_map_transform);
	shader_data.common.albedo = sample2DGamma(base_map, base_map_uv);
	shader_data.common.albedo.a = alpha_multiplier;
	
	BRANCH
	if (uv_space_mask_1_enabled)
	{
		shader_data.common.albedo.a *= SampleUvSpace(uv_space_mask_1, uv_space_mask_1_transform, pixel_shader_input);
	}
	BRANCH
	if (uv_space_mask_2_enabled)
	{
		shader_data.common.albedo.a *= SampleUvSpace(uv_space_mask_2, uv_space_mask_2_transform, pixel_shader_input);
	}
	
	BRANCH
	if (world_space_mask_1_enabled)
	{
		shader_data.common.albedo.a *= SampleWorldSpace(world_space_mask_1, world_space_mask_1_transform, shader_data);
	}
	BRANCH
	if (world_space_mask_2_enabled)
	{
		shader_data.common.albedo.a *= SampleWorldSpace(world_space_mask_2, world_space_mask_2_transform, shader_data);
	}
	
	BRANCH
	if (screen_space_mask_1_enabled)
	{
		shader_data.common.albedo.a *= SampleScreenSpace(screen_space_mask_1, screen_space_mask_1_transform, shader_data);
	}
	BRANCH
	if (screen_space_mask_2_enabled)
	{
		shader_data.common.albedo.a *= SampleScreenSpace(screen_space_mask_2, screen_space_mask_2_transform, shader_data);
	}
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	inout s_shader_data shader_data)
{
	float4 out_color = shader_data.common.albedo;

	out_color.rgb *= intensity;
	out_color.rgb *= tint;
	
	float fresnel = fresnel_intensity * pow(saturate(1.0 - dot(pixel_shader_input.normal, -shader_data.common.view_dir_distance.xyz)), fresnel_power);
	
	out_color.rgb += fresnel * fresnel_color;
	
	shader_data.common.albedo = out_color;
	
	return out_color;
}


#include "techniques.fxh"
