#if DX_VERSION == 9

DECLARE_PARAMETER(float4,		vs_screenspace_to_pixelspace_xform,	c250);
DECLARE_PARAMETER(float4,		vs_screenspace_xform,				c251);

DECLARE_PARAMETER(float4,		ps_screenspace_xform,				c200);
DECLARE_PARAMETER(float4,		ps_inv_screenspace_xform,			c201);
DECLARE_PARAMETER(float4,		ps_screenspace_to_pixelspace_xform,	c202);
DECLARE_PARAMETER(float4x4,		ps_pixel_to_world_relative,			c204);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ScreenBaseVS)
	CBUFFER_CONST(ScreenBaseVS,	float4,			vs_screenspace_to_pixelspace_xform,			k_vs_screen_base_screenspace_to_pixelspace_xform)
	CBUFFER_CONST(ScreenBaseVS,	float4,			vs_screenspace_xform,						k_vs_screen_base_screenspace_xform)
CBUFFER_END	
	
CBUFFER_BEGIN(ScreenBasePS)	
	CBUFFER_CONST(ScreenBasePS,		float4,			ps_screenspace_xform,					k_ps_screen_base_screenspace_xform)
	CBUFFER_CONST(ScreenBasePS,		float4,			ps_inv_screenspace_xform,				k_ps_screen_base_inv_screenspace_xform)
	CBUFFER_CONST(ScreenBasePS,		float4,			ps_screenspace_to_pixelspace_xform,		k_ps_screen_base_screenspace_to_pixelspace_xform)
	CBUFFER_CONST(ScreenBasePS,		float4x4,		ps_pixel_to_world_relative,				k_ps_screen_base_pixel_to_world_relative)
CBUFFER_END

#endif
