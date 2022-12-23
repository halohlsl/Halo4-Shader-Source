// Author:	 hocoulby
// Date:	 04/06/12
//
// Surface Shader - Custom Character Blinn Shader with only Normal and Control Maps
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
// Control Map
/*
-          R: spec int
-          G: diffuse
-          B: gloss
*/


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

		
//#### ALBEDO
// Control Map for Specular, Gloss, Reflection , SelfIllum
		float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpDfGl_transform);
		float4 control_mask		= sample2DGamma(control_map_SpDfGl, control_map_uv);
		
		shader_data.common.albedo.rgb = albedo_tint * control_mask.g;
        shader_data.common.albedo.a = 1.0;

		shader_data.common.shaderValues.x = control_mask.r; // spec int
		shader_data.common.shaderValues.y = control_mask.b; // spec gloss
		
		
		
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
	specular *= shader_data.common.shaderValues.x * specular_col * specular_intensity;

	
	out_color.rgb = diffuse + specular;

	return out_color;
}


#include "techniques.fxh"