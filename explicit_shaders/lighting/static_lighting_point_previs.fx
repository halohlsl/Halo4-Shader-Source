/*
STATIC_LIGHTING_POINT_PREVIS.HLSL
Copyright (c) Microsoft Corporation, 2008. all rights reserved.
08/12/2009 corrinyu
*/


#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "ss_light_registers.fxh"


#define LIGHT_COLOR (ps_screen_space_light_constants[4].rgb)
#define DEFORM deform_tiny_position

// default parameters

#ifndef SHADER_ATTRIBUTES
#define SHADER_ATTRIBUTES
#endif // SHADER_ATTRIBUTES

#define pi 3.14159265358979323846

LOCAL_SAMPLER2D(depth_sampler, 0);
LOCAL_SAMPLER2D(albedo_sampler, 1);
LOCAL_SAMPLER2D(normal_sampler, 2);
LOCAL_SAMPLER2D(specular_curve_sampler, 3);
LOCAL_SAMPLER2D(gobo_sampler, 4);

static float4x4 screen_to_relative_world=transpose(float4x4(ps_screen_space_light_constants[0], ps_screen_space_light_constants[1], ps_screen_space_light_constants[2], ps_screen_space_light_constants[3]));

// ps_screen_space_light_constants[4 is the light color tint

#define LIGHT_FAR_ATTENUATION_END	(ps_screen_space_light_constants[5].x)
#define LIGHT_FAR_ATTENUATION_RATIO	(ps_screen_space_light_constants[5].y)
#define LIGHT_COSINE_CUTOFF_ANGLE	(ps_screen_space_light_constants[5].z)
#define LIGHT_ANGLE_FALLOFF_RAIO	(ps_screen_space_light_constants[5].w)
#define LIGHT_ANGLE_FALLOFF_POWER	(ps_screen_space_light_constants[4].w)
#define CAMERA_TO_LIGHT				(ps_screen_space_light_constants[6].xyz)

float3 calculate_relative_world_position(float2 texcoord, float depth)
{
	float4 clip_space_position = float4(texcoord.xy, depth, 1.0f);
	float4 world_space_position = mul(clip_space_position, transpose(screen_to_relative_world));
	return world_space_position.xyz / world_space_position.w;
}

void default_vs(
	in s_tiny_position_vertex input,
	out float4 screen_position : SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(DEFORM, input, output, local_to_world_transform, screen_position);
}

void light_calculation(
   in float2 pixel_pos,
   out float3 color,
   out float3 camera_to_fragment,
   out float4 normal)
{
#ifdef pc
 	color = 0.0f;
	camera_to_fragment = 0;
	normal = 0;
#else
	float3 light_to_fragment;		
	float4 albedo;
	float depth;
	asm
	{
		tfetch2D depth.x,	pixel_pos, depth_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
		tfetch2D normal,	pixel_pos, normal_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
		tfetch2D albedo,	pixel_pos, albedo_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
	};		
	albedo.w *= albedo.w;
	light_to_fragment =	calculate_relative_world_position(pixel_pos, depth);	

	float distance_falloff, cosine_lobe;
	{
		float distance2 = dot(light_to_fragment, light_to_fragment);
		float distance = sqrt(distance2);
		light_to_fragment = light_to_fragment / distance;
		
		cosine_lobe = saturate(dot(-light_to_fragment, normal));
	    SQUARE_FALLOFF_SS(cosine_lobe);

		distance_falloff = 1 / distance2;
	}
	
	float3 irradiance = LIGHT_COLOR * distance_falloff * VMF_BANDWIDTH;
	color =	irradiance * cosine_lobe / pi * albedo;
#endif
}


SHADER_ATTRIBUTES
float4 default_ps(
	in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target0
{
	float3 color;
	float3 camera_to_fragment;
	float4 normal;

	light_calculation(pixel_pos, color, camera_to_fragment,normal);   
	float4 final = apply_exposure(float4(color.rgb, 1.0f));

	return final;
}


BEGIN_TECHNIQUE _default
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

