//
// File:	 screen/base.fx
// Author:	 adamgold
// Date:	 1/23/12
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "core/core_vertex_types.fxh"
#include "base_registers.fxh"

#if defined (NO_WARP)
	#define CALC_WARP calc_warp_none
#endif

#if !defined(CALC_WARP)
	#define CALC_WARP calc_warp_screen_space
#endif

#if defined NORMAL_EDGE_SHADE
	#define CALC_BASE calc_base_normal_map_edge_shade
#endif

#if !defined(CALC_BASE)
	#define CALC_BASE calc_base_single_screen_space
#endif

#define CALC_OVERLAY_B(type, stage) calc_overlay_##type(color, texcoord, detail_map, detail_map_transform)

#if !defined (DETAIL_SCREEN_SPACE)
	#define CALC_OVERLAY_A(type, stage) CALC_OVERLAY_B(type, stage)
#endif

#if !defined(OVERLAY_A_TYPE) && !defined(DETAIL_SCREEN_SPACE)
	#define OVERLAY_A_TYPE none
#elif defined(DETAIL_SCREEN_SPACE)
	#define OVERLAY_A_TYPE detail_screen_space

	DECLARE_FLOAT_WITH_DEFAULT(detail_fade, 		"Detail Fade", "", 0, 1, float(1));
	#include "used_float.fxh"

	DECLARE_FLOAT_WITH_DEFAULT(detail_multiplier, 	"Detail Multiplier", "", 0, 10, float(4.59479));
	#include "used_float.fxh"

	#define CALC_OVERLAY_A(type, stage) calc_overlay_##type(color, texcoord, detail_map, detail_map_transform, detail_fade, detail_multiplier)
#endif


#if !defined(OVERLAY_B_TYPE)
	#define OVERLAY_B_TYPE none
#endif


#if !defined(BLEND_MODE_ADDITIVE) && !defined(BLEND_MODE_ALPHA_BLEND)
	#define BLEND_MODE_OPAQUE
#endif


#ifndef LDR_ALPHA_ADJUST
	#ifdef pc
		#define LDR_ALPHA_ADJUST 1.0f
	#else
		#define LDR_ALPHA_ADJUST 1.0f/32.0f
	#endif
#endif


