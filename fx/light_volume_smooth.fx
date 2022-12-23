#include "fx/light_volume_core.fxh"

DECLARE_FLOAT_WITH_DEFAULT(centerOffset, "Center Offset", "", 0, 1.4142, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(falloff, "Falloff exponent", "", 0, 10, float(2.0));
#include "used_float.fxh"

// do the color shuffle
float4 PixelComputeColor(
	in LightVolumeInterpolatedValues lightVolumeValues)
{
	float2 fromCenter = 2 * lightVolumeValues.texcoord - 1;
	float radius = saturate(centerOffset - centerOffset * dot(fromCenter.xy, fromCenter.xy));
	float alpha = pow(radius, falloff);
	return float4(alpha, alpha, alpha, 1.0f);
}

#include "fx/light_volume_techniques.fxh"