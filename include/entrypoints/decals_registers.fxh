#if DX_VERSION == 9

DECLARE_PARAMETER(float4,	vsCurrentTimeLifetime,	c10)= (float4)1;
DECLARE_PARAMETER(float4,	vsNaN, c9);

#elif DX_VERSION == 11

CBUFFER_BEGIN(DecalsVS)
	CBUFFER_CONST(DecalsVS,		float4,			vsCurrentTimeLifetime,		k_vs_decals_current_time_lifetime)
	CBUFFER_CONST(DecalsVS,		float4,			vsNaN,						k_vs_decals_nan)
CBUFFER_END

#endif
