//
// File:	 srf_ca_boundary.fx
// Author:	 v-tomau
// Date:	 3/13/12
//
// Surface Shader - Boundary shader that supports team color for our game modes
//
// Copyright (c) 343 Industries. All rights reserved.
//

#define ENABLE_DEPTH_INTERPOLATER
#if defined(xenon)
#define ENABLE_VPOS
#endif

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "depth_fade_registers.fxh"

LOCAL_SAMPLER2D(depthSampler, 14);

DECLARE_SAMPLER( overlay_map, "Overlay Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( overlay_detail_map, "Overlay Detail Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(overlay_tint,		"Overlay Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay_intensity,  "Overlay Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER( self_illum_alpha_mask_map, "Alpha Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( self_illum_noise_map_a, "Noise A Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( self_illum_noise_map_b, "Noise B Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( self_illum_palette_map, "Palette Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT( self_illum_intensity,  "Self Illume Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(intensity_fresnel_intensity,		"Intensity Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensity_fresnel_power,			"Intensity Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensity_fresnel_inv,			"Intensity Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(v_coordinate,				"V coordinate", "", 0, 1, float(0.5));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth_highlight_range,  "Depth Highlight Range", "", 0, 5, float(0.4));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(plasma_falloff,  "Plasma Falloff", "", 0, 5, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(top_edge_size,  "Top Edge Size", "", 0, 5, float(0.5));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(noise_power,  "Noise Power", "", 0, 5, float(1.0));
#include "used_float.fxh"

#if defined(xenon) || (DX_VERSION == 11)
	void sampleDepth(in float2 uv, inout float depth)
	{
		float4 s;
#ifdef xenon		
		asm
		{
			tfetch2D s, uv, depthSampler, UnnormalizedTextureCoords=true
		};
#else
		s.x = depthSampler.t.Load(int3(uv, 0)).x;
#endif
		// convert to real depth
		depth = 1.0f - s.x;
		depth = 1.0f / (psDepthConstants.x + depth * psDepthConstants.y);	
	}
#endif

	
float3 calc_overlay_additive_detail_ps(float3 color, float2 texcoord)
{
	float4 overlay=			sample2D(overlay_map,   transform_texcoord(texcoord, overlay_map_transform));
	float4 overlay_detail=	sample2D(overlay_detail_map, transform_texcoord(texcoord, overlay_detail_map_transform));

	const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)
	float3 overlay_color=	overlay.rgb * overlay_detail.rgb * DETAIL_MULTIPLIER * overlay_tint.rgb * overlay_intensity;

	return color + overlay_color;
}

float3 calc_self_illumination_palettized_plasma_change_color_ps(
	in float2 texcoord,
	in float3 view_dir,
	in float3 normal,
	in float2 vPos,
	in float view_vec_w)
{
	float alpha=	sample2D(self_illum_alpha_mask_map, transform_texcoord(texcoord, self_illum_alpha_mask_map_transform)).a;
	float noise_a=	sample2D(self_illum_noise_map_a, transform_texcoord(texcoord, self_illum_noise_map_a_transform)).r;
	float noise_b=	sample2D(self_illum_noise_map_b, transform_texcoord(texcoord, self_illum_noise_map_b_transform)).r;
	float noise = 1.0 - (noise_power * abs(noise_a-noise_b) );

	///////fresnel
	float fresnel = 0.0f;
	{ // Compute fresnel to modulate reflection
		float  vdotn = saturate(dot(view_dir, normal));
		fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
		fresnel = saturate( pow(saturate(fresnel), fresnel_power) * fresnel_intensity );
	}
	//////

	///Depth factor
	float depthEdgeAmount = 0.0;
	{
		float sceneDepth = 0;
	#if defined(xenon) || (DX_VERSION == 11)
		sampleDepth( vPos * psDepthConstants.z, sceneDepth );
	#endif

		float deltaDepth = sceneDepth - view_vec_w;
		depthEdgeAmount = 1.0 - saturate(deltaDepth / depth_highlight_range);
		depthEdgeAmount = depthEdgeAmount * depthEdgeAmount;//we square it to correct the perspective in the general case...
	}
	/////

	//blend the different factors.
	float uvLookup= saturate( 1.0 - (texcoord.y / top_edge_size )   );
	float blendTop = uvLookup + (fresnel * (1.0 - uvLookup ));
	float lookup_selection = sqrt( blendTop * blendTop + ( depthEdgeAmount * depthEdgeAmount ) );
	lookup_selection = saturate( noise * lookup_selection );

	//lookup the pallet value.
	float2 lookup_uv = float2( lookup_selection, v_coordinate );
	float illum= sample2D(self_illum_palette_map,  transform_texcoord(lookup_uv, self_illum_palette_map_transform) );
	
	illum= pow(abs(illum), plasma_falloff);

#if defined(DEBUG_SCALE_UV) 
	float3 self_illum_color = overlay_tint.rgb;
#else
	float3 self_illum_color = ps_material_object_parameters[0] * overlay_tint.rgb;
#endif

	float3 color= illum * self_illum_color * self_illum_intensity * alpha;
	
	return color;
}


struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixelShaderInput,
		inout s_shader_data shaderData)
{
}

float4 pixel_lighting(
        in s_pixel_shader_input pixelShaderInput,
	    inout s_shader_data shaderData
		)
{
	float2 uv = pixelShaderInput.texcoord.xy;

	float3 color = 0;
	color = calc_overlay_additive_detail_ps( color, uv );

	float2 vPos = 0;
#if defined(xenon) || (DX_VERSION == 11)
	vPos = shaderData.common.platform_input.fragment_position.xy;
#endif

	color = color + calc_self_illumination_palettized_plasma_change_color_ps( 
														uv, 
														-shaderData.common.view_dir_distance.xyz,
														shaderData.common.normal,
														vPos,
														pixelShaderInput.view_vector.w);

	///////intensityFresnel
	float intensityFresnel = 0.0f;
	{ // Compute fresnel to modulate reflection
		float  vdotn = saturate(dot(-shaderData.common.view_dir_distance.xyz, shaderData.common.normal));
		intensityFresnel = vdotn + intensity_fresnel_inv - 2 * intensity_fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
		intensityFresnel = 1.0 - saturate( pow(saturate(intensityFresnel), intensity_fresnel_power) * intensity_fresnel_intensity );
	}
	//////

	return float4( color * intensityFresnel, 1.0f );
}

#ifndef USE_TRUE_UV
void CustomVertexCode(inout float2 uv)
{
	uv.x = uv.x * vs_mesh_position_compression_scale.x;
	uv.y = (1.0 - uv.y) * vs_mesh_position_compression_scale.z;//we scale the boundary by the height of the boundary to keep the uv's spread nicely.
}

#define custom_deformer(vertex, vertexColor, localToWorld) CustomVertexCode(vertex.texcoord)
#endif

#include "techniques.fxh"
