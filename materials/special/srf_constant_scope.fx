//
// File:	 srf_constant.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Constant, no diffuse illumination model, may have specular though
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
DECLARE_SAMPLER( scope_map, "Scope Map", "Scope Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( selfillum_map, "SelfIllum Map", "SelfIllum Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Scope Map
DECLARE_RGB_COLOR_WITH_DEFAULT(scope_edge_color,	"Scope Edge Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scope_edge_intensity,	"Scope Edge Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(scope_heat_color,	"Scope Heat Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scope_heat_intensity,	"Scope Heat Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Self Illumination
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"



struct s_shader_data
{
	s_common_shader_data common;
    float3 self_illum;
    float alpha;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv    		 = pixel_shader_input.texcoord.xy;
	float2 selfillum_uv  = pixel_shader_input.texcoord.xy;

    {// Sample color map.
	    float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
        shader_data.alpha = shader_data.common.albedo.a;

		shader_data.common.albedo.rgb *= albedo_tint.rgb;
		shader_data.common.albedo.a = shader_data.alpha;
	}


    { // sample self illum map
    	float2 scope_map_uv 	   = transform_texcoord(selfillum_uv, scope_map_transform);

		float3 self_illum_heat_color;

#if (!defined(xenon)) && (DX_VERSION != 11)

		shader_data.self_illum = scope_edge_intensity * sample2DGamma(scope_map, scope_map_uv).rgb;

#else

		float4 color_0, color_1, color_2, color_3;
		
#ifdef xenon
		asm
		{
			tfetch2D color_0, scope_map_uv, scope_map, OffsetX=  0.5f, OffsetY=  0.5f
			tfetch2D color_1, scope_map_uv, scope_map, OffsetX= -0.5f, OffsetY=  0.5f
			tfetch2D color_2, scope_map_uv, scope_map, OffsetX= -0.5f, OffsetY= -0.5f
			tfetch2D color_3, scope_map_uv, scope_map, OffsetX=  0.5f, OffsetY= -0.5f
		};
#elif DX_VERSION == 11
		color_0 = scope_map.t.Sample(scope_map.s, scope_map_uv, int2(0,0));
		color_1 = scope_map.t.Sample(scope_map.s, scope_map_uv, int2(-1,0));
		color_2 = scope_map.t.Sample(scope_map.s, scope_map_uv, int2(-1,-1));
		color_3 = scope_map.t.Sample(scope_map.s, scope_map_uv, int2(0,-1));
#endif

		float2 average = (color_0 + color_1 + color_2 + color_3) * 0.25f;

		shader_data.self_illum = lerp(scope_heat_intensity * scope_heat_color * average.g,
									  scope_edge_intensity * scope_edge_color, average.r);
#endif

		float2 si_map_uv 	   = transform_texcoord(selfillum_uv, selfillum_map_transform);
		shader_data.self_illum += sample2DGamma(selfillum_map, si_map_uv).rgb * si_color * si_intensity;

        shader_data.self_illum *= shader_data.alpha;
    }
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo ;

    //.. Finalize Output Color
	float4 out_color = float4(0.0f, 0.0f, 0.0f, shader_data.alpha);

	if (AllowSelfIllum(shader_data.common))
	{
		out_color.rgb += albedo.rgb * diffuse_intensity;
	}

	// self illum
    if (AllowSelfIllum(shader_data.common))
    {
		out_color.rgb += shader_data.self_illum;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(shader_data.self_illum);
	}


	return out_color;


}


#include "techniques.fxh"

