#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"
#include "cui_transform.fxh"		// adds the default vertex shader

#define MeterEpsilon	0.00001
#define MeterBias		(-MeterEpsilon/256.0)
#define MeterScale		((256.0+MeterEpsilon+MeterEpsilon)/256.0)

// ==== SHADER DOCUMENTATION
// 
// ---- COLOR OUTPUTS
// k_cui_pixel_shader_color0= unused
// 
// ---- SCALAR OUTPUTS
// k_cui_pixel_shader_scalar0= current meter value (0 .. 1)
// k_cui_pixel_shader_scalar1= meter minimum value (0 .. 1)
// k_cui_pixel_shader_scalar2= meter maximum value (0 .. 1)
// k_cui_pixel_shader_scalar3= unused
//
// ---- BITMAP CHANNELS
// A: alpha (except for empty meter regions, which are transparent)
// R: intensity
// G: unused
// B: meter mask

float2 biasedTexCoord(in float2 baseTexCoord, in float4 gradients, in float2 stepOffset)
{
	return baseTexCoord + (gradients.xz * stepOffset.x) + (gradients.yw * stepOffset.y);
}

float ScaleBiasComparand(float comparand)
{
	return (saturate(comparand) * MeterScale) + MeterBias;
}

float4 BuildResultSingle(float2 texcoord)
{
	float4 bitmap_result = sample2D(source_sampler0, texcoord);

	// Result rgb channels use the intensity mask from the red channel replicated across the red green and blue channels.
	float4 result = float4(bitmap_result.rrr, bitmap_result.a);

	// Clip the alpha value for meter fragments above the meter edge value, and outside the minimum/maximum values.
	// Meter value for the current fragment is the blue channel.
	result.a *= step(bitmap_result.b, ScaleBiasComparand(k_cui_pixel_shader_scalar0)) *	// Clip to the current meter value
		step(bitmap_result.b, ScaleBiasComparand(k_cui_pixel_shader_scalar2)) *			// Clip to the maximum meter value
		step(ScaleBiasComparand(k_cui_pixel_shader_scalar1), bitmap_result.b);			// Clip to the minimum meter value

	return result;
}

float4 BuildResultMultisampled(in float2 texcoord, in float4 gradients)
{
	float4 sampleGroup1;
	float4 sampleGroup2;

	// Grab three samples to see if we are near the leading edge of the meter
	sampleGroup1[0] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2(-1.00, -1.00))).b;
	float4 primarySample = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2(0.00, 0.00)));
	sampleGroup2[3] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2( 1.00,  1.00))).b;

	float curMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar0);
	float minMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar1);
	float maxMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar2);

	// If all three samples are from one side of the leading edge or the other, just use the primary sample.
	// Note: The expensive path should be located inside the conditional. For more info see [branch] XDK documents.
	float primaryClipped = step(primarySample.b, curMeterValue) * step(primarySample.b, maxMeterValue) * step(minMeterValue, primarySample.b);
	if (step(sampleGroup1[0], curMeterValue) != primaryClipped ||
		step(sampleGroup2[3], curMeterValue) != primaryClipped)
	{
		// The samples straddle the leading edge of the meter, so we need to grab the full 9 samples for decent
		// antialiasing
		sampleGroup1[1] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2( 0.00, -1.00))).b;
		sampleGroup1[2] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2( 1.00, -1.00))).b;
		sampleGroup1[3] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2(-1.00,  0.00))).b;
		sampleGroup2[0] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2( 1.00,  0.00))).b;
		sampleGroup2[1] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2(-1.00,  1.00))).b;
		sampleGroup2[2] = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2( 0.00,  1.00))).b;

		// Weight and sum the samples
		float weightedSum;
		weightedSum  = dot(sampleGroup1, float4(1.0f, 2.0f, 1.0f, 2.0f));
		weightedSum += dot(sampleGroup2, float4(2.0f, 1.0f, 2.0f, 1.0f));
		weightedSum += primarySample.b * 4.0f;
		weightedSum /= 16.0f;

		// Weight and sum the individual clipped values
		float4 clipGroup1;
		clipGroup1  = step(sampleGroup1, float4(curMeterValue, curMeterValue, curMeterValue, curMeterValue));
		clipGroup1 *= step(sampleGroup1, float4(maxMeterValue, maxMeterValue, maxMeterValue, maxMeterValue));
		clipGroup1 *= step(float4(minMeterValue, minMeterValue, minMeterValue, minMeterValue), sampleGroup1);

		float4 clipGroup2;
		clipGroup2  = step(sampleGroup2, float4(curMeterValue, curMeterValue, curMeterValue, curMeterValue));
		clipGroup2 *= step(sampleGroup2, float4(maxMeterValue, maxMeterValue, maxMeterValue, maxMeterValue));
		clipGroup2 *= step(float4(minMeterValue, minMeterValue, minMeterValue, minMeterValue), sampleGroup2);

		float weightedAlpha;
		weightedAlpha  = dot(clipGroup1, float4(1.0f, 2.0f, 1.0f, 2.0f));
		weightedAlpha += dot(clipGroup2, float4(2.0f, 1.0f, 2.0f, 1.0f));
		weightedAlpha += primaryClipped * 4.0f;
		weightedAlpha /= 16.0f;

		return float4(primarySample.rrr, primarySample.a * step(weightedSum, curMeterValue) * weightedAlpha);
	}

	// Fast path uses fallthrough from conditional
	return float4(primarySample.rrr, primarySample.a * primaryClipped);
}

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float2 texcoord = input.texcoord;

#if (! defined(pc)) || (DX_VERSION == 11)

#ifdef xenon
	float4 gradients;
	asm {
		getGradients gradients, texcoord, source_sampler0
	};
#else
	float4 gradients = GetGradients(texcoord);
#endif
	
	float4 result = BuildResultMultisampled(texcoord, gradients);
#else
	float4 result= BuildResultSingle(texcoord);
#endif

	// Final rgb result is the user color multiplied by the bitmap's intensity channel, and the bitmap's
	// alpha channel multiplied by the user alpha.

	float4 tint = cui_linear_to_gamma2(k_cui_pixel_shader_tint);

	result.rgb = tint.rgb * result.r;
	result.a *= k_cui_pixel_shader_tint.a;

	return cui_convert_to_premultiplied_alpha(result, k_cui_sampler0_transform) * ps_scale;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE curved_cui
{
	pass screen
	{
		SET_VERTEX_SHADER(curved_cui_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
