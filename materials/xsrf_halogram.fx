//
// File:	 srf_micron_halogram.fx
// Author:	 micron
// Date:	 10/30/11
//
// Surface Shader - Halogram - Generic
//
// Copyright (c) 343 Industries. All rights reserved.
//
//
//

// Libraries
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"



// Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(scan_lines_map, "Scan Lines Map", "screen_space_mask_2_enabled", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"



DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity, "Diffuse Intensity", "", 0, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_width, "rim_width", "", -5, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(rim_intensity, "fresnel_intensity", "", -5, 5, float(1.0));
#include "used_float.fxh"

DECLARE_BOOL_WITH_DEFAULT(use_albedo_color, "Use Color", "", false);
#include "next_bool_parameter.fxh"
DECLARE_BOOL_WITH_DEFAULT(use_albedo_alpha, "Use Alpha", "", false);
#include "next_bool_parameter.fxh"
DECLARE_BOOL_WITH_DEFAULT(use_scan_lines, "Use Scan Lines", "", false);
#include "next_bool_parameter.fxh"
// Lighting Rig


DECLARE_FLOAT_WITH_DEFAULT(lgt_key_intensity, "Key Light Intensity", "", 0, 2, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_intensity, "Fill Light Intensity", "", 0, 2, float(0.25));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_intensity, "Rim Light Intensity", "", 0, 2, float(0.8));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(lgt_key_forward_value, "lgt_key_forward", "", -1, 1, float(-20.525));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_key_right_value, "lgt_key_right", "", -1, 1, float(20.046));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_key_up_value, "lgt_key_up", "", -1, 1, float(20.691));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_forward_value, "lgt_fill_forward", "", -1, 1, float(27.482));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_right_value, "lgt_fill_right", "", -1, 1, float(-29.55));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_up_value, "lgt_fill_up", "", -1, 1, float(20.324));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_forward_value, "lgt_rim_forward", "", -1, 1, float(100.547));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_right_value, "lgt_rim_right", "", -1, 1, float(100.667));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_up_value, "lgt_rim_up", "", -1, 1, float(-180.837));
#include "used_float.fxh"

static const float clip_threshold = 250.0f / 255.0f;



struct s_shader_data {
	s_common_shader_data common;
	SCREEN_POSITION_INPUT(vPos);
};


float SampleScreenSpace(texture_sampler_2d map, float4 transform, in s_shader_data shader_data)
{
#if defined(xenon) || (DX_VERSION == 11)
	return sample2D(map, transform_texcoord(shader_data.common.platform_input.fragment_position.xy / 1000.0, transform)).r;
#else // defined(xenon)
	return 1;
#endif // defined(xenon)
}


void build_lighting_data( inout s_shader_data shader_data )
{
#if defined(cgfx)
	float4 objectToWorld[3];
	objectToWorld[0] = float4(0,-1,0,0);
	objectToWorld[1] = float4(0,0,1,0);
	objectToWorld[2] = float4(-1,0,0,0);

	// Hard coding the rig for maya to simulate the default in engine.
	lgt_key_forward_value = -100;
	lgt_key_right_value = 100;
	lgt_key_up_value = 100;

	lgt_fill_forward_value = -100;
	lgt_fill_right_value = -100;
	lgt_fill_up_value = -50;

	lgt_rim_forward_value = 100;
	lgt_rim_right_value = -50;
	lgt_rim_up_value = 50;

#else
	float4 objectToWorld[3] = {ps_material_generic_parameters[0], ps_material_generic_parameters[1], ps_material_generic_parameters[2]};
#endif

#if defined(xenon) || (DX_VERSION == 11)

	shader_data.common.lighting_data.light_direction_specular_scalar[0].xyz = objectToWorld[0].xyz;
	shader_data.common.lighting_data.light_direction_specular_scalar[1].xyz = objectToWorld[1].xyz;
	shader_data.common.lighting_data.light_direction_specular_scalar[2].xyz = objectToWorld[2].xyz;

#else

	shader_data.common.lighting_data.light_direction_specular_scalar[0].xyz =
		normalize(transform_vector(float3(lgt_key_forward_value, lgt_key_right_value, lgt_key_up_value), objectToWorld));

	shader_data.common.lighting_data.light_direction_specular_scalar[1].xyz =
		normalize(transform_vector(float3(lgt_fill_forward_value, lgt_fill_right_value, lgt_fill_up_value), objectToWorld));

	shader_data.common.lighting_data.light_direction_specular_scalar[2].xyz =
		normalize(transform_vector(float3(lgt_rim_forward_value, lgt_rim_right_value, lgt_rim_up_value), objectToWorld));


#endif

	shader_data.common.lighting_data.light_direction_specular_scalar[0].w = 1.0;
	shader_data.common.lighting_data.light_direction_specular_scalar[1].w = 1.0;
	shader_data.common.lighting_data.light_direction_specular_scalar[2].w = 1.0;

	shader_data.common.lighting_data.light_intensity_diffuse_scalar[0] = (float4)lgt_key_intensity;
	shader_data.common.lighting_data.light_intensity_diffuse_scalar[1] = (float4)lgt_fill_intensity;
	shader_data.common.lighting_data.light_intensity_diffuse_scalar[2] = (float4)lgt_rim_intensity;

	shader_data.common.lighting_data.light_component_count = 3;
}


