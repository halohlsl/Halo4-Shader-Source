//
// File:	 srf_special_peterson.fx
// Author:	 hocoulby
// Date:	 02/12/12
//
// Simple surface shader with only a normal map and specualr to be used with additive blend mode set on material tag.
//
// Copyright (c) 343 Industries. All rights reserved.


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

//  Samplers
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
//Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power,		"Specular Power White", "", 0, 1, float(0.01));
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
	shader_data.common.albedo.rgb = 1.0f;
	shader_data.common.albedo.a = 1.0f;
	
	// Sample normal map.   
 	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo  = shader_data.common.albedo;

	float3 specular = 0.0f;
	float power = calc_roughness(specular_power);
	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, albedo.a, power);

	specular *= specular_color * specular_intensity;
	
    //.. Finalize Output Color
    float4 out_color = 1.0f;
    out_color.rgb = specular;
	out_color.a = 1.0f;//saturate(specular);
	
	return out_color;
}


#include "techniques.fxh"