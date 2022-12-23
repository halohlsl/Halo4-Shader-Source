#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, tex0, s0);
DECLARE_PARAMETER(sampler, tex1, s1);
DECLARE_PARAMETER(sampler, tex2, s2);
DECLARE_PARAMETER(sampler, tex3, s3);

DECLARE_PARAMETER(float4, tor, c3);
DECLARE_PARAMETER(float4, tog, c4);
DECLARE_PARAMETER(float4, tob, c5);
DECLARE_PARAMETER(float4, consts, c6);

#elif DX_VERSION == 11

CBUFFER_BEGIN(YUVToRGBPS)
	CBUFFER_CONST(YUVToRGBPS,		float4,		consta,		k_ps_yuv_to_rgb_consta)
	CBUFFER_CONST(YUVToRGBPS,		float4,		crc,		k_ps_yuv_to_rgb_crc)
	CBUFFER_CONST(YUVToRGBPS,		float4,		cbc,		k_ps_yuv_to_rgb_cbc)
	CBUFFER_CONST(YUVToRGBPS,		float4,		adj,		k_ps_yuv_to_rgb_adj)
	CBUFFER_CONST(YUVToRGBPS,		float4,		yscale,		k_ps_yuv_to_rgb_yscale)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex0, 	k_ps_yuv_to_rgb_tex0,	0);
PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex1, 	k_ps_yuv_to_rgb_tex1,	1);
PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex2, 	k_ps_yuv_to_rgb_tex2,	2);
PIXEL_TEXTURE_AND_SAMPLER(_2D,	tex3, 	k_ps_yuv_to_rgb_tex3,	3);

#endif
