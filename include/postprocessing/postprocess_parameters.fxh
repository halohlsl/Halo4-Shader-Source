#if !defined(__POSTPROCESS_PARAMETERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __POSTPROCESS_PARAMETERS_FXH

#include "core/core_parameters.fxh"
#endif

#if DX_VERSION == 9

///////////////////////////////////////////
// vertex shader engine-supplied parameters
DECLARE_PARAMETER(	float4,		vs_texture_size,						c16);
DECLARE_PARAMETER(	float4,		vs_window_size,							c17);
DECLARE_PARAMETER(	float4,		vs_pointsize_time_radius,				c18);
DECLARE_PARAMETER(	float4,		vs_forward,								c19);
DECLARE_PARAMETER(	float4,		vs_right,								c20);
DECLARE_PARAMETER(	float4,		vs_up,									c21);


//////////////////////////////////////////
// pixel shader engine-supplied parameters

DECLARE_PARAMETER(			float4,		ps_exposure,															c0);
DECLARE_PARAMETER(			float4,		ps_pixel_size,															c1);
DECLARE_PARAMETER(			float4,		ps_scale,																c2);
DECLARE_PARAMETER(			float4, 	ps_intensity,															c3);

DECLARE_PARAMETER(			float4,		ps_alt_exposure,														c12);		// self-illum exposure, unused, unused, unused

DECLARE_PARAMETER(			float4x3,	ps_hue_saturation_matrix,												c129);
DECLARE_PARAMETER(			float4,		ps_contrast,															c132);

#elif DX_VERSION == 11

CBUFFER_BEGIN(PostProcessVS)
	CBUFFER_CONST(PostProcessVS,		float4,		vs_texture_size,			k_vs_postprocess_texture_size)
	CBUFFER_CONST(PostProcessVS,		float4,		vs_window_size,				k_vs_postprocess_window_size)
	CBUFFER_CONST(PostProcessVS,		float4,		vs_pointsize_time_radius,	k_vs_postprocess_pointsize_time_radius)
	CBUFFER_CONST(PostProcessVS,		float4,		vs_forward,					k_vs_postprocess_forward)
	CBUFFER_CONST(PostProcessVS,		float4,		vs_right,					k_vs_postprocess_right)
	CBUFFER_CONST(PostProcessVS,		float4,		vs_up,						k_vs_postprocess_up)
CBUFFER_END

CBUFFER_BEGIN(PostProcessPS)
	CBUFFER_CONST(PostProcessPS,		float4,		ps_pixel_size,				k_ps_postprocess_pixel_size)
	CBUFFER_CONST(PostProcessPS,		float4,		ps_scale,					k_ps_postprocess_scale)
	CBUFFER_CONST(PostProcessPS,		float4,		ps_intensity,				k_ps_postprocess_intensity)
	CBUFFER_CONST(PostProcessPS,		float4x3,	ps_hue_saturation_matrix,	k_ps_postprocess_hue_saturation_matrix)
	CBUFFER_CONST(PostProcessPS,		float4,		ps_contrast,				k_ps_postprocess_contrast)
CBUFFER_END

#define ps_exposure ps_view_exposure

#endif

#define DARK_COLOR_MULTIPLIER ps_exposure.g



#endif 	// !defined(__ENGINE_POSTPROCESS_PARAMETERS_FXH)