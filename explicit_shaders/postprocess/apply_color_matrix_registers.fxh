#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, ps_source_sampler,		s0);

DECLARE_PARAMETER(float4, dest_red,		c3);
DECLARE_PARAMETER(float4, dest_green,	c4);
DECLARE_PARAMETER(float4, dest_blue,	c5);
DECLARE_PARAMETER(float4, dest_alpha,	c6);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ApplyColorMatrixPS)
	CBUFFER_CONST(ApplyColorMatrixPS,		float4,		dest_red,		k_ps_apply_color_matrix_dest_red)
	CBUFFER_CONST(ApplyColorMatrixPS,		float4,		dest_green,		k_ps_apply_color_matrix_dest_green)
	CBUFFER_CONST(ApplyColorMatrixPS,		float4,		dest_blue,		k_ps_apply_color_matrix_dest_blue)
	CBUFFER_CONST(ApplyColorMatrixPS,		float4,		dest_alpha,		k_ps_apply_color_matrix_dest_alpha)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler,		k_ps_apply_color_matrix_source_sampler,			0)

#endif