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
DECLARE_SAMPLER( selection_mask_map, "Selection Mask", "Selection Mask", "shaders/default_bitmaps/bitmaps/color_black.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(selection_mask_index, "Selection Mask Index", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(selection_color,"Selection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(selection_color_itensity, "Selection Color Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"



// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(diffuse_color,"Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(self_illum_itensity, "Self Illum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


DECLARE_SAMPLER(screen_space_mask_1, "Screen-Space Mask 1", "Screen-Space Mask 1", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(screen_space_mask_2, "Screen-Space Mask 2", "Screen-Space Mask 2", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(screen_space_mask_3, "Screen-Space Mask 3", "Screen-Space Mask 3", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"


DECLARE_FLOAT_WITH_DEFAULT(ssm1_amount, "ssm1_amount", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(ssm2_amount, "ssm2_amount", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ssm3_white, "ssm3_white", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(ssm3_amount, "ssm3_amount", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_BOOL_WITH_DEFAULT(multiply, "Multiply Effects", "", false);
#include "next_bool_parameter.fxh"


struct s_shader_data {
	s_common_shader_data common;
 };


float SampleScreenSpace(texture_sampler_2d map, float4 transform, in s_shader_data shader_data)
{
#if defined(xenon) || (DX_VERSION == 11)
	return sample2D(map, transform_texcoord(shader_data.common.platform_input.fragment_position.xy / 1000.0, transform)).r;
#else // defined(xenon)
	return 1;
#endif // defined(xenon)
}


// pre lighting
void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
	
	// noise and scrolling additve scanlines
	float ssMask1 = SampleScreenSpace(screen_space_mask_1, screen_space_mask_1_transform, shader_data);
	float ssMask2 = SampleScreenSpace(screen_space_mask_2, screen_space_mask_2_transform, shader_data);
	ssMask1 *= ssm1_amount;
	ssMask2 *= ssm2_amount;

	shader_data.common.shaderValues.x = ssMask1 + ssMask2;

	// static fixed scanlines, black white mask
	float ssMask3 = SampleScreenSpace(screen_space_mask_3, screen_space_mask_3_transform, shader_data);
	ssMask3 = saturate(ssMask3 + ssm3_white) * ssm3_amount;
	
	shader_data.common.shaderValues.x *= ssMask3 * shader_data.common.albedo.a;

}



// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	inout s_shader_data shader_data)
{

	float4 out_color = 1.0;

	// composite 
	float4 selection_mask = sample2D(selection_mask_map, pixel_shader_input.texcoord.xy);	
	float selMaskArray[5] = {0.0f, selection_mask.r, selection_mask.g, selection_mask.b, selection_mask.a};
	float selectedMask = selMaskArray[floor(selection_mask_index*5)];
	
	float3 selColor = selection_color * selection_color_itensity * selectedMask;	
	float3 difColor = shader_data.common.albedo.rgb * diffuse_color * self_illum_itensity;
	out_color.rgb = ColorScreenExtendedRange(difColor, selColor);	
	
	float3 bloom = 	out_color.rgb * (1-shader_data.common.albedo.a);	
	out_color.rgb *= shader_data.common.shaderValues.x;
	out_color.rgb += bloom;
	
	// Output self-illum intensity as linear luminance of the added value
	if (AllowSelfIllum(shader_data.common)) {
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(out_color.rgb);
	}
	
	return out_color;
}

#include "techniques.fxh"


