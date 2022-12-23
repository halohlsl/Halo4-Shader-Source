//
// File:	 srf_david.fx
// Author:	 hocoulby
// Date:	 11/29/11
//
// Custum shader requested by David Lesperance
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
// The basic idea is that I would like to have the ability to multiply a specific Amboc
// map against tiled diffuse and spec along with having a specific normal map.
// For added control I would like to use a gradient that we can overlay and or color burn
// against the diffuse and spec.  - David

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"


//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( ao_map, "Amboc Map", "Amboc Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint, "Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity, "Diffuse Intensity", "", 0, 1, float(1.0));
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


DECLARE_RGB_COLOR_WITH_DEFAULT(amboc_tint, "AmbOcc Tint", "", float3(1,1,1));
#include "used_float3.fxh"

// Detail Normal Map
DECLARE_BOOL_WITH_DEFAULT(detail_normals, "Detail Normals Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"





struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv= pixel_shader_input.texcoord.xy;

    {// Sample color map.
	    float2 color_uv  = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_uv);
        shader_data.common.shaderValues.x  = shader_data.common.albedo.a;

		shader_data.common.albedo.rgb *= albedo_tint.rgb;
		shader_data.common.albedo.a = 1.0;
    }


    {// Sample normal map.
    	float2 normal_map_uv = transform_texcoord(uv, normal_map_transform);
		shader_data.common.normal= sample_2d_normal_approx(normal_map, normal_map_uv);

		STATIC_BRANCH
		if (detail_normals)
		{
			// Composite detail normal map onto the base normal map
			float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
			shader_data.common.normal = CompositeDetailNormalMap(shader_data.common,
																 shader_data.common.normal,
																 normal_detail_map,
																 detail_uv,
																 normal_detail_dist_min,
																 normal_detail_dist_max);
		}

    	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }


}




float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo     = shader_data.common.albedo;
	float3 normal  	  = shader_data.common.normal;
	float  alpha		  = shader_data.common.shaderValues.x;

    float3 diffuse = 0.0f;
	// using lambert model
	calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
	// modulate by albedo, color, and intensity
	diffuse *= albedo.rgb * diffuse_intensity;


	//.. Specular
	float3 specular = 0.0f;

	// sample specular map
	float2 spec_uv  =  transform_texcoord(pixel_shader_input.texcoord.xy, specular_map_transform);
	float4 spec_map = sample2DGamma(specular_map, spec_uv);

	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(spec_map.a, specular_power_min, specular_power_max );
	// using blinn specular model
	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);
	// mix specular_color with albedo_color
    float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);
	// modulate by mask, color, and intensity
	specular *= spec_map.rgb * specular_col * specular_intensity;


    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = (diffuse + specular);

	// occclusion
	float2 occ_map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, ao_map_transform);
	out_color.rgb *= sample2DGamma(ao_map, occ_map_uv).rgb * amboc_tint;


	// alpha
    out_color.a   = alpha;

	return out_color;
}


#include "techniques.fxh"
