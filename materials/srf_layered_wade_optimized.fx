//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//....Settings
#define BLENDED_MATERIAL

//....Parameters

// Texture Samplers
DECLARE_SAMPLER( blend_map, "Blend Map RGB", "Blend Map RGB", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

//... Base Layer
//
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
DECLARE_SAMPLER( layer1_nmMap, "Layer1 Normal", "Layer1 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_co_tint,	"Layer1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

    // specular control
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_sp_tint,	"Layer1 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_spPow,	"Layer1 Spec Pow", "", 0, 1, float(0.01));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(layer0_normal_influnece, "Layer0 Normal Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"
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


DECLARE_FLOAT_WITH_DEFAULT(layer01_normal_influnece, "Layer0-1 Normal Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_alpha_amt, "Layer2 Alpha Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_threshold_min,"Height Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer2_threshold_max,"Height Threshold Soften", "", 1, 100, float(1.0));
#include "used_float.fxh"


struct s_shader_data {
	s_common_shader_data common;
	float4 specular_mask;
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
    float2 uv        = pixel_shader_input.texcoord.xy;


    //----------------------------------------------
    // Sample blend map
    //----------------------------------------------
    float2 blend_uv	= transform_texcoord(uv, blend_map_transform);
    float4 blend	= sample2DGamma(blend_map, blend_uv);


    //----------------------------------------------
    // Sample layers
    //----------------------------------------------
    float2 layer0_uv	= transform_texcoord(uv, layer0_coMap_transform);
    float4 layer0_color	= sample2DGamma(layer0_coMap, layer0_uv);
    float3 layer0_normal= sample_2d_normal_approx(layer0_nmMap, layer0_uv);

    float2 layer1_uv	= transform_texcoord(uv, layer1_coMap_transform);
    float4 layer1_color	= sample2DGamma(layer1_coMap, layer1_uv);
    float3 layer1_normal= sample_2d_normal_approx(layer1_nmMap, layer1_uv);

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

    // inv comp - color value
    composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);
    composite_color = lerp(composite_color, layer2_color.rgb, layer2_mask);

    shader_data.common.albedo.rgb  = composite_color;
    shader_data.common.albedo.a    = 1.0;


    //----------------------------------------------
    // Composite normal maps, output normal
    //----------------------------------------------
    float3 composite_normal;

    float layer0_normal_mask = lerp(1 - blend.r, 1.0, layer0_normal_influnece);
    layer0_normal *= layer0_normal_mask;
    layer1_normal *= layer1_mask;

    // comp the two normals
    composite_normal.xy = layer0_normal.xy + layer1_normal.xy;

    // now mask the comp normal based on an influence control for the second layer
    float  layer1_normal_mask = lerp( 1-blend.g, 1.0, layer01_normal_influnece);
    composite_normal.xy *= layer1_normal_mask;

    composite_normal.z = sqrt(saturate(1.0f + dot(composite_normal.xy, -composite_normal.xy)));

    shader_data.common.normal = mul(composite_normal, shader_data.common.tangent_frame);


    //----------------------------------------------
    // Determine specular color based on masking
    //----------------------------------------------
    shader_data.common.shaderValues.x = saturate(layer1_mask - layer2_mask);
    shader_data.common.shaderValues.x *= (1 - layer2_mask);
}


/// Pixel Shader - Lighting Pass

float4 pixel_lighting(
    in s_pixel_shader_input pixel_shader_input,
    inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;

    //----------------------------------------------
    // Input from albedo pass
    //----------------------------------------------
    float4 albedo	= shader_data.common.albedo;
    float3 normal	= shader_data.common.normal;
    float specular_blend= shader_data.common.shaderValues.x;

    //----------------------------------------------
    // Determine specular color based on masking
    //----------------------------------------------

    float4 specular_mask;
    specular_mask.rgb = lerp(layer0_sp_tint, layer1_sp_tint, specular_blend);
    specular_mask.a = specular_blend;


    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    {
        // Layer 0 - r, specular
        float layer0_power = calc_roughness(specular_mask.a,
                                            layer0_spPow,
                                            layer1_spPow );

    	calc_specular_blinn(specular, shader_data.common, normal, float(1.0), layer0_power);
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