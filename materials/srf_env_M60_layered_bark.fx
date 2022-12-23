//
// File:	 srf_env_M60_layered_bark.fx
// Author:	 wesleyg
// Date:	 06/14/12
//
// Surface Shader - Performance Optimized layered shader for bark surfaces in M60 
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//... Base Layer
// colormap
DECLARE_SAMPLER( layer0_coMap, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_nmMap, "Layer0 Normal", "Layer0 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_co_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

 // specular control
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_sp_tint,	"Layer0 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_spPow,	"Layer0 Spec Pow", "", 0, 1, float(0.01));
#include "used_float.fxh"

// ... Red Layer
// Layer1

// Color Map
DECLARE_SAMPLER( layer1_coMap, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
#if !defined(DISABLE_LAYER1_NORMAL)
DECLARE_SAMPLER( layer1_nmMap, "Layer1 Normal", "Layer1 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
#endif
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_co_tint,	"Layer1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

 // specular control
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_sp_tint,	"Layer1 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_spPow,	"Layer1 Spec Pow", "", 0, 1, float(0.01));
#include "used_float.fxh"

#if !defined(DISABLE_LAYER1_NORMAL)
DECLARE_FLOAT_WITH_DEFAULT(layer0_normal_influnece, "Layer0 Normal Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

DECLARE_FLOAT_WITH_DEFAULT(layer1_alpha_amt, "Layer1 Alpha Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if !defined(DISABLE_LAYER2_COLOR)
// Color Map
DECLARE_SAMPLER( layer2_coMap, "Layer2 Color", "Layer2 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
#endif

#if !defined(DISABLE_LAYER1_NORMAL)
DECLARE_FLOAT_WITH_DEFAULT(layer01_normal_influnece, "Layer0-1 Normal Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

#if !defined(DISABLE_LAYER2_COLOR)
DECLARE_FLOAT_WITH_DEFAULT(layer2_alpha_amt, "Layer2 Alpha Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

struct s_shader_data {
	s_common_shader_data common;
	float3 layer0_specular;
	float3 layer1_specular;
};

/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;


    //----------------------------------------------
    // Sample blend values
    //----------------------------------------------
    float4 blend = float4(0, 0, 0, 0);
    shader_data.common.vertexColor.a *= 2;
    if (shader_data.common.vertexColor.a < 1.0)
	{
        blend.r = shader_data.common.vertexColor.a;
    }
	else
	{
        blend.g = shader_data.common.vertexColor.a - 1.0;
        blend.r = 1.0 - blend.g;
    }

    //----------------------------------------------
    // Sample layers
	//----------------------------------------------

	// Base Layer
    float2 layer0_uv	= transform_texcoord(uv, layer0_coMap_transform);
    float4 layer0_color	= sample2DGamma(layer0_coMap, layer0_uv);
	layer0_color.rgb *= layer0_co_tint;
    float3 layer0_normal  = sample_2d_normal_approx(layer0_nmMap, layer0_uv);
    shader_data.layer0_specular = float3(layer0_color.g, layer0_color.g, layer0_color.g); //Reuse color channel for specular map
	
	//Layer 1 = red
    float2 layer1_uv     = transform_texcoord(uv, layer1_coMap_transform);
    float4 layer1_color  = sample2DGamma(layer1_coMap, layer1_uv);
	layer1_color.rgb *= layer1_co_tint;
#if !defined(DISABLE_LAYER1_NORMAL)
	float3 layer1_normal = sample_2d_normal_approx(layer1_nmMap, layer1_uv);
#endif
	shader_data.layer1_specular = layer1_color.rgb; //Reuse color for specular map
	
	float layer1_mask = saturate(blend.r - layer1_alpha_amt);

#if !defined(DISABLE_LAYER2_COLOR)
	float4 layer2_color  = sample2DGamma(layer2_coMap, layer1_uv);
	float layer2_mask = saturate(blend.g - layer2_alpha_amt);
#endif
    
    //----------------------------------------------
    // Composite color maps, set output albedo value
    //----------------------------------------------
	
	float3 composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);

#if !defined(DISABLE_LAYER2_COLOR)
    composite_color = lerp(composite_color, layer2_color.rgb, layer2_mask);
#endif

    shader_data.common.albedo.rgb  = composite_color;
    shader_data.common.albedo.a    = 1.0;
	
    //----------------------------------------------
    // Composite normal maps, output normal
    //----------------------------------------------
    float3 composite_normal = layer0_normal;

#if !defined(DISABLE_LAYER1_NORMAL)
    float layer0_normal_mask = lerp(1 - blend.r, 1.0, layer0_normal_influnece);
    layer0_normal *= layer0_normal_mask;
    layer1_normal *= layer1_mask;

    // comp the two normals
    composite_normal.xy = layer0_normal.xy + layer1_normal.xy;
    float  layer1_normal_mask = lerp( 1-blend.g, 1.0, layer01_normal_influnece);
    composite_normal.xy *= layer1_normal_mask;
#endif

    // Transform final normal into world space
    shader_data.common.normal = mul(composite_normal, shader_data.common.tangent_frame);

    //----------------------------------------------
    // Output layer blend factors
    //----------------------------------------------
#if !defined(DISABLE_LAYER2_COLOR)
    shader_data.common.shaderValues.x = layer1_mask - layer2_mask;
	shader_data.common.shaderValues.y = layer2_mask;
#endif
#if defined(DISABLE_LAYER2_COLOR)
	shader_data.common.shaderValues.x = layer1_mask;
#endif
}


/// Pixel Shader - Lighting Pass

float4 pixel_lighting(
    in s_pixel_shader_input pixel_shader_input,
    inout s_shader_data shader_data)
{
    //----------------------------------------------
    // Input from albedo pass
    //----------------------------------------------
    float layer1_mask	= shader_data.common.shaderValues.x;
#if !defined(DISABLE_LAYER2_COLOR)
    float layer2_mask	= shader_data.common.shaderValues.y;
#endif
	float3 layer0_spec  = shader_data.layer0_specular;
	float3 layer1_spec  = shader_data.layer1_specular;

    //----------------------------------------------
    // Determine specular color based on masking
    //----------------------------------------------
#if !defined(DISABLE_LAYER2_COLOR)
	float3 spec_color_0	= layer0_spec.rgb * layer0_sp_tint * (1 - layer2_mask);
#endif
#if defined(DISABLE_LAYER2_COLOR)
	float3 spec_color_0	= layer0_spec.rgb * layer0_sp_tint;
#endif
	float3 spec_color_1	= layer1_spec.rgb * layer1_sp_tint;
	float3 specular_mask = lerp(spec_color_0, spec_color_1, layer1_mask);

    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    {
		float layer0_power = calc_roughness(layer1_mask, layer1_spPow, layer0_spPow);
    	calc_specular_phong(specular, shader_data.common, shader_data.common.normal, 1.0, layer0_power); //Switch to phong specular to reduce cost
        specular *= specular_mask.rgb;
    }

    //----------------------------------------------
    // Calculate diffuse lighting contribution
    //----------------------------------------------
    float3 diffuse = 1.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);

    //----------------------------------------------
    // Finalize output color
    //----------------------------------------------
    float4 out_color;
    out_color.rgb = (shader_data.common.albedo.rgb * diffuse) + specular;
    out_color.a   = 1.0f;
    return out_color;
}


#include "techniques.fxh"