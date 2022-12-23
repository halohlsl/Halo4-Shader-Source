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

#define DISABLE_LIGHTING_TANGENT_FRAME

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"

//tint control
DECLARE_SAMPLER(tint_map,		"Tint Map", "Tint Map", "shaders/default_bitmaps/bitmaps/color_red.tif");
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(tint_colorR,		"Color Tint R Channel", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(tint_colorG,		"Color Tint G Channel", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(tint_colorB,		"Color Tint B Channel", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(tint_desaturate,		"Tint Desaturate", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_alpha_mask_specular, "Diffuse Alpha Masks Specular", "", 0, 1, float(0.0));
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

// Detail Normal Map
DECLARE_BOOL_WITH_DEFAULT(detail_normals, "Detail Normals Enabled", "", true);
#include "next_bool_parameter.fxh"

DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"

// vertex occlusion
DECLARE_FLOAT_WITH_DEFAULT(vert_occlusion_amt,  "Vertex Occlusion Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"

struct s_shader_data {
	s_common_shader_data common;

    float  alpha;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	shader_data.common.shaderValues.x = 1.0f; 			// Default specular mask

	// Calculate the normal map value
    {
		// Sample normal maps
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);

		STATIC_BRANCH
		if (detail_normals)
		{
			// Composite detail normal map onto the base normal map
			float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
			shader_data.common.normal = CompositeDetailNormalMap(shader_data.common,
																 base_normal,
																 normal_detail_map,
																 detail_uv,
																 normal_detail_dist_min,
																 normal_detail_dist_max);
		}
		else
		{
			// Use the base normal map
			shader_data.common.normal = base_normal;
		}

		// Transform from tangent space to world space
		shader_data.common.normal = normalize(mul(shader_data.common.normal, shader_data.common.tangent_frame));
    }



    {// Sample color map.
	    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

		//handle the tint map
		float3 tintMask = sample2D(tint_map, color_map_uv).xyz;
		float tintTotal = saturate( dot(tintMask.xyz, float3(1,1,1)));

		float3 tintColor = tintMask.r * tint_colorR + tintMask.g * tint_colorG + tintMask.b * tint_colorB + (1.0-tintTotal)*float3(1,1,1);

		float destaturatedColor = mul( shader_data.common.albedo.rgb, float3( 0.3, 0.59, 0.11 ) );//would the average be better?
		float3 baseColor = lerp( shader_data.common.albedo.rgb, float3( destaturatedColor, destaturatedColor, destaturatedColor ), tintTotal * tint_desaturate );
		shader_data.common.albedo.rgb = baseColor * tintColor;

		//albedo now has our tinted color move on like normal.

		float specularMask = lerp(1.0f, shader_data.common.albedo.w, diffuse_alpha_mask_specular);
		shader_data.common.shaderValues.x *= specularMask;

        shader_data.alpha	= shader_data.common.albedo.a;

		shader_data.common.albedo.rgb *= albedo_tint;
		shader_data.common.albedo.a = shader_data.alpha;
	}
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;

	// Sample specular map
	float2 specular_map_uv	= transform_texcoord(uv, specular_map_transform);
	float4 specular_mask 	= sample2DGamma(specular_map, specular_map_uv);

	// Apply the specular mask from the albedo pass
	specular_mask.rgb *= shader_data.common.shaderValues.x;

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
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);

		// Store the mask for diffuse reflection
        diffuse_reflection_mask = diffuse;

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

    //.. Finalize Output Color
    float4 out_color;
	out_color.rgb = diffuse + specular;
	out_color.a   = shader_data.alpha;

    // Vertex Occlusion
    out_color.rgb *= lerp(1.0f, shader_data.common.vertexColor.a, vert_occlusion_amt);

	return out_color;
}


#include "techniques.fxh"