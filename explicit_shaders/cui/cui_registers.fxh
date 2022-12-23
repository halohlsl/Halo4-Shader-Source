#if !defined(__CUI_REGISTERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __CUI_REGISTERS_FXH


#include "core/core.fxh"
#endif

#if DX_VERSION == 9

//NOTE: if you modify any of this, than you need to modify cui_hlsl_registers.h

DECLARE_PARAMETER(float4x4, k_cui_vertex_shader_constant_projection_matrix, c30);
DECLARE_PARAMETER(float4x4, k_cui_vertex_shader_constant_absolute_projection_matrix, c34);
DECLARE_PARAMETER(float4x3, k_cui_vertex_shader_constant_model_view_matrix, c38);
DECLARE_PARAMETER(float4x3, k_cui_vertex_shader_constant_absolute_model_view_matrix, c41);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant0, c44);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant1, c45);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant2, c46);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant3, c47);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant4, c48);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant5, c49);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant6, c50);
DECLARE_PARAMETER(float4, k_cui_vertex_shader_constant7, c51);

DECLARE_PARAMETER(float4, k_cui_pixel_shader_color0, c30);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_color1, c31);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_color2, c32);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_color3, c33);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_color4, c34);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_color5, c35);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar0, c36);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar1, c37);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar2, c38);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar3, c39);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar4, c40);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar5, c41);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar6, c42);
DECLARE_PARAMETER(float, k_cui_pixel_shader_scalar7, c43);

DECLARE_PARAMETER(float4, k_cui_pixel_shader_bounds, c44);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_authored_bounds, c45);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_pixel_size, c46);
DECLARE_PARAMETER(float4, k_cui_pixel_shader_tint, c47);

// <scale, offset, bool need_to_premultiply>
// premultiplied (render target): <1, 0, 1>
// non-premultiplied (source bitmap): <-1, 1, 0>
DECLARE_PARAMETER(float4, k_cui_sampler0_transform, c48);
DECLARE_PARAMETER(float4, k_cui_sampler1_transform, c49);
DECLARE_PARAMETER(float4, k_cui_sampler2_transform, c50);

// DECLARE_PARAMETER() is incompatible with integer and boolean constants, so specify these manually
int k_cui_pixel_shader_int0 : register(i0);
int k_cui_pixel_shader_int1 : register(i1);
int k_cui_pixel_shader_int2 : register(i2);
int k_cui_pixel_shader_int3 : register(i3);

bool k_cui_pixel_shader_bool0 : register(b0);
bool k_cui_pixel_shader_bool1 : register(b1);
bool k_cui_pixel_shader_bool2 : register(b2);
bool k_cui_pixel_shader_bool3 : register(b3);

DECLARE_PARAMETER(sampler2D, source_sampler0, s0);
DECLARE_PARAMETER(sampler2D, source_sampler1, s1);
DECLARE_PARAMETER(sampler2D, source_sampler2, s2);

// cui_high_contrast_additive
DECLARE_PARAMETER(float4, psBloomTransform, c11);

#elif DX_VERSION == 11

CBUFFER_BEGIN(CUIVS)
	CBUFFER_CONST(CUIVS,		float4x4,		k_cui_vertex_shader_constant_projection_matrix,				k_cui_vertex_shader_constant_projection_matrix)
	CBUFFER_CONST(CUIVS,		float4x4,		k_cui_vertex_shader_constant_absolute_projection_matrix,	k_cui_vertex_shader_constant_absolute_projection_matrix)	
	CBUFFER_CONST(CUIVS,		float4x3,		k_cui_vertex_shader_constant_model_view_matrix,				k_cui_vertex_shader_constant_model_view_matrix)
	CBUFFER_CONST(CUIVS,		float4x3,		k_cui_vertex_shader_constant_absolute_model_view_matrix,	k_cui_vertex_shader_constant_absolute_model_view_matrix)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant0,								k_cui_vertex_shader_constant0)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant1,                              k_cui_vertex_shader_constant1)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant2,                              k_cui_vertex_shader_constant2)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant3,                              k_cui_vertex_shader_constant3)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant4,                              k_cui_vertex_shader_constant4)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant5,                              k_cui_vertex_shader_constant5)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant6,                              k_cui_vertex_shader_constant6)
	CBUFFER_CONST(CUIVS,		float4, 		k_cui_vertex_shader_constant7,                              k_cui_vertex_shader_constant7)	
CBUFFER_END

