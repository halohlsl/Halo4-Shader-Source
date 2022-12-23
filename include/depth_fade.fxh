#if !defined(__DEPTH_FADE_FXH)
#define __DEPTH_FADE_FXH

#if !defined(DEFAULT_DEPTH_FADE_RANGE)
#define DEFAULT_DEPTH_FADE_RANGE 0.0f
#endif // !defined(DEFAULT_DEPTH_FADE_RANGE)

#if !defined(DEPTH_FADE_SWITCH)
#define DEPTH_FADE_SWITCH ""
#endif // !defined(DEPTH_FADE_SWITCH)

// by default use a material parameter, but allow overriding
#if !defined(DEPTH_FADE_RANGE)
#define DEPTH_FADE_RANGE DepthFadeRange
#endif // !defined(DEPTH_FADE_RANGE)
#if !defined(DEPTH_FADE_INVERT)
#define DEPTH_FADE_INVERT DepthFadeInvert
#endif // !defined(DEPTH_FADE_INVERT)

#include "depth_fade_registers.fxh"

DECLARE_FLOAT_WITH_DEFAULT(DepthFadeRange, "Depth Fade Range", DEPTH_FADE_SWITCH, 0, 5, DEFAULT_DEPTH_FADE_RANGE);
#include "used_float.fxh"
DECLARE_BOOL_WITH_DEFAULT(DepthFadeInvert, "Depth Fade Invert", DEPTH_FADE_SWITCH, false);
#include "next_bool_parameter.fxh"

float ComputeDepthFade(float2 screenCoords, float inputDepth)
{
#if defined(xenon) || (DX_VERSION == 11)
	float4 depthValue;
#ifdef xenon	
	asm 
	{
		tfetch2D depthValue, screenCoords, psDepthSampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
#else
	int3 intScreenCoords = int3(screenCoords, 0);
	depthValue = psDepthSampler.t.Load(intScreenCoords);
#endif
	
	// used to be this (which is slightly better on ALUs, but lacks resolution far away:
	//float sceneDepth = 1.0f - depthValue.x;
	//sceneDepth = 1.0f / (psDepthConstants.x + sceneDepth * psDepthConstants.y); // convert to real depth
	
	// Now, to avoid tossing out precision in the first step, we have:
	float sceneDepth = 1.0f / ((psDepthConstants.x + psDepthConstants.y) - psDepthConstants.y * depthValue.x);
	
	float deltaDepth = sceneDepth - inputDepth;
	if (DEPTH_FADE_INVERT)
	{
		return saturate(1.0 - deltaDepth / DEPTH_FADE_RANGE);
	}
	else
	{
		return saturate(deltaDepth / DEPTH_FADE_RANGE);
	}
#else // defined(xenon)
	return 1.0f;
#endif // defined(xenon)
}

#endif 	// !defined(__DEPTH_FADE_FXH)
