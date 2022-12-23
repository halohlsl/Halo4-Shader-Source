//
// File:	 srf_layered_two_height_detailnormal_reflection.fx
// Author:	 v-tomau
// Date:	 05/2/12
//
// Copyright (c) 343 Industries. All rights reserved.
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters
//... Blend Map
DECLARE_SAMPLER( blend_map, "Blend Map RGB", "Blend Map RGB", "shaders/default_bitmaps/bitmaps/blendmaprgb_control.tif")
#include "next_texture.fxh"


//... Base Layer
DECLARE_SAMPLER( layer0_coMap, "Layer0 Color", "Layer0 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_nmMap, "Layer0 Normal", "Layer0 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_detailNmMap, "Layer0 Detail Normal", "Layer0 Detail Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_control_map_SpGlRf, "Layer 0 Control Map SpGlRf", "Layer 0 Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_normal_detail_dist_max,	"Layer0 Detail Start Dist.", "Layer0 Detail Start Dist.", 0, 1 , float( 5.0 ));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_normal_detail_dist_min, 	"Layer0 Detail End Dist.", "Layer0 Detail End Dist.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"
#if defined USE_TOP_LAYER_DETAIL_NORMAL
	DECLARE_SAMPLER( layer0_detailNmMap2, "Layer0 Detail Normal 2", "Layer0 Detail Normal 2", "shaders/default_bitmaps/bitmaps/default_normal.tif")
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT( layer0_normal_detail_2_dist_max,	"Layer0 Detail 2 Start Dist.", "Layer0 Detail 2 Start Dist.", 0, 1 , float( 5.0 ));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT( layer0_normal_detail_2_dist_min, 	"Layer0 Detail 2 End Dist.", "Layer0 Detail 2 End Dist.", 0, 1 , float( 1.0 ));
	#include "used_float.fxh"
