//
// File:     srf_blinn.fx
// Author:   hocoulby
// Date:     06/16/10
//
// Surface Shader - Standard Blinn
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(color_tint,        "Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_intensity,     "Alpha Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(color_intensity,             "Color Intensity", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(top_tint,        "Top Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(top_alpha_intensity,     "Top Alpha Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(top_intensity,             "Top Intensity", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER(color_top_map,      "Color top Map", "Color top Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(mask_tint,        "Mask Map Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(mask_alpha_intensity,     "Mask Alpha Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(mask_intensity,             "Mask Intensity", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER(mask_map,       "mask Map", "Mask Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"



struct s_shader_data {
    s_common_shader_data common;

    float4 specular_mask;
    float  alpha;

#if defined(REFLECTION)
    float4 control_mask;
    float3 reflection;
#endif
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

    float2 uv = pixel_shader_input.texcoord.xy;

    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);

    shader_data.common.albedo.rgb *= color_tint * color_intensity;
    shader_data.common.albedo.a *= alpha_intensity;

    float2 color_top_map_uv = transform_texcoord(uv, color_top_map_transform);
    float4 color_top = sample2DGamma(color_top_map, color_top_map_uv);

    color_top.rgb *= top_tint * top_intensity;
    color_top.a *= top_alpha_intensity;

    shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, color_top, color_top.a);
    shader_data.common.albedo.a = saturate(color_top.a + shader_data.common.albedo.a);

    float2 mask_map_uv = transform_texcoord(uv, mask_map_transform);
    float4 mask_color = sample2DGamma(mask_map, mask_map_uv);

    mask_color.rgb *= mask_tint * mask_intensity;
    mask_color.a *= mask_alpha_intensity;

    shader_data.common.albedo *= mask_color;

}


float4 pixel_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    return albedo;

}


#include "techniques.fxh"
