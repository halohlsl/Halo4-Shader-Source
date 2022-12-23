#if !defined(__ATMOSPHERE_FXH)
#define __ATMOSPHERE_FXH

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "atmosphere/atmosphere_calculate.fxh"

#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_ATMOSPHERICS)

float2 GetAtmosphericFogTableCoords(
	in float3 viewVector,
	in float3 worldPosition)
{
	float2 fogTableCoords;

	float viewOffsetZ = abs(viewVector.z) + FOG_DELTA;
	float worldOffsetZToLUT = abs(PIN_LUT(worldPosition.z) - LUT_clamped_view_z) + FOG_DELTA;

#if 1
	fogTableCoords.x = ONE_OVER_MAX_VIEW_DISTANCE * worldOffsetZToLUT / (viewOffsetZ / length(viewVector));
	fogTableCoords.x = sqrt(fogTableCoords.x);
#else
	fogTableCoords.x = (MAX_VIEW_DISTANCE * viewOffsetZ) / length(viewVector) * worldOffsetZToLUT;
	fogTableCoords.x = sqrt(1.0f / fogTableCoords.x);
#endif

	float worldOffsetZToLUTFloor = max(worldPosition.z - LUT_Z_FLOOR, FOG_DELTA);
	fogTableCoords.y = (worldOffsetZToLUTFloor + LUT_log_one_over_coeff_b) * LUT_exp2_neg_coeff_a;

	return fogTableCoords;
}



float compute_extinction(
		const float thickness,
		const float dist)
{
	// 7 ALU, hard to be parallalized
	return saturate(exp( -thickness * dist));			// ###XWAN $TODO $PERF use exp2 instead
}

float3 fog_light_color(
	in float3 view_direction,
	in float3 light_direction,
	in float light_radius_scale,
	in float light_radius_offset,
	in float light_falloff_steepness,
	in float3 light_color)
{
	float cosine=		dot(view_direction, light_direction);
	float ratio=		saturate( cosine * light_radius_scale + light_radius_offset );
	return light_color * pow(ratio, light_falloff_steepness);
}

float3 apply_desaturation(
	in float3 rgb,
	in float desaturation)
{
	const float monochrome= dot(rgb, float3(0.2989, 0.5870f, 0.1140f));
	return lerp(rgb, monochrome, desaturation);
}

float4 SampleAtmosphericFogTable(
	in texture_sampler_2d atmosphericFogTableSampler,
	in float3 viewVector,
	in float3 worldPosition,
	uniform bool fogLightsEnabled,
	uniform bool forceAtmosphereFogEnable)
{
	float4 scatterParameters = float4(0, 0, 0, 1);

	[branch]
	if (forceAtmosphereFogEnable || s_atmosphere_fog_enable)
	{
		float2 fogLUTCoords = GetAtmosphericFogTableCoords(viewVector, worldPosition);

#if defined(xenon)
		asm
		{
			tfetch2D scatterParameters, fogLUTCoords, atmosphericFogTableSampler, MagFilter=linear, MinFilter=linear, MipFilter=point, AnisoFilter=disabled, UnnormalizedTextureCoords= false, UseComputedLOD=false, UseRegisterLOD=false
		};
#else
		scatterParameters = atmosphericFogTableSampler.t.SampleLevel(atmosphericFogTableSampler.s, fogLUTCoords, 0);
#endif

		// The fog table inscatter is stored with a gamma 2.0 curve
		scatterParameters.rgb *= scatterParameters.rgb;

		if (fogLightsEnabled || s_atmosphere_fog_light_enable)
		{
			float3 viewDirection = normalize(viewVector);

			float fog_distance_scale;
			fog_distance_scale = saturate(scatterParameters.a * _fog_light_1_nearby_cutoff + 1.0);

			float fog_angular_scale;
			float cosine =		dot(viewDirection, _fog_light_1_direction);
			fog_angular_scale =	saturate( cosine * _fog_light_1_radius_scale + _fog_light_1_radius_offset );

#if DX_VERSION == 11
			// avoid NaNs from log2
			fog_angular_scale = max(fog_angular_scale, 0.0000001);
			fog_distance_scale = max(fog_distance_scale, 0.0000001);
#endif
			
			float fog_light_scale = exp2(log2(fog_distance_scale) * _fog_light_1_distance_falloff + log2(fog_angular_scale) * _fog_light_1_angular_falloff);

			scatterParameters.rgb += fog_light_scale * _fog_light_1_color;
		}
	}

	return scatterParameters;
}

void ComputeAtmosphericScattering(
	texture_sampler_2d atmosphericFogTableSampler,
	in float3 viewVector,
	in float3 worldPosition,
	inout float3 inscatter,
	inout float extinction,
	inout float desaturation,
	uniform bool calculateFogLight,
	uniform bool forceAtmosphereFogEnable)
{
	float4 scatterParameters = SampleAtmosphericFogTable(
		atmosphericFogTableSampler,
		viewVector,
		worldPosition,
		calculateFogLight,
		forceAtmosphereFogEnable);

	inscatter = scatterParameters.rgb;
	extinction = scatterParameters.a;

	desaturation = 0.0f;
}

float4 ApplyAtmosphericScattering(
	in float4 color,
	in const float3 inscatter,
	in const float extinction)
{
	color.rgb = color * extinction + inscatter;

	return color;
}

float4 ApplyAtmosphericScatteringDesaturation(
	in float4 color,
	in const float3 inscatter,
	in const float extinction,
	in const float desaturation)
{
	// Desaturate the color first
	color.rgb = DesaturateLinearColor(color.rgb, desaturation);

	return ApplyAtmosphericScattering(color, inscatter, extinction);
}



#else

void ComputeAtmosphericScattering(
	texture_sampler_2d atmosphericFogTableSampler,
	in float3 viewVector,
	in float3 worldPosition,
	inout float3 inscatter,
	inout float extinction,
	inout float desaturation,
	uniform bool calculateFogLight,
	uniform bool forceAtmosphereFogEnable)
{
	inscatter = 0.0f;
	extinction = 1.0f;
	desaturation = 0.0f;
}

float4 ApplyAtmosphericScattering(
	in float4 color,
	in const float3 inscatter,
	in const float extinction)
{
	return color;
}
#endif

#endif // __ATMOSPHERE_CORE_FX_H__