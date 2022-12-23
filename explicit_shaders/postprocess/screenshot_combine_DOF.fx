#if defined(xenon)
#define COMBINE combine_dof
float4 combine_dof(in float2 texcoord);
#endif // !pc

#define CALC_BLOOM calc_bloom_screenshot
float4 calc_bloom_screenshot(in float2 texcoord);


#include "../postprocess/final_composite_shared.fxh"
#include "screenshot_combine_registers.fxh"


#if defined(xenon)
float4 combine_dof(in float2 texcoord)
{
	return SimpleDOFFilter(texcoord, ps_surface_sampler, false, ps_blur_sampler, ps_depth_sampler, ps_depth_constants);
}
#endif // defined(xenon)


float4 calc_bloom_screenshot(in float2 texcoord)
{
	// sample bloom super-smooth bspline!
	return tex2D_bspline(ps_bloom_sampler, transform_texcoord(texcoord, ps_bloom_sampler_xform));
}
