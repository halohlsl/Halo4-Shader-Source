//
// File:	 srf_ca_special_highrise_floor.fx
// Author:	 v-danval
// Date:	 01/9/13
//
// Copyright (c) 343 Industries. All rights reserved.
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters
//... Blend Map
DECLARE_SAMPLER( blend_map, "Blend Map RGB", "Blend Map RGB", "shaders/default_bitmaps/bitmaps/blendmaprgb_control.tif");
#include "next_texture.fxh"


//... Base Maps
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif");
#include "next_texture.fxh"

//Color Detail map that is applied to ALL layers.
DECLARE_SAMPLER(all_layers_color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_alpha_mask_specular, "Detail Alpha Masks Spec", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_alpha_mask_reflection, "Detail Alpha Masks Spec", "", 0, 1, float(0.0));
#include "used_float.fxh"

//Detail Normal
DECLARE_SAMPLER( normal_detail_map, "Detail Normal", "Detail Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT( normal_detail_dist_max,	"Detail Start Dist.", "Detail Start Dist.", 0, 1 , float( 5.0 ));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( normal_detail_dist_min, 	"Detail End Dist.", "Detail End Dist.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"

DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif");
#include "next_texture.fxh"

//Layer Tints
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_co_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_co_tint,	"Layer1 Tint", "", float3(1,0,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer2_co_tint,	"Layer2 Tint", "", float3(0,1,0));
#include "used_float3.fxh"

//Specular control
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_normal,		"Specular Normal", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( specular_use_diffuse, 	"Specular Use Diffuse.", "Layer0 Specular Use Diffuse.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"

//Layer Specular Colors
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_specular_color,		"Layer0 Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_specular_color,		"Layer1 Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer2_specular_color,		"Layer2 Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"


//Reflection control
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,	"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_normal,		"Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"
// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,			"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

//Layer Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_reflection_color,	"Layer 0 Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_reflection_color,	"Layer 1 Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer2_reflection_color,	"Layer 2 Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"



struct s_shader_data {
    s_common_shader_data common;

};

/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;

    //----------------------------------------------
    // Sample blend and cloud maps
    //----------------------------------------------
	float2 blend_map_uv = pixel_shader_input.texcoord.zw;

	float4 blend    	= sample2D(blend_map, transform_texcoord(blend_map_uv, blend_map_transform));


    //----------------------------------------------
    // Sample layer
    //----------------------------------------------
    float4 layer0_color = sample2DGamma(color_map, transform_texcoord(uv, color_map_transform));
	
	//----------------------------------------------
    // Calculate the normal map value
    //----------------------------------------------
    float3 layer0_normal= sample_2d_normal_approx(normal_map, transform_texcoord(uv, normal_map_transform));
	layer0_normal = CompositeDetailNormalMap(shader_data.common,
												layer0_normal,
												normal_detail_map,
												transform_texcoord(uv, normal_detail_map_transform),
												normal_detail_dist_min,
												normal_detail_dist_max);
	shader_data.common.normal = mul(layer0_normal, shader_data.common.tangent_frame);

    //----------------------------------------------
    // Compute layer masks
    //----------------------------------------------
    float layer1_mask = 1.0;
    layer1_mask = saturate( (blend.r - ( 1 - layer0_color.a )) / ( 1 - min( 0.99, ( blend.b ) ) ) );

    float layer2_mask = 1.0;
    layer2_mask = saturate( (blend.g - ( 1 - layer0_color.a )) / ( 1 - min( 0.99, ( blend.b ) ) ) );
	
    //----------------------------------------------
    // Composite color maps, output albedo
    //----------------------------------------------
    float3 composite_color = 0.0;

	float3 base_color = layer0_color.rgb;
    layer0_color.rgb *= layer0_co_tint;
    float3 layer1_color = base_color * layer1_co_tint;
	float3 layer2_color = base_color * layer2_co_tint;

    composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);
	composite_color = lerp(composite_color, layer2_color.rgb, layer2_mask);

    shader_data.common.albedo.rgb  = composite_color;
    shader_data.common.albedo.a    = 1.0;

    //----------------------------------------------
    // Composite global detail color maps, output albedo
    //----------------------------------------------
	const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)

    float2 all_layers_color_detail_map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, all_layers_color_detail_map_transform);
	float4 color_detail = sample2DGamma(all_layers_color_detail_map, all_layers_color_detail_map_uv);
	color_detail.rgb *= DETAIL_MULTIPLIER;

	shader_data.common.albedo.rgb *= color_detail;


    //----------------------------------------------
    // Output layer blend factors
    //----------------------------------------------
    shader_data.common.shaderValues.x = layer1_mask;
	shader_data.common.shaderValues.y = layer2_mask;
}


/// Pixel Shader - Lighting Pass

float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;

    //----------------------------------------------
    // Input from albedo pass
    //----------------------------------------------
    float4 albedo	= shader_data.common.albedo;
    float3 normal	= shader_data.common.normal;
    float layer1_mask	= shader_data.common.shaderValues.x;
	float layer2_mask	= shader_data.common.shaderValues.y;

    //----------------------------------------------
    // Sample the control map
    //----------------------------------------------
    float4 controlMap = sample2DGamma(control_map_SpGlRf, transform_texcoord(uv, control_map_SpGlRf_transform) );
 
    //----------------------------------------------
    // Composite Spec maps, output spec mask
    //----------------------------------------------
    float4 specular_mask;
	
	float3 specular_color = lerp(layer0_specular_color.rgb, layer1_specular_color.rgb, layer1_mask);
	specular_color = lerp(specular_color, layer2_specular_color.rgb, layer2_mask);
	
	specular_color = lerp( specular_color, albedo, specular_use_diffuse );
	specular_mask.rgb = specular_color * controlMap.r;
    specular_mask.a  = controlMap.g;
 
    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    { // Compute Specular
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max);

		// using phong specular model
	
		float3 sNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, specular_normal);
    	calc_specular_phong(specular, shader_data.common, sNormal, albedo.a, power);

        // modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_intensity;
    }


    //----------------------------------------------
    // Calculate diffuse lighting contribution
    //----------------------------------------------
    float3 diffuse = 1.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, normal);

    //----------------------------------------------
    // Calculate reflected lighting contribution
    //----------------------------------------------
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common))
	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		float3 reflection_color = lerp(layer0_reflection_color.rgb, layer1_reflection_color.rgb, layer1_mask);
		reflection_color = lerp(reflection_color, layer2_reflection_color.rgb, layer2_mask);

		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection
			float  vdotn = saturate(dot(-view, rNormal));
			float tfresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
			fresnel = pow(tfresnel, fresnel_power) * fresnel_intensity;
		}

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			controlMap.b *								// control mask reflection intensity channel
			fresnel *									// fresnel
			reflectionMap.a;							// intensity scalar from reflection cube

		reflection = lerp(reflection, reflection * diffuse, diffuse_mask_reflection);
	}


    //----------------------------------------------
    // Finalize output color
    //----------------------------------------------
    float4 out_color;
    out_color.rgb = (albedo.rgb * diffuse) + specular + reflection;
    out_color.a   = 1.0f;
    return out_color;
}


#include "techniques.fxh"

