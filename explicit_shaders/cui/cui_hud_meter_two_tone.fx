#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"
#include "cui_transform.fxh"		// adds the default vertex shader

#define MeterEpsilon	0.00001
#define MeterBias		(-MeterEpsilon/256.0)
#define MeterScale		((256.0+MeterEpsilon+MeterEpsilon)/256.0)

#define LeftColor		k_cui_pixel_shader_color0
#define RightColor		k_cui_pixel_shader_color1

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
// k_cui_pixel_shader_color0= left color
// k_cui_pixel_shader_color1= right color
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
	float curMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar0);
	float minMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar1);
	float maxMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar2);
	
	clip( step(minMeterValue, curMeterValue) - 0.5 );
	clip( step(curMeterValue, maxMeterValue) - 0.5 );
	
	float4 sample = sample2D(source_sampler0, texcoord);
	
	float isLeft = step(sample.b, curMeterValue);
	
	float4 gammaLeft = cui_linear_to_gamma2(LeftColor);
	float4 gammaRight = cui_linear_to_gamma2(RightColor);
	float4 original = sample.rrra;
	return lerp( original * gammaRight, original * gammaLeft, isLeft );
}

float4 BuildResultMultisampled(in float2 texcoord, in float4 gradients)
{
	float curMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar0);
	float minMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar1);
	float maxMeterValue = ScaleBiasComparand(k_cui_pixel_shader_scalar2);
	
	clip( step(minMeterValue, curMeterValue) - 0.5 );
	clip( step(curMeterValue, maxMeterValue) - 0.5 );

	// Grab three samples to see if we are near the leading edge of the meter
	float4 leftSample = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2(-1.0, 0.0)));
	float4 primarySample = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2(0.0, 0.0)));
	float4 rightSample = sample2D(source_sampler0, biasedTexCoord(texcoord, gradients, float2(1.0, 0.0)));
	
	float isLeft = step(primarySample.b, curMeterValue);
	
	float3 steps = float3( step(leftSample.b, curMeterValue),
			       isLeft,
			       step(rightSample.b, curMeterValue) );
	
	float3 leftBlendAmts = float3( 0.333, 0.333, 0.333 );
	float leftAmt = saturate( dot( steps, leftBlendAmts ) );
	
	float4 gammaLeft = cui_linear_to_gamma2(LeftColor);
	float4 gammaRight = cui_linear_to_gamma2(RightColor);
	float4 original = primarySample.rrra;
	return lerp(original * gammaRight, original * gammaLeft, leftAmt);
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
	float4 result = BuildResultSingle(texcoord);
#endif

	// Final rgb result is the user color multiplied by the bitmap's intensity channel, and the bitmap's
	// alpha channel multiplied by the user alpha.

	float4 tint = cui_linear_to_gamma2(k_cui_pixel_shader_tint);

	result *= tint;

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
