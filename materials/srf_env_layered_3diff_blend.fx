//
// File:	 srf_env_layered_3diff_blend.fx
// Author:	 wesleyg
// Date:	 07/24/12
//
// Surface Shader - A layered shader that mixes three color maps and has a Macro Normal
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//....Settings
#define BLENDED_MATERIAL

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER_NO_TRANSFORM( blend_map, "Blend Map RGB", "Blend Map RGB", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
#if defined(SPECULAR_MAP)
DECLARE_SAMPLER_NO_TRANSFORM( specular_map, "Specular Map", "Specular_Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#endif
#include "next_texture.fxh"

// Red Layer
// colormap

DECLARE_SAMPLER( r_color, "Red - Color Map", "Red - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(r_color_tint,	"Red - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"

// normalmap
DECLARE_SAMPLER( r_normal, "Macro Normal Map", "Macro Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(blend_normal_g,"Blend Macro Normal", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Green Layer
	// color map
DECLARE_SAMPLER( g_color, "Green - Color Map", "Green - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(g_color_tint,	"Green - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"


// Blue Layer
// color
#if !defined(TWO_LAYER)
DECLARE_SAMPLER( b_color, "Blue - Color Map", "Blue - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(b_color_tint,	"Blue - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
#endif

#if defined(SPECULAR)
	DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,	"Specular Intensity", "", 0, 1, float(1.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(specular_power,		"Specular Power ", "", 1, 200, float(20.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.8));
	#include "used_float.fxh"
#endif

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
	float4 blend   = sample2DGamma(blend_map, uv, float4(1,1,0,0));
    // normalize blend map
	blend = normalize(blend);

// Albedo
#if defined(TWO_LAYER)
	float4 color_r = sample2DGamma(r_color, uv, r_color_transform);
	float4 color_g = sample2DGamma(g_color, uv, g_color_transform);
	shader_data.common.albedo.rgb = lerp((color_g.rgb * g_color_tint),(color_r.rgb * r_color_tint), blend.r);
#else
	float4 color_r = sample2DGamma(r_color, uv, r_color_transform);
	float4 color_g = sample2DGamma(g_color, uv, g_color_transform);
	float4 color_b = sample2DGamma(b_color, uv, b_color_transform);
	shader_data.common.albedo.rgb = ((color_r.rgb * r_color_tint) * blend.r) +
								    ((color_g.rgb * g_color_tint) * blend.g) +
									((color_b.rgb * b_color_tint) * blend.b);
#endif


	// Specular Mask
	#if defined(SPECULAR)	
		
		#if defined(SPECULAR_MAP)
			shader_data.common.shaderValues.x = sample2DGamma(specular_map, uv, float4(1,1,0,0));
		#else
			shader_data.common.shaderValues.x = blend.a;
		#endif
		
	#endif

	shader_data.common.albedo.a = 1.0f;

	
// Normals
	shader_data.common.normal = normalize(lerp(float3(0,0,1),sample2DNormal(r_normal, uv, r_normal_transform), max(min(blend.r + blend_normal_g,1.0),0.0)));
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
}

float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;


    float3 diffuse = 0.0f;
	// using standard lambert model
    calc_diffuse_lambert(diffuse, shader_data.common, normal);
    diffuse *= albedo.rgb;

	float3 specular = 0.0f;
	#if defined(SPECULAR)
			calc_specular_phong(specular, shader_data.common, normal, albedo.a, specular_power);
			float3 specular_col = lerp(float3(1,1,1), albedo.rgb, specular_mix_albedo);	
			specular *= shader_data.common.shaderValues.x	* specular_intensity * specular_col;			
	#endif
	
    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse + specular; 
    out_color.a   = 1.0f;

	return out_color;
}


#include "techniques.fxh"