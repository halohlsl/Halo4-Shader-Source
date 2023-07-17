#define PARTICLE_EXTRA_INTERPOLATOR

#include "fx/particle_core.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(top_offset, "Top Offset", "", 0, 10, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(bottom_offset, "Bottom Offset", "", -10, 0, float(-1.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(bottom_aligned_override_cutoff, "Bottom Aligned Override Cutoff", "", 0, 1, float(0.1));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(bottom_aligned_override_range, "Bottom Aligned Override Range", "", 0, 1, float(0.3));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(bottom_rim_light_size_u, "Bottom Rim Light Size U", "", 0, 10, float(1));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(bottom_rim_light_size_v, "Bottom Rim Light Size V", "", 0, 10, float(1));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(top_aligned_override_cutoff, "Top Aligned Override Cutoff", "", 0, 1, float(0.1));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(top_aligned_override_range, "Top Aligned Override Range", "", 0, 1, float(0.3));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(height_axis_x, "Height Axis X", "", -1, 1, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(height_axis_y, "Height Axis Y", "", -1, 1, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(height_axis_z, "Height Axis Z", "", -1, 1, float(1.0));
#include "used_vertex_float.fxh"

#define CUSTOM_VERTEX_PROCESSING
void CustomVertexProcessing(s_particle_memexported_state STATE, float3 worldPos, inout s_particle_interpolated_values out_values)
{
	float3 emitterPosition = float3(vs_emitter_to_world_matrix[0].w, vs_emitter_to_world_matrix[1].w, vs_emitter_to_world_matrix[2].w);
	float3 relativePosition = worldPos - emitterPosition;
	float3 heightVector = normalize(float3(height_axis_x, height_axis_y, height_axis_z));
	float relativeHeight = dot(relativePosition, heightVector);
	out_values.palette = 1.0 - ((relativeHeight - bottom_offset) / (top_offset - bottom_offset));
	
	float3 viewVector = normalize(vs_view_camera_position - emitterPosition);
	float viewDotHeight = dot(viewVector, heightVector);
	float topProximity = 1.0 - viewDotHeight;
	float bottomProximity = 1.0 + viewDotHeight;
	float topBlendOverride = saturate((top_aligned_override_cutoff + top_aligned_override_range - topProximity) / top_aligned_override_range);
	float bottomBlendOverride = saturate((bottom_aligned_override_cutoff + bottom_aligned_override_range - bottomProximity) / bottom_aligned_override_range);
	
	out_values.palette = lerp(out_values.palette, 0.0f, topBlendOverride);
	out_values.palette = lerp(out_values.palette, 1.0f, bottomBlendOverride);
	
	float3 rimLightVectorU = safe_normalize(cross(float3(0, 1, 0), heightVector));
	float3 rimLightVectorV = safe_normalize(cross(heightVector, rimLightVectorU));
	float2 rimLightTexCoord = float2(dot(relativePosition, rimLightVectorU) / bottom_rim_light_size_u, dot(relativePosition, rimLightVectorV) / bottom_rim_light_size_v);
	rimLightTexCoord += float2(0.5, 0.5);
	// rim light uv, 0.0f, rim light strength
	out_values.custom_value2 = float4(rimLightTexCoord, 0.0f, bottomBlendOverride);
}

void FillExtraInterpolator(
	in s_particle_memexported_state state,
	inout s_particle_interpolated_values particleValues)
{ }

//#include "particle_palettized.fx"
DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
	
DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(paletteTextureSuppliesAlpha, "Palette Texture Supplies Alpha", "", false);
#include "next_bool_parameter.fxh"

DECLARE_SAMPLER(bottom_rim_light_texture, "Bottom Rim Light Texture", "", "shaders\default_bitmaps\bitmaps\color_black.tif");
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(bottom_rim_light_strength, "Bottom Rim Light Strength", "", 0, 1, float(0.1));
#include "used_float.fxh"

// do the color shuffle
float4 pixel_compute_color(
	in s_particle_interpolated_values particle_values,
	in float2 sphereWarp,
	in float depthFade)
{
	float paletteValue = particle_values.palette;
	paletteValue -= particle_values.custom_value2.w * bottom_rim_light_strength * sample2D(bottom_rim_light_texture, particle_values.custom_value2.xy).r;

	float4 color;
	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_billboard + sphereWarp, basemap_transform), particle_values.texcoord_sprite0.x);
		color = sample3DPalettizedScrolling(basemap, palette, texcoord, paletteValue, paletteTextureSuppliesAlpha);
	}
	else
	{
		// old-school
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_sprite0 + sphereWarp, basemap_transform), 0.0);
		color= sample3DPalettizedScrolling(basemap, palette, texcoord, paletteValue, paletteTextureSuppliesAlpha);
	}
	
	return color;
}

#include "fx/particle_techniques.fxh"