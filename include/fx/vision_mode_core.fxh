#if !defined(__VISION_MODE_CORE_FXH)
#define __VISION_MODE_CORE_FXH

#include "vision_mode_core_registers.fxh"

DECLARE_SAMPLER(plasmaMapA, "Plasma Map A", "Plasma Map A", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(plasmaMapB, "Plasma Map B", "Plasma Map B", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(plasma_strength, "Plasma Strength", "", 0, 1, .25);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(plasma_edge_strength, "Plasma Edge Strength", "", 0, 1, .25);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(plasma_threshold, "Plasma Threshold", "", 0, 1, .25);
#include "used_float.fxh"

#if defined(pc) && (DX_VERSION == 9)
	void sampleDepth(in float2 uv, inout float depth)
	{
 		depth = sample2D(depthSampler, uv).x;	
	}
	void sampleFramebuffer(in float2 uv, inout float3 color, inout float depth)
	{
 		color = sample2D(framebufferSampler, uv).xyz;
 		depth = sample2D(depthSampler, uv).x;
	}
	void ApplyPlasmaWarping(inout float2 pixelCoordinate, out float plasmaValue, out float plasmaEdgeValue)
	{
		plasmaValue = plasmaEdgeValue = 1;
	}
#else
	// do NOT use VPOS, it forces 3 interpolants, and we can get away with 2
	// single target restore runs at nearly full rate of 2 quads/clock
	// VPOS forces halfrate and will make this interpolant bound.
	void sampleDepth(in float2 uv, inout float depth)
	{
		float4 s;
#ifdef xenon	
		asm
		{
			tfetch2D s, uv, depthSampler, UnnormalizedTextureCoords=true
		};
#else
		s = depthSampler.t.Load(uint3(uv, 0));
#endif
		// convert to real depth
		depth = 1.0f - s.x;
		depth = 1.0f / (psDepthConstants.x + depth * psDepthConstants.y);	
	}
	void sampleFramebuffer(in float2 uv, inout float3 color, inout float depth)
	{
		float4 s;
#ifdef xenon
		asm
		{
			tfetch2D s, uv, framebufferSampler, UnnormalizedTextureCoords=true
		};
#else
		s = sample2D(framebufferSampler, uv * ps_pixel_size);
#endif		
		color = s.xyz;

		sampleDepth(uv, depth);
	}
	
	void ApplyPlasmaWarping(inout float2 pixelCoordinate, out float plasmaValue, out float plasmaEdgeValue)
	{
		float4 sA, sB;
		float2 uvA = transform_texcoord(pixelCoordinate, plasmaMapA_transform);
		float2 uvB = transform_texcoord(pixelCoordinate, plasmaMapB_transform);
#ifdef xenon		
		asm
		{
			tfetch2D sA, uvA, plasmaMapA
			tfetch2D sB, uvB, plasmaMapB
		};
#else
		sA = sample2D(plasmaMapA, uvA);
		sB = sample2D(plasmaMapB, uvB);
#endif		
		float plasmaA = sA.x;
		float plasmaB = sB.x;
		
		plasmaValue = saturate(abs(plasmaA - plasmaB) - plasma_threshold) / (1 - plasma_threshold);
		plasmaEdgeValue = saturate(plasmaValue * plasma_edge_strength);
		plasmaValue = saturate(1 - plasmaValue * plasma_strength);
		
		pixelCoordinate = pixelCoordinate * ps_pixel_size - float2(0.5, 0.5);
		pixelCoordinate -= pixelCoordinate * (1 - plasmaValue);
		pixelCoordinate = (pixelCoordinate + float2(0.5, 0.5)) / ps_pixel_size;
	}
#endif

#endif 	// !defined(__VISION_MODE_CORE_FXH)