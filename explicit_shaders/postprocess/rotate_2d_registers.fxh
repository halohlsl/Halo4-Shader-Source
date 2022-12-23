#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, 	ps_source_sampler,			s0);
DECLARE_PARAMETER(sampler2D, 	ps_background_sampler,		s1);

DECLARE_PARAMETER(float2,		ps_offset,					c3);

#elif DX_VERSION == 11

CBUFFER_BEGIN(Rotate2DPS)
	CBUFFER_CONST(Rotate2DPS,		float2,		ps_offset,		k_ps_rotate2d_offset)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler,			k_ps_rotate2d_source_sampler,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_background_sampler,		k_ps_rotate2d_background_sampler,		1)

#endif
