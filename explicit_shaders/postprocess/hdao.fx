#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "hdao_registers.fxh"
#include "ssao_local_depth_registers.fxh"

#define SCREENSHOT_RADIUS_X		(ps_pixel_size.z)
#define SCREENSHOT_RADIUS_Y		(ps_pixel_size.w)
#define CORNER_SCALE	(corner_params.x)
#define CORNER_OFFSET	(corner_params.y)
#define BOUNDS_SCALE	(bounds_params.x)
#define BOUNDS_OFFSET	(bounds_params.y)
#define CURVE_SCALE		(curve_params.x)
#define CURVE_OFFSET	(curve_params.y)
#define CURVE_SIGMA		(curve_params.z)
#define CURVE_SIGMA2	(curve_params.w)					// ignores sample count, for use with screenshots
#define NEAR_SCALE		(fade_params.x)
#define NEAR_OFFSET		(fade_params.y)
#define FAR_SCALE		(fade_params.z)
#define FAR_OFFSET		(fade_params.w)
#define CHANNEL_SCALE (channel_scale.xyzw)
#define CHANNEL_OFFSET (channel_offset.xyzw)


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 1.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}


float calculate_fade(float center_depth)
{
	float near_fade=	saturate(center_depth * NEAR_SCALE + NEAR_OFFSET);
	float far_fade=		saturate(center_depth * FAR_SCALE + FAR_OFFSET);
	float fade=			near_fade * far_fade;

	// smoothing
//	fade=	(3-2*fade)*fade*fade;

	return fade;
}

float calc_occlusion_samples(in float4 depths0, in float4 depths1, in float center_depth)
{
/*
	// traditional HDAO (from paper) -- slightly modified by using a faded far test, instead of a strict cutoff
	// the shadowing factor (DEPTH_TEST) for each depth sample is simply whether it is within a valid range in front of the center sample
	// opposing depth samples must both be shadowing to contribute to occlusion (their shadowing factors are multiplied)

	#define CLOSE_TEST(depths)	(depths > 0.0015f ? 1 : 0)
	#define FAR_TEST(depths)	saturate(1.2f - 3.0 * (depths))
	#define DEPTH_TEST(depths)	(CLOSE_TEST(depths) * FAR_TEST(depths))

	depths0= center_depth	- depths0;
	depths1= center_depth	- depths1;

	depths0=	DEPTH_TEST(depths0);
	depths1=	DEPTH_TEST(depths1);

	return dot(depths0 * depths1, 1.0f);
/*/
	// improved method (ctchou)
	// the shadowing factor is a combination of:
	//   depression amount (how much the center sample is below the average of the two outer opposing depth samples)
	//   bounds amount (whether the nearest depth sample is within shadowing range of the center sample)
	// all depth comparisons are scaled by the distance to the center sample, so that the effect scales with distance


//	#define FAR_TEST(depths)	saturate(1.1f - bounds_scale * (depths))
//	float bounds_scale=		5.0f / abs(center_depth);
//	float4 bounds=			FAR_TEST(center_depth - min(depths0, depths1));


	float4 bounds1=			saturate(BOUNDS_OFFSET + depths0 * (BOUNDS_SCALE / center_depth));
	float4 bounds2=			saturate(BOUNDS_OFFSET + depths1 * (BOUNDS_SCALE / center_depth));
	float4 bounds=	bounds1*bounds2;

//	float4 bounds=			saturate(BOUNDS_OFFSET + min(depths0, depths1) * (BOUNDS_SCALE / center_depth));
//	bounds *= bounds;		// the square based on bounds here is relatively expensive


//	float depression_scale=	20 / abs(center_depth);
//	float4 depression=		saturate(depression_scale * (center_depth * 2.0 - (depths0 + depths1)));

//	float4 depression=		saturate(25 * (2.0 - (depths0 + depths1) / center_depth));
	float4 depression=		saturate(CORNER_OFFSET + (depths0 + depths1) * (CORNER_SCALE / center_depth));

	return dot(bounds * depression, 1.0f);


	// better, but more expensive, do separate bounds tests for each depth
//	float4 bounds1=			FAR_TEST(center_depth - depths0);
//	float4 bounds2=			FAR_TEST(center_depth - depths1);
//	float4 bounds1=			saturate(BOUNDS_OFFSET + (center_depth - depths0) * (BOUNDS_SCALE / center_depth));
//	float4 bounds2=			saturate(BOUNDS_OFFSET + (center_depth - depths1) * (BOUNDS_SCALE / center_depth));
//	return dot(depression * bounds1 * bounds2, 1.0f);

//*/
}


void fix_depth_deproject(inout float4 depths)
{
	depths=	1.0f / (local_depth_constants.xxxx + depths * local_depth_constants.yyyy);
}

