#if DX_VERSION == 9

#if MAX_COLOR_GRADING_TEXTURES > 0
DECLARE_PARAMETER(			float4,		ps_color_grading_scale_offset[MAX_COLOR_GRADING_TEXTURES],				c11);
#endif

DECLARE_PARAMETER(			float4,		ps_filmic_tone_curve_params[5],											c13);

DECLARE_PARAMETER(			bool,		ps_apply_color_matrix,													b8) = false;
DECLARE_PARAMETER(			bool,		ps_apply_contrast,														b9) = false;

#elif DX_VERSION == 11

CBUFFER_BEGIN(FinalCompositeFunctionsPS)
	CBUFFER_CONST_ARRAY(FinalCompositeFunctionsPS,	float4,		ps_color_grading_scale_offset, [2],			k_ps_final_composite_functions_color_grading_scale_offset)
	CBUFFER_CONST_ARRAY(FinalCompositeFunctionsPS,	float4,		ps_color_grading_half_texel_offset, [2],	k_ps_final_composite_functions_color_grading_half_texel_offset)
	CBUFFER_CONST_ARRAY(FinalCompositeFunctionsPS,	float4,		ps_filmic_tone_curve_params, [5],			k_ps_final_composite_functions_filmic_tone_curve_params)
	CBUFFER_CONST(FinalCompositeFunctionsPS,			bool,		ps_apply_color_matrix,					k_ps_final_composite_functions_bool_apply_color_matrix)
	CBUFFER_CONST(FinalCompositeFunctionsPS,			bool,		ps_apply_contrast,						k_ps_final_composite_functions_bool_apply_contrast)
CBUFFER_END

#endif