DECLARE_SAMPLER(color_map, 			"Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/color_black_alpha_black.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER(warp_map, 			"Warp Map", "Warp Map", "shaders/default_bitmaps/bitmaps/color_black_alpha_black.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER(normal_map, 		"Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(detail_map, 		"Detail Map", "Detail Map", "shaders/default_bitmaps/bitmaps/color_black_alpha_black.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER(palette_map, 		"Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float4 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 1.0, 1.0);
	output.texcoord.xy=	input.texcoord;
	output.texcoord.zw=	transform_texcoord(output.texcoord.xy,		vs_screenspace_to_pixelspace_xform);
	return output;
}

float2 get_screen_space(float4 texcoord)
{
	return texcoord.xy;
}

//////////////////////////////////////////////////////////////////////
// WARP
//////////////////////////////////////////////////////////////////////
float4 calc_warp_none(in float4 originalTexcoord)
{
	return originalTexcoord;
}

#if !defined (NO_WARP)
	DECLARE_FLOAT_WITH_DEFAULT(warp_amount, 			"Warp Amount", "", 0, 1, float(1));
	#include "used_float.fxh"

	float4 apply_warp(float4 texcoord, float2 warp)
	{
		texcoord.xy += warp;
		texcoord.zw += warp * ps_screenspace_to_pixelspace_xform.xy;

		return texcoord;
	}

	float4 calc_warp_screen_space(in float4 original_texcoord)
	{
		float2 warp=	sample2D(warp_map, transform_texcoord(get_screen_space(original_texcoord), warp_map_transform)).xy;

		warp *= warp_amount;

		return apply_warp(original_texcoord, warp);
	}
#endif

//////////////////////////////////////////////////////////////////////
// BASE
//////////////////////////////////////////////////////////////////////
float4 calc_base_single_screen_space(in float4 texcoord)
{
	float4	base=	sample2D(color_map,   transform_texcoord(get_screen_space(texcoord), color_map_transform));
	return	base;
}

#if defined NORMAL_EDGE_SHADE
	DECLARE_FLOAT_WITH_DEFAULT(palette_v, 			"Palette V", "", 0, 11, float(1));
	#include "used_float.fxh"

	float4 calc_base_normal_map_edge_shade(in float4 texcoord)
	{
		float4	world_relative=	mul(float4(texcoord.zw, 0.2f, 1.0f), transpose(ps_pixel_to_world_relative));
		world_relative.xyz=	normalize(world_relative.xyz);

		float3	normal=			sample2D(normal_map,	transform_texcoord(texcoord.xy,	normal_map_transform)).rgb * 2.0 - 1.0;
		float2	palette_coord=	float2(-dot(normal, world_relative.xyz), palette_v);
		float4	base=			sample2D(palette_map, palette_coord);

		return base;
	}
#endif

#if defined MOTION_SUCK
#if !defined(MOTION_SUCK_TAP_COUNT)
#define MOTION_SUCK_TAP_COUNT 6
#endif // !defined(MOTION_SUCK_TAP_COUNT)

	DECLARE_FLOAT_WITH_DEFAULT(motion_suck_distance, "Motion Suck Distance", "", -1, 1, float(.05));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(motion_suck_strength, "Motion Suck Strength", "", 0, 1, float(.75));
	#include "used_float.fxh"

	float4 calc_base_motion_suck(in float4 texcoord)
	{
#if defined(xenon) || (DX_VERSION == 11)
		float2 pixelDelta = (texcoord.xy - float2(0.5, 0.5)) * motion_suck_distance;

		float4 base = {0, 0, 0, 1};
#ifdef xenon
		asm {
			tfetch2D base.xyz_, texcoord.xy, color_map, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled, UseComputedLOD = false
		};
#else
		base.xyz = sample2D(color_map, texcoord.xy);
#endif
		float multiplier = 1.0;

		[unroll]
		for (int i = 0; i < MOTION_SUCK_TAP_COUNT; ++i)
		{
			texcoord.xy += pixelDelta;
			multiplier *= motion_suck_strength;
			float3 sample;
#ifdef xenon
			asm {
				tfetch2D sample.xyz_, texcoord.xy, color_map, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled, UseComputedLOD = false
			};
#else
			sample.xyz = sample2D(color_map, texcoord.xy);
#endif
			base += float4(sample * multiplier, multiplier);
		}

		base /= base.w;

		return base;
#else // xenon
		return calc_base_single_screen_space(texcoord);
#endif
	}
#endif // defined MOTION_SUCK

//////////////////////////////////////////////////////////////////////
// OVERLAY
//////////////////////////////////////////////////////////////////////
float4 calc_overlay_none(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform)
{
	return color;
}

#if defined(USING_TINT_ADD)
	DECLARE_RGB_COLOR_WITH_DEFAULT(tint_color,			"Tint Color", "", float3(1,1,1));
	#include "used_float3.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(tint_color_alpha,			"Tint Color Alpha", "", 0, 1, float(1.0));
	#include "used_float.fxh"

	DECLARE_RGB_COLOR_WITH_DEFAULT(add_color,			"Tint Color", "", float3(0,0,0));
	#include "used_float3.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(add_color_alpha,			"Add Color Alpha", "", 0, 1, float(0.0));
	#include "used_float.fxh"

	float4 calc_overlay_tint_add_color(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform)
	{
		return color * float4(tint_color.xyz, tint_color_alpha) + float4(add_color.xyz, add_color_alpha);
	}
#endif

float4 calc_overlay_detail_screen_space(in float4 color, in float4 texcoord, texture_sampler_2d detail_map, in float4 detail_map_xform, in float detail_fade, in float detail_multiplier)
{
	float4 detail=	sample2D(detail_map, transform_texcoord(get_screen_space(texcoord), detail_map_xform));
	detail.rgb *= detail_multiplier;
	detail=	lerp(1.0f, detail, detail_fade);
	return color * detail;
}

//////////////////////////////////////////////////////////////////////
// FADE
//////////////////////////////////////////////////////////////////////
#if defined(BLEND_MODE_ADDITIVE) || defined(BLEND_MODE_ALPHA)
	DECLARE_FLOAT_WITH_DEFAULT(fade, 				"Fade", "", 0, 1, float(1));
	#include "used_float.fxh"
#endif

float4 calc_fade_out(in float4 color)
{
#if defined(BLEND_MODE_ADDITIVE) || defined(BLEND_MODE_ALPHA)
	#if defined(BLEND_MODE_ADDITIVE)
		color.rgba *= fade;
	#elif defined(BLEND_MODE_ALPHA)
		color.a *= fade;
	#endif

	// we don't really need to do this if the blend mode is opaque, since alpha won't affect the end result
	color.a= 			color.a * LDR_ALPHA_ADJUST;
#endif

	return color;
}

//////////////////////////////////////////////////////////////////////
// PS
//////////////////////////////////////////////////////////////////////
float4 default_ps(
	in float4 screenPosition : SV_Position,
	in float4 originalTexcoord : TEXCOORD0) : SV_Target
{
	float4 texcoord=	CALC_WARP(originalTexcoord);

	float4 color=		CALC_BASE(texcoord);
	color=				CALC_OVERLAY_A(OVERLAY_A_TYPE, a);
	color=				CALC_OVERLAY_B(OVERLAY_B_TYPE, b);

	color=				calc_fade_out(color);

	return color;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}