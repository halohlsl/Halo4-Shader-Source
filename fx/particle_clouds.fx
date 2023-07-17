// need a tangent frame to use the normal map
#define PARTICLE_EXTRA_INTERPOLATOR
#define PASS_TANGENT_FRAME

#include "fx/particle_core.fxh"

DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(cloud_lighting_mask, "Cloud Lighting Mask", "Cloud Lighting Mask", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif")
#include "next_texture.fxh"

// do the color shuffle
float4 pixel_compute_color(
	in s_particle_interpolated_values particle_values,
	in float2 sphereWarp,
	in float depthFade)
{
	float4 color;
	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_billboard + sphereWarp, basemap_transform), particle_values.texcoord_sprite0.x);
#if DX_VERSION == 11
		color = sampleArrayWith3DCoordsGamma(basemap, texcoord);
#else
		color = sample3DGamma(basemap, texcoord);
#endif
	}
	else
	{
		// old-school
		color= sample3DGamma(basemap, float3(transform_texcoord(particle_values.texcoord_sprite0 + sphereWarp, basemap_transform), 0.0));
	}

	return color;
}

#define MODIFY_NORMAL
float3 ModifyNormal(in s_particle_interpolated_values particle_values)
{
	float3 normal = sample_2d_normal_approx(normal_map, transform_texcoord(particle_values.texcoord_billboard, normal_map_transform));
	normal = normalize(mul(normal, float3x3(particle_values.tangent, particle_values.binormal, particle_values.normal)));

	return normal;
}

#define CUSTOM_LIGHTING_MODEL
float3 CustomLighting(
	in float3 particleColor,
	in s_particle_interpolated_values particleValues)
{
	float4 cloudLightingMask = sample2DGamma(cloud_lighting_mask, transform_texcoord(particleValues.texcoord_billboard, cloud_lighting_mask_transform));

	float cosine = dot(particleValues.normal.xyz, psLightingBrightDirection.xyz);

	float negativeInfluence = pow(saturate(dot(normalize(particleValues.custom_value2.xyz - ps_camera_position), psLightingBrightDirection.xyz)), 4);

	float biased = saturate(cosine * LightingContrastScale + LightingContrastOffset);
	float blend = pow(biased, 3);
	float3 lightColor = lerp(psLightingDarkColor.rgb, psLightingBrightColor.rgb, blend) + cloudLightingMask.rgb * negativeInfluence * psLightingBrightColor.rgb;
	return particleColor * lerp(float3(1.0, 1.0, 1.0), lightColor, LightingStrength);
}


void FillExtraInterpolator(
	in s_particle_memexported_state state,
	inout s_particle_interpolated_values particleValues)
{
	float3 position = mul(vs_emitter_to_world_matrix, float4(state.m_position, 1.0f));
	position -= normalize(vs_view_camera_position - position) * vsRenderState.curvature_cameraOffset.y;

	particleValues.custom_value2.xyz = position.xyz;
	particleValues.custom_value2.w = 1.0f;
}



#include "fx/particle_techniques.fxh"