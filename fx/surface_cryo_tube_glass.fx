//
// File:	 surface_cryo_tube_glass.fx
// Author:	 willclar
// Date:	 10/31/2011
//
// Surface FX Shader - Cryo tube glass for chief's cryo tube
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
DECLARE_SAMPLER(base_map, "Base Map", "Base Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_white_point, "Alpha White Point", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_black_point, "Alpha Black Point", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(palette_v_coord_texture, "Palette V-Coord Texture", "Palette V-Coord Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(palette_v_coord_scale, "Palette V Coord Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(palette_v_coord_offset, "Palette V Coord Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_multiplier, "Alpha Multiplier", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(color_multiplier, "Color Multiplier", "", float3(1.0, 1.0, 1.0));
#include "used_float3.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

// Specialized routine for smoothly fading out transparents.  Maps
//		[0, black_point] to 0
//		[black_point, mid_point] to [0, 1 - (white_point - mid_point)] linearly
//		[mid_point, white_point] to [1 - (white_point - mid_point), 1] linearly (identity-like)
// where mid_point is halfway between black_point and white_point
//
//		|                   *******
//		|                 **
//		|               **
//		|             **
//		|            *
//		|           *
//		|          *
//		|         *
//		|        *
//		|       *
//		|*******___________________
//      0      bp     mp    wp    1
float ApplyBlackPointAndWhitePoint(float blackPoint, float whitePoint, float alpha)
{
	float midPoint = (whitePoint + blackPoint) / 2.0;
	
	if (alpha > midPoint)
	{
		return 1 - saturate(whitePoint - alpha);		
	}
	else
	{
		return saturate((alpha - blackPoint) / (midPoint - blackPoint)) * (1 - whitePoint + midPoint);
	}
}

void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	// Sample base map.
	float4 base = sample2DGamma(base_map, uv);
	float paletteV = sample2DGamma(palette_v_coord_texture, uv);
	paletteV *= palette_v_coord_scale;
	paletteV += palette_v_coord_offset;
	
	float2 paletteCoord = float2(base.r, paletteV);
	float4 paletteValue = sample2DGamma(palette, paletteCoord);
	
	float alpha = ApplyBlackPointAndWhitePoint(alpha_black_point, alpha_white_point, base.a);

  // composite
  shader_data.common.albedo = float4(paletteValue.rgb * color_multiplier, alpha * alpha_multiplier);
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
