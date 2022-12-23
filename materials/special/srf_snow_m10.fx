//
// File:	 srf_snow_m10.fx
// Author:	 hocoulby
// Date:	 10/07/11
//
// Surface Shader - Custom snow shader for m10
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes: The is a custom shader requested for m10. A little bit of fake sss and noise to help acheive a snowy ice pack look.
//

#define MATERIAL_CONTROLS_SHADOW_MASK_READOUT

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map_flake, "Normal Map - Noise", "Normal Map - Noise", "shaders/default_bitmaps/bitmaps/default_noise_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"

// Diffuse
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(0.9));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.02));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(spec_noise_intensity,		"Specular Noise Intensity", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.5));
#include "used_float.fxh"


// Scatter Settings
DECLARE_RGB_COLOR_WITH_DEFAULT(scatter_color,	"Scatter Color", "", float3(0.82,0.96,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scatter_intensity,	"Scatter Intensity", "", 0, 1, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scatter_mix_albedo,	"Scatter Mix Albedo", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(wrap_diffuse,	"Wrap Diffuse Lighting", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(wrap_scatter,	"Wrap Scatter Lighting", "", 0, 1, float(0.8));
#include "used_float.fxh"

// Snow flecks, noise
DECLARE_RGB_COLOR_WITH_DEFAULT(fleck_color,	"Fleck  Color", "", float3(0.93,0.98,0.99));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fleck_power,		"Fleck Power", "", 0, 100, float(20.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fleck_intensity,	"Fleck  Intensity", "", 0, 1, float(1.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fleck_opacity,		"Fleck  Opacity", "", 0, 1, float(2.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fleck_mix_albedo,		"Fleck Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"


DECLARE_FLOAT_WITH_DEFAULT(height_influence,	"Alpha Height Influence", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(threshold_softness,	"Alpha Threshold Softness", "", 0, 1, float(0.0));
#include "used_float.fxh"


struct s_shader_data {
	s_common_shader_data common;
	float alpha;

};




void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv    		= pixel_shader_input.texcoord.xy;

	// color map
	float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	float4 color_sMap    = sample2DGamma(color_map, color_map_uv);

    shader_data.common.albedo.rgb = color_sMap.rgb;
	shader_data.alpha = color_sMap.a;
	shader_data.common.albedo.a = shader_data.alpha;

	//  surface normal
	float3 surf_normal   = sample_2d_normal_approx( normal_map, transform_texcoord(uv, normal_map_transform) );
	shader_data.common.normal = normalize( mul(surf_normal, shader_data.common.tangent_frame) );

}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo       = shader_data.common.albedo;
    float3 normal       = shader_data.common.normal;
	float3 geo_normal	= shader_data.common.geometricNormal;
	
	float alpha = saturate( (shader_data.common.vertexColor.a  - ( 1 - shader_data.alpha )) / max(0.001, threshold_softness)  );
	alpha = lerp( shader_data.common.vertexColor.a, alpha, height_influence);

    float4 out_color;
    out_color.a  = alpha;

	// noise for snow flecks
	float3 noise_normal = sample_2d_normal_approx( normal_map_flake, transform_texcoord(pixel_shader_input.texcoord.xy, normal_map_flake_transform) );
	noise_normal = normalize( mul(noise_normal, shader_data.common.tangent_frame) );
	float3 specular_normal = normalize(spec_noise_intensity * noise_normal + shader_data.common.normal);

    float3 specular = 0.0f;

	//  control map SpGlRfAo
	float2 specular_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpGlRf_transform);
	float4 control_mask      = sample2DGamma(control_map_SpGlRf, specular_map_uv);
	{ // Compute Specular

        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(control_mask.g, specular_power_min, specular_power_max );
	    // using phong specular model
    	calc_specular_blinn(specular, shader_data.common, specular_normal, alpha, power);
		// mix specular_color with albedo_color
        float3 specular_col = lerp(specular_color, albedo.rgb, specular_mix_albedo);
        // modulate by mask, color, and intensity
        specular *= control_mask.r * specular_col * specular_intensity;
    }





// simple diffuse scattering
    float3 diffuse = 0.0f;  // final diffuse lighting

    // hard lighting use the high res normal and detail normal map
    float3 diffuse_hard = 0.0f;
    calc_diffuse_lambert_wrap(diffuse_hard, shader_data.common, shader_data.common.normal, wrap_diffuse, true);
    diffuse_hard *= diffuse_intensity;

    // mask specular
    //specular *= diffuse_hard;

    // aproximates scattered light
    float3 diffuse_soft = 0.0f;
    calc_diffuse_lambert_wrap(diffuse_soft, shader_data.common, geo_normal, wrap_scatter, true);
    diffuse_soft *= diffuse_intensity;


	 // difference between two lobes
    float diffuse_diff = saturate(diffuse_soft-diffuse_hard);
    diffuse_diff = smoothstep(0,1,diffuse_diff);
    diffuse_diff *= scatter_intensity;


    // surface colors

    float3 diffuse_hard_color = diffuse_hard * shader_data.common.albedo.rgb;
	float3 diffuse_soft_color = diffuse_soft * shader_data.common.albedo.rgb;
    float3 scatter_color_mix  = lerp(scatter_color, shader_data.common.albedo.rgb, scatter_mix_albedo);
    float3 scatColor = scatter_color_mix*float3(0.01,0.01,0.02);
    scatColor = pow(saturate(scatColor * 2), 0.25);

    // layer in scatter color
    float3 diffuse_mixture = lerp(diffuse_hard_color, diffuse_soft_color,  scatColor);
    diffuse_mixture = lerp(diffuse_mixture, diffuse_soft_color*scatter_color_mix, diffuse_diff);

    diffuse = diffuse_mixture + (diffuse_diff * scatter_color_mix * shader_data.common.albedo.rgb );
	diffuse *= diffuse_intensity;


	// fleck color
	float3 view = -shader_data.common.view_dir_distance.xyz;
	noise_normal = normalize(fleck_intensity * noise_normal + shader_data.common.normal);
	float noise_fresnel = saturate( dot(noise_normal, view) );
	float3 flecks = fleck_color * (pow( noise_fresnel, fleck_power) * fleck_opacity) ;
	flecks = lerp(flecks*diffuse_hard, flecks*diffuse, fleck_mix_albedo);

    //.. Finalize Output Color
    out_color.rgb = diffuse + specular + flecks;

	return out_color;
}


#include "techniques.fxh"