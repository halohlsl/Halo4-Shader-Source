#if DX_VERSION == 9

DECLARE_PARAMETER(float, ps_block_size,		c80);
DECLARE_PARAMETER(bool, ps_odd_bits,		b1);

#elif DX_VERSION == 11

CBUFFER_BEGIN(StencilStipplePS)
	CBUFFER_CONST(StencilStipplePS,	float,		ps_block_size,		k_ps_stencil_stipple_block_size)
	CBUFFER_CONST(StencilStipplePS,	float3,		ps_block_size_pad,	k_ps_stencil_stipple_block_size_pad)
	CBUFFER_CONST(StencilStipplePS,	bool,		ps_odd_bits,		k_ps_stencil_stipple_bool_odd_bits)
CBUFFER_END

#endif
