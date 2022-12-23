//
// File:	 srf_blinn_vertalpha_reflection.fx
// Author:	 v-tomau
// Date:	 10/24/11
//
// Surface Shader - uses the vertex color set as the alpha value of the shader wil Reflectivity.
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

// Reflection
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_normal,		"Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_normal_influence,		"Diffuse Normal Influence", "", 0, 1, float(1.0));
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

// Detail Normal Map
DECLARE_BOOL_WITH_DEFAULT(detail_normals, "Detail Normals Enabled", "", true);
#include "next_bool_parameter.fxh"

DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"


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



struct s_shader_data
{
    s_common_shader_data common;
    #if defined(HEIGHT_MASK)
    	float height_from_colormap ;
    #endif
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

		#if defined(HEIGHT_MASK)
			shader_data.height_from_colormap = shader_data.common.albedo.a;
		#endif
        shader_data.common.albedo.a = 1.0f;
    }


    {// Sample normal map.
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
    float3 normal = shader_data.common.normal;
    shader_data.common.normal = shader_data.common.normal * diffuse_normal_influence;

    float4 specular_mask  = 0.0f;
    {// Sample specular map.
    	float2 spec_map_uv	  = transform_texcoord(uv, normal_map_transform);
    	specular_mask = sample2DGamma(specular_map, spec_map_uv);
    }

    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal );

		// Store the mask for diffuse reflection
        diffuse_reflection_mask = diffuse;

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

	// Sample control mask
	float2 control_map_uv	= transform_texcoord(uv, control_map_SpGlRf_transform);
	float4 control_mask		= sample2DGamma(control_map_SpGlRf, control_map_uv);

	specular_mask.rgb *= control_mask.r;
    specular_mask.a  = control_mask.g;

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

	float3 reflection = 0.0f;

	if (AllowReflection(shader_data.common))
	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, normal, reflection_normal);

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap;

		reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			control_mask.b *							// control mask reflection intensity channel
			reflectionMap.a;							// intensity scalar from reflection cube

		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection

			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot( view, rNormal));
			fresnel = lerp(vdotn, saturate(1 - vdotn), fresnel_inv);
			fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
		}

		// Fresnel Reflection Masking
		reflection  = lerp(reflection, reflection * fresnel, fresnel_mask_reflection);
		reflection  = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
	}

    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse + specular + reflection;

    //.. Finalize Output Alpha
    float out_alpha = shader_data.common.vertexColor.a;

    #if defined(HEIGHT_MASK)
		out_alpha = saturate( (shader_data.common.vertexColor.a - ( 1 - shader_data.height_from_colormap )) / max(0.001, threshold_softness)  );
		out_alpha = lerp( shader_data.common.vertexColor.a, out_alpha, height_influence );
    #endif

    out_color.a   = out_alpha;

    return out_color;
}


#include "techniques.fxh"