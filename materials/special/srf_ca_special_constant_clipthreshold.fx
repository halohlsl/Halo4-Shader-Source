//
// File:	 srf_constant_core.fxh
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Constant, no diffuse illumination model
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader
#define DISABLE_SH

#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( selfillum_map, "SelfIllum Map", "SelfIllum Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"



struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv    		 = pixel_shader_input.texcoord.xy;

    {// Sample color map.
	    float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
		shader_data.common.shaderValues.y = shader_data.common.albedo.a;

		shader_data.common.albedo.rgb *= albedo_tint.rgb;
	}

	// Snip snip
	clip(shader_data.common.shaderValues.y - clip_threshold);
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
    // input from s_shader_data
    float3 albedo         = shader_data.common.albedo;

     //.. Finalize Output Color
	float4 out_color = float4(0.0f, 0.0f, 0.0f, shader_data.common.shaderValues.y);

	if (AllowSelfIllum(shader_data.common))
	{
		out_color.rgb += albedo.rgb * diffuse_intensity;
	}

	// self illum
    if (AllowSelfIllum(shader_data.common))
    {
		// sample self illum map
		float2 selfillum_uv  = pixel_shader_input.texcoord.xy;

		float2 si_map_uv 	   = transform_texcoord(selfillum_uv, selfillum_map_transform);
		float3 self_illum = sample2DGamma(selfillum_map, si_map_uv).rgb;
		self_illum *= si_color * si_intensity;

		out_color.rgb += self_illum;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(self_illum);
	}


	return out_color;

}


#include "techniques.fxh"
