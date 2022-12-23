//
// File:	 srf_char_visor.fx
// Author:	 hocoulby
//
// Character Visor shader for MC and MP
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


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"

//.. Artistic Parameters

// Texture Samplers
// do not require the color map sampler for multiplayer assets
#if !defined(MULTIPLAYER)
	DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
	#include "next_texture.fxh"
#endif

DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

/// differnt pack order for control map
#if defined(MULTIPLAYER)
	DECLARE_SAMPLER( control_map_SpDfGlRf, "Control Map SpDfGlRf", "Control Map SpDfGlRf", "shaders/default_bitmaps/bitmaps/default_spec.tif")
	#include "next_texture.fxh"
#else
	DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_spec.tif")
	#include "next_texture.fxh"
#endif


DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(front_color,	"Front Color Tint", "", float3(0.47,0.14,0.14));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(rim_color,	"Rim Color Tint", "", float3(0.59,0.94,0.97));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(front_color_power, "Color Power", "", 0, 10, float(7.0));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// there is no specular gloss in the control map when using the mp variation, provide only a single specular power
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(specular_phong_power,	"Specular Phong Power", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_phong_color,	"Specular Phong Color", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(visor_saturation, "Visor Saturation", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(visor_intensity,	"Visor Total Intensity", "", 0, 1, float(1));
#include "used_float.fxh"






// Reflection
// reflection color is set by mp change colors, show only if using the non mp variation
//DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
//#include "used_float3.fxh"






struct s_shader_data {
	s_common_shader_data common;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	// dont need to sample color map in MP variaion
	#if !defined(MULTIPLAYER)
		float2 color_map_uv = transform_texcoord(uv, color_map_transform);
		shader_data.common.albedo  = sample2DGamma(color_map, color_map_uv);
	#else
		shader_data.common.albedo = 1.0;
	#endif

	shader_data.common.albedo.a = 1.0f;

	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
    shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

	shader_data.common.shaderValues.x = saturate( dot(shader_data.common.normal, -shader_data.common.view_dir_distance.xyz) );
	float  fresnel = pow(shader_data.common.shaderValues.x, front_color_power);

// Override the front and rim colors with the change colors if valid
	float3 front_color_cc = front_color;
	float3 rim_color_cc   = rim_color;

	// apply the change colors when in MP
	#if defined(MULTIPLAYER)
		front_color_cc = ps_material_object_parameters[2];
		rim_color_cc = ps_material_object_parameters[3];
	#endif

	//float3 front_color_cc = lerp(front_color, ps_material_object_parameters[0], ps_material_object_parameters[0].w * change_color_intensity);
	//float3 rim_color_cc = lerp(rim_color, ps_material_object_parameters[1], ps_material_object_parameters[1].w * change_color_intensity);

    shader_data.common.albedo.rgb  *= lerp(rim_color_cc, front_color_cc, fresnel);
}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo = shader_data.common.albedo;
    float3 normal = shader_data.common.normal;
	float3 ndotv  = shader_data.common.shaderValues.x;

	// Sample control mask
	// different pack order for the MP variation, define which one to sample
	#if defined(MULTIPLAYER)
		// spec intensity, diffuse intensity, and reflection
		float2 control_map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpDfGlRf_transform);
		float4 control_mask = sample2DGamma(control_map_SpDfGlRf, control_map_uv);
	#else
		// spec intensity, gloss, and reflection
		float2 control_map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpGlRf_transform);
		float4 control_mask = sample2DGamma(control_map_SpGlRf, control_map_uv);
	#endif


// Diffuse lighting
    float3 diffuse = 0.0f;
	calc_diffuse_lambert(diffuse, shader_data.common, normal);
	float diffuse_mask = dot(float3(0.33, 0.33, 0.33), diffuse);

	//diffuse *= albedo.rgb;

	// scale diffuse by control map
	#if defined(MULTIPLAYER)
		diffuse_mask *= control_mask.g;
	#endif


// Specular Lighting
	float3 specular = 0.0f;

	// there is no specular gloss control in the MP shader.
	#if defined(MULTIPLAYER)
		float power = calc_roughness(control_mask.b, specular_power_min, specular_power_max);
	#else
		float power = calc_roughness(control_mask.g, specular_power_min, specular_power_max);
	#endif

	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

	float3 spec_color = specular_color;	// from user param

	#if defined MULTIPLAYER
		// use the color defined by biped change colors
		spec_color = ps_material_object_parameters[2];
	#endif

	spec_color = lerp(spec_color, albedo.rgb * spec_color, 0.9);

	specular *=  spec_color * specular_intensity * control_mask.r;


	float3 specular_phong = 0.0f;
	power = calc_roughness(specular_phong_power);
	calc_specular_phong(specular_phong, shader_data.common, normal, albedo.a, power);
	specular += specular_phong * specular_phong_color;//



// Reflection
	float3 reflection = 0.0f;
	float4 rVec = 0.0f;
	float3 view = shader_data.common.view_dir_distance.xyz;
	rVec.xyz = reflect(view, normal);

	float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

	// A very hacked approach attemping create the same result as the photoshop color blend mode
	float3 top = albedo.rgb;//* diffuse;
	float3 bkg = reflectionMap.rgb * reflectionMap.a;// * diffuse_mask;

	float topLuma = color_luminance(top);
	float bkgLuma = color_luminance(bkg);

	topLuma  = pow(topLuma, 0.5);    // sRGB
    bkgLuma = pow(bkgLuma, 0.5);   // sRGB

	float luminance = saturate(bkgLuma - topLuma);

	float3 blend = top;
	blend += luminance;

	blend = lerp(blend, top, luminance*0.75);
	blend = blend * blend; // linear

	reflection  =  blend;
	reflection *= diffuse_mask;

    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = reflection + specular;

	out_color.rgb = color_saturation(out_color.rgb, visor_saturation);
	out_color.rgb *= visor_intensity;


    out_color.a   = 1.0f;


	return out_color;
}


#include "techniques.fxh"