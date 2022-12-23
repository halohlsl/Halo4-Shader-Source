#if !defined(__POSTPROCESS_TEXTURES_FXH)
#define __POSTPROCESS_TEXTURES_FXH

#include "postprocessing/postprocess_parameters.fxh"


float4 Sample2DOffsetExact(
	texture_sampler_2d samp,
	const float2 texCoord,
	const float offsetX,
	const float offsetY)
{
	return sample2D(samp, texCoord + float2(offsetX, offsetY) * ps_pixel_size.xy);
}


float4 Sample2DOffset(
	texture_sampler_2d samp,
	float2 texCoord,
	const float offsetX,
	const float offsetY)
{
	float4 value;

#if !defined(xenon)
	value = Sample2DOffsetExact(samp, texCoord, offsetX, offsetY);
#else
	asm
	{
		tfetch2D value, texCoord, samp, OffsetX = offsetX, OffsetY = offsetY
	};
#endif

	return value;
}


float4 Sample2DOffsetPoint(
	texture_sampler_2d samp,
	float2 texCoord,
	const float offsetX,
	const float offsetY)
{
#if !defined(xenon)
	return Sample2DOffsetExact(samp, texCoord, offsetX, offsetY);
#else
	float4 value;
	asm
	{
		tfetch2D value, texCoord, samp, MinFilter = point, MagFilter = point, OffsetX = offsetX, OffsetY = offsetY
	};
	return value;
#endif
}




float4 CalcWeightsBicubic(float4 dist)
{
	//
	//  bicubic is a smooth sampling method
	//  it is smoother than bilinear, but can have ringing around high-contrast edges (because of it's weights can go negative)
	//	bicubic in linear space is not the best..
	//

	// input vector contains the distance of 4 sample pixels [-1.5, -0.5, +0.5, +1.5] to our sample point
	// output vector contains the weights for each of the corresponding pixels

	// bicubic parameter 'A'
#define A -0.75f
	float4 weights;
	weights.yz= (((A + 2.0f) * dist.yz - (A + 3.0f)) * dist.yz * dist.yz + 1.0f);					// 'photoshop' style bicubic
	weights.xw= (((A * dist.xw - 5.0f * A ) * dist.xw + 8.0f * A ) * dist.xw - 4.0f * A);
	return weights;
#undef A
}

float4 CalcWeightsBSpline(float4 dist)
{
	//
	//  bspline is a super-smooth sampling method
	//  it is smoother than bicubic (much smoother than bilinear)
	//  and, unlike bicubic, is guaranteed not to have ringing around high-contrast edges (because it has no negative weights)
	//  the downside is it gives everything a slight blur so you lose a bit of the high frequencies
	//

	float4 weights;
	weights.yz= (4.0f + (-6.0f + 3.0f * dist.yz) * dist.yz * dist.yz) / 6.0f;						// bspline
	weights.xw= (2.0f - dist.xw) * (2.0f - dist.xw) * (2.0f - dist.xw) / 6.0f;
	return weights;
}

float4 CalcWeightsBSpline2x(float dist)
{
	// these weights only work when you're resizing by a perfect factor of two.  (but it's faster than above)

	// 0, 0.5
//	return	float4( 0.166666,  0.666666,  0.166666, 0.0) +
//			float4(-0.291666, -0.375000,  0.625000, 0.041666667) * dist;

	// 0.5, 1.0
	return	float4( 0.0416666,  0.791666,  0.291666, -0.125000) +
			float4(-0.0416666, -0.625000,  0.375000,  0.291666) * dist;
}


