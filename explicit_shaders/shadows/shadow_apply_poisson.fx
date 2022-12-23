#ifndef NUM_TAPS
	#define NUM_TAPS 12
#endif // NUM_TAPS

#define FASTER_SHADOWS
#define SHADOW_APPLY_JUST_USE_FETCH_RESULT
#define EXCLUDE_MODEL_MATRICES
#define FLOATING_SHADOW
#define SAMPLE_PERCENTAGE_CLOSER midgraph_poisson_shadow


float midgraph_poisson_shadow(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos);

#include "shadow_apply.fx"
#include "shadow_apply_poisson_registers.fxh"

float4 InnerLoop(int size, int outerIndex, float2 texel1, float2 sampleRot)
{
	float4 shadowTaps;
	
	for (int nTapInner = 0; nTapInner < size; nTapInner++)
	{
		float4 tapOffset = ps_midgraph_poisson_shadow_taps[outerIndex * 4 + nTapInner];

		// Perform rotation
		float2 rotated_tap = texel1;
		rotated_tap.x += dot(sampleRot.xy, tapOffset.xw);
		rotated_tap.y += dot(sampleRot.xy, tapOffset.yx);

		shadowTaps[nTapInner] = sample2DLOD(shadow, rotated_tap, 0, false).r;
	}
	
	return shadowTaps;
}

float midgraph_poisson_shadow(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos)
{
	// [mboulton 4/6/2010] : "Random screenspace rotation" Poisson disk
	float2 texel1 = fragment_shadow_position.xy;

	float4 poisson_pcf;

#if !defined(xenon) && (DX_VERSION == 9)
	fragment_shadow_position.xy = (fragment_shadow_position.xy * 480.0f);
	return 1;
#else
	fragment_shadow_position.xy += 0.5f;
#endif

	//float max_depth= fragment_shadow_position.z;
	float max_depth = fragment_shadow_position.z - ps_midgraph_poisson_shadow_info.y;		// [mboulton 1/9/2012] Additional bias for very large frustums

	// Rotation angle
	float angle = 3.14159f * frac(pixel_pos.x*123.456 + pixel_pos.y*321.321);
	float c = cos(angle);
	float s = sin(angle);
	float2 sampleRot = float2(c, s);

	// Take 12 samples in disc
	float cSampleAccum = 0.0f;
	float4 shadowTaps;
		
#if NUM_TAPS == 6
	// first four
	shadowTaps = InnerLoop(4, 0, texel1, sampleRot);
	cSampleAccum += dot(1.0/(float)NUM_TAPS, step(max_depth.xxxx, shadowTaps));
	
	// last two
	shadowTaps = InnerLoop(2, 1, texel1, sampleRot);
	cSampleAccum += dot(1.0/(float)NUM_TAPS, step(max_depth.xx, shadowTaps.xy));
	
#else
	for (int nTapOuter = 0; nTapOuter < (NUM_TAPS / 4); nTapOuter++)
	{
		shadowTaps = InnerLoop(4, nTapOuter, texel1, sampleRot);

		// Accumulate samples
		cSampleAccum += dot(1.0/(float)NUM_TAPS, step(max_depth.xxxx, shadowTaps));
	}
#endif

	return cSampleAccum;
}

/*
#define FASTER_SHADOWS
#define SHADOW_APPLY_JUST_USE_FETCH_RESULT
#define EXCLUDE_MODEL_MATRICES

#define SAMPLE_PERCENTAGE_CLOSER midgraph_poisson_shadow
float midgraph_poisson_shadow(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos);

sampler poisson_sampler : register(s3);
sampler random_rotation_sampler : register(s4);

float4  ps_midgraph_poisson_shadow_info: register(c229);
float4  ps_midgraph_poisson_shadow_taps[12] : register(c230);
float4	ps_midgraph_poisson_shadow_scale_offset : register(c231);

#include "shadow_apply.fx"



float midgraph_poisson_shadow(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos)
{
	const float2 PoissonLookup[12]=
	{
		float2(-0.326212f,-0.40581f),
		float2(-0.840144f,-0.07358f),
		float2(-0.695914f,0.457137f),
		float2(-0.203345f,0.620716f),
		float2(0.96234f,-0.194983f),
		float2(0.473434f,-0.480026f),
		float2(0.519456f,0.767022f),
		float2(0.185461f,-0.893124f),
		float2(0.507431f,0.064425f),
		float2(0.89642f,0.412458f),
		float2(-0.32194f,-0.932615f),
		float2(-0.791559f,-0.59771f)
	};

	// [mboulton 4/6/2010] : "Random screenspace rotation" Poisson disk
	float2 shadow_buffer_coord = fragment_shadow_position.xy;

	//float max_depth= depth_bias + fragment_shadow_position.z;
	float max_depth = depth_bias + fragment_shadow_position.z - ps_midgraph_poisson_shadow_info.y;		// [mboulton 1/9/2012] Additional bias for very large frustums

	// Rotation angle
	float2 rot = sample2D(random_rotation_sampler, transform_texcoord(pixel_pos, ps_midgraph_poisson_shadow_scale_offset));

	// Take 12 samples in disc
	float cSampleAccum = 0.0f;

	[unroll]
	for (int nTapOuter = 0; nTapOuter < 3; nTapOuter++)
	{
		float4 shadowTaps;

		for (int nTapInner = 0; nTapInner < 4; nTapInner++)
		{
			// Perform rotation
			float2 off;
			off.x = dot(rot.xy, PoissonLookup[nTapOuter * 4 + nTapInner].xy);
			off.y = dot(float2(-rot.y, rot.x), PoissonLookup[nTapOuter * 4 + nTapInner].xy);

			shadowTaps[nTapInner] = sample2DLOD(shadow, shadow_buffer_coord.xy + off, 0, false).r;
		}

		// Accumulate samples
		cSampleAccum += dot(1.0/12.0, step(max_depth.xxxx, shadowTaps));
	}

	return cSampleAccum;
}
*/
