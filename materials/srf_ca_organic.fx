//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Standard Blinn
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
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"

#if defined(REFLECTION)
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
#endif

// Texture controls
DECLARE_FLOAT_WITH_DEFAULT(color_tile_u, 			"Color Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_tile_v, 			"Color Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_u, 			"Normal Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_v, 			"Normal Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_tile_u, 		    "Specular Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_tile_v, 		    "Specular Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"

#if defined(COLOR_DETAIL)
DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_detail_tile_u,	    "Color Detail Tile U", "", 1, 64, float(16.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_detail_tile_v, 		"Color Detail Tile V", "", 1, 64, float(16.0));
#include "used_float.fxh"
#endif

#if defined(REFLECTION)
DECLARE_FLOAT_WITH_DEFAULT(control_tile_u, 		    "Control Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(control_tile_v, 		    "Control Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"
#endif

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(diffuse_color,		"Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(transmission_color,        "Transmission Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(transmission_pulse_speed,        "Transmission Pulse Speed", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(transmission_intensity,        "Transmission Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(transmission_offset,        "Transmission Offset", "", 0, 1, float(0.0));
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
DECLARE_FLOAT_WITH_DEFAULT(specular_power,		"Specular Power", "", 0, 100, float(60));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if defined(TWO_TONE_SPECULAR)
// Glancing specular
DECLARE_RGB_COLOR_WITH_DEFAULT(glancing_specular_color,"Glancing Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(5.0));
#include "used_float.fxh"
#endif

#if defined(REFLECTION)
// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_normal,		"Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

#if !defined(TWO_TONE_SPECULAR)
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
#endif

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
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_tile_u, 	"Detail Tile U", "detail_normals", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_tile_v, 	"Detail Tile V", "detail_normals", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(rim_color,        "Rim Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_power,        "Rim Power", "", 0, 20, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_intensity,        "Rim Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"


#if defined(PRIMARY_CHANGE_COLOR)
DECLARE_FLOAT_WITH_DEFAULT(pcc_amount, "Primary Change Color Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif


#if defined(USE_DIFFUSE_FILL)
	DECLARE_FLOAT_WITH_DEFAULT(direct_fill_int,  "Direct Fill Intensity", "", 0, 1, float(0.15));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(indirect_fill_int, "Indirect Fill Intensity", "", 0, 1, float(0.15));
	#include "used_float.fxh"
#endif

#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif

#if defined(PLASMA)
#include "shared/plasma.fxh"
#endif

struct s_shader_data {
	s_common_shader_data common;

    float4 specular_mask;
    float  alpha;

#if defined(REFLECTION)
	float4 control_mask;
	float3 reflection;
#endif
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;

    {
		// Sample specular map.
    	float2 specular_map_uv	  = transform_texcoord(uv, float4(specular_tile_u, specular_tile_v, 0, 0));
    	shader_data.specular_mask  = sample2DGamma(specular_map, specular_map_uv);
	}

    {// Sample and composite normal and detail maps.
    	float2 normal_uv   = transform_texcoord(uv, float4(normal_tile_u, normal_tile_v, 0, 0));
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);

    // composite detail normal map
	STATIC_BRANCH
	if (detail_normals)
	{
		float2 detail_uv = transform_texcoord(uv, float4(normal_detail_tile_u, normal_detail_tile_v, 0, 0));
		shader_data.common.normal = CompositeDetailNormalMap(shader_data.common,
															 base_normal,
															 normal_detail_map,
															 detail_uv,
															 normal_detail_dist_min,
															 normal_detail_dist_max);
	}
	else
	{
		shader_data.common.normal = base_normal;
	}

	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }

#if defined(REFLECTION)
	{
		// Sample control map.
    	float2 control_map_uv	    = transform_texcoord(uv, float4(control_tile_u, control_tile_v, 0, 0));
    	shader_data.control_mask    = sample2DGamma(control_map_SpGlRf, control_map_uv);
    }

	if (AllowReflection(shader_data.common))
	{ // sample reflection cube map
		float3 reflection = 0.0f;
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		shader_data.reflection = reflectionMap.rgb * reflection_intensity * reflection_color * shader_data.control_mask.b * reflectionMap.a;
	}
#endif

    {// Sample color map.
	    float2 color_map_uv = transform_texcoord(uv, float4(color_tile_u, color_tile_v, 0, 0));
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

#if defined(PRIMARY_CHANGE_COLOR)
        // apply primary change color
        float4 primary_cc = ps_material_object_parameters[2];
        float albedo_lum = color_luminance(shader_data.common.albedo.rgb);

        shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb,
                                             albedo_lum * primary_cc.rgb,
                                             primary_cc.a * pcc_amount);
#endif

#if defined(COLOR_DETAIL)
		const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)

	    float2 color_detail_map_uv = transform_texcoord(uv, float4(color_detail_tile_u, color_detail_tile_v, 0, 0));
	    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
	    color_detail.rgb *= DETAIL_MULTIPLIER;

		shader_data.common.albedo.rgb *= color_detail;
		shader_data.specular_mask.rgb *= shader_data.common.albedo.w;

#if defined(REFLECTION)
		shader_data.reflection *= shader_data.common.albedo.w;
#endif
#else
		float specularMask = lerp(1.0f, shader_data.common.albedo.w, diffuse_alpha_mask_specular);
		shader_data.specular_mask.rgb *= specularMask;
#if defined(REFLECTION)
		shader_data.reflection *= specularMask;
#endif
#endif

#if defined(FIXED_ALPHA)
        float2 alpha_uv		= transform_texcoord(uv, float4(1, 1, 0, 0));
		shader_data.alpha	= sample2DGamma(color_map, alpha_uv).a;
#else
        shader_data.alpha	= shader_data.common.albedo.a;
#endif

#if defined(ALPHA_CLIP) && defined(xenon)
		// Tex kill pixel
		clip(shader_data.alpha - clip_threshold);
#endif

		shader_data.common.albedo.a = shader_data.alpha;
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

#if defined(REFLETION)
	specular_mask.rgb *= shader_data.control_mask.r;
    specular_mask.a  = shader_data.control_mask.g;
#endif

    float3 specular = 0.0f;
	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = specular_power * specular_mask.r;

	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

#if defined(TWO_TONE_SPECULAR)
        // Use the view angle to mix the two specular colors, as well as the albedo color
        float3 specular_col = CalcSpecularColor(
        	-shader_data.common.view_dir_distance.xyz,
        	normal,
        	albedo.rgb,
        	specular_mix_albedo,
        	specular_color,
        	glancing_specular_color,
        	fresnel_power);
#else
        // mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);
#endif

        // modulate by mask, color, and intensity
        specular *= specular_mask.g * specular_col * specular_intensity;
	}

	float3 base_diffuse = 0.0f;
    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
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

		// Store the mask for diffuse reflection
        diffuse_reflection_mask = diffuse;
        base_diffuse = diffuse;
        // modulate by albedo, color, and intensity
        float vibration = sin(ps_time.x * transmission_pulse_speed)/2 + .5 + transmission_offset  ;
        diffuse += transmission_color * specular_mask.b * vibration * transmission_intensity;
    	diffuse *= albedo.rgb * diffuse_color * diffuse_intensity;

    }



#if defined(REFLECTION)
	float3 reflection = shader_data.reflection;
	{
		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection

			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot( view, normal));
			fresnel = lerp(vdotn, saturate(1 - vdotn), fresnel_inv);
			fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
		}

		// Fresnel Reflection Masking
		reflection  = lerp(reflection, reflection*fresnel, fresnel_mask_reflection);
		reflection  = lerp(reflection , reflection*diffuse_reflection_mask, diffuse_mask_reflection);
	}
#endif

    //.. Finalize Output Color
    float4 out_color;

    //.. Fresnel Calculations
    float3 view = normalize(-shader_data.common.view_dir_distance.xyz);
    float base_fresnel = 1- saturate(dot(shader_data.common.normal, view));
    float3 fresnel = pow(base_fresnel, rim_power) * rim_intensity * base_diffuse * rim_color * specular_mask.g;



	out_color.rgb = diffuse + specular + fresnel;
//	out_color.rgb = float3( vibration,  vibration,vibration);
	out_color.a   = shader_data.alpha;

#if defined(REFLECTION)
	if (AllowReflection(shader_data.common))
	{
		out_color.rgb += reflection;
	}
#endif

#if defined(PLASMA)
	out_color.rgb += GetPlasmaColor(pixel_shader_input);
#endif

	return out_color;
}


#include "techniques.fxh"