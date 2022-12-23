//
// File:	 surface_hard_light.fx
// Author:	 willclar
// Date:	 2/21/2012
//
// Hard Light FX Shader
//
// Copyright (c) 343 Industries. All rights reserved.
//
//
#define DISABLE_TANGENT_FRAME
#define ENABLE_DEPTH_INTERPOLATER

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"
#include "fx/blend_modes.fxh"
#include "fx/fx_parameters.fxh"
#include "fx/fx_functions.fxh"


#include "depth_fade.fxh"

// Texture Samplers
DECLARE_SAMPLER(base_map, "Base Map", "Base Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(fx_map_a, "FX Map A", "FX Map A", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(fx_map_b, "FX Map B", "FX Map B", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(palette_map, "Palette Map", "Palette Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(distortion_strength, "Distortion Strength", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fx_map_blend, "FX Map Blend", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(palette_v_coord, "Palette V Coord", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(use_depth_fade_as_power_minimum, "Use depth fade as power minimum", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_BOOL_WITH_DEFAULT(use_depth_fade_as_power, "Use depth fade as power", "", false);
#include "next_bool_parameter.fxh"
DECLARE_FLOAT_WITH_DEFAULT(intensity, "Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_multiplier, "Alpha Multiplier", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_black_point, "Alpha Black Point", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_white_point, "Alpha White Point", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_BOOL_WITH_DEFAULT(add_blue_to_base, "Add blue channel to base map", "", true);
#include "next_bool_parameter.fxh"

DECLARE_FLOAT_WITH_DEFAULT(depth_based_color_strength, "Depth-Based Color Strength", "", 0, 0.1, float(0.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(depth_based_color, "Depth-Based Color", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(edge_fade_cutoff_dot_prod, "Edge Fade Cutoff Dot Product", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edge_fade_range, "Edge Fade Range", "", 0.000001, 1, float(0.000001));
#include "used_float.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	
	float depthFade = 1.0f;

#if defined(xenon) || (DX_VERSION == 11)
	// this bad boy can be run in opaque, in which case we don't have depth constants set up; so we need to be able to fully
	// "turn off" depth fade, rather than just hoping the setting makes it have no effect
	if (DepthFadeRange > 0.0f)
	{
		float2 vPos = shader_data.common.platform_input.fragment_position.xy;
		depthFade = ComputeDepthFade(vPos * psDepthConstants.z, pixel_shader_input.view_vector.w); // stored depth in the view_vector w
	}
#endif

	float4 fxMapASample = sample2DGamma(fx_map_a, transform_texcoord(uv, fx_map_a_transform));
	float4 fxMapBSample = sample2DGamma(fx_map_b, transform_texcoord(uv, fx_map_b_transform));

	float4 fxMapValue = fxMapASample * fxMapBSample;
	float2 uvDistort = (sqrt(fxMapValue.rg) - 0.5f) * distortion_strength;

	// Sample base map
	float4 base = sample2DGamma(base_map, transform_texcoord(uv, base_map_transform) + uvDistort);
	//base.rgb = (base.rgb * fxMapValue.b) + (fxMapValue.a * fx_map_blend);
	//base.rgb += fxMapValue.a * fx_map_blend;
	if (add_blue_to_base) {
		base.rgb = lerp(fxMapValue.a * fx_map_blend, base.rgb + fxMapValue.b, base.r);
	} else{
		base.rgb = lerp(fxMapValue.a * fx_map_blend, base.rgb * fxMapValue.b, base.r);
	}
	//base.rgb = lerp(fxMapValue.a * fx_map_blend, base.rgb * fxMapValue.b, base.r);
	float2 paletteCoord = float2(base.r, palette_v_coord);
	if (use_depth_fade_as_power)
	{
		paletteCoord.x = pow(paletteCoord.x, max(use_depth_fade_as_power_minimum, depthFade));
	}
	float4 paletteValue = sample2DGamma(palette_map, paletteCoord);

	paletteValue.rgb = lerp(paletteValue.rgb, depth_based_color, saturate(depth_based_color_strength * pixel_shader_input.view_vector.w));

	// composite
	shader_data.common.albedo = float4(paletteValue.rgb * intensity, base.a * alpha_multiplier);
	shader_data.common.albedo.a = ApplyBlackPointAndWhitePoint(alpha_black_point, alpha_white_point, saturate(shader_data.common.albedo.a));
	shader_data.common.albedo.a *= 1.0 - shader_data.common.vertexColor.a;

	shader_data.common.selfIllumIntensity = intensity;

	// input from s_shader_data
	float4 albedo = shader_data.common.albedo;

	float3 view = -shader_data.common.view_dir_distance.xyz;
	float vdotn = saturate(abs(dot(view, pixel_shader_input.normal)));
	albedo.a *= saturate((vdotn - edge_fade_cutoff_dot_prod) / edge_fade_range);

        albedo *= depthFade;
}

// lighting
float4 pixel_lighting(in s_pixel_shader_input pixel_shader_input, inout s_shader_data shader_data)
{
	return shader_data.common.albedo;
}

#include "techniques.fxh"
