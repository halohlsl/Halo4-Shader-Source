//
// File:	 srf_constant.fx
// Author:	 hocoulby
// Date:	 04/26/2011
//
// Surface FX Shader - Cinematic vertical slice screen fx shader (requested by Jon Wood)
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
DECLARE_SAMPLER_3D( base_map, "Base Map", "Base Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT( base_map_frame_index, "Base Map Frame Index", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_SAMPLER( screenA_map, "Screen Breakup A", "Screen Breakup A", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( screenB_map, "Screen Breakup B", "Screen Breakup B", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"


DECLARE_BOOL_WITH_DEFAULT(wireframe_outline, "Wireframe Outline", "", false);
#include "next_bool_parameter.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv    		= pixel_shader_input.texcoord.xy;

    // Sample base map.

    float3 base_map_uv 	= float3(transform_texcoord(uv, float4(1, 1, 0, 0)), base_map_frame_index);
    float3 base         = sample3DGamma(base_map, base_map_uv).rgb;

    // sample screen breakup map A
    float2 screenA_uv = transform_texcoord( uv, screenA_map_transform);
    float4 screenA = sample2DGamma(screenA_map, screenA_uv);

    // sample screen breakup map B
    float2 screenB_uv = transform_texcoord( uv, screenB_map_transform);
    float4 screenB = sample2DGamma(screenB_map, screenB_uv);

    // composite
    shader_data.common.albedo.rgb = (screenA.rgb * screenB.rgb) + base;

	shader_data.common.albedo.rgb *= albedo_tint;
    shader_data.common.albedo.a = 1.0f;
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
#if defined(xenon)
	if (wireframe_outline)
	{
		pixel_pre_lighting(pixel_shader_input, shader_data);
	}
#endif

    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo ;

     //.. Finalize Output Color
    float4 out_color = albedo;

	return out_color;
}


#include "techniques.fxh"
