/**
 * Copyright (C) 2010 Jorge Jimenez (jorge@iryoku.com)
 * Copyright (C) 2010 Belen Masia (bmasia@unizar.es) 
 * Copyright (C) 2010 Jose I. Echevarria (joseignacioechevarria@gmail.com) 
 * Copyright (C) 2010 Fernando Navarro (fernandn@microsoft.com) 
 * Copyright (C) 2010 Diego Gutierrez (diegog@unizar.es)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the following statement:
 * 
 *       "Uses Jimenez's MLAA. Copyright (C) 2010 by Jorge Jimenez, Belen Masia,
 *        Jose I. Echevarria, Fernando Navarro and Diego Gutierrez."
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS 
 * IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS OR CONTRIBUTORS 
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are 
 * those of the authors and should not be interpreted as representing official
 * policies, either expressed or implied, of the copyright holders.
 */

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "core/core_functions.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "mlaa_registers.fxh"


#define PIXEL_SIZE float2(ps_pixel_size.xy)
#define MAX_SEARCH_STEPS_X 8
#define MAX_SEARCH_STEPS_Y 6
//#define MAX_DISTANCE (MAX_SEARCH_STEPS * 4 + 1)
#define MAX_DISTANCE 33
//#define MAX_DISTANCE 65


/**
 * Input vars and textures.
 */

#define threshold ps_scale

 
//DECLARE_PARAMETER(int, iMaxSearchSteps, i1) = MAX_SEARCH_STEPS_X;
//DECLARE_PARAMETER(float, fMaxSearchSteps, c3);
//#define fMaxSearchSteps 16


/**
 * Here we have an interesting define. In the last pass we make usage of 
 * bilinear filtering to avoid some lerps; however, bilinear filtering
 * in DX9, under DX9 hardware (but not in DX9 code running on DX10 hardware)
 * is done in gamma space, which gives sustantially worser results. So, this
 * flag allows to avoid the bilinear filter trick, changing it with some 
 * software lerps.
 *
 * So, to summarize, it is safe to use the bilinear filter trick when you are
 * using DX10 hardware on DX9. However, for the best results when using DX9
 * hardware, it is recommended comment this line.
 */

#define BILINEAR_FILTER_TRICK



/**
 * Same as above, this eases translation to assembly code;
 */

float4 tex2DLinear(texture_sampler_2d map, float2 texcoord)
{
#if defined(xenon)
    float4 result;
    asm
	{
        tfetch2D result, texcoord, map, UseComputedLOD = false, MinFilter = linear, MagFilter = linear, MipFilter = linear
    };
    return result;
#else
    return sample2D(map, texcoord);
#endif
}

float4 tex2DOffsetLinear(texture_sampler_2d map, float2 texcoord, float offX, float offY)
{
#if defined(xenon)
    float4 result;
    asm
	{
        tfetch2D result, texcoord, map, OffsetX = offX, OffsetY = offY, UseComputedLOD = false, MinFilter = linear, MagFilter = linear, MipFilter = linear
    };
    return result;
#else
    return sample2D(map, texcoord + PIXEL_SIZE * float2(offX, offY));
#endif
}

float4 tex2DOffsetPoint(texture_sampler_2d map, float2 texcoord, float offX, float offY)
{
#if defined(xenon)
    float4 result;
    asm
	{
        tfetch2D result, texcoord, map, OffsetX = offX, OffsetY = offY, UseComputedLOD = false, MinFilter = point, MagFilter = point, MipFilter = point
    };
    return result;
#else
    return sample2D(map, texcoord + PIXEL_SIZE * float2(offX, offY));
#endif
}


/** 
 * Ok, we have the distance and both crossing edges, can you please return 
 * the float2 blending weights?
 */

float2 Area(float2 distance, float e1, float e2) {
     // * Rounding prevents bilinear access precision problems
    float areaSize = MAX_DISTANCE * 5.0;
    float2 pixcoord = MAX_DISTANCE * round(4.0 * float2(e1, e2)) + distance;
    float2 texcoord = saturate(pixcoord / areaSize);
    return tex2DOffsetPoint(area_sampler, texcoord, 0.5, 0.5).ra;
}


/**
 *  V E R T E X   S H A D E R S
 */


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output PassThroughVS(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}
 

/**
 *  1 S T   P A S S   ~   C O L O R   V E R S I O N
 */
#define square(x) ((x)*(x))


float4 ColorEdgeDetectionPS(
	in float4 screenPosition : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target0
{
#if defined(xenon)

	float L =		tex2DOffsetPoint(source_sampler, texcoord, 0, 0).a;
	float Lleft =	tex2DOffsetPoint(source_sampler, texcoord,-1, 0).a - L;
	float Ltop =	tex2DOffsetPoint(source_sampler, texcoord, 0,-1).a - L;

	// Use math to reduce complexity of the shader and keep it texture bound
	// Threshold.x is log2(Threshold.z), which makes addition in log2 space equal to multiplication by Threshold.z
	// Threshold.y is the exponent to apply, which makes multiplication in log space equal to pow()
	float2 logDelta = log2(abs(float2(Lleft, Ltop)));
	logDelta = logDelta * threshold.y + threshold.x;
	float2 colorDelta = exp2(logDelta);

	clip(dot(colorDelta, 1.0) - 1.0);

	float2 edges = step(1.0f, colorDelta);
	return edges.xxyy;

#else

	return 0;

#endif
}


/**
 *  1 S T   P A S S   ~   D E P T H   V E R S I O N
 */

float4 DepthEdgeDetectionPS(
	in float4 screenPosition : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target0
{
#if defined(xenon)

    float D =		tex2DOffsetPoint(depth_sampler, texcoord, 0, 0).r;
    float Dleft =	tex2DOffsetPoint(depth_sampler, texcoord,-1, 0).r - D;
    float Dtop  =	tex2DOffsetPoint(depth_sampler, texcoord, 0,-1).r - D;

	float2 depthDelta = threshold.w * abs(float2(Dleft, Dtop));

	clip(dot(depthDelta, 1.0) - 1.0);

	float2 edges = step(1.0f, depthDelta);
	return edges.xxyy;

#else

	return 0;

#endif
}

/**
 *  1 S T   P A S S   ~   C O L O R + D E P T H   V E R S I O N
 */

float4 ColorDepthEdgeDetectionPS(
	in float4 screenPosition : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target0
{
#if defined(xenon)

	float L =		tex2DOffsetPoint(source_sampler, texcoord, 0, 0).a;
	float Lleft =	tex2DOffsetPoint(source_sampler, texcoord,-1, 0).a - L;
	float Ltop =	tex2DOffsetPoint(source_sampler, texcoord, 0,-1).a - L;

	// Use math to reduce complexity of the shader and keep it texture bound
	// Threshold.x is log2(Threshold.z), which makes addition in log2 space equal to multiplication by Threshold.z
	// Threshold.y is the exponent to apply, which makes multiplication in log space equal to pow()
	float2 logDelta = log2(abs(float2(Lleft, Ltop)));
	logDelta = logDelta * threshold.y + threshold.x;
	float2 colorDelta = exp2(logDelta);

	float D =		tex2DOffsetPoint(depth_sampler_2, texcoord, 0, 0).r;
	float Dleft =	tex2DOffsetPoint(depth_sampler_2, texcoord,-1, 0).r - D;
	float Dtop  =	tex2DOffsetPoint(depth_sampler_2, texcoord, 0,-1).r - D;

	float2 depthDelta = threshold.w * abs(float2(Dleft, Dtop));

	float2 delta = colorDelta + depthDelta;

	clip(dot(delta, 1.0) - 1.0);

	float2 edges = step(1.0f, delta);
	return edges.xxyy;

#else

	return 0;

#endif
}


/**
 * Search functions for the 2nd pass.
 */

#if defined(xenon)


float SearchXLeft(uniform int maxSearchSteps, float2 texcoord)
{
	texcoord.x -= 9.0 * PIXEL_SIZE.x;
	float e = 0;
	for (int i = 0, j = 0; i < maxSearchSteps; i++, j++)
	{
		if (j >= 8)
		{
			texcoord.x -= 16.0 * PIXEL_SIZE.x;
			j -= 8;
		}

		e = tex2DOffsetLinear(edge_sampler, texcoord, 7.5 - 2*j, 0).b;

		if (e < 0.9)
		{
			break;
		}
	}
	return 2.0 * min(i + e, maxSearchSteps);
}

float SearchXRight(uniform int maxSearchSteps, float2 texcoord)
{
	texcoord.x += 9.0 * PIXEL_SIZE.x;
	float e = 0;
	for (int i = 0, j = 0; i < maxSearchSteps; i++, j++)
	{
		if (j >= 8)
		{
			texcoord.x += 16.0 * PIXEL_SIZE.x;
			j -= 8;
		}

		e = tex2DOffsetLinear(edge_sampler, texcoord, -7.5 + 2*j, 0).b;

		if (e < 0.9)
		{
			break;
		}
	}
	return 2.0 * min(i + e, maxSearchSteps);
}

float SearchYUp(uniform int maxSearchSteps, float2 texcoord)
{
	texcoord.y -= 9.0 * PIXEL_SIZE.y;
	float e = 0;
	for (int i = 0, j = 0; i < maxSearchSteps; i++, j++)
	{
		if (j >= 8)
		{
			texcoord.y -= 16.0 * PIXEL_SIZE.y;
			j -= 8;
		}

		e = tex2DOffsetLinear(edge_sampler, texcoord, 0, 7.5 - 2*j).g;

		if (e < 0.9)
		{
			break;
		}
	}
	return 2.0 * min(i + e, maxSearchSteps);
}

float SearchYDown(uniform int maxSearchSteps, float2 texcoord)
{
	texcoord.y += 9.0 * PIXEL_SIZE.y;
	float e = 0;
	for (int i = 0, j = 0; i < maxSearchSteps; i++, j++)
	{
		if (j >= 8)
		{
			texcoord.y += 16.0 * PIXEL_SIZE.y;
			j -= 8;
		}

		e = tex2DOffsetLinear(edge_sampler, texcoord, 0, -7.5 + 2*j).g;

		if (e < 0.9)
		{
			break;
		}
	}
	return 2.0 * min(i + e, maxSearchSteps);
}


#endif

/**
 *  2 N D   P A S S
 */

float4 BlendWeightCalculationCombinedPS(
	uniform int maxSearchStepsX, 
	uniform int maxSearchStepsY, 
	in float4 screenPosition : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target0 {
#if defined(xenon)

    float4 areas = 0.0;


	float4 result;
	asm {
		tfetch2D result, texcoord, edge_sampler, UseComputedLOD = false, UseRegisterLOD = false, UseRegisterGradients = false, MinFilter = point, MagFilter = point, MipFilter = point
	};

	float2 e = result.gb;

    //[branch]
	if (e.g)		// edge above (so search that horizontal line for the endpoints)
	{
        // Search distances to the left and to the right:
        float2 d = float2(SearchXLeft(maxSearchStepsX, texcoord), SearchXRight(maxSearchStepsX, texcoord));

        // Now fetch the crossing edges. Instead of sampling between edgels, we
        // sample at -0.25, to be able to discern what value has each edgel:
        float4 coords = float4(-d.x, -0.25, d.y + 1.0, -0.25) * PIXEL_SIZE.xyxy + texcoord.xyxy;
        float e1 = sample2D(edge_sampler, coords.xy).g;
        float e2 = sample2D(edge_sampler, coords.zw).g;

        // Ok, we know how this pattern looks like, now it is time for getting
        // the actual area:
        areas.rg = Area(d, e1, e2);
    }

//    [branch]
    if (e.r)		 // Edge at west (so search that vertical line for the endpoints)
	{
        // Search distances to the top and to the bottom:
		float2 d = float2(SearchYUp(maxSearchStepsY, texcoord), SearchYDown(maxSearchStepsY, texcoord));

        // Now fetch the crossing edges (yet again):
        float4 coords = float4(-0.25, -d.x, -0.25, d.y + 1.0) * PIXEL_SIZE.xyxy + texcoord.xyxy;
        float e1 = sample2D(edge_sampler, coords.xy).b;
        float e2 = sample2D(edge_sampler, coords.zw).b;

        // Get the area for this direction:
        areas.ba = Area(d, e1, e2);
    }

    return areas;

#else

	return 0;

#endif
}


float4 BlendWeightCalculationHorizontalPS(
	uniform int maxSearchSteps, 
	in float4 screenPosition : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target0 {
#if defined(xenon)

    float4 areas = 0.0;

	float4 result;
	asm
	{
		tfetch2D result, texcoord, edge_sampler, UseComputedLOD = false, UseRegisterLOD = false, UseRegisterGradients = false, MinFilter = point, MagFilter = point, MipFilter = point
	};

	float e = result.b;

    if (e)		// edge above (so search that horizontal line for the endpoints)
	{
        // Search distances to the left and to the right:
		float2 d = float2(SearchXLeft(maxSearchSteps, texcoord), SearchXRight(maxSearchSteps, texcoord));

        // Now fetch the crossing edges. Instead of sampling between edgels, we
        // sample at -0.25, to be able to discern what value has each edgel:
        float4 coords = float4(-d.x, -0.25, d.y + 1.0, -0.25) * PIXEL_SIZE.xyxy + texcoord.xyxy;
        float e1 = sample2D(edge_sampler, coords.xy).g;
        float e2 = sample2D(edge_sampler, coords.zw).g;

        // Ok, we know how this pattern looks like, now it is time for getting
        // the actual area:
        areas.rg = Area(d, e1, e2);
    }

    return areas;

#else

	return 0;

#endif
}


float4 BlendWeightCalculationVerticalPS(
	uniform int maxSearchSteps, 
	in float4 screenPosition : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target0 {
#if defined(xenon)

    float4 areas = 0.0;

	float4 result;
	asm
	{
		tfetch2D result, texcoord, edge_sampler, UseComputedLOD = false, UseRegisterLOD = false, UseRegisterGradients = false, MinFilter = point, MagFilter = point, MipFilter = point
	};

	float e = result.g;

    if (e)			// edge to left (so search that vertical line for the endpoints)
	{
        // Search distances to the top and to the bottom:
		float2 d = float2(SearchYUp(maxSearchSteps, texcoord), SearchYDown(maxSearchSteps, texcoord));

        // Now fetch the crossing edges (yet again):
        float4 coords = float4(-0.25, -d.x, -0.25, d.y + 1.0) * PIXEL_SIZE.xyxy + texcoord.xyxy;
        float e1 = sample2D(edge_sampler, coords.xy).b;
        float e2 = sample2D(edge_sampler, coords.zw).b;

        // Get the area for this direction:
        areas.ba = Area(d, e1, e2);
    }

    return areas;

#else

	return 0;

#endif
}


/**
 *  3 R D   P A S S
 */
[reduceTempRegUsage(5)]
float4 NeighborhoodBlendingPS(
	in float4 screenPosition : SV_Position,
	float2 texcoord : TEXCOORD0) : SV_Target0
{
#if defined(xenon)

    // Fetch the blending weights for current pixel:
    float4 topLeft =	tex2DOffsetPoint(blend_sampler, texcoord, 0, 0);
    float bottom =		tex2DOffsetPoint(blend_sampler, texcoord, 0, 1).g;
    float right =		tex2DOffsetPoint(blend_sampler, texcoord, 1, 0).a;
    float4 a = float4(topLeft.r, bottom, topLeft.b, right);

    // Up to 4 lines can be crossing a pixel (one in each edge). So, we perform
    // a weighted average, where the weight of each line is 'a' cubed, which
    // favors blending and works well in practice.
    float4 w = a * a * a;

    // There is some blending weight with a value greater than 0.0?
    float sum = dot(w, 1.0);

	clip(sum - 1.0f / 256.0f);

	float4 color = 0.0;

	// Add the contributions of the possible 4 lines that can cross this pixel
	float4 coords;
	coords = float4( 0.0, -a.r, 0.0,  a.g) * PIXEL_SIZE.yyyy + texcoord.xyxy;
	color += tex2DLinear(source_sampler, coords.xy) * w.r;
	color += tex2DLinear(source_sampler, coords.zw) * w.g;

	coords = float4(-a.b,  0.0, a.a,  0.0) * PIXEL_SIZE.xxxx + texcoord.xyxy;
	color += tex2DLinear(source_sampler, coords.xy) * w.b;
	color += tex2DLinear(source_sampler, coords.zw) * w.a;

	color /= sum;

	// Normalize the resulting color and we are finished!
	return color; 

#else

	return sample2D(source_sampler, texcoord);

#endif
}


/**
 * Time for some techniques!
 */

BEGIN_TECHNIQUE
{
    pass screen
	{
        SET_VERTEX_SHADER(PassThroughVS());
        SET_PIXEL_SHADER(ColorEdgeDetectionPS());
    }
}

BEGIN_TECHNIQUE
{
    pass screen
	{
        SET_VERTEX_SHADER(PassThroughVS());
        SET_PIXEL_SHADER(DepthEdgeDetectionPS());
    }
}

BEGIN_TECHNIQUE
{
    pass screen
	{
        SET_VERTEX_SHADER(PassThroughVS());
        SET_PIXEL_SHADER(ColorDepthEdgeDetectionPS());
    }
}

BEGIN_TECHNIQUE
{
    pass screen
	{
        SET_VERTEX_SHADER(PassThroughVS());
        SET_PIXEL_SHADER(BlendWeightCalculationCombinedPS(MAX_SEARCH_STEPS_X, MAX_SEARCH_STEPS_Y));
    }
}

BEGIN_TECHNIQUE
{
    pass screen
	{
        SET_VERTEX_SHADER(PassThroughVS());
        SET_PIXEL_SHADER(BlendWeightCalculationHorizontalPS(MAX_SEARCH_STEPS_X));
    }
}

BEGIN_TECHNIQUE
{
    pass screen
	{
        SET_VERTEX_SHADER(PassThroughVS());
        SET_PIXEL_SHADER(BlendWeightCalculationVerticalPS(MAX_SEARCH_STEPS_Y));
    }
}

BEGIN_TECHNIQUE
{
    pass screen
	{
        SET_VERTEX_SHADER(PassThroughVS());
        SET_PIXEL_SHADER(NeighborhoodBlendingPS());
    }
}


