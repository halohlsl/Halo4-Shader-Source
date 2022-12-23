#define FASTER_SHADOWS

#define SAMPLE_PERCENTAGE_CLOSER sample_percentage_closer_point
float sample_percentage_closer_point(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos);

#include "shadow_apply.fx"


float sample_percentage_closer_point(float3 fragment_shadow_position, float depth_bias, float2 pixel_pos)
{
	float shadow_depth= sample2D(shadow, fragment_shadow_position.xy).r;
	float depth_disparity= fragment_shadow_position.z - shadow_depth;
	return step(depth_disparity, depth_bias);
}
