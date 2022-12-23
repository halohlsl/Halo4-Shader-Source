#if DX_VERSION == 9

DECLARE_PARAMETER(float3, forward, c1);
DECLARE_PARAMETER(float3, up, c2);
DECLARE_PARAMETER(float3, left, c3);
DECLARE_PARAMETER(float4, scale, c4);

DECLARE_PARAMETER(float4, scale_a, c4);
DECLARE_PARAMETER(float4, scale_b, c5);

DECLARE_PARAMETER(float, delta, c4);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CubemapPS)
	CBUFFER_CONST(CubemapPS,		float3,		forward,		k_ps_cubemap_forward)
	CBUFFER_CONST(CubemapPS,		float,		forward_pad,	k_ps_cubemap_forward_pad)
	CBUFFER_CONST(CubemapPS,		float3,		up,				k_ps_cubemap_up)
	CBUFFER_CONST(CubemapPS,		float,		up_pad,			k_ps_cubemap_up_pad)
	CBUFFER_CONST(CubemapPS,		float3,		left,			k_ps_cubemap_left)
	CBUFFER_CONST(CubemapPS,		float,		left_pad,		k_ps_cubemap_left_pad)
	CBUFFER_CONST(CubemapPS,		float4,		scale,			k_ps_cubemap_scale)
	CBUFFER_CONST(CubemapPS,		float4,		scale_b,		k_ps_cubemap_scale_b)	
CBUFFER_END

#ifndef DEFINE_CPP_CONSTANTS
#define scale_a scale
#define delta scale
#else
#define k_ps_cubemap_scale_a k_ps_cubemap_scale
#define k_ps_cubemap_delta k_ps_cubemap_scale
#endif

#endif