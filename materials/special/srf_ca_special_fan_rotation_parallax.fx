//
// File:	 srf_forerunner_parallax.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Custom parallax shader for forerunner surfaces
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

DECLARE_SAMPLER( depth_1_map, "Depth Map 1", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( depth_2_map, "Depth Map 2", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( depth_3_map, "Depth Map 3", "Depth Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_amount,	"SelfIllum Amount", "", 0, 1, float(1.0));
#include "used_float.fxh"


DECLARE_FLOAT_WITH_DEFAULT(multiply_diff_on_depth, "Multiply Diff on Depth", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth1, "Depth R", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth2, "Depth G", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth3, "Depth B", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(depth1_tint,	"Depth Tint R", "", float3(0.4,0.4,0.4));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(depth2_tint,	"Depth Tint G", "", float3(0.2,0.2,0.2));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(depth3_tint,	"Depth Tint B", "", float3(0.05,0.05,0.05));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(rotation, "Rotation", "", 0, 3.14, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rot_center_u, "Rotation Center U", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rot_center_v, "Rotation Center V", "", 0, 1, float(0.5));
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
	
	float2 rot_uv = base_uv;
	//offest to origin
	rot_uv = float2(rot_uv.x - rot_center_u, rot_uv.y - rot_center_v);
	//apply rotation
	rot_uv = float2( rot_uv.x*cos(rotation) - rot_uv.y*sin(rotation) , rot_uv.x*sin(rotation) + rot_uv.y*cos(rotation) );
	//offset to original position
	rot_uv = float2(rot_uv.x + rot_center_u, rot_uv.y + rot_center_v);

    float3   view          = shader_data.common.view_dir_distance.xyz;
    float3x3 tangent_frame = shader_data.common.tangent_frame;

#if !defined(cgfx)
	//(aluedke) The tangent frame is currently incorrect for transformations into UV space (the binormal is inverted).  Correct for this.
	tangent_frame[1] = -tangent_frame[1];
#endif

    float3   viewTS        = mul(tangent_frame, view);
    viewTS /= abs(viewTS.z);				// Do the divide to scale the view vector to the length needed to reach 1 unit 'deep'

    float2 colorMap_uv = transform_texcoord(rot_uv, color_map_transform);
    float4 colorMap_sampled  = sample2DGamma(color_map, colorMap_uv);

    /// UV Transformations
    float2 uv_offset1 = parallax_texcoord(base_uv,
    							   depth1,
                                   viewTS,
                                   pixel_shader_input );

	float2 uv_offset2 = parallax_texcoord(base_uv,
								   depth2,
								   viewTS,
                                   pixel_shader_input );

	float2 uv_offset3 = parallax_texcoord(base_uv,
								   depth3,
								   viewTS,
                                   pixel_shader_input );

	uv_offset1 = transform_texcoord(uv_offset1, depth_1_map_transform);
	uv_offset2 = transform_texcoord(uv_offset2, depth_2_map_transform);
	uv_offset3 = transform_texcoord(uv_offset3, depth_3_map_transform);

	float3 dmap1_sampled  = sample2DGamma(depth_1_map, uv_offset1).r;
    float3 dmap2_sampled  = sample2DGamma(depth_2_map, uv_offset2).g;
    float3 dmap3_sampled  = sample2DGamma(depth_3_map, uv_offset3).b;

    dmap1_sampled.rgb *= depth1_tint;
    dmap2_sampled.rgb *= depth2_tint;
    dmap3_sampled.rgb *= depth3_tint;

    //shader_data.common.shaderValues.y = color_luminance(dmap1_sampled + dmap2_sampled + dmap3_sampled);
	
	//#if defined(MASK_PARALLAX)
	//	shader_data.common.shaderValues.y *= colorMap_sampled.a;
	//#endif
	

	float3 multDiff = lerp(float3(1, 1, 1), colorMap_sampled.rgb, multiply_diff_on_depth); 
	shader_data.common.albedo.rgb = lerp((dmap1_sampled + dmap2_sampled + dmap3_sampled) * multDiff , colorMap_sampled.rgb , colorMap_sampled.a) ;

    shader_data.common.albedo.rgb *= albedo_tint.rgb;
    shader_data.common.albedo.a = 1.0f;
	
    //shader_data.common.normal = mul(normal, shader_data.common.tangent_frame);

}

/// Pixel Shader - Lighting Pass


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

    // input from shader_data
    float4 out_color;
    float4 albedo  = shader_data.common.albedo;
	
    float3 normal = shader_data.common.normal;

	// Sample control mask
	float2 control_map_uv	= transform_texcoord(uv, color_map_transform);
	//offest to origin
	control_map_uv = float2(control_map_uv.x - rot_center_u, control_map_uv.y - rot_center_v);
	//apply rotation
	control_map_uv = float2( control_map_uv.x*cos(rotation) - control_map_uv.y*sin(rotation) , control_map_uv.x*sin(rotation) + control_map_uv.y*cos(rotation) );
	//offset to original position
	control_map_uv = float2(control_map_uv.x + rot_center_u, control_map_uv.y + rot_center_v);
	
	float selfIllum_mask		= (1-sample2DGamma(color_map, control_map_uv).a);

    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

    //.. Finalize Output Color
    out_color.rgb = diffuse;
    out_color.a   = 1.0f;
	
	// self illum
	if (AllowSelfIllum(shader_data.common))
	{
		float3 selfIllum = albedo.rgb * si_color * si_intensity * selfIllum_mask;

		float3 si_out_color = out_color.rgb + selfIllum;
		float3 si_no_color  = out_color.rgb * (1-selfIllum_mask);

		out_color.rgb = lerp(si_no_color, si_out_color, min(1, si_amount));

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum);
	}
	
	return out_color;


}


#include "techniques.fxh"