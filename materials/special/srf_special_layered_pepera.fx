//
// File:	 srf_lambert.fx
// Date:	 06/16/10
//
// Custom Layered Shader 
//
// Copyright (c) 343 Industries. All rights reserved.


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER_NO_TRANSFORM( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER( color_detail_map, "Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_detail_map, "Normal Detail Map", "Normal Detail Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_start,	"Detail Start Dist." , "", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_end, 	"Detail End Dist.", "", 0, 1, float(1.0));
#include "used_float.fxh"


DECLARE_SAMPLER( color_layer1_map, "Color Layer 1", "Color Layer 1", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( color_layer2_map, "Color Layer 2", "Color Layer 2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"




struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv= pixel_shader_input.texcoord.xy;

// SURFACE COLOR

    // Sample base color map.
	shader_data.common.albedo = sample2DGamma(color_map, uv);
	shader_data.common.albedo.a = 1.0;


	// computer vertex layer blend for two layers
	float4 blend = float4(0, 0, 0, 0);
    shader_data.common.vertexColor.a *= 2;
	
    if (shader_data.common.vertexColor.a < 1.0)
	{
        blend.r = shader_data.common.vertexColor.a;
    }
	else
	{
        blend.g = shader_data.common.vertexColor.a - 1.0;
        blend.r = 1.0 - blend.g;
    }
	
	
	// mix in the layers
	
	// red layer
	float2 tUv = transform_texcoord(uv, color_layer1_map_transform);
	float4 layer1  = sample2DGamma(color_layer1_map, tUv);	
	// green layer
	tUv = transform_texcoord(uv, color_layer2_map_transform);
	float4 layer2  = sample2DGamma(color_layer2_map, tUv);
	
	
	shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, layer1.rgb, blend.r);
	shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, layer2.rgb, blend.g);
	
	
	// Color detail map
	const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)
	float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
	float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
	color_detail.rgb *= DETAIL_MULTIPLIER;
	shader_data.common.albedo.rgb *= color_detail;
	
	
// SURFACE NORMAL	
	
    // Sample normal map.
	shader_data.common.normal = sample_2d_normal_approx(normal_map, uv);
	
	// detail normal 
	float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
	
	shader_data.common.normal  = CompositeDetailNormalMap(
																 shader_data.common,
																 shader_data.common.normal,
																 normal_detail_map,
																 detail_uv,
																 normal_detail_end,
																 normal_detail_start);

	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
    float3 diffuse = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
	diffuse *=  shader_data.common.albedo.rgb;

    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse;
    out_color.a   =  shader_data.common.albedo.a;

	return out_color;
}


#include "techniques.fxh"