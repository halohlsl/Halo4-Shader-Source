#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"


#if !defined(MAX_COLOR_GRADING_TEXTURES)
#define MAX_COLOR_GRADING_TEXTURES 2
#endif

#include "final_composite_functions_registers.fxh"

#if MAX_COLOR_GRADING_TEXTURES > 0
LOCAL_SAMPLER3D(ps_color_grading_0,		8);
LOCAL_SAMPLER3D(ps_color_grading_1,		9);
#endif


void apply_hue_saturation_contrast(
	inout float3 color,
	uniform bool forcedOn = false)
{
#if defined(xenon) || (DX_VERSION == 11)
	[predicateBlock]
	if (forcedOn || ps_apply_color_matrix)
	{
		// apply hue and saturation (3 instructions)
		color= mul(float4(color, 1.0f), ps_hue_saturation_matrix);
	}

	[predicateBlock]
	if (forcedOn || ps_apply_contrast)
	{
		// apply contrast (4 instructions)
		float luminance = dot(color, float3(0.333f, 0.333f, 0.333f));
		color *= pow(luminance, ps_contrast.w);
	}
#endif // !pc
}

float3 ApplyFilmicToneCurve(
	in float3 sourceColor)
{
	const float3 AFmAE	= ps_filmic_tone_curve_params[0];
	const float3 BCFmBE	= ps_filmic_tone_curve_params[1];
	const float3 AF		= ps_filmic_tone_curve_params[2];
	const float3 BF		= ps_filmic_tone_curve_params[3];
	const float3 DFF	= ps_filmic_tone_curve_params[4];

	// x(AFx-AEx+BCF-BE)/(AFx^2+BFx+DF^2) * LinearWhitePoint
	return (sourceColor * (sourceColor * AFmAE + BCFmBE)) / (sourceColor * (sourceColor * AF + BF) + DFF);
}

float3 InverseFilmicToneCurve(
	in float3 sourceColor)
{
	const float3 AFmAE	= ps_filmic_tone_curve_params[0];
	const float3 BCFmBE	= ps_filmic_tone_curve_params[1];
	const float3 AF		= ps_filmic_tone_curve_params[2];
	const float3 BF		= ps_filmic_tone_curve_params[3];
	const float3 DFF	= ps_filmic_tone_curve_params[4];

	// Inverse of (x * (x * a + b)) / (x * (x * c + d) + e)
	// x = (sqrt(4 * e * y * (a - c * y) + (b - d * y)^2) - b + d * y) / (2 * (a - c * y))
	return (sqrt(4 * DFF * sourceColor * (AFmAE - AF * sourceColor) + (BCFmBE - BF * sourceColor) * (BCFmBE - BF * sourceColor)) - BCFmBE + BF * sourceColor) / (2 * (AFmAE - AF * sourceColor));
}


float4 apply_color_grading(
	in float4 color,
	uniform int maxColorGradingTextures)
{
#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_COLOR_GRADING) && (MAX_COLOR_GRADING_TEXTURES > 0)

	if (maxColorGradingTextures == 1)
	{
		color.rgb *= ps_color_grading_scale_offset[0].xyz;

		// Fetch the color grading sample
#ifdef xenon
		asm
		{
			tfetch3D color, color.rgb, ps_color_grading_0, OffsetX=0.5, OffsetY=0.5, OffsetZ=0.5, UseComputedLOD=false, UseRegisterLOD=false, LODBias=0.0
		};
#else
		color = sample3DLOD(ps_color_grading_0, color.rgb + ps_color_grading_half_texel_offset[0].xyz, 0);
#endif		
	}
	else if (maxColorGradingTextures > 1)
	{
		float4 colorGradingAccum = 0;
		float colorGradingWeight = 0;

		[unroll]
		for (int colorGradingIndex = 0; colorGradingIndex < maxColorGradingTextures; ++colorGradingIndex)
		{
			[branch]
			if (colorGradingIndex == 0 ||									// The first color grading texture is always active
				ps_color_grading_scale_offset[colorGradingIndex].w > 0.0)	// Other color grading textures may have zero weight
			{
				// Remap the range to ensure sampling lines up on the appropriate pixel centers
				float4 colorGradingSample;
				colorGradingSample.rgb = color.rgb * ps_color_grading_scale_offset[colorGradingIndex].xyz;

				// Fetch the color grading sample
				if (colorGradingIndex == 0)
				{
#ifdef xenon				
					asm
					{
						tfetch3D colorGradingSample, colorGradingSample.rgb, ps_color_grading_0, OffsetX=0.5, OffsetY=0.5, OffsetZ=0.5, UseComputedLOD=false, UseRegisterLOD=false, LODBias=0.0
					};
#else
					colorGradingSample = sample3DLOD(ps_color_grading_0, colorGradingSample.rgb + ps_color_grading_half_texel_offset[0].xyz, 0);
#endif
				}
				else
				{
#ifdef xenon				
					asm
					{
						tfetch3D colorGradingSample, colorGradingSample.rgb, ps_color_grading_1, OffsetX=0.5, OffsetY=0.5, OffsetZ=0.5, UseComputedLOD=false, UseRegisterLOD=false, LODBias=0.0
					};
#else
					colorGradingSample = sample3DLOD(ps_color_grading_1, colorGradingSample.rgb + ps_color_grading_half_texel_offset[1].xyz, 0);
#endif
				}

				// Scale the accumulation of color grading values
				colorGradingAccum += colorGradingSample * ps_color_grading_scale_offset[colorGradingIndex].w;
				colorGradingWeight += ps_color_grading_scale_offset[colorGradingIndex].w;
			}
		}

		color = lerp(color, colorGradingAccum, colorGradingWeight);
	}
#endif
	return color;
}
