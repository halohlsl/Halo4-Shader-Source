#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "core/core_functions.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "fxaa_registers.fxh"


//
// Controls the sharpness of edges.
//
// 8.0 is sharper
// 4.0 is softer
//
#define FXAA_EDGE_SHARPNESS_SHARP 8.0
#define FXAA_EDGE_SHARPNESS_SOFT 4.0


//
// The minimum amount of local contrast required to apply algorithm.
//
// 0.125 leaves less aliasing, but is softer
// 0.25 leaves more aliasing, and is sharper
//
#define FXAA_EDGE_THRESHOLD_SOFT 0.125
#define FXAA_EDGE_THRESHOLD_SHARP 0.25


//
// Trims the algorithm from processing darks, which have less
// noticable aliasing
//
#define FXAA_EDGE_THRESHOLD_MIN 0.05


//
// Controls where the inner taps are sampled
//
#define FXAA_UNIT_INNER_TAPS 0
#define FXAA_EDGE_INNER_TAPS 1




void FxaaVertexShader(
	in float4 inPosition : POSITION0,
	out float4 outPosition : SV_Position,
	inout float4 texCenter : TEXCOORD0
#if !defined(xenon)
	, out float4 texCorners : TEXCOORD1
#endif
)
{
	texCenter.zw = texCenter.xy + g_outerTapOffsetsOpt.zw;

	outPosition = float4(inPosition.xy, 0, 1);
#if !defined(xenon)
	texCorners.xy = texCenter + g_innerTapOffsets.xy;
	texCorners.zw = texCenter + g_innerTapOffsets.zw;
#endif
}

float4 FxaaPixelShader(
	in float4 screenPosition : SV_Position,
	float4 pos : TEXCOORD0,										// Pixel center
#if !defined(xenon)
	float4 posPos : TEXCOORD1,									// Upper left, lower right of pixel
#endif
	uniform float edgeThresholdMin,								// Trims the algorithm from processing darks
	uniform float edgeThreshold,								// The minimum amount of local contrast required to apply algorithm
	uniform float edgeSharpness,								// Controls the sharpness of edges.
	uniform int innerTapOffset
) : SV_Target0
{
	float4 lumaNwNeSwSe;

#if defined(xenon)
	asm {
		tfetch2D lumaNwNeSwSe.w___, sourceSamplers[0], pos.xy, OffsetX = -0.5, OffsetY = -0.5, UseComputedLOD=false
		tfetch2D lumaNwNeSwSe._w__, sourceSamplers[0], pos.xy, OffsetX =  0.5, OffsetY = -0.5, UseComputedLOD=false
		tfetch2D lumaNwNeSwSe.__w_, sourceSamplers[0], pos.xy, OffsetX = -0.5, OffsetY =  0.5, UseComputedLOD=false
		tfetch2D lumaNwNeSwSe.___w, sourceSamplers[0], pos.xy, OffsetX =  0.5, OffsetY =  0.5, UseComputedLOD=false
	};
#else
	lumaNwNeSwSe.x = sample2DLOD(sourceSampler, posPos.xy, 0.0, false).w;
	lumaNwNeSwSe.y = sample2DLOD(sourceSampler, posPos.zy, 0.0, false).w;
	lumaNwNeSwSe.z = sample2DLOD(sourceSampler, posPos.xw, 0.0, false).w;
	lumaNwNeSwSe.w = sample2DLOD(sourceSampler, posPos.zw, 0.0, false).w;
#endif

	// Prevent divide by zero errors
	lumaNwNeSwSe.y += 1.0/384.0;

	// Calculate the surrounding min/max
	float2 lumaMinTemp = min(lumaNwNeSwSe.xy, lumaNwNeSwSe.zw);
	float2 lumaMaxTemp = max(lumaNwNeSwSe.xy, lumaNwNeSwSe.zw);
	float lumaMin = min(lumaMinTemp.x, lumaMinTemp.y);
	float lumaMax = max(lumaMaxTemp.x, lumaMaxTemp.y);

	// Calculate the 5-sample min/max
#ifdef xenon
	float4 rgbyM = sample2DLOD(sourceSamplers[0], pos.xy, 0.0, false);
#else
	float4 rgbyM = sample2DLOD(sourceSampler, pos.xy, 0.0, false);
#endif
	float lumaMinM = min(lumaMin, rgbyM.w);
	float lumaMaxM = max(lumaMax, rgbyM.w);

	[predicateBlock]
	if ((lumaMaxM - lumaMinM) > max(edgeThresholdMin, lumaMax * edgeThreshold))
	{

		// Get the gradient in x and y
		float2 dir;
		dir.x = dot(lumaNwNeSwSe, g_externMathValues.yyxx);			// (-1.0, -1.0, 1.0, 1.0)
		dir.y = dot(lumaNwNeSwSe, g_externMathValues.xyxy);			// ( 1.0, -1.0, 1.0,-1.0)

		if (innerTapOffset == FXAA_UNIT_INNER_TAPS)
		{
			// One unit out from pixel center
			dir = normalize(dir);
		}
		else
		{
			// Interesect edge of center pixel
			float dirAbsMax = max(abs(dir.x), abs(dir.y));
			dir /= dirAbsMax;
		}

		// Sample nearby taps along the rescaled gradient
		float4 dir1 = dir.xyxy * g_innerTapOffsets.xyzw;			// +half pixel, -half pixel


		// Calculate the outer tap offsets
		float4 dir2;
		float dirAbsMinTimesC = min(abs(dir.x), abs(dir.y));

		// Rescale the -2 ... +2 range to 0 ... 1 and clamp
		dir2 = saturate(g_externMathValues.zzww * dir.xyxy / edgeSharpness / dirAbsMinTimesC + 0.5);

		// Remap the clamped 0 ... 1 range to the outer tap range.  The offset is already added into the zw component of the texcoord
		dir2 = dir2 * g_outerTapOffsetsOpt.xyxy;


		// Sample the inner and outer taps
#ifdef xenon		
		float4 rgbyN1 = sample2DLOD(sourceSamplers[1], pos.xy + dir1.xy, 0.0, false);		// Exp -1 on this sampler divides by 2
		float4 rgbyP1 = sample2DLOD(sourceSamplers[1], pos.xy + dir1.zw, 0.0, false);		// Exp -1 on this sampler divides by 2
		float4 rgbyN2 = sample2DLOD(sourceSamplers[2], pos.zw + dir2.xy, 0.0, false);		// Exp -2 on this sampler divides by 4
		float4 rgbyP2 = sample2DLOD(sourceSamplers[2], pos.zw + dir2.zw, 0.0, false);		// Exp -2 on this sampler divides by 4
#else
		float4 rgbyN1 = sample2DLOD(sourceSampler, pos.xy + dir1.xy, 0.0, false) / 2;
		float4 rgbyP1 = sample2DLOD(sourceSampler, pos.xy + dir1.zw, 0.0, false) / 2;
		float4 rgbyN2 = sample2DLOD(sourceSampler, pos.zw + dir2.xy, 0.0, false) / 4;
		float4 rgbyP2 = sample2DLOD(sourceSampler, pos.zw + dir2.zw, 0.0, false) / 4;
#endif
		

		// Combine the taps
		float4 rgbyA = rgbyN1 + rgbyP1;
		float4 rgbyB = rgbyN2 + rgbyP2 + 0.5 * rgbyA;


		// Select and return the best output
		float4 outVal = (rgbyB.w - lumaMax > 0) ? rgbyA : rgbyB;	// w greater than max, select A; otherwise keep value
		outVal = (rgbyB.w - lumaMin > 0) ? outVal : rgbyA;			// w greater than min, keep value; otherwise select A
		return outVal;
	}
	else
	{
		return rgbyM;
	}

}




BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SOFT,				// blurrier, less aliasing
			FXAA_EDGE_SHARPNESS_SHARP,				// sharper
			FXAA_UNIT_INNER_TAPS));					// inner taps are one unit out
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SHARP,				// sharper, more aliasing
			FXAA_EDGE_SHARPNESS_SHARP,				// sharper
			FXAA_UNIT_INNER_TAPS));					// inner taps are one unit out
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SOFT,				// blurrier, less aliasing
			FXAA_EDGE_SHARPNESS_SOFT,				// blurrier
			FXAA_UNIT_INNER_TAPS));					// inner taps are one unit out
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SHARP,				// sharper, more aliasing
			FXAA_EDGE_SHARPNESS_SOFT,				// blurrier
			FXAA_UNIT_INNER_TAPS));					// inner taps are one unit out
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SOFT,				// blurrier, less aliasing
			FXAA_EDGE_SHARPNESS_SHARP,				// sharper
			FXAA_EDGE_INNER_TAPS));					// inner taps are on pixel edge
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SHARP,				// sharper, more aliasing
			FXAA_EDGE_SHARPNESS_SHARP,				// sharper
			FXAA_EDGE_INNER_TAPS));					// inner taps are on pixel edge
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SOFT,				// blurrier, less aliasing
			FXAA_EDGE_SHARPNESS_SOFT,				// blurrier
			FXAA_EDGE_INNER_TAPS));					// inner taps are on pixel edge
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(FxaaVertexShader());
		SET_PIXEL_SHADER(FxaaPixelShader(
			FXAA_EDGE_THRESHOLD_MIN,
			FXAA_EDGE_THRESHOLD_SHARP,				// sharper, more aliasing
			FXAA_EDGE_SHARPNESS_SOFT,				// blurrier
			FXAA_EDGE_INNER_TAPS));					// inner taps are on pixel edge
	}
}