void fix_depth_scale(inout float4 depths)
{
//	depths *= 16.0f;
}



#define CALC_OCCLUSION(samp, fix_depth,		DX0, DY0,		DX1, DY1)																											\
{																																												\
	[isolate]																																									\
	asm																																											\
	{																																											\
		tfetch2D	depths0.r___, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -DX0, OffsetY= -DY0						\
		tfetch2D	depths0._r__, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -DX1, OffsetY= -DY1						\
		tfetch2D	depths0.__r_, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -DY0, OffsetY= +DX0						\
		tfetch2D	depths0.___r, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -DY1, OffsetY= +DX1						\
																																												\
		tfetch2D	depths1.r___, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +DX0, OffsetY= +DY0						\
		tfetch2D	depths1._r__, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +DX1, OffsetY= +DY1						\
		tfetch2D	depths1.__r_, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +DY0, OffsetY= -DX0						\
		tfetch2D	depths1.___r, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +DY1, OffsetY= -DX1						\
	};																																											\
																																												\
	fix_depth(depths0);																																							\
	fix_depth(depths1);																																							\
																																												\
	occlusion	+=	calc_occlusion_samples(depths0, depths1, center_depth);																										\
}


#define CALC_OCCLUSION4(samp, fix_depth,		DX0, DY0)																														\
{																																												\
	{																																											\
		[isolate]																																								\
		asm																																										\
		{																																										\
			tfetch2D	depths0.rgba, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -DX0, OffsetY= -DY0					\
			tfetch2D	depths1.rgba, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +DX0, OffsetY= +DY0					\
		};																																										\
	}																																											\
	occlusion	+=	calc_occlusion_samples(depths0.xyzw, depths1.xyzw, center_depth);																							\
	{																																											\
		[isolate]																																								\
		asm																																										\
		{																																										\
			tfetch2D	depths0.rgba, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= -DY0, OffsetY= +DX0					\
			tfetch2D	depths1.rgba, texcoord, samp, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +DY0, OffsetY= -DX0					\
		};																																										\
	}																																											\
	occlusion	+=	calc_occlusion_samples(depths0.xyzw, depths1.xyzw, center_depth);																							\
}


// small 24-sample

//[maxtempreg(4)]
float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
#ifdef pc
	return 1.0f;
#else

	float2 texcoord= input.texcoord;

	float inv_center_depth;
	asm
	{
		tfetch2D	inv_center_depth.r___, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.0, OffsetY= +0.0
	};
	inv_center_depth=	(local_depth_constants.x + inv_center_depth * local_depth_constants.y);
	float center_depth=	1.0f / inv_center_depth;


	float4 depths0;
	float4 depths1;
	float occlusion= 0;

//	CALC_OCCLUSION(depth_sampler,	fix_depth_deproject,		1.0, 1.0,		1.0, 0.0);
	CALC_OCCLUSION(depth_sampler,	fix_depth_deproject,		2.0, 2.0,		3.0, 0.0);
	CALC_OCCLUSION(depth_sampler,	fix_depth_deproject,		5.0, 2.0,		2.0, 5.0);
	CALC_OCCLUSION(depth_sampler,	fix_depth_deproject,		7.0, 0.0,		5.0, 5.0);
//	CALC_OCCLUSION(depth_sampler,	fix_depth_deproject,		7.0, 3.0,		3.0, 7.0);

//	return 0.2f + 0.8f * exp2(-0.1f * occlusion*occlusion);

	float fade= calculate_fade(center_depth);

	return CHANNEL_OFFSET + CHANNEL_SCALE * max(1-fade, exp2(CURVE_SIGMA * occlusion*occlusion));


#endif
}


// large 64 sample

//[maxtempreg(4)]
float4 albedo_ps(const in s_screen_vertex_output input,	SCREEN_POSITION_INPUT(vpos)) : SV_Target
{
#ifdef pc
	return 1.0f;
#else

	float2 texcoord= input.texcoord;

	float inv_center_depth;
	asm
	{
		tfetch2D	inv_center_depth.r___, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.0, OffsetY= +0.0
	};
	inv_center_depth=	(local_depth_constants.x + inv_center_depth * local_depth_constants.y);
	float center_depth=	1.0f / inv_center_depth;

	float4 depths0;
	float4 depths1;
	float occlusion= 0;

//	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			2.0, 2.0);
//	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			3.0, 0.0);

	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			1.5, 1.5);
	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			3.0, 0.0);

	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			5.0, 1.5);
	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			1.5, 5.0);

//	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			4.5, 1.5);
//	CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			1.5, 4.5);

//	occlusion *= 2.0f;			// 8 sample
//	occlusion *= 1.333f;		// 12 sample

