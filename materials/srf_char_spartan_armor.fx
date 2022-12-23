//
// File:	 xsrf_spartan_armor.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Spartan Armor shader for apply custom lookup to change colors
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
/*
special case shader for MP Spartan Armor sets. The shader needs to take a packed control map and apply the Primary and Secondary color sets based on a painted mask.

Two core maps as input for each armor component
(perhaps a detail normal for hi-frequency noise).

Normal - standard normal map

Control map
R - Spec
G - Gloss
B - Color Mask
A - Color/Diffuse Intensity
*/


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER_HIDE_TRANSFORM( control_map_SpDiGlCm, "Control Map SpDiGlCm", "Control Map SpDiGlCm", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_HIDE_TRANSFORM( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(base_color,	"Base Color", "", float3(1,1,1));
#include "used_float3.fxh"


// Diffuse Primary and Secondary Change Colors
#if defined(cgfx) || defined(ARMOR_PREVIS)
    DECLARE_RGB_COLOR_WITH_DEFAULT(tmp_primary_cc,	"Test Primary Color", "", float3(1,1,1));
    #include "used_float3.fxh"
    DECLARE_RGB_COLOR_WITH_DEFAULT(tmp_secondary_cc,	"Test Secondary Color", "", float3(1,1,1));
    #include "used_float3.fxh"
#endif


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



struct s_shader_data {
	s_common_shader_data common;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	// we normalize ourselves since we might be atlased and we need to be within 0-1
	float2 uv = pixel_shader_input.texcoord.xy;
	uv = uv - floor(uv);

// Albedo Color
    float2 control_map_uv	   = transform_texcoord(uv, control_map_SpDiGlCm_transform);
    float4 control_map_sampled = sample2DGamma(control_map_SpDiGlCm, control_map_uv);

    // determine surface color
    // primary change color engine mappings, using temp values in maya for prototyping
    float4 primary_cc = 1.0;
    float3 secondary_cc = 1.0f;

    #if defined(cgfx)  || defined(ARMOR_PREVIS)
        primary_cc   = float4(tmp_primary_cc, 1.0);
        secondary_cc = float4(tmp_secondary_cc,1.0);
    #else
        primary_cc   = ps_material_object_parameters[0];
        secondary_cc = ps_material_object_parameters[1];
    #endif

    float3 surface_colors[3] = {base_color.rgb,
                                secondary_cc.rgb,
                                primary_cc.rgb};

    // control_map_sampled.b = color mask
    float index = floor((control_map_sampled.a * 2) + 0.99f);

	// output color
    shader_data.common.albedo.rgb = surface_colors[index] * control_map_sampled.g;
    shader_data.common.albedo.a = 1.0f;

// Normals
    float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
    float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);

    // composite detail normal map
	STATIC_BRANCH
	if (detail_normals)
	{
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
		shader_data.common.normal = base_normal;
	}

    shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

	// prop Sp and Gl to static lighting phase
	shader_data.common.shaderValues.x = control_map_sampled.r;
	shader_data.common.shaderValues.y = control_map_sampled.b;
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	// Engine Mappings
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;

	// pull Sp and Gl back out to avoid resample of control map
	float Sp = shader_data.common.shaderValues.x;
	float Gl = shader_data.common.shaderValues.y;

	// Diffuse Lighting
    float3 diffuse = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, normal);
    diffuse *= albedo.rgb;

    float3 specular = 0.0f;
	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(Gl, specular_power_min, specular_power_max );

	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

        // modulate by mask, color, and intensity
        specular *= Sp * specular_col * specular_intensity;
	}


    //.. Finalize Output Color
    float4 out_color = 0.0f;
	out_color.rgb = diffuse + specular;

	return out_color;
}


#include "techniques.fxh"