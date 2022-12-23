//
// File:	 srf_env_m90_phong.fx
// Author:	 wesleyg
// Date:	 06/06/12
//
// Surface Shader - Optimized Phong Specular with Reflection specifically to address perf needs for M90_eye
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
#if defined(USE_COLOR)
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
#endif

#if defined(USE_NORMAL)
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
#endif

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

#if defined(USE_SPECULAR)
//Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

// Alpha clip threshold (only when alpha clip is used)
#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif

//Reflection
#if defined(REFLECTION)
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Global Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_lightIntensity,		"Reflection Light Side Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_darkIntensity,		"Reflection Dark Side Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_mask_brighten,		"Reflection Mask Dim", "", 0, 1, float(0.1));
#include "used_float.fxh"
#endif

#if defined(FADE_DETAIL)
DECLARE_FLOAT_WITH_DEFAULT(detail_fade_min,		"Detail Fade Min", "", 0, 9999, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_fade_max,		"Detail Fade Max", "", 0, 9999, float(500.0));
#include "used_float.fxh"
#endif

#if defined(NORMAL_DETAIL)
DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"
#endif


struct s_shader_data {
	s_common_shader_data common;
	float alpha;

};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv    		= pixel_shader_input.texcoord.xy;
	
	shader_data.common.albedo = float4(1.0f,1.0f,1.0f,1.0f);
	
	{// Sample color map.
    
#if defined(USE_COLOR)
        shader_data.common.albedo = sample2DGamma(color_map, uv);
        shader_data.alpha = shader_data.common.albedo.a;
#endif
        shader_data.common.albedo.rgb *= albedo_tint.rgb;
		
#if defined(PSEUDO_VERTEX_COLOR)
		shader_data.common.albedo.rgb *= shader_data.common.vertexColor.a;
#endif

#if defined(ALPHA_CLIP)
		// Alpha clip pixels
		clip(shader_data.alpha - clip_threshold);
#endif
    }
	
	shader_data.common.normal.xyz = float3(0.5,0.5,1.0);

#if defined(USE_NORMAL)
	 // Calculate the base normal map value
	shader_data.common.normal = sample_2d_normal_approx(normal_map, uv);
#endif
		
#if defined(NORMAL_DETAIL) && defined(USE_NORMAL) 
    {// Composite detail normal map onto the base normal map
		float2 detail_uv = pixel_shader_input.texcoord.xy;
#if defined(NORMAL_DETAIL_UV2)
		detail_uv =  pixel_shader_input.texcoord.zw;
#endif
		
		detail_uv = transform_texcoord(detail_uv, normal_detail_map_transform);
		
		shader_data.common.normal = CompositeDetailNormalMap(shader_data.common,
															 shader_data.common.normal,
															 normal_detail_map,
															 detail_uv,
															 normal_detail_dist_min,
															 normal_detail_dist_max);
	}
#endif

	// Transform from tangent space to world space
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

	float2 color_detail_uv   = pixel_shader_input.texcoord.xy;
#if defined(COLOR_DETAIL_UV2)
	color_detail_uv = pixel_shader_input.texcoord.zw;
#endif
	{//Control map
#if defined(REFLECTION)
	color_detail_uv = transform_texcoord(color_detail_uv, control_map_SpGlRf_transform);
	shader_data.common.shaderValues.xyz = sample2DGamma(control_map_SpGlRf, color_detail_uv).rgb;
#endif
	}


}

float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	// input from s_shader_data
	float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;

#if defined(REFLECTION)
	
#if defined(FADE_DETAIL)
	// Multiply the control mask by the reflection fresnel multiplier (calculated in albedo pass)
	float fade = (shader_data.common.view_dir_distance.w-detail_fade_min)/(detail_fade_max-detail_fade_min);
	reflectionMask = lerp(shader_data.common.shaderValues.z, 1, fade);
#endif

#endif

    float3 specular = 0.0f;
#if defined(USE_SPECULAR)
	{ // Compute Specular
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(1.0, specular_power_min, specular_power_max );
	    // using phong specular model
    	calc_specular_phong(specular, shader_data.common, normal, albedo.a, power);
		specular *= specular_color * specular_intensity * shader_data.common.shaderValues.x * (1-shader_data.common.shaderValues.y);
    }
#endif

    float3 diffuse = 0.0f;
	float luminance = 1.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);
		diffuse *= diffuse_intensity;
		luminance = diffuse.r;
        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb;
		
    }


#if defined(REFLECTION)
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view, shader_data.common.normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			(lerp(reflection_darkIntensity, reflection_lightIntensity, luminance) * reflection_intensity) *	
			reflectionMap.a *
			((shader_data.common.shaderValues.y * shader_data.common.shaderValues.x) + reflection_mask_brighten);
	}
	
#if defined(PSEUDO_VERTEX_COLOR)
		reflection *= shader_data.common.vertexColor.a;
#endif

#endif

#if defined(CHEAP_COLOR)
	diffuse *= shader_data.common.shaderValues.y * shader_data.common.shaderValues.x; //Add detail to cheap metal for M90
#endif
    //.. Finalize Output Color
    float4 out_color;

    out_color.rgb = diffuse + specular;
	
#if defined(REFLECTION)
	out_color.rgb += reflection;
#endif
	
    out_color.a   = shader_data.alpha;

	return out_color;
}


#include "techniques.fxh"