//	return 0.08f + 0.92f * exp2(-0.018f * occlusion*occlusion);
//	return 0.1f + 0.9f * exp2(-0.018f * occlusion*occlusion);

	float fade= calculate_fade(center_depth);

	return CHANNEL_OFFSET + CHANNEL_SCALE * max(1-fade, exp2(CURVE_SIGMA * occlusion*occlusion));

#endif
}


// optimized predicated 64 sample

//[maxtempreg(5)]
float4 static_probe_ps(const in s_screen_vertex_output input) : SV_Target
{
#ifdef pc
	return 1.0f;
#else

	float2 texcoord= input.texcoord;

	float occlusion=	0.0f;
	float fade=			1.0f;

	{
		float inv_center_depth;
		asm
		{
			tfetch2D	inv_center_depth.r___, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.0, OffsetY= +0.0
		};
		inv_center_depth=	(local_depth_constants.x + inv_center_depth * local_depth_constants.y);
		float center_depth=	1.0f / inv_center_depth;

		fade= calculate_fade(center_depth);

		float4 depths0;
		float4 depths1;

		CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			3.5, 2.0);
		CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			2.0, 4.0);

		// this if causes more ghosting around edges, but is a big perf win.   I wish we could afford to leave it out  :(
		if (occlusion > 1.0f)
		{
			CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			1.0, 1.5);
			CALC_OCCLUSION4(depth_low_sampler,	fix_depth_scale,			0.0, 2.5);
		}

	}

//	return 0.25f + 0.75f * exp2(-0.018f * occlusion*occlusion);

	float4 result = CHANNEL_OFFSET + CHANNEL_SCALE * max(1-fade, exp2(CURVE_SIGMA * occlusion*occlusion));
	return result.xywz;		// mboulton : Swizzle to put the ambient SSAO result into the BLUE channel (was in the alpha channel)
#endif
}


// screenshot version

float4 shadow_generate_ps(const in s_screen_vertex_output input) : SV_Target
{
#ifdef pc
	return 1.0f;
#else

	float2 texcoord= input.texcoord;

	float occlusion=	0.0f;
	float fade=			1.0f;
	float sample_count=	0.0f;

	{
		float inv_center_depth;
		asm
		{
			tfetch2D	inv_center_depth.r___, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.0, OffsetY= +0.0
		};
		inv_center_depth=	(local_depth_constants.x + inv_center_depth * local_depth_constants.y);
		float center_depth=	1.0f / inv_center_depth;

		fade= calculate_fade(center_depth);

		for (float y= 1; y <= SCREENSHOT_RADIUS_Y; y++)				// don't include zero, (when mirrored, this produces a full sampling of the square, minus the center pixel)
		{
			float relative_y=			y / SCREENSHOT_RADIUS_Y;
			float relative_y_squared=	relative_y * relative_y;

			float x_start=	(y % 2);								// we don't sample every pixel, we sample every other one in a checkerboard pattern

			for (float x= x_start; x <= SCREENSHOT_RADIUS_X; x += 2)
			{
				float relative_x=		x / SCREENSHOT_RADIUS_X;
				float distance_squared=	(relative_x * relative_x + relative_y_squared);

				if (distance_squared <= 1.0f)
				{
					float4 depths0;
					float4 depths1;
					{
						[isolate]
						float2 offset0=		texcoord + ps_pixel_size.xy * float2( x,  y);
						float2 offset1=		texcoord + ps_pixel_size.xy * float2(-x, -y);
						asm
						{
							tfetch2D	depths0.rgba, offset0, depth_low_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled
							tfetch2D	depths1.rgba, offset1, depth_low_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled
						};
					}
					occlusion	+=	calc_occlusion_samples(depths0.xyzw, depths1.xyzw, center_depth);
					sample_count+=	8.0f;
					{
						[isolate]
						float2 offset0=		texcoord + ps_pixel_size.xy * float2(-x,  y);
						float2 offset1=		texcoord + ps_pixel_size.xy * float2( x, -y);
						asm
						{
							tfetch2D	depths0.rgba, offset0, depth_low_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled
							tfetch2D	depths1.rgba, offset1, depth_low_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled
						};
					}
					occlusion	+=	calc_occlusion_samples(depths0.xyzw, depths1.xyzw, center_depth);
					sample_count+=	8.0f;
				}
			}
		}
	}

	occlusion /= sample_count;

	return CHANNEL_OFFSET + CHANNEL_SCALE * max(1-fade, exp2(CURVE_SIGMA2 * occlusion*occlusion));
#endif
}

// mask debug
float4 active_camo_ps() : SV_Target
{
	return 0.0f;
}


// corrinyu: 16 samples 5 GPR's 83.00 GPU cycles

struct D
{
	float4 d[4];
};

// corrinyu: fade off far away AO lines so they don't do a stipple dance
float far_clip_fade(float center_depth)
{
	return saturate(center_depth * FAR_SCALE + FAR_OFFSET);
}

