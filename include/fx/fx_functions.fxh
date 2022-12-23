#if !defined(__FX_FUNCTIONS_FXH)
#define __FX_FUNCTIONS_FXH

#include "core/core_functions.fxh"
#include "fx/blend_modes.fxh"

float4 sample2DPalettizedScrolling(texture_sampler_2d inputSampler, texture_sampler_2d paletteSampler, float2 inputUV, float paletteScroll, bool alphaFromPalette)
{
	float4 inputValue = sample2D(inputSampler, inputUV);
	float2 paletteCoord = float2(inputValue.r, paletteScroll);
#if DX_VERSION == 9	
	float4 paletteValue = sample2DGamma(paletteSampler, paletteCoord);
#elif DX_VERSION == 11
	float4 paletteValue = sample2DLOD(paletteSampler, paletteCoord, 0, true);
#endif
	return alphaFromPalette ? paletteValue : float4(paletteValue.rgb, inputValue.a);
}

float4 sample2DPalettized(texture_sampler_2d inputSampler, texture_sampler_2d paletteSampler, float2 inputUV, bool alphaFromPalette)
{
	return sample2DPalettizedScrolling(inputSampler, paletteSampler, inputUV, 0.5f, alphaFromPalette);
}

float4 sample3DPalettizedScrolling(texture_sampler_3d inputSampler, texture_sampler_2d paletteSampler, float3 inputUVW, float paletteScroll, bool alphaFromPalette)
{
	float4 inputValue = sample3D(inputSampler, inputUVW);
	float2 paletteCoord = float2(inputValue.r, paletteScroll);
#if DX_VERSION == 9	
	float4 paletteValue = sample2DGamma(paletteSampler, paletteCoord);
#elif DX_VERSION == 11
	float4 paletteValue = sample2DLOD(paletteSampler, paletteCoord, 0, true);
#endif
	return alphaFromPalette ? paletteValue : float4(paletteValue.rgb, inputValue.a);
}

float4 sample3DPalettized(texture_sampler_3d inputSampler, texture_sampler_2d paletteSampler, float3 inputUVW, bool alphaFromPalette)
{
	return sample3DPalettizedScrolling(inputSampler, paletteSampler, inputUVW, 0.5f, alphaFromPalette);
}

#if DX_VERSION == 11
float4 sample3DPalettizedScrolling(texture_sampler_2d_array inputSampler, texture_sampler_2d paletteSampler, float3 inputUVW, float paletteScroll, bool alphaFromPalette)
{
	float4 inputValue = sampleArrayWith3DCoords(inputSampler, inputUVW);
	float2 paletteCoord = float2(inputValue.r, paletteScroll);
	float4 paletteValue = sample2DLOD(paletteSampler, paletteCoord, 0, true);
	return alphaFromPalette ? paletteValue : float4(paletteValue.rgb, inputValue.a);
}

float4 sample3DPalettized(texture_sampler_2d_array inputSampler, texture_sampler_2d paletteSampler, float3 inputUVW, bool alphaFromPalette)
{
	return sample3DPalettizedScrolling(inputSampler, paletteSampler, inputUVW, 0.5f, alphaFromPalette);
}
#endif

// Specialized routine for smoothly fading out transparents.  Maps
//		[0, black_point] to 0
//		[black_point, mid_point] to [0, 1 - (white_point - mid_point)] linearly
//		[mid_point, white_point] to [1 - (white_point - mid_point), 1] linearly (identity-like)
// where mid_point is halfway between black_point and white_point
//
//		|                   *******
//		|                 **
//		|               **
//		|             **
//		|            *
//		|           *
//		|          *
//		|         *
//		|        *
//		|       *
//		|*******___________________
//      0      bp     mp    wp    1
float ApplyBlackPointAndWhitePoint(float blackPoint, float whitePoint, float alpha)
{
	float midPoint = (whitePoint + blackPoint) / 2.0;

	if (alpha > midPoint)
	{
		return 1 - saturate(whitePoint - alpha);
	}
	else
	{
		return saturate((alpha - blackPoint) / (midPoint - blackPoint)) * (1 - whitePoint + midPoint);
	}
}

float4 vs_apply_exposure(float4 in_color)
{
	float4 out_color= in_color;

#if defined(HAS_ALPHA_BLEND_MODE)
	// in additive blend modes, we need to scale things down to avoid blowing out the bloom
	if (IS_BLEND_MODE_VS(additive) || IS_BLEND_MODE_VS(add_src_times_srcalpha))
	{
		// reduce the exposure
		out_color.rgb*= vs_bungie_additive_scale_and_exposure.y;
	}
	else if (IS_BLEND_MODE_VS(multiply))
	{
		// no exposure adjustment
	}
	else
	{
		out_color.rgb*= vs_bungie_exposure.x;
	}
#endif

	return out_color;
}

float4 ps_apply_exposure(float4 in_color, float4 vert_color, float3 addColor, float tint_factor)
{
	float4 out_color= in_color;

	out_color.rgb *= lerp(vert_color.rgb, float3(1.0f, 1.0f, 1.0f), saturate(tint_factor * dot(vert_color.rgb, vert_color.rgb)));
	out_color.a *= vert_color.a;

	out_color.a = saturate(out_color.a);

#if defined(HAS_ALPHA_BLEND_MODE)
	if (IS_BLEND_MODE_PS(multiply))
	{
		out_color.rgb= lerp(float3(1.0f, 1.0f, 1.0f), out_color.rgb, out_color.a);
		out_color.rgb*= ps_view_exposure.w;
	}
	else
	{
		out_color.rgb += addColor;
		if (IS_BLEND_MODE_PS(pre_multiplied_alpha) || IS_BLEND_MODE_PS(revsubtract))
		{
			out_color.rgb*= out_color.a;
		}

		// just copied this off Bungie; don't like it much
		out_color.a*= ps_view_exposure.w;
	}
#endif

	return out_color;
}

#endif 	// !defined(__FX_FUNCTIONS_FXH)