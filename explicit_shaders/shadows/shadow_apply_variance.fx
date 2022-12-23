#define FASTER_SHADOWS
#define VARIANCE

#ifndef SAMPLE_PERCENTAGE_CLOSER
#define SAMPLE_PERCENTAGE_CLOSER ComputeVarianceAttenuation
#endif

float ComputeVarianceAttenuation(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos);

#include "shadow_apply.fx"

#define VSM_EPSILON			ps_shadow_parameters[9].r
#define VSM_DPOW			ps_shadow_parameters[9].g
#define VSM_ATTENUATIONPOW	ps_shadow_parameters[9].b

float ComputeVarianceAttenuation(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos)
{
    float4 VSM   = sample2D(shadow, fragment_shadow_position.xy);
    float  filteredZ  = VSM.r; // Filtered z
    float  filteredZ2 = VSM.g; // Filtered z-squared

    // Standard shadow map comparison
    if(fragment_shadow_position.z <= filteredZ)
	{
        return 1.0f;
	}
	else
	{
		const float VSMEpsilon = VSM_EPSILON;

		// Use variance shadow mapping to compute the maximum probability that the
		// pixel is in shadow
		float variance = filteredZ2 - filteredZ * filteredZ;
		variance       = saturate(variance + VSMEpsilon);
		
		float mean     = filteredZ;
		float d        = fragment_shadow_position.z - mean;
		float d2 	   = pow(d, VSM_DPOW);
		float p_max    = variance / (variance + d2);

#ifdef BLOB
		float output = p_max * p_max; // for blobs, don't worry about light bleeding as much
#else
		// To combat light-bleeding, experiment with raising p_max to some power
		// (Try values from 0.1 to 100.0, if you like.)
		float output = pow(p_max, VSM_ATTENUATIONPOW);
#endif
		
		return output;
	}
}
