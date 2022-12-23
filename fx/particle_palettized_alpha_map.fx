#include "fx/particle_core.fxh"

DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
	
DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
	
DECLARE_SAMPLER(alpha_map, "Alpha Map Texture", "Alpha Map Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(useAlphaMapRed, "Alpha Map Use Red", "", false);
#include "next_bool_parameter.fxh"

// do the color shuffle
float4 pixel_compute_color(
	in s_particle_interpolated_values particle_values,
	in float2 sphereWarp,
	in float depthFade)
{
	float3 color;
	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_billboard + sphereWarp, basemap_transform), particle_values.texcoord_sprite0.x);
		color = sample3DPalettizedScrolling(basemap, palette, texcoord, particle_values.palette, false).rgb;
	}
	else
	{
		// old-school
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_sprite0 + sphereWarp, basemap_transform), 0.0);
		color= sample3DPalettizedScrolling(basemap, palette, texcoord, particle_values.palette, false).rgb;
	}

	float4 alphaMapValue = sample2D(alpha_map, transform_texcoord(particle_values.texcoord_billboard, alpha_map_transform));
	float alpha = useAlphaMapRed ? alphaMapValue.r : alphaMapValue.a;

	return float4(color, alpha);
}

#include "fx/particle_techniques.fxh"