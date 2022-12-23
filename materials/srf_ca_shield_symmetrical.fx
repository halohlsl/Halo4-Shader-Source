//
// File:	 srf_ca_shield_symmetrical.fx
// Author:	 v-jcleav
// Date:	 5/18/12
//
// Surface Shader - Shield material center component
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

//----------------------------
DECLARE_SAMPLER(overlayMap, "Overlay Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(overlayMap2, "Overlay Map 2", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay1Intensity, "Overlay 1 Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay2Intensity, "Overlay 2 Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensity, "Global Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensity2, "Global Intensity2", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay1AlphaThreshold, "Overlay 1 Alpha Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay2AlphaThreshold, "Overlay 2 Alpha Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay1ThresholdWidth, "Overlay 1 Threshold Width", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay2ThresholdWidth, "Overlay 2 Threshold Width", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay1ThresholdIntensity, "Overlay 1 Threshold Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(overlay2ThresholdIntensity, "Overlay 2 Threshold Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(overlayTint, "Overlay Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(changeColorAmount, "Primary Change Color Amount", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(symmetricFadeAmount, "Symmetric Fade", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(symmetricFadePower, "Symmetric Fade Power", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(gradientLowerBoundTint, "Gradient Lower Bound Tint", "", float3(0.6, 0.25, 0.6));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(gradientMidpoint, "Gradient Tint Midpoint", "", 0, 1, float(0.5));
#include "used_float.fxh"

DECLARE_SAMPLER(distortionMap, "Distortion Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distortionStrength, "Gradient Tint Midpoint", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_SAMPLER(illumPaletteMap, "Depth Palette Map", "", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(selfIllumIntensity,  "Self Illum Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depthHighlightRange,  "Depth Highlight Range", "", 0, 5, float(0.4));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depthFade, "Depth Fade", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(plasmaFalloff, "Plasma Falloff", "", 0, 5, float(1.0));
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

void ApplyPalette(
	in float paletteLookup,
	inout float3 color)
{
	paletteLookup = saturate(paletteLookup);
	
	// Combine the two tints -- these are almost never used together
	float3 mixedTint = ps_material_object_parameters[0].rgb * overlayTint.rgb;
	
	// Contrive a three-color palette for the mixed tint to maintain hot whites
	// and interesting color variations
	const float3 higherBound = (float3)1;
	float3 lowerBound = mixedTint * gradientLowerBoundTint;
	
	// Use the user-defined midpoint for finer control of this gradient
	const float e = 0.000001;
	float gradientScalar = saturate(1.0 / (gradientMidpoint + e));
	
	float3 left = lerp( lowerBound, mixedTint, clamp(paletteLookup, 0.0, gradientMidpoint) * gradientScalar );
	float3 right = lerp( mixedTint, higherBound, (clamp(paletteLookup, gradientMidpoint, 1.0) - gradientMidpoint) / (1.0 - gradientMidpoint + e) );
	
	// Wherever you go, there you are
	float3 mixedPaletteColor = paletteLookup < 0.5 ? left : right;
	
	// Apply palette
	color *= mixedPaletteColor;
}

float2 CalcUVDistortion(float2 uv)
{
	float2 distortionUV = transform_texcoord(uv, distortionMap_transform);
	float2 distortion = (sample2D(distortionMap, distortionUV).rg * 2.0 - 1.0) * distortionStrength;
	
	return uv + distortion;
}

float4 CalcPalettizedOverlays(float4 color, float2 texcoord)
{
	float4 overlay = sample2D(overlayMap, transform_texcoord(texcoord, overlayMap_transform));
	float4 overlay2 = sample2D(overlayMap2, transform_texcoord(texcoord, overlayMap2_transform));
	
	// Apply the symmetric fade to the second overlay
	float computedSymmetricFade = pow(1.0 - texcoord.x, symmetricFadePower) * symmetricFadeAmount;
	overlay2 -= (overlay2 * computedSymmetricFade);
	
	// Apply threshold effect
	float overlay1Threshold = (1.0 - saturate(abs(overlay1AlphaThreshold - overlay.a) / overlay1ThresholdWidth)) * overlay1ThresholdIntensity;
	float overlay2Threshold = (1.0 - saturate(abs(overlay2AlphaThreshold - overlay2.a) / overlay2ThresholdWidth)) * overlay2ThresholdIntensity;
	overlay.rgb += overlay.a * overlay1Threshold;
	overlay2.rgb += overlay2.a * overlay2Threshold;
	
	float4 overlayColor = overlay * overlay1Intensity + overlay2 * overlay2Intensity;
	
	// Apply the palette
	ApplyPalette(overlayColor.r, overlayColor.rgb);
	
	return color + overlayColor;
}

void CompositeDepthContribution(
	in float2 texcoord,
	in float3 view_dir,
	in float3 normal,
	in float2 vPos,
	in float view_vec_w,
	inout float4 color)
{
	// Compute depth factor
	float depthEdgeAmount = 0;
	float depthFadeAmount = 0;
	{
		float sceneDepth = 0;
		
#if defined(xenon)
		sampleDepth( vPos * psDepthConstants.z, sceneDepth );
#endif
		
		float deltaDepth = sceneDepth - view_vec_w;
		depthEdgeAmount = 1.0 - saturate(deltaDepth / depthHighlightRange);
		depthEdgeAmount = depthEdgeAmount * depthEdgeAmount; // Squared for perspective correction
		
		depthFadeAmount = 1.0 - saturate(deltaDepth); // Fades over one world unit (whatever)
		depthFadeAmount *= depthFadeAmount; // Squared for same reason
	}

	// Now lookup into the illum depth palette
	float2 paletteLookup = float2( depthEdgeAmount, 0 );
	float illum = sample2D(illumPaletteMap, transform_texcoord(paletteLookup, illumPaletteMap_transform) );
	
	illum = pow(abs(illum), plasmaFalloff);

	float3 composite = illum;
	ApplyPalette(illum, composite);
	composite *= selfIllumIntensity;
	
	color += float4(composite, 1);
	
	// Depth fade is applied to the entire composite
	color = lerp(color, color - (color * depthFadeAmount), depthFade);
	
	// Apply global intensity(s)
	color *= intensity * intensity2;
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
	uv = CalcUVDistortion(uv);

	float4 color = 0;
	color = CalcPalettizedOverlays( color, uv );

	float2 vPos = 0;
	
#if defined(xenon)
	vPos = shaderData.common.platform_input.fragment_position.xy;
#endif

	CompositeDepthContribution( 
		uv, 
		-shaderData.common.view_dir_distance.xyz,
		shaderData.common.normal,
		vPos,
		pixelShaderInput.view_vector.w,
		color);
	
	return color;
}

#include "techniques.fxh"
