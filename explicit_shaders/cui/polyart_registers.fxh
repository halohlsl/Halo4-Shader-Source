#if DX_VERSION == 9

DECLARE_PARAMETER(sampler, vector_map, s0);

DECLARE_PARAMETER(sampler2D, sampler0, s0);
DECLARE_PARAMETER(sampler2D, sampler1, s1);
DECLARE_PARAMETER(sampler2D, sampler2, s2);

DECLARE_PARAMETER(float4, baseColor, c16);
DECLARE_PARAMETER(float4x3, modelViewMatrix, c17);
DECLARE_PARAMETER(float4x4, projectionMatrix, c20);
DECLARE_PARAMETER(float4, widgetBounds, c24);

#elif DX_VERSION == 11

CBUFFER_BEGIN(PolyArtVS)
	CBUFFER_CONST(PolyArtVS,		float4,		baseColor,			k_vs_polyart_base_color)
	CBUFFER_CONST(PolyArtVS,		float4x3,	modelViewMatrix,	k_vs_polyart_model_view_matrix)
	CBUFFER_CONST(PolyArtVS,		float4x4,	projectionMatrix,	k_vs_polyart_projection_matrix)
	CBUFFER_CONST(PolyArtVS,		float4,		widgetBounds,		k_vs_polyart_widget_bounds)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	sampler0, 	k_ps_polyart_sampler0,	0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	sampler1, 	k_ps_polyart_sampler1,	1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	sampler2, 	k_ps_polyart_sampler2,	2)

#endif
