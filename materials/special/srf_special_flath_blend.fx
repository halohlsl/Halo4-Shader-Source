//
// File:	 srf_special_flath_blend.fx
// Author:	 hocoulby
// Date:	 11/28/11
//
// Lyered Shader - Blends two texture maps based on vert color. For the second color/normal artist has control
// over which uv set sampled with
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


DECLARE_BOOL_WITH_DEFAULT(use_uvset2, "Use Uv Set 2", "", true);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER( color_02_map, "Color Map 2", "Color Map 2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_02_map, "Normal Map 2", "Normal Map 2", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"

#if defined(COLOR_DETAIL)
	DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(detail_alpha_mask_specular, "Detail Alpha Masks Spec", "", 0, 1, float(0.0));
	#include "used_float.fxh"
#endif

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint_1, "Color Tint 1", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity_1, "Diffuse Intensity 1", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color_1,		"Specular Color 1", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(specular_intensity_1,		"Specular Intensity 1", "", 0, 1, float(1.0));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint_2, "Color Tint 2", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity_2, "Diffuse Intensity 2", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color_2,		"Specular Color 2", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity_2,		"Specular Intensity 2", "", 0, 1, float(1.0));
#include "used_float.fxh"



DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


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
	float2 uv_blended = 0.0f;


	STATIC_BRANCH
	if (use_uvset2)
	{
		uv_blended = pixel_shader_input.texcoord.zw;
	} else {
		uv_blended = uv;
	}


    {// Sample color map.
	    float2 map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, map_uv);
        shader_data.common.shaderValues.x  = shader_data.common.albedo.a;


		map_uv = transform_texcoord(uv_blended, color_02_map_transform);

	    shader_data.common.albedo = lerp( shader_data.common.albedo,
										  sample2DGamma(color_02_map, map_uv),
										  shader_data.common.vertexColor.a);

		float3 color_tint = lerp(albedo_tint_1, albedo_tint_2, shader_data.common.vertexColor.a);
		shader_data.common.albedo.rgb *= color_tint.rgb;		
		shader_data.common.albedo.a = shader_data.common.shaderValues.x;

#if defined(COLOR_DETAIL)
		const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)

	    float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
	    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
	    color_detail.rgb *= DETAIL_MULTIPLIER;

		shader_data.common.albedo.rgb *= color_detail;
		shader_data.common.shaderValues.y =  lerp(1.0f, color_detail.a, detail_alpha_mask_specular);
#endif


	}




    {// Sample normal map.
    	float2 normal_1_map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, normal_map_transform);
		float3 normal_1_map = sample_2d_normal_approx(normal_map, normal_1_map_uv);

		float2 normal_2_map_uv = transform_texcoord(uv_blended, normal_02_map_transform);
		float3 normal_2_map = sample_2d_normal_approx(normal_02_map, normal_2_map_uv);

		normal_1_map = lerp(normal_1_map, float3(0,0,0), shader_data.common.vertexColor.a);
		normal_2_map = lerp(float3(0,0,0), normal_2_map, shader_data.common.vertexColor.a);

		shader_data.common.normal.xy = normal_1_map.xy + normal_2_map.xy;

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
		else
		{
			shader_data.common.normal.z = sqrt(saturate(1.0f + dot(shader_data.common.normal.xy, -shader_data.common.normal.xy)));
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

    float3 diffuse = 0.0f;
	float diffuse_intensity = lerp(diffuse_intensity_1, diffuse_intensity_2, shader_data.common.vertexColor.a);

	// using lambert model
	calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
	// modulate by albedo, color, and intensity
	diffuse *= albedo.rgb * diffuse_intensity;



	//.. Specular
	float3 specular = 0.0f;

	// sample specular map
	float2 spec_uv  = transform_texcoord(pixel_shader_input.texcoord.xy, specular_map_transform);
	float4 spec_map = sample2DGamma(specular_map, spec_uv);

	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(spec_map.a, specular_power_min, specular_power_max );
	// using blinn specular model
	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, albedo.a, power);
	// mix specular_color with albedo_color

    float3 specular_col =  lerp(specular_color_1, specular_color_2, shader_data.common.vertexColor.a);
	float  specular_intensity = lerp(specular_intensity_1, specular_intensity_2, shader_data.common.vertexColor.a);


#if defined(COLOR_DETAIL)
	specular_intensity *=  shader_data.common.shaderValues.y;
#endif

	
	specular_col = lerp(specular_col, albedo.rgb, specular_mix_albedo);

	// modulate by mask, color, and intensity
	specular *= spec_map.rgb * specular_col * specular_intensity;



    //.. Finalize Output Color
    float4 out_color;

    out_color.rgb = diffuse + specular;
    out_color.a   = shader_data.common.shaderValues.x;

	return out_color;
}


#include "techniques.fxh"