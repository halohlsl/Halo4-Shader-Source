//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Standard Blinn
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
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ss_wrap, 		    "Subsurface Wrap", "", 0, 1, float(0.2));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(ss_color,	"Subsurface Color", "", float3(1,0.2,0.2));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ss_int, 		    "Subsurface Intensity", "", 0, 10, float(1.0));
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



struct s_shader_data {
	s_common_shader_data common;

	float4 specular_mask;               // specular sampler
    float alpha;
    float ss_mask;

};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;


    {// Sample color map.
        float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
        shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
        shader_data.ss_mask = shader_data.common.albedo.a;

        shader_data.common.albedo.rgb *= albedo_tint.rgb;
        shader_data.common.albedo.a = 1.0f;
    }


    {// Sample and composite normal and detail maps.
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);
    	shader_data.common.normal = mul(base_normal, shader_data.common.tangent_frame);
    }


    {// Sample specular map.
    	float2 specular_map_uv	  = transform_texcoord(uv, specular_map_transform);
    	shader_data.specular_mask  = sample2DGamma(specular_map, specular_map_uv);

    }

}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;
    float4 specular_mask  = shader_data.specular_mask;

    float3 specular = 0.0f;
	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );

	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

        // mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

        // modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_col * specular_intensity;
	}

    float3 diffuse = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert_skin_basic(diffuse,
                                        shader_data.common,
                                        normal,
                                        ss_color * shader_data.ss_mask * ss_int,
                                        ss_wrap);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

    //.. Finalize Output Color
    float4 out_color;

    out_color.rgb = diffuse + specular;
    out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"