//
// File:	 srf_layered_three.fx
// Author:	 hocoulby
// Date:	 08/20/10
//
// Surface Shader - A layered shader that mixes three color and normal maps, with two  (Macro, Micro) Detail Normal Maps
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes: Shader variation requested by Vick Deleon [3/2/2011]
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
DECLARE_SAMPLER( r_normal, "Red - Normal Map", "Red - Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Green Layer
	// color map
DECLARE_SAMPLER( g_color, "Green - Color Map", "Green - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(g_color_tint,	"Green - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"

	// normalmap
DECLARE_SAMPLER( g_normal, "Green - Normal Map", "Green - Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Blue Layer
	// color
DECLARE_SAMPLER( b_color, "Blue - Color Map", "Blue - Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(b_color_tint,	"Blue - Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"

// normal
DECLARE_SAMPLER( b_normal, "Blue - Normal Map", "Blue - Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Detail Normal Map
DECLARE_SAMPLER(normal_detail_01_map,		"Detail Normal Map 1", "Detail Normal Map 1 ", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max_01,	"Detail Start Dist. 1", "", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min_01, 	"Detail End Dist. 1", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_view_invert_01, 	"Detail View Invert 1", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Detail Normal Map 2
DECLARE_SAMPLER(normal_detail_02_map,		"Detail Normal Map 2", "Detail Normal Map 2", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max_02,	"Detail Start Dist. 2", "", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min_02, 	"Detail End Dist. 2", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_view_invert_02, 	"Detail View Invert 2", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if defined(SPECULAR)
	DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,	"Specular Intensity", "", 0, 1, float(1.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(specular_power,		"Specular Power ", "", 0, 1, float(0.01));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
	#include "used_float.fxh"
#endif

#if defined(VERTOCCLUSION)
// vertex occlusion
DECLARE_FLOAT_WITH_DEFAULT(vert_occlusion_amt,  "Vertex Occlusion Amount", "", 0, 1, float(0.0));
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
	float4 color_r = sample2DGamma(r_color, uv, r_color_transform);
	float4 color_g = sample2DGamma(g_color, uv, g_color_transform);
	float4 color_b = sample2DGamma(b_color, uv, b_color_transform);

	shader_data.common.albedo.rgb = ((color_r.rgb * r_color_tint) * blend.r) +
								    ((color_g.rgb * g_color_tint) * blend.g) +
								    ((color_b.rgb * b_color_tint) * blend.b);

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
	// sample normal maps
    float3 normal_r = sample2DNormal(r_normal, uv, r_normal_transform);
	float3 normal_g = sample2DNormal(g_normal, uv, g_normal_transform);
	float3 normal_b = sample2DNormal(b_normal, uv, b_normal_transform);

	shader_data.common.normal = (normal_r * blend.r) + (normal_g * blend.g) + (normal_b * blend.b);
	
	// add detail map
	float2 detail_uv_01	      = transform_texcoord(uv, normal_detail_01_map_transform);
	shader_data.common.normal = CompositeDetailNormalMapMACRO(shader_data.common,
															  shader_data.common.normal,
															  normal_detail_01_map,
															  detail_uv_01,
															  normal_detail_dist_min_01,
															  normal_detail_dist_max_01,
															  normal_detail_view_invert_01);

	// add second detail map
	float2 detail_uv_02	 = transform_texcoord(uv, normal_detail_02_map_transform);
	shader_data.common.normal = CompositeDetailNormalMapMACRO(shader_data.common,
															  shader_data.common.normal,
															  normal_detail_02_map,
															  detail_uv_02,
															  normal_detail_dist_min_02,
															  normal_detail_dist_max_02,
															  normal_detail_view_invert_02);


	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

	
	#if defined(VERTOCCLUSION)
	// Bake the vertex ambient occlusion amount into scaling parameters for lighting components
	float vertOcclusion = lerp(1.0f, shader_data.common.vertexColor.a, vert_occlusion_amt);
	shader_data.common.albedo.rgb *= vertOcclusion;				// albedo * vertex occlusion
	#endif
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
			float power = calc_roughness( specular_power );
			calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);
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