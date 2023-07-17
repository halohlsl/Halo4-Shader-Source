//
// File:	 srf_constant_layered_wade.fx
// Author:	 hocoulby
// Date:	 11/07/11
//
// Surface Shader - Wade custom layering shader with constant illumination model
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"



//....Settings
#define BLENDED_MATERIAL

// no sh airporbe lighting needed for constant shader
#define DISABLE_SH


//... Base Layer
//
	// colormap
DECLARE_SAMPLER( layer0_coMap, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_co_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"


// ... Red Layer
// Layer1

// Color Map
DECLARE_SAMPLER( layer1_coMap, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_co_tint,	"Layer1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_alpha_amt, "Layer1 Alpha Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_min,"Height Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_max,"Height Threshold Soften", "", 1, 100, float(1.0));
#include "used_float.fxh"



// Color Map
DECLARE_SAMPLER( layer2_coMap, "Layer2 Color", "Layer2 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer2_co_tint,	"Layer2 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_alpha_amt, "Layer2 Alpha Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_threshold_min,"Height Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_threshold_max,"Height Threshold Soften", "", 1, 100, float(1.0));
#include "used_float.fxh"




struct s_shader_data {
	s_common_shader_data common;
};


float compute_mask(
            float blend_mask,
            float height,
            float alpha_mask,
            float alpha_amt,
            float threshold_min,
            float threshold_max)

{
    float3 height3 = height;
    float threshold = color_threshold(height3, threshold_min, threshold_max).r;
    float mask = saturate( blend_mask - (alpha_mask * alpha_amt) );
    return saturate( mask - (threshold * mask) );
}



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

    // Layer 1 - red
    float2 layer1_uv     = transform_texcoord(uv, layer1_coMap_transform);
    float4 layer1_color  = sample2DGamma(layer1_coMap, layer1_uv);


	// Layer 2 - green
    float2 layer2_uv	= transform_texcoord(uv, layer2_coMap_transform);
    float4 layer2_color	= sample2DGamma(layer2_coMap, layer2_uv);


    //----------------------------------------------
    // Compute layer masks
    //----------------------------------------------
    float layer1_mask;
    float layer1_threshold = color_threshold(layer0_color.a, layer1_threshold_min, layer1_threshold_max).r;
    layer1_mask = saturate(blend.r - (layer1_color.a * layer1_alpha_amt));
    layer1_mask = saturate(layer1_mask - (layer1_threshold * layer1_mask));

    float layer2_mask;
    float layer2_threshold = color_threshold(layer0_color.a, layer2_threshold_min, layer2_threshold_max).r;

    layer2_mask = saturate(blend.g - (layer2_color.a * layer2_alpha_amt));
    layer2_mask = saturate(layer2_mask - (layer2_threshold * layer2_mask));


    //----------------------------------------------
    // Composite color maps, set output albedo value
    //----------------------------------------------
    float3 composite_color;

    layer0_color.rgb *= layer0_co_tint;
    layer1_color.rgb *= layer1_co_tint;
    layer2_color.rgb *= layer2_co_tint;

    // Composite color values
    composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);
    composite_color = lerp(composite_color, layer2_color.rgb, layer2_mask);


    shader_data.common.albedo.rgb  = composite_color;
    shader_data.common.albedo.a    = 1.0;

    // Transform final normal into world space
    shader_data.common.normal = mul(float3(0,0,1), shader_data.common.tangent_frame);

}


/// Pixel Shader - Lighting Pass

float4 pixel_lighting(
    in s_pixel_shader_input pixel_shader_input,
    inout s_shader_data shader_data)
{
    float4 out_color;
    out_color.rgb = shader_data.common.albedo;
    out_color.a   = 1.0f;
    return out_color;
}


#include "techniques.fxh"