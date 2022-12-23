#if DX_VERSION == 9

DECLARE_PARAMETER(			float4,		atmosphereGroundFunction[64],	c17);
DECLARE_PARAMETER(			float4,		atmosphereSkyFunction[64],		c81);

#elif DX_VERSION == 11

CBUFFER_BEGIN(AtmosphereCalculatePS)
	CBUFFER_CONST_ARRAY(AtmosphereCalculatePS,	float4,		atmosphereGroundFunction, [64],		k_ps_atmosphere_calculate_ground_function)
	CBUFFER_CONST_ARRAY(AtmosphereCalculatePS,	float4,		atmosphereSkyFunction, [64],		k_ps_atmosphere_calculate_sky_function)
CBUFFER_END

#endif
