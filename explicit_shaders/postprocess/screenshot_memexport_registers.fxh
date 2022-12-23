#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, ps_source_sampler, s0);
DECLARE_PARAMETER(sampler2D, ps_background_sampler, s1);

DECLARE_PARAMETER(float4, vpos_to_pixel_xform,		c2);
DECLARE_PARAMETER(float4, pixel_to_source_xform,	c3);
DECLARE_PARAMETER(float4, export_info,				c4);		// row stride in pixels, maximum pixel index, screenshot gamma
DECLARE_PARAMETER(float4, export_stream_constant,	c5);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenshotMemexportPS)
	CBUFFER_CONST(ScreenshotMemexportPS,		float4,		vpos_to_pixel_xform,	k_ps_screenshot_memexport_vpos_to_pixel_xform)
	CBUFFER_CONST(ScreenshotMemexportPS,		float4, 	pixel_to_source_xform,	k_ps_screenshot_memexport_pixel_to_source_xform)
	CBUFFER_CONST(ScreenshotMemexportPS,		float4, 	export_info,			k_ps_screenshot_memexport_export_info)
	CBUFFER_CONST(ScreenshotMemexportPS,		float4, 	export_stream_constant,	k_ps_screenshot_memexport_export_stream_constant)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_source_sampler, 			k_ps_screenshot_memexport_source_sampler,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_background_sampler, 		k_ps_screenshot_memexport_background_sampler,		1)

#endif
