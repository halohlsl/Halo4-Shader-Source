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

DECLARE_RGB_COLOR_WITH_DEFAULT(detail_tint,        "Detail Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(detail_alpha_intensity,     "Detail Alpha Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(detail_intensity,             "Detail Intensity", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER(color_detail_map,       "Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

#if defined(THIRD_TEXTURE)

DECLARE_RGB_COLOR_WITH_DEFAULT(third_tint,        "Third Map Tint", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(third_alpha_intensity,     "Third Alpha Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(third_intensity,             "Third Intensity", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER(third_map,       "Third Map", "Third Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

#endif


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

    float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);

    color_detail.rgb *= detail_tint * detail_intensity;
    color_detail.a *= detail_alpha_intensity;

    shader_data.common.albedo *= color_detail;

#if defined(THIRD_TEXTURE)

    float2 third_map_uv = transform_texcoord(uv, third_map_transform);
    float4 third_color = sample2DGamma(third_map, third_map_uv);

    third_color.rgb *= third_tint * third_intensity;
    third_color.a *= third_alpha_intensity;

    shader_data.common.albedo *= third_color;

#endif






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