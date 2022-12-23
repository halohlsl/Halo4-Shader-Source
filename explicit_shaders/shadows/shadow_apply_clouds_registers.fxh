#if DX_VERSION == 9

DECLARE_PARAMETER(			float4x4,	ps_view_transform_inverse,												c213);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ShadowApplyCloudsPS)
	CBUFFER_CONST(ShadowApplyCloudsPS,		float4x4,		ps_view_transform_inverse,		k_ps_shadow_apply_clouds_view_transform_inverse)
CBUFFER_END

#endif
