//
// File:	 srf_special_flath_blend_cheap.fx
// Author:	 wesleyg
// Date:	 8/31/12
//
// Cheaper Layered Shader - Blends two texture maps based on vert color. For the second color/normal artist has control
// over which uv set sampled with
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

DECLARE_BOOL_WITH_DEFAULT(use_uvset2, "Use Uv Set 2", "", true);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER( color_02_map, "Color Map 2", "Color Map 2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_02_map, "Normal Map 2", "Normal Map 2", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity_1, "Diffuse Intensity 1", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity_2, "Diffuse Intensity 2", "", 0, 1, float(1.0));
#include "used_float.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv= pixel_shader_input.texcoord.xy;
	float2 uv_blended = 0.0f;


	STATIC_BRANCH
	if (use_uvset2)
	{
		uv_blended = pixel_shader_input.texcoord.zw;
	} else {
		uv_blended = uv;
	}


    {// Sample color map.
	    float2 map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, map_uv);
        shader_data.common.shaderValues.x  = shader_data.common.albedo.a;

		map_uv = transform_texcoord(uv_blended, color_02_map_transform);

	    shader_data.common.albedo = lerp( shader_data.common.albedo,
										  sample2DGamma(color_02_map, map_uv),
										  shader_data.common.vertexColor.a);

		shader_data.common.albedo.a = shader_data.common.shaderValues.x;
	}

    {// Sample normal map.
    	float2 normal_1_map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, normal_map_transform);
		float3 normal_1_map = sample_2d_normal_approx(normal_map, normal_1_map_uv);

		float2 normal_2_map_uv = transform_texcoord(uv_blended, normal_02_map_transform);
		float3 normal_2_map = sample_2d_normal_approx(normal_02_map, normal_2_map_uv);

		normal_1_map = lerp(normal_1_map, float3(0,0,0), shader_data.common.vertexColor.a);
		normal_2_map = lerp(float3(0,0,0), normal_2_map, shader_data.common.vertexColor.a);

		shader_data.common.normal.xy = normal_1_map.xy + normal_2_map.xy;

		shader_data.common.normal.z = 1.0;
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }

}

float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;

    float3 diffuse = 0.0f;
	float diffuse_intensity = lerp(diffuse_intensity_1, diffuse_intensity_2, shader_data.common.vertexColor.a);

	// using lambert model
	calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
	// modulate by albedo, color, and intensity
	diffuse *= albedo.rgb * diffuse_intensity;

	//.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse;
    out_color.a   = shader_data.common.shaderValues.x;

	return out_color;
}


#include "techniques.fxh"