//
// File:	 srf_forerunner_parallax.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Custom parallax shader for forerunner surfaces
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//....Parameters

DECLARE_SAMPLER( color_map, "Color", "Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( depth_1_map, "Depth Map 1", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( depth_2_map, "Depth Map 2", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( depth_3_map, "Depth Map 3", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse_alpha_mask_specular, "Diffuse Alpha Masks Specular", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_amount,	"SelfIllum Amount", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(multiply_diff_on_depth, "Multiply Diff on Depth", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth1, "Depth R", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth2, "Depth G", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth3, "Depth B", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(depth1_tint,	"Depth Tint R", "", float3(0.4,0.4,0.4));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(depth2_tint,	"Depth Tint G", "", float3(0.2,0.2,0.2));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(depth3_tint,	"Depth Tint B", "", float3(0.05,0.05,0.05));
#include "used_float3.fxh"


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
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;
};



float2 parallax_texcoord(
                float2 uv,
                float  amount,
                float2 viewTS,
                s_pixel_shader_input pixel_shader_input
                )
{

    viewTS.y = -viewTS.y;
    return uv + viewTS * amount * 0.1;
}


/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

    float2 base_uv        = pixel_shader_input.texcoord.xy;

    float3   view          = shader_data.common.view_dir_distance.xyz;
    float3x3 tangent_frame = shader_data.common.tangent_frame;

#if !defined(cgfx)
	//(aluedke) The tangent frame is currently incorrect for transformations into UV space (the binormal is inverted).  Correct for this.
	tangent_frame[1] = -tangent_frame[1];
#endif

    float3   viewTS        = mul(tangent_frame, view);
    viewTS /= abs(viewTS.z);				// Do the divide to scale the view vector to the length needed to reach 1 unit 'deep'

    float2 normalMap_uv = transform_texcoord(base_uv, normal_map_transform);
    float3 normal       = sample_2d_normal_approx(normal_map, normalMap_uv);

    float2 colorMap_uv = transform_texcoord(base_uv, color_map_transform);
    float4 colorMap_sampled  = sample2DGamma(color_map, colorMap_uv);

    /// UV Transformations
    float2 uv_offset1 = parallax_texcoord(base_uv,
    							   depth1,
                                   viewTS,
                                   pixel_shader_input );

	float2 uv_offset2 = parallax_texcoord(base_uv,
								   depth2,
								   viewTS,
                                   pixel_shader_input );

	float2 uv_offset3 = parallax_texcoord(base_uv,
								   depth3,
								   viewTS,
                                   pixel_shader_input );

	uv_offset1 = transform_texcoord(uv_offset1, depth_1_map_transform);
	uv_offset2 = transform_texcoord(uv_offset2, depth_2_map_transform);
	uv_offset3 = transform_texcoord(uv_offset3, depth_3_map_transform);

	float3 dmap1_sampled  = sample2DGamma(depth_1_map, uv_offset1).r;
    float3 dmap2_sampled  = sample2DGamma(depth_2_map, uv_offset2).g;
    float3 dmap3_sampled  = sample2DGamma(depth_3_map, uv_offset3).b;

    dmap1_sampled.rgb *= depth1_tint;
    dmap2_sampled.rgb *= depth2_tint;
    dmap3_sampled.rgb *= depth3_tint;

    //shader_data.common.shaderValues.y = color_luminance(dmap1_sampled + dmap2_sampled + dmap3_sampled);
	
	//#if defined(MASK_PARALLAX)
	//	shader_data.common.shaderValues.y *= colorMap_sampled.a;
	//#endif
	

    {// Sample specular map.
    	float2 specular_map_uv	    = transform_texcoord(base_uv, specular_map_transform);
    	shader_data.common.shaderValues.x   = sample2DGamma(specular_map, specular_map_uv);
    }
	
	float specularMask = lerp(1.0f, shader_data.common.albedo.w, diffuse_alpha_mask_specular);
	shader_data.common.shaderValues.x *= specularMask;
	

	float3 multDiff = lerp(float3(1, 1, 1), colorMap_sampled.rgb, multiply_diff_on_depth); 
    //shader_data.common.albedo.rgb = colorMap_sampled.rgb;
	shader_data.common.albedo.rgb = lerp((dmap1_sampled + dmap2_sampled + dmap3_sampled) * multDiff , colorMap_sampled.rgb , colorMap_sampled.a) ;
	//shader_data.common.albedo.rgb = dmap1_sampled + dmap2_sampled + dmap3_sampled;//debug

    shader_data.common.albedo.rgb *= albedo_tint.rgb;
    shader_data.common.albedo.a = 1.0f;

	float fresnel = 0.0f;
	{ // Compute fresnel to modulate reflection
		float3 view = -shader_data.common.view_dir_distance.xyz;
		float  vdotn = saturate(dot(view, shader_data.common.normal));
		fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
		fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
	}

	// Fresnel mask for reflection
	shader_data.common.shaderValues.y = lerp(1.0, fresnel, fresnel_mask_reflection);
	
    shader_data.common.normal = mul(normal, shader_data.common.tangent_frame);

}

/// Pixel Shader - Lighting Pass


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

    // input from shader_data
    float4 out_color;
    float4 albedo  = shader_data.common.albedo;
	
    //float4 specular_mask  = shader_data.common.shaderValues.x;
    float3 normal = shader_data.common.normal;

	// Sample specular map
	float2 specular_map_uv	= transform_texcoord(uv, specular_map_transform);
	float4 specular_mask 	= sample2DGamma(specular_map, specular_map_uv);

	// Apply the specular mask from the albedo pass
	specular_mask.rgb *= shader_data.common.shaderValues.x;

		// Sample control mask
	float2 control_map_uv	= transform_texcoord(uv, control_map_SpGlRf_transform);
	float4 control_mask		= sample2DGamma(control_map_SpGlRf, control_map_uv);

	specular_mask.rgb *= control_mask.r;
    specular_mask.a  = control_mask.g;

	// Multiply the control mask by the reflection fresnel multiplier (calculated in albedo pass)
	float reflectionMask = shader_data.common.shaderValues.y * control_mask.b;
	
    float3 specular = 0.0f;
	//float specular_depth = 1.0f;
    {  
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );

	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);
		
		// mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);
		
		// modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_col * specular_intensity;
    }

    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }
	
	
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);
		
		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			reflectionMask *							// control mask reflection intensity channel * fresnel intensity
			reflectionMap.a;							// intensity scalar from reflection cube

		reflection = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
	}

    //.. Finalize Output Color
    out_color.rgb = diffuse + specular;
	out_color.rgb += reflection;
    out_color.a   = 1.0f;
	
	// self illum
	if (AllowSelfIllum(shader_data.common))
	{
		float3 selfIllum = albedo.rgb * si_color * si_intensity * control_mask.a;

		float3 si_out_color = out_color.rgb + selfIllum;
		float3 si_no_color  = out_color.rgb * (1-control_mask.a);

		out_color.rgb = lerp(si_no_color, si_out_color, min(1, si_amount));

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum);
	}
	
	return out_color;


}


#include "techniques.fxh"