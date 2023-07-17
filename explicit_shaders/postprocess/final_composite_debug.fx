
#define TEMPORAL_ANTIALIASING


#if defined(xenon)
#define COMBINE_HDR_LDR combine_dof
float4 combine_dof(in float2 texcoord);
#endif // !pc

float4 default_combine_hdr_ldr(in float2 texcoord);							// supports multiple sources and formats, but much slower than the optimized version
#define COMBINE default_combine_hdr_ldr


#include "../postprocess/final_composite_shared.fxh"


float4 default_combine_hdr_ldr(in float2 texcoord)							// supports multiple sources and formats, but much slower than the optimized version
{
	float4 accum=		sample2D(ps_surface_sampler, texcoord);
	float4 accum_dark=	sample2D(ps_dark_surface_sampler, texcoord);
	float4 combined=	max(accum, accum_dark * DARK_COLOR_MULTIPLIER);		// convert_from_render_targets <-- for some reason this isn't optimized very well
	return combined;
}

