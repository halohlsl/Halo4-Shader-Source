//
// File:	 srf_lewis_lights.fx
// Author:	 v-inyang
// Date:	 06/20/11
//
// Surface Shader - for forerunner emissive decorations
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader
#define DISABLE_SH


#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER( selfillum_map, "SelfIllum Map", "SelfIllum Map", "shaders/default_bitmaps/bitmaps/forerunner_lights_diff.tif")
#include "next_texture.fxh"



// Texture controls
	//Self Illumination
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0.345,0.565,0.980));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 50, float(10.0));
#include "used_float.fxh"

	//Scrolling
DECLARE_FLOAT_WITH_DEFAULT(scrolling_map1_u, 	"Scrolling Tile1 U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scrolling_map1_v, 	"Scrolling Tile1 V", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scrolling_map2_u, 	"Scrolling Tile2 U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scrolling_map2_v, 	"Scrolling Tile2 V", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(scroll_rate1_u, 	"Scroll Rate1 U", "", -100, 100, float(60.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll_rate1_v, 	"Scroll Rate1 V", "", -100, 100, float(60.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll_rate2_u, 	"Scroll Rate2 U", "", -100, 100, float(-3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll_rate2_v, 	"Scroll Rate2 V", "", -100, 100, float(1.5));
#include "used_float.fxh"


#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif

#if defined(EDGE_GLOW_COLOR)

// Fresnel term used to mask the edge glow
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(edge_glow_color,		"Edge Glow Color", "", float3(0.345,0.565,0.980));
#include "used_float3.fxh"

#endif

#if defined(PRIMARY_CHANGE_COLOR)
DECLARE_FLOAT_WITH_DEFAULT(pcc_amount, "Primary Change Color Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

DECLARE_BOOL_WITH_DEFAULT(wireframe_outline, "Wireframe Outline", "", false);
#include "next_bool_parameter.fxh"

struct s_shader_data
{
	s_common_shader_data common;
    float4 self_illum;
    float alpha;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv    		= pixel_shader_input.texcoord.xy;
	float2 scrolling1_uv = uv;
	float2 scrolling2_uv = uv;

#if !defined(cgfx)
	scrolling1_uv += float2(scroll_rate1_u, scroll_rate1_v) * ps_time.z;
	scrolling2_uv += float2(scroll_rate2_u, scroll_rate2_v) * ps_time.z;
#else
	scrolling1_uv += float2(scroll_rate1_u, scroll_rate1_v) * frac(ps_time.x/600.0f);
	scrolling2_uv += float2(scroll_rate2_u, scroll_rate2_v) * frac(ps_time.x/600.0f);
#endif




     // sample alpha map
    	float2 alpha_map_uv	= transform_texcoord(uv, selfillum_map_transform);
	    float4 alpha_map = sample2DGamma(selfillum_map, alpha_map_uv);
		shader_data.alpha = alpha_map.a;
		// Tex kill pixel for clipping
		#if defined(ALPHA_CLIP)
			clip(alpha_map.a - clip_threshold);
			shader_data.alpha = 1.0f;
		#else
			shader_data.alpha = alpha_map.a;
		#endif


    // sample self illum map
		//scrolling 1 uv
		float2 scrolling_map1_uv 	= transform_texcoord(scrolling1_uv, float4(scrolling_map1_u, scrolling_map1_v, 0, 0));
		float3 scrolling_map1 = sample2DGamma(selfillum_map, scrolling_map1_uv).rgb;
		//scrolling 2 uv
		float2 scrolling_map2_uv 	= transform_texcoord(scrolling2_uv, float4(scrolling_map2_u, scrolling_map2_v, 0, 0));
		float3 scrolling_map2 = sample2DGamma(selfillum_map, scrolling_map2_uv).rgb;
		//multiply uvs together
		float2 multiplied_uv = (uv + scrolling_map1.r) * (uv + scrolling_map2.r);
		float2 si_map_uv 	= transform_texcoord(multiplied_uv, selfillum_map_transform);
		//sample self illum map
		shader_data.self_illum = sample2DGamma(selfillum_map, si_map_uv);

 #if defined(PRIMARY_CHANGE_COLOR)
		float4 primary_cc = ps_material_object_parameters[0];
        shader_data.self_illum.rgb *= lerp( si_color.rgb, primary_cc.rgb, pcc_amount ) * si_intensity;
#else
        shader_data.self_illum.rgb *= si_color * si_intensity;
#endif



#if defined(EDGE_GLOW_COLOR)
	// Use a fresnel term to mask solid-color edge glow

	float fresnel = 0.0f;
	{
		// Compute fresnel to modulate reflection
		float3 view = -shader_data.common.view_dir_distance.xyz;
		float  vdotn = saturate(dot( view, shader_data.common.normal));
		fresnel = lerp(vdotn, saturate(1 - vdotn), fresnel_inv);
		fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
	}

	shader_data.self_illum.rgb += fresnel * edge_glow_color;
#endif

}




// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
#if defined(xenon)
	if (wireframe_outline)
	{
		pixel_pre_lighting(pixel_shader_input, shader_data);
	}
#endif

    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo ;


	//float3 H = normalize(direction - common.view_dir_distance.xyz);
	float3 specular = 0.0f;

     //.. Finalize Output Color
    float4 out_color = float4(0.0f, 0.0f, 0.0f, shader_data.alpha) ;

	// self illum
	if (AllowSelfIllum(shader_data.common))
	{
		out_color.rgb += shader_data.self_illum.rgb;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(shader_data.self_illum.rgb);
	}

	return out_color;
}

#if defined(ALPHA_CLIP)
#define REQUIRE_Z_PASS_PIXEL_SHADER
#endif

#include "techniques.fxh"
