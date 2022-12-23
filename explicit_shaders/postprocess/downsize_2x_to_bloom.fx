#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "core/core_functions.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(ps_source_sampler,		0);

#include "final_composite_functions.fxh"


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


[reduceTempRegUsage(3)]
float4 default_ps(
	const in s_screen_vertex_output input,
	uniform int colorGradingCount,
	uniform bool useHighlightBloom,
	uniform bool useSelfIllumBloom,
	uniform bool useInherentBloom,
	uniform bool outputIntensityInAlpha) : SV_Target
{
	float4 sample0 = Sample2DOffset(ps_source_sampler, input.texcoord, -1, -1);
	float4 sample1 = Sample2DOffset(ps_source_sampler, input.texcoord, +1, -1);
	float4 sample2 = Sample2DOffset(ps_source_sampler, input.texcoord, -1, +1);
	float4 sample3 = Sample2DOffset(ps_source_sampler, input.texcoord, +1, +1);

	float4 color = 0;
	color += sample0;
	color += sample1;
	color += sample2;
	color += sample3;
	color /= 4.0f;
#if DX_VERSION == 11
	// Need to saturate on D3D11 because on Xenon the render target saturated naturally at 31.  Alpha
	// is saturated at 1/32.0 which is an artifact of the way the exponent biased render target was used.
	color.rgb = saturate(color.rgb);
	color.a = min(color.a, 1.0/32.0);
#endif		
	color.rgb *= DARK_COLOR_MULTIPLIER;

	// Either use the luminance from the color grading alpha, or calculate directly
	float intensity = (colorGradingCount >= 0)?
		apply_color_grading(color, colorGradingCount).a :
		GetLinearColorIntensity(color.rgb);

	// calculate bloom curve intensity
	// If no bloom settings are defined, set scale to full
	float bloomScale = (useHighlightBloom || useSelfIllumBloom || useInherentBloom) ? 0 : 1;

	// Accumulate different portions of bloom
	if (useHighlightBloom)	bloomScale += ps_scale.x * intensity;		// Highlight Bloom
	if (useSelfIllumBloom)	bloomScale += ps_scale.z * color.a;			// Self-Illum Bloom
	if (useInherentBloom)	bloomScale += ps_scale.y;					// Inherent Bloom

	// calculate bloom color
	float3 bloomColor = color.rgb * bloomScale;

	return float4(bloomColor, (outputIntensityInAlpha) ? intensity : color.a);
}



// Standard downsample for bloom (no color grading)
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(0, true, true, true, true));
	}
}

// Standard downsample for bloom (1 color grading textures)
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(1, true, true, true, true));
	}
}

// Standard downsample for bloom (2 color grading textures)
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(2, true, true, true, true));
	}
}

// Simple downsample that outputs intensity in alpha (used for lightshafts)
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(-1, false, false, false, true));
	}
}

// No color grading, no self-illum, with alpha preservation (used for Hologram)
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps(-1, true, false, true, false));
	}
}
