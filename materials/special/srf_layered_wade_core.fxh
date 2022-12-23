//
// File:	 srf_layered_wade_core.fxh
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Wade custom layering shader
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

#if !defined(BLENDED_LAYER_COUNT)
#define BLENDED_LAYER_COUNT 3
#endif

#if !defined(SPECULAR_LAYER_COUNT)
#define SPECULAR_LAYER_COUNT 2
#endif

//....Settings
#define BLENDED_MATERIAL

//....Parameters

#if !defined(VERTEX_BLEND)
// Texture Samplers
DECLARE_SAMPLER( blend_map, "Blend Map RGB", "Blend Map RGB", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
#endif

//... Base Layer
//
	// colormap
DECLARE_SAMPLER( layer0_coMap, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_spMap, "Layer0 Specular", "Layer0 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
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
DECLARE_SAMPLER( layer1_spMap, "Layer1 Specular", "Layer1 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
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

#if (BLENDED_LAYER_COUNT > 2)

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

#endif

// Detail Normal Map
DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "", 0, 1, float(1.0));
#include "used_float.fxh"

#if defined(OCCLUSION_MAP)
DECLARE_SAMPLER_NO_TRANSFORM( occ_map, "Cavity-Occlusion Map ", "Cavity-Occlusion Map", "shaders/default_bitmaps/bitmaps/default_occ_diff.tif")
#include "next_texture.fxh"
#endif

#if defined(COLOR_DETAIL)
// Detail Diffuse Map
DECLARE_SAMPLER(diff_detail_map   ,  "Diff Detail Map", "Diff Detail Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diff_detail_dist_max, "Diff Start Dist.", ""               , 0, 1 , float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diff_detail_dist_min,  "Diff End Dist." , ""               , 0, 1 , float(1.0));
#include "used_float.fxh"
#endif

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
#if defined(VERTEX_BLEND)
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
#else
    float2 blend_uv	= transform_texcoord(uv, blend_map_transform);
    float4 blend	= sample2DGamma(blend_map, blend_uv);
#endif


    //----------------------------------------------
    // Sample layers
	//----------------------------------------------

	// Base Layer
    float2 layer0_uv	= transform_texcoord(uv, layer0_coMap_transform);
    float4 layer0_color	= sample2DGamma(layer0_coMap, layer0_uv);
#if defined(SEPARATE_UV_TILING)
    float2 layer0_nm_uv   = transform_texcoord(uv, layer0_nmMap_transform);
#else
	float2 layer0_nm_uv   = layer0_uv;
#endif
    float3 layer0_normal  = sample_2d_normal_approx(layer0_nmMap, layer0_nm_uv);

    // Layer 1 - red
    float2 layer1_uv     = transform_texcoord(uv, layer1_coMap_transform);
    float4 layer1_color  = sample2DGamma(layer1_coMap, layer1_uv);
#if defined(SEPARATE_UV_TILING)
	float2 layer1_nm_uv   = transform_texcoord(uv, layer1_nmMap_transform);
#else
	float2 layer1_nm_uv   = layer1_uv;
#endif
    float3 layer1_normal = sample_2d_normal_approx(layer1_nmMap, layer1_nm_uv);

#if (BLENDED_LAYER_COUNT > 2)
	// Layer 2 - green
    float2 layer2_uv	= transform_texcoord(uv, layer2_coMap_transform);
    float4 layer2_color	= sample2DGamma(layer2_coMap, layer2_uv);
#if defined(VERTEX_BLEND)
	// Use inverted alpha for vertex blend shaders
	layer2_color.a = 1.0f - layer2_color.a;
#endif
#endif

    //----------------------------------------------
    // Compute layer masks
    //----------------------------------------------
	float layer1_mask;
	float layer2_mask;

	float layer1_threshold = color_threshold(layer0_color.a, layer1_threshold_min, layer1_threshold_max).r;
#if (SPECULAR_LAYER_COUNT == 1)
	layer1_mask = saturate(blend.r - layer1_alpha_amt);
	layer2_mask = layer1_color.a;
#else
    layer1_mask = saturate(blend.r - (layer1_color.a * layer1_alpha_amt));
#endif
    layer1_mask = saturate(layer1_mask - (layer1_threshold * layer1_mask));

#if (BLENDED_LAYER_COUNT > 2)
    float layer2_threshold = color_threshold(layer0_color.a, layer2_threshold_min, layer2_threshold_max).r;
    layer2_mask = saturate(blend.g - (layer2_color.a * layer2_alpha_amt));
    layer2_mask = saturate(layer2_mask - (layer2_threshold * layer2_mask));
#endif

    //----------------------------------------------
    // Composite color maps, set output albedo value
    //----------------------------------------------
    float3 composite_color;

    layer0_color.rgb *= layer0_co_tint;
    layer1_color.rgb *= layer1_co_tint;
#if (BLENDED_LAYER_COUNT > 2)
	layer2_color.rgb *= layer2_co_tint;
#endif

    // Composite color values
    composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);
#if (BLENDED_LAYER_COUNT > 2)
    composite_color = lerp(composite_color, layer2_color.rgb, layer2_mask);
#endif

#if defined(COLOR_DETAIL)
	// multiply against diffuse detail
	float lerpAmt = float_remap( shader_data.common.view_dir_distance.w,
								 diff_detail_dist_min,
								 diff_detail_dist_max,
								 1, 0);

	const float DETAIL_MULTIPLIER= 4.59479f;  // 4.59479f== 2 ^ 2.2  (sRGB gamma)
	float2 diff_detail_uv        = transform_texcoord(uv, diff_detail_map_transform);
	float4 diff_detail           = sample2DGamma(diff_detail_map, diff_detail_uv);
	diff_detail.rgb				*= DETAIL_MULTIPLIER;

	composite_color = lerp(composite_color, diff_detail, lerpAmt);
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

    float layer0_normal_mask = lerp(1 - blend.r, 1.0, layer0_normal_influnece);
    layer0_normal *= layer0_normal_mask;
    layer1_normal *= layer1_mask;

    // comp the two normals
    composite_normal.xy = layer0_normal.xy + layer1_normal.xy;

#if (BLENDED_LAYER_COUNT > 2)
    // now mask the comp normal based on an influence control for the second layer
    float  layer1_normal_mask = lerp( 1-blend.g, 1.0, layer01_normal_influnece);
    composite_normal.xy *= layer1_normal_mask;
#endif

    // blend detail normal amount based on view distance
    float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);

#if defined(DISABLE_NORMAL_DETAIL_FADE)
	// Composite the detail normal at 100%
	composite_normal = CompositeDetailNormalMap(composite_normal,
												normal_detail_map,
												detail_uv,
												1.0f);
#else
	// Distance fade the detail normal
    composite_normal = CompositeDetailNormalMap(shader_data.common,
						composite_normal,
						normal_detail_map,
						detail_uv,
						normal_detail_dist_min,
						normal_detail_dist_max);
#endif

    // Transform final normal into world space
    shader_data.common.normal = mul(composite_normal, shader_data.common.tangent_frame);


    //----------------------------------------------
    // Output layer blend factors
    //----------------------------------------------
#if (BLENDED_LAYER_COUNT > 2)
    shader_data.common.shaderValues.x = layer1_mask - layer2_mask;
#else
	shader_data.common.shaderValues.x = layer1_mask;
#endif
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
	float3 layer0_spec	= sample2DGamma(layer0_spMap, transform_texcoord(uv, layer0_coMap_transform));

#if (SPECULAR_LAYER_COUNT > 1)
	float3 spec_color_0	= layer0_spec.rgb * layer0_sp_tint * (1 - layer2_mask);
	float3 layer1_spec	= sample2DGamma(layer1_spMap, transform_texcoord(uv, layer1_coMap_transform));
	float3 spec_color_1	= layer1_spec.rgb * layer1_sp_tint;
#else
	float3 spec_color_0	= layer0_spec.rgb * layer0_sp_tint;
	float3 spec_color_1	= layer2_mask * layer1_sp_tint;
#endif

	float3 specular_mask;
    specular_mask.rgb	= lerp(spec_color_0, spec_color_1, layer1_mask);


    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    {
		float layer0_power = calc_roughness(layer1_mask,
                                            layer1_spPow,
                                            layer0_spPow);

    	calc_specular_blinn(specular, shader_data.common, normal, 1.0, layer0_power);
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