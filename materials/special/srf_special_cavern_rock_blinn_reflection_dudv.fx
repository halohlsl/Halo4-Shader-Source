//
// File:	 srf_special_cavern_rock_blinn_reflection_dudc.fx
// Author:	 hcoulby
//
// Surface Shader - special variation based on srf_special_cavern_rock for ryan peterson's "crazy" water duduv needs :)
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"


//....Settings
#define BLENDED_MATERIAL

//... Base Layer
//
// colormap
DECLARE_SAMPLER( layer0_color_map, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_spec_map, "Layer0 Specular", "Layer1 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_normal1_map, "Layer0 Normal 1", "Layer0 Normal 1", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
 
DECLARE_SAMPLER( layer1_color_map, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_color_uv,	"layer1_color_uv", "", 0, 1, float(0));
#include "used_float.fxh"


DECLARE_SAMPLER( layer1_spec_map, "Layer1 Specular", "Layer1 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_normal_map, "Layer1 Normal", "Layer1 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_color_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_specular_tint,	"Layer0 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_specular_itensity,	"Layer0 Spec Itensity", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_specular_pow,	"Layer0 Spec Pow", "", 0, 1, float(100));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_color_tint,	"Layer1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_specular_tint,	"Layer1 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_specular_itensity,	"Layer1 Spec Itensity", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_specular_pow,	"Layer1 Spec Pow", "", 0, 1, float(100));
#include "used_float.fxh"

//DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_min,"Height Threshold", "", 0, 1, float(1.0));
//#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_max,"Height Threshold Soften", "", 1, 100, float(1.0));
#include "used_float.fxh"


DECLARE_SAMPLER(uv_distortion_map, "UV Distortion Map", "UV Distortion Map", "shaders/default_bitmaps/bitmaps/color_black.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distortion_strength,"Distortion Strength", "", 0, 2, float(0.25));
#include "used_float.fxh"


DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;
	float3 specular_map_color;
};




/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

    float blend = shader_data.common.vertexColor.a;

	// Layer 0
    float2 layer0_uv	   = pixel_shader_input.texcoord.xy * layer0_color_map_transform.xy;
    float4 layer0_color    = sample2DGamma(layer0_color_map, layer0_uv);
	float3 layer0_normal   = sample_2d_normal_approx(layer0_normal1_map, layer0_uv);
	float3 layer0_spec     = sample2DGamma(layer0_spec_map, layer0_uv).r; 
	layer0_color.rgb *= layer0_color_tint;

    // Layer 1
	
	// distortion map
	float2 distortionuv = transform_texcoord(pixel_shader_input.texcoord.zw, uv_distortion_map_transform);
    float2 dudv = sample2D(uv_distortion_map, distortionuv).rg;
	dudv *= distortion_strength;

	
	float2 layer1_uv_uvset1 = pixel_shader_input.texcoord.xy + dudv;	
	float2 layer1_uv_uvset2 = pixel_shader_input.texcoord.zw + dudv;	
	
	
	float2 colorUv = lerp(layer1_uv_uvset1, layer1_uv_uvset2, layer1_color_uv);
	colorUv = transform_texcoord(colorUv, layer1_color_map_transform);
	float4 layer1_color  = sample2DGamma(layer1_color_map, colorUv);	
	
	float2 normaluv = transform_texcoord(layer1_uv_uvset2, layer1_normal_map_transform);
    float3 layer1_normal = sample_2d_normal_approx(layer1_normal_map, normaluv);
	
	float2 specuv = transform_texcoord(layer1_uv_uvset2, layer1_spec_map_transform);
	float3 layer1_spec	 = sample2DGamma(layer1_spec_map, specuv);	

	
	layer1_color.rgb *= layer1_color_tint;


    // Compute layer masks
	float height_mask = layer0_color.a;
	float blend_diff  = saturate(blend * (1-blend));
	height_mask *= blend_diff;
	blend -= color_threshold(height_mask, 0, layer1_threshold_max);
	float layer1_mask = saturate(blend);
	
	
	// store mask for use in the lighting shader
	shader_data.common.shaderValues.x = layer1_mask;
	// store specular color from sampled maps
	shader_data.specular_map_color = lerp(layer0_spec, layer1_spec, layer1_mask);
	// Composite color maps, set output albedo 
	shader_data.common.albedo.rgb = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);
    shader_data.common.albedo.a    = 1.0;


    // Composite normal maps, output normal
    float3 composite_normal=float3(1,1,0);

    float layer0_normal_mask = 1-blend;
    layer0_normal *= layer0_normal_mask;
    layer1_normal *= layer1_mask;

    // comp the two normals
    composite_normal.xy = layer0_normal.xy + layer1_normal.xy;

	// recompute z
	composite_normal.z = sqrt(saturate(1.0f + dot(composite_normal.xy, -composite_normal.xy)));		
    // Transform final normal into world space
    shader_data.common.normal = mul(composite_normal, shader_data.common.tangent_frame);

}


/// Pixel Shader - Lighting Pass

float4 pixel_lighting(
    in s_pixel_shader_input pixel_shader_input,
    inout s_shader_data shader_data)
{

    // Input from albedo pass
    float4 albedo		= shader_data.common.albedo;
    float3 normal		= shader_data.common.normal;
	
	float layer1_mask = shader_data.common.shaderValues.x;

	// Calculate diffuse lighting contribution
    float3 diffuse = 1.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, normal);
	
	
    // Calculate specular lighting contribution
    float3 specular = 0.0f;
    {
		float specular_power = lerp(layer0_specular_pow, layer1_specular_pow, layer1_mask);

		calc_specular_blinn(specular, shader_data.common, normal, 1.0, specular_power);
		
		float3 specular_tint_color = lerp(layer0_specular_tint * layer0_specular_itensity, 
										  layer1_specular_tint * layer1_specular_itensity, layer1_mask);
									 
		specular *= shader_data.specular_map_color * specular_tint_color;
    }


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
			diffuse *									// diffuse lighting mask total reflection
			layer1_mask *								// only valid on layer 1
			reflectionMap.a;							// intensity scalar from reflection cube
	}


	
    // Finalize output color
    float4 out_color;
    out_color.rgb = (albedo.rgb * diffuse) + specular + reflection;
    out_color.a   = 1.0f;
	
	
    return out_color;
}


#include "techniques.fxh"