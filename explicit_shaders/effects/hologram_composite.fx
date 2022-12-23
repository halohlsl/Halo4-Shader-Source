#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "../postprocess/final_composite_functions.fxh"

LOCAL_SAMPLER2D(source_sampler, 0);
#include "next_texture.fxh"

LOCAL_SAMPLER2D(layer_sum_sampler, 1);
#include "next_texture.fxh"

#if DX_VERSION == 11
texture2D<uint2> stencil_texture : register(t1);
#endif

// Intensity scale for composite
DECLARE_FLOAT_WITH_DEFAULT(hologram_intensity, "Hologram Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Remapping parameters for composite range
DECLARE_FLOAT_WITH_DEFAULT(hologram_alpha, "Hologram Alpha", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Source alpha intensity
DECLARE_FLOAT_WITH_DEFAULT(alpha_premultiply_intensity, "Alpha Premultiply Intensity", "", 0, 1, float(0.0));
#include "used_float.fxh"

#define ps_depth_sampler layer_sum_sampler

struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen_tex default_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

float4 hologram_composite_ps(const in s_vertex_output_screen_tex input) : SV_Target
{
	float2 texcoord = input.texcoord;
	float4 source;
#if defined(xenon)
	asm
	{
		tfetch2D source, texcoord, source_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, UseComputedLOD=false
	};
#else
	source = sample2DLOD(source_sampler, texcoord, 0, false);
#endif

	source.rgb = InverseFilmicToneCurve(source.rgb);

	source.a = saturate(float_remap(source.a, 12.0f / 255.0f, 1.0f, 0.0, hologram_alpha));
	source.rgb *= lerp(hologram_intensity, hologram_intensity * source.a, alpha_premultiply_intensity);

	return ApplyExposureSelfIllum(source, 1.0f, false);
}

// This shader uses the accumulation of the layers of transparency and calculates the alpha blend
// factor using the assumption that layers will have a somewhat common average alpha value.  The
// accumulated layes have their alpha already premultiplied.  Stencil buffer has layer count.
float4 weighted_average_alpha_ps(const in s_vertex_output_screen_tex input) : SV_Target
{
#if DX_VERSION == 9
	float layerCount = floor(sample2DLOD(layer_sum_sampler, input.texcoord, 0, false).b * 255.0 + 0.5);	
#elif defined(durango)
	// G8 SRVs are broken on Durango - components are swapped
	float layerCount = stencil_texture.Load(int3(input.position.xy, 0)).x;
#elif DX_VERSION == 11
	float layerCount = stencil_texture.Load(int3(input.position.xy, 0)).y;
#endif

	// Slight hack to force blended layers to have more influence than solid pixels. This weights
	// the average color toward the blend layers, reducing the background color importance.
	layerCount = max(0, (layerCount - 1) * 4 + 1);

	float4 source = sample2DLOD(source_sampler, input.texcoord, 0, false) *3.0;
	source.a /= 1.0 + 1.0/256.0;

	float3 averageColor = source.rgb / source.a;
	float averageAlpha = source.a / layerCount;

	float blendFactor = pow(max(0, 1.0 - averageAlpha), layerCount);

	return float4(averageColor * (1.0f - blendFactor), 1 - blendFactor);
}



struct HologramCompositeOutputDOF
{
	float4 outColor : SV_Target0;
	float1 outDepth : SV_Depth0;
};


HologramCompositeOutputDOF hologram_composite_dof_ps(const in s_vertex_output_screen_tex input)
{
	float2 texcoord = input.texcoord;
	float4 source;
#if defined(xenon)
	asm
	{
		tfetch2D source, texcoord, source_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, UseComputedLOD=false
	};
#else
	source = sample2DLOD(source_sampler, texcoord, 0, false);
#endif

	const float minAlpha = 12.0 / 255.0;
	const float maxAlpha = 160.0 / 255.0;
	const float remapExponent = 8.0;

	float depthAdjustmentIntensity = source.a + color_luminance(source.rgb);
	float minThreshold = depthAdjustmentIntensity - 1.0 / 224.0f;
	clip(minThreshold);

	HologramCompositeOutputDOF output = (HologramCompositeOutputDOF)0;

	[predicateBlock]
	if (minThreshold > 0.0)
	{
		depthAdjustmentIntensity = saturate((depthAdjustmentIntensity - minAlpha) / (maxAlpha - minAlpha));
		depthAdjustmentIntensity = pow(depthAdjustmentIntensity, remapExponent);

		float depth;
#if defined(xenon)
		asm
		{
			tfetch2D depth.x___, texcoord, ps_depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, UseComputedLOD=false
		};
#else
		depth = sample2DLOD(ps_depth_sampler, input.texcoord, 0, false).r;
#endif

		output.outColor = hologram_composite_ps(input);
		output.outDepth = max(depth, lerp(depth, ps_scale.a, depthAdjustmentIntensity));
	}

	return output;
}

BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(hologram_composite_ps());
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(weighted_average_alpha_ps());
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(hologram_composite_dof_ps());
	}
}



