#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "final_composite_shared_registers.fxh"


#define DARK_COLOR_MULTIPLIER ps_exposure.g

#include "postprocessing/postprocess_textures.fxh"
#include "final_composite_functions.fxh"


// define default functions, if they haven't been already

#ifndef COMBINE
#define COMBINE default_combine_optimized
#endif // !COMBINE

#ifndef COMBINE_AA
#define COMBINE_AA default_combine_antialiased
#endif // !COMBINE

#ifndef CALC_BLOOM
#define CALC_BLOOM default_calc_bloom
#endif // !CALC_BLOOM

#ifndef CALC_BLEND
#define CALC_BLEND default_calc_blend
#endif // !CALC_BLEND

#ifndef CONVERT_OUTPUT
#define CONVERT_OUTPUT convert_output_gamma2
#endif // !CONVERT_OUTPUT

#ifndef CONVERT_OUTPUT_AA
#define CONVERT_OUTPUT_AA convert_output_antialiased
#endif // !CONVERT_OUTPUT)AA


struct s_default_ps_output
{
	float4 color : SV_Target0;
};

struct s_antialiased_ps_output
{
    float4 antialias_result	: SV_Target0;
    float4 curframe_result	: SV_Target1;
};

#if defined(xenon)
#define tfetch(color, texcoord, sampler, offsetx, offsety)	asm	{ tfetch2D color, texcoord, sampler, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled, OffsetX = offsetx, OffsetY = offsety, UseComputedLOD = false }
#endif

float4 default_combine_optimized(in float2 texcoord)						// final game code: single sample LDR surface, use hardcoded hardware curve
{
	float4 color;
#ifdef pc
	color = sample2D(ps_surface_sampler, texcoord);
#else
	tfetch(color, texcoord, ps_surface_sampler, 0.0f,  0.0f);
#endif
#if DX_VERSION == 11
	color = max(color, 0);
#endif
	return color * float4(DARK_COLOR_MULTIPLIER, DARK_COLOR_MULTIPLIER, DARK_COLOR_MULTIPLIER, 32.0f);
}


float4 default_combine_antialiased(in float2 texcoord, in bool centered)
{
    float4 color;
#ifdef pc
	color = sample2D(ps_surface_sampler, texcoord) * float4(DARK_COLOR_MULTIPLIER, DARK_COLOR_MULTIPLIER, DARK_COLOR_MULTIPLIER, 32.0f);
#else // xenon
    if (centered)
    {
		tfetch(color, texcoord, ps_surface_sampler, 0.0f,  0.0f);
    }
    else
    {
		float4 temp;

		tfetch(temp, texcoord, ps_surface_sampler,  0.0f,  0.0f);
		color=	temp;

		tfetch(temp,    texcoord, ps_surface_sampler, -1.0f,  0.0f);
		color.rgb+= temp.rgb;
		color.a= max(color.a, temp.a);

		tfetch(temp,    texcoord, ps_surface_sampler, -1.0f, -1.0f);
		color.rgb+= temp.rgb;
		color.a= max(color.a, temp.a);

		tfetch(temp, texcoord, ps_surface_sampler,  0.0f, -1.0f);
		color.rgb+= temp.rgb;
		color.a= max(color.a, temp.a);

		color.rgb*= 0.25f;
    }
#endif // xenon
#if DX_VERSION == 11
	color = max(color, 0);
#endif
	return color * float4(DARK_COLOR_MULTIPLIER, DARK_COLOR_MULTIPLIER, DARK_COLOR_MULTIPLIER, 32.0f);
}


// This generally doesn't need to modify bloom coordinates (only screenshot and DOF overrides do)
float4 default_calc_bloom(in float2 texcoord)
{
	return sample2D(ps_bloom_sampler, texcoord);
}


float3 default_calc_blend(in float2 texcoord, in float4 combined, in float4 bloom)
{
	return combined.rgb + bloom.rgb;
}


// 8-bit gammma 2
s_default_ps_output convert_output_gamma2(
	in float4 result,
	in float2 texcoord,
	uniform int colorGradingCount)
{
	s_default_ps_output output;

	// Apply filmic tone curve
	result.rgb =			ApplyFilmicToneCurve(result.rgb);

	// Remap linear space to pseudo-gamma before color grading
	output.color.rgb =		sqrt(result.rgb);
	output.color.a =		result.a;

	// Color grading maps pseudo-gamma to device gamma
	output.color =			apply_color_grading(output.color, colorGradingCount);

	return output;
}


s_antialiased_ps_output convert_output_antialiased(
	in float4 result,
	in float2 texcoord,
	uniform int colorGradingCount)
{
	s_antialiased_ps_output output;

	// Apply color grading to the output value
	result.rgb = convert_output_gamma2(result, texcoord, colorGradingCount).color.rgb;

    [branch]
    if (result.a < 1.0f)														// magically optimizing branch
    {
		// sample previous frame's sRGB value
		float4 prev =				sample2D(ps_prev_sampler, texcoord);

		// calculate AA blending weights
		float min_velocity =		max(result.a, prev.a);
		float expected_velocity =	sqrt(min_velocity);                           // if we write estimated velocity into the alpha channel, we can use them here
		float2 weights =			lerp(float2(0.5f, 0.5f), float2(0.0f, 1.0f), expected_velocity);

		// do the AA blend (square the values to get them closer to a linear value from sRGB)
		float3 blended_result =		sqrt((weights.x * prev.rgb * prev.rgb) + (weights.y * result.rgb * result.rgb));

		// 8-bit gamma2
		output.curframe_result=		result;
		output.antialias_result=	float4(blended_result.rgb, 1.0f);
    }
    else
    {
		// output sRGB value to both buffers
		output.curframe_result=		result;
		output.antialias_result=	float4(result.rgb, 1.0f);
    }

    return output;
}

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

s_default_ps_output default_ps(
	const in s_screen_vertex_output input,
	uniform int colorGradingCount)
{
	// final composite
	float4 combined=	COMBINE(input.texcoord);									// sample and blend full resolution render targets
	float4 bloom=		CALC_BLOOM(input.texcoord);									// sample postprocessed buffer(s)
	float3 blend=		CALC_BLEND(input.texcoord, combined, bloom);				// blend them together

	apply_hue_saturation_contrast(blend);

	float4 result;
	result.rgb=			blend;
	result.a=			combined.a;

	return				CONVERT_OUTPUT(result, input.texcoord, colorGradingCount);
}

s_antialiased_ps_output combine_aa_ps(const in s_screen_vertex_output input, uniform bool centered)
{
	// final composite
	float4 combined=	COMBINE_AA(input.texcoord, centered);						// sample and blend full resolution render targets
	float4 bloom=		CALC_BLOOM(input.texcoord);									// sample postprocessed buffer(s)
	float3 blend=		CALC_BLEND(input.texcoord, combined, bloom);				// blend them together

	apply_hue_saturation_contrast(blend);

	float4 result;
	result.rgb=			blend;
	result.a=			combined.a;

	return				CONVERT_OUTPUT_AA(result, input.texcoord, MAX_COLOR_GRADING_TEXTURES);
}





// _explicit_shader_final_composite
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(0));
	}
}

// _explicit_shader_final_composite_color_grading_1
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(1));
	}
}

// _explicit_shader_final_composite_color_grading_2
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(2));
	}
}





#if defined(TEMPORAL_ANTIALIASING)

// _explicit_shader_final_composite_aa_centered
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(combine_aa_ps(true));
	}
}

// _explicit_shader_final_composite_aa_offset
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(combine_aa_ps(false));
	}
}


#endif