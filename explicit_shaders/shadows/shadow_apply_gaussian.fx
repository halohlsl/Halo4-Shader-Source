#define FASTER_SHADOWS

#define SAMPLE_PERCENTAGE_CLOSER midgraph_PCF_gaussian
float midgraph_PCF_gaussian(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos);

#include "shadow_apply.fx"

float midgraph_PCF_gaussian(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos)
{
	float2 texel1 = fragment_shadow_position.xy;

	float4 gaussian_coefficients;

#ifdef pc
	fragment_shadow_position.xy = (fragment_shadow_position.xy * 480.0f);
	gaussian_coefficients.xy = fragment_shadow_position.xy - floor(fragment_shadow_position.xy);
#else
#ifndef VERTEX_SHADER
	fragment_shadow_position.xy += 0.5f;
	asm {
		getWeights2D gaussian_coefficients.xy, fragment_shadow_position.xy, shadow, MagFilter=linear, MinFilter=linear
	};
#endif
#endif
	gaussian_coefficients.zw = 1.0f - gaussian_coefficients.xy;

#define offset_0 -1.5f
#define offset_1 -0.5f
#define offset_2 +0.5f
#define offset_3 +1.5f

	// gaussian distribution function
	float d0 = 0.391042694; // e^(-0.2*0.2/(2*1*1))/(sqrt(2*pi)*1*1)
	float d1 = 0.396952547; // e^(-0.1*0.1/(2*1*1))/(sqrt(2*pi)*1*1)
	float d2 = 0.396952547; // e^(-0.1*0.1/(2*1*1))/(sqrt(2*pi)*1*1)
	float d3 = 0.391042694; // e^(-0.2*0.2/(2*1*1))/(sqrt(2*pi)*1*1)

	float3 max_depth = depth_bias;
	max_depth *= float3(-2.0, -sqrt(5.0f), -4.0f);
	max_depth += fragment_shadow_position.z;
	
	float color =	d0 * d0 * gaussian_coefficients.z * gaussian_coefficients.w * step(max_depth[2], Sample2DOffsetPoint(shadow, texel1, offset_0, offset_0).r) + 
					d1 * d0 * 1.0f    * gaussian_coefficients.w * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_1, offset_0).r) +
					d2 * d0 * 1.0f    * gaussian_coefficients.w * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_2, offset_0).r) +
					d3 * d0 * gaussian_coefficients.x * gaussian_coefficients.w * step(max_depth[2], Sample2DOffsetPoint(shadow, texel1, offset_3, offset_0).r) +
					d0 * d1 * gaussian_coefficients.z * 1.0f    * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_0, offset_1).r) +
					d1 * d1 * 1.0f    * 1.0f    * step(max_depth[0], Sample2DOffsetPoint(shadow, texel1, offset_1, offset_1).r) +
					d2 * d1 * 1.0f    * 1.0f    * step(max_depth[0], Sample2DOffsetPoint(shadow, texel1, offset_2, offset_1).r) +
					d3 * d1 * gaussian_coefficients.x * 1.0f    * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_3, offset_1).r) +
					d0 * d2 * gaussian_coefficients.z * 1.0f    * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_0, offset_2).r) +
					d1 * d2 * 1.0f    * 1.0f    * step(max_depth[0], Sample2DOffsetPoint(shadow, texel1, offset_1, offset_2).r) +
					d2 * d2 * 1.0f    * 1.0f    * step(max_depth[0], Sample2DOffsetPoint(shadow, texel1, offset_2, offset_2).r) +
					d3 * d2 * gaussian_coefficients.x * 1.0f    * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_3, offset_2).r) +
					d0 * d3 * gaussian_coefficients.z * gaussian_coefficients.y * step(max_depth[2], Sample2DOffsetPoint(shadow, texel1, offset_0, offset_3).r) +
					d1 * d3 * 1.0f    * gaussian_coefficients.y * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_1, offset_3).r) +
					d2 * d3 * 1.0f    * gaussian_coefficients.y * step(max_depth[1], Sample2DOffsetPoint(shadow, texel1, offset_2, offset_3).r) +
					d3 * d3 * gaussian_coefficients.x * gaussian_coefficients.y * step(max_depth[2], Sample2DOffsetPoint(shadow, texel1, offset_3, offset_3).r);
					
	return color;
}