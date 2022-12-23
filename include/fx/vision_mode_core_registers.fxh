#if DX_VERSION == 9

DECLARE_PARAMETER(float4, psDepthConstants, c65);

sampler2D framebufferSampler : register(s10);
sampler2D depthSampler : register(s11);

#elif DX_VERSION == 11

CBUFFER_BEGIN(VisionModeCorePS)
	CBUFFER_CONST(VisionModeCorePS,		float4,		psDepthConstants,		k_ps_vision_mode_core_depth_constants)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	framebufferSampler,		k_ps_vision_mode_core_framebuffer_sampler,		10)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	depthSampler,			k_ps_vision_mode_core_depth_sampler,			11)

#endif