void calc_diffuse(
			inout float3 diffuse,
			const in s_shader_data shader_data,
			const in float index)
{
    float3 direction = shader_data.common.lighting_data.light_direction_specular_scalar[index].xyz;
    float4 intensity_diffuse_scalar= shader_data.common.lighting_data.light_intensity_diffuse_scalar[index];
	float ndotl = saturate(dot(direction, shader_data.common.normal)) * intensity_diffuse_scalar.a;
	diffuse += ndotl;
}


// pre lighting
void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	float2 color_map_uv = transform_texcoord(uv, color_map_transform);
	shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
	shader_data.common.albedo.rgb = color_luminance(shader_data.common.albedo.rgb);
	shader_data.common.albedo.a = shader_data.common.albedo.a;

	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
	
	// Tex kill non-opaque pixels in albedo pass; tex kill opaque pixels in all other passes
	if (use_albedo_alpha) {
		clip((shader_data.common.shaderValues.x - clip_threshold) * ps_material_blend_constant.w); //
	}

	shader_data.common.shaderValues.x = 1.0;
	shader_data.common.shaderValues.x = SampleScreenSpace(scan_lines_map, scan_lines_map_transform, shader_data);

	
}



// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	inout s_shader_data shader_data)
{
	float dif_int = diffuse_intensity;
	float4 out_color = 1.0;
	
	out_color.rgb  = shader_data.common.albedo.rgb;

	float3 diffuse = 0.0f;
	build_lighting_data(shader_data);
	calc_diffuse( diffuse, shader_data, 0); // key
	calc_diffuse( diffuse, shader_data, 1); // fill
	calc_diffuse( diffuse, shader_data, 2); // rim
	

	float fresnel = 0.0f;
	float3 view = -shader_data.common.view_dir_distance.xyz;	
	float  vdotn =  saturate(dot( view, shader_data.common.normal ));
	fresnel = 1 - smoothstep(1.0 - rim_width, 1.0, vdotn);
	
	float3 albedoColor = 1.0;
	
	if (use_albedo_color) {	albedoColor = shader_data.common.albedo.rgb;}
	
	float3 srfColor = ((diffuse*albedoColor) + (fresnel*rim_intensity)) * albedo_tint;
	float  srfAlpha = (diffuse.r + fresnel);

	if (use_albedo_alpha) {	
		srfAlpha *= shader_data.common.albedo.a;
	}
	
	if (use_scan_lines) {
		srfAlpha += shader_data.common.shaderValues.x;
	}
	
	out_color.rgb = srfColor;
	out_color.a   = srfAlpha;
	
	
/*	
	out_color.rgb += fresnel;
	out_color.rgb *= albedo_tint;	
	out_color.rgb *= dif_int;

	out_color.rgb *= fresnel * rim_intensity;

	out_color.a = saturate(fresnel  + color_luminance(diffuse)); //surfAlpha

	
	float albedoLuma = color_luminance(shader_data.common.albedo.rgb);
	out_color.a += lerp(albedoLuma * dif_int + shader_data.common.albedo.a, 0, fresnel);
	out_color.rgb += lerp((albedoLuma*albedo_tint*dif_int)*color_luminance(diffuse), 0, fresnel);


	if (shader_data.common.lighting_mode != LM_PROBE)
	{
		// Maya does its own form of transparency sorting, so do not modify the output for OIT
		// Need to premultiply the alpha into the color to work with order-independent transparency
		out_color.rgb *= out_color.a;

		if (out_color.a <= 254.0 / 255.0)
		{
			out_color /= 3.0f;
		}
	}
	*/
	
	// flicker map
	//out_color.a *= sample2D(maskA, transform_texcoord(shader_data.vPos, maskA_transform) + (float2(maskASlideU, maskASlideV) * ps_time.x)).r;

		
	
	return out_color;
}

// Mark this shader as a hologram shader
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_hologram = true; bool is_alpha_clip = true;>



#if !defined(cgfx)

	#include "techniques_base.fxh"
	#include "entrypoints/single_pass_lighting.fxh"

	MAKE_TECHNIQUE(single_pass_per_vertex)
	MAKE_TECHNIQUE(single_pass_single_probe)

#elif defined(cgfx)

	#include "techniques_cgfx.fxh"

#endif 	// !defined(cgfx)


