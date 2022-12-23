//
// File:	 srf_ca_monitor.fx
// Author:	 v-tomau
// Date:	 4/24/12
//
// Surface Shader - Monitor shader that supports team color for our game modes 
//
// Copyright (c) 343 Industries. All rights reserved.
//

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER(diffuseMap, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(scanMap, "Scan Map", "Scan Map", "shaders/default_bitmaps/bitmaps/alpha_black.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(uvOffsetMap, "UV Offset Map", "UV Offset map", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(uvOffsetStrength, "UV Offset Strength", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(uvOffsetSpeed, "UV Offset Speed", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(uvOffsetFrequency, "UV Offset Frequency", "", 0, 10, float(1.0));
#include "used_float.fxh"

#if defined(SPIN_UV)
DECLARE_FLOAT_WITH_DEFAULT(spinColorAngle, "Color Map Spin", "", 0, 360, float(1.0));
#include "used_float.fxh"
#endif

DECLARE_FLOAT_WITH_DEFAULT(intensity, "Global Intensity", "", 0, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensityMask, "Global Intensity Mask", "", 0, 5, float(1.0));//This is necessary so that I can have the traditional intensity, coupled with a scripted intensity to turn the whole thing on in a binary fashion.
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(holoIntensity, "Holo Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scanIntensity, "Scan Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(changeColorAmount, "Primary Change Color Amount", "", 0, 1, float(1.0));
#include "used_float.fxh"

#if defined(PROGRESS_MAP)
//Adds a lookup color modifier based on a progress amount.
DECLARE_FLOAT_WITH_DEFAULT(progressAmount, "Amount of progress the shader should show.", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(progressColorEmpty,	"Empty Progress Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(progressColorFull,	"Full Progress Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(progressColorFullEdge,	"Full Progress Edge Color", "", float3(1,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(progressFullEdgeSize, "Full Progress Edge Size", "", 0, 1, float(0.1));
#include "used_float.fxh"
#endif

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
		in s_pixel_shader_input pixelShaderInput,
		inout s_shader_data shaderData)
{
#if defined(xenon) || (DX_VERSION == 11)

	// Base hologram color
	float2 uv = transform_texcoord(pixelShaderInput.texcoord.xy, uvOffsetMap_transform);
	float2 offsetValue = sample2D(uvOffsetMap, uv).rg;
	float2 uvOffset = uvOffsetStrength * offsetValue * cos(uvOffsetFrequency + uvOffsetSpeed * float2(ps_time.x, ps_time.x));
	
	//float2 vPos = shaderData.common.platform_input.fragment_position.xy;
	
#if defined(SPIN_UV)
	float sinAngle;
	float cosAngle;
	//NOTE: I could bake this into a transform, but would it be faster...
	sincos( radians( spinColorAngle ), sinAngle, cosAngle );
	uv = pixelShaderInput.texcoord.xy - float2( 0.5, 0.5 );
	uv = float2( uv.x * cosAngle + uv.y * sinAngle,  
		         uv.y * cosAngle - uv.x * sinAngle );
	uv = uv + float2( 0.5, 0.5 );
	uv = transform_texcoord(uv, diffuseMap_transform) + uvOffset;
#else
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, diffuseMap_transform) + uvOffset;
#endif

	float4 diffuse = sample2DGamma(diffuseMap, uv);
#if defined(PROGRESS_MAP)
	float delta = diffuse.a - progressAmount;
	float progressT = saturate( ( delta * 100 ) );
	float progressEdge = saturate( ( ( delta ) / (progressFullEdgeSize < 0.001 ? 0.001 : progressFullEdgeSize) ) );
	diffuse.rgb = diffuse.rgb * lerp( progressColorEmpty, lerp( progressColorFullEdge, progressColorFull, progressEdge ), progressT );
#endif
	float4 hologramColor = float4(diffuse.rgb, 1.0) * holoIntensity;
	
	// Scan contribution (gets more offset, too)
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, scanMap_transform) + uvOffset * 2.0;
	float4 scanColor = sample2D(scanMap, uv) * scanIntensity;
	hologramColor += scanColor;
	
#if !defined(PROGRESS_MAP)	
	// The alpha channel of the diffuse texture is revealed by the scan texture
	hologramColor += scanColor * diffuse.a;
#endif
	
	float4 changeColor = lerp( float4( 1.0, 1.0, 1.0, 1.0), ps_material_object_parameters[0], changeColorAmount ) ;  
	
	shaderData.common.albedo = (hologramColor * changeColor) * intensity * intensityMask;
	
#else // PC

	// Just output the diffuse on the PC for speed
	float2 uv = transform_texcoord(pixelShaderInput.texcoord.xy, diffuseMap_transform);
	float4 diffuse = sample2DGamma(diffuseMap, uv);
	
	shaderData.common.albedo = diffuse;

#endif
	
#ifdef VERT_MASK
	// Respect vertex alpha
	shaderData.common.albedo *= shaderData.common.vertexColor.a;
#endif
}

float4 pixel_lighting(
        in s_pixel_shader_input pixelShaderInput,
	    inout s_shader_data shaderData)
{
	// input from shader_data 
    return shaderData.common.albedo;
}


#include "techniques.fxh"
