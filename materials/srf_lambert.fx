//
// File:	 srf_lambert.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Standard Lambert with self illumination
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


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


struct s_shader_data
{
	s_common_shader_data common;
    float alpha;

};


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv= pixel_shader_input.texcoord.xy;

    {// Sample color map.
	    float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
        shader_data.alpha = shader_data.common.albedo.a;

        shader_data.common.albedo.rgb *= albedo_tint.rgb;
		shader_data.common.albedo.a = shader_data.alpha;
	}


    {// Sample normal map.
    	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
    	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
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
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }


    //.. Finalize Output Color
    float4 out_color;

    out_color.rgb = diffuse;
    out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"