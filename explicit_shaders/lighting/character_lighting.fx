/*
CHARACTER_LIGHTING.HLSL
Copyright (c) Microsoft Corporation, 2008. all rights reserved.
08/12/2009 corrinyu
*/

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "character_lighting_registers.fxh"
#include "ss_light_registers.fxh"

// corrinyu: TO DO: Can I do better?
// VS 4 GPR 32 cycles
// PS 4 GPR 20 cycles

#define SHADER_ATTRIBUTES [maxtempreg(4)]
#define COMBINE_LOBES(cosine_lobe, albedo) (cosine_lobe * albedo.rgb)
#define LIGHT_COLOR (ps_screen_space_light_constants[4].rgb)
// spotlight transform
//#define DEFORM deform_tiny_position_projective
// point light transform
#define DEFORM deform_tiny_position

/*
#define LDR_ALPHA_ADJUST ps_exposure.w
#define HDR_ALPHA_ADJUST ps_exposure.b
#define DARK_COLOR_MULTIPLIER ps_exposure.g
*/

// p_lighting_constant_4 is the light color tint

#define LIGHT_FALLOFF_SCALE									(ps_screen_space_light_constants[5].x)
#define LIGHT_FALLOFF_OFFSET								(ps_screen_space_light_constants[5].y)

#define CAMERA_TO_LIGHT										(ps_screen_space_light_constants[6].xyz)

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

SHADER_ATTRIBUTES
float4 default_ps(
	in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target0
{
#ifdef pc
 	float3 color= 0.0f;
#else

	float3 light_to_fragment;
	float3 camera_to_fragment;
	float4 normal;
	float4 albedo;
	{
		float depth;
		asm
		{
			tfetch2D depth.x,	pixel_pos, depth_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
			tfetch2D normal,	pixel_pos, normal_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
			tfetch2D albedo,	pixel_pos, albedo_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
		};		
		light_to_fragment=	calculate_relative_world_position(pixel_pos, depth);	
		camera_to_fragment= CAMERA_TO_LIGHT + light_to_fragment;
	}

	// convert from worldspace to lightspace
	float3 light_to_fragment_lightspace= mul(light_to_fragment, ps_light_rotation);
	
	[isolate]
	float distance_falloff, cosine_lobe;
	{	
		float distance2 = dot(light_to_fragment, light_to_fragment);
		float distance = sqrt(distance2);
		light_to_fragment = light_to_fragment / distance;

		float falloff2 = saturate(distance * LIGHT_FALLOFF_SCALE + LIGHT_FALLOFF_OFFSET);
		cosine_lobe = saturate(dot(-light_to_fragment, normal));

		distance_falloff = falloff2 * falloff2;
	}
	
	float3 color=	distance_falloff * COMBINE_LOBES(cosine_lobe, albedo) * LIGHT_COLOR;
#endif
	
	return apply_exposure(float4(color.rgb, 1.0f));
}




BEGIN_TECHNIQUE _default
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
