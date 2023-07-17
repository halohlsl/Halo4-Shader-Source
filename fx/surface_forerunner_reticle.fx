//
// File:	 surface_forerunner_reticle.fx
// Author:	 willclar
// Date:	 01/20/2012
//
// Surface FX Shader - Emulates particle_palettized, and allows animated 3D textures
//
// Copyright (c) 343 Industries. All rights reserved.
//
//
#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"

// Texture Samplers
DECLARE_SAMPLER(ring_map, "Ring Map", "Ring Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(alpha_multiplier, "Alpha Multiplier", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(inner_radius, "Inner Radius", "", 0, 1, float(0.7));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(outer_radius, "Outer Radius", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(self_illum_intensity, "Self Illum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 normalizedPosition = 2 * (pixel_shader_input.texcoord.xy - float2(0.5, 0.5));
	float theta = atan2(normalizedPosition.y, normalizedPosition.x) / (2 * pi);
	
	float radius = length(normalizedPosition);
	
	float2 ringCoordinate = float2(theta, (radius - inner_radius) / (outer_radius - inner_radius));
		
	if (ringCoordinate.y > 0 && ringCoordinate.y < 1)
	{
		// obnoxious artifacts with the computed mip levels at the wrap point. Grr
		shader_data.common.albedo = sample2DLOD(ring_map, transform_texcoord(ringCoordinate, ring_map_transform), 0, false);
		shader_data.common.albedo.a *= alpha_multiplier;
	}
	else
	{
		shader_data.common.albedo = float4(0, 0, 0, 0);	
	}
	
	shader_data.common.selfIllumIntensity = self_illum_intensity;
}

// lighting
float4 pixel_lighting(in s_pixel_shader_input pixel_shader_input, inout s_shader_data shader_data)
{
	// input from s_shader_data
	float4 albedo = shader_data.common.albedo;

	//.. Finalize Output Color
	float4 out_color = albedo;
	return out_color;
}

#include "techniques.fxh"
