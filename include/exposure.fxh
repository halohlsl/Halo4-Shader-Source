#if !defined(__EXPOSURE_FXH)
#define __EXPOSURE_FXH

#include "core/core.fxh"


#define SINGLE_PASS_LIGHTING_SCALE 32.0f
#define DECORATOR_SINGLE_PASS_LIGHTING_SCALE SINGLE_PASS_LIGHTING_SCALE


float apply_exposure_alpha(in float alpha)
{
#if !defined(DISABLE_EXPOSURE) && (defined(xenon) || (DX_VERSION == 11))	// only adjust exposure on xenon and d3d11
	alpha *= ps_view_exposure.w;
#endif
	return alpha;
}

float4 apply_exposure_scale(in float4 shadedPixel)
{
#if !defined(DISABLE_EXPOSURE) && (defined(xenon) || (DX_VERSION == 11))	// only adjust exposure on xenon and d3d11
	shadedPixel.rgba *= ps_view_exposure.xxxw;
#endif

	return shadedPixel;
}

// Mixes standard and self-illum exposure settings
float4 ApplyExposureScaleSelfIllum(in float4 shadedPixel, float selfIllumIntensity)
{
#if !defined(DISABLE_EXPOSURE) && (defined(xenon) || (DX_VERSION == 11))	// only adjust exposure on xenon and d3d11
	shadedPixel.rgba *= lerp(ps_view_exposure.xxxw, ps_view_self_illum_exposure.yyyw, saturate(selfIllumIntensity));
#endif

	return shadedPixel;
}


// Applies standard expousre settings
float4 apply_exposure(in float4 shadedPixel, uniform bool isAlphaBlend = false)
{
	float4 exposedPixel = apply_exposure_scale(shadedPixel);

	if (isAlphaBlend)
	{
		exposedPixel = lerp(exposedPixel, shadedPixel * ps_view_exposure.w, ps_material_blend_constant.z);
	}

	return apply_output_gamma(exposedPixel);
}

// Applies exposure settings based on how 'self-illum' the pixel is
float4 ApplyExposureSelfIllum(in float4 shadedPixel, float selfIllumIntensity, uniform bool isAlphaBlend = false)
{
	float4 exposedPixel = ApplyExposureScaleSelfIllum(shadedPixel, selfIllumIntensity);

	if (isAlphaBlend)
	{
		exposedPixel = lerp(exposedPixel, shadedPixel * ps_view_exposure.w, ps_material_blend_constant.z);
	}

	return apply_output_gamma(exposedPixel);
}



#endif 	// !defined(__EXPOSURE_FXH)