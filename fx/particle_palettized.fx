#include "fx/particle_core.fxh"

DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
	
DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(paletteTextureSuppliesAlpha, "Palette Texture Supplies Alpha", "", false);
#include "next_bool_parameter.fxh"

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
		color = sample3DPalettizedScrolling(basemap, palette, texcoord, particle_values.palette, paletteTextureSuppliesAlpha);
	}
	else
	{
		// old-school
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_sprite0 + sphereWarp, basemap_transform), 0.0);
		color= sample3DPalettizedScrolling(basemap, palette, texcoord, particle_values.palette, paletteTextureSuppliesAlpha);
	}

	return color;
}

#include "fx/particle_techniques.fxh"