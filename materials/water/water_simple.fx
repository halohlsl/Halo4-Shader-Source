//
// File:	 water_simple.fx
// Author:	 timfort
// Date:	 01/23/2012
//
// Surface Shader - Water Simple
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//     -based on srf_blinn - made specific for simple (non-deforming) water
//     -layered water textures
//

#define DISABLE_LIGHTING_TANGENT_FRAME
#define DISABLE_LIGHTING_VERTEX_COLOR


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "fx/fx_parameters.fxh"
#include "fx/fx_functions.fxh"


///====================================================================================


DECLARE_RGB_COLOR_WITH_DEFAULT(base_water_color, "Base Water Color", "", float3(0.051,0.012,0.263));
#include "used_float3.fxh"

// Opacity -------------
DECLARE_FLOAT_WITH_DEFAULT( opacity, "Opacity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( minimum_opacity, "Minimum Opacity", "", 0, 1, float(0.1));
#include "used_float.fxh"

DECLARE_BOOL_WITH_DEFAULT( do_opacity_fade,    "Do Opacity Fade", "", true);
#include "next_bool_parameter.fxh"
DECLARE_FLOAT_WITH_DEFAULT( opac_fade_start_u, "Opacity Edge Fade Start U","do_opacity_fade", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( opac_fade_end_u,   "Opacity Edge Fade End U",  "do_opacity_fade", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( opac_mod_color,    "Modulate Color with Opacity",  "", 0, 1, float(0.0));
#include "used_float.fxh"

// Alpha Map ----------------------
DECLARE_BOOL_WITH_DEFAULT( do_alpha_map,    "Use Alpha Map", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER( alpha_map, "Alpha Map", "do_alpha_map", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT( alpha_map_intensity, "Alpha Map Intensity",  "do_alpha_map", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( alpha_map_blackpoint, "Alpha Map Blackpoint",  "do_alpha_map", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( alpha_map_whitepoint, "Alpha Map Whitepoint",  "do_alpha_map", 0, 1, float(1.0));
#include "used_float.fxh"


// Diffuse Map ----------------------
DECLARE_SAMPLER( diffuse_map,     "Diffuse Map",  "Diffuse Map",  "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT( diffuse_intensity, "Diffuse Intensity",  "", 0, 1, float(1.0));
#include "used_float.fxh"

// Diffuse Detail Map ----------------------
DECLARE_BOOL_WITH_DEFAULT( diffuse_detail,          "Detail Diffuse Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER( diffuse_detail_map,   "Diffuse Detail Map",         "diffuse_detail", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_detail_intensity,"Diffuse Detail Intensity.",  "diffuse_detail", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_detail_dist_min, "Diffuse Detail Start Dist.", "diffuse_detail", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_detail_dist_max, "Diffuse Detail End Dist.",   "diffuse_detail", 0, 1, float(5.0));
#include "used_float.fxh"


// Normal Map ----------------------
DECLARE_SAMPLER( normal_map,     "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
//DECLARE_FLOAT_WITH_DEFAULT( normal_intensity, "Normal Map Intensity", "", 0, 1, float(1.0));
//#include "used_float.fxh"

// Normal Detail Map -------------
DECLARE_BOOL_WITH_DEFAULT(detail_normals,          "Detail Normals Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(normal_detail_map,    "Normal Detail Map",  "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_intensity,"Normal Detail Map Intensity", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, "Normal Detail Start Dist.", "detail_normals", 0, 1, float(.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max, "Normal Detail End Dist.",   "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"



// Specular Map  -------------------------
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"

// Specular Parameters
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color, "Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity, "Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min, "Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max, "Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Specular Map Detailed -------------
DECLARE_BOOL_WITH_DEFAULT(detail_specular,           "Detail Specular Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(specular_detail_map,    "Specular Detail Map", "detail_specular", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_detail_intensity,"Specular Detail Intensity", "detail_specular", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_detail_dist_min, "Specular Detail Start Dist.", "detail_specular", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_detail_dist_max, "Specular Detail End Dist.", "detail_specular", 0, 1, float(5.0));
#include "used_float.fxh"



// Reflection ----------------------------------------------
DECLARE_SAMPLER_CUBE(reflection_map,   "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"

// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,    "Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,    "Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_normal,       "Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,       "Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,	       "Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,	       "Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Reflection Control Map
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,    "Fresnel Masks Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,    "Diffuse Masks Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_alpha_mask_specular,"Diffuse Alpha Masks Specular", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Iridescenece
DECLARE_SAMPLER(iridescence_basemap, "Iridescent Base Texture", "Iridescent Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(iridescence_palette, "Iridescent Palette Texture", "Iridescent Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iridescence_intensity, "Iridescence Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_BOOL_WITH_DEFAULT(iridPaletteTextureSuppliesAlpha, "Iridescent Palette Texture Supplies Alpha", "", false);
#include "next_bool_parameter.fxh"



/// ====================================================================================
struct s_shader_data {
    s_common_shader_data common;
    float  alpha;
};


/// ===================================================================================
void pixel_pre_lighting(
			in s_pixel_shader_input pixel_shader_input,
			inout s_shader_data shader_data)
{
    float2 uv = pixel_shader_input.texcoord.xy;

    // Default specular mask
    shader_data.common.shaderValues.x = 1.0f;

    // Set starting color and Alpha explicitly
    shader_data.alpha = opacity;
    shader_data.common.albedo.rgb = base_water_color;

    // Alpha fade - do this first as we use this for fake water depth
    float stream_depth  = 1.0f;
    if (do_opacity_fade) {
        // normalize with 0 in center, 1 at edge
        float norm_u = 2 * abs(uv.x - 0.5);
	stream_depth  = (1 - smoothstep(opac_fade_start_u, opac_fade_end_u, norm_u)); 
    }
    shader_data.alpha *= stream_depth;


    // Calculate the normal map value
    {
        // Sample normal maps
    	float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);
        //base_normal *= normal_intensity;

	STATIC_BRANCH
	if (detail_normals)
	{
	    // Composite detail normal map onto the base normal map
	    float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
	    float3 comped_normal = CompositeDetailNormalMap(shader_data.common,
							    base_normal,
							    normal_detail_map,
							    detail_uv,
							    normal_detail_dist_min,
							    normal_detail_dist_max);
	    // Mix this in by user preference
	    shader_data.common.normal = base_normal + ( (base_normal-comped_normal) * normal_detail_intensity);
	}
	else
	{
	    // Use the base normal map
	    shader_data.common.normal = base_normal;
	}

	// Transform from tangent space to world space
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }  // end normal calc



    //  Diffuse maps
    {
	float2 diffuse_map_uv = transform_texcoord(uv, diffuse_map_transform);
	float4 diffuse = sample2DGamma(diffuse_map, diffuse_map_uv);
	diffuse.rgb *= diffuse_intensity;
	shader_data.common.albedo.rgb += diffuse;
 
	//const float DETAIL_MULTIPLIER = 4.59479f; // 4.59479f == 2 ^ 2.2  (sRGB gamma)
	float2 diffuse_detail_map_uv = transform_texcoord(uv, diffuse_detail_map_transform);
	float4 diffuse_detail = sample2DGamma(diffuse_detail_map, diffuse_detail_map_uv);
	diffuse_detail.rgb *= diffuse_detail_intensity;

	// add diffuse detail
	//diffuse_detail.rgb *= DETAIL_MULTIPLIER;
	// use fake depth to modulate diff contribution
	//if (opac_mod_color>0.0) {
	//    diffuse_detail *= (stream_depth * opac_mod_color);
	//}
	shader_data.common.albedo.rgb *= diffuse_detail;

    }

    // Alpha map
    if (do_alpha_map) {
	float2 alpha_map_uv = transform_texcoord(uv, alpha_map_transform);
	float map_alpha = sample2DGamma(alpha_map, alpha_map_uv);
	map_alpha = ApplyBlackPointAndWhitePoint(alpha_map_blackpoint, alpha_map_whitepoint, map_alpha);

	// mix in based on intensity (wrong)
	//shader_data.alpha = ((1-alpha_map_intensity) * shader_data.alpha) + 
	//                     (alpha_map_intensity * map_alpha * shader_data.alpha);

	shader_data.alpha *= map_alpha;
    }

    // opacity housecleaning
    shader_data.alpha = max(shader_data.alpha, minimum_opacity);
    shader_data.common.albedo.a *= shader_data.alpha;
    shader_data.common.shaderValues.x *= shader_data.common.albedo.w;



    // Reflection | fresnel
    {
	float fresnel = 0.0f;
	{ 
	    // Compute fresnel to modulate reflection
	    float3 view = -shader_data.common.view_dir_distance.xyz;
	    float  vdotn = saturate(dot(view, shader_data.common.normal));
	    // equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
	    fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	
	    fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
	}
	// Store Fresnel mask for reflection
	shader_data.common.shaderValues.y = lerp(1.0, fresnel, fresnel_mask_reflection);

	// Bake the vertex ambient occlusion amount into scaling parameters for lighting components
	// albedo * vertex occlusion
	shader_data.common.albedo.rgb *= shader_data.common.vertexColor.a;	
	// specular mask * vertex occlusion
	shader_data.common.shaderValues.x *= shader_data.common.vertexColor.a;	
	// reflection mask * vertex occlusion
	shader_data.common.shaderValues.y *= shader_data.common.vertexColor.a;	
	
    }
} // pixel_pre_lighting




/// ==================================================================================
float4 pixel_lighting(
		      in s_pixel_shader_input pixel_shader_input,
		      inout s_shader_data shader_data)
{
    float2 uv = pixel_shader_input.texcoord.xy;

    // input from s_shader_data
    float4 albedo               = shader_data.common.albedo;
    float3 normal               = shader_data.common.normal;

    // Sample specular map
    float2 specular_map_uv	= transform_texcoord(uv, specular_map_transform);
    float4 specular_mask 	= sample2DGamma(specular_map, specular_map_uv);

    // Apply the specular mask from the albedo pass
    specular_mask.rgb *= shader_data.common.shaderValues.x;


    // Sample control mask for reflection
    float2 control_map_uv = transform_texcoord(uv, control_map_SpGlRf_transform);
    float4 control_mask	  = sample2DGamma(control_map_SpGlRf, control_map_uv);
    specular_mask.rgb    *= control_mask.r;
    specular_mask.a       = control_mask.g;

    // Multiply the control mask by the reflection fresnel multiplier (calculated in albedo pass)
    float reflectionMask  = shader_data.common.shaderValues.y * control_mask.b;

    
    // Compute Diffuse
    float3 diffuse = 0.0f;
    float3 diffuse_reflection_mask = 0.0f;
    { 
        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);

	// Store the mask for diffuse reflection
        diffuse_reflection_mask = diffuse;

        // modulate by albedo, color, intensity
	diffuse *= albedo.rgb * diffuse_intensity;
    } // diffuse

    

    // Compute Specular
    float3 specular = 1.0f;
    {    
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );

	// using blinn specular model
	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

	// mix specular_color with albedo_color
	float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);

	// modulate by mask, color, and intensity
	//specular *= specular_mask.rgb * specular_col * specular_intensity;
	specular *= specular_col * specular_intensity;
    }


        
    // Compute Iridescence
    float4 iridescence = 0.0f;
    {
        // sample shape texture map
	float2 iridescence_basemap_uv = transform_texcoord(uv, iridescence_basemap_transform);
	iridescence = sample2DPalettizedScrolling(
	    iridescence_basemap, 
	    iridescence_palette, 
	    iridescence_basemap_uv, 
	    0.5,
	    iridPaletteTextureSuppliesAlpha);

	// mask into reflection | fresnel
	iridescence *= reflectionMask * iridescence_intensity;
 
    } // iridescence
    

    
    // calculate reflection
    float3 reflection = 0.0f;
    {
        // sample reflection
        float3 view = shader_data.common.view_dir_distance.xyz;
	float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);

	float3 rVec = reflect(view, rNormal);
	float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

	reflection =
	  reflectionMap.rgb *		// reflection cube sample
	  reflection_color *		// RGB reflection color from material
	  reflection_intensity *	// scalar reflection intensity from material
	  reflectionMask *		// control mask reflection intensity channel * fresnel intensity
	  reflectionMap.a;		// intensity scalar from reflection cube

	reflection = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
    }  // end reflection



    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = albedo.rgb + diffuse + specular + reflection + iridescence;
    out_color.a    = shader_data.alpha;

    return out_color;
}


#include "techniques.fxh"
