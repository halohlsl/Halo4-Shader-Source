//
// File:	 srf_env_M30_rock.fx
// Author:	 wesleyg
// Date:	 06/21/12
//
// Surface Shader - Highly optimized shader for rocks on M30.
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

//... Base Layer
//
	// colormap
DECLARE_SAMPLER( layer0_coMap, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_spMap, "Layer0 Specular", "Layer0 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_nmMap, "Layer0 Normal", "Layer0 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

// specular control
DECLARE_FLOAT_WITH_DEFAULT(layer0_spPow,	"Layer0 Spec Pow", "", 0, 1, float(0.01));
#include "used_float.fxh"

// ... Red Layer
// Layer1

// Color Map
DECLARE_SAMPLER( layer1_coMap, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_spMap, "Layer1 Specular", "Layer1 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_nmMap, "Layer1 Normal", "Layer1 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_sp_tint,	"Layer1 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_spPow,	"Layer1 Spec Pow", "", 0, 1, float(0.01));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_min,"Height Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_max,"Height Threshold Soften", "", 1, 100, float(1.0));
#include "used_float.fxh"

// Detail Normal Map
DECLARE_SAMPLER_NO_TRANSFORM(normal_detail_map,		"Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"


#if defined(OCCLUSION_MAP)
DECLARE_SAMPLER_NO_TRANSFORM( occ_map, "Cavity-Occlusion Map ", "Cavity-Occlusion Map", "shaders/default_bitmaps/bitmaps/default_occ_diff.tif")
#include "next_texture.fxh"
#endif

#if defined(BRIGHTNESS)
DECLARE_FLOAT_WITH_DEFAULT(brightness,"Brightness", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif

struct s_shader_data {
	s_common_shader_data common;
};

/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;
    float blend = min((shader_data.common.vertexColor.a*2.0),1.0);

    //----------------------------------------------
    // Sample layers
	//----------------------------------------------

	// Base Layer
    float2 layer0_uv	= uv * layer0_coMap_transform.xy;//transform_texcoord(uv, layer0_coMap_transform);
    float4 layer0_color	= sample2DGamma(layer0_coMap, layer0_uv);
	float3 layer0_normal  = sample_2d_normal_approx(layer0_nmMap, layer0_uv);

    // Layer 1 - red
    float2 layer1_uv     = uv * layer1_coMap_transform.xy;// transform_texcoord(uv, layer1_coMap_transform);
    float4 layer1_color  = sample2DGamma(layer1_coMap, layer1_uv);
	float3 layer1_normal = sample_2d_normal_approx(layer1_nmMap, layer1_uv);

    //----------------------------------------------
    // Compute layer masks
    //----------------------------------------------
	float layer1_mask;
	float layer2_mask;

	float layer1_threshold = color_threshold(layer0_color.a, layer1_threshold_min, layer1_threshold_max).r;
	layer2_mask = layer1_color.a;
    layer1_mask = saturate(blend - (layer1_threshold * blend));

    //----------------------------------------------
    // Composite color maps, set output albedo value
    //----------------------------------------------
    float3 composite_color;

    // Composite color values
    composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);
#if defined(BRIGHTNESS)
	composite_color *= brightness;
#endif

#if defined(OCCLUSION_MAP)
    // apply cavity and occlusion map
    float2 occ_map_sampled = sample2DGamma(occ_map, uv);
    composite_color *= occ_map_sampled.g;
    composite_color = color_overlay(composite_color, occ_map_sampled.r);
#endif

    shader_data.common.albedo.rgb  = composite_color;
    shader_data.common.albedo.a    = 1.0;


    //----------------------------------------------
    // Composite normal maps, output normal
    //----------------------------------------------
    float3 composite_normal;

    float layer0_normal_mask = 1-blend;
    layer0_normal *= layer0_normal_mask;
    layer1_normal *= layer1_mask;

    // comp the two normals
    composite_normal.xy = layer0_normal.xy + layer1_normal.xy;

	composite_normal = CompositeDetailNormalMap(composite_normal,
												normal_detail_map,
												uv,
												1.0f);

    // Transform final normal into world space
    shader_data.common.normal = mul(composite_normal, shader_data.common.tangent_frame);

    //----------------------------------------------
    // Output layer blend factors
    //----------------------------------------------
	shader_data.common.shaderValues.x = layer1_mask;
	shader_data.common.shaderValues.y = layer2_mask;
}


/// Pixel Shader - Lighting Pass

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
    float layer1_mask	= shader_data.common.shaderValues.x;
    float layer2_mask	= shader_data.common.shaderValues.y;


    //----------------------------------------------
    // Determine specular color based on masking
    //----------------------------------------------
	float3 layer0_spec	= sample2DGamma(layer0_spMap,(uv * layer0_coMap_transform.xy));
	float3 specular_mask = lerp(layer0_spec, (layer2_mask * layer1_sp_tint), layer1_mask);

    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    {
		float layer0_power = lerp(layer1_spPow, layer0_spPow,1-layer1_mask);
		
		calc_specular_phong(specular, shader_data.common, normal, 1.0, layer0_power);
		
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