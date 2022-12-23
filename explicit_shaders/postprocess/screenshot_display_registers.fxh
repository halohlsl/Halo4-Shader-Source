#if DX_VERSION == 9

DECLARE_PARAMETER(sampler2D, ps_screenshot_source_sampler,		s0);

DECLARE_PARAMETER(float4, ps_swap_color_channels,	c5);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenshotDisplayPS)
	CBUFFER_CONST(ScreenshotDisplayPS,	float4,		ps_swap_color_channels,		k_ps_screenshot_display_swap_color_channels)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_screenshot_source_sampler,		k_ps_screenshot_display_source_sampler,			0)

#endif
