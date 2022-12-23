#if !defined(__FX_PARAMETERS_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __FX_PARAMETERS_FXH

#include "core/core_parameters.fxh"

#define HAS_ALPHA_BLEND_MODE
#endif


#if DX_VERSION == 9

///////////////////////////////////////////
// vertex shader engine-supplied parameters

// this is in a float register because int registers don't work with ==
DECLARE_PARAMETER(			int,		vs_alpha_blend_mode,													c16);

DECLARE_PARAMETER(float4, vs_hiddenFromCompilerNaN, c32); // 1 variable

// not sure when it changes
DECLARE_PARAMETER(			float4,		vs_bungie_exposure,														c230);
DECLARE_PARAMETER(			float2,		vs_bungie_additive_scale_and_exposure,									c231);



//////////////////////////////////////////
// pixel shader engine-supplied parameters

// see vs_alpha_blend_mode
DECLARE_PARAMETER(			int,		ps_alpha_blend_mode,													c3);

#if defined(RENDER_DISTORTION)
// engine supplied
DECLARE_PARAMETER(float3, psDistortionScreenConstants, c196);
#endif // defined(RENDER_DISTORTION)

#elif DX_VERSION == 11

CBUFFER_BEGIN(FXParametersVS)
	CBUFFER_CONST(FXParametersVS,		float,		vs_alpha_blend_mode,						k_vs_fx_parameters_alpha_blend_mode)
	CBUFFER_CONST(FXParametersVS,		float3,		vs_alpha_blend_mode_pad,					k_vs_fx_parameters_alpha_blend_mode_pad)
	CBUFFER_CONST(FXParametersVS,		float4, 	vs_hiddenFromCompilerNaN,					k_vs_fx_parameters_hidden_from_compiler_nan)
	CBUFFER_CONST(FXParametersVS,		float4,		vs_bungie_exposure,							k_vs_fx_parameters_bungie_exposure)
	CBUFFER_CONST(FXParametersVS,		float2,		vs_bungie_additive_scale_and_exposure,		k_vs_fx_parameters_bungie_additive_scale_and_exposure)
CBUFFER_END

CBUFFER_BEGIN(FXParametersPS)
	CBUFFER_CONST(FXParametersPS,		float,		ps_alpha_blend_mode,						k_ps_fx_parameters_alpha_blend_mode)
	CBUFFER_CONST(FXParametersPS,		float3,		ps_alpha_blend_mode_pad,					k_ps_fx_parameters_alpha_blend_mode_pad)
	CBUFFER_CONST(FXParametersPS,		float3, 	psDistortionScreenConstants, 				k_ps_fx_parameters_distortion_screen_constants)
CBUFFER_END

#endif

#if defined(RENDER_DISTORTION) && (! defined(DEFINE_CPP_CONSTANTS))
// user-supplied
DECLARE_FLOAT_WITH_DEFAULT(DistortionStrength, "Distortion Strength", "", 0, 5, float(1));
#include "used_float.fxh"
DECLARE_BOOL_WITH_DEFAULT(DistortionExpensiveDepthTest, "Distortion Expensive Depth Test", "", false);
#include "next_bool_parameter.fxh"
#endif // defined(RENDER_DISTORTION)

#endif 	// !defined(__FX_PARAMETERS_FXH)