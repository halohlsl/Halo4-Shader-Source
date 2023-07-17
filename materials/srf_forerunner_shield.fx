//
// File:	 srf_forerunner_shield.fx
// Author:	 willclar
// Date:	 12/3/10
//
// Surface Shader - Forerunner shield, including "erode in", palette sampling, and moving noisy mask textures
//
// Copyright (c) 343 Industries. All rights reserved.
//


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER(baseMap, "Base Map", "Base Map", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(maskA, "Mask A", "Mask A", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(maskB, "Mask B", "Mask B", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(palette, "Palette", "Palette", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"

// Texture controls
DECLARE_FLOAT_WITH_DEFAULT(maskASlideU, "Mask A Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskASlideV, "Mask A Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskBSlideU, "Mask B Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskBSlideV, "Mask B Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskStrength, "Mask Strength", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskUVOffsetStrength, "Mask UV Offset Strength", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskUVOffsetSpeed, "Mask UV Offset Speed", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskUVOffsetFrequency, "Mask UV Offset Frequency", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskUVOffsetEnergyFade, "Mask UV Offset Energy Fade", "", 0, 1, float(1.0));
#include "used_float.fxh"
// DECLARE_FLOAT_WITH_DEFAULT(maskBorderSize, "Mask Border Size", "", 0, 1, float(0.0));
//
// Generic parameters
DECLARE_FLOAT_WITH_DEFAULT(intensity, "Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

// Erode parameters
DECLARE_FLOAT_WITH_DEFAULT(erosionRange, "Erosion Range", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(erodeTime, "Erode Time", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(finalMaskOffset, "Final Mask Offset", "", 0, 1, float(0.2));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(finalMaskScale, "Final Mask Scale", "", 0, 20, float(8));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(shieldColorInput, "Shield Color Input", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(erosionInput, "Erosion Input", "", 0, 1, float(1.0));
#include "used_float.fxh"

// given a sample from the erosion map, convert to a palette sample value
float GetErosionValue(float erosionMapSample)
{
	float result;
	if (erosionRange > 0.0)
	{
		result = saturate(((erosionMapSample + erosionInput) - 1.0) / erosionRange);
	}
	else
	{
		result = (erosionMapSample + erosionInput > 1.0) ? 1.0 : 0.0;
	}

	return result;
}

float2 GetSlidingTexCoord(float2 inputCoord, float slideU, float slideV)
{
	return inputCoord + frac(float2(slideU, slideV) * ps_time.x);
}

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
	in s_pixel_shader_input pixelShaderInput,
	inout s_shader_data shaderData)
{
	float2 maskUV = shaderData.common.normal.xy;
	float2 maskAUV = GetSlidingTexCoord(maskUV, maskASlideU, maskASlideV);
	float2 maskBUV = GetSlidingTexCoord(maskUV, maskBSlideU, maskBSlideV);
	float maskAValue = sample2D(maskA, maskAUV).r;
	float maskBValue = sample2D(maskB, maskBUV).r;
	float maskValue = lerp(1.0, maskAValue * maskBValue, maskStrength);

	float2 uvOffset = maskUVOffsetStrength * float2(maskAValue, maskBValue) * cos(maskUV * maskUVOffsetFrequency + maskUVOffsetSpeed * float2(ps_time.x, ps_time.x));
	uvOffset *= lerp(1.0, shieldColorInput, maskUVOffsetEnergyFade);

	float2 uv = (pixelShaderInput.texcoord.xy + uvOffset);
	uv = ((uv - 0.5) / erosionInput) + 0.5;
	clip(float4(uv.x, uv.y, 1 - uv.x, 1 - uv.y));
	float4 baseMapValue = sample2DGamma(baseMap, uv);
	float borderValue = baseMapValue.g;
	//float erosionValue = GetErosionValue(baseMapValue.g);
	float detailValue = baseMapValue.a;
	float alpha = baseMapValue.r;

	float colorInput = borderValue + (maskValue * detailValue);
	float4 palettizedColor = sample2DGamma(palette, float2(colorInput, shieldColorInput));

	float maskMultiply = saturate((maskValue - finalMaskOffset) * finalMaskScale);

	shaderData.common.albedo = palettizedColor * alpha * lerp(maskMultiply, 1.0, shieldColorInput) * intensity;
}

float4 pixel_lighting(
	in s_pixel_shader_input pixelShaderInput,
    inout s_shader_data shaderData)
{
    // input from shader_data
    return shaderData.common.albedo;
}

void CustomVertexCode(out float3 normal, in float3 localPosition, in float4 localToWorld[3])
{
	float3 shieldPosition = float3(localToWorld[0].w, localToWorld[1].w, localToWorld[2].w);
	float3 shieldLeft = float3(localToWorld[0].y, localToWorld[1].y, localToWorld[2].y);
	float3 shieldUp = float3(localToWorld[0].z, localToWorld[1].z, localToWorld[2].z);
	float3 worldPosition = transform_point(float4(localPosition, 1.0), localToWorld);
	float3 shieldRelativePosition = worldPosition - shieldPosition;
	float2 maskUV = float2(dot(shieldRelativePosition, shieldLeft), dot(shieldRelativePosition, shieldUp));// / maskScale;
	normal = float3(maskUV, 0.0f);
}

#define custom_deformer(vertex, vertexColor, localToWorld) CustomVertexCode(vertex.normal.xyz, vertex.position, localToWorld)

#include "techniques.fxh"