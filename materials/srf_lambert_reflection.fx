//
// File:	 srf_lambert_reflection.fx
// Author:	 aluedke
// Date:	 11/09/2011
//
// Surface Shader - Lambert shader with reflection
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
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_normal,		"Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;

    float  alpha;

};





void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv			     = pixel_shader_input.texcoord.xy;


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
    float3 normal         = shader_data.common.normal;

    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse
        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);
        diffuse *= diffuse_intensity;
		diffuse_reflection_mask = diffuse;
        // modulate by albedo
    	diffuse *= albedo.rgb;
    }


	float fresnel = 0.0f;
	{ // Compute fresnel to modulate reflection

		float3 view = -shader_data.common.view_dir_distance.xyz;
		float  vdotn = saturate(dot( view, normal));
		fresnel = pow(vdotn, fresnel_power) * fresnel_intensity;
		fresnel = lerp(fresnel, saturate(1-fresnel), fresnel_inv);
	}

	float3 reflection = 0.0f;
	{ // sample reflection cube map
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);
		reflection = reflectionMap.rgb * reflection_intensity * reflection_color * reflectionMap.a;

		// Reflection Masking
		reflection  = lerp(reflection, reflection * fresnel, fresnel_mask_reflection);
		reflection  = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
	}


    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse + reflection;
    out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"