//
// File:	 srf_special_lava_scurve.fx
// Author:	 v-inyang
// Date:	 02/22/2012
//
// Surface Shader - lava for halp4 MP map Scurve
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader
#define DISABLE_SH

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER( color_map, "Big Crust Map", "Big Crust Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( color1_map, "Small Crust Map", "Small Crust Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"


DECLARE_SAMPLER( selfillum_map, "Lava Map", "Lava Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( distortion1_map, "Lava Distortion Map1", "Lava Distortion Map1", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( distortion2_map, "Lava Distortion Map2", "Lava Distortion Map2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"



// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Crust Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Crust Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(bigcrust_contrast,	"Big Crust Mask Contrast", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(smallcrust_contrast,	"Small Crust Mask Contrast", "", 0, 10, float(1.0));
#include "used_float.fxh"


// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"Lava Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"Lava Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_contrast,	"Lava contrast", "", 0, 1, float(1.0));
#include "used_float.fxh"







DECLARE_BOOL_WITH_DEFAULT(wireframe_outline, "Wireframe Outline", "", false);
#include "next_bool_parameter.fxh"

struct s_shader_data
{
	s_common_shader_data common;
    float3 self_illum;
    float alpha;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;
	shader_data.common.albedo.rgb = float4(0,0,0,1);

	
    // Sample Crust map(color map)
	    float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
	    float4 bigcrust = sample2DGamma(color_map, color_map_uv);
		
		float2 color1_map_uv 	  = transform_texcoord(uv, color1_map_transform);
	    float4 smallcrust = sample2DGamma(color1_map, color1_map_uv);
		
		float3 crust_color = bigcrust.xyz * smallcrust.xyz;
		crust_color *= albedo_tint.rgb;
		
	//Calculate Crust map Mask
		float bigcrust_mask =( bigcrust.r - 0.5 ) * bigcrust_contrast + 0.5; //add contrast
		float smallcrust_mask =( smallcrust.r - 0.5 ) * smallcrust_contrast + 0.5; //add contrast
		float crust_mask = saturate(  1 - ( bigcrust_mask + smallcrust_mask ) );
		crust_mask *= diffuse_intensity;
		
	
    // Generate Distortion UVs for Lava map
	    float2 distortion1_map_uv 	  = transform_texcoord(uv, distortion1_map_transform);
	    float d1 = sample2DGamma(distortion1_map, distortion1_map_uv).z;

		float2 distortion2_map_uv 	  = transform_texcoord(uv, distortion2_map_transform);
	    float d2 = sample2DGamma(distortion2_map, distortion2_map_uv).z;
		
		float2 distortion_uv = float2(d1, d2);
		
		
	// sample Lava map (self illum map)
    if (AllowSelfIllum(shader_data.common))
    {
		float2 si_map_uv = transform_texcoord(uv, selfillum_map_transform);
		si_map_uv += distortion_uv;

	    float3 self_illum = sample2DGamma(selfillum_map, si_map_uv).rgb;
		self_illum = pow(self_illum, si_contrast);
        self_illum *= si_color * si_intensity;
		
		// output to pixel shader final color
		shader_data.common.albedo.rgb = lerp( self_illum, crust_color, crust_mask );
		
		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(self_illum);
	}	

}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
#if defined(xenon)
	if (wireframe_outline)
	{
		pixel_pre_lighting(pixel_shader_input, shader_data);
	}
#endif

     //.. Output Color from albedo pass
	float4 out_color = shader_data.common.albedo;
	return out_color;
}


#include "techniques.fxh"