#endif //USE_TOP_LAYER_DETAIL_NORMAL
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_co_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_specular_color,		"Layer0 Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_specular_use_diffuse, 	"Layer0 Specular Use Diffuse.", "Layer0 Specular Use Diffuse.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_specular_roghness, 	"Layer0 Specular Roughness.", "Layer0 Specular Roughness.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_specular_diff_desaturate,	"Layer0 Diffuse As Specular Desaturate", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_specular_diff_power,		"Layer0 Diffuse As Specular Power", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_specular_diff_scale,		"Layer0 Diffuse As Specular Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer0_specular_diff_offset,		"Layer0 Diffuse As Specular Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_reflection_color,	"Layer 0 Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_reflection_intensity,	"Layer 0 Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_reflection_normal,		"Layer 0 Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(layer0_fresnel_intensity,		"Layer 0 Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_fresnel_power,			"Layer 0 Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer0_fresnel_inv,			"Layer 0 Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

//... Layer1 - Red
DECLARE_SAMPLER( layer1_coMap, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_nmMap, "Layer1 Normal", "Layer1 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_detailNmMap, "Layer1 Detail Normal", "Layer1 Detail Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_control_map_SpGlRf, "Layer 1 Control Map SpGlRf", "Layer 1 Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_normal_detail_dist_max,	"Layer1 Detail Start Dist.", "Layer1 Detail Start Dist.", 0, 1 , float( 5.0 ));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_normal_detail_dist_min, 	"Layer1 Detail End Dist.", "Layer1 Detail End Dist.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_co_tint,	"Layer1 Tint", "", float3(1,0,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_specular_color,		"Layer1 Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_specular_use_diffuse, 	"Layer1 Specular Use Diffuse.", "Layer1 Specular Use Diffuse.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_specular_roghness, 	"Layer1 Specular Roughness.", "Layer1 Specular Roughness.", 0, 1 , float( 1.0 ));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_specular_diff_desaturate,	"Layer1 Diffuse As Specular Desaturate", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_specular_diff_power,		"Layer1 Diffuse As Specular Power", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_specular_diff_scale,		"Layer1 Diffuse As Specular Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( layer1_specular_diff_offset,		"Layer1 Diffuse As Specular Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(layer1_height_influence, "Layer1 Height Map Influence", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_cloud_influence, "Layer1 Cloud Map Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_reflection_color,	"Layer 1 Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_reflection_intensity,	"Layer 1 Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_reflection_normal,		"Layer 1 Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(layer1_fresnel_intensity,		"Layer 1 Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_fresnel_power,			"Layer 1 Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_fresnel_inv,			"Layer 1 Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

// specular control
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"

//Color Detail map that is applied to ALL layers.
DECLARE_SAMPLER(all_layers_color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


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
	float2 blend_map_uv = uv;

	#if defined BLENDMAP_UVSET2
		blend_map_uv = pixel_shader_input.texcoord.zw;
	#endif

	float4 blend		= sample2D(blend_map, blend_map_uv);
	float4 cloud    	= sample2D(blend_map, transform_texcoord(blend_map_uv, blend_map_transform));


    //----------------------------------------------
    // Sample layers
    //----------------------------------------------
    float4 layer0_color = sample2DGamma(layer0_coMap, transform_texcoord(uv, layer0_coMap_transform));
    float3 layer0_normal= sample_2d_normal_approx(layer0_nmMap, transform_texcoord(uv, layer0_nmMap_transform));
	layer0_normal = CompositeDetailNormalMap(shader_data.common,
												layer0_normal,
												layer0_detailNmMap,
												transform_texcoord(uv, layer0_detailNmMap_transform),
												layer0_normal_detail_dist_min,
												layer0_normal_detail_dist_max);
#if defined USE_TOP_LAYER_DETAIL_NORMAL
	layer0_normal = CompositeDetailNormalMap(shader_data.common,
												layer0_normal,
												layer0_detailNmMap2,
												transform_texcoord(uv, layer0_detailNmMap2_transform),
												layer0_normal_detail_2_dist_min,
												layer0_normal_detail_2_dist_max);
#endif


    float4 layer1_color = sample2DGamma(layer1_coMap, transform_texcoord(uv, layer1_coMap_transform));
    float3 layer1_normal= sample_2d_normal_approx(layer1_nmMap, transform_texcoord(uv, layer1_nmMap_transform));
	layer1_normal = CompositeDetailNormalMap(shader_data.common,
												layer1_normal,
												layer1_detailNmMap,
												transform_texcoord(uv, layer1_detailNmMap_transform),
												layer1_normal_detail_dist_min,
												layer1_normal_detail_dist_max);

    //----------------------------------------------
    // Compute layer masks
    //----------------------------------------------
    float layer1_mask = 1.0;
    float cloud_map1 = lerp( 1, cloud.b, layer1_cloud_influence ) ;
    layer1_mask = saturate( (blend.r - ( 1 - layer1_color.a )) / ( 1 - min( 0.99, ( cloud_map1 * shader_data.common.vertexColor.a ) ) ) );
    layer1_mask = lerp(blend.r, layer1_mask, layer1_height_influence);

    //----------------------------------------------
    // Composite color maps, output albedo
    //----------------------------------------------
    float3 composite_color = 0.0;

    layer0_color.rgb *= layer0_co_tint;
    layer1_color.rgb *= layer1_co_tint;

    composite_color = lerp(layer0_color.rgb, layer1_color.rgb, layer1_mask);

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
    // Composite normal maps, output normal
    //----------------------------------------------
    float3 composite_normal;

    composite_normal = lerp(layer0_normal.rgb, layer1_normal.rgb, layer1_mask);
    composite_normal.z = sqrt(saturate(1.0f + dot(composite_normal.xy, -composite_normal.xy)));

    shader_data.common.normal = mul(composite_normal, shader_data.common.tangent_frame);


    //----------------------------------------------
    // Output layer blend factors
    //----------------------------------------------
    shader_data.common.shaderValues.x = layer1_mask;
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

    //----------------------------------------------
    // Sample the control map
    //----------------------------------------------
	float4 layer0_controlMap = sample2DGamma(layer0_control_map_SpGlRf, transform_texcoord(uv, layer0_control_map_SpGlRf_transform) );
	float4 layer1_controlMap = sample2DGamma(layer1_control_map_SpGlRf, transform_texcoord(uv, layer1_control_map_SpGlRf_transform) );
    float4 controlMap = lerp(layer0_controlMap, layer1_controlMap, layer1_mask);
 
    //----------------------------------------------
    // Composite Spec maps, output spec mask
    //----------------------------------------------
    float4 specular_mask;
	float4 layer0_spec = float4( DesaturateGammaColor( sample2DGamma(layer0_coMap, transform_texcoord(uv, layer0_coMap_transform) ), layer0_specular_diff_desaturate ), 1 );
	layer0_spec = saturate( pow( layer0_spec, layer0_specular_diff_power ) * layer0_specular_diff_scale + layer0_specular_diff_offset );
	layer0_spec  = float4( lerp( layer0_specular_color, layer0_spec.rgb, layer0_specular_use_diffuse ), layer0_specular_roghness );
	layer0_spec.rgb *= layer0_controlMap.r;
    layer0_spec.a  = layer0_controlMap.g;    

	float4 layer1_spec = float4( DesaturateGammaColor( sample2DGamma(layer1_coMap, transform_texcoord(uv, layer1_coMap_transform) ), layer1_specular_diff_desaturate ), 1 );
	layer1_spec = saturate( pow( layer1_spec, layer1_specular_diff_power ) * layer1_specular_diff_scale + layer1_specular_diff_offset );
	layer1_spec  = float4( lerp( layer1_specular_color, layer1_spec.rgb, layer1_specular_use_diffuse ), layer1_specular_roghness );
	layer1_spec.rgb *= layer1_controlMap.r;
    layer1_spec.a  = layer1_controlMap.g;    

    specular_mask = lerp(layer0_spec, layer1_spec, layer1_mask);
 
    //----------------------------------------------
    // Calculate specular lighting contribution
    //----------------------------------------------
    float3 specular = 0.0f;
    { // Compute Specular
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max);

	// using phong specular model
    	calc_specular_phong(specular, shader_data.common, normal, albedo.a, power);

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
		float reflection_normal = lerp(layer0_reflection_normal, layer1_reflection_normal, layer1_mask);
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		float3 reflection_color = lerp(layer0_reflection_color, layer1_reflection_color, layer1_mask);
		float reflection_intensity = lerp(layer0_reflection_intensity, layer1_reflection_intensity, layer1_mask);

		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection
			float  vdotn = saturate(dot(-view, rNormal));
			float layer0_fresnel = vdotn + layer0_fresnel_inv - 2 * layer0_fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
			layer0_fresnel = pow(layer0_fresnel, layer0_fresnel_power) * layer0_fresnel_intensity;
			float layer1_fresnel = vdotn + layer1_fresnel_inv - 2 * layer1_fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
			layer1_fresnel = pow(layer1_fresnel, layer1_fresnel_power) * layer1_fresnel_intensity;
			
			fresnel = lerp(layer0_fresnel, layer1_fresnel, layer1_mask);
		}

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			controlMap.b *							// control mask reflection intensity channel
			fresnel *									// fresnel
			reflectionMap.a;							// intensity scalar from reflection cube

		reflection = lerp(reflection, reflection * diffuse, lerp(layer0_diffuse_mask_reflection, layer1_diffuse_mask_reflection, layer1_mask));
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

