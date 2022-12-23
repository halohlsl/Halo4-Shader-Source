#if DX_VERSION == 9

DECLARE_PARAMETER(float4, pixelOffsetX, c4);		// 0.5 pixels, 1.5 pixels, 2.0 pixels, 0
DECLARE_PARAMETER(float4, pixelOffsetY, c5);		// 0.5 pixels, 1.5 pixels, 2.0 pixels, 0

/**
 * DX9 samplers hell following this.
 */

sampler2D source_sampler : register(s0);
sampler2D depth_sampler : register(s0);
sampler2D depth_sampler_2 : register(s1);
sampler2D edge_sampler : register(s0);
sampler2D area_sampler : register(s1);
sampler2D blend_sampler : register(s1);

#elif DX_VERSION == 11

CBUFFER_BEGIN(MLAAPS)
	CBUFFER_CONST(MLAAPS,		float4,		pixelOffsetX,		k_ps_mlaa_pixel_offset_x)
	CBUFFER_CONST(MLAAPS,		float4,		pixelOffsetY,		k_ps_mlaa_pixel_offset_y)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	source_sampler,		k_ps_mlaa_source_sampler,	0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_sampler,		k_ps_mlaa_depth_sampler,	0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_sampler_2,	k_ps_mlaa_depth_sampler_2,	1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	edge_sampler,		k_ps_mlaa_edge_sampler,		0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	area_sampler,		k_ps_mlaa_area_sampler,		1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	blend_sampler,		k_ps_mlaa_blend_sampler,	1)

#endif
