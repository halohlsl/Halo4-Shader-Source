
// Author:	 hocoulby
// Date:	 03/28/12
//
// Surface Shader - Custom Character Forerunner Shader
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

#define DISABLE_LIGHTING_TANGENT_FRAME


// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( control_map_SpDfGl, "Control Map SpDfGl", "Control Map SpDfGl", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"



// Albedo
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity, "Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,	"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,	 "Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,	 "Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"




DECLARE_VERTEX_FLOAT_WITH_DEFAULT(rotation_amount,		"Rotation", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(undulate_intensity,	"Undulation Intensity", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(undulate_falloff,		"Undulation Falloff", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(undulate_scale,		"Undulation Scale", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(undulate_offset,		"Undulation Offset", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"


void CustomVertexCode(
	inout float4 position,
	inout float3 normal,
	inout float3 tangent,
	inout float4 vertexColor,
	inout float4 localToWorld[3])
{
	if (vertexColor.a < 0.5)
	{
		float undulationOffset = undulate_intensity * saturate(-position.x * undulate_falloff) * sin(undulate_scale * position.x + undulate_offset);

		float4 tmpMat[3];
		tmpMat[0] = float4(1, 0, 0, 0);
		tmpMat[1] = float4(0, cos(rotation_amount),-sin(rotation_amount), undulationOffset);
		tmpMat[2] = float4(0, sin(rotation_amount), cos(rotation_amount), 0);

		position.xyz = transform_point(float4(position.xyz, 1), tmpMat);
		normal = transform_vector(normal, tmpMat);
		tangent = transform_vector(tangent, tmpMat);
	}
}

#define custom_deformer(vertex, vertexColor, localToWorld) CustomVertexCode(vertex.position, vertex.normal.xyz, vertex.tangent.xyz, vertexColor, localToWorld)



struct s_shader_data {
	s_common_shader_data common;
};



void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;



// Control Map for Specular, Diffuse, Gloss
		float2 control_map_uv	= transform_texcoord(uv, control_map_SpDfGl_transform);
		float3 control_mask		= sample2DGamma(control_map_SpDfGl, control_map_uv);


//#### ALBEDO
		shader_data.common.albedo.rgb = albedo_tint * control_mask.g;
        shader_data.common.albedo.a = 1.0;



//#### NORMAL
		// Sample normal maps
    	float2 normal_uv    = transform_texcoord(uv, normal_map_transform);
        float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);


#if defined(DETAIL_NORMAL)
		// Composite detail normal map onto the base normal map
		float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
		shader_data.common.normal = CompositeDetailNormalMap(
															shader_data.common,
															base_normal,
															normal_detail_map,
															detail_uv,
															normal_detail_dist_min,
															normal_detail_dist_max);
#else
		shader_data.common.normal = base_normal;
#endif

		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

		// Copy SpecMask and Gloss into shader values
		shader_data.common.shaderValues.xy = control_mask.rb;
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	//..  Output Color
    float4 out_color = 1.0;

	float specular_mask = shader_data.common.shaderValues.x;
	float gloss = shader_data.common.shaderValues.y;

//!-- Diffuse Lighting
    float3 diffuse = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
    diffuse *= shader_data.common.albedo.rgb;


//!-- Specular Lighting
    float3 specular = 0.0f;
	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(gloss, specular_power_min, specular_power_max );
	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, specular_mask, power);
    float3 specular_col = lerp(specular_color, shader_data.common.albedo.rgb, specular_mix_albedo);
	specular *= specular_col * specular_intensity;


	out_color.rgb = diffuse + specular;

	return out_color;
}


#include "techniques.fxh"
