//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Custom Character Specific Blinn Shader
//
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
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRfSi", "Control Map SpGlRfSi", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
		
#if defined(REFLECTION)
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
#endif

// Albedo
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


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



#if defined(REFLECTION)
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
#endif


// Self Illum
#if defined(SELFILLUM)
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

#if defined(OCCLUSION)
	DECLARE_SAMPLER_NO_TRANSFORM( occ_map_uv2, "Occlusion Map Uv2", "Occlusion Map Uv2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
	#include "next_texture.fxh"
	DECLARE_RGB_COLOR_WITH_DEFAULT(occlusion_tint,	"Occlusion Tint", "", float3(0.25,0.25,0.25));
	#include "used_float3.fxh"
#endif


#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
static const float clip_threshold = 240.0f / 255.0f;
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
	    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
		
#if defined(ALPHA_CLIP)
		// Tex kill pixel
		clip(shader_data.common.albedo.a - clip_threshold);
#endif
			
		shader_data.common.albedo.rgb *= albedo_tint;
		shader_data.common.shaderValues.x = shader_data.common.albedo.a;        
		shader_data.common.albedo.a = 1.0;


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


//#### RELFECTION - FRESNEL MASK
#if defined(REFLECTION)
		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection
			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot(view, shader_data.common.normal));
			fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
			fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
		}

		// Fresnel mask for reflection
		shader_data.common.shaderValues.y = lerp(1.0, fresnel, fresnel_mask_reflection);
#endif

#if  defined(OCCLUSION)
	#if !defined(REFLECTION)
		float2 occ_map_uv = transform_texcoord(pixel_shader_input.texcoord.zw, float4(1,1,0,0));	
		shader_data.common.shaderValues.y = sample2DGamma(occ_map_uv2, occ_map_uv);	 
	#endif	
#endif

}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	//..  Output Color
    float4 out_color = float4(1,1,1,shader_data.common.shaderValues.x);
	
	
	// Control Map for Specular, Gloss, Reflection , SelfIllum
	float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpGlRf_transform);
	float4 control_mask		= sample2DGamma(control_map_SpGlRf, control_map_uv);
	
	
//!-- Diffuse Lighting
    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
    diffuse_reflection_mask = diffuse;
    diffuse *= shader_data.common.albedo.rgb * diffuse_intensity;

		
//!-- Specular Lighting				
    float3 specular = 0.0f;
	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(control_mask.g, specular_power_min, specular_power_max );
	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, shader_data.common.albedo.a, power);		
    float3 specular_col = lerp(specular_color, shader_data.common.albedo.rgb, specular_mix_albedo);
	specular *= control_mask.r * specular_col * specular_intensity;

	
// Add diffuse and specular to outcolor
	out_color.rgb = diffuse + specular;
	

	
//!-- Reflection 

#if defined(REFLECTION)
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

#endif


	
//!-- Occlusion
  
#if defined(OCCLUSION)
	float3 occlusion = 0.0f;
	
	#if !defined(REFLECTION)
		// when reflection is not used passed in from the albedo shader to improve pixel shader perf
		occlusion = shader_data.common.shaderValues.y;
	#else
		// otherwise we need to sample in the pixel shader. 
		float2 occ_map_uv = transform_texcoord(pixel_shader_input.texcoord.zw, float4(1,1,0,0));	
		occlusion = sample2DGamma(occ_map_uv2, occ_map_uv);
	#endif

	out_color.rgb *= lerp(occlusion_tint * (out_color.rgb-specular), float3(1,1,1), occlusion) ;

#endif

	
#if defined(SELFILLUM)

	float si_mask = 1.0;
	// mask channel depends on wether reflection is used or not
	#if defined(REFLECTION)
		si_mask = control_mask.a;
	#else
		si_mask = control_mask.b;
	#endif
	
	// self illum
	if (AllowSelfIllum(shader_data.common))
	{
		float3 selfIllumColor = si_color;
		
		// support for multiplayer turrets in shader srf_char_mp_turret
		#if defined(SELFILLUM_TEAMCOLOR)
			#if defined(xenon) || (DX_VERSION == 11) // only apply on xbox and d3d11 otherwise use the si_color color in maya			
				selfIllumColor = ps_material_object_parameters[0]; // primary team color
			#endif
		#endif
	
		float3 selfIllum = shader_data.common.albedo.rgb * selfIllumColor * si_intensity * si_mask;
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