#if defined(xenon)
#define DECLARE_TEX2D_4x4_METHOD(name, calculate_weights_func)																\
float4 name(texture_sampler_2d s, float2 texc)																						\
{																															\
    float4 subpixel_dist;																									\
    asm {																													\
        getWeights2D subpixel_dist, texc, s																					\
    };																														\
  	float4 x_dist= float4(1.0f+subpixel_dist.x, subpixel_dist.x, 1.0f-subpixel_dist.x, 2.0f-subpixel_dist.x);				\
	float4 x_weights= calculate_weights_func(x_dist);																		\
																															\
	float4 y_dist= float4(1.0f+subpixel_dist.y, subpixel_dist.y, 1.0f-subpixel_dist.y, 2.0f-subpixel_dist.y);				\
	float4 y_weights= calculate_weights_func(y_dist);																		\
																															\
	float4 color=	0.0f;																									\
																															\
	[unroll]																												\
	[isolate]																												\
	for (int y= 0; y < 4; y++)																								\
	{																														\
		float y_offset= y - 1.5f;																							\
		float4 color0, color1, color2, color3;																				\
		asm {																												\
			tfetch2D color0, texc, s, MinFilter=point, MagFilter=point, OffsetX=-1.5, OffsetY=y_offset						\
			tfetch2D color1, texc, s, MinFilter=point, MagFilter=point, OffsetX=-0.5, OffsetY=y_offset						\
			tfetch2D color2, texc, s, MinFilter=point, MagFilter=point, OffsetX=+0.5, OffsetY=y_offset						\
			tfetch2D color3, texc, s, MinFilter=point, MagFilter=point, OffsetX=+1.5, OffsetY=y_offset						\
		};																													\
		float4 vert_color=	x_weights.x * color0 +																			\
							x_weights.y * color1 +																			\
							x_weights.z * color2 +																			\
							x_weights.w * color3;																			\
																															\
		color += vert_color * y_weights.x;																					\
		y_weights.xyz= y_weights.yzw;																						\
	}																														\
																															\
	return color;																											\
}
#else  // defined(xenon)
#define DECLARE_TEX2D_4x4_METHOD(name, calculate_weights_func) float4 name(texture_sampler_2d s, float2 texc) { return sample2D(s, texc); }
#endif // defined(xenon)

DECLARE_TEX2D_4x4_METHOD(tex2D_bicubic, CalcWeightsBicubic)
DECLARE_TEX2D_4x4_METHOD(tex2D_bspline, CalcWeightsBSpline)
DECLARE_TEX2D_4x4_METHOD(tex2D_bspline2x, CalcWeightsBSpline2x)



#if defined(DARK_COLOR_MULTIPLIER)

// depth of field
#define DEPTH_BIAS			depth_constants[0].x
#define DEPTH_SCALE			depth_constants[0].y
#define MAX_BLUR_BLEND		depth_constants[0].zw
#define FOCUS_SCALE			depth_constants[1].xz
#define FOCUS_RANGE			depth_constants[1].yw


float4 SimpleDOFFilter(
	float2 texcoord,
	texture_sampler_2d original_sampler,
	uniform bool original_gamma2,
	texture_sampler_2d blurry_sampler,
	texture_sampler_2d zbuffer_sampler,
	const in float4 depth_constants[2])
{
	// Fetch high and low resolution taps
	float4 vTapLow=		sample2D( blurry_sampler,	texcoord ) * DARK_COLOR_MULTIPLIER;
	float4 vTapHigh=	sample2D( original_sampler, texcoord ) * DARK_COLOR_MULTIPLIER;
	if (original_gamma2)
	{
		vTapHigh.rgb *= vTapHigh.rgb;
	}

	// get pixel depth, and calculate blur amount
	float fCenterDepth = sample2D( zbuffer_sampler, texcoord ).r;
	fCenterDepth= 1.0f / (DEPTH_BIAS + fCenterDepth * DEPTH_SCALE);					// convert to real depth

	float2 fTapBlur = clamp(FOCUS_SCALE * fCenterDepth.xx + FOCUS_RANGE, 0.0f, MAX_BLUR_BLEND);

	// blend high and low res based on blur amount
	float4 vOutColor= lerp(vTapHigh, vTapLow, dot(fTapBlur, fTapBlur));				// blurry samples use blurry buffer,  sharp samples use sharp buffer

    return vOutColor;
}



#endif


#endif 	// !defined(__POSTPROCESS_TEXTURES_FXH)
