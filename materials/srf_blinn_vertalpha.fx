//
// File:	 srf_blinn_vertalpha.fx
// Author:	 hocoulby
// Date:	 5/02/11
//
// Surface Shader - uses the vertex color set as the alpha value of the shader.
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

#if defined(HEIGHT_MASK)
    DECLARE_FLOAT_WITH_DEFAULT(height_influence, "Height Map Influence", "", 0, 1, float(1.0));
    #include "used_float.fxh"
    DECLARE_FLOAT_WITH_DEFAULT(threshold_softness, "Height Map Threshold Softness", "", 0.01, 1, float(0.1));
    #include "used_float.fxh"
#endif

#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif


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
        float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
		shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

        shader_data.common.albedo.rgb *= albedo_tint;

		//.. Solve Output Alpha - this needs to be done here so both passes can use the clip.
		float out_alpha = shader_data.common.vertexColor.a;

		#if defined(HEIGHT_MASK)
			//shader_data.common.albedo.a is the height_mask
			out_alpha = saturate( (shader_data.common.vertexColor.a - ( 1 - shader_data.common.albedo.a )) / max(0.001, threshold_softness)  );
			out_alpha = lerp( shader_data.common.vertexColor.a, out_alpha, height_influence );
		#endif

		#if defined(ALPHA_CLIP)
			// Tex kill pixel
			clip(out_alpha - clip_threshold);
		#endif

		shader_data.common.shaderValues.x = out_alpha;

		shader_data.common.albedo.a = out_alpha;
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
	float2 uv   = pixel_shader_input.texcoord.xy;

    // input from s_shader_data
    float4 albedo = shader_data.common.albedo;

    float4 specular_mask  = 0.0f;
    {// Sample specular map.
    	float2 spec_map_uv	  = transform_texcoord(uv, normal_map_transform);
    	specular_mask = sample2DGamma(specular_map, spec_map_uv);
    }

    float3 diffuse = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

    float3 specular = 0.0f;
	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );
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

    //.. Finalize Output Alpha
    out_color.a   = shader_data.common.shaderValues.x;

    return out_color;
}


#include "techniques.fxh"