#if !defined(__COLOR_FXH)
#define __COLOR_FXH


// takes an incoming color and re-maps incoming color range
float3 color_remap(
            const float3 colorIn,
			const float inMin,
			const float inMax,
			const float outMin,
			const float outMax)
{
	return outMin + saturate((colorIn - inMin) / (inMax - inMin)) * (outMax - outMin);
}


float float_remap(
            const float floatIn,
			const float inMin,
			const float inMax,
			const float outMin,
			const float outMax)
{
	return outMin + saturate((floatIn - inMin) / (inMax - inMin)) * (outMax - outMin);
}


// Performs a threshold (clamping) operation on an incoming color, much like photoshop's threshold adjustment
float3 color_threshold(
            float3 colorin,
            float  threshold_min,
            float  threshold_max)
{
      float  max = threshold_min + (threshold_max/255.0);
      return color_remap(colorin, threshold_min, max, 0, 1);
}

float float_threshold(
            float  colorin,
            float  threshold_min,
            float  threshold_max)
{
      float  max = threshold_min + (threshold_max/255.0);
      return float_remap(colorin, threshold_min, max, 0, 1);
}


// Returns luminance
float color_luminance(
            const float3 color )
{
    return dot(float3(0.2125,0.7154,0.0721), color);
}


float3 color_saturation(
        const float3 color,
        const float saturation)
{
    float3 luma = color_luminance(color);
    float3 result = lerp(luma, color, saturation);
    return result;
}


float3 color_screen (float3 a, float3 b){
    float3 white = float3(1.0,1.0,1.0);
    return (white - (white-a)*(white-b));
}

float3 ColorScreenExtendedRange(float3 a, float3 b)
{
    return max(max(a, b), (1 - saturate(1 - a) * saturate(1 - b)));
}


// Performs an overaly composite simalir to photoshop, all in-coming color values should be linear
float3 color_overlay(
            float3 base,
            float3 blend)
{
    base  = pow(base, 0.5);    // sRGB
    blend = pow(blend, 0.5);   // sRGB
    float3 result = base <= 0.5 ? ( (2.0 * base) * blend) : (1.0 - 2.0*((1.0 - blend.xyz) * (1.0 - base.xyz)));
    return result * result;    // linear
}



float3 color_composite_detail(
            float3 color_base,
            float3 color_detail)
{
    const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)
    color_detail.rgb *= DETAIL_MULTIPLIER;
    color_base *= color_detail;
    return color_base;
}







#endif 	// !defined(__CORE_TYPES_FXH)
