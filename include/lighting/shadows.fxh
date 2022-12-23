#if !defined(__SHADOWS_FXH)
#define __SHADOWS_FXH

#include "core/core.fxh"

#if defined(xenon) || (DX_VERSION == 11)
#include "postprocessing/postprocess_textures.fxh"
#endif

#include "../explicit_shaders/shadows/shadow_apply_poisson_registers.fxh"

void generate_shadow_mask(
	inout s_common_shader_data common,
	in s_platform_pixel_input platformInput,
#if DX_VERSION == 9
	sampler shadowMask
#elif DX_VERSION == 11
	texture2D<float4> shadowMask
#endif
)
{
#if defined(xenon)
	float2 screen_texcoord= platformInput.fragment_position.xy;
	float4 shadow_mask;
	asm
	{
		tfetch2D shadow_mask, screen_texcoord, shadowMask, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords = true, UseComputedLOD = false
	};
	common.lighting_data.shadow_mask= shadow_mask;
#elif DX_VERSION == 11
	int3 screen_texcoord = int3(platformInput.fragment_position.xy, 0);
	common.lighting_data.shadow_mask = shadowMask.Load(screen_texcoord);
#endif // xenon
}

float midgraph_poisson_shadow_8tap(float3 fragment_shadow_position, float2 pixel_pos)
{
	float2 texel1 = fragment_shadow_position.xy;
	float max_depth = fragment_shadow_position.z;

	// Rotation angle
	float angle = 3.14159f * frac(pixel_pos.x*123.456 + pixel_pos.y*321.321);
	float c = cos(angle);
	float s = sin(angle);

	// Take 8 samples in disc
	float cSampleAccum = 0.0f;
	float2 sampleRot = float2(c, s);

	for (int nTapIndex = 0; nTapIndex < 8; nTapIndex++)
	{
		float4 tapOffset = ps_midgraph_poisson_shadow_taps[nTapIndex];

		// Perform rotation
		float2 rotated_tap;
		rotated_tap.x = dot(sampleRot.xy, tapOffset.xw) + texel1.x;
		rotated_tap.y = dot(sampleRot.yx, tapOffset.xy) + texel1.y;

		// Accumulate samples
		cSampleAccum += step(max_depth, sample2DLOD(ps_shadow_depth_map, rotated_tap, 0, false).r) / 8;
	}

	return cSampleAccum;
}

float sample_percentage_closer_PCF_5x5_block_predicated(float3 fragment_shadow_position, float depth_bias)
{
#if !defined(xenon) && (DX_VERSION != 11)
	return 1.0f;
#else

	float2 texel1= fragment_shadow_position.xy;

	float4 blend;
#if defined(pc) && (DX_VERSION == 9)
	fragment_shadow_position.xy= (fragment_shadow_position.xy * 480.0f);
	blend.xy= fragment_shadow_position.xy - floor(fragment_shadow_position.xy);			// bilinear-sampled filter
#elif (DX_VERSION == 11)
	float depth_map_width, depth_map_height;
	ps_shadow_depth_map.t.GetDimensions(depth_map_width, depth_map_height);
	blend.xy = frac((fragment_shadow_position.xy * float2(depth_map_width, depth_map_height)) + 0.5f);
#else
	asm
	{
		getWeights2D blend.xy, fragment_shadow_position.xy, ps_shadow_depth_map, MagFilter=linear, MinFilter=linear
	};
#endif
	blend.zw = 1.0f - blend.xy;

#define offset_0 -1.5f
#define offset_1 -0.5f
#define offset_2 +0.5f
#define offset_3 +1.5f

	float3 max_depth= depth_bias;							// x= central samples,   y = adjacent sample,   z= diagonal sample
	max_depth *= float3(-2.0f, -sqrt(5.0f), -4.0f);			// make sure the comparison depth is taken from the very corner of the samples (maximum possible distance from our central point)
	max_depth += fragment_shadow_position.z;

	// 4x4 point and 3x3 bilinear
	float color=	blend.z * blend.w * step(max_depth.z, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_0, offset_0).r) +
					1.0f    * blend.w * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_1, offset_0).r) +
					1.0f    * blend.w * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_2, offset_0).r) +
					blend.x * blend.w * step(max_depth.z, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_3, offset_0).r) +
					blend.z * 1.0f    * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_0, offset_1).r) +
					1.0f    * 1.0f    * step(max_depth.x, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_1, offset_1).r) +
					1.0f    * 1.0f    * step(max_depth.x, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_2, offset_1).r) +
					blend.x * 1.0f    * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_3, offset_1).r) +
					blend.z * 1.0f    * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_0, offset_2).r) +
					1.0f    * 1.0f    * step(max_depth.x, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_1, offset_2).r) +
					1.0f    * 1.0f    * step(max_depth.x, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_2, offset_2).r) +
					blend.x * 1.0f    * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_3, offset_2).r) +
					blend.z * blend.y * step(max_depth.z, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_0, offset_3).r) +
					1.0f    * blend.y * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_1, offset_3).r) +
					1.0f    * blend.y * step(max_depth.y, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_2, offset_3).r) +
					blend.x * blend.y * step(max_depth.z, Sample2DOffsetPoint(ps_shadow_depth_map, texel1, offset_3, offset_3).r);

	color /= 9.0f;

	return color;
#endif
}


#endif 	// !defined(__LIGHTING_FXH)