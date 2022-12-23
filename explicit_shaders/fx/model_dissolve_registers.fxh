#if DX_VERSION == 9

DECLARE_PARAMETER(float4, vs_dissolvePointAndRadius, c8);

#elif DX_VERSION == 11

CBUFFER_BEGIN(ModelDissolveVS)
	CBUFFER_CONST(ModelDissolveVS,		float4,		vs_dissolvePointAndRadius,		k_vs_model_dissolve_point_and_radius)
CBUFFER_END

#endif
