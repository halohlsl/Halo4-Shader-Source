#define PARTICLE_EXTRA_INTERPOLATOR

#include "fx/particle_core.fxh"

#define BASEMAP_HELP_TEXT "This texture will scroll, and its R value will be used as the u-coordinate into the palette texture.  It should be a luminance-texture."

#include "fx/esoteric/particle_scrolling_uv_distorted.fxh"
	
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
	float4 color = SampleBaseAndAlphaMap(particle_values, sphereWarp);
	
	float2 paletteCoord = float2(color.r, particle_values.palette);
	float4 paletteValue = sample2DGamma(palette, paletteCoord);
	color = paletteTextureSuppliesAlpha ? paletteValue : float4(paletteValue.rgb, color.a);

	return color;
}

#include "fx/particle_techniques.fxh"