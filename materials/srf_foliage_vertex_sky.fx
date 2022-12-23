//
// File:	 srf_foliage_vertex.fx
// Author:	 aluedke
// Date:	 03/06/12
//
// Foliage shader with back face lighting (simple translucence)
// Vertex color controls amplitute of motion
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//


#define DISABLE_SHADOW_FRUSTUM_POS

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

///
//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER(color_map, 				"Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER(normal_map, 			"Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"



// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,			"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"



// Back Lighting
DECLARE_RGB_COLOR_WITH_DEFAULT(translucent_color,	"Translucent Color", "", float3(0.6,0.7,0.4));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(translucent_intensity,	"Translucent Intensity", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(translucent_alpha_scale,	"Translucent Alpha Scale", "", 0, 1, float(2.0f / 3.0f));
#include "used_float.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,			"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,			"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,			"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_alpha_scale,	"Specular Power Alpha Scale", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,			"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Clipping
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,				"Clipping Threshold", "", 0, 1, float(1.0f / 3.0f));
#include "used_float.fxh"


// a couple parameters for vertex animation
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_frequency,	"Foliage Animation Frequency", "", 0, 1, float(360.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_intensity,	"Foliage Animation Intensity", "", 0, 1, float(0.04));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_x,			"Foliage Animation Intensity", "", 0, 1, float(0.04));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_y,			"Foliage Animation Intensity", "", 0, 1, float(0.04));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_z,			"Foliage Animation Intensity", "", 0, 1, float(0.04));
#include "used_vertex_float.fxh"


struct s_shader_data
{
	s_common_shader_data common;
};


#if defined(xenon) || defined(cgfx) || (DX_VERSION == 11)

float PeriodicVibration(in float animationOffset)
{
#if !defined(cgfx)
	float timeValue = vs_time.z;
#else
	float timeValue = frac(vs_time.x/600.0f);
#endif

	float vibrationBase = 2.0 * abs(frac(animationOffset + animation_frequency * timeValue) - 0.5);

	return sin((0.5f - vibrationBase) * 3.14159265f);
}

float3 GetVibrationOffset(
	in float3 position,
	in float2 texcoord,
	in float4 color)
{
	float offset = dot((float3)1, position);

	float3 vibrationCoeff;

	float id = texcoord.x - offset;
	vibrationCoeff.x = PeriodicVibration(id / 0.53);

	id += texcoord.y * 7;
	vibrationCoeff.y = PeriodicVibration(id / 1.1173);

	id += texcoord.x * 5;
	vibrationCoeff.z = PeriodicVibration(id / 1.7221);

	float3 direction = float3(animation_x, animation_y, animation_z);

	return animation_intensity * color.a * vibrationCoeff * direction;
}

#define custom_deformer(vertex, vertexColor, local_to_world)			\
{																		\
	vertex.position.xyz += GetVibrationOffset(vertex.position.xyz, vertex.texcoord.xy, vertexColor);\
}

#endif


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{


	float2 uv = pixel_shader_input.texcoord.xy;

    {
		// Sample color map
	    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
		shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

		if (shader_data.common.lighting_mode == LM_ALBEDO)
		{
			// Tex kill pixel for clipping
			clip(shader_data.common.albedo.a - clip_threshold);
		}

		// Set the translucence intensity based on alpha value
		// Alpha 1.0 = Intensity 0.0
		// Alpha <clip> = Intensity <alpha scale>
		float translucenceIntensity = float_remap(shader_data.common.albedo.a, 1.0f, clip_threshold, 0.0f, translucent_alpha_scale);
		shader_data.common.shaderValues.x = translucenceIntensity;

		float specularPowerIntensity = float_remap(shader_data.common.albedo.a, 1.0f, clip_threshold, 0.0f, specular_power_alpha_scale);
		shader_data.common.shaderValues.y = specularPowerIntensity;

		shader_data.common.albedo.rgb *= albedo_tint.rgb;
    }

    {
		// Sample normal map
    	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
    	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
    	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo = shader_data.common.albedo;
    float3 normal = shader_data.common.normal;
	float translucenceIntensity	= shader_data.common.shaderValues.x;
	float specularPowerIntensity= shader_data.common.shaderValues.y;

	float3 specular = 0.0f;
	{ // Compute Specular
		// pre-computing roughness with independent control over white and black point in gloss map
		float power = calc_roughness(specularPowerIntensity, specular_power_min, specular_power_max);

		// using blinn specular model
		calc_specular_blinn(specular, shader_data.common, normal, specular_intensity, power);

		// mix specular and albedo color, and set final specular value
		specular *= lerp(specular_color, albedo.rgb, specular_mix_albedo);
	}

    float3 diffuse = 0.0f;
    { // Compute Diffuse Lighting

        // Fake Translucence
		float3 translucence = translucent_intensity * translucent_color * translucenceIntensity;
        calc_diffuse_backlighting(diffuse, shader_data.common, normal, translucence);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

    //.. Finalize Output Color
    float4 out_color;
	out_color.rgb = diffuse + specular;
    out_color.a   = 1.0;

	return out_color;
}

#if defined(FOLIAGE_ALPHA_CLIP)
#define REQUIRE_Z_PASS_PIXEL_SHADER
#endif


#include "techniques.fxh"
