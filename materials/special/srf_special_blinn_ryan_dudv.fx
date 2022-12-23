//
// File:	 srf_special_cavern_rock_blinn_reflection_dudc.fx
// Author:	 hcoulby
//
// Surface Shader - special variation of a blinn vert alpha shader with DuDv distortion map; requested by ryan peterson
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"


//... Base Layer
//
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(uv_distortion_map, "UV Distortion Map", "UV Distortion Map", "shaders/default_bitmaps/bitmaps/color_black.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(color_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_tint,	"Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_itensity,	"Spec Intensity", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_pow,	"Spec Pow", "", 0, 1, float(100));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(distortion_strength,"Distortion Strength", "", 0, 2, float(0.25));
#include "used_float.fxh"





struct s_shader_data {
	s_common_shader_data common;
};




/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	// DuDv | distortion map
	float2 distortionuv = transform_texcoord(pixel_shader_input.texcoord.xy, uv_distortion_map_transform);
    float2 dudv = sample2D(uv_distortion_map, distortionuv).rg;
	dudv *= distortion_strength;
	
    float2 uv = pixel_shader_input.texcoord.xy;
	uv += dudv;
	
	// pass along the distortion coords to the pixel shader
	shader_data.common.shaderValues.x = uv.x;
	shader_data.common.shaderValues.y = uv.y;
	
	
	float2 color_uv = transform_texcoord(uv, color_map_transform);
    float4 color    = sample2DGamma(color_map, color_uv);

	shader_data.common.albedo.rgb = color * color_tint;
	shader_data.common.albedo.a   = 1.0;
	
	float2 normal_uv = transform_texcoord(uv, normal_map_transform);
	float3 normal   = sample_2d_normal_approx(normal_map, color_uv);

    shader_data.common.normal = mul(normal, shader_data.common.tangent_frame);

}


/// Pixel Shader - Lighting Pass

float4 pixel_lighting(
    in s_pixel_shader_input pixel_shader_input,
    inout s_shader_data shader_data)
{

    // Input from albedo pass
    float4 albedo		= shader_data.common.albedo;
    float3 normal		= shader_data.common.normal;
	float2 dudv			= float2(shader_data.common.shaderValues.x, shader_data.common.shaderValues.y);
	
	// Calculate diffuse lighting contribution
    float3 diffuse = 1.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, normal);
	diffuse *= albedo.rgb;
	
	
	
    // Calculate specular lighting contribution
    float3 specular = 0.0f;
	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, specular_pow);	
	
	float2 specular_uv = transform_texcoord(dudv, specular_map_transform);
	specular *= sample2DGamma(specular_map, specular_uv) * specular_tint * specular_itensity;

	

	// reflection	
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view, shader_data.common.normal);

		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *
			reflectionMap.a;							// intensity scalar from reflection cube
	}


    // Finalize output color
    float4 out_color;
    out_color.rgb = diffuse + specular + reflection;
    out_color.a   = saturate(shader_data.common.vertexColor.a);
	
	return out_color;
}


#include "techniques.fxh"