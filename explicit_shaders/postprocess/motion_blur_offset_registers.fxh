#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, ps_distortion_depth_buffer, s0);

DECLARE_PARAMETER(float4x4, ps_combined3[4], c188);

// .xy == misc.w
// .zw == (-center_pixel) * misc.w
DECLARE_PARAMETER(float4, ps_crosshair_constants, c209);


#elif DX_VERSION == 11

CBUFFER_BEGIN(MotionBlurOffsetPS)
	CBUFFER_CONST_ARRAY(MotionBlurOffsetPS,		float4x4,	ps_combined3, [4],			k_ps_motion_blur_offset_combined3)
	CBUFFER_CONST(MotionBlurOffsetPS,				float4,		ps_crosshair_constants,		k_ps_motion_blur_offset_crosshair_constants)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_distortion_depth_buffer, 	k_ps_motion_blur_offset_distortion_depth_buffer,		0)

#endif
