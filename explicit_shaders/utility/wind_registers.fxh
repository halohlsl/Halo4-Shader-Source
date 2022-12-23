#if DX_VERSION == 9

DECLARE_PARAMETER(float4, wind_data, c246);
DECLARE_PARAMETER(float4, wind_data2, c247);
DECLARE_PARAMETER(sampler2D, wind_texture, s2);			// vertex shader

#elif DX_VERSION == 11

CBUFFER_BEGIN(WindVS)
	CBUFFER_CONST(WindVS,	float4,		wind_data,		eMSWR_wind)
	CBUFFER_CONST(WindVS,	float4,		wind_data2,		eMSWR_wind2)
CBUFFER_END

VERTEX_TEXTURE_AND_SAMPLER(_2D,	wind_texture,	_vs_wind_texture,	2)

#endif
