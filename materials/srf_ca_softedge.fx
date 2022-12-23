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

DECLARE_SAMPLER( falloff_palette_map, "Falloff Palette Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(colorBlack,		"Color Black", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(blackItensity,		"Black Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(colorWhite,		"Color White", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(whiteItensity,		"White Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(v_coordinate,				"V coordinate", "", 0, 1, float(0.5));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth_fade_range,  "Depth Fade Range", "", 0, 5, float(0.4));
#include "used_float.fxh"

#if defined(xenon)
	void sampleDepth(in float2 uv, inout float depth)
	{
		float4 s;
		asm
		{
			tfetch2D s, uv, depthSampler, UnnormalizedTextureCoords=true
		};
		// convert to real depth
		depth = 1.0f - s.x;
		depth = 1.0f / (psDepthConstants.x + depth * psDepthConstants.y);	
	}
#endif


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

	float2 vPos = 0;

	///Depth factor
	float depthFadeAmount = 1.0;
	#if defined(xenon)
	{
		float sceneDepth = 0;
		float2 vPos = shaderData.common.platform_input.fragment_position.xy;
		sampleDepth( vPos * psDepthConstants.z, sceneDepth );

		float deltaDepth = sceneDepth - pixelShaderInput.view_vector.w;
		depthFadeAmount = saturate(deltaDepth / depth_fade_range);
	}
	#endif
	/////

	///// // Compute lookup value based on the normal / view dir.
	float normalCoord = saturate(dot(-shaderData.common.view_dir_distance.xyz, shaderData.common.normal));;
	float2 falloff_palette_uv = transform_texcoord( float2( normalCoord, v_coordinate ), falloff_palette_map_transform);
	float lookupValue = sample2D( falloff_palette_map, falloff_palette_uv );
	//////

	float3 color = lerp( colorBlack * blackItensity, colorWhite * whiteItensity, lookupValue );

	return float4( color * depthFadeAmount, 1.0f );
}

#include "techniques.fxh"
