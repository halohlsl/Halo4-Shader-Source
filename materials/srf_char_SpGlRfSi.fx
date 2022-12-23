//
// File:	 srf_char_SpGlRfSi.fx
// Author:	 hocoulby
// Date:	 06/23/10
//
// Surface Shader - Character shader with Specular, Gloss, Refelction, and SelfIllum
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
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
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
DECLARE_FLOAT_WITH_DEFAULT(reflection_lod,		    "Reflection_Blur", "", 0, 10, float(0.0));
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

// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
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

	float4 control_mask;
    float4 specular_mask;
	float3 reflection;
	float3 self_illum;
	float alpha;
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

		shader_data.common.albedo.rgb *= albedo_tint;
		shader_data.common.albedo.a = shader_data.alpha;
    }


    {// Sample specular map.
    	float2 specular_map_uv	  = transform_texcoord(uv, specular_map_transform);
    	shader_data.specular_mask  = sample2DGamma(specular_map, specular_map_uv);
    }


    {// Sample and composite normal and detail maps.
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);

        // composite detail normal map
		float2 detail_uv	  = transform_texcoord(uv, normal_detail_map_transform);
        shader_data.common.normal = CompositeDetailNormalMap(  shader_data.common,
																										  base_normal,
																										  normal_detail_map,
																										  detail_uv,
																										  normal_detail_dist_min,
																										  normal_detail_dist_max);



    	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }


    {// Sample control map.
    	float2 control_map_uv	    = transform_texcoord(uv, control_map_SpGlRf_transform);
    	shader_data.control_mask    = sample2DGamma(control_map_SpGlRf, control_map_uv);

    }


	{ // sample reflection cube map
		float3 view = shader_data.common.view_dir_distance.xyz;

		float4 rVec = 0.0;
		rVec.rgb = reflect(view, shader_data.common.normal);
		rVec.w    = reflection_lod;

		shader_data.reflection = sampleCUBEGamma(reflection_map, rVec).rgb;
		shader_data.reflection *= reflection_intensity * reflection_color * shader_data.control_mask.b;
	}


}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;
	float3  specular_mask  = shader_data.specular_mask * shader_data.control_mask.r;
    float    specular_gloss  = shader_data.control_mask.g;
	float    self_illum_mask = shader_data.control_mask.a;

    float3 specular = 0.0f;

	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_gloss, specular_power_min, specular_power_max );

	    // using phong specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

        // mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

        // modulate by mask, color, and intensity
        specular *= specular_mask * specular_col;
	}


    float3 diffuse = 0.0f;
	float3  diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);
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


	float3 reflection = shader_data.reflection;
	{ // Fresnel Reflection Masking
		reflection  = lerp(reflection, reflection*fresnel, fresnel_mask_reflection);
		reflection  = lerp(reflection , reflection*diffuse_reflection_mask, diffuse_mask_reflection);
	}


    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse + specular + reflection;

	// self illum
	if (AllowSelfIllum(shader_data.common))
	{
		float3 self_illum = albedo.rgb * si_color * si_intensity * self_illum_mask;
		out_color.rgb += self_illum;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(self_illum);
	}

	out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"