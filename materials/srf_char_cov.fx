//
// File:	 srf_char_cov.fx
// Author:	 hocoulby
// Date:	 08/10/2011
//
// Surface Shader - Covenant Armor Shader
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
// removed surface and apec. noise for now, may add back in later



// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"

//.. Artistic Parameters


// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/color_white_alpha_black.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
#if defined(SPECULAR_DETAIL)
DECLARE_SAMPLER( spec_detail_map, "Specular Detail", "Specular Detail", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
#endif


//DECLARE_SAMPLER( normal_map_flake, "Normal Map - Noise", "Normal Map - Noise", "shaders/default_bitmaps/bitmaps/default_noise_normal.tif")
//#include "next_texture.fxh"

// Surface Colors
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Albedo Tint", "", float3(1.0,1.0,1.0));
#include "used_float3.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(front_color,	"Front Color Tint", "", float3(0.47,0.14,0.14));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(front_color_power, "Front Color Power", "", 0, 10, float(7.0));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(middle_color, "Middle Color Tint", "", float3(0.98,0.46, 0.68));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(middle_color_power, "Middle Color Power", "", 0, 10, float(2.5));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(rim_color,	"Rim Color Tint", "", float3(0.59,0.94,0.97));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_color_power,	"Rim Color Power", "", 0, 10, float(4.0));
#include "used_float.fxh"

// Diffuse
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
//DECLARE_FLOAT_WITH_DEFAULT(specular_noise,		"Specular Noise", "", 0, 1, float(1.0));
//#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_white,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_black,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_albedo_mix,		"Specular Albedo Blend", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_saturation, "Relection Saturation", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Self Illum
#if defined(SELFILLUM)
DECLARE_RGB_COLOR_WITH_DEFAULT(self_illum_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(self_illum_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif


/* NOISE?
DECLARE_RGB_COLOR_WITH_DEFAULT(noise_color,	"Noise  Color", "", float3(0.97,0.95,0.88));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noise_power,		"Noise Power", "", 0, 100, float(16.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noise_layer1_intensity,		"Noise Reflection Intensity", "", 0, 1, float(0.35));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noise_layer2_intensity,		"Noise TopLayer Intensity", "", 0, 1, float(0.3));	
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(noise_layer2_opacity,		"Noise TopLayer Opacity", "", 0, 1, float(1.0));
#include "used_float.fxh"
*/



struct s_shader_data {
	s_common_shader_data common;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{

	float2 uv    		 = pixel_shader_input.texcoord.xy;
    float3 surface_color = 0.0f;   

// Samplers
    // Albedo map
	float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
	float4 color_map_sampled   = sample2DGamma(color_map, color_map_uv);
    color_map_sampled.rgb *= albedo_tint;
	
	// strore alpha for self illum to pass to pixel shader
	#if defined(SELFILLUM)
	if (AllowSelfIllum(shader_data.common))
	{
		shader_data.common.shaderValues.y = color_map_sampled.a;
	}
	#endif
	
    //  control map SpGlRfAo
	float2 control_map_uv      = transform_texcoord(uv, control_map_SpGlRf_transform);
	float4 control_map_sampled = sample2DGamma(control_map_SpGlRf, control_map_uv);

    //  surface normals
	float2 normal_uv = transform_texcoord(uv, normal_map_transform);
	float3 normal_map_sampled = sample_2d_normal_approx( normal_map, normal_uv );
	float3 surface_normal = mul(normal_map_sampled, shader_data.common.tangent_frame);

	// layered colors - back to front
    float3 fresnel_color = 0;
	float3 view = shader_data.common.view_dir_distance.xyz;
	float fresnel  = 1-saturate( dot(normalize(surface_normal), -view) );

	
    float3  rim_fresnel = pow(fresnel, rim_color_power);
    float3  mid_fresnel = pow(fresnel, middle_color_power);
    float3  frt_fresnel = pow(1-fresnel, front_color_power);


    //rim_fresnel *= saturate(mid_fresnel + frt_fresnel);
    mid_fresnel *= 1-rim_fresnel;
    frt_fresnel *= 1-mid_fresnel;

    rim_fresnel *= rim_color;
    mid_fresnel *= middle_color;
    frt_fresnel *= front_color;

    fresnel_color = color_screen(rim_fresnel, mid_fresnel);
    fresnel_color = color_screen(fresnel_color, frt_fresnel);

    // may want to switch this masking up.
    fresnel_color = lerp(float3(1,1,1), fresnel_color, control_map_sampled.a);


    // composite fresnel coloration
    surface_color =  color_map_sampled.rgb * fresnel_color;

    // composite reflection
	// adding in specular detail map
	#if defined(SPECULAR_DETAIL)
		float2 map_uv      = transform_texcoord(uv, spec_detail_map_transform);
		shader_data.common.shaderValues.x  = sample2DGamma(spec_detail_map, map_uv);
	#endif
	
	
    //composite surface noise
    //float noise_fresnel = saturate( dot(noise_normal, view_dir) );
	//surface_color = lerp(layeredColor, noise_color, pow( noise_fresnel, noise_power) * noise_layer2_opacity);

	shader_data.common.albedo.rgb = surface_color;
 	shader_data.common.albedo.a = 1.0f;
    shader_data.common.normal = surface_normal;

}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 out_color = 0.0f;
	float2 uv        = pixel_shader_input.texcoord.xy;
    float4 albedo    = shader_data.common.albedo;
    float3 normal    = shader_data.common.normal;

	float2 control_map_uv      = transform_texcoord(uv, control_map_SpGlRf_transform);
	float4 control_map_sampled = sample2DGamma(control_map_SpGlRf, control_map_uv);


// Specular
    float3 specular = 0.0f;
    // pre-computing roughness with independent control over white and black point in gloss map
    float power = calc_roughness(control_map_sampled.g, specular_power_white, specular_power_black);

    calc_specular_blinn(specular, shader_data.common, normal, albedo.a, power);

    // mix specular_color with albedo_color
    float3 specular_col = lerp(specular_color, albedo.rgb, specular_albedo_mix);
    // modulate by mask, color, and intensity
    specular *= control_map_sampled.r * specular_col * specular_intensity;
	
	#if defined(SPECULAR_DETAIL)
		specular *= shader_data.common.shaderValues.x;
	#endif 

// Diffuse
    float3 diffuse = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, normal);
	float diffuse_mask_reflection = diffuse;
	
    diffuse *= albedo.rgb * diffuse_intensity;


// Composite diffuse and Specular
    out_color.rgb = diffuse + specular;

// Composite Reflection
    // reflection
	if (AllowReflection(shader_data.common)) {
		
		float3 reflection = 0.0f;
		float3 view = shader_data.common.view_dir_distance.xyz;
		
		float fresnel  = 1-saturate( dot(normal, -view) );
		fresnel = pow(fresnel, rim_color_power);
		
		float3 rVec = reflect(view, normal);
		reflection = sampleCUBEGamma(reflection_map, rVec);

		reflection *= reflection_color;
		reflection  = color_saturation(reflection, reflection_saturation);
		reflection *= control_map_sampled.b * fresnel * diffuse_mask_reflection;
		out_color.rgb += reflection;		
	}
	

// Self Illum
	#if defined(SELFILLUM)
	if (AllowSelfIllum(shader_data.common))
	{
		out_color.rgb  *= 1-shader_data.common.shaderValues.y;
        float3 selfIllum = albedo * self_illum_color * self_illum_intensity * shader_data.common.shaderValues.y;
		out_color.rgb += selfIllum;
		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum);
	}
	#endif
	
	
    //.. Finalize Output Color
    out_color.a   = float(1.0);
	return out_color;
}


#include "techniques.fxh"