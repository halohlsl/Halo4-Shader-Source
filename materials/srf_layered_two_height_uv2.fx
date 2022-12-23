// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
/*
Started from layered_wade
Blends three sets of terrain textures using R and G channel of blend map.
Heightmap threshold is painted in blend map
Heightmap threshold softness is controlled by vertex color
Heightmap threshold softness is also controlled by B channel of blend map(cloud map parameter), to quickly add variation.

#!  Blend Map and Layer 1 (all texture samplers) use the second uv set 
*/

// Define default settings for this shader
#if !defined(BLENDMAP_UV2)
	#define BLENDMAP_UV2
#endif

#if !defined(LAYER1_UV2)
	#define LAYER1_UV2
#endif



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
DECLARE_SAMPLER( layer0_spMap, "Layer0 Specular", "Layer0 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer0_nmMap, "Layer0 Normal", "Layer0 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer0_co_tint,	"Layer0 Tint", "", float3(1,1,1));
#include "used_float3.fxh"



//... Layer1 - Red
DECLARE_SAMPLER( layer1_coMap, "Layer1 Color", "Layer1 Color", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_spMap, "Layer1 Specular", "Layer1 Specular", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_nmMap, "Layer1 Normal", "Layer1 Normal", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_co_tint,	"Layer1 Tint", "", float3(1,0,0));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(layer1_height_influence, "Layer1 Height Map Influence", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_cloud_influence, "Layer1 Cloud Map Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"


// specular control
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"


//VERTEX ALPHA
#if defined VERT_ALPHA
DECLARE_FLOAT_WITH_DEFAULT(alpha_mask_falloff, "Alpha Mask Falloff", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif

// Detail Normal Map
#if defined(DETAIL_NORMAL)
	DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist", "", 0, 1, float(5.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist", "", 0, 1, float(1.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(normal_detail_view_invert, 	"Detail View Invert 1", "", 0, 1, float(0.0));
	#include "used_float.fxh"
#endif


struct s_shader_data {
    s_common_shader_data common;

};



/// Pixel Shader - Albedo Pass

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    float2 uv		= pixel_shader_input.texcoord.xy;

	float2 layer0_texcoord = pixel_shader_input.texcoord.xy;
	#if defined LAYER0_UV2
		layer0_texcoord = pixel_shader_input.texcoord.zw;
	#endif
	
	float2 layer1_texcoord = pixel_shader_input.texcoord.xy;
	#if defined LAYER1_UV2
		layer1_texcoord =  pixel_shader_input.texcoord.zw;
	#endif

	float2 blend_map_uv = pixel_shader_input.texcoord.xy;
	#if defined BLENDMAP_UV2
		blend_map_uv = pixel_shader_input.texcoord.zw;
	#endif
	
    //----------------------------------------------
    // Sample blend and cloud maps
    //----------------------------------------------

	float4 blend		= sample2DGamma(blend_map, blend_map_uv);
	float4 cloud    	= sample2DGamma(blend_map, transform_texcoord(blend_map_uv, blend_map_transform));


    //----------------------------------------------
    // Sample layers
    //----------------------------------------------
    float4 layer0_color = sample2DGamma(layer0_coMap, transform_texcoord(layer0_texcoord, layer0_coMap_transform));
    float3 layer0_normal= sample_2d_normal_approx(layer0_nmMap, transform_texcoord(layer0_texcoord, layer0_nmMap_transform));

	// Detail normal to base layer
	#if defined(DETAIL_NORMAL)
	float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
	layer0_normal = CompositeDetailNormalMap(
									shader_data.common,
									layer0_normal,
									normal_detail_map,
									detail_uv,
									normal_detail_dist_min,
									normal_detail_dist_max);															  
	#endif

	
    float4 layer1_color = sample2DGamma(layer1_coMap, transform_texcoord(layer1_texcoord, layer1_coMap_transform));
    float3 layer1_normal= sample_2d_normal_approx(layer1_nmMap, transform_texcoord(layer1_texcoord, layer1_nmMap_transform));


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
    shader_data.common.albedo.a    = 1.0f;
	
	
	//VERTEX ALPHA
	#if defined VERT_ALPHA
			
		float vert_alpha = shader_data.common.vertexColor.a;
		float alpha_mask = 1.0f ;
		
		alpha_mask *= vert_alpha - ( 1 - blend.r - blend.g )*( 1 - layer0_color.a );	//color0 mask
		alpha_mask += vert_alpha - blend.r * ( 1 - layer1_color.a );					//color1 mask
		alpha_mask += vert_alpha - blend.g * ( 1 - layer2_color.a );					//color2 mask
		alpha_mask = alpha_mask/alpha_mask_falloff ;
		alpha_mask = saturate( alpha_mask );

		shader_data.common.albedo.a = alpha_mask;
		
	#endif
	
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
    // Composite Spec maps, output spec mask
    //----------------------------------------------
	float2 layer0_texcoord = pixel_shader_input.texcoord.xy;
	#if defined LAYER0_UV2
		layer0_texcoord = pixel_shader_input.texcoord.zw;
	#endif
	
	float2 layer1_texcoord = pixel_shader_input.texcoord.xy;
	#if defined LAYER1_UV2
		layer1_texcoord =  pixel_shader_input.texcoord.zw;
	#endif

    float4 layer0_spec  = sample2DGamma(layer0_spMap, transform_texcoord(layer0_texcoord, layer0_spMap_transform));
    float4 layer1_spec  = sample2DGamma(layer1_spMap, transform_texcoord(layer1_texcoord, layer1_spMap_transform));

    float4 specular_mask;
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
    // Finalize output color
    //----------------------------------------------
    float4 out_color;
    out_color.rgb = (albedo.rgb * diffuse) + specular;
    out_color.a   = albedo.a;
	
    return out_color;
}


#include "techniques.fxh"