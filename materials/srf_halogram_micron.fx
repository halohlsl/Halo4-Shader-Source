//
// File:	 srf_micron_halogram.fx
// Author:	 micron
// Date:	 10/30/11
//
// Surface Shader - Halogram - Generic
//
// Copyright (c) 343 Industries. All rights reserved.
//
//
//

// Libraries
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( maskA, "Mask A", "Mask A", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( maskB, "Mask B", "Mask B", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity, "Diffuse Intensity", "", 0, 5, float(1.0));
#include "used_float.fxh"

// Parameters
DECLARE_FLOAT_WITH_DEFAULT(maskASlideU, "Mask A Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskASlideV, "Mask A Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskBSlideU, "Mask B Slide U", "", -5, 5, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(maskBSlideV, "Mask B Slide V", "", -5, 5, float(0.0));
#include "used_float.fxh"

#define ps_hologram_screen_left		ps_material_generic_parameters[0]
#define ps_hologram_screen_right	ps_material_generic_parameters[1]
#define ps_hologram_screen_top		ps_material_generic_parameters[2]
#define ps_hologram_screen_bottom	ps_material_generic_parameters[3]

struct s_shader_data {
	s_common_shader_data common;
	SCREEN_POSITION_INPUT(vPos);
};

// pre lighting
void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	inout s_shader_data shader_data)
{
	float dif_int = diffuse_intensity;
	float4 out_color = shader_data.common.albedo;

	out_color.rgb *= dif_int;
	out_color.rgb *= albedo_tint;

	shader_data.common.albedo = out_color;

	out_color.a *= sample2D(maskA, transform_texcoord(shader_data.vPos, maskA_transform) + (float2(maskASlideU, maskASlideV) * ps_time.x)).r;
	out_color.a *= sample2D(maskB, transform_texcoord(shader_data.vPos, maskB_transform) + (float2(maskBSlideU, maskBSlideV) * ps_time.x)).r;
	out_color.rgb *= out_color.a;

	return out_color;
}

//post
//float4 default_ps(in s_shader_data shader_data) : SV_Target0
//{
//	float4 result = shader_data.common.albedo;
//	result.a *= sample2D(maskA, transform_texcoord(shader_data.vPos*6.0f, maskA_transform) + (float2(maskASlideU, maskASlideV) * ps_time.x)).r;
//	result.a *= sample2D(maskB, transform_texcoord(shader_data.vPos*6.0f, maskB_transform) + (float2(maskBSlideU, maskBSlideV) * ps_time.x)).r;
//	result.rgb *= result.a;
//	result.b += 1.0f;
//	return result;
//}


#include "techniques.fxh"
