#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "engine/engine_parameters.fxh"

#define ATMOSPHERE_TABLE_GENERATION

#include "atmosphere/atmosphere.fxh"
#include "screen_atmospheric_fog_registers.fxh"

LOCAL_SAMPLER2D(ps_depth_sampler,			1);
LOCAL_SAMPLER2D(ps_color_sampler,			2);
LOCAL_SAMPLER2D(ps_atmosphere_fog_table,	3);
LOCAL_SAMPLER2D(ps_atmosphere_fog_mask,		4);


float4 AtmosphericFogTexVS(const in s_screen_vertex input, out float2 fogTableCoordinates : TEXCOORD0) : SV_Position
{
	const float2 corner = input.position.xy;

	const float s_fogTableResolution = 256;
	fogTableCoordinates = corner * 0.5f + 0.5f;
	fogTableCoordinates = (fogTableCoordinates * (s_fogTableResolution - 1) / s_fogTableResolution) + 0.5f / s_fogTableResolution;
	fogTableCoordinates.y = 1.0 - fogTableCoordinates.y;

	return float4(corner, 0.0, 1.0);
}

float4 AtmosphericFogApplyVS(const in s_screen_vertex input, out float4 screenTexCoords : TEXCOORD0) : SV_Position
{
	screenTexCoords.xy = input.texcoord;
	screenTexCoords.zw = input.position.xy;

	return float4(input.position.xy, vs_near_fog_projected_depth.x, 1.0);
}

float4 AtmosphericFogVS(const in s_screen_vertex input) : SV_Position
{
	float2 fogTableCoordinates;
	return AtmosphericFogTexVS(input, fogTableCoordinates);
}


float3 GetPixelWorldPosition(in float4 fragment_pixel_position)
{
	float depth = 0;
#if defined(xenon)
	asm
	{
		tfetch2D depth.x___, fragment_pixel_position.xy, ps_depth_sampler, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, OffsetX=0.5, OffsetY=0.5, UnnormalizedTextureCoords= false, UseComputedLOD=false
	};
#else
	depth = ps_depth_sampler.t.Sample(ps_depth_sampler.s, fragment_pixel_position.xy);
#endif

	float4 worldPosition = float4(fragment_pixel_position.zw, depth, 1.0f);
	worldPosition = mul(worldPosition, transpose(ps_view_transform_inverse));

	return worldPosition.xyz / worldPosition.w;
}



float4 GenerateAtmosphericFogTablePS(
	in float4 screenPosition : SV_Position,
	in float2 fogTableCoordinates : TEXCOORD0,
	uniform bool blendFunctions,
	uniform bool mixedFog) : SV_Target
{
#if defined(xenon) || (DX_VERSION == 11)
	float viewPositionZ = ps_camera_position.z;
	float worldPositionZ = GetLUTDepthValue(fogTableCoordinates.y);
	float viewDistance = fogTableCoordinates.x * fogTableCoordinates.x * MAX_VIEW_DISTANCE;

	// calculate scattering
	float3 inscatter;
	float extinction;

	if (mixedFog)
	{
		compute_scattering_mixed(
			viewPositionZ,
			worldPositionZ,
			viewDistance,
			blendFunctions,
			inscatter,
			extinction);
	}
	else
	{
		compute_scattering_separate(
			viewPositionZ,
			worldPositionZ,
			viewDistance,
			blendFunctions,
			inscatter,
			extinction);
	}

	float4 ret = float4(sqrt(inscatter), extinction);
#if DX_VERSION == 11
	ret = saturate(ret);
#endif	
	return ret;
#else
	return float4(0,0,0,1);
#endif
}



float4 CalculateAtmosphericFogPS(
	in float4 screenPosition : SV_Position,
	in float4 texCoord : TEXCOORD0,
	uniform bool fogLighting) : SV_Target
{
#if defined(xenon) || (DX_VERSION == 11)
	float3 worldPosition = GetPixelWorldPosition(texCoord);
	float3 viewVector = worldPosition - ps_camera_position;

	float3 inscatter;
	float extinction;
	float desaturation;
	ComputeAtmosphericScattering(
		ps_atmosphere_fog_table,
		viewVector,
		worldPosition,
		inscatter,
		extinction,
		desaturation,
		fogLighting,
		true);

	return float4(inscatter, extinction) * ps_view_exposure.xxxw;
#else
	return float4(0,0,0,1);
#endif
}



#define FOG_TABLE_GENERATE(blendFunctions, mixedFog)								\
BEGIN_TECHNIQUE																			\
{																					\
	pass screen																		\
	{																				\
		SET_VERTEX_SHADER(AtmosphericFogTexVS());						\
		SET_PIXEL_SHADER(GenerateAtmosphericFogTablePS(blendFunctions, mixedFog));	\
	}																				\
}

#define FOG_TABLE_APPLY(lightFog)													\
BEGIN_TECHNIQUE																			\
{																					\
	pass screen																		\
	{																				\
		SET_VERTEX_SHADER(AtmosphericFogApplyVS());						\
		SET_PIXEL_SHADER(CalculateAtmosphericFogPS(lightFog));			\
	}																				\
}


// fog table generate
FOG_TABLE_GENERATE(false, true)			// no function blend, mixed fog
FOG_TABLE_GENERATE(false, false)		// no function blend, separate fog
FOG_TABLE_GENERATE(true, true)			// blend functions, mixed fog
FOG_TABLE_GENERATE(true, false)			// blend functions, separate fog


// fog apply
FOG_TABLE_APPLY(false)					// use table, no fog lighting
FOG_TABLE_APPLY(true)					// use table, with fog lighting
