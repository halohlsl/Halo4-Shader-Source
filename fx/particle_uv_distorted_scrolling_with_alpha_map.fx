#define PARTICLE_EXTRA_INTERPOLATOR

#include "fx/particle_core.fxh"

#define BASEMAP_HELP_TEXT "This texture will scroll, and be sampled for the RGBA of the particle."

#include "fx/esoteric/particle_scrolling_uv_distorted.fxh"

// do the color shuffle
float4 pixel_compute_color(
	in s_particle_interpolated_values particle_values,
	in float2 sphereWarp,
	in float depthFade)
{
	return SampleBaseAndAlphaMap(particle_values, sphereWarp);
}

#include "fx/particle_techniques.fxh"