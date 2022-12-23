#if !defined(__PARTICLE_SCROLLING_FXH)
#define __PARTICLE_SCROLLING_FXH

// helper file for all scrolling particle shaders

DECLARE_SAMPLER(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(basemap_slide_u, "Slide Rate U", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(basemap_slide_v, "Slide Rate V", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(basemap_scale_u, "Scale U", "", 0.1, 5, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(basemap_scale_v, "Scale V", "", 0.1, 5, float(1.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(basemap_scale_rate_u, "Scale Rate U", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(basemap_scale_rate_v, "Scale Rate V", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(basemap_rotation_rate, "Rotation Rate", "", -5, 5, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_SAMPLER_2D_ARRAY(alphaMap, "Alpha Map", "Alpha Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(useAlphaMapRed, "Alpha Map Use Red", "", true);
#include "next_bool_parameter.fxh"

DECLARE_VERTEX_BOOL_WITH_DEFAULT(basemap_random_offset, "Basemap Random Offset", "", true);
#include "next_vertex_bool_parameter.fxh"

void FillExtraInterpolator(
	in s_particle_memexported_state state,
	inout s_particle_interpolated_values particleValues)
{
	float time = state.m_age / state.m_inverse_lifespan;
	
	float angle = time * basemap_rotation_rate;
	float2 sineCosine;
	sincos(angle, sineCosine.x, sineCosine.y);
	float2 rotatedCoord = particleValues.texcoord_billboard - float2(0.5f, 0.5f); // rotate about the center of the billboard
	
	rotatedCoord = float2(
		sineCosine.y * rotatedCoord.x - sineCosine.x * rotatedCoord.y,
		sineCosine.y * rotatedCoord.y + sineCosine.x * rotatedCoord.x);
		
	rotatedCoord += float2(0.5f, 0.5f); // restore original origin

	// interestingly, "scale" winds up being divided, as it's the scale of the bitmap, so texcoord size is the inverse of it
	float2 newScale = float2(
		basemap_scale_u * (basemap_scale_rate_u >= 0.0f ? (1.0f + time * basemap_scale_rate_u) : 1.0f / (1 + time * basemap_scale_rate_u)),
		basemap_scale_v * (basemap_scale_rate_v >= 0.0f ? (1.0f + time * basemap_scale_rate_v) : 1.0f / (1 + time * basemap_scale_rate_v)));
	
	particleValues.custom_value2.xy =
		rotatedCoord / newScale +
		(basemap_random_offset ? state.m_random2.xy : 0.0f) +
		time * float2(-basemap_slide_u, -basemap_slide_v); // make positive be up and left
	particleValues.custom_value2.zw = 0.0;
}

#endif 	// !defined(__PARTICLE_SCROLLING_FXH)