//
// File:	 srf_special_lava_scurve.fx
// Author:	 v-inyang
// Date:	 02/22/2012
//
// Surface Shader - lava for halp4 MP map Scurve
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader
#define DISABLE_SH

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER( color_map, "Slow Crust Map", "Slow Crust Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( color1_map, "Fast Crust Map", "Fast Crust Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER( control_map, "Crust Control Map", "Crust Control Map", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER( selfillum_map, "Lava Map", "Lava Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( distortion1_map, "Lava Distortion Map1", "Lava Distortion Map1", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( distortion2_map, "Lava Distortion Map2", "Lava Distortion Map2", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER( normal_map, "Slow Crust Normal Map", "Slow Crust Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal1_map, "Fast Crust Normal Map", "Fast Crust Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( lava_normal_map, "Lava Normal Map", "Lava Normal Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"


// Lava Control
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"Lava Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"Lava Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_contrast,	"Lava contrast", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(lava_wave_size,	"Lava_Wave_Size", "", 0, 1, float(0.1));
#include "used_vertex_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(slow_crust_intensity,	"Slow Crust contrast Intensity", "", 0, 5, float(3.0));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_BOOL_WITH_DEFAULT(wireframe_outline, "Wireframe Outline", "", false);
#include "next_bool_parameter.fxh"

// a couple parameters for vertex animation
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_frequency,	"Animation Frequency", "", 0, 1, float(360.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(animation_intensity,	"Animation Intensity", "", 0, 1, float(0.04));
#include "used_vertex_float.fxh"


struct s_shader_data
{
	s_common_shader_data common;
    float3 self_illum;
    float alpha;
};

#if defined(xenon) || defined(cgfx) || (DX_VERSION == 11)

float PeriodicVibration(in float animationOffset)
{
#if !defined(cgfx)
	float vibrationBase = 2.0 * abs(frac(animationOffset + animation_frequency * vs_time.z) - 0.5);
#else
	float vibrationBase = 2.0 * abs(frac(animationOffset + animation_frequency * frac(vs_time.x/600.0f)) - 0.5);
#endif
	return sin((0.5f - vibrationBase) * 3.14159265f);
}

float3 GetVibrationOffset(in float2 texture_coord, float animationOffset)
{
	float2 vibrationCoeff;
    float distance = frac(texture_coord.x);

	float id = texture_coord.x - distance + animationOffset;
	vibrationCoeff.x = PeriodicVibration(id / 0.53);

	id += floor(texture_coord.y) * 7;
	vibrationCoeff.y = PeriodicVibration(id / 1.1173);

	float2 direction = frac(id.xx / float2(0.727, 0.371)) - 0.5;

	return distance * animation_intensity * vibrationCoeff.xxy * float3(direction.xy, 0.3f);
}

#define custom_deformer(vertex, vertexColor, local_to_world)			\
{																		\
	float animationOffset = dot(float3(1,1,1), lava_wave_size*vertex.position.xyz);	\
	vertex.position.xyz += GetVibrationOffset(vertex.texcoord.xy, animationOffset);\
}

#endif


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{

	float2 uv = pixel_shader_input.texcoord.xy;
	shader_data.common.albedo.rgb = float4(0,0,0,1);
	
	// Sample Control Map
		float2 control_map_uv 	  = transform_texcoord(uv, control_map_transform);
		float4 control_mask = sample2DGamma(control_map, control_map_uv);

		
    //Crust////////////////////////////////////////////////////////////////////////////
	// Sample Crust Map
	    float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
		float2 color1_map_uv 	  = transform_texcoord(uv, color1_map_transform);
	    float4 slowcrust = sample2DGamma(color_map, color_map_uv);
		//darken slowcrust
		float darkencrust = 1.0f; 
		darkencrust = pow( slowcrust.r, slow_crust_intensity );
		darkencrust = lerp ( darkencrust, 1, control_mask.b);
		slowcrust *= darkencrust; 
		//mix slow and fast 
		float4 fastcrust = sample2DGamma(color1_map, color1_map_uv);
		float4 crust = lerp( slowcrust, fastcrust, control_mask.r );
		
	////Base Lava//////////////////////////////////////////////////////////////////////
		// Generate Distortion UVs for Lava Distortion map
	    float2 distortion1_map_uv 	  = transform_texcoord(uv, distortion1_map_transform);
	    float d1 = sample2DGamma(distortion1_map, distortion1_map_uv).z;

		float2 distortion2_map_uv 	  = transform_texcoord(uv, distortion2_map_transform);
	    float d2 = sample2DGamma(distortion2_map, distortion2_map_uv).z;
		
		float2 distortion_uv = float2(d1, d2);

		
		// Sample Lava Distortion Map
		float2 si_map_uv = transform_texcoord(uv, selfillum_map_transform);
		si_map_uv += distortion_uv;
		float3 self_illum = sample2DGamma(selfillum_map, si_map_uv).rgb;
		self_illum = pow(self_illum, si_contrast);		
		self_illum *= si_color ;
		
	// Mix Crust and Lava Base//////////////////////////////////////////////////////////
		self_illum = lerp( self_illum, crust, control_mask.g );
		self_illum *= si_intensity;	


    if (AllowSelfIllum(shader_data.common))
    {
		// output to pixel shader final color
		shader_data.common.albedo.rgb = self_illum;
		
		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(self_illum);
	}	
	
	////Normal Map////////////////////////////////////////////////////////////////////////
    float3 slowcrust_normal = sample_2d_normal_approx(normal_map, color_map_uv);
    float3 fastcrust_normal = sample_2d_normal_approx(normal1_map, color1_map_uv);
	float2 lava_normal_uv 	  = transform_texcoord(uv, lava_normal_map_transform);
	float3 lava_normal = sample_2d_normal_approx(lava_normal_map, lava_normal_uv);
	float3 crust_normal = lerp( slowcrust_normal, fastcrust_normal, control_mask.r );
	crust_normal = lerp( lava_normal, crust_normal, control_mask.g );
	crust_normal = lerp( lava_normal, crust_normal, control_mask.g );
	shader_data.common.normal = crust_normal;
				
	// Transform from tangent space to world space
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
	

}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{

#if defined(xenon)
	if (wireframe_outline)
	{
		pixel_pre_lighting(pixel_shader_input, shader_data);
	}
#endif
	float4 albedo  = shader_data.common.albedo;
	float3 normal  = shader_data.common.normal;
	float3 specular = 1.0f;
	float4 specular_mask = 1.0f;


	{ // Compute Specular
		float3 specNormal = normal;
        // pre-computing roughness with independent control over white and black point in gloss map
        float power = calc_roughness(specular_mask.a, specular_power_min, specular_power_max );
	    // using blinn specular model
    	calc_specular_blinn(specular, shader_data.common, specNormal, albedo.a, power);
		// modulate by mask, color, and intensity
        specular *= specular_mask.rgb * specular_color * specular_intensity;
	}
	
	{ // Compute Diffuse
		// using standard lambert model
        calc_diffuse_lambert(albedo.rgb, shader_data.common, normal);
    }


     //.. Output Color from albedo pass
	float4 out_color = shader_data.common.albedo;
	out_color.rgb += specular;
	return out_color;
}


#include "techniques.fxh"
