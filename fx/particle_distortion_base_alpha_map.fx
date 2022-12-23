#define RENDER_DISTORTION

#include "fx/particle_core.fxh"

DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
	
DECLARE_SAMPLER(alpha_map, "Alpha Map Texture", "Alpha Map Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_BOOL_WITH_DEFAULT(useAlphaMapRed, "Alpha Map Use Red", "", true);
#include "next_bool_parameter.fxh"
DECLARE_BOOL_WITH_DEFAULT(useAlphaMapGreen, "Alpha Map Use Green", "", false);
#include "next_bool_parameter.fxh"

float2 PixelComputeDisplacement(
	in s_particle_interpolated_values particle_values)
{
	float3 color;
	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_billboard, basemap_transform), particle_values.texcoord_sprite0.x);
#if DX_VERSION == 11
		color = sampleArrayWith3DCoords(basemap, texcoord).rgb;
#else
		color = sample3D(basemap, texcoord).rgb;
#endif
	}
	else
	{
		// old-school
		color= sample3D(basemap, float3(transform_texcoord(particle_values.texcoord_sprite0, basemap_transform), 0.0)).rgb;
	}

	float4 alphaMapValue = sample2D(alpha_map, transform_texcoord(particle_values.texcoord_billboard, alpha_map_transform));
	float alpha = useAlphaMapRed ? alphaMapValue.r : (useAlphaMapGreen ? alphaMapValue.g : alphaMapValue.a);

	return color.rg * alpha;
}

#include "fx/particle_techniques.fxh"