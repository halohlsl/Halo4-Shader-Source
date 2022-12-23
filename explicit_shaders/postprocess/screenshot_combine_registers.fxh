#if DX_VERSION == 9

DECLARE_PARAMETER(float4, ps_bloom_sampler_xform, c5);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenshotCombinePS)
	CBUFFER_CONST(ScreenshotCombinePS,		float4,		ps_bloom_sampler_xform,			k_ps_screenshot_combine_bloom_sampler_xform)
CBUFFER_END

#endif
