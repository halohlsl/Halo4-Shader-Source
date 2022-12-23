// Author:	 hocoulby
// Date:	 03/28/12
//
// Surface Shader - Custom Character Forerunner Shader
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

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
DECLARE_SAMPLER( control_map_GlSpRfDf, "Control Map GlSpRfDf", "Control Map GlSpRfDf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"

#if defined(COLOR_DETAIL)
DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
#endif



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



// Self Illum
#if defined(SELFILLUM)
	DECLARE_SAMPLER(selfillum_map,  "Self Illum Map", "", "shaders/default_bitmaps/bitmaps/color_white_alpha_black.tif")
	#include "next_texture.fxh"
	DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
	#include "used_float3.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(si_amount,	"SelfIllum Amount", "", 0, 1, float(1.0));
	#include "used_float.fxh"
#endif


// DETAIL NORMAL
#if defined(DETAIL_NORMAL)
	DECLARE_SAMPLER(normal_detail_map,	"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
	#include "used_float.fxh"
#endif



struct s_shader_data {
	s_common_shader_data common;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;


//#### CONTROL MASK
		float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_GlSpRfDf_transform);
		float4 control_mask		= sample2DGamma(control_map_GlSpRfDf, control_map_uv);


//#### ALBEDO
		shader_data.common.albedo.rgb = albedo_tint * control_mask.a;
        shader_data.common.albedo.a = 1.0;

		// Detail color
		#if defined(COLOR_DETAIL)
			const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)

			float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
			float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
			color_detail.rgb *= DETAIL_MULTIPLIER;

			shader_data.common.albedo.rgb *= color_detail;
		#endif



		#if defined(SELFILLUM)
			float2 map_uv      = transform_texcoord(uv, selfillum_map_transform);
			shader_data.common.shaderValues.x = sample2DGamma(selfillum_map, map_uv).r;
		#endif


//#### NORMAL
		// Sample normal maps
    	float2 normal_uv    = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);


#if defined(DETAIL_NORMAL)
		// Composite detail normal map onto the base normal map
		float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
		shader_data.common.normal = CompositeDetailNormalMap(
															shader_data.common,
															base_normal,
															normal_detail_map,
															detail_uv,
															normal_detail_dist_min,
															normal_detail_dist_max);
#else
		shader_data.common.normal = base_normal;
#endif

		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);


//#### RELFECTION FRESNEL

		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection
			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot(view, shader_data.common.normal));
			fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
			fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
		}

		// Fresnel mask for reflection
		shader_data.common.shaderValues.y = lerp(1.0, fresnel, fresnel_mask_reflection);


}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	//..  Output Color
    float4 out_color = 1.0;


// Control Map for Specular, Gloss, Reflection , SelfIllum
	float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_GlSpRfDf_transform);
	float4 control_mask		= sample2DGamma(control_map_GlSpRfDf, control_map_uv);


//!-- Diffuse Lighting
    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
    diffuse_reflection_mask = diffuse;
    diffuse *= shader_data.common.albedo.rgb;


//!-- Specular Lighting
    float3 specular = 0.0f;
	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(control_mask.r, specular_power_min, specular_power_max );
	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, shader_data.common.albedo.a, power);
    float3 specular_col = lerp(specular_color, shader_data.common.albedo.rgb, specular_mix_albedo);
	specular *= control_mask.g * specular_col * specular_intensity;


	out_color.rgb = diffuse + specular;


//!-- Reflection
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common)) {

		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view,  shader_data.common.normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *								// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			control_mask.b *								// control mask reflection intensity channel
			shader_data.common.shaderValues.y * // Fresnel Intensity
			reflectionMap.a;								// intensity scalar from reflection cube

		reflection = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
		out_color.rgb += reflection;
	}


#if defined(SELFILLUM)
	float si_mask = 1.0;
	// self illum
	if (AllowSelfIllum(shader_data.common))
	{
		// Control Map for Specular, Gloss, Reflection , SelfIllum
		si_mask	*= shader_data.common.shaderValues.x;

		float3 selfIllum = shader_data.common.albedo.rgb * si_color * si_intensity * si_mask;
		float3 si_out_color = out_color.rgb + selfIllum;
		float3 si_no_color  = out_color.rgb * (1-si_mask);

		out_color.rgb = lerp(si_no_color, si_out_color, min(1, si_amount));

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum);
	}
#endif


	return out_color;
}


#include "techniques.fxh"