#define PARTICLE_EXTRA_INTERPOLATOR

#include "fx/particle_core.fxh"

#define BASEMAP_HELP_TEXT "This texture will scroll, and its R value will be used as the u-coordinate into the palette texture.  It should be a luminance-texture."

#include "fx/esoteric/particle_scrolling.fxh"
	
DECLARE_SAMPLER(palette, "Palette Texture", "Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

// do the color shuffle
float4 pixel_compute_color(
	in s_particle_interpolated_values particle_values,
	in float2 sphereWarp,
	in float depthFade)
{
	float2 scrollingUV = transform_texcoord(particle_values.custom_value2.xy + sphereWarp, basemap_transform);
	float4 color;
	color.rgb = sample2DPalettizedScrolling(basemap, palette, scrollingUV, particle_values.palette, false).rgb;

	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_billboard, alphaMap_transform), particle_values.texcoord_sprite0.x);
#if DX_VERSION == 11
		float4 alphaMapValue = sampleArrayWith3DCoords(alphaMap, texcoord);
#else
		float4 alphaMapValue = sample3D(alphaMap, texcoord);
#endif
		
		color.a = useAlphaMapRed ? alphaMapValue.r : alphaMapValue.a;
	}
	else
	{
		// old-school
		float4 alphaMapValue = sample3D(alphaMap, float3(transform_texcoord(particle_values.texcoord_sprite0, alphaMap_transform), 0.0));
		color.a = useAlphaMapRed ? alphaMapValue.r : alphaMapValue.a;
	}

	return color;
}

#include "fx/particle_techniques.fxh"