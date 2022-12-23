#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, 	ps_source_sampler,			s0);
DECLARE_PARAMETER(sampler2D, 	ps_source_add_sampler,		s1);

DECLARE_PARAMETER(float4,		ps_kernel[5],				c3);		// 5 tap ps_kernel, (x offset, y offset, weight),  offsets should be premultiplied by ps_pixel_size

#elif DX_VERSION == 11

CBUFFER_BEGIN(Kernel5PS)
	CBUFFER_CONST_ARRAY(Kernel5PS,	float4,		ps_kernel, [5],		k_ps_kernel_5_kernel)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler,			k_ps_kernel_5_source_sampler,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_add_sampler,		k_ps_kernel_5_source_add_sampler,		1)

#endif