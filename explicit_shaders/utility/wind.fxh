#if !defined(__WIND_FXH)
#define __WIND_FXH

#include "wind_registers.fxh"

#if defined(xenon) || (DX_VERSION == 11)

float2 sample_wind(float2 position)
{
	// apply wind
	float2 texc= position.xy * wind_data.z + wind_data.xy;			// calculate wind texcoord
	float4 wind_vector;
#ifdef xenon
	asm {
		tfetch2D wind_vector, texc, wind_texture, MinFilter=linear, MagFilter=linear, UseComputedLOD=false, UseRegisterGradients=false
	};
#else
	wind_vector = wind_texture.t.SampleLevel(wind_texture.s, texc, 0);
#endif	
	wind_vector.xy= wind_vector.xy * wind_data2.z + wind_data2.xy;			// scale motion and add in bend
	
	return wind_vector;
}

#else	// defined(xenon)

float2 sample_wind(float2 position)
{
	return 0;
}

#endif	// defined(xenon)

#endif  