#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, psDepthSampler, s14);

DECLARE_PARAMETER(float4, psDepthConstants, c2);

#elif DX_VERSION == 11

CBUFFER_BEGIN(DepthFadePS)
	CBUFFER_CONST(DepthFadePS,	float4, 	psDepthConstants, 	k_ps_depth_fade_depth_constants)	
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	psDepthSampler, 		k_ps_depth_fade_depth_sampler,		14)

#endif
