//
// File:	 srf_glass_simple.fx
// Author:	 aluedke
// Date:	 11/09/2011
//
// Surface Shader - Glass (simplified)
//
// Copyright (c) 343 Industries. All rights reserved.
//

#define DISABLE_TANGENT_FRAME


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"


// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(parallax, "Parallax", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if defined(HOLOGRAM)
DECLARE_FLOAT_WITH_DEFAULT(maximum_opacity, "Maximum Opacity", "", 0, 1, float(1.0f));
#include "used_float.fxh"
#endif


struct s_shader_data {
	s_common_shader_data common;

	float3 reflection;
    float  alpha;

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


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv					= pixel_shader_input.texcoord.xy;

	float2 color_map_uv			= transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo	= sample2DGamma(color_map, uv);
	shader_data.alpha			= shader_data.common.albedo.a;
	shader_data.common.albedo.a	= 1.0f;

	shader_data.common.normal	= shader_data.common.geometricNormal;
}




float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;

	float fresnel = 0.0f;
	{ // Compute fresnel to modulate reflection
		float3 view = -shader_data.common.view_dir_distance.xyz;
		float  vdotn = saturate(dot( view, normal));
		fresnel = pow(vdotn, fresnel_power) * fresnel_intensity;
		fresnel = lerp(fresnel, saturate(1-fresnel), fresnel_inv);
	}

    float3 diffuse = 1.0f;
    calc_simple_lighting(diffuse, shader_data.common);

	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{ // sample reflection cube map
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view, normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);
		reflection = reflectionMap.rgb * reflection_intensity * reflection_color;
        shader_data.reflection = reflection;
		reflection = lerp(reflection, fresnel * reflection, fresnel_mask_reflection);
	}

    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = (diffuse * color_screen(reflection, albedo));

	//.. Finalize Alpha
	out_color.a   = saturate(fresnel + shader_data.alpha);
	#if defined(HOLOGRAM)
		clip(out_color.a - ps_material_generic_parameters[3].x);
		out_color.a = saturate(out_color.a) * maximum_opacity;	
	#endif
	
	
	return out_color;
}


#include "techniques.fxh"