#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(source_sampler, 0);
#include "next_texture.fxh"

#include "volumetric_light_shafts_registers.fxh"

DECLARE_SAMPLER(mask_map, "Mask Map", "Mask Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(shaft_intensity, "Shaft Intensity", "", 0, 1, float(1.4));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(masked_intensity, "Masked Intensity", "", 0, 1, float(0.5));
#include "used_float.fxh"

#define LIGHT_SHAFT_SCREEN_POS		ps_screen_sun_pos.xy
#define LIGHT_SHAFT_MAX_DISTANCE	ps_screen_sun_pos.z
#define LIGHT_SHAFT_SAMPLE_DENSITY	ps_screen_sun_pos.w
#define LIGHT_SHAFT_COLOR			ps_screen_sun_col.xyz
#define LIGHT_SHAFT_DECAY			ps_screen_sun_col.w

#define LIGHT_SHAFT_MAXIMUM_RANGE			ps_screen_maximum_range.x
#define LIGHT_SHAFT_MAXIMUM_RANGE_CLAMPED	ps_screen_maximum_range.y
#define LIGHT_SHAFT_MAXIMUM_CLAMP			64

#if DX_VERSION == 11
LOCAL_SAMPLER2D(depth_sampler, 2);
#endif

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, vs_near_mask_depth.x, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}


#ifdef xenon
float4 LightShaftNearMaskPS() : SV_Target
{
	return ps_scale;
}
#elif DX_VERSION == 11
float4 LightShaftNearMaskPS(in s_screen_vertex_output input) : SV_Target
{
	float4 result = 0;
	
	float4 depth = depth_sampler.t.Gather(depth_sampler.s, input.texcoord);
	bool4 mask = (depth < ps_scale.x);
	
	uint3 screen_coord = uint3(input.position.xy * 2, 0);
	
	[branch]
	if (mask.x)
	{
		result += source_sampler.t.Load(screen_coord);
	}
	[branch]
	if (mask.y)
	{
		result += source_sampler.t.Load(screen_coord, int2(1,0));
	}
	[branch]
	if (mask.z)
	{
		result += source_sampler.t.Load(screen_coord, int2(1,1));
	}
	[branch]
	if (mask.w)
	{
		result += source_sampler.t.Load(screen_coord, int2(0,1));
	}
		
	return result / 4;
}
#endif


float4 LightShaftRenderPS(const in s_screen_vertex_output input) : SV_Target
{
#if defined(xenon) || (DX_VERSION == 11)
	float2 curPixelPos = input.texcoord.xy * ps_pixel_size.zw;
	float2 curSunPos = LIGHT_SHAFT_SCREEN_POS * ps_pixel_size.zw;
	float2 sunDir = (curSunPos - curPixelPos);

	float scaleFactor = 1.0f;
	float angle = 0.5 + (atan2(sunDir.x, sunDir.y) / (6.283185307179586476925286766559));

	float2 noiseSample = sample2D(mask_map, transform_texcoord(float2(angle, 0.0), mask_map_transform));

	scaleFactor = lerp(masked_intensity, shaft_intensity, noiseSample.r);
	sunDir *= scaleFactor;

	// Clamp the maximum ray length
	float distanceFromCurPixelToSun = length(sunDir);
	float clippedDistanceFromCurPixelToSun = min(distanceFromCurPixelToSun, LIGHT_SHAFT_MAX_DISTANCE);

	int2 kNumRaySamples = (int2)(clippedDistanceFromCurPixelToSun / LIGHT_SHAFT_SAMPLE_DENSITY);
	kNumRaySamples = min(kNumRaySamples, int2(LIGHT_SHAFT_MAXIMUM_RANGE_CLAMPED, LIGHT_SHAFT_MAXIMUM_CLAMP));

	float distanceToSun = distanceFromCurPixelToSun;

	// Perform walk
	{
		float2 samplingDeltaVector = (sunDir/distanceFromCurPixelToSun) * clippedDistanceFromCurPixelToSun / (float)(kNumRaySamples.y);
		samplingDeltaVector *= ps_pixel_size.xy;


		float4 curPos1, curPos2;
		curPos1.xy = input.texcoord.xy;
		curPos1.zw = curPos1.xy + samplingDeltaVector;
		curPos2.xy = curPos1.zw + samplingDeltaVector;
		curPos2.zw = curPos2.xy + samplingDeltaVector;

		samplingDeltaVector *= 4;

		float illuminationDecay = 1.0f;
		float2 shaftIntensity = 0.0f;

		int i = 0;
		bool4 mask;
		do
		{
			// Fetch
			float4 sample;
#ifdef xenon			
			asm { tfetch2D sample.w___, curPos1.xy, source_sampler, MagFilter=linear, MinFilter=linear, AnisoFilter=disabled, UseComputedLOD = false };
			asm { tfetch2D sample._w__, curPos1.zw, source_sampler, MagFilter=linear, MinFilter=linear, AnisoFilter=disabled, UseComputedLOD = false };
			asm { tfetch2D sample.__w_, curPos2.xy, source_sampler, MagFilter=linear, MinFilter=linear, AnisoFilter=disabled, UseComputedLOD = false };
			asm { tfetch2D sample.___w, curPos2.zw, source_sampler, MagFilter=linear, MinFilter=linear, AnisoFilter=disabled, UseComputedLOD = false };
#else
			sample.x = sample2D(source_sampler, curPos1.xy).w;
			sample.y = sample2D(source_sampler, curPos1.zw).w;
			sample.z = sample2D(source_sampler, curPos2.xy).w;
			sample.w = sample2D(source_sampler, curPos2.zw).w;
#endif
			
			mask[0] = 1;
			mask[1] = (++i < kNumRaySamples.x && i < LIGHT_SHAFT_MAXIMUM_CLAMP);
			mask[2] = (++i < kNumRaySamples.x && i < LIGHT_SHAFT_MAXIMUM_CLAMP);
			mask[3] = (++i < kNumRaySamples.x && i < LIGHT_SHAFT_MAXIMUM_CLAMP);

			for (int j = 0; j < 4; ++j)
			{
				// Scale factor to reduce streaking from bright parts of frame buffer away from the sun
				float distanceScaleFactor = saturate( (LIGHT_SHAFT_MAX_DISTANCE - distanceToSun) * 0.01f );

				// Accumulate
				shaftIntensity += float2(sample[j], 1.0f) * mask[j] * illuminationDecay;

				// Decay and step
				illuminationDecay *= LIGHT_SHAFT_DECAY;
				distanceToSun -= clippedDistanceFromCurPixelToSun / (float)kNumRaySamples;
			}

			curPos1.xyzw += samplingDeltaVector.xyxy;
			curPos2.xyzw += samplingDeltaVector.xyxy;

		} while (++i < kNumRaySamples.x && i < LIGHT_SHAFT_MAXIMUM_CLAMP);

		return (shaftIntensity.x / shaftIntensity.y) * float4(LIGHT_SHAFT_COLOR, 1.0f);
	}
#else
	return 0.0f;
#endif
}


// extract pass
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(LightShaftNearMaskPS());
	}
}

// shaft pass
BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(LightShaftRenderPS());
	}
}
