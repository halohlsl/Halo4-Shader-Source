//
// File:	 decals/base.fx
// Author:	 aluedke
// Date:	 03/21/11
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

#define DISABLE_VERTEX_COLOR
#define DISABLE_VIEW_VECTOR

#define DECAL_DISABLE_TEXCOORD_CLIP
#define DECAL_OUTPUT_COLOR

#if !defined(DECAL_OUTPUT_NORMAL)
#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME
#endif


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

#include "../explicit_shaders/utility/player_emblem.fxh"


//.. Artistic Parameters
#if defined(PATCHY_EMBLEM)

DECLARE_SAMPLER(alpha_map, "Alpha Map", "Alpha Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_min,			"Alpha Max", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_max,			"Alpha Min", "", 0, 1, float(1.0));
#include "used_float.fxh"

#endif

struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	float4 emblem = calc_emblem(uv, true);

#if defined(PATCHY_EMBLEM)
	float alpha = sample2D(alpha_map, uv).a;
	alpha = saturate(lerp(alpha_min, alpha_max, alpha));
#else
	float alpha = 1.0f;
#endif

	shader_data.common.albedo = float4(emblem.rgb, (1.0f - emblem.a) * alpha);
}


#define DECAL_IS_EMBLEM

#include "techniques_decals.fxh"