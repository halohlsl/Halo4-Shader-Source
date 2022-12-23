#define RENDER_DISTORTION

#include "fx/particle_core.fxh"

DECLARE_SAMPLER_2D_ARRAY(basemap, "Base Texture", "Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

float4 PixelComputeDisplacement(
	in s_particle_interpolated_values particle_values)
{
	float4 color;
	[branch]
	if (psNewSchoolFrameIndex)
	{
		// this means we're using new-school tex arrays instead of laid-out sprite sheets
		float3 texcoord = float3(transform_texcoord(particle_values.texcoord_billboard, basemap_transform), particle_values.texcoord_sprite0.x);
#if DX_VERSION == 11		
		color = sampleArrayWith3DCoords(basemap, texcoord);
#else
		color = sample3D(basemap, texcoord);
#endif
	}
	else
	{
		// old-school
		color= sample3D(basemap, float3(transform_texcoord(particle_values.texcoord_sprite0, basemap_transform), 0.0));
	}

	return color;
}

#include "fx/particle_techniques.fxh"