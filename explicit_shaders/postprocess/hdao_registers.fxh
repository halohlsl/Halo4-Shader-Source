#if DX_VERSION == 9

DECLARE_PARAMETER( float4,	corner_params,		c116 );			// corner_scale, corner_scale*2, corner_offset
DECLARE_PARAMETER( float4,	bounds_params,		c117 );			// bounds_scale, bounds_offset
DECLARE_PARAMETER( float4,	curve_params,		c118 );			// curve_scale, curve_offset, curve_sigma
DECLARE_PARAMETER( float4,	fade_params,		c119 );			//
DECLARE_PARAMETER( float4, channel_scale,		c120 );			// channel transform CONTAINS curve_scale/curve_offset already
DECLARE_PARAMETER( float4, channel_offset,		c121 );

sampler2D depth_sampler		: register(s0);
sampler2D depth_low_sampler : register(s1);
sampler2D mask_sampler		: register(s2);

#elif DX_VERSION == 11

CBUFFER_BEGIN(HDAOPS)
	CBUFFER_CONST(HDAOPS,		float4,		corner_params,				k_ps_hdao_corner_params)
	CBUFFER_CONST(HDAOPS,		float4,		bounds_params,				k_ps_hdao_bounds_params)
	CBUFFER_CONST(HDAOPS,		float4,		curve_params,				k_ps_hdao_curve_params)
	CBUFFER_CONST(HDAOPS,		float4,		fade_params,				k_ps_hdao_fade_params)
	CBUFFER_CONST(HDAOPS,		float4, 	channel_scale,				k_ps_hdao_channel_scale)
	CBUFFER_CONST(HDAOPS,		float4, 	channel_offset,				k_ps_hdao_channel_offset)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_sampler,			k_ps_hdao_depth_sampler,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_low_sampler,		k_ps_hdao_depth_low_sampler,	1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	mask_sampler,			k_ps_hdao_mask_sampler,			2)

#endif
