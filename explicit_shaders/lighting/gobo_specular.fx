/*
gobo_specular.fx
Copyright (c) Microsoft Corporation, 2008. all rights reserved.
08/12/2009 corrinyu

[tholmes: 2011.05.11] This is actually now a general purpose screen space light shader
*/

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "core/core_functions.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "deform.fxh"
#include "lighting/shadows.fxh"
#include "ss_light_registers.fxh"

#define LIGHT_COLOR												(ps_screen_space_light_constants[4].rgb)
#define DEFORM													deform_tiny_position


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

// ps_screen_space_light_constants[4] is the light color tint

#define LIGHT_FAR_ATTENUATION_END	(ps_screen_space_light_constants[5].x)
#define LIGHT_FAR_ATTENUATION_RATIO	(ps_screen_space_light_constants[5].y)
#define LIGHT_COSINE_CUTOFF_ANGLE	(ps_screen_space_light_constants[5].z)
#define LIGHT_ANGLE_FALLOFF_RATIO	(ps_screen_space_light_constants[5].w)
#define LIGHT_ANGLE_FALLOFF_POWER	(ps_screen_space_light_constants[4].w)
#define CAMERA_TO_LIGHT				(ps_screen_space_light_constants[6].xyz)
#define LIGHT_DIRECTION				(ps_screen_space_light_constants[9].xyz)
#define LIGHT_PROJECTION			(ps_screen_space_light_constants[13].xy)
#define LIGHT_SPECULAR_SCALAR		(ps_screen_space_light_constants[13].z)
#define LIGHT_DIFFUSE_SCALAR		(ps_screen_space_light_constants[13].w)

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
   out float3 light_to_fragment_unnormalized,
   uniform bool spotFalloff,
   uniform bool specularEnabled)
{
#if (!defined(xenon) && (DX_VERSION == 9))
 	color = 0.0f;
	light_to_fragment_unnormalized = 0;
#else
	float3 camera_to_fragment;
	float4 normal, albedo;
	float depth;
	
#ifdef xenon	
	asm
	{
		tfetch2D depth.x,	pixel_pos, depth_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled, UseComputedLOD=false
		tfetch2D normal,	pixel_pos, normal_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled, UseComputedLOD=false
		tfetch2D albedo,	pixel_pos, albedo_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled, UseComputedLOD=false
	};

	normal.xyz = DecodeWorldspaceNormalSigned(normal.xy);
#else
	int3 int_pixel_pos = int3(pixel_pos, 0);
	depth = depth_sampler.t.Load(int_pixel_pos).x;
	normal = normal_sampler.t.Load(int_pixel_pos);
	albedo = albedo_sampler.t.Load(int_pixel_pos);

	normal.xyz = DecodeWorldspaceNormal(normal.xy);
#endif	
	
	light_to_fragment_unnormalized =	calculate_relative_world_position(pixel_pos, depth);
	camera_to_fragment = CAMERA_TO_LIGHT + light_to_fragment_unnormalized;

	float3 light_to_fragment;
	float falloff, cosine_lobe;
	{
		float distance2 = dot(light_to_fragment_unnormalized, light_to_fragment_unnormalized);
		float distance = sqrt(distance2);
		light_to_fragment = light_to_fragment_unnormalized / distance;

		cosine_lobe = saturate(dot(-light_to_fragment, normal));
		SQUARE_FALLOFF_SS(cosine_lobe);

		// linear^3 is a closer approximation to distance^2 than linear^2
		float distance_falloff = saturate(LIGHT_FAR_ATTENUATION_END + distance * LIGHT_FAR_ATTENUATION_RATIO);
		falloff = distance_falloff * distance_falloff * distance_falloff;

		// spot falloff if there
		if (spotFalloff)
		{
			float spot_falloff;
			spot_falloff = saturate(dot(light_to_fragment, LIGHT_DIRECTION) * LIGHT_ANGLE_FALLOFF_RATIO + LIGHT_COSINE_CUTOFF_ANGLE);
			spot_falloff = pow(spot_falloff, LIGHT_ANGLE_FALLOFF_POWER);
			falloff *= spot_falloff;
		}
	}


	float specular_lobe = 0;
	if (specularEnabled)
	{
		// blinn lobe
		float3 view_dir = normalize(camera_to_fragment);
		float3 H = normalize(-light_to_fragment - view_dir);
		float NdotH = saturate(dot(H, normal));

		float specular_power = 50;
		specular_lobe = pow(NdotH, specular_power);
	}

	falloff *= (cosine_lobe * LIGHT_DIFFUSE_SCALAR + specular_lobe * LIGHT_SPECULAR_SCALAR);
	color =	falloff * LIGHT_COLOR * albedo.xyz;
#endif
}


