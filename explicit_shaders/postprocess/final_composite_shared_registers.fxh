#if DX_VERSION == 9

DECLARE_PARAMETER(			sampler2D, 	ps_surface_sampler,														s0);
DECLARE_PARAMETER(			sampler2D, 	ps_dark_surface_sampler,												s1);
DECLARE_PARAMETER(			sampler2D, 	ps_bloom_sampler,														s2);
DECLARE_PARAMETER(			sampler2D, 	ps_depth_sampler,														s3);
DECLARE_PARAMETER(			sampler2D, 	ps_blur_sampler,														s4);
DECLARE_PARAMETER(			sampler2D, 	ps_blur_grade_sampler,													s5);
DECLARE_PARAMETER(			sampler2D, 	ps_prev_sampler,														s6);

DECLARE_PARAMETER(			float4,		ps_player_window_constants, 											c4);	// weapon zoom:		x, y, (left top corner), z,w (width, height);
DECLARE_PARAMETER(			float4,		ps_depth_constants[2],													c6);	// depth of field:	1/near,  -(far-near)/(far*near), focus distance, aperture

#elif DX_VERSION == 11

CBUFFER_BEGIN(FinalCompositeSharedPS)
	CBUFFER_CONST(FinalCompositeSharedPS,			float4,		ps_player_window_constants,		k_final_composite_shared_player_window_constants)
	CBUFFER_CONST_ARRAY(FinalCompositeSharedPS,	float4,		ps_depth_constants, [2],		k_final_composite_shared_depth_constants)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_surface_sampler,				k_final_composite_shared_surface_sampler,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_dark_surface_sampler,		k_final_composite_shared_dark_surface_sampler,		1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_bloom_sampler,				k_final_composite_shared_bloom_sampler,				2)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_depth_sampler,				k_final_composite_shared_depth_sampler,				3)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_blur_sampler,				k_final_composite_shared_blur_sampler,				4)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_blur_grade_sampler,			k_final_composite_shared_blur_grade_sampler,		5)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ps_prev_sampler,				k_final_composite_shared_prev_sampler,				6)

#endif
