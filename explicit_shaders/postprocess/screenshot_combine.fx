#define CALC_BLOOM calc_bloom_screenshot
float4 calc_bloom_screenshot(in float2 texcoord);

#include "../postprocess/final_composite_shared.fxh"
#include "screenshot_combine_registers.fxh"

float4 calc_bloom_screenshot(in float2 texcoord)
{
	// sample bloom super-smooth bspline!
	return tex2D_bspline(ps_bloom_sampler, transform_texcoord(texcoord, ps_bloom_sampler_xform));
}
