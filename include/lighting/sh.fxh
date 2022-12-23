#if !defined(__SH_FXH)
#define __SH_FXH

#include "core/core.fxh"
#include "operations/color.fxh"

// [mboulton 4/22/2011] Perform quadratic clamped cosine convolution in specified direction

float3 PerformQuadraticSHCosineConvolution(
    const in float4 shCoefficients[8],
    const in float3 direction)
{
    float4 n = float4(direction, 1.0f);
    float3 x1, x2, x3;

    x1.r = dot(shCoefficients[0], n);
    x1.g = dot(shCoefficients[1], n);
    x1.b = dot(shCoefficients[2], n);

    float4 vB = n.xyzz * n.yzzx;
    x2.r = dot(shCoefficients[3], vB);
    x2.g = dot(shCoefficients[4], vB);
    x2.b = dot(shCoefficients[5], vB);

    float vC = n.x * n.x - n.y * n.y;
    x3 = shCoefficients[6].rgb * vC;

    float3 irradiance = x1 + x2 + x3;

	return irradiance;
}

float WrappedCosine(float3 dir1, float3 dir2)
{
	return saturate((dot(dir1, dir2) + 0.5f)/1.5f);
}

// [adamgold 2/1/12] Calculate and return the lighting from the quadratic SH, modulated by SSAO and/or visibility, and use confidence (as energy).
// We're okay with double-lighting on the ground, so we took out the clamped cosine factor.
// [adamgold 2/9/12] Took out confidence here, because we can do it on the CPU
float3 CompSH(
            const in s_common_shader_data common,
            const in float3 vmf_lighting,
            const in float3 normal)
{

    float3 diffuse = vmf_lighting;

#if !defined(DISABLE_SH)

	// Only add SH if we are rendering probe based assets like characters, crates, weapons, et cetera
	if (common.lighting_mode == LM_PROBE || common.lighting_mode == LM_PROBE_AO || common.lighting_mode == LM_PER_PIXEL_FORGE ||
		(common.lighting_mode == LM_OBJECT && !ps_boolean_using_static_lightmap_only))
	{	
		float darkeningFactor = 1.0f; // common.lighting_data.shadow_mask.b; // SSAO
				
		if (common.lighting_mode == LM_OBJECT || common.lighting_mode == LM_PROBE_AO || common.lighting_mode == LM_PER_PIXEL_FORGE)
		{
			// For objects with static lightmaps, we comp with a visibility term
			darkeningFactor *= common.lighting_data.visibility;
		}
	
		// Compute the SH, modulated by the SSAO value
		float3 sh = PerformQuadraticSHCosineConvolution(ps_model_sh_lighting, normal) * darkeningFactor;
		
		// Forge "indoor lighting"
		if (common.lighting_mode == LM_PER_PIXEL_FORGE)
		{
#if defined(FORGE_ISLAND)
			sh = max(0.5, sh);
#else
			sh = max(ps_forge_lightmap_compress_constant.z, sh);
#endif
		}
	
		// lerp
		diffuse = sh + diffuse;
	}

#endif

	return diffuse;
}


float3 ConvertRGBToCIExyz(float3 rgb)
{
	float3 xyz;

	float3 hdrColor = rgb;
	float X, Y, Z;
	X = hdrColor.x * 0.412453f + hdrColor.y * 0.357580f + hdrColor.z * 0.180423f;
	Z = hdrColor.x * 0.019334f + hdrColor.y * 0.119193f + hdrColor.z * 0.950227f;
	Y = hdrColor.x * 0.212671f + hdrColor.y * 0.715160f + hdrColor.z * 0.072169f;

	float denominator = X + Y + Z;

	if (denominator != 0.0f)
	{
		xyz.x = X / denominator;
		xyz.y = Y / denominator;
		xyz.z = Z / denominator;
	}
	else
	{
		xyz = 0;
	}

	return xyz;
}

float3 ConvertCIEXYZToRGB(float X, float Y, float Z)
{
	float3 rgb;
	rgb.r = max(0.0f, X * 3.240479f + Y * (-1.537150f) + Z * (-0.498535f));
	rgb.g = max(0.0f, X * (-0.969256f) + Y * 1.875992f + Z * 0.041556f);
	rgb.b = max(0.0f, X * 0.055648f + Y * (-0.204043f) + Z * 1.057311f);
	return rgb;
}

float LinearSHClampedCosineConvolution(float4 linearSH, float3 normal, float3 geoNormal, uniform bool notProbe)
{
#if (!defined(xenon) && (DX_VERSION == 9))
	return 0;
#else
	const float sqrtPi = 1.7724538509055160272981674833411f;
	const float sqrt3 = 1.7320508075688772935274463415059f;
	const float fC0 = 1.0f / (2.0f * sqrtPi);
	const float fC1 = sqrt3 / (3.0f * sqrtPi);

#if defined(DISABLE_SHARPEN_FALLOFF)
	float factor = dot(linearSH, float4(fC1 * normal, fC0));
	return saturate(factor);
#endif

	if (!notProbe)
	{
		// if sharpening, we have already redistributed all but 20% of the energy in the DC term into the linear
		// to provide sharpened normal response, otherwise the objects will be too "flat" often
		// otherwise, a value of 1.0 in ps_model_sh_lighting[7].w indicates we must add linear sh

		// convolution
		float factor = dot(linearSH, float4(fC1 * normal, fC0)) * ps_model_sh_lighting[7].w;
		return saturate(factor);
	}
	else
	{
		float factor = dot(linearSH, float4(fC1 * normal, fC0));

#if defined(DEBUG)
		if (ps_bsp_boolean_enable_sharpened_falloff)
#endif
		{
			float geometricFactor = dot(linearSH, float4(fC1 * geoNormal, fC0));
			return sample2D(ps_lightmap_sharpen_falloff, float2(factor, geometricFactor));
		}
#if defined(DEBUG)
		else
		{
			float geometricFactor = dot(linearSH, float4(fC1 * geoNormal, fC0));

			const float power = ps_bsp_lightmap_compress_constant_2.x;

			[flatten]
			if (factor > geometricFactor)
			{
				float f = (factor - geometricFactor) / (1.0f - geometricFactor);
				f = pow(f, power);
				factor = f * (1.0f - geometricFactor) + geometricFactor;
			}
			else
			{
				float f = (geometricFactor - factor) / geometricFactor;
				f = pow(f, power);
				factor = geometricFactor - f * geometricFactor;
			}

			return saturate(factor);
		}
#endif
	}
#endif
}

float3 LinearSHIrradianceScalar(float3 normal, float4 linearSH, float3 rgb, float3 geoNormal, bool allowSharpen)
{
	return rgb * LinearSHClampedCosineConvolution(linearSH, normal, geoNormal, allowSharpen);
}

float LinearSHIrradianceScalarRegular(float3 normal, float4 linearSH)
{
	const float sqrtPi = 1.7724538509055160272981674833411f;
	const float sqrt3 = 1.7320508075688772935274463415059f;
	const float fC0 = 1.0f / (2.0f * sqrtPi);
	const float fC1 = sqrt3 / (3.0f * sqrtPi);

	return dot(linearSH, float4(fC1 * normal, fC0));
}

#endif  // !defined(__VMF_FXH)

