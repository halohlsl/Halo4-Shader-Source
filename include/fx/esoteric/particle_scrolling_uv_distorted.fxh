#if !defined(__PARTICLE_SCROLLING_FXH)
#define __PARTICLE_SCROLLING_FXH

// helper file for all scrolling particle shaders

DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_SAMPLER_2D_ARRAY(alphaMap, "Alpha Map", "Alpha Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(useAlphaMapRed, "Alpha Map Use Red", "", true);
#include "next_bool_parameter.fxh"

DECLARE_BOOL_WITH_DEFAULT(transformAlphaMap, "Transform Alpha Map", "", false);
#include "next_bool_parameter.fxh"
DECLARE_BOOL_WITH_DEFAULT(transformBaseMap, "Transform Base Map", "", true);
#include "next_bool_parameter.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(map_slide_u, "Slide Rate U", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(map_slide_v, "Slide Rate V", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(map_scale_u, "Scale U", "", 0.1, 5, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(map_scale_v, "Scale V", "", 0.1, 5, float(1.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(map_scale_rate_u, "Scale Rate U", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(map_scale_rate_v, "Scale Rate V", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(map_rotation_rate, "Rotation Rate", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_BOOL_WITH_DEFAULT(map_random_offset, "Basemap Random Offset", "", true);
#include "next_vertex_bool_parameter.fxh"

DECLARE_SAMPLER(uv_distortion_map, "UV Distortion Map", "", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(distortionMapIsZeroCentered, "Distortion Map Is Zero-Centered", "", false);
#include "next_bool_parameter.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(uv_distortion_map_slide_u, "Slide Rate U", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(uv_distortion_map_slide_v, "Slide Rate V", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(basemap_uv_distortion_strength, "Basemap UV Distortion Strength", "", 0, 5, float(0.2));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(alpha_map_uv_distortion_strength, "Alpha Map UV Distortion Strength", "", 0, 5, float(0.2));
#include "used_float.fxh"

void FillExtraInterpolator(
	in s_particle_memexported_state state,
	inout s_particle_interpolated_values particleValues)
{
	float time = state.m_age / state.m_inverse_lifespan;
	
	float angle = time * map_rotation_rate;
	float2 sineCosine;
	sincos(angle, sineCosine.x, sineCosine.y);
	float2 rotatedCoord = particleValues.texcoord_billboard - float2(0.5f, 0.5f); // rotate about the center of the billboard
	
	rotatedCoord = float2(
		sineCosine.y * rotatedCoord.x - sineCosine.x * rotatedCoord.y,
		sineCosine.y * rotatedCoord.y + sineCosine.x * rotatedCoord.x);
		
	rotatedCoord += float2(0.5f, 0.5f); // restore original origin

	// interestingly, "scale" winds up being divided, as it's the scale of the bitmap, so texcoord size is the inverse of it
	float2 newScale = float2(
		map_scale_u * (map_scale_rate_u >= 0.0f ? (1.0f + time * map_scale_rate_u) : 1.0f / (1 + time * map_scale_rate_u)),
		map_scale_v * (map_scale_rate_v >= 0.0f ? (1.0f + time * map_scale_rate_v) : 1.0f / (1 + time * map_scale_rate_v)));
	
	particleValues.custom_value2.xy =
		rotatedCoord / newScale +
		(map_random_offset ? state.m_random2.xy : 0.0f) +
		time * float2(-map_slide_u, -map_slide_v); // make positive be up and left
	particleValues.custom_value2.zw = particleValues.texcoord_billboard + time * float2(-uv_distortion_map_slide_u, -uv_distortion_map_slide_v);
}

float4 SampleBaseAndAlphaMap(s_particle_interpolated_values particle_values, in float2 sphereWarp)
{
	float2 distortionValue = sample2D(uv_distortion_map, transform_texcoord(particle_values.custom_value2.zw, uv_distortion_map_transform)).rg;
	
	if (!distortionMapIsZeroCentered)
	{
		distortionValue -= float2(0.5, 0.5);
	}

	float2 basemapUV = transformBaseMap ? particle_values.custom_value2.xy : particle_values.texcoord_billboard;
	basemapUV = transform_texcoord(basemapUV + sphereWarp, basemap_transform) + distortionValue * basemap_uv_distortion_strength;
	float2 alphamapUV = transformAlphaMap ? particle_values.custom_value2.xy : particle_values.texcoord_billboard;
	alphamapUV = transform_texcoord(alphamapUV + sphereWarp, alphaMap_transform) + distortionValue * alpha_map_uv_distortion_strength;
	
	float4 color;

	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(basemapUV, particle_values.texcoord_sprite0.x);
#if DX_VERSION == 11
		color = sampleArrayWith3DCoordsGamma(basemap, texcoord);
#else
		color = sample3DGamma(basemap, texcoord);
#endif
		
		texcoord = float3(alphamapUV, particle_values.texcoord_sprite0.x);
#if DX_VERSION == 11
		float4 alphaMapValue = sampleArrayWith3DCoords(alphaMap, texcoord);
#else
		float4 alphaMapValue = sample3D(alphaMap, texcoord);
#endif
		
		color.a *= useAlphaMapRed ? alphaMapValue.r : alphaMapValue.a;
	}
	else
	{
		// old-school
		color = sample3DGamma(basemap, float3(basemapUV, 0.5f));
		float4 alphaMapValue = sample3D(alphaMap, float3(alphamapUV, 0.5f));
		color.a *= useAlphaMapRed ? alphaMapValue.r : alphaMapValue.a;
	}

	return color;
}

#endif 	// !defined(__PARTICLE_SCROLLING_FXH)