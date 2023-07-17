//
// File:	 srf_constant_meter.fx
// Author:	 aluedke
// Date:	 01/06/12
//
// Surface Shader - Constant with 'meter' self-illum
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// No lighting needed for constant shader
#define DISABLE_SH
#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME


#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER(color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(meter_map, "Meter Map", "Meter Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

// Constant color tint and intensity
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Constant Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Constant Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Meter colors and value
DECLARE_RGB_COLOR_WITH_DEFAULT(meter_color_off,	"Meter Color (off)", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(meter_color_on,	"Meter Color (on)", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(meter_value,			"Meter Value", "", 0, 1, float(0.5));
#include "used_float.fxh"


struct s_shader_data
{
	s_common_shader_data common;
    float3 self_illum;
    float alpha;
};



float3 CalcMeterSelfIllumination(
	in float4 meterMapSample)
{
	return (meterMapSample.x >= 0.5f)
		? (meter_value >= meterMapSample.w)
			? meter_color_on.xyz
			: meter_color_off.xyz
		: float3(0,0,0);
}



void pixel_pre_lighting(
	in s_pixel_shader_input pixel_shader_input,
	inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;

	// Get the base color and tint
    {
	    float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
        shader_data.alpha = shader_data.common.albedo.a;

		shader_data.common.albedo.rgb *= albedo_tint.rgb;
		shader_data.common.albedo.a = shader_data.alpha;
	}

	// Set the 'meter' value into the self_illum value
    {
		float2 meter_map_uv = transform_texcoord(uv, meter_map_transform);
		float4 meterMapSample = sample2DGamma(meter_map, meter_map_uv);
		shader_data.self_illum = CalcMeterSelfIllumination(meterMapSample);
    }
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
	// Finalize Output Color
	float4 out_color = float4(0.0f, 0.0f, 0.0f, shader_data.alpha);

	// Constant color
	if (AllowSelfIllum(shader_data.common))
	{
		out_color.rgb += shader_data.common.albedo.rgb * diffuse_intensity;
	}

	// Meter
    if (AllowSelfIllum(shader_data.common))
    {
		// Add the meter value
		out_color.rgb += shader_data.self_illum;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(shader_data.self_illum);
	}

	return out_color;
}


#include "techniques.fxh"

