//
// File:	 srf_forerunner_layered
// Author:	 hocoulby
// Date:	 12/13/11
//
// Surface Shader - Forerunner layered shader as requested by Chris Emond
//
// Copyright (c) 343 Industries. All rights reserved.
//
/*
UV0 - this channel is used for setting up materials the same way we do it now. Using sets of tileable diff/normal/spec maps 
for the entire model (I think this needs to be a unique UV channel for versatility in laying out things like trims and generally
 aligning the tileable textures for the desired effect).

    Diff
    Normal
    Specular
    (detail?)

UV1 - a 1:1 UV map of the entire model. This will provide overall normal detail, especially useful for edges and surface curvature. 
There should also be a control map used for masking the specular and normal maps of the underlying tiled textures (in UV0) and 
applying 1:1 spec wherever needed (mostly useful for the model edges where the underlying spec is masked out). Ideally,
 we'd like to be able to use a channel of the control map for an AO map to be multiplied 1:1 over the entire model. I
 if the spec and AO map could be color tinted that would be even better, if not too expensive (warm specular highlights with cool 
 baked in AO, for example).

    Normal
    Control
    R - spec/normal mask
    G - AO to be multiplied over entire model 1:1
    B - unused right now, do we need anything else here?

*/



// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Texture Sampletrs for UV1
DECLARE_SAMPLER_NO_TRANSFORM( specular_map_uv2, "Specular Map UV2", "Specular Map UV2", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( normal_map_uv2, "Normal Map UV2", "Normal Map UV2", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( control_SpAoRf_uv2, "Control SpAoRf UV2", "Control Map SpAoRf UV2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

// Reflections
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Specular Layer 1
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Specular Layer 2
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color_2,	"Specular Color L2", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity_2,		"Specular Intensity L2", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(ao_color,	"Ambient Occ. Color", "", float3(1,1,1));
#include "used_float3.fxh"


// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_lod,		    "Reflection_Blur", "", 0, 10, float(0.0));
#include "used_float.fxh"


// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Detail Normal Map
DECLARE_BOOL_WITH_DEFAULT(detail_normals, "Detail Normals Enabled", "", false);
#include "next_bool_parameter.fxh"
DECLARE_BOOL_WITH_DEFAULT(detail_normals_uv2, "Detail use UV2 ", "", false);
#include "next_bool_parameter.fxh"
DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "", 0, 1, float(1.0));
#include "used_float.fxh"




struct s_shader_data {
	s_common_shader_data common;
};





void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv1 = pixel_shader_input.texcoord.xy;
	float2 uv2 = pixel_shader_input.texcoord.zw;

	// color
	float2 color_map_uv  = transform_texcoord(uv1, color_map_transform);
	shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
	shader_data.common.albedo .a = 1.0;
	shader_data.common.albedo.rgb *= albedo_tint;
	

	// second uv control
	float2 control_map_uv	 = transform_texcoord( pixel_shader_input.texcoord.zw, float4(1,1,0,0));
	float4 control_mask      = sample2DGamma(control_SpAoRf_uv2, control_map_uv);
	
	
    {// Sample and composite normal and detail maps.
    	float2 normal_uv   = transform_texcoord(uv1, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);
		
		// second normal map uv2
		normal_uv =  transform_texcoord(uv2, float4(1,1,0,0));
		float3 second_layer_normal = sample_2d_normal_approx(normal_map_uv2, normal_uv);
		
		// mask out second layer normal contribution
		//second_layer_normal = lerp(float3(0,0,0), second_layer_normal, control_mask.r);
		base_normal = lerp(base_normal,  float3(0,0,0), control_mask.r); 
		
		// composite the two normals together 
		shader_data.common.normal.xy = base_normal.xy  + second_layer_normal.xy;
		
		// using detail normal maps?
		STATIC_BRANCH
		if (detail_normals)
		{
			float2 normal_detail_uv = uv1;
			
			if (detail_normals_uv2)
			{				
				normal_detail_uv = uv2;
			}
				
				
			float2 detail_uv	  = transform_texcoord(normal_detail_uv, normal_detail_map_transform);
			shader_data.common.normal = CompositeDetailNormalMap(   shader_data.common,
																											  shader_data.common.normal,
																											  normal_detail_map,
																											  detail_uv,
																											  normal_detail_dist_min,
																											  normal_detail_dist_max);

    	

		} else {
			// reconstruct Z without the detail map
			shader_data.common.normal.z =  sqrt(saturate(1.0f + dot(shader_data.common.normal.xy, -shader_data.common.normal.xy)));
		}
		

		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
	}
	
		
		
	
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
    float3 normal         = shader_data.common.normal;

	
	// Sample control map and specular.
	// second uv control
	float2 control_map_uv	 = transform_texcoord( pixel_shader_input.texcoord.zw, float4(1,1,0,0));
	float4 control_mask      = sample2DGamma(control_SpAoRf_uv2, control_map_uv);


    float3 diffuse = 0.0f;
	float3  diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse
        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, normal);
        diffuse_reflection_mask = diffuse;
        // modulate by albedo
    	diffuse *= albedo.rgb;
    }

	

	
    float3 specular = 0.0f;
	{ // Compute Specular
		// sample specular map
		float2 specular_mask_uv		 = transform_texcoord( pixel_shader_input.texcoord.xy, specular_map_transform);
		float4 specular_map_sampled 	 = sample2DGamma(specular_map,  specular_mask_uv);
		
		// second layer
		specular_mask_uv		 = transform_texcoord( pixel_shader_input.texcoord.zw, float4(1,1,0,0));
		float4 specular_map_sampeld_2  = sample2DGamma(specular_map_uv2,  specular_mask_uv);
		// mask the contribtion of the specular map
		
		specular_map_sampled = lerp(	specular_map_sampled * float4(specular_color, 1) * specular_intensity, 
															specular_map_sampeld_2 * float4(specular_color_2, 1) * specular_intensity_2,
															control_mask.r );
		
		
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_map_sampled.a, specular_power_min, specular_power_max );

	    // using phong specular model
    	calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

	
		specular_map_sampled.rgb = lerp(specular_map_sampled.rgb, albedo.rgb, specular_mix_albedo);

        // modulate by mask, color, and intensity
        specular *= specular_map_sampled.rgb;
	}


	
/*
	float3 reflection = 0.0f;
	{ // REFLECTION
	
		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection

			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot( view, normal));
			fresnel = pow(vdotn, fresnel_power) * fresnel_intensity;
			fresnel = lerp(fresnel, saturate(1-fresnel), fresnel_inv);
		}

		float3 view = shader_data.common.view_dir_distance.xyz;

		float4 rVec = 0.0;
		rVec.rgb = reflect(view, shader_data.common.normal);
		rVec.w    = reflection_lod;

		shader_data.reflection = texCUBElod(reflection_map, rVec).rgb;
		shader_data.reflection *= reflection_intensity * reflection_color * diffuse_reflection_mask * control_mask.b;
		
		reflection  = lerp(reflection, reflection*fresnel, fresnel_mask_reflection);
	}

*/

	

    //.. Finalize Output Color
    float4 out_color;
    out_color.rgb = diffuse + specular;

	// mask out color with occlusion
	//out_color.rgb *= control_mask.g * ao_color;

/*
	// self illum
	if (AllowSelfIllum(shader_data.common))
	{
		float3 self_illum = albedo.rgb * si_color * si_intensity * self_illum_mask;
		out_color.rgb += self_illum;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(self_illum);
	}
*/

	out_color.a   = 1.0f;

	return out_color;
}


#include "techniques.fxh"