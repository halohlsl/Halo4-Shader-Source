//
// File:	 srf_glass.fx
// Author:	 hocoulby
// Date:	 06/23/10
//
// Surface Shader - Glass
//
// Copyright (c) 343 Industries. All rights reserved.
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
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"


// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(parallax, "Parallax", "", 0, 1, float(0.0));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv			     = pixel_shader_input.texcoord.xy;




	float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
	shader_data.common.shaderValues.x = shader_data.common.albedo.a;
	shader_data.common.albedo.a = 1.0;

		
	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
	
	
	float fresnel = 0.0f;
	float3 view = -shader_data.common.view_dir_distance.xyz;
	float  vdotn = saturate(dot( view, shader_data.common.normal ));
	fresnel = pow(vdotn, fresnel_power) * fresnel_intensity;
	fresnel = lerp(fresnel, saturate(1-fresnel), fresnel_inv);
	
	// Fresnel mask for reflection
	shader_data.common.shaderValues.y = lerp(1.0, fresnel, fresnel_mask_reflection);
		
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;


		// Control Map for Specular, Gloss, Reflection , SelfIllum
	float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpGlRf_transform);
	float4 control_mask		= sample2DGamma(control_map_SpGlRf, control_map_uv);
	
	float3 diffuse = 1.0f;
    calc_simple_lighting(diffuse, shader_data.common);
	
    float3 specular = 0.0f;
	float power = calc_roughness(control_mask.g, specular_power_min, specular_power_max );
	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);
	float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);
	specular *= control_mask.r * specular_col * specular_intensity;


	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{ // sample reflection cube map
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view, shader_data.common.normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);
		reflection = 
			reflectionMap.rgb * 
			reflection_intensity *
			reflection_color * 
			control_mask.b * 
			reflectionMap.a * 
			shader_data.common.shaderValues.y;
	}
	



    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = (diffuse * color_screen(reflection, albedo.rgb)) + specular;
    out_color.a   = saturate(shader_data.common.shaderValues.y + shader_data.common.shaderValues.x  + specular);

	return out_color;
}


#include "techniques.fxh"