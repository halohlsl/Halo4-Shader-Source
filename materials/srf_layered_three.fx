//
// File:	 srf_layered_three.fx
// Author:	 hocoulby
// Date:	 08/20/10
//
// Surface Shader - A layered shader that mixes three maps.
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//....Settings
#define BLENDED_MATERIAL

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( blend_map, "Blend Map RGB", "Blend Map RGB", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

// Red Layer
	// colormap

DECLARE_SAMPLER( r_color, "Red - Color Map", "Red - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(r_color_tint,	"Red - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
	// specular
DECLARE_SAMPLER( r_spec, "Red - Specular Map", "Red - Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
	// normalmap
DECLARE_SAMPLER( r_normal, "Red - Normal Map", "Red - Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Green Layer
	// color map
DECLARE_SAMPLER( g_color, "Green - Color Map", "Green - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(g_color_tint,	"Green - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
	// specular
DECLARE_SAMPLER( g_spec, "Green - Specular Map", "Green - Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
	// normalmap
DECLARE_SAMPLER( g_normal, "Green - Normal Map", "Green - Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Blue Layer
	// color
DECLARE_SAMPLER( b_color, "Blue - Color Map", "Blue - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(b_color_tint,	"Blue - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
	// specular
DECLARE_SAMPLER( b_spec, "Blue - Specular Map", "Blue - Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
	// normal
DECLARE_SAMPLER( b_normal, "Blue - Normal Map", "Blue - Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

// specular control
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Detail Normal Map
DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "", 0, 1, float(1.0));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;

};


float4 sample2DGamma(texture_sampler_2d map, float2 uv, float4 transform){
	return sample2DGamma(map, transform_texcoord(uv, transform));
}

float3 sample2DNormal(texture_sampler_2d map, float2 uv, float4 transform){
	return sample_2d_normal_approx(map, transform_texcoord(uv, transform));
}



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;

	// sample blend map
	float4 blend   = sample2D(blend_map, uv, float4(1,1,0,0));

// Albedo
	float4 color_r = sample2DGamma(r_color, uv, r_color_transform);
	float4 color_g = sample2DGamma(g_color, uv, g_color_transform);
	float4 color_b = sample2DGamma(b_color, uv, b_color_transform);

	shader_data.common.albedo.rgb = ((color_r.rgb * r_color_tint) * blend.r) +
								    ((color_g.rgb * g_color_tint) * blend.g) +
								    ((color_b.rgb * b_color_tint) * blend.b);

    shader_data.common.albedo.a = 1.0f;


// Normals
	// sample normal maps
    float3 normal_r = sample2DNormal(r_normal, uv, r_normal_transform);
	float3 normal_g = sample2DNormal(g_normal, uv, g_normal_transform);
	float3 normal_b = sample2DNormal(b_normal, uv, b_normal_transform);

	shader_data.common.normal.xy = (normal_r.xy * blend.r) + (normal_g.xy * blend.g) + (normal_b.xy * blend.b);
	shader_data.common.normal.z = sqrt(saturate(1.0f + dot(shader_data.common.normal.xy, -shader_data.common.normal.xy)));


	// add detail map

    float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
	shader_data.common.normal = CompositeDetailNormalMap( shader_data.common,
														  shader_data.common.normal,
														  normal_detail_map,
														  detail_uv,
														  normal_detail_dist_min,
														  normal_detail_dist_max);


	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo  = shader_data.common.albedo;
    float3 normal  = shader_data.common.normal;
    float4 blend   = sample2DGamma(blend_map, pixel_shader_input.texcoord.xy, float4(1,1,0,0));

	// using standard lambert model
    float3 diffuse = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, normal);
    diffuse *= shader_data.common.albedo;



    float3 specular = 0.0f;
    float4 specular_mask  = 0.0f;
	{ // Compute Specular


        // Specular blending based on img
        float4 spec_r = sample2DGamma(r_spec, pixel_shader_input.texcoord.xy, r_spec_transform);
        float4 spec_g = sample2DGamma(g_spec, pixel_shader_input.texcoord.xy, g_spec_transform);
        float4 spec_b = sample2DGamma(b_spec, pixel_shader_input.texcoord.xy, b_spec_transform);
        // output final combined spec
        specular_mask = (spec_r * blend.r) + (spec_g * blend.g) + (spec_b * blend.b);

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );
	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);
        // modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_intensity;
	}



    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse + specular;
    out_color.a   = 1.0f;

	return out_color;
}


#include "techniques.fxh"