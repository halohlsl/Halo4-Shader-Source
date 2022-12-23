//
// File:	 srf_ward.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Ward specular model shader, defaults to isotropic
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

#if !defined(VERTEX_BLEND)
#define DISABLE_VERTEX_COLOR
#endif

#if !defined(ANISOTROPIC_WARD)
#define DISABLE_LIGHTING_TANGENT_FRAME
#endif

// Ward is generally used only on relatively angular/flat surfaces, where the sharpened fallof has less effect
#define DISABLE_SHARPEN_FALLOFF


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
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
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
DECLARE_FLOAT_WITH_DEFAULT(aniso_power_x, "Specular Power X", "", 0, 1.0, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(aniso_power_y, "Specular Power Y", "", 0, 1.0, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,	    "Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_lod,		    "Reflection	Blur", "", 0, 10, float(0.0));
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


// Fill Lighting
#if defined(USE_DIFFUSE_FILL)
	DECLARE_FLOAT_WITH_DEFAULT(direct_fill_int,  "Direct Fill Intensity", "", 0, 1, float(0.15));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(indirect_fill_int, "Indirect Fill Intensity", "", 0, 1, float(0.15));
	#include "used_float.fxh"
#endif

#if defined(DIRT_LAYER)
// Dirt layer
#if !defined(VERTEX_BLEND)
DECLARE_SAMPLER_NO_TRANSFORM( blend_map, "Blend Map", "Blend Map", "shaders/default_bitmaps/bitmaps/default_black_diff.tif")
#include "next_texture.fxh"
#endif

DECLARE_SAMPLER( dirt_map, "Dirt Map", "Dirt Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(dirt_tint,	"Dirt Map Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(height_influence, "Height Map Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(threshold_softness, "Height Map Threshold Softness", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

struct s_shader_data {
	s_common_shader_data common;

	float4 specular_mask;               // specular sampler
	float2 aniso_roughness;				// roughness of aniso specualar
	float3 reflection;		     		// reflection
    float reflection_mask ;

};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

#if defined(DIRT_LAYER)

	// dirt mask
	float2 dir_map_uv 	     = transform_texcoord(uv, dirt_map_transform);
	float4 dirt_map_sampled  = sample2DGamma(dirt_map, dir_map_uv);
	dirt_map_sampled.rgb *= dirt_tint;

#if !defined(VERTEX_BLEND)
	float2 blend_map_uv 	 = transform_texcoord(pixel_shader_input.texcoord.zw, float4(1,1,0,0));
	float4 blend_map_sampled = sample2DGamma(blend_map, blend_map_uv);

	float3 dirt_mask = saturate( (blend_map_sampled - ( 1 - dirt_map_sampled.a )) / max(0.001, threshold_softness)  );
	dirt_mask = lerp( blend_map_sampled, dirt_mask, height_influence);
#else
	float3 dirt_mask = saturate( (shader_data.common.vertexColor.a  - ( 1 - dirt_map_sampled.a )) / max(0.001, threshold_softness)  );
	dirt_mask = lerp( shader_data.common.vertexColor.a, dirt_mask, height_influence);
#endif

#endif

    {// Sample color map.
	    float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo  = sample2DGamma(color_map, color_map_uv);

		shader_data.common.albedo.rgb *= albedo_tint;
		shader_data.common.albedo.a = 1.0f;
#if defined(DIRT_LAYER)
		// blend over dirt
		shader_data.common.albedo.rgb  = lerp(shader_data.common.albedo.rgb, dirt_map_sampled.rgb, dirt_mask );
		shader_data.common.albedo.a = saturate(1-dirt_mask.r);
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

#if defined(ANISOTROPIC_WARD)
		shader_data.aniso_roughness = float2(calc_roughness(shader_data.specular_mask.g) * aniso_power_x,
										     calc_roughness(shader_data.specular_mask.b) * aniso_power_y);
#else
		shader_data.aniso_roughness.xy = calc_roughness(shader_data.specular_mask.g) * aniso_power_x;
#endif
	}
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo          = shader_data.common.albedo;
    float3 normal          = shader_data.common.normal;
    float4 specular_mask   = shader_data.specular_mask;
    float2 aniso_roughness = shader_data.aniso_roughness;



    float3 diffuse = 0.0f;
    { // Compute Diffuse

        #if defined(USE_DIFFUSE_FILL)
            calc_diffuse_lambert_fill(
                        diffuse,
                        shader_data.common,
                        normal,
                        direct_fill_int,
                        indirect_fill_int);
        #else
            // using standard lambert model
            calc_diffuse_lambert(diffuse, shader_data.common, normal);
        #endif
    }


	float3 specular = 0.0f;
	{ // Compute Specular

		// using ward specular model
		calc_specular_ward(specular, shader_data.common, normal, albedo.a, aniso_roughness);

		// mix specular_color with albedo_color
		float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

		// modulate by mask, color, and intensity
		specular *= specular_mask.r * specular_col * specular_intensity;
	}

	float fresnel = 0.0f;
	{ // Compute fresnel to modulate reflection

		float3 view = -shader_data.common.view_dir_distance.xyz;
		float  vdotn = saturate(dot(view, normal));

		fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
		fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
	}

	float3 reflection = 0.0f;
	float reflectionScale = reflection_intensity * specular_mask.a * lerp(1.0, fresnel, fresnel_mask_reflection);

	if (AllowReflection(shader_data.common) && reflectionScale > 0)
	{ // sample reflection cube map
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = 0.0f;
		rVec.xyz = reflect(view, normal);

		reflection = sampleCUBEGamma(reflection_map, rVec).rgb;

		reflection *= (reflection_color * diffuse) * reflectionScale;
	}



    //.. Finalize Output Color
    float4 out_color;

    out_color.rgb = (albedo.rgb * diffuse * diffuse_intensity) + specular + reflection ;
    out_color.a   = 1.0f;

	return out_color;
}


#include "techniques.fxh"
