// Author:	 hocoulby
// Date:	 03/28/12
//
// Surface Shader - Custom Character Forerunner Shader as requested by Andrew Bradbury
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//
/*
Control Map
Rch = Specular & Reflection Mask
Gch = Diffuse Intensity
Bch = Gloss

Reflection is scaled by the specular mask stored in the red channel of the control map
additional gamma control over this mask has been provided to get some variation

Additional specular mask also provided to get high frequency detail

*/

#define DISABLE_VERTEX_COLOR
#define DISABLE_LIGHTING_TANGENT_FRAME

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( control_map_SpDfGl, "Control Map SpDfGl", "Control Map SpDfGl", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(specular_detail_map,		"Specular Detail Map", "Specular Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"

// Albedo
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity, "Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,	"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,	 "Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,	 "Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_mask_gamma,		"Reflection Mask Gamma", "", 0, 2, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,	"Fresnel Power", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity, "Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,	"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"	



struct s_shader_data {
	s_common_shader_data common;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;


//#### CONTROL	(Specular, Albedo, Gloss)
		float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpDfGl_transform);
		float3 control_mask		= sample2DGamma(control_map_SpDfGl, control_map_uv);

		float2 specular_detail_map_uv  = transform_texcoord(uv, specular_detail_map_transform);
		float  specular_detail_mask = sample2DGamma(specular_detail_map, specular_detail_map_uv).r;

		shader_data.common.shaderValues.x = specular_detail_mask * control_mask.r;
		shader_data.common.shaderValues.y = control_mask.b;


//#### ALBEDO
		shader_data.common.albedo.rgb = albedo_tint * control_mask.g;
        shader_data.common.albedo.a = 1.0;


//#### NORMAL
		// Sample normal maps
    	float2 normal_uv    = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);
		shader_data.common.normal = mul(base_normal, shader_data.common.tangent_frame);


}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	//..  Output Color
    float4 out_color = 1.0;

//!-- Diffuse Lighting
    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
    diffuse_reflection_mask = diffuse;
    diffuse *= shader_data.common.albedo.rgb;


//!-- Specular Lighting
    float3 specular = 0.0f;
	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(shader_data.common.shaderValues.y, specular_power_min, specular_power_max );
	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, shader_data.common.albedo.a, power);
    float3 specular_col = lerp(specular_color, shader_data.common.albedo.rgb, specular_mix_albedo);
	specular *= specular_col * specular_intensity * shader_data.common.shaderValues.x;


	out_color.rgb = diffuse + specular;


//!-- Reflection
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{
		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection
			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot(view, shader_data.common.normal));
			fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
			fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
			fresnel = lerp(1.0, fresnel, fresnel_mask_reflection);		// Fresnel mask for reflection
		}

		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view, shader_data.common.normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		// gamma control over reflection mask
		reflection =
			reflectionMap.rgb *																// reflection cube sample
			reflection_color *																// RGB reflection color from material
			reflection_intensity *															// scalar reflection intensity from material
			pow(shader_data.common.shaderValues.x, 1/reflection_mask_gamma) *			    // control mask reflection intensity channel
			fresnel *															 			// Fresnel Intensity
			reflectionMap.a;																// intensity scalar from reflection cube

		reflection = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
		out_color.rgb += reflection;
	}


	return out_color;
}


#include "techniques.fxh"