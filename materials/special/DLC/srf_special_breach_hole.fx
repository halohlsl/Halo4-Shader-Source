//
// File:	 srf_special_lava_rock_dipper.fx
// Author:	 inyoungyang
// Date:	 04/12/12
//
// Surface Shader - Blinn Variation
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

// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(si_amount,	"SelfIllum Amount", "", 0, 1, float(1.0));
//#include "used_float.fxh"

//Lava Control
DECLARE_FLOAT_WITH_DEFAULT(lava_height,		"Lava Height", "", -500, 500, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lava_falloff,		"Lava Falloff Height", "", .1, 2, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lava_falloff_vert,		"Lava Falloff Vertex", "", .1, 2, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(occlusion_intensity,		"Occlusion Intensity", "", 0, 2, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(dark_edge_bias,		"Dark Edge Bias", "", 0.5, 2, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(dark_edge_intensity,		"Dark Edge Intensity", "", 0, 1, float(1));
#include "used_float.fxh"


// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"


DECLARE_SAMPLER( control_map_SiRf, "Control Map SiRf", "Control Map SiRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"

#if defined(REFLECTION)
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
#endif

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

#if defined(REFLECTION)
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif

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

#if defined(REFLECTION)
// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_mask_power,		"Reflection Mask Power", "", 0, 10, float(0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_normal,		"Reflection Normal", "", 0, 1, float(0.0));
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
#endif

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
    float3 self_illum;
    float  alpha;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;


	// Sample color map.
	float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);//sample2DGamma(color_map, color_map_uv);
	
		//Caculate lava mask using world position, occlusion mask and vertex color
	
		float lava_mask = 0.0f ;
				
			#if defined(cgfx)
			lava_mask = 0.0f ;
			#else
			lava_mask = 1 -(shader_data.common.position.z - lava_height) / lava_falloff ; //Use World Z position as lava mask
			lava_mask = max ( 0, lava_mask ) ;
			#endif


		float vertOcclusion = 1 - lerp(1.0f, shader_data.common.vertexColor.a, vert_occlusion_amt); // Using vert color as lava mask instead of vert occlusion
		vertOcclusion = vertOcclusion / lava_falloff_vert ;
		lava_mask = lava_mask + vertOcclusion ;

				

		float2 control_map_uv	= transform_texcoord(uv, control_map_SiRf_transform);
		float4 control_mask		= sample2DGamma(control_map_SiRf, control_map_uv);
		float occlusion = control_mask.r * occlusion_intensity ; //Add occlusion map to lava mask
		lava_mask = lava_mask - occlusion ;

		

			
			
		float si_mask = 0.0f ; //self illum mask
		si_mask = saturate( lava_mask ) ; 
		shader_data.common.shaderValues.y = si_mask ;
		
		
		float dark_edge_mask = 1 - lava_mask - dark_edge_bias; //Darkening around lava
		dark_edge_mask = clamp( dark_edge_mask, 1 - dark_edge_intensity, 1) ;
		shader_data.common.albedo *= dark_edge_mask;
	

	
	//Specular Mask	
	float specularMask = lerp(1.0f, shader_data.common.albedo.w, diffuse_alpha_mask_specular);
	shader_data.common.shaderValues.x = 1.0f; 			// Default specular mask
	shader_data.common.shaderValues.x *= specularMask;


	shader_data.common.albedo.rgb *= albedo_tint;



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
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
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

    if (AllowSelfIllum(shader_data.common))
    {
		out_color.rgb += si_color * si_intensity * shader_data.common.shaderValues.y;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(shader_data.self_illum);
	}

#if defined(REFLECTION)
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{
		//Fresnel
		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection
			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot(view, shader_data.common.normal));
			fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
			fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
		}		
		float reflectionMask = lerp(1.0, fresnel, fresnel_mask_reflection);
		//Control Mask
		reflectionMask = reflectionMask * pow(( 1 - shader_data.common.shaderValues.y ),reflection_mask_power);
		
		
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			reflectionMask *							// control mask reflection intensity channel 
			reflectionMap.a;							// intensity scalar from reflection cube

		reflection = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
	}
	out_color.rgb += reflection;
#endif

	return out_color;
}


#include "techniques.fxh"