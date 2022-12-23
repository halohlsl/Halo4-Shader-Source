//
// File:	 srf_special_scurve_rock_mossy.fx
// Author:	 In Young Yang	
// Date:	 05/09/2012
//
// Surface Shader - Standard Blinn
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

#define DISABLE_LIGHTING_TANGENT_FRAME
#define DISABLE_LIGHTING_VERTEX_COLOR

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

#if defined(COLOR_DETAIL)
DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_alpha_mask_specular, "Detail Alpha Masks Spec", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

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
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_mask_influence, 	"Detail Mask Influence", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"

// Texture Samplers 1
DECLARE_SAMPLER( color1_map, "Color1 Map", "Color1 Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
/*DECLARE_SAMPLER( normal1_map, "Normal1 Map", "Normal1 Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"*/

// Diffuse 1
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo1_tint,		"Color1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

// Mask
DECLARE_FLOAT_WITH_DEFAULT(mask_bias,		"Mask Bias", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_intensity,		"Mask Intensity", "", 0, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_power,		"Mask Power", "", 0, 50, float(4.0));
#include "used_float.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(mask_normal_map_influence,		"Mask Normal Map Influence", "", 0, 1, float(0.5));
//#include "used_float.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(mask_diffuse_alpha_influence,		"Mask Diffuse Alpha Influence", "", 0, 1, float(0.5));
//#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_x_direction,		"Mask X Direction", "", -1, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_y_direction,		"Mask Y Direction", "", -1, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_z_direction,		"Mask Z Direction", "", -1, 1, float(0.0));
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
	float2 color_detail_uv   = pixel_shader_input.texcoord.xy;

	
	float3 geometry_normal = shader_data.common.normal;
	float3 maskNormal;
	float maskBias = mask_bias;
	
	


	shader_data.common.shaderValues.x = 1.0f; 			// Default specular mask

	// Calculate the normal map value
    {
		// Sample base normal map, this will be used to calculate the direction for the blend.
    	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
		float3 base_normal  = sample_2d_normal_approx(normal_map, normal_map_uv);

		maskNormal = base_normal;

		STATIC_BRANCH
		if (detail_normals)
		{
			// Composite detail normal map onto the base normal map
			float2 detail_uv = pixel_shader_input.texcoord.xy;

			
			detail_uv = transform_texcoord(detail_uv, normal_detail_map_transform);
			
			shader_data.common.normal = CompositeDetailNormalMap(shader_data.common,
																 base_normal,
																 normal_detail_map,
																 detail_uv,
																 normal_detail_dist_min,
																 normal_detail_dist_max);
			// blend in detail normal for mask
			maskNormal = lerp(maskNormal,base_normal,normal_detail_mask_influence);																 
		}
		else
		{
			// Use the base normal map
			shader_data.common.normal = base_normal;
		}

		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }

	float alphaMaskMap = 0;

    {// Sample color map.
	    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
		
		//Save off alpha map influance for later use as a mask
		alphaMaskMap = shader_data.common.albedo.a;
		
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

#else

		float specularMask = lerp(1.0f, shader_data.common.albedo.w, diffuse_alpha_mask_specular);
		shader_data.common.shaderValues.x *= specularMask;

#endif
	}

	// Create directional mask for snow using base normals
	maskNormal = mul(maskNormal, shader_data.common.tangent_frame);
#if defined(xenon) 
    float3 maskDirectionVector = float3(mask_z_direction, mask_x_direction, mask_y_direction);
#elif defined(pc)
    float3 maskDirectionVector = float3(mask_z_direction, mask_x_direction, mask_y_direction);
#else
    float3 maskDirectionVector = float3(mask_x_direction, mask_y_direction, mask_z_direction);
#endif
#if defined(VERTEX_MASK)
	//Use vertex alpha to modify bias
	maskBias += ((shader_data.common.vertexColor.a * 4) - 2);
#endif
	//float maskDirection = dot ( normalize( maskDirectionVector ) , lerp(geometry_normal, maskNormal, mask_normal_map_influence) ) + maskBias;
	float maskDirection = dot ( normalize( maskDirectionVector ) , maskNormal ) + maskBias;
	//float mask = pow(saturate((  (lerp( maskDirection,maskDirection*(1-alphaMaskMap),mask_diffuse_alpha_influence)) ) * mask_intensity), mask_power) ;
	float mask = pow(saturate( maskDirection * mask_intensity), mask_power) ;
    {// Blend in second color map and spec masks.
	    float2 color1_map_uv 	   = transform_texcoord(uv, color1_map_transform);
		float4 color1_map_sample    = sample2DGamma(color1_map, color1_map_uv);

        color1_map_sample.rgb *= albedo1_tint.rgb;

		// mix specular_color with albedo_color
        //float alphaedSpec = lerp(1,color1_map_sample.a, specular1_mix_albedo_alpha);
		//shader_data.common.shaderValues.x = lerp(shader_data.common.shaderValues.x, alphaedSpec, mask);

		// Blend color and spec based on mask
		shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, color1_map_sample.rgb, mask);
    }
	
	//shader_data.common.shaderValues.y = mask;
    
	shader_data.alpha = shader_data.common.albedo.a;


	shader_data.common.albedo.rgb *= albedo_tint;
	shader_data.common.albedo.a = shader_data.alpha;

	// Bake the vertex ambient occlusion amount into scaling parameters for lighting components
	float vertOcclusion = lerp(1.0f, shader_data.common.vertexColor.a, vert_occlusion_amt);

	shader_data.common.albedo.rgb *= vertOcclusion;				// albedo * vertex occlusion
	shader_data.common.shaderValues.x *= vertOcclusion;			// specular mask * vertex occlusion

}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;
	//float mask		      = shader_data.common.shaderValues.y;

	// Sample specular map
	float2 specular_map_uv	= transform_texcoord(uv, specular_map_transform);
	float4 specular_mask 	= sample2DGamma(specular_map, specular_map_uv);

	// Apply the specular mask from the albedo pass
	specular_mask.rgb *= shader_data.common.shaderValues.x;


    float3 specular = 0.0f;

	{ // Compute Specular
		float3 specNormal = normal;



        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );

	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, specNormal, albedo.a, power);


        // mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);


        // modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_col * specular_intensity;
	}

    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;

	{ // Compute Diffuse


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



	return out_color;
}


#include "techniques.fxh"