CBUFFER_BEGIN(CUIPS)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_color0,									k_cui_pixel_shader_color0)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_color1,                                  k_cui_pixel_shader_color1)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_color2,                                  k_cui_pixel_shader_color2)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_color3,                                  k_cui_pixel_shader_color3)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_color4,                                  k_cui_pixel_shader_color4)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_color5,                                  k_cui_pixel_shader_color5)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar0,									k_cui_pixel_shader_scalar0)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar0_pad,								k_cui_pixel_shader_scalar0_pad)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar1,                                 k_cui_pixel_shader_scalar1)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar1_pad,								k_cui_pixel_shader_scalar1_pad)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar2,                                 k_cui_pixel_shader_scalar2)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar2_pad,								k_cui_pixel_shader_scalar2_pad)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar3,                                 k_cui_pixel_shader_scalar3)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar3_pad,								k_cui_pixel_shader_scalar3_pad)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar4,                                 k_cui_pixel_shader_scalar4)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar4_pad,								k_cui_pixel_shader_scalar4_pad)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar5,                                 k_cui_pixel_shader_scalar5)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar5_pad,								k_cui_pixel_shader_scalar5_pad)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar6,                                 k_cui_pixel_shader_scalar6)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar6_pad,								k_cui_pixel_shader_scalar6_pad)
	CBUFFER_CONST(CUIPS,		float, 			k_cui_pixel_shader_scalar7,                                 k_cui_pixel_shader_scalar7)
	CBUFFER_CONST(CUIPS,		float3,			k_cui_pixel_shader_scalar7_pad,								k_cui_pixel_shader_scalar7_pad)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_bounds,									k_cui_pixel_shader_texture_bounds)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_authored_bounds,                         k_cui_pixel_shader_authored_bounds)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_pixel_size,                              k_cui_pixel_shader_pixel_size)
	CBUFFER_CONST(CUIPS,		float4, 		k_cui_pixel_shader_tint,                                    k_cui_pixel_shader_tint)
	CBUFFER_CONST(CUIPS,		float4,			k_cui_sampler0_transform,									k_cui_pixel_shader_sampler0_transform)
	CBUFFER_CONST(CUIPS,		float4,			k_cui_sampler1_transform,                                   k_cui_pixel_shader_sampler1_transform)
	CBUFFER_CONST(CUIPS,		float4,			k_cui_sampler2_transform,	                                k_cui_pixel_shader_sampler2_transform)
	CBUFFER_CONST(CUIPS,		float4,			psBloomTransform,											k_cui_pixel_shader_bloom_transform)
	CBUFFER_CONST(CUIPS,		int,			k_cui_pixel_shader_int0,									k_cui_pixel_shader_int0)
	CBUFFER_CONST(CUIPS,		int3,			k_cui_pixel_shader_int0_pad,								k_cui_pixel_shader_int0_pad)
	CBUFFER_CONST(CUIPS,		int,			k_cui_pixel_shader_int1,									k_cui_pixel_shader_int1)
	CBUFFER_CONST(CUIPS,		int3,			k_cui_pixel_shader_int1_pad,								k_cui_pixel_shader_int1_pad)
	CBUFFER_CONST(CUIPS,		int,			k_cui_pixel_shader_int2,									k_cui_pixel_shader_int2)
	CBUFFER_CONST(CUIPS,		int3,			k_cui_pixel_shader_int2_pad,								k_cui_pixel_shader_int2_pad)
	CBUFFER_CONST(CUIPS,		int,			k_cui_pixel_shader_int3,									k_cui_pixel_shader_int3)
	CBUFFER_CONST(CUIPS,		int3,			k_cui_pixel_shader_int3_pad,								k_cui_pixel_shader_int3_pad)
	CBUFFER_CONST(CUIPS,		bool,			k_cui_pixel_shader_bool0,									k_cui_pixel_shader_bool0)
	CBUFFER_CONST(CUIPS,		bool,			k_cui_pixel_shader_bool1,									k_cui_pixel_shader_bool1)
	CBUFFER_CONST(CUIPS,		bool,			k_cui_pixel_shader_bool2,									k_cui_pixel_shader_bool2)
	CBUFFER_CONST(CUIPS,		bool,			k_cui_pixel_shader_bool3,									k_cui_pixel_shader_bool3)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	source_sampler0, 	k_cui_source_sampler0,	0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	source_sampler1, 	k_cui_source_sampler1,	1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	source_sampler2, 	k_cui_source_sampler2,	2)

#endif

#endif // __CUI_REGISTERS_FXH
