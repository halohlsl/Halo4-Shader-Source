#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, ps_displacement_sampler, s0);
DECLARE_PARAMETER(sampler, ps_ldr_buffer, s1);

// screen_constants.xy == 1/pixel resolution
// screen_constants.zw == screenshot_scale
DECLARE_PARAMETER(float4, ps_screen_constants, c203);

// resolution_constants.xy == pixel resolution (width, height)
// resolution_constants.zw == 1.0 / pixel resolution
DECLARE_PARAMETER(float4, vs_resolution_constants, c250);

// distort_constants.xy == (screenshot scale) * 2 * max_displacement * (0.5f if multisampled) * resolution.xy		<----------------- convert to pixels
// distort_constants.zw == -distortion_offset * distort_constants.xy
DECLARE_PARAMETER(float4, ps_distort_constants, c205);

// The safe area to fetch within
DECLARE_PARAMETER(float4, ps_window_bounds, c204);

// motion blur

DECLARE_PARAMETER(float4x4, ps_reprojectionMatrix, c188);

// resolution_constants.xy == pixel resolution (width, height)
// resolution_constants.zw == 1.0 / pixel resolution
DECLARE_PARAMETER(float4, ps_resolution_constants, c207);

DECLARE_PARAMETER(float4, ps_motionSuckVectorAndLength, c206);
DECLARE_PARAMETER(bool, ps_motionSuckEnabled, b3) = false;

// .x = total scale
// .y = max blur / total scale
// .z = inverse_num_taps * total scale
// .w = inverse_num_taps * 2 * total scale
DECLARE_PARAMETER(float4, ps_pixel_blur_constants, c158);

// Enable/disable distortion
DECLARE_PARAMETER(bool, do_distortion, b2) = false;


#elif DX_VERSION == 11

CBUFFER_BEGIN(DisplacementVS)
	CBUFFER_CONST(DisplacementVS,				float4,		vs_resolution_constants,		k_vs_displacement_resolution_constants)
CBUFFER_END					
					
CBUFFER_BEGIN(DisplacementPS)					
	CBUFFER_CONST(DisplacementPS,				float4,		ps_screen_constants,			k_ps_displacement_screen_constants)
	CBUFFER_CONST(DisplacementPS,				float4,		ps_distort_constants,			k_ps_displacement_distort_constants)
	CBUFFER_CONST(DisplacementPS,				float4,		ps_window_bounds,				k_ps_displacement_window_bounds)
CBUFFER_END

CBUFFER_BEGIN(DisplacementMotionBlurPS)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4x4,	ps_reprojectionMatrix,			k_ps_displacement_motion_blur_reprojection_matrix)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4,		ps_resolution_constants,		k_ps_displacement_motion_blur_resolution_constants)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4,		ps_motionSuckVectorAndLength,	k_ps_displacement_motion_blur_motion_suck_vector_and_length)
	CBUFFER_CONST(DisplacementMotionBlurPS,	float4,		ps_pixel_blur_constants,		k_ps_displacement_motion_blur_pixel_blur_constants)
	CBUFFER_CONST(DisplacementMotionBlurPS,	bool,		ps_motionSuckEnabled,			k_ps_displacement_motion_blur_bool_motion_suck_enabled)
	CBUFFER_CONST(DisplacementMotionBlurPS,	bool,		do_distortion,					k_ps_displacement_motion_blur_bool_do_distortion)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_displacement_sampler, 	k_ps_displacement_displacement_sampler,	 0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_ldr_buffer, 				k_ps_displacement_ldr_buffer,			 1)

#endif
