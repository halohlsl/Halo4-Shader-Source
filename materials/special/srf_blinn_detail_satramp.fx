//
// File:	 srf_blinn_detail_satramp.fx
// Author:	 hcoulby
// Date:	 08/10/11
//
// Surface Shader - Custom shader for rocks in M40 as requested by Vic DeLeon, uses are ramp texture to define saturation
//
// Copyright (c) 343 Industries. All rights reserved.


// no sh airporbe lighting needed for constant shader
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"


// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"

// Ramp texture to define saturation value
DECLARE_BOOL_WITH_DEFAULT(show_ramp, "Show Ramp Only", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER_GRADIENT( saturation_ramp, "Saturation Ramp", "Saturation Ramp", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(sat_ramp_normal,	"Saturation Ramp Normal Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Detail Normal Map
DECLARE_BOOL_WITH_DEFAULT(detail_normals, "Detail Normals Enabled", "", true);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"



struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv		= pixel_shader_input.texcoord.xy;


// Sample color map and color detail maps.
    float4 albedo = float4(0.0f, 0.0f, 0.0f, 1.0f);

    // albedo map
    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
    albedo = sample2DGamma(color_map, color_map_uv);

    // color detail map
    float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
    albedo.rgb = color_composite_detail(albedo.rgb, color_detail.rgb);

    // apply tints
    albedo.rgb *= albedo_tint;



// Sample and composite detail maps.
    float3   normal  = 0.0f;

    float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
    normal = sample_2d_normal_approx(normal_map, normal_uv);

    float3 ramp_normal = lerp(float3(0,0,1), normal, sat_ramp_normal);

    // composite detail normal map
    STATIC_BRANCH
    if (detail_normals) {
        float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
        normal = CompositeDetailNormalMap(shader_data.common,
                                         normal,
                                         normal_detail_map,
                                         detail_uv,
                                         normal_detail_dist_min,
                                         normal_detail_dist_max);

    }
    // how much does the surface normal effect ramp lookup

    normal = normalize( mul(normal, shader_data.common.tangent_frame) );
    ramp_normal = normalize( mul(ramp_normal, shader_data.common.tangent_frame) );


// Apply saturation ramp

    // def up directional vector
    #if defined(cgfx)
        float3 up = float3(0,1,0);
    #else
        float3 up = float3(0,0,1);
    #endif

    float3 ramp_lookup_uv = 1.0f;
    ramp_lookup_uv.y = dot( up, ramp_normal );
    ramp_lookup_uv.y = 1-((ramp_lookup_uv.y + 1) * 0.5);
    float saturation = sample2D(saturation_ramp, ramp_lookup_uv).r;


    STATIC_BRANCH
    if (show_ramp) {
        albedo.rgb = saturation;
    } else {
        // desat based on ramp
        albedo.rgb = color_saturation(albedo.rgb, saturation);
    }


// Output
    shader_data.common.albedo = albedo;
    shader_data.common.normal = normal;


}


// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)

{
	float2 uv		= pixel_shader_input.texcoord.xy;
    float4 albedo   = shader_data.common.albedo;
    float3 normal   = shader_data.common.normal;


//  Specular
    float3 specular = 0.0f;

    // sample textures
    float2 specular_map_uv	= transform_texcoord(uv, specular_map_transform);
    float4 specular_mask    = sample2DGamma(specular_map, specular_map_uv);

    // pre-computing roughness with independent control over white and black point in gloss map
    float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );

    // brdf
    calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

    // final color
    float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);
    specular *= specular_mask.rgb * specular_col * specular_intensity;



// Compute Diffuse
    float3 diffuse = 0.0f;

    calc_diffuse_lambert(diffuse, shader_data.common, normal);
    diffuse *= albedo.rgb * diffuse_intensity;


// Final output color


    float4 out_color = 1.0f;
	out_color.rgb = diffuse + specular;

    STATIC_BRANCH
    if (show_ramp) {
        out_color.rgb  = albedo.rgb;
    }

    return out_color;
}


#include "techniques.fxh"
