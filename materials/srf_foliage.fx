//
// File:	 srf_foliage.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - basic foliage shader with back face lighting (simple translucence)
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

///
//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

#if defined(FOLIAGE_NORMAL)

DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

#endif


DECLARE_SAMPLER( control_map_SpGlTr, "Control Map SpGlTr", "Control Map SpGlTr", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"



// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,			"Diffuse Intensity", "", 0, 1, float(1.0));

// Specular

#if defined(FOLIAGE_SPECULAR)

DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,			"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,			"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,			"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,			"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


#endif

// Back Lighting
// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(translucent_color,	"Translucent Color", "", float3(0.6,0.7,0.4));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(translucent_intensity,		"Translucent Intensity", "", 0, 1, float(0.1));
#include "used_float.fxh"

#if defined(FOLIAGE_ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,				"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif

// a couple parameters for vertex animation
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_frequency,	"Foliage Animation Frequency", "", 0, 1, float(360.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_intensity,	"Foliage Animation Intensity", "", 0, 1, float(0.04));
#include "used_vertex_float.fxh"


struct s_shader_data {
	s_common_shader_data common;

	float4 control_mask;               // specular sampler
	float alpha;
};


#if defined(xenon) || defined(cgfx) || (DX_VERSION == 11)

float PeriodicVibration(in float animationOffset)
{
#if !defined(cgfx)
	float vibrationBase = 2.0 * abs(frac(animationOffset + animation_frequency * vs_time.z) - 0.5);
#else
	float vibrationBase = 2.0 * abs(frac(animationOffset + animation_frequency * frac(vs_time.x/600.0f)) - 0.5);
#endif
	return sin((0.5f - vibrationBase) * 3.14159265f);
}

float3 GetVibrationOffset(in float2 texture_coord, float animationOffset)
{
	float2 vibrationCoeff;
    float distance = frac(texture_coord.x);

	float id = texture_coord.x - distance + animationOffset;
	vibrationCoeff.x = PeriodicVibration(id / 0.53);

	id += floor(texture_coord.y) * 7;
	vibrationCoeff.y = PeriodicVibration(id / 1.1173);

	float2 direction = frac(id.xx / float2(0.727, 0.371)) - 0.5;

	return distance * animation_intensity * vibrationCoeff.xxy * float3(direction.xy, 0.3f);
}

#define custom_deformer(vertex, vertexColor, local_to_world)			\
{																		\
	float animationOffset = dot(float3(1,1,1), vertex.position.xyz);	\
	vertex.position.xyz += GetVibrationOffset(vertex.texcoord.xy, animationOffset);\
}

#endif


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;


    {// Sample color map.
	    float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

		// Tex kill pixel for clipping
		#if defined(FOLIAGE_ALPHA_CLIP)
			clip(shader_data.common.albedo.a - clip_threshold);
			shader_data.alpha = 1.0f;
		#else
			shader_data.alpha = shader_data.common.albedo.a;
		#endif

		shader_data.common.albedo.rgb *= albedo_tint.rgb;
        shader_data.common.albedo.a = shader_data.alpha;
    }

	#if defined(FOLIAGE_NORMAL)

    {// Sample normal map.
    	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
    	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
    	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }
	#endif

    {// Sample control map.
    	float2 control_mask_uv	  = transform_texcoord(uv, control_map_SpGlTr_transform);
    	shader_data.control_mask  = sample2DGamma(control_map_SpGlTr, control_mask_uv);

    }



}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;
	float4 control_mask   = shader_data.control_mask;

    float3 specular = 0.0f;
	{ // Compute Specular
		#if defined(FOLIAGE_SPECULAR)

			// pre-computing roughness with independent control over white and black point in gloss map
			float power = calc_roughness(control_mask.g, specular_power_min, specular_power_max );
			// using blinn specular model
			calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);
			// mix specular_color with albedo_color
			float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);
			// modulate by mask, color, and intensity
			specular *= control_mask.r * specular_col * specular_intensity;

		#endif
	}

    float3 diffuse = 0.0f;
    { // Compute Diffuse Lighting

        // Fake Translucence
		float3 translucence = translucent_intensity * translucent_color * control_mask.b ;
        calc_diffuse_backlighting(diffuse, shader_data.common, normal, translucence);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = color_screen(diffuse, specular);
    out_color.a   = shader_data.alpha;

	return out_color;
}

#if defined(FOLIAGE_ALPHA_CLIP)
#define REQUIRE_Z_PASS_PIXEL_SHADER
#endif


#include "techniques.fxh"