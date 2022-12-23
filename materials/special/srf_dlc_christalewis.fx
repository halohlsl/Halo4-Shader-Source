//
// File:	 srf_dlc_chirstal_lewis.fx
// Author:	 hocoulby
//
//
// Surface DLC Shader variation requested by Chris Lewis for his Crystal
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//....Parameters

DECLARE_SAMPLER( color_map, "Color", "Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( depth_1_map, "Depth Map 1", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( depth_2_map, "Depth Map 2", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"


DECLARE_FLOAT_WITH_DEFAULT(depth1, "Depth R", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth2, "Depth G", "", 0, 1, float(0.0));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(depth1_tint,	"Depth Tint R", "", float3(0.4,0.4,0.4));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(depth2_tint,	"Depth Tint G", "", float3(0.2,0.2,0.2));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(fresnel_color,"Fresnel Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,	"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"




struct s_shader_data {
	s_common_shader_data common;
};



float2 parallax_texcoord(
                float2 uv,
                float  amount,
                float2 viewTS,
                s_pixel_shader_input pixel_shader_input
                )
{

    viewTS.y = -viewTS.y;
    return uv + viewTS * amount * 0.1;
}


/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

    float2 base_uv        = pixel_shader_input.texcoord.xy;

    float3   view          = shader_data.common.view_dir_distance.xyz;
    float3x3 tangent_frame = shader_data.common.tangent_frame;

#if !defined(cgfx)
	//(aluedke) The tangent frame is currently incorrect for transformations into UV space (the binormal is inverted).  Correct for this.
	tangent_frame[1] = -tangent_frame[1];
#endif

    float3   viewTS        = mul(tangent_frame, view);
    viewTS /= abs(viewTS.z);				// Do the divide to scale the view vector to the length needed to reach 1 unit 'deep'

    float2 normalMap_uv = transform_texcoord(base_uv, normal_map_transform);
    float3 normal       = sample_2d_normal_approx(normal_map, normalMap_uv);

    float2 colorMap_uv = transform_texcoord(base_uv, color_map_transform);
    float4 colorMap_sampled  = sample2DGamma(color_map, colorMap_uv);

    /// UV Transformations
    float2 uv_offset1 = parallax_texcoord(base_uv,
    							   normal.z * depth1,
                                   viewTS,
                                   pixel_shader_input );

	float2 uv_offset2 = parallax_texcoord(base_uv,
								   normal.z * depth2,
								   viewTS,
                                   pixel_shader_input );


	uv_offset1 = transform_texcoord(uv_offset1, depth_1_map_transform);
	uv_offset2 = transform_texcoord(uv_offset2, depth_2_map_transform);

	float3 dmap1_sampled  = sample2DGamma(depth_1_map, uv_offset1).r;
    float3 dmap2_sampled  = sample2DGamma(depth_2_map, uv_offset2).g;

    dmap1_sampled.rgb *= depth1_tint;
    dmap2_sampled.rgb *= depth2_tint;


    shader_data.common.shaderValues.y = color_luminance(dmap1_sampled + dmap2_sampled);
	

    {// Sample specular map.
    	float2 specular_map_uv	    = transform_texcoord(base_uv, specular_map_transform);
    	shader_data.common.shaderValues.x   = sample2DGamma(specular_map, specular_map_uv);
    }

    shader_data.common.albedo.rgb = colorMap_sampled.rgb;

    shader_data.common.albedo.rgb *= albedo_tint.rgb;
    shader_data.common.albedo.a = 1.0f;

    shader_data.common.normal = mul(normal, shader_data.common.tangent_frame);

}

/// Pixel Shader - Lighting Pass


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

    // input from shader_data
    float4 out_color;
    float4 albedo  = shader_data.common.albedo;
    float3 depth_mask = shader_data.common.shaderValues.y;
    float4 specular_mask  = shader_data.common.shaderValues.x;
    float3 normal = shader_data.common.normal;



    float3 specular = 0.0f;
	float specular_depth = 1.0f;
    {  // using aniso ward specular model
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );


        calc_specular_blinn(specular, shader_data.common, normal, albedo.a * specular_intensity, power);

        specular_depth = depth_mask * 5.0;

        float3 specular_col = lerp(specular_color, albedo.r, specular_mix_albedo);
        specular *= specular_mask.r * specular_col + specular_depth;
    }

    float3 diffuse = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

	float fresnel = 0.0f;
	{ // Compute fresnel to modulate surface
		float3 view = -shader_data.common.view_dir_distance.xyz;
		float  vdotn = saturate(dot(view, shader_data.common.normal));
		fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	
		fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
	}

	
    //.. Finalize Output Color
    out_color.rgb = ColorScreenExtendedRange(diffuse, specular);
	out_color.rgb = lerp(out_color.rgb, fresnel_color, fresnel);
	
    out_color.a   = 0.0f;
	return out_color;


}


#include "techniques.fxh"