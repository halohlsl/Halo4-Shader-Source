#if DX_VERSION == 9

// A few parameters that enable various shader math tricks
DECLARE_PARAMETER(float4, g_externMathValues,	c4);			// = float4(1.0, -1.0, 0.25, -0.25);
DECLARE_PARAMETER(float4, g_innerTapOffsets,	c5);			// = float4(0.5/1280.0, 0.5/720.0, -0.5/1280.0, -0.5/720.0);
DECLARE_PARAMETER(float4, g_outerTapOffsetsOpt, c6);			// = float4(8.0/1280.0, 8.0/720.0, -4.0/1280.0, -4.0/720.0);

// Three samplers for the same texture:
//   sampler 0: exp bias =  0
//   sampler 1: exp bias = -1
//   sampler 2: exp bias = -2
sampler2D sourceSamplers[3] : register(s0);

#elif DX_VERSION == 11

CBUFFER_BEGIN(FXAA)
	CBUFFER_CONST(FXAA,			float4, 	g_externMathValues,		k_fxaa_extern_math_values)
	CBUFFER_CONST(FXAA,			float4, 	g_innerTapOffsets,		k_fxaa_inner_tap_offsets)
	CBUFFER_CONST(FXAA,			float4, 	g_outerTapOffsetsOpt, 	k_fxaa_outer_tap_offsets_opt)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	sourceSampler,		k_fxaa_source_sampler,		0)

#endif
