#include "core/core.fxh"

#define TEMPORAL_ANTIALIASING


#if defined(xenon) || (DX_VERSION == 11)

#define COMBINE		combine_dof
#define COMBINE_AA	combine_dof_antialiased

float4 combine_dof(in float2 texcoord);
float4 combine_dof_antialiased(in float2 texcoord, in bool centered);

#endif // defined(xenon)


#include "../postprocess/final_composite_shared.fxh"


#if defined(xenon) || (DX_VERSION == 11)


float4 combine_dof(in float2 texcoord)
{
	return SimpleDOFFilter(texcoord, ps_surface_sampler, false, ps_blur_sampler, ps_depth_sampler, ps_depth_constants);
}

float4 combine_dof_antialiased(in float2 texcoord, in bool centered)
{
	// ###ctchou $TODO
	return SimpleDOFFilter(texcoord, ps_surface_sampler, false, ps_blur_sampler, ps_depth_sampler, ps_depth_constants);
}

#endif
