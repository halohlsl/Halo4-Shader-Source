//
// File:	 surface_animated_palettized.fx
// Author:	 willclar
// Date:	 10/28/2011
//
// Surface FX Shader - Emulates particle_palettized, and allows animated 3D textures
//
// Copyright (c) 343 Industries. All rights reserved.
//
//
#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"

// Texture Samplers
DECLARE_SAMPLER_2D_ARRAY(base_map, "Base Map", "Base Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(base_map_frame_index, "Base Map Frame Index", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(palette_v_coord, "Palette V Coord", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_multiplier, "Alpha Multiplier", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(self_illum_intensity, "Self Illum Intensity", "", 0, 1, float(0.0));
#include "used_float.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	// Sample base map.

	float3 base_map_texcoord = float3(transform_texcoord(uv, base_map_transform), base_map_frame_index);
#if DX_VERSION == 11
	float4 base = sampleArrayWith3DCoords(base_map, base_map_texcoord);
#else
	float4 base = sample3DGamma(base_map, base_map_texcoord);
#endif
	
	float2 paletteCoord = float2(base.r, palette_v_coord);
	float4 paletteValue = sample2DGamma(palette, paletteCoord);

  // composite
  shader_data.common.albedo = float4(paletteValue.rgb, base.a);
  shader_data.common.albedo.a *= alpha_multiplier;
  
	shader_data.common.selfIllumIntensity = self_illum_intensity;
}

// lighting
float4 pixel_lighting(in s_pixel_shader_input pixel_shader_input, inout s_shader_data shader_data)
{
	// input from s_shader_data
	float4 albedo = shader_data.common.albedo;

	//.. Finalize Output Color
	float4 out_color = albedo;
	return out_color;
}

#include "techniques.fxh"
