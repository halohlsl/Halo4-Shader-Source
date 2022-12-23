//
// File:	 srf_special_cavern_rock.fx
// Author:	 hcoulby, inyang
//
// Surface Shader - srf_env_M30_rock.fx variation for ff153_cavern
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
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
DECLARE_SAMPLER_NO_TRANSFORM( layer0_spec_map, "Layer0 Specular", "Layer1 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( layer0_normal1_map, "Layer0 Normal 1", "Layer0 Normal 1", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

//second normal
#if defined(USE_SECOND_NORMAL)
	DECLARE_SAMPLER_NO_TRANSFORM(layer0_normal2_map, "Layer0 Normal 2", "Layer0 Normal 2", "shaders/default_bitmaps/bitmaps/default_normal.tif");
	#include "next_texture.fxh"
#endif

// cavity occlusion map
#if defined(OCCLUSION_MAP)
	DECLARE_SAMPLER_NO_TRANSFORM( occ_map, "Cavity-Occlusion Map ", "Cavity-Occlusion Map", "shaders/default_bitmaps/bitmaps/default_add_occ.tif")
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(cavity_value,	"Cavity Value", "", 0, 1, float(2.0));
	#include "used_float.fxh"
#endif


DECLARE_FLOAT_WITH_DEFAULT(layer1_use_uv2,	"Layer1 Use Uv2", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_SAMPLER( layer1_color_map, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( layer1_spec_map, "Layer1 Specular", "Layer1 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( layer1_normal_map, "Layer1 Normal", "Layer1 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_color_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_specular_tint,	"Layer0 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_specular_itensity,	"Layer0 Spec Itensity", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_specular_pow,	"Layer0 Spec Pow", "", 0, 1, float(100));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_color_tint,	"Layer1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_specular_tint,	"Layer1 Spec Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_specular_itensity,	"Layer1 Spec Itensity", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_specular_pow,	"Layer1 Spec Pow", "", 0, 1, float(100));
#include "used_float.fxh"


DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_min,"Height Threshold", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_threshold_max,"Height Threshold Soften", "", 1, 100, float(1.0));
#include "used_float.fxh"

#if defined(UV_DISTORTION_MAP)
DECLARE_SAMPLER(uv_distortion_map, "UV Distortion Map", "UV Distortion Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(distortion_strength,"Distortion Strength", "", 1, 10, float(1.0));
#include "used_float.fxh"
#endif

#if defined(REFLECTION)
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
#endif


struct s_shader_data {
	s_common_shader_data common;
	#if defined(UV_DISTORTION_MAP)
		float2 dudv_map;
	#endif
	
	float3 specular_map_color;
};




/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;
	float2 uv2 		= lerp(uv, pixel_shader_input.texcoord.zw, layer1_use_uv2);
	

    float blend = shader_data.common.vertexColor.a;

	// Layer 0
    float2 layer0_uv	   = uv * layer0_color_map_transform.xy;
    float4 layer0_color    = sample2DGamma(layer0_color_map, layer0_uv);
	float3 layer0_normal   = sample_2d_normal_approx(layer0_normal1_map, layer0_uv);
	float3 layer0_spec     = sample2DGamma(layer0_spec_map, layer0_uv).r; 
	layer0_color.rgb *= layer0_color_tint;

	#if defined(OCCLUSION_MAP)
		// apply cavity and occlusion map with no transformation to layer 0
		float2 occ_map_sampled = sample2DGamma(occ_map, uv).rg;
		layer0_color.rgb += ((layer0_color.rgb * cavity_value) * occ_map_sampled.r) * occ_map_sampled.g;
	#endif


    // Layer 1
    float2 layer1_uv     = uv2 * layer1_color_map_transform.xy;
    
	#if defined(UV_DISTORTION_MAP)
		float2 dudv = sample2D(uv_distortion_map, uv2 * uv_distortion_map_transform.xy).rg;
		shader_data.dudv_map = dudv * distortion_strength;
		layer1_uv += shader_data.dudv_map;
	#endif
		
	float4 layer1_color  = sample2DGamma(layer1_color_map, layer1_uv);
	float3 layer1_normal = sample_2d_normal_approx(layer1_normal_map, layer1_uv);
	float  layer1_spec	 = sample2DGamma(layer1_spec_map, layer1_uv).g;	
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

	#if defined(USE_SECOND_NORMAL)
		float3 layer0_normal2 = sample_2d_normal_approx(layer0_normal2_map, uv);
		layer0_normal2 *= layer0_normal_mask;
		composite_normal.xy += layer0_normal2.xy;
	#endif

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

		#if defined(SPECULAR_BLINN)
			calc_specular_blinn(specular, shader_data.common, normal, 1.0, specular_power);
		#else
			calc_specular_phong(specular, shader_data.common, normal, 1.0, specular_power);
		#endif
		
		float3 specular_tint_color = lerp(layer0_specular_tint * layer0_specular_itensity, 
										  layer1_specular_tint * layer1_specular_itensity, layer1_mask);
									 
		specular *= shader_data.specular_map_color * specular_tint_color;
    }


	// reflection	
	float3 reflection = 0.0f;
	#if defined(REFLECTION)
		if (AllowReflection(shader_data.common))
		{
			// sample reflection
			float3 view = shader_data.common.view_dir_distance.xyz;
			float3 rVec = reflect(view, shader_data.common.normal);

			#if defined(UV_DISTORTION_MAP)
				rVec.xy += shader_data.dudv_map;
			#endif

			float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

			reflection =
				reflectionMap.rgb *							// reflection cube sample
				reflection_color *							// RGB reflection color from material
				reflection_intensity *
				diffuse *									// diffuse lighting mask total reflection
				layer1_mask *								// only valid on layer 1
				reflectionMap.a;							// intensity scalar from reflection cube
		}
	#endif
	
	
    // Finalize output color
    float4 out_color;
    out_color.rgb = (albedo.rgb * diffuse) + specular + reflection;
    out_color.a   = 1.0f;
	
	
    return out_color;
}


#include "techniques.fxh"