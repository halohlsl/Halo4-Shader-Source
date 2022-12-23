//
// File:	 srf_env_M60_terrain.fx
// Author:	 wesleyg
// Date:	 08/23/12
//
// Surface Shader - Optimized terrain shader for M60
//
// Copyright (c) 343 Industries. All rights reserved.
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

#define BLENDED_MATERIAL_COUNT 3

//.. Artistic Parameters
//... Blend Map
DECLARE_SAMPLER( blend_map, "Blend Map RGB", "Blend Map RGB", "shaders/default_bitmaps/bitmaps/blendmaprgb_control.tif")
#include "next_texture.fxh"

//... Base Layer
DECLARE_SAMPLER( layer0_coMap, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_co_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

//... Layer1 - Red
DECLARE_SAMPLER( layer1_coMap, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_co_tint,	"Layer1 Tint", "", float3(1,0,0));
#include "used_float3.fxh"

//... Layer2 - Green
DECLARE_SAMPLER( layer2_coMap, "Layer2 Color", "Layer2 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer2_nmMap, "Layer2 Normal", "Layer Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer2_co_tint,	"Layer2 Tint", "", float3(0,1,0));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(layer2_normal_influence, "Layer2 Normal Map Influence", "", 0.0, 1.0, float(0.166));
#include "used_float.fxh"

// specular control
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(sp_tint,	"Specular Tint", "", float3(1,1,1));
#include "used_float3.fxh"

struct s_shader_data {
    s_common_shader_data common;

};

/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;

    //----------------------------------------------
    // Sample blend and cloud maps
    //----------------------------------------------
	float2 blend_map_uv = uv;

	#if defined BLENDMAP_UVSET2
		blend_map_uv = pixel_shader_input.texcoord.zw;
	#endif

	float4 blend		= sample2D(blend_map, blend_map_uv);

    //----------------------------------------------
    // Sample layers
    //----------------------------------------------
    float4 layer0_color = sample2DGamma(layer0_coMap, transform_texcoord(uv, layer0_coMap_transform));
    float4 layer1_color = sample2DGamma(layer1_coMap, transform_texcoord(uv, layer1_coMap_transform));
    float4 layer2_color = sample2DGamma(layer2_coMap, transform_texcoord(uv, layer2_coMap_transform));
    float3 layer2_normal= sample_2d_normal_approx(layer2_nmMap, transform_texcoord(uv, layer2_nmMap_transform));

    //----------------------------------------------
    // Compute layer masks
    //----------------------------------------------
    float layer1_mask = saturate( (blend.r - ( 1 - layer1_color.a )) / 0.3);
    float layer2_mask = saturate( (blend.g - ( 1 - layer2_color.a )) / 0.3);

    //----------------------------------------------
    // Composite color maps, output albedo
    //----------------------------------------------
    float3 composite_color = 0.0;

    layer0_color.rgb *= layer0_co_tint;
    layer1_color.rgb *= layer1_co_tint;
    layer2_color.rgb *= layer2_co_tint;

    composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);
    composite_color = lerp(composite_color, layer2_color.rgb, layer2_mask);

    shader_data.common.albedo.rgb  = composite_color;
    shader_data.common.albedo.a    = 1.0f;

    //----------------------------------------------
    // Composite normal maps, output normal
    //----------------------------------------------
    float3 composite_normal = lerp(float3(0.0,0.0,1.0), layer2_normal.rgb, layer2_normal_influence);
    composite_normal = normalize(lerp(composite_normal, layer2_normal.rgb, layer2_mask));
	
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
    float2 uv		= pixel_shader_input.texcoord.xy;

    //----------------------------------------------
    // Input from albedo pass
    //----------------------------------------------
    float4 albedo	= shader_data.common.albedo;
    float3 normal	= shader_data.common.normal;
    float layer2_mask	= shader_data.common.shaderValues.y;
    float4 specular_mask = albedo * saturate(layer2_mask + 0.2);
    
    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    { // Compute Specular
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max);

	// using phong specular model
    	calc_specular_phong(specular, shader_data.common, normal, albedo.a, power);

        // modulate by mask, color, and intensity
        specular *= specular_mask.b * specular_intensity * sp_tint;
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

    out_color.a   = albedo.a;

    return out_color;
}


#include "techniques.fxh"