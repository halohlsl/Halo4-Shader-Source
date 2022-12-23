#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "../copy/displacement_registers.fxh"


LOCAL_SAMPLER2D(ps_surface_sampler,	0);

#define DARK_COLOR_MULTIPLIER ps_exposure.g

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

float4 ApplyMotionSuck(in float2 suckVector, in float suckStrength, float2 pixelPos)
{
	// This function is ugly as sin and not optimized. I am aware of this fact.
	float2 offset = suckVector - pixelPos * float2(1280.0f, 720.0f);
	float displacement = length(offset);
	offset *= sqrt(max(displacement, 100)) / displacement;
	
	const int sampleCount = 10;
	
	offset *= suckStrength * 0.0005f / sampleCount;
	
	const float sampleStrength = 1.0 / sampleCount;
	
	float4 sample = sampleStrength * sample2D(ps_surface_sampler, pixelPos);
	float2 delta = offset;
	for (int i = 0; i < sampleCount - 1; i++)
	{
		sample += sampleStrength * sample2D(ps_surface_sampler, pixelPos + delta);
		delta += offset;
	}
	
	//float intensity = GetLinearColorIntensity(sample.rgb);
	//sample.rgb /= intensity;
	sample.a = 2.0f * abs(suckStrength);// / max(intensity, 0.1);
	
	return sample;
}

float4 default_ps(
	const in s_screen_vertex_output input,
	uniform int colorGradingCount,
	uniform bool useHighlightBloom,
	uniform bool useSelfIllumBloom,
	uniform bool useInherentBloom,
	uniform bool outputIntensityInAlpha,
	uniform bool applyMotionSuck,
	uniform bool fakeSelfIllum) : SV_Target
{
	float4	sample;
	if (applyMotionSuck)
	{
		sample = ApplyMotionSuck(ps_motionSuckVectorAndLength.xy, ps_motionSuckVectorAndLength.w, input.texcoord);
	}
	else
	{
		// Sample and scale the buffer
		sample = sample2D(ps_surface_sampler, input.texcoord);
	}
	
#if DX_VERSION == 11
	// Need to saturate on D3D11 because on Xenon the render target saturated naturally at 31.  Alpha
	// is saturated at 1/32.0 which is an artifact of the way the exponent biased render target was used.
	sample.rgb = saturate(sample.rgb);	
	if (! fakeSelfIllum)
	{
		sample.a = min(sample.a, 1.0/32.0);
	} else
	{
		sample.a = 0;
	}
#endif	
	sample.rgb *= DARK_COLOR_MULTIPLIER;

	// Either use the luminance from the color grading alpha, or calculate directly
	float intensity = (colorGradingCount >= 0)?
		apply_color_grading(sample, colorGradingCount).a :
		GetLinearColorIntensity(sample);

	// If no bloom settings are defined, set scale to full
	float bloomScale = (useHighlightBloom || useSelfIllumBloom || useInherentBloom) ? 0 : 1;

	// Accumulate different portions of bloom
	if (useHighlightBloom)	bloomScale += ps_scale.x * intensity;		// Highlight Bloom
	if (useSelfIllumBloom)	bloomScale += ps_scale.z * sample.a;		// Self-Illum Bloom
	if (useInherentBloom)	bloomScale += ps_scale.y;					// Inherent Bloom

	// Hack to apply self-illum boost to bright pixels when we don't have self-illum information in the render target
	if (fakeSelfIllum && useSelfIllumBloom)
	{
		bloomScale += saturate((GetLinearColorIntensity(sample) - ps_intensity.x) * ps_intensity.y) * ps_scale.z;
	}
	
	// Get the scaled value
	float3 bloomColor = sample.rgb * bloomScale;

	return float4(bloomColor, (outputIntensityInAlpha) ? intensity : sample.a);
}

#define MAKE_BLOOM_TECHNIQUE(colorGradingCount, useHighlightBloom, useSelfIllumBloom, useInherentBloom, outputIntensityInAlpha, applyMotionSuck, fakeSelfIllum) \
BEGIN_TECHNIQUE \
{ \
	pass screen \
	{ \
		SET_VERTEX_SHADER(default_vs()); \
		SET_PIXEL_SHADER(default_ps(colorGradingCount, useHighlightBloom, useSelfIllumBloom, useInherentBloom, outputIntensityInAlpha, applyMotionSuck, fakeSelfIllum)); \
	} \
}

#define MAKE_BLOOM_TECHNIQUES(fakeSelfIllum)												\
	/* Standard downsample for bloom (no color grading) */                                  \
	MAKE_BLOOM_TECHNIQUE(0, true, true, true, true, false, fakeSelfIllum)               \
                                                                                            \
	/* Standard downsample for bloom (1 color grading textures) */                          \
	MAKE_BLOOM_TECHNIQUE(1, true, true, true, true, false, fakeSelfIllum)               \
                                                                                            \
	/* Standard downsample for bloom (2 color grading textures) */                          \
	MAKE_BLOOM_TECHNIQUE(2, true, true, true, true, false, fakeSelfIllum)               \
                                                                                            \
	/* Simple downsample that outputs intensity in alpha (used for lightshafts) */          \
	MAKE_BLOOM_TECHNIQUE(-1, false, false, false, true, false, fakeSelfIllum)          \
                                                                                            \
	/* No color grading, no self-illum, with alpha preservation (used for Hologram) */      \
	MAKE_BLOOM_TECHNIQUE(-1, true, false, true, false, false, fakeSelfIllum)           \
                                                                                            \
	/* Bloom with motion blur (no color grading) */                                        	\
	MAKE_BLOOM_TECHNIQUE(0, true, true, true, false, true, fakeSelfIllum)               \
                                                                                            \
	/* Bloom with motion blur (1 color grading textures) */                                 \
	MAKE_BLOOM_TECHNIQUE(1, true, true, true, false, true, fakeSelfIllum)               \
                                                                                            \
	/* Bloom with motion blur (2 color grading textures) */                                 \
	MAKE_BLOOM_TECHNIQUE(2, true, true, true, false, true, fakeSelfIllum)
	
MAKE_BLOOM_TECHNIQUES(false)
MAKE_BLOOM_TECHNIQUES(true)
