/*
PATCHY_FOG_REGISTERS.FX
Copyright (c) Microsoft Corporation, 2007. all rights reserved.
4/05/2007 9:15:00 AM (kuttas)
	
*/

#if DX_VERSION == 9

// Noise texture sampled for fog density
DECLARE_PARAMETER(sampler,		k_ps_sampler_tex_noise,			s0);

// Scene depth texture sampled to fade fog near scene intersections
DECLARE_PARAMETER(sampler,		k_ps_sampler_tex_scene_depth,	s1);

// Scene depth texture sampled to fade fog near scene intersections
DECLARE_PARAMETER(sampler,		k_ps_sampler_patchy_buffer0,	s2);
DECLARE_PARAMETER(sampler,		k_ps_sampler_patchy_buffer1,	s3);


DECLARE_PARAMETER(float4,		k_ps_inverse_z_transform,		c32);
DECLARE_PARAMETER(float4,		k_ps_texcoord_basis,			c33);
DECLARE_PARAMETER(float4,		k_ps_attenuation_data,			c34);
DECLARE_PARAMETER(float4,		k_ps_eye_position,				c35);
DECLARE_PARAMETER(float4,		k_ps_window_pixel_bounds,		c36);
DECLARE_PARAMETER(float4,		k_ps_tint_color,				c37);
DECLARE_PARAMETER(float4,		k_ps_tint_color2,				c38);
DECLARE_PARAMETER(float4,		k_ps_optical_depth_scale,		c39);

DECLARE_PARAMETER(float4,		k_ps_sheet_fade_factors[2],		c40);
DECLARE_PARAMETER(float4,		k_ps_sheet_depths[2],			c42);

DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform0,		c44);
DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform1,		c45);
DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform2,		c46);
DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform3,		c47);
DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform4,		c48);
DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform5,		c49);
DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform6,		c50);
DECLARE_PARAMETER(float4,		k_ps_tex_coord_transform7,		c51);

DECLARE_PARAMETER(float4,		k_ps_texcoord_offsets[4],		c80);
DECLARE_PARAMETER(float4,		k_ps_texcoord_x_scale[4],		c84);
DECLARE_PARAMETER(float4,		k_ps_texcoord_y_scale[4],		c88);

DECLARE_PARAMETER(float4,		k_ps_height_fade_scales[2],		c92);
DECLARE_PARAMETER(float4,		k_ps_height_fade_offset[2],		c94);
DECLARE_PARAMETER(float4,		k_ps_depth_fade_scales[2],		c96);
DECLARE_PARAMETER(float4,		k_ps_depth_fade_offset[2],		c98);
DECLARE_PARAMETER(float4,		k_ps_sheet_fade[2],				c100);

DECLARE_PARAMETER(float4,		k_vs_z_epsilon,					c239);
DECLARE_PARAMETER(float4x4,		k_vs_proj_to_world_relative,	c240);

#elif DX_VERSION == 11

CBUFFER_BEGIN(PatchyFogPS)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_inverse_z_transform,		k_ps_patchy_fog_inverse_z_transform)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_texcoord_basis,			k_ps_patchy_fog_texcoord_basis)	
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_attenuation_data,			k_ps_patchy_fog_attenuation_data)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_eye_position,				k_ps_patchy_fog_eye_position)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_window_pixel_bounds,		k_ps_patchy_fog_window_pixel_bounds)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tint_color,				k_ps_patchy_fog_tint_color)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tint_color2,				k_ps_patchy_fog_tint_color2)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_optical_depth_scale,		k_ps_patchy_fog_optical_depth_scale)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_sheet_fade_factors, [2],	k_ps_patchy_fog_sheet_fade_factors)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_sheet_depths, [2],			k_ps_patchy_fog_sheet_depths)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform0,		k_ps_patchy_fog_tex_coord_transform0)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform1,		k_ps_patchy_fog_tex_coord_transform1)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform2,		k_ps_patchy_fog_tex_coord_transform2)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform3,		k_ps_patchy_fog_tex_coord_transform3)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform4,		k_ps_patchy_fog_tex_coord_transform4)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform5,		k_ps_patchy_fog_tex_coord_transform5)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform6,		k_ps_patchy_fog_tex_coord_transform6)
	CBUFFER_CONST(PatchyFogPS,		float4,			k_ps_tex_coord_transform7,		k_ps_patchy_fog_tex_coord_transform7)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_texcoord_offsets, [4],		k_ps_patchy_fog_texcoord_offsets)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_texcoord_x_scale, [4],		k_ps_patchy_fog_texcoord_x_scale)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_texcoord_y_scale, [4],		k_ps_patchy_fog_texcoord_y_scale)	
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_height_fade_scales, [2],	k_ps_patchy_fog_height_fade_scales)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_height_fade_offset, [2],	k_ps_patchy_fog_height_fade_offset)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_depth_fade_scales, [2],	k_ps_patchy_fog_depth_fade_scales)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_depth_fade_offset, [2],	k_ps_patchy_fog_depth_fade_offset)
	CBUFFER_CONST_ARRAY(PatchyFogPS,	float4,			k_ps_sheet_fade, [2],			k_ps_patchy_fog_sheet_fade)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_sampler_tex_noise,				k_ps_patchy_fog_sampler_tex_noise,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_sampler_tex_scene_depth,		k_ps_patchy_fog_sampler_tex_scene_depth,	1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_sampler_patchy_buffer0,		k_ps_patchy_fog_sampler_patchy_buffer0,		2)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	k_ps_sampler_patchy_buffer1,		k_ps_patchy_fog_sampler_patchy_buffer1,		3)

CBUFFER_BEGIN(PatchyFogVS)
	CBUFFER_CONST(PatchyFogVS,		float4,			k_vs_z_epsilon,					k_vs_patchy_fog_z_epsilon)
	CBUFFER_CONST(PatchyFogVS,		float4x4,		k_vs_proj_to_world_relative,	k_vs_patchy_fog_proj_to_world_relative)
CBUFFER_END

#endif

#define k_ps_sphere_warp_scale (k_ps_optical_depth_scale.y)
#define k_ps_projective_to_tangent_space	(k_ps_optical_depth_scale.zw)

