//
// File:	 srf_glass_simple.fx
// Author:	 aluedke
// Date:	 11/09/2011
//
// Surface Shader - Glass (simplified)
//
// Copyright (c) 343 Industries. All rights reserved.
//

#define DISABLE_TANGENT_FRAME


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"

struct s_shader_data {
	s_common_shader_data common;

	float3 reflection;
    float  alpha;

};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv					= pixel_shader_input.texcoord.xy;

	float2 color_map_uv			= transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo	= sample2DGamma(color_map, uv);
	shader_data.alpha			= shader_data.common.albedo.a;
	shader_data.common.albedo.a	= 1.0f;

	shader_data.common.normal	= shader_data.common.geometricNormal;
}




float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;

    float3 diffuse = 1.0f;
    calc_simple_lighting(diffuse, shader_data.common);

	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{ // sample reflection cube map
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view, normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);
		reflection = reflectionMap.rgb * reflection_intensity * reflection_color;
        shader_data.reflection = reflection;
	}

    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = (diffuse * color_screen(reflection, albedo));

	//.. Finalize Alpha
	out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"