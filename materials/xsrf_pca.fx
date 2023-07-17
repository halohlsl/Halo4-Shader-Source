//
// File:	 xsrf_pca.fx
// Author:	 hocoulby
// Date:	 04/19/11
//
// Experimental Surface Shader - Basic PCA blending shader
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
DECLARE_SAMPLER( color_map,  "Color Map Base", "Color Map Base", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( color_map_wrinkle, "Color Map Wrinkle", "Color Map Wrink;e", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map_wrinkle, "Normal Map Wrinkle", "Normal Map Wrinkle", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"



// Diffuse
DECLARE_FLOAT_WITH_DEFAULT(wrinkle_amt, "Wrinkle Amount", "", 1, 10, float(1.0));
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
    float2 tension = shader_data.common.vertexColor.rb;
    tension.r = tension.r * wrinkle_amt;

    float2 uv   = transform_texcoord(pixel_shader_input.texcoord.xy, float4(1, 1, 0, 0));

    {// Sample  and composite color map.

	    float4 colorBase    = sample2DGamma(color_map,  uv);
		float4 colorWrinkle = sample2DGamma(color_map_wrinkle,  uv);

		shader_data.common.albedo.rgb = lerp(colorBase.rgb, colorWrinkle.rgb, tension.r);

        shader_data.alpha = colorBase.a;

        shader_data.common.albedo.rgb *= albedo_tint;
		shader_data.common.albedo.a = shader_data.alpha;
    }


    {// Sample normal map.
    	float3 normal_base     = sample_2d_normal_approx(normal_map,  uv);
		float3 normal_wrinkle  = sample_2d_normal_approx(normal_map_wrinkle,  uv);

		normal_wrinkle  = lerp(float3(0,0,0), normal_wrinkle, tension.r);
		normal_base     = lerp(float3(0,0,0), normal_base, 1-tension.r);

		shader_data.common.normal.xy = normal_base.xy  + normal_wrinkle.xy;
		shader_data.common.normal.z = sqrt(saturate(1.0f + dot( shader_data.common.normal.xy, -shader_data.common.normal.xy)));


    	shader_data.common.normal = normalize( mul( shader_data.common.normal,
													shader_data.common.tangent_frame));
    }


}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{


	// input from s_shader_data
    float4 albedo  = shader_data.common.albedo;
    float2 uv   = transform_texcoord(pixel_shader_input.texcoord.xy, float4(1, 1, 0, 0));
    float4 specular_mask  = sample2DGamma(specular_map, uv);

    float3 diffuse = 0.0f;
    { // Compute Diffuse
        // using standard lambert model


        calc_diffuse_lambert_fill(
                        diffuse,
                        shader_data.common,
                        shader_data.common.normal,
                        0.15f,
                        0.15f);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }


    float3 specular = 0.0f;
	{ // Compute Specular
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(   specular_mask.a,
                                        specular_power_min,
                                        specular_power_max );

	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, albedo.a, power);

        // mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

        // modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_col * specular_intensity;

    }


    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse + specular;
    out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"