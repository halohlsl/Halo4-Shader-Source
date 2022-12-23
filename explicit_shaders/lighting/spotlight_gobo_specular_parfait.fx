/*
spotlight_gobo_specular_parfait.fx
Copyright (c) Microsoft Corporation, 2008. all rights reserved.
08/12/2009 corrinyu
*/

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "light_apply_base_registers.fxh"
#include "ss_light_registers.fxh"

#define COMBINE_LOBES(cosine_lobe, specular_lobe, albedo) (cosine_lobe * albedo.rgb + specular_lobe * albedo.a)
#define LIGHT_COLOR (ps_screen_space_light_constants[4] * sample2D(gobo_sampler, light_to_fragment_lightspace.yx / light_to_fragment_lightspace.z).rgb)
#define DEFORM deform_tiny_position_projective


#ifndef SHADER_ATTRIBUTES
#define SHADER_ATTRIBUTES 
#endif // SHADER_ATTRIBUTES

#define pi 3.14159265358979323846

LOCAL_SAMPLER2D(gobo_sampler, 4);

static float4x4 screen_to_relative_world=transpose(float4x4(ps_screen_space_light_constants[0], ps_screen_space_light_constants[1], ps_screen_space_light_constants[2], ps_screen_space_light_constants[3]));

// ps_screen_space_light_constants[4 is the light color tint

#define LIGHT_FAR_ATTENUATION_END	(ps_screen_space_light_constants[5].x)
#define LIGHT_FAR_ATTENUATION_RATIO	(ps_screen_space_light_constants[5].y)
#define LIGHT_COSINE_CUTOFF_ANGLE	(ps_screen_space_light_constants[5].z)
#define LIGHT_ANGLE_FALLOFF_RATIO	(ps_screen_space_light_constants[5].w)
#define LIGHT_ANGLE_FALLOFF_POWER	(ps_screen_space_light_constants[4].w)
#define CAMERA_TO_LIGHT				(ps_screen_space_light_constants[6].xyz)
#define CHEAP_ALBEDO_BLEND			(ps_screen_space_light_constants[9].w)

LOCAL_SAMPLER2D(shadow_depth_map_1, 5);

float3 compute_gobo(float3 light_to_fragment_lightspace)
{
	float2 uv = light_to_fragment_lightspace.yx / light_to_fragment_lightspace.z;
	float4 gobo = sample2D(gobo_sampler, uv);
	return ps_screen_space_light_constants[4].rgb * gobo.rgb;
}

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

void albedo_vs(
   in s_tiny_position_vertex vertex,
	out float4 screen_position : SV_Position)
{
	default_vs(vertex, screen_position);
}

void light_calculation(
   in float2 pixel_pos,
   out float3 color,
   out float3 camera_to_fragment,
   out float4 normal)
{
#if defined(pc) && (DX_VERSION == 9)
 	color = 0.0f;
	camera_to_fragment = 0;
	normal = 0;
#else
	float3 light_to_fragment;		
	float4 albedo;
	{	
		float depth;
#ifdef xenon	
		asm
		{
			tfetch2D depth.x,	pixel_pos, depth_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
			tfetch2D normal,	pixel_pos, normal_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
			tfetch2D albedo,	pixel_pos, albedo_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
		};	
#else
		int3 int_pixel_pos = int3(pixel_pos, 0);
		depth = depth_sampler.t.Load(int_pixel_pos).x;
		normal = normal_sampler.t.Load(int_pixel_pos);
		albedo = albedo_sampler.t.Load(int_pixel_pos);
#endif
		
		albedo.w *= albedo.w;
#ifdef xenon
		normal.xyz = DecodeWorldspaceNormalSigned(normal.xy);
#else
		normal.xyz = DecodeWorldspaceNormal(normal.xy);
#endif
		light_to_fragment =	calculate_relative_world_position(pixel_pos, depth);	
		camera_to_fragment = CAMERA_TO_LIGHT + light_to_fragment;
	}
	float3 light_to_fragment_lightspace = mul(light_to_fragment, ps_light_rotation);
	
	float distance_falloff, cosine_lobe, angle_falloff;
	{	
		float distance2 = dot(light_to_fragment, light_to_fragment);
		float distance = sqrt(distance2);
		light_to_fragment = light_to_fragment / distance;
		
		cosine_lobe = saturate(dot(-light_to_fragment, normal));
	    SQUARE_FALLOFF_SS(cosine_lobe);

		// $review why does linear here better approximate static falloff?
		distance_falloff = saturate((LIGHT_FAR_ATTENUATION_END - distance) * LIGHT_FAR_ATTENUATION_RATIO);
		angle_falloff = saturate((light_to_fragment_lightspace.z / distance - LIGHT_COSINE_CUTOFF_ANGLE) * LIGHT_ANGLE_FALLOFF_RATIO);
		angle_falloff = pow(angle_falloff, LIGHT_ANGLE_FALLOFF_POWER);
	}
	
	float3 specular_lobe;
	{
		// phong lobe
		float3 view_dir = - normalize(camera_to_fragment);
		float view_dot_normal = dot(view_dir, normal);
		float3 view_reflect_dir = view_dot_normal * normal * 2 - view_dir;
		if (normal.w < 1)
		{
			float specular_power = 50 - (50 - 8) * normal.w / 0.66f;
			float specular_cosine_lobe = saturate(dot(-light_to_fragment, view_reflect_dir));
			float3 final_specular_color = lerp(float3(1,1,1), albedo.xyz, CHEAP_ALBEDO_BLEND);
			specular_lobe = pow(specular_cosine_lobe, specular_power) * (1 + specular_power) * final_specular_color;
		}
		else
		{
			specular_lobe = 0;
		}
	}
	
	[predicateBlock]
	if (normal.w > 0.9f)
	{
		albedo.rgba = float4(0.09, 0.09f, 0.09f, 0.0f);
	}

	float3 irradiance = compute_gobo(light_to_fragment_lightspace) * distance_falloff * angle_falloff * VMF_BANDWIDTH;
	color =	irradiance * COMBINE_LOBES(cosine_lobe/pi, specular_lobe.rgb, albedo);
#endif
}


SHADER_ATTRIBUTES
float4 default_ps(in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target0
{
	float3 color;
	float3 camera_to_fragment;
	float4 normal;

	light_calculation(pixel_pos, color, camera_to_fragment, normal);   
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

