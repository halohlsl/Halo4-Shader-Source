#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "fx/vision_mode_core.fxh"
#include "exposure.fxh"

DECLARE_FLOAT_WITH_DEFAULT(desired_intensity, "Desired Intensity", "", 0, 3, 0.5);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensity_smoothing_strength, "Intensity Smoothing Strength", "", 0, 1, 0.5);
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(intensity_multiplier, "Intensity Multiplier", "", 0, 2, 1);
#include "used_float.fxh"

DECLARE_SAMPLER(depth_palette, "Depth Palette", "Depth Palette", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth_palette_strength, "Depth Palette Strength", "", 0, 1, 0.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth_palette_vcoordinate, "Depth Palette vCoordinate", "", 0, 1, 0.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth_palette_near_fade_cutoff, "Depth Palette Near Fade Cutoff", "", 0, 50, 1);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth_palette_near_fade_range, "Depth Intensity Near Fade Range", "", 0, 50, 1);
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth_intensity_falloff_begin, "Depth Intensity Falloff Begin", "", 0, 50, 1);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(depth_intensity_falloff_end, "Depth Intensity Falloff End", "", 0, 50, 20);
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(edge_detect_strength, "Edge Detect Strength", "", 0, 10, 1);
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(edge_detect_color, "Edge Detect Color", "", float3(1,1,1));
#include "used_float3.fxh"

struct s_screen_vertex_output
{
	float4 position:                            SV_Position;
	float2 texcoord:                            TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position = float4(input.position.xy, 1.0, 1.0);
#if defined(pc) && (DX_VERSION == 9)
	output.texcoord = input.texcoord;
#else
	output.texcoord = input.texcoord * vs_texture_size.xy + vs_texture_size.zw;
#endif
	return output;
}

float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	float2 pixel_coordinates = input.texcoord;
	
	float plasmaValue;
	float plasmaEdgeValue;
	
	ApplyPlasmaWarping(pixel_coordinates, plasmaValue, plasmaEdgeValue);
	pixel_coordinates = input.texcoord; // don't want to warp it here, not cleaning up since we're changing this shader a ton right now
		
	// get color and depth at this screen coord
	// remember that depth isn't linear if that is important to you
	float3 color0;
	float depth;
	float3 normal;
	sampleFramebuffer(pixel_coordinates, color0, depth);
	float depthPx, depthNx, depthPy, depthNy;
	sampleDepth(pixel_coordinates + float2(1, 0), depthPx);
	sampleDepth(pixel_coordinates + float2(-1, 0), depthNx);
	sampleDepth(pixel_coordinates + float2(0, 1), depthPy);
	sampleDepth(pixel_coordinates + float2(0, -1), depthNy);
	float4 laplacianX = max(depthPx + depthNx - 2 * depth, 0);
	float4 laplacianY = max(depthPy + depthNy - 2 * depth, 0);
	float depthLaplacian = edge_detect_strength * sqrt(laplacianX * laplacianX + laplacianY * laplacianY); // arbitrary scale
	
	// albedo intensity can be all over the board, so we may smooth it a bit
	float intensity = length(color0 * 8 / sqrt(3));
	float notTooDarkConstant = saturate(intensity * 10); // careful not to normalize black pixels
	float3 smoothedColor = lerp(color0, color0 * (desired_intensity / intensity), notTooDarkConstant);
	smoothedColor = lerp(color0, smoothedColor, intensity_smoothing_strength);
	
	float depthIntensityFalloff = saturate((depth_intensity_falloff_end - depth) / (depth_intensity_falloff_end - depth_intensity_falloff_begin));
	
	float depthPaletteCoordinate = (depth - depth_palette_near_fade_cutoff) / (depth_intensity_falloff_end - depth_palette_near_fade_cutoff);
	float depthPaletteStrength = depth_palette_strength * saturate((depth - depth_palette_near_fade_cutoff) / depth_palette_near_fade_range);
	float2 uvDepth = transform_texcoord(float2(depthPaletteCoordinate, depth_palette_vcoordinate), depth_palette_transform);
	float3 depthPaletteColor = sample2D(depth_palette, uvDepth).rgb;
	smoothedColor = lerp(smoothedColor, depthPaletteColor, depthPaletteStrength);
		
	float3 outColor = smoothedColor * intensity_multiplier * depthIntensityFalloff * plasmaValue + depthLaplacian * edge_detect_color * depthIntensityFalloff * plasmaEdgeValue * plasmaEdgeValue;
	
	return float4(outColor,1);
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