// fast version of reconstruction from sampled point
float
midnight_depth_distance_over_reconstruction(
	in float4 depths0,
	in float4 depths1,
	in float center_depth,
	in float4 reconstructed)
{
	float4 d0 = saturate(BOUNDS_OFFSET + depths0 * (BOUNDS_SCALE / center_depth));
	float4 d1 = saturate(BOUNDS_OFFSET + depths1 * (BOUNDS_SCALE / center_depth));
	float4 test01 =	d0 * d1;
	float r = dot(test01 * reconstructed, 1.0f);
	return r;
}

// fast version of reconstruction from sampled point
float midnight_depth_distance_and_reconstruction(in float4 depths0, in float4 depths1, in float center_depth)
{
	float4 reconstructed01 = saturate(CORNER_OFFSET + (depths0 + depths1) * (CORNER_SCALE / center_depth));
	return midnight_depth_distance_over_reconstruction(depths0, depths1, center_depth, reconstructed01);
}

// sample depths
D SampleDepths(sampler2D s, in float2 texcoord, const float DX0, const float DY0)
{
	D d;
	const float NDX = -DX0;
	const float NDY = -DY0;
	float4 depths0;
	float4 depths1;
	float4 depths2;
	float4 depths3;
#ifndef pc
#ifndef VERTEX_SHADER
	[isolate]
	asm
	{
		tfetch2D	depths0.rgba, texcoord, s, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=NDX, OffsetY=NDY
		tfetch2D	depths1.rgba, texcoord, s, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=DX0, OffsetY=DY0
		tfetch2D	depths2.rgba, texcoord, s, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=NDX, OffsetY=DY0
		tfetch2D	depths3.rgba, texcoord, s, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=DX0, OffsetY=NDY
	};
#endif
#endif
	d.d[0] = depths0;
	d.d[1] = depths1;
	d.d[2] = depths2;
	d.d[3] = depths3;
	return d;
}

// fast version of reconstruction from sampled point
float MidnightReconstructSamples4(float center_depth, sampler2D s, in float2 texcoord, const float DX0, const float DY0)
{
	float occlusion = 0.0f;
	D d = SampleDepths(s, texcoord, DX0, DY0);
	// corrinyu: TODO work on 1st person 3rd person depth discrepancy eject
	float4 reconstructed01 = saturate(CORNER_OFFSET + (d.d[0] + d.d[1]) * (CORNER_SCALE / center_depth));
	float4 reconstructed23 = saturate(CORNER_OFFSET + (d.d[2] + d.d[3]) * (CORNER_SCALE / center_depth));
	occlusion += midnight_depth_distance_over_reconstruction(d.d[0], d.d[1], center_depth, reconstructed01);
	occlusion += midnight_depth_distance_over_reconstruction(d.d[2], d.d[3], center_depth, reconstructed23);
	return occlusion;
}

float4 static_per_pixel_ps(const in s_screen_vertex_output input) : SV_Target
{
#ifdef pc
	return 1.0f;
#else
	float2 texcoord = input.texcoord;
	float occlusion = 0.0f;

	float inv_center_depth;
	asm
	{
		tfetch2D	inv_center_depth.r___, texcoord, depth_sampler, MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX= +0.0, OffsetY= +0.0
	};
	inv_center_depth = (local_depth_constants.x + inv_center_depth * local_depth_constants.y);
	float center_depth = 1.0f / inv_center_depth;

	// corrinyu: fade off far away AO lines so they don't do a stipple dance
	float far_clip_scale = far_clip_fade(center_depth);

	// fast version of reconstruction from sampled point
	occlusion += MidnightReconstructSamples4(center_depth, depth_low_sampler, texcoord, 2.0, 3.0);
	occlusion += MidnightReconstructSamples4(center_depth, depth_low_sampler, texcoord, 0.5, 5.0);
	occlusion += MidnightReconstructSamples4(center_depth, depth_low_sampler, texcoord, 7.0, 4.0);
	occlusion += MidnightReconstructSamples4(center_depth, depth_low_sampler, texcoord, 4.0, 7.5);

	return CHANNEL_OFFSET + CHANNEL_SCALE * max(1 - far_clip_scale, exp2(CURVE_SIGMA * occlusion * occlusion));
#endif
}




BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE albedo
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(albedo_ps());
	}
}


BEGIN_TECHNIQUE static_probe
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(static_probe_ps());
	}
}

BEGIN_TECHNIQUE shadow_generate
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(shadow_generate_ps());
	}
}

BEGIN_TECHNIQUE active_camo
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(active_camo_ps());
	}
}

BEGIN_TECHNIQUE static_per_pixel
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(static_per_pixel_ps());
	}
}


