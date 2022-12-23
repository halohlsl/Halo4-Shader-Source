//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Blinn with Self Illum
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
// Control Map - Rch. = Spec Intensity, Gch. = Spec. Gloss, Bch = Self-Illum Mask

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
DECLARE_SAMPLER( control_map_SpGlSi, "Control Map SpGlSi", "Control Map SpGlSi", "shaders/default_bitmaps/bitmaps/default_spec.tif");
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

// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
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



struct s_shader_data {
	s_common_shader_data common;

	float4 specular_mask;               // specular sampler
    float alpha;

};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;


    {// Sample color map.
        float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
        shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
        shader_data.alpha = shader_data.common.albedo.a;

        shader_data.common.albedo.rgb *= albedo_tint;
		shader_data.common.albedo.a = shader_data.alpha;
    }


    {// Sample and composite normal and detail maps.
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);

            // composite detail normal map
            STATIC_BRANCH
            if (detail_normals) {
                float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
                shader_data.common.normal = CompositeDetailNormalMap(shader_data.common,
                                                                     base_normal,
                                                                     normal_detail_map,
                                                                     detail_uv,
                                                                     normal_detail_dist_min,
                                                                     normal_detail_dist_max);
            } else {
                shader_data.common.normal = base_normal;
            }

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

    float2 uv = pixel_shader_input.texcoord.xy;

    // sample control map
	float4 ctrlMap_SpGlSi = sample2DGamma(control_map_SpGlSi,
                                          transform_texcoord(uv, control_map_SpGlSi_transform));

    // self illum
     ctrlMap_SpGlSi.b *= si_intensity;


    float3 diffuse = 0.0f;
    { // Compute Diffuse

        calc_diffuse_lambert(diffuse, shader_data.common, normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

    float3 specular = 0.0f;
	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(ctrlMap_SpGlSi.g, specular_power_min, specular_power_max );

	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

        // mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

        // modulate by mask, color, and intensity
        specular *= ctrlMap_SpGlSi.r * specular_col * specular_intensity;
	}


    //.. Finalize Output Color
    float4 out_color;

    out_color.rgb = diffuse + specular;

    // self illum
    if (AllowSelfIllum(shader_data.common))
    {
		float3 selfIllumColor = si_color * ctrlMap_SpGlSi.b * si_intensity;

		// Add self-illum directly
		out_color.rgb += selfIllumColor;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(selfIllumColor);
    }

    // alpha
    out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"