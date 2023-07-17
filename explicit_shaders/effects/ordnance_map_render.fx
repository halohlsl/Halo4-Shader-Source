#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "fx/ordnance_map_core.fxh"

DECLARE_FLOAT_WITH_DEFAULT(normal_change_strength, "Normal-Change Strength", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_change_sharpness, "Normal-Change Sharpness", "", 0, 10, float(1));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth_change_strength, "Depth-Change Strength", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth_change_sharpness, "Depth-Change Sharpness", "", 0, 10, float(1));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel_strength, "Fresnel Strength", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_sharpness, "Fresnel Sharpness", "", 0, 10, float(1));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth_strength, "Depth Strength", "", 0, 1, float(0.5));
#include "used_float.fxh"

DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(occlusion_strength, "Occlusion Strength", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(occlusion_offset, "Occlusion Offset", "", 0, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(occlusion_depth_cutoff, "Occlusion Depth Cutoff", "", 0, 1, float(0.2));
#include "used_float.fxh"

struct s_vertex_output_screen
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen default_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen output;
	output.position = float4(input.position.xy, 0.0, 1.0);
	
	// I hate this double-Y flip, but it's whats I gots ta do
	output.texcoord =
	 (float2(input.texcoord.x, 1.0 - input.texcoord.y) * vsVisibleScreenBounds.zw + vsVisibleScreenBounds.xy - vsWholeMapBounds.xy) / vsWholeMapBounds.zw;
	output.texcoord.y = 1.0 - output.texcoord.y;
	
	return output;
}

float occlusion(float centerDepth, float offsetDepth, float multiplier)
{
	float difference = centerDepth - offsetDepth;
	return (offsetDepth > 0.0 ? clamp(centerDepth - offsetDepth, 0, occlusion_depth_cutoff) * multiplier : 0.0);
}

float4 default_ps(const in s_vertex_output_screen input) : SV_Target
{
#if defined(xenon)
	float2 texcoord = input.texcoord;
	
	float center = 1;
	float adjacent = 0.5;
	float doubleAdj = 0.333;
	float tripleAdj = 0.25;
	float quadAdj = 0.2;
	float diagonal = 0.4;
	float doubleDiag = 0.2;
	float total = 4 * (adjacent + doubleAdj + tripleAdj + quadAdj + diagonal + doubleDiag);

#define OPERATION(suffix, xOffset, yOffset, multiplier) \
	float depth##suffix; \
	float3 normal##suffix; \
	{ \
		float4 val; \
		asm { tfetch2D val, texcoord, psMapSampler, OffsetX = xOffset, OffsetY = yOffset }; \
		val.rg = float2(2.0 * val.r - 1.0, 2.0 * val.g - 1.0); \
		depth##suffix = val.b; \
		normal##suffix = float3(val.r, val.g, sqrt(1.0 - (val.r * val.r + val.g * val.g))); \
		if (depth##suffix == 0.0) normal##suffix = normalOO; \
	}
#define INCLUDE_CENTER
#include "fx/esoteric/ordnance_map_multi_include.fxh"
#undef OPERATION
#undef INCLUDE_CENTER

	float depth = depthOO;
	float3 normal = normalOO;

	float dotsAdjacent =
		(dot(normal, normalOP) +
		dot(normal, normalPO) +
		dot(normal, normalON) +
		dot(normal, normalNO)) * adjacent;
	float dotsDiagonal =
		(dot(normal, normalPP) +
		dot(normal, normalNN) +
		dot(normal, normalPN) +
		dot(normal, normalNP)) * diagonal;
	float dotsDouble =
		(dot(normal, normalDNO) +
		dot(normal, normalDPO) +
		dot(normal, normalODN) +
		dot(normal, normalODP)) * doubleAdj;

	float dots = (dotsAdjacent + dotsDiagonal + dotsDouble) / total;

	//float depthLaplacianX = (depthPO + depthNO - 2 * depth);
	//float depthLaplacianY = (depthOP + depthON - 2 * depth);
	//float laplacianMagnitude = sqrt(depthLaplacianX * depthLaplacianX + depthLaplacianY * depthLaplacianY);
	float depthChange = (depth * total - (
#define OPERATION(suffix, xOffset, yOffset, multiplier) (depth##suffix > 0.0 ? depth##suffix : depth) * multiplier +
#include "fx/esoteric/ordnance_map_multi_include.fxh"
#undef OPERATION
		0)) / total; // trailing '+'
	float laplacianMagnitude = abs(depthChange);
		
	float occludedAmount = occlusion_offset - occlusion_strength * (
#define OPERATION(suffix, xOffset, yOffset, multiplier) occlusion(depth, depth##suffix, multiplier) +
#include "fx/esoteric/ordnance_map_multi_include.fxh"
#undef OPERATION
		0); // trailing '+'
 
	float normalDotView = normal.z;
	
	float normalChangeValue = (pow(1.0 - dots, normal_change_sharpness)) * normal_change_strength;
	float depthChangeValue = (pow(laplacianMagnitude, depth_change_sharpness)) * depth_change_strength;
	float dotViewValue = (pow(1.0 - normalDotView, fresnel_sharpness)) * fresnel_strength;	
	
	float paletteValue = (depth > 0.0) ? 
		saturate(normalChangeValue + depthChangeValue + dotViewValue + occludedAmount + saturate((depth - vsZBounds.z) / (vsZBounds.w - vsZBounds.z)) * depth_strength)
		 : 0.0;
	
	float3 color = sample2DGamma(palette, float2(paletteValue, 0.5));
	
 	return float4(color, 1.0f);
#else // defined(xenon)
	return float4(1.0, 0.0, 0.75, 1.0); // obnoxious pink
#endif // defined(xenon)
}

BEGIN_TECHNIQUE _default <bool no_physics_material = true;>
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
