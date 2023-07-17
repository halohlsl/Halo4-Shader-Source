//
// File:	 srf_ca_terrain.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Standard Blinn
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#define IGNORE_DYNAMIC_CUBEMAPS
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers *************************************************************************

// blend map
DECLARE_SAMPLER( mix_map, "Blend Map", "Blend Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"

// FIRST LAYER
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_tile_u,             "Color Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_tile_v,             "Color Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_u,            "Normal Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_v,            "Normal Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(diffuse_color,        "Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,        "Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


// DETAIL MAPS
DECLARE_SAMPLER(color_detail_map,       "Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_detail_tile_u,      "Color Detail Tile U", "", 1, 64, float(16.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_detail_tile_v,      "Color Detail Tile V", "", 1, 64, float(16.0));
#include "used_float.fxh"

DECLARE_SAMPLER(normal_detail_map,      "Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_tile_u,     "Detail Normal Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_tile_v,     "Detail Normal Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,       "Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,       "Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power,       "Specular Power", "", 0, 100, float(60.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,      "Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if defined(REFLECTION)
DECLARE_RGB_COLOR_WITH_DEFAULT(rim_color,        "Rim Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_power,        "Rim Power", "", 0, 20, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_intensity,        "Rim Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"
#endif


// SECOND LAYER
DECLARE_SAMPLER( color_map2, "Color Map 2", "Color Map 2", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color2_tile_u,             "Color2 Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color2_tile_v,             "Color2 Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER( normal_map2, "Normal Map2", "Normal Map2", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_u2,            "Normal2 Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_v2,            "Normal2 Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"

// DETAIL MAPS
DECLARE_SAMPLER(color2_detail_map,       "Color2 Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color2_detail_tile_u,      "Color2 Detail Tile U", "", 1, 64, float(16.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color2_detail_tile_v,      "Color2 Detail Tile V", "", 1, 64, float(16.0));
#include "used_float.fxh"

DECLARE_SAMPLER(normal2_detail_map,      "Detail2 Normal Map", "Detail2 Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal2_detail_tile_u,     "Detail2 Normal Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal2_detail_tile_v,     "Detail2 Normal Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color2,       "Specular Color2", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity2,       "Specular Intensity2", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power2,       "Specular Power2", "", 0, 100, float(60.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo2,      "Specular Mix Albedo2", "", 0, 1, float(0.0));
#include "used_float.fxh"


#if defined(REFLECTION)
DECLARE_RGB_COLOR_WITH_DEFAULT(rim_color2,        "Rim Color2", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_power2,        "Rim Power2", "", 0, 20, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_intensity2,        "Rim Intensity2", "", 0, 10, float(1.0));
#include "used_float.fxh"
#endif

// THIRD LAYER

DECLARE_SAMPLER( color_map3, "Color Map 3", "Color Map 3", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color3_tile_u,             "Color3 Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color3_tile_v,             "Color3 Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER( normal_map3, "Normal Map3", "Normal Map3", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_u3,            "Normal3 Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_v3,            "Normal3 Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"

// DETAIL MAPS

DECLARE_SAMPLER(normal3_detail_map,      "Detail3 Normal Map", "Detail3 Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal3_detail_tile_u,     "Detail3 Normal Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal3_detail_tile_v,     "Detail3 Normal Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal3_detail_blend,       "Detail3 Diffuse Blend", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color3,       "Specular Color3", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity3,       "Specular Intensity3", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power3,       "Specular Power3", "", 0, 100, float(60.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo3,      "Specular Mix Albedo3", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if defined(REFLECTION)
DECLARE_RGB_COLOR_WITH_DEFAULT(rim_color3,        "Rim Color3", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_power3,        "Rim Power3", "", 0, 20, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_intensity3,        "Rim Intensity3", "", 0, 10, float(1.0));
#include "used_float.fxh"
#endif
// NORMAL MAPS
// Texture controls

#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif

#if defined(PLASMA)
#include "shared/plasma.fxh"
#endif




struct s_shader_data {
	s_common_shader_data common;

    float4 specular_mask;
    float  alpha;
	float3 blend_map;


};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;

    float2 blend_map_uv = transform_texcoord(uv, float4(1, 1, 0, 0));
    float4 blendmap = sample2DGamma(mix_map, blend_map_uv);
    shader_data.blend_map = blendmap.rgb;
    float3 detail3_normal = float3(0,0,0);
    {// Sample and composite normal and detail maps.
    	float2 normal_uv   = transform_texcoord(uv, float4(normal_tile_u, normal_tile_v, 0, 0));
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);

        float2 normal_uv2   = transform_texcoord(uv, float4(normal_tile_u2, normal_tile_v2, 0, 0));
        float3 base_normal2 = sample_2d_normal_approx(normal_map2, normal_uv2);

        float2 normal_uv3   = transform_texcoord(uv, float4(normal_tile_u3, normal_tile_v3, 0, 0));
        float3 base_normal3 = sample_2d_normal_approx(normal_map3, normal_uv3);


		shader_data.common.normal = (base_normal *  blendmap.r) +  (base_normal2 *  blendmap.g) + (base_normal3 *  blendmap.b);


        float2 detail_uv = transform_texcoord(uv, float4(normal_detail_tile_u, normal_detail_tile_v, 0, 0));
        float3 detail_normal = sample2DVector(normal_detail_map, detail_uv);

        float2 detail2_uv = transform_texcoord(uv, float4(normal2_detail_tile_u, normal2_detail_tile_v, 0, 0));
        float3 detail2_normal = sample2DVector(normal2_detail_map, detail2_uv);

        float2 detail3_uv = transform_texcoord(uv, float4(normal3_detail_tile_u, normal3_detail_tile_v, 0, 0));
        detail3_normal = sample2DVector(normal3_detail_map, detail3_uv);

        float3 details_mixed = (detail_normal *  blendmap.r) +  (detail2_normal *  blendmap.g) +  (detail3_normal *  blendmap.b);
        shader_data.common.normal.xy += details_mixed.xy;
        shader_data.common.normal.z = sqrt(saturate(1.0f + dot(shader_data.common.normal.xy, -shader_data.common.normal.xy)));

    	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }


    {// Sample color map.
	    float2 color_map_uv = transform_texcoord(uv, float4(color_tile_u, color_tile_v, 0, 0));
	    float4 baseColor = sample2DGamma(color_map, color_map_uv);

        float2 color_map_uv2 = transform_texcoord(uv, float4(color2_tile_u, color2_tile_v, 0, 0));
        float4 baseColor2 = sample2DGamma(color_map2, color_map_uv2);

        float2 color_map_uv3 = transform_texcoord(uv, float4(color3_tile_u, color3_tile_v, 0, 0));
        float4 baseColor3 = sample2DGamma(color_map3, color_map_uv3);

        shader_data.common.albedo = (baseColor *  blendmap.r) +  (baseColor2 *  blendmap.g) + (baseColor3 *  blendmap.b);

        float2 color_detail_map_uv = transform_texcoord(uv, float4(color_detail_tile_u, color_detail_tile_v, 0, 0));
        float4 detailsColor = sample2DGamma(color_detail_map, color_detail_map_uv);

        float2 color_detail_map_uv2 = transform_texcoord(uv, float4(color2_detail_tile_u, color2_detail_tile_v, 0, 0));
        float4 detailsColor2 = sample2DGamma(color2_detail_map, color_detail_map_uv2);


        const float DETAIL_MULTIPLIER = 4.59479f;       // 4.59479f == 2 ^ 2.2  (sRGB gamma)
        const float BASE_DETAIL = 0.217637641f; // 0.217637641f == .5 ^ 2.2  (sRGB gamma)
        float4 blended_detail= (detailsColor *  blendmap.r) +  (detailsColor2 *  blendmap.g) + lerp(blendmap.b * BASE_DETAIL, saturate(detail3_normal.r * detail3_normal.g + BASE_DETAIL) * blendmap.b, normal3_detail_blend);
        shader_data.common.albedo.rgb *= blended_detail.rgb * DETAIL_MULTIPLIER;

		shader_data.specular_mask.rgb = shader_data.common.albedo.www;

#if defined(FIXED_ALPHA)
        float2 alpha_uv		= transform_texcoord(uv, float4(1, 1, 0, 0));
		shader_data.alpha	= sample2DGamma(color_map, alpha_uv).a;
#else
        shader_data.alpha	= shader_data.common.albedo.a;
#endif

#if defined(ALPHA_CLIP) && defined(xenon)
		// Tex kill pixel
		clip(shader_data.alpha - clip_threshold);
#endif

		shader_data.common.albedo.a = shader_data.alpha;
    }
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;
	float4 specular_mask  = shader_data.specular_mask;
	float3 blend_map      = shader_data.blend_map;

    float3 specular = 0.0f;
	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
       //float power = calc_roughness(specular_mask.g, specular_power_min, specular_power_max );
	    float power = (specular_power *  blend_map.r) +  (specular_power2 *  blend_map.g) + (specular_power3 *  blend_map.b) ;
	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

        // mix specular_color with albedo_color
        float3 combined_spec = (specular_color *  blend_map.r) +  (specular_color2 *  blend_map.g) + (specular_color3 *  blend_map.b) ;
        float combined_mix = (specular_mix_albedo *  blend_map.r) +  (specular_mix_albedo2 *  blend_map.g) + (specular_mix_albedo3 *  blend_map.b) ;
        float3 specular_col = lerp(combined_spec, albedo.rgb, combined_mix);
        // modulate by mask, color, and intensity
        float combined_intensity = (specular_intensity *  blend_map.r) +  (specular_intensity2 *  blend_map.g) + (specular_intensity3 *  blend_map.b) ;
        specular *= specular_mask * specular_col * combined_intensity;
	}

	float3 base_diffuse = 0.0f;
    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);

		// Store the mask for diffuse reflection
        diffuse_reflection_mask = diffuse;
        base_diffuse = diffuse;

    	diffuse *= albedo.rgb * diffuse_color * diffuse_intensity;

    }





    //.. Finalize Output Color
    float4 out_color;

#if defined(REFLECTION)
    //.. Fresnel Calculations
    float3 view = normalize(-shader_data.common.view_dir_distance.xyz);
    float base_fresnel = 1- saturate(dot(shader_data.common.normal, view));
    float3 combinedRimColor = (rim_color *  blend_map.r) +  (rim_color2 *  blend_map.g) + (rim_color3 *  blend_map.b) ;
    float  combinedRimIntensity =  (rim_intensity *  blend_map.r) +  (rim_intensity2 *  blend_map.g) + (rim_intensity3 *  blend_map.b) ;
    float  combinedRimPower = (rim_power *  blend_map.r) +  (rim_power2 *  blend_map.g) + (rim_power3 *  blend_map.b) ;
    float3 fresnel = pow(base_fresnel, combinedRimPower) * combinedRimIntensity * base_diffuse * combinedRimColor * specular_mask;

#endif

	out_color.rgb = diffuse + specular;

	#if defined(REFLECTION)
	out_color.rgb +=  fresnel;
	#endif
    //out_color.rgb = specular_mask;
	//out_color.rgb = shader_data.common.vertexColor.aaa;
	out_color.a   = shader_data.alpha;


#if defined(PLASMA)
	out_color.rgb += GetPlasmaColor(pixel_shader_input);
#endif

	return out_color;
}


#include "techniques.fxh"