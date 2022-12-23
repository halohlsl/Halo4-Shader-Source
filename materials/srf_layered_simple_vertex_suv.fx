//
// File:	 srf_layered_simple_vertex_suv.fx
// Author:	 aluedke
// Date:	 04/10/12
//
// Surface Shader - Layered shader that does a simple blend betwee
// 					a full base layer and an albedo-only layer
//
// Copyright (c) 343 Industries. All rights reserved.
//


////////////////////
/// Core Includes //
////////////////////

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"



////////////////////////
/// Shader Parameters //
////////////////////////

//----------------------------------------------
// Full base layer
//----------------------------------------------

// Color
DECLARE_SAMPLER( layer0_coMap, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_co_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

// Normal
DECLARE_SAMPLER( layer0_nmMap, "Layer0 Normal", "Layer0 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

// Specular
DECLARE_SAMPLER( layer0_spMap, "Layer0 Specular", "Layer0 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_sp_tint,	"Layer0 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_spPow,	"Layer0 Spec Pow", "", 0, 1, float(0.01));
#include "used_float.fxh"

//----------------------------------------------
// Blended albedo-only layer
//----------------------------------------------

// Color
DECLARE_SAMPLER(layer2_coMap, "Layer2 Color", "Layer2 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer2_co_tint,	"Layer2 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

// Blending control
DECLARE_FLOAT_WITH_DEFAULT(layer2_alpha_amt, "Layer2 Alpha Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_threshold_min,"Height Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_threshold_max,"Height Threshold Soften", "", 1, 100, float(1.0));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;
};


/////////////////////////////////
/// Pixel Shader - Albedo Pass //
/////////////////////////////////
void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;


    //----------------------------------------------
    // Sample blend values
    //----------------------------------------------
    float blend = shader_data.common.vertexColor.a;

    //----------------------------------------------
    // Sample layers
	//----------------------------------------------

	// Base Layer
    float2 layer0_uv	= transform_texcoord(uv, layer0_coMap_transform);
    float4 layer0_color	= sample2DGamma(layer0_coMap, layer0_uv);
    float2 layer0_nm_uv	= transform_texcoord(uv, layer0_nmMap_transform);
    float3 layer0_normal= sample_2d_normal_approx(layer0_nmMap, layer0_nm_uv);

	// Layer 2 (albedo only)
    float2 layer2_uv	= transform_texcoord(uv, layer2_coMap_transform);
    float4 layer2_color	= sample2DGamma(layer2_coMap, layer2_uv);

	// Use inverted alpha for vertex blend shaders
	layer2_color.a = 1.0f - layer2_color.a;


    //----------------------------------------------
    // Compute layer masks
    //----------------------------------------------
	float layer2_mask;
    float layer2_threshold = float_threshold(layer0_color.a, layer2_threshold_min, layer2_threshold_max);
    layer2_mask = saturate(blend - (layer2_color.a * layer2_alpha_amt));
    layer2_mask = saturate(layer2_mask - (layer2_threshold * layer2_mask));


    //----------------------------------------------
    // Composite color maps, set output albedo value
    //----------------------------------------------
    float3 composite_color;

    layer0_color.rgb *= layer0_co_tint;
	layer2_color.rgb *= layer2_co_tint;

    // Composite color values
    composite_color = lerp(layer0_color.rgb, layer2_color.rgb, layer2_mask);

    shader_data.common.albedo.rgb  = composite_color;
    shader_data.common.albedo.a    = 1.0;

    //----------------------------------------------
	// Transform final normal into world space
    //----------------------------------------------
    shader_data.common.normal = mul(layer0_normal, shader_data.common.tangent_frame);
}


/////////////////////////////////////
/// Pixel Shader - Lighting Passes //
/////////////////////////////////////
float4 pixel_lighting(
    in s_pixel_shader_input pixel_shader_input,
    inout s_shader_data shader_data)
{
    float2 uv			= pixel_shader_input.texcoord.xy;

    //----------------------------------------------
    // Input from albedo pass
    //----------------------------------------------
    float4 albedo		= shader_data.common.albedo;
    float3 normal		= shader_data.common.normal;


    //----------------------------------------------
    // Determine specular color based on masking
    //----------------------------------------------
	float3 specular_mask = sample2DGamma(layer0_spMap, transform_texcoord(uv, layer0_coMap_transform));
	specular_mask = specular_mask * layer0_sp_tint;


    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    {
		float specular_power = calc_roughness(layer0_spPow);

    	calc_specular_blinn(specular, shader_data.common, normal, 1.0, specular_power);
        specular *= specular_mask.rgb;
    }


    //----------------------------------------------
    // Calculate diffuse lighting contribution
    //----------------------------------------------
    float3 diffuse = 1.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, normal);


    //----------------------------------------------
    // Finalize output color
    //----------------------------------------------
    float4 out_color;
    out_color.rgb = (albedo.rgb * diffuse) + specular;
    out_color.a   = 1.0f;
    return out_color;
}


#include "techniques.fxh"