SHADER_ATTRIBUTES
float4 default_ps(
	in SCREEN_POSITION_INPUT(pixel_pos),
	uniform bool useGobo,
	uniform bool useShadow,
	uniform bool spotFalloff,
	uniform bool specularEnabled) : SV_Target0
{
	float3 color;
	float3 light_to_fragment;

	light_calculation(
		pixel_pos,
		color,
		light_to_fragment,
		spotFalloff,
		specularEnabled);

#if defined(xenon) || (DX_VERSION == 11)
	if (useGobo || useShadow)
	{
		if (useGobo)
		{
			float3 light_to_fragment_lightspace = mul(float4(light_to_fragment, 1.0f), ps_screen_space_light_rotation);
			light_to_fragment_lightspace.xy /= light_to_fragment_lightspace.z;

			color *= sample2D(gobo_sampler, light_to_fragment_lightspace.yx).rgb;
		}
		if (useShadow)
		{
			float3 light_to_fragment_lightspace = mul(light_to_fragment, ps_screen_space_shadow_rotation);
			light_to_fragment_lightspace.xy /= light_to_fragment_lightspace.z;
			light_to_fragment_lightspace.z = (-light_to_fragment_lightspace.z * LIGHT_PROJECTION.x + LIGHT_PROJECTION.y) / light_to_fragment_lightspace.z;

			color *= midgraph_poisson_shadow_8tap(light_to_fragment_lightspace.yxz, pixel_pos);
		}
	}
#endif

	return float4(color.rgb, 1); // test
}



#define MAKE_SS_LIGHT_TECHNIQUE(gobo, shadow, spot, specular)					\
BEGIN_TECHNIQUE { pass tiny_position {												\
	SET_VERTEX_SHADER(default_vs());									\
	SET_PIXEL_SHADER(default_ps(gobo, shadow, spot, specular));}}

MAKE_SS_LIGHT_TECHNIQUE(false,	false,	false,	false)
MAKE_SS_LIGHT_TECHNIQUE(true,	false,	false,	false)
MAKE_SS_LIGHT_TECHNIQUE(false,	true,	false,	false)
MAKE_SS_LIGHT_TECHNIQUE(true,	true,	false,	false)
MAKE_SS_LIGHT_TECHNIQUE(false,	false,	true,	false)
MAKE_SS_LIGHT_TECHNIQUE(true,	false,	true,	false)
MAKE_SS_LIGHT_TECHNIQUE(false,	true,	true,	false)
MAKE_SS_LIGHT_TECHNIQUE(true,	true,	true,	false)
MAKE_SS_LIGHT_TECHNIQUE(false,	false,	false,	true)
MAKE_SS_LIGHT_TECHNIQUE(true,	false,	false,	true)
MAKE_SS_LIGHT_TECHNIQUE(false,	true,	false,	true)
MAKE_SS_LIGHT_TECHNIQUE(true,	true,	false,	true)
MAKE_SS_LIGHT_TECHNIQUE(false,	false,	true,	true)
MAKE_SS_LIGHT_TECHNIQUE(true,	false,	true,	true)
MAKE_SS_LIGHT_TECHNIQUE(false,	true,	true,	true)
MAKE_SS_LIGHT_TECHNIQUE(true,	true,	true,	true)

