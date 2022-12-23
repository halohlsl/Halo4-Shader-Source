#if DX_VERSION == 9

DECLARE_PARAMETER(float3, psFalloffMax_FalloffStart_Alpha, c5); // hack arbitrary number wooo!
DECLARE_PARAMETER(float, psBipedThreat, c6); // hack arbitrary number wooo!
sampler2D stencilSampler : register(s9);
sampler2D objectDepthSampler : register(s8);

#elif DX_VERSION == 11

CBUFFER_BEGIN(VisionObjPS)
	CBUFFER_CONST(VisionObjPS,	float3,		psFalloffMax_FalloffStart_Alpha,		k_ps_vision_obj_falloffmax_falloffstart_alpha)
	CBUFFER_CONST(VisionObjPS,	float,		psFalloffMax_FalloffStart_Alpha_pad,	k_ps_vision_obj_falloffmax_falloffstart_alpha_pad)
	CBUFFER_CONST(VisionObjPS,	float,		psBipedThreat,							k_ps_vision_obj_biped_threat)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	objectDepthSampler,		k_ps_vision_obj_depth_sampler,		8)

#define k_ps_vision_obj_stencil_sampler 9
#ifndef DEFINE_CPP_CONSTANTS
texture2D<uint2> stencilTexture : register(t9);
#endif

#endif
