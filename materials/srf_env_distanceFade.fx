//
// File:	 srf_env_distanceFade.fx
// Author:	 wesleyg
// Date:	 06/11/12
//
// Distance Fade Surface Shader - Cheap constant shader that fades as it is approached and can bloom out - can be used as visibility blocker for culling
//
// Copyright (c) 343 Industries. All rights reserved.
//
//
#define DISABLE_SH
#if !defined(FRESNEL_FADE)
#define DISABLE_NORMAL
#endif
#define DISABLE_TANGENT_FRAME
#define ENABLE_DEPTH_INTERPOLATER

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "depth_fade.fxh"

DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"Tint", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"Bloom", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fade_start,	"Fade Start", "", 0, 9999, float(200.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fade_end,		"Fade End", "", 0, 9999, float(500.0));
#include "used_float.fxh"

#if defined(EDGE_FADE)

#define EDGE_FADE_INVERT_SWITCH ""
#define EDGE_FADE_INVERT edgeFadeInvert

DECLARE_BOOL_WITH_DEFAULT(edgeFadeInvert, "Edge Fade Invert", EDGE_FADE_INVERT_SWITCH , false);
#include "next_bool_parameter.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edgefade_exp,	"Edge Fade Falloff Exp.", EDGE_FADE_INVERT_SWITCH, 0, 20, float(1.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edgefade_hardness,"Edge Fade Hardness", EDGE_FADE_INVERT_SWITCH, 0, 20, float(1.00));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(edgefade_sx,"Edge Fade Scale X", EDGE_FADE_INVERT_SWITCH, 0, 2, float(1.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edgefade_sy,"Edge Fade Scale Y", EDGE_FADE_INVERT_SWITCH, 0, 2, float(1.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edgefade_ox,"Edge Fade Offset X", EDGE_FADE_INVERT_SWITCH, -1, 1, float(0.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edgefade_oy,"Edge Fade Offset Y", EDGE_FADE_INVERT_SWITCH, -1, 1, float(0.00));
#include "used_float.fxh"

#endif

#if defined(FRESNEL_FADE)
DECLARE_FLOAT_WITH_DEFAULT(fresnel_fade_exp,"Fresnel Fade Exponent", "", 0.0, 20.0, float(20.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,"Fresnel Fade Intensity", "", 1.0, 20.0, float(1.0));
#include "used_float.fxh"
#endif

#if defined(SCROLL_UV)
//Layer0 Scrolling UV Speed
DECLARE_FLOAT_WITH_DEFAULT(tile0_u,"Layer0 Tile U", "", 0, 1, float(0.30));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(tile0_v,"Layer0 Tile V", "",0, 1, float(1.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll0_u,"Layer0 Scroll U", "",-1, 1, float(0.10));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll0_v,"Layer0 Scroll V","", -1, 1, float(1.00));
#include "used_float.fxh"

//Layer1 Scrolling UV Speed
DECLARE_FLOAT_WITH_DEFAULT(tile1_u,"Layer1 Tile U", "",0, 1, float(0.10));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(tile1_v,"Layer1 Tile V","", 0, 1, float(1.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll1_u,"Layer1 Scroll U", "",-1, 1, float(0.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll1_v,"Layer1 Scroll V", "",-1, 1, float(0.00));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_fade,"Detail Fade", "",-1, 1, float(0.50));
#include "used_float.fxh"

#endif

struct s_shader_data
{
	s_common_shader_data common;
    float3 self_illum;
	float edgeFade;
    float alpha;
};

void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)

{
	shader_data.alpha = 1.0;
	float2 uv    		= pixel_shader_input.texcoord.xy;
	#if defined (EDGE_FADE)
	{//Edge Fade
		float2 uvOffset = (uv-float2(0.5,0.5));
		uvOffset.x = (uvOffset.x * edgefade_sx) + edgefade_ox;
		uvOffset.y = (uvOffset.y * edgefade_sy) + edgefade_oy;
		
		float sphereGrad = saturate(dot(uvOffset,uvOffset) * edgefade_hardness);
		
		if (EDGE_FADE_INVERT)
		{
			shader_data.alpha = saturate(pow(1.0-sphereGrad, edgefade_exp));
		}
		else
		{
			shader_data.alpha = saturate(pow(sphereGrad, edgefade_exp));
		}
	}
	#endif
	{
		float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
    }
	#if defined(SCROLL_UV)
	{
		
		float time = 1.0;
		#if !defined(cgfx) || defined(xenon)
		time = ps_time.z;
		#else
		time = frac(ps_time.x/600.0f);
		#endif
		//Scrolling UV's
		float2 uvLayer0 = (uv * float2(tile0_u,tile0_v)) + (float2(scroll0_u, scroll0_v) * time);
		float2 uvLayer1 = (uv * float2(tile1_u,tile1_v)) + (float2(scroll1_u, scroll1_v) * time);
		//Add Tinting
		shader_data.common.albedo.rgb = si_color.rgb;
		//Mask Alpha
		shader_data.alpha *= shader_data.common.albedo.a;
		#if !defined(USE_FULL_RGB)
		{
			//Combined Color Layers
			float color = sample2DGamma(color_map, uvLayer0).r;
			color += sample2DGamma(color_map, uvLayer1).r;
			//Modulate with alpha and clamp
			float contrast_color = lerp(detail_fade,1.0,min(color,1.0));
			float alpha = min(color+shader_data.alpha,1.0);
			shader_data.common.albedo.rgb *= contrast_color;
			shader_data.alpha *= alpha;
		}
		#else
		{
			float4 color = sample2DGamma(color_map, uvLayer0);
			shader_data.common.albedo.rgb *= color.rgb;
			shader_data.alpha *= color.a;
		}
		#endif
	}
	#else
	{// Sample color map.
		shader_data.common.albedo.rgb *= si_color.rgb;
		shader_data.alpha *= shader_data.common.albedo.a;
		shader_data.common.albedo.a = shader_data.alpha;
	}
	#endif

	{// sample self illum map
       shader_data.self_illum.rgb = shader_data.common.albedo.rgb;
       shader_data.self_illum *= si_intensity;
    }
	#if defined(FRESNEL_FADE)
	{
		float3 view = -shader_data.common.view_dir_distance.xyz;
		float vdotn = saturate(dot(view, shader_data.common.geometricNormal));
		shader_data.alpha *= min(max((pow(vdotn, fresnel_fade_exp) * fresnel_intensity),0.0),1.0);
	}
    #endif
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
    float depthFade = 1.0f;

	float4 out_color = float4(0.0f, 0.0f, 0.0f, shader_data.alpha);
	out_color.rgb = shader_data.common.albedo.rgb;
	
    if (AllowSelfIllum(shader_data.common))
    {
		out_color.rgb += shader_data.self_illum.rgb;

		//Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(shader_data.self_illum);
	}

#if defined(xenon) || (DX_VERSION == 11)
	float2 vPos = shader_data.common.platform_input.fragment_position.xy;
	depthFade = ComputeDepthFade(vPos * psDepthConstants.z, pixel_shader_input.view_vector.w); // stored depth in the view_vector w
#endif
	
	float fade = (shader_data.common.view_dir_distance.w-fade_start)/(fade_end-fade_start);
	out_color.a *= saturate(max(lerp(0.0, 1.0, fade)* depthFade, 0.0));
	return out_color;
}

#include "techniques.fxh"
