//
// File:	 srf_ca_snow.fx
// Author:	 dvaley
// Date:	 08/19/11
//
// Surface Shader - Vector defined directional blend
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
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Detail Color
DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_mix_detail_alpha,		"Specular Mix Detail Alpha", "", 0, 1, float(0.0));
#include "used_float.fxh"

//// Detail Normal Map
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

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular0_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_power,		"Specular Power", "", 0.01, 100, float(20));
#include "used_float.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(specular0_power_min,		"Specular Power White", "", 0, 1, float(0.01));
//#include "used_float.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(specular0_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
//#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_mix_albedo_alpha,		"Specular Mix Albedo Alpha", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection0_color,	"Reflection0 Color", "", float3(1,1,1));
#include "used_float3.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(reflection0_intensity,		"Reflection0 Intensity", "", 0, 1, float(0.8));
//#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection0_normal,		"Reflection0 Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel0_intensity,		"Fresnel0 Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel0_power,			"Fresnel0 Power", "", 0, 10, float(3.0));
#include "used_float.fxh"

//DECLARE_FLOAT_WITH_DEFAULT(fresnel0_mask_reflection,	"Fresnel0 Mask Reflection", "", 0, 1, float(1.0));
//#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel0_inv,				"Fresnel0 Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse0_mask_reflection,	"Diffuse0 Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Texture Samplers 1
DECLARE_SAMPLER( color1_map, "Color1 Map", "Color1 Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal1_map, "Normal1 Map", "Normal1 Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"

// Diffuse 1
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo1_tint,		"Color1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

// Specular 1
DECLARE_RGB_COLOR_WITH_DEFAULT(specular1_color,		"Specular1 Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_intensity,		"Specular1 Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_power,		"Specular1 Power", "", 0.01, 100, float(20));
#include "used_float.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(specular1_power_min,		"Specular1 Power White", "", 0, 1, float(0.01));
//#include "used_float.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(specular1_power_max,		"Specular1 Power Black", "", 0, 1, float(0.0));
//#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_mix_albedo,		"Specular1 Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_mix_albedo_alpha,		"Specular1 Mix Albedo Alpha", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse1_mask_reflection,	"Diffuse1 Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Mask
DECLARE_FLOAT_WITH_DEFAULT(mask_bias,		"Mask Bias", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_intensity,		"Mask Intensity", "", 0, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_power,		"Mask Power", "", 0, 50, float(4.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_normal_map_influence,		"Mask Normal Map Influence", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_diffuse_alpha_influence,		"Mask Diffuse Alpha Influence", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_x_direction,		"Mask X Direction", "", -1, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_y_direction,		"Mask Y Direction", "", -1, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_z_direction,		"Mask Z Direction", "", -1, 1, float(0.0));
#include "used_float.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)
	float3 geometry_normal = shader_data.common.normal;
	float3 maskNormal;
	float maskBias = mask_bias;
	float specularIntensity = 0;

    {// Sample base normal map, this will be used to calculate the direction for the blend.
    	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
		float3 normal_map_sample  = sample_2d_normal_approx(normal_map, normal_map_uv);

		maskNormal = normal_map_sample;

		// composite detail normal map
		STATIC_BRANCH
		if (detail_normals)
		{
			float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);

			normal_map_sample = CompositeDetailNormalMap(shader_data.common,
															 normal_map_sample,
															 normal_detail_map,
															 detail_uv,
															 normal_detail_dist_min,
															 normal_detail_dist_max);

			// blend in detail normal for mask
			maskNormal = lerp(maskNormal,normal_map_sample,normal_detail_mask_influence);
		}

    	shader_data.common.normal = normal_map_sample;
    }

	float alphaMaskMap = 0;

	{// Sample color map and spec.
	    float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
		float4 color_map_sample    = sample2DGamma(color_map, color_map_uv);

	    shader_data.common.albedo = color_map_sample;
        shader_data.common.albedo.rgb *= albedo_tint.rgb;

		// mix specular_color with albedo_color
		shader_data.common.shaderValues.x = lerp(1,color_map_sample.a, specular0_mix_albedo_alpha);;

		//Save off alpha map influance for later use as a mask
		alphaMaskMap = color_map_sample.a;

		// Layer in detail color
	    float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
	    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
	    color_detail.rgb *= DETAIL_MULTIPLIER;

		shader_data.common.albedo.rgb *= color_detail;

		// Layer in detail spec
		//specularIntensity *= lerp(1,color_detail.a, specular0_mix_detail_alpha);
		shader_data.common.shaderValues.x *= lerp(1,color_detail.a, specular0_mix_detail_alpha);

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

	float maskDirection = dot ( normalize( maskDirectionVector ) , lerp(geometry_normal, maskNormal, mask_normal_map_influence) ) + maskBias;
	float mask = pow(saturate((  (lerp( maskDirection,maskDirection*(1-alphaMaskMap),mask_diffuse_alpha_influence)) ) * mask_intensity), mask_power) ;

	{// Blend in second normal
		float2 normal1_map_uv	  = transform_texcoord(uv, normal1_map_transform);
		float3 normal1_map_sample  = sample_2d_normal_approx(normal1_map, normal1_map_uv);

		shader_data.common.normal.xy = lerp(shader_data.common.normal.xy, normal1_map_sample.xy, mask);
		shader_data.common.normal.z = sqrt(saturate(1.0f + dot(shader_data.common.normal.xy, -shader_data.common.normal.xy)));

		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
	}

    {// Blend in second color map and spec masks.
	    float2 color1_map_uv 	   = transform_texcoord(uv, color1_map_transform);
		float4 color1_map_sample    = sample2DGamma(color1_map, color1_map_uv);

        color1_map_sample.rgb *= albedo1_tint.rgb;

		// mix specular_color with albedo_color
        float alphaedSpec = lerp(1,color1_map_sample.a, specular1_mix_albedo_alpha);
		shader_data.common.shaderValues.x = lerp(shader_data.common.shaderValues.x, alphaedSpec, mask);

		// Blend color and spec based on mask
		shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, color1_map_sample.rgb, mask);
    }

	shader_data.common.shaderValues.y = mask;
}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
	float3 normal         = shader_data.common.normal;
	float specular1_alpha = shader_data.common.shaderValues.x;
	float mask		      = shader_data.common.shaderValues.y;

	float3 specular = 0.0f;
	{
		// Compute Specular

		//compute specular mask
		float3 specular_mask0 = specular0_color * lerp(1,  shader_data.common.albedo.rgb, specular0_mix_albedo);
		float3 specular_mask1 = specular1_color * lerp(1,  shader_data.common.albedo.rgb, specular1_mix_albedo);
		float3 specular_mask = lerp(specular_mask0, specular_mask1, mask);

       // pre-computing roughness with independent control over white and black point in gloss map
        //float specular0_power = calc_roughness(albedo.a, specular0_power_min, specular0_power_max);
        //float specular1_power = calc_roughness(specular1_alpha, specular1_power_min, specular1_power_max);
		//combine specular powers
		float specular_power = lerp(specular0_power, specular1_power, mask);

	    // using blinn specular model
    	calc_specular_phong(specular, shader_data.common, normal, specular1_alpha , specular_power);

		//Find blend spec intensity
		float specular_intensity = lerp(specular0_intensity, specular1_intensity, mask);

        // modulate by mask
        specular *= specular_mask.rgb * specular_intensity;
	}

    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);

		// Store the mask for diffuse reflection
        diffuse_reflection_mask = diffuse;

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

	float3 reflection = 0.0f;

	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		//float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, lerp( reflection0_normal, reflection1_normal, mask ) );

		//float3 rVec = reflect(view, rNormal);
		//float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflection0_color;

		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection

			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot( view, normal));
			fresnel = lerp(vdotn, saturate(1 - vdotn), fresnel0_inv );
			fresnel = pow(fresnel, fresnel0_power ) * fresnel0_intensity;
			fresnel *= (1-mask);
		}

		
		reflection  = lerp(reflection, reflection * diffuse_reflection_mask, diffuse0_mask_reflection  );
		// Fresnel Reflection Masking
		reflection  *= fresnel;
	}

    //.. Finalize Output Color
    float4 out_color;
	//float4 out_color = float4(shader_data.common.vertexColor.aaa,1);

    out_color.rgb = diffuse + specular;
 	out_color.a   = shader_data.common.albedo.a;

	out_color.rgb += reflection;

	return out_color;
}


#include "techniques.fxh"