//
// File:	 srf_special_sky_ocean_calm.fx
// Author:	 inyoung
// Date:	 05/22/2012
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

//Normals
DECLARE_SAMPLER( normal_map, "Big Wave Normal Map", "Big Wave Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(big_normal_intensity,		"Big Wave Norma Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_SAMPLER( normal1_map, "Small Wave Normal Map", "Small Wave Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(small_normal_intensity,		"Small Wave Norma Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_dist_max,	"Normal Start Distance", "Normal Start Distance", 0, 200, float(120.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_dist_min, "Normal End Distance", "RNormal End Distance", 0, 200, float(50.0));
#include "used_float.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

#if defined(SPEC)
// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power,		"Specular Power", "", 0, 1, float(0.01));
#include "used_float.fxh"
#endif

// Reflection
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
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

DECLARE_FLOAT_WITH_DEFAULT(ref_dist_max,	"Reflection Start Distance", "Reflection Start Distance", 0, 200, float(120.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(ref_dist_min, "Reflection End Distance", "Reflection End Distance", 0, 200, float(50.0));
#include "used_float.fxh"

#if defined(DETAIL_NORMAL)
// Detail Normal Map
DECLARE_BOOL_WITH_DEFAULT(detail_normals, "Detail Normals Enabled", "", false);
#include "next_bool_parameter.fxh"

DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(normal_detail_control_map,		"Detail Normal Control Map", "detail_normals", "shaders/default_bitmaps/bitmaps/color_black.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(crest_normal_intensity, 	"Crest Normal Intensity.", "detail_normals", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(crest_diffuse_intensity, 	"Crest Diffuse Intensity.", "detail_normals", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_noise, 	"Detail Normal Noise.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(30.0));
#include "used_float.fxh"
#endif



struct s_shader_data {
	s_common_shader_data common;

    float  alpha;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	// COLOR /////////////////////////////////////////////////////////////
	    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
		shader_data.common.albedo.rgb *= albedo_tint;
		shader_data.common.albedo.a = 1.0;		
		// vertex color passed to pixel shader for alpha
		shader_data.common.shaderValues.x = shader_data.common.vertexColor.a;
		
		
		
	// NORMAL /////////////////////////////////////////////////////////////
    {
		// Sample two normal maps for wave
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 big_normal = sample_2d_normal_approx(normal_map, normal_uv);
		
		float2 normal1_uv   = transform_texcoord(uv, normal1_map_transform);
        float3 small_normal = sample_2d_normal_approx(normal1_map, normal1_uv);
		
		float3 base_normal = big_normal * big_normal_intensity ;
		base_normal.xy += small_normal.xy * small_normal_intensity ;	
	

#if defined(DETAIL_NORMAL)			
		STATIC_BRANCH
		if (detail_normals)
		{
			// Use detail normal for white crest				
			float2 detail_normal_uv = transform_texcoord(uv, normal_detail_map_transform);
			float2 detailNormal = sample2DVector(normal_detail_map, detail_normal_uv);
			float3 detailControl = sample2DVector(normal_detail_control_map, detail_normal_uv);
 
			//detail noraml distance is backwards in this case, to fade out up close
			float crestFade = float_remap( shader_data.common.view_dir_distance.w, normal_detail_dist_min, normal_detail_dist_max, 1, 0 );
			detailControl *= crestFade;			
			
			//crest normal intensity
			detailNormal *= crest_normal_intensity ;
						
			//add some animation on crest, G channel of control map
			detailNormal += small_normal.xy * detailControl.y * normal_detail_noise;
			
			detailNormal *= crest_normal_intensity ;
			base_normal.xy = base_normal.xy + detailNormal.xy;//blend in on the base normal
			
			//add white on crest, R channel of control map
			shader_data.common.albedo.rgb += detailControl.x * crest_diffuse_intensity ;				
		}
#endif
	
		//normal distance fade
		float normalFade = float_remap( shader_data.common.view_dir_distance.w, normal_dist_min, normal_dist_max, 1, 0 );
		base_normal.xy *= normalFade;	
		
		base_normal.z = sqrt(saturate(1.0f + dot(base_normal.xy, base_normal.xy)));//recompute z
		shader_data.common.normal = base_normal;
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
 
	}///////////////////////////////////////////////////////////////// NORMAL //


	float fresnel = 0.0f;
	{ // Compute fresnel to modulate reflection
		float3 view = -shader_data.common.view_dir_distance.xyz;
		float  vdotn = saturate(dot(view, shader_data.common.normal));
		fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
		fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
	}

	// Reflection Mask
	float ref_dist_falloff = float_remap( shader_data.common.view_dir_distance.w, ref_dist_min, ref_dist_max, 1, 0 );
	float reflection_mask = lerp(1.0, fresnel, fresnel_mask_reflection);//fresnel
	reflection_mask *= ref_dist_falloff;
	shader_data.common.shaderValues.y = reflection_mask;//pass it to lighting


}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;

	// masks from the albedo pass
	float reflectionMask = shader_data.common.shaderValues.y ;


    float3 specular = 0.0f;
#if defined(SPEC)
	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(specular_power);
	// using blinn specular model
	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);
	// modulate by mask, color, and intensity
	specular *= specular_color * specular_intensity;
#endif

    float3 diffuse = 0.0f;
	// using standard lambert model
	calc_diffuse_lambert(diffuse, shader_data.common, normal);
	// modulate by albedo, color, and intensity
	diffuse *= albedo.rgb * diffuse_intensity;

	
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view, normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			reflectionMask *							// control mask reflection intensity channel * fresnel intensity
			reflectionMap.a;							// intensity scalar from reflection cube

	}



	//.. Finalize Output Color
    float4 out_color;
	out_color.rgb = diffuse + specular + reflection;
	out_color.a   = shader_data.common.shaderValues.x;

	return out_color;
}


#include "techniques.fxh"