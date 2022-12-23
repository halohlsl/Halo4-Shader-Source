// hcoulby 4/30/2011
// character hair shader with ansio lighting
// Copyright (c) 343 Industries. All rights reserved.
 
// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"


// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

#if defined(NORMALMAP)
	DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
	#include "next_texture.fxh"
#endif

DECLARE_SAMPLER( control_map_hair, "Control Map Hair", "Control Map Hair", "shaders/default_bitmaps/bitmaps/default_hair_diff.tif")
#include "next_texture.fxh"


// Albedo
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity, "Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power,	"Specular Power ", "", 0, 1, float(200));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_shift,	"Specular Shift", "", -1, 1, float(-0.45));
#include "used_float.fxh"

#if defined(HAIR_SPECULAR_TWO)
	DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color_2,	"Specular Color 2", "", float3(1,1,1));
	#include "used_float3.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(specular_intensity_2, "Specular Intensity 2", "", 0, 1, float(1.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(specular_power_2,	"Specular Power 2 ", "", 0, 1, float(10));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(specular_shift_2,	"Specular Shift 2", "", -1, 1, float(-0.45));
	#include "used_float.fxh"
#endif

static const float clip_threshold = 240.0f / 255.0f;

float3 shiftVector( float3 dirVector, float3 normal, float amount)
{
	float3 shifted = dirVector + amount * normal;
	return normalize(shifted);
}


struct s_shader_data {
	s_common_shader_data common;
	float alpha;
};




void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
		
//#### ALBEDO
	float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
	shader_data.common.shaderValues.x = shader_data.common.albedo.a;
	shader_data.alpha = shader_data.common.albedo.a; // store the alpha value away in case we need to premultiply with it later
	shader_data.common.albedo.rgb *= albedo_tint;
	shader_data.common.albedo.a = 1.0;
		
//#### NORMAL

#if defined(NORMALMAP)
	// Sample normal maps
	float2 normal_uv    = transform_texcoord(uv, normal_map_transform);
	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_uv);
	// Transform from tangent space to world space
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
#else
	shader_data.common.normal =	shader_data.common.tangent_frame[2];
#endif

	// Tex kill non-opaque pixels in albedo pass; tex kill opaque pixels in all other passes
	clip((shader_data.common.shaderValues.x - clip_threshold) * ps_material_blend_constant.w); // The blend constant chooses whether we clip anything that is less than white in the alpha or anything larger than near-white (flipped)
}




float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	//..  Output Color
    float4 out_color = 1.0;
	
	
// Control Map for Specular, Gloss, Reflection , SelfIllum
	float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_hair_transform);
	float4 control_mask		= sample2DGamma(control_map_hair, control_map_uv);
	
	
//!-- Diffuse Lighting
    float3 diffuse = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
	float3 diffuse_mask = diffuse;
	diffuse *= diffuse_intensity;

//!-- Specular Lighting				
    float3 specular_1 = 0.0f;
	float3 specular_2 = 0.0f;

	
	#if defined(NORMALMAP)
		// compute a new binromal incorporating the user defined normal map
		float3 T	= cross(shader_data.common.tangent_frame[1], shader_data.common.normal);
		float3 B	= cross(shader_data.common.normal,T);
		B *= sign(dot(B, shader_data.common.tangent_frame[1]));
	#else
		// use the binormal straight off the obj
		float3 B = shader_data.common.tangent_frame[1];
	#endif

	// flipping the binormal in maya to align with engine results
	#if defined(cgfx)
		B = -B;
	#endif
	
	// first layer specular
	float3 dirVector1 = shiftVector(B, shader_data.common.normal, specular_shift + control_mask.b);
	calc_specular_hair(specular_1, shader_data.common, dirVector1, shader_data.common.albedo.a, specular_power);	
	specular_1 *= specular_color * specular_intensity * control_mask.r;
	
	
	//  second layer with noise texture
	#if defined(HAIR_SPECULAR_TWO)
		float3 dirVector2 = shiftVector(B, shader_data.common.normal, specular_shift_2 + control_mask.b);
		calc_specular_hair(specular_2, shader_data.common, dirVector2, shader_data.common.albedo.a, specular_power_2);	
		specular_2 *= specular_color_2 * specular_intensity_2 * control_mask.g;
	#endif

	
	float3 specular = (specular_1 + specular_2) * diffuse_mask;
	

	out_color.rgb = (diffuse + specular) * shader_data.common.albedo.rgb;
	out_color.a    = shader_data.common.shaderValues.x;
	
	// If it's a dynamic lighting pass, we'll have to pre-multiply the alpha in, because the dynamic lighting entrypoint zeroes out alpha as an optimization
	if (shader_data.common.shaderPass == SP_DYNAMIC_LIGHTING) 
	{
		out_color.rgb *= shader_data.alpha;
	}

	return out_color;
}


#define REQUIRE_SPOTLIGHT_TRANSPARENT // make sure we compile to the transparent spotlight entrypoint
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_lightable_transparent = true; bool is_alpha_clip = true;>

#include "techniques.fxh"
