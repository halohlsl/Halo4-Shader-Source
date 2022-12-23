//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Standard Phong
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

// Alpha clip threshold (only when alpha clip is used)
#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif

#if defined(COLOR_DETAIL)
DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_alpha_mask_specular, "Detail Alpha Masks Spec", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

#if defined(VERTEX_MULTIPLY)
DECLARE_FLOAT_WITH_DEFAULT(vertex_ao, "Vertex AO Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif



struct s_shader_data {
	s_common_shader_data common;

	float4 specular_mask;               // specular sampler
    float alpha;

};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv    		= pixel_shader_input.texcoord.xy;
	shader_data.common.shaderValues.x = 1.0f; 			
	
	#if defined(COLOR_DETAIL)
			float2 color_detail_uv   = pixel_shader_input.texcoord.xy;
			#if defined(COLOR_DETAIL_UV2)
				color_detail_uv = pixel_shader_input.texcoord.zw;
			#endif
	#endif
	

    {// Sample color map.
	    float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
        shader_data.alpha = shader_data.common.albedo.a;

        shader_data.common.albedo.rgb *= albedo_tint.rgb;
		shader_data.common.albedo.a = shader_data.alpha;

		#if defined(COLOR_DETAIL)
			const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)

			float2 color_detail_map_uv = transform_texcoord(color_detail_uv, color_detail_map_transform);
			float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
			color_detail.rgb *= DETAIL_MULTIPLIER;

			shader_data.common.albedo.rgb *= color_detail;
			shader_data.common.shaderValues.x *= shader_data.common.albedo.w;

			// specular detail mask in alpha, artist weighted influence.
			float specularMask = lerp(1.0f, color_detail.a, detail_alpha_mask_specular);
			shader_data.common.shaderValues.x *= specularMask;
		#endif

		
#if defined(ALPHA_CLIP)
		// Alpha clip pixels
		clip(shader_data.alpha - clip_threshold);
#endif
    }

    {// Sample normal map.
    	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
    	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
    	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }


    {// Sample specular map.
    	float2 specular_map_uv	    = transform_texcoord(uv, specular_map_transform);
    	shader_data.specular_mask   = sample2DGamma(specular_map, specular_map_uv);
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
    	calc_specular_phong(specular, shader_data.common, normal, albedo.a, power);

        // mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

        // modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_col * specular_intensity * shader_data.common.shaderValues.x;
    }



    float3 diffuse = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }



    //.. Finalize Output Color
    float4 out_color;

    out_color.rgb = diffuse + specular;
	
#if defined(VERTEX_MULTIPLY)
		out_color.rgb *= lerp(1.0, shader_data.common.vertexColor.a, vertex_ao);
#endif
	
    out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"