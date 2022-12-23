#include "lighting/forge_lightmap.fxh"

#define forge_bx2_inv(x)	(((x) * 511.0 / 1023.0) + 512.0 / 1023.0)

float depth_test(float3 fragment_shadow_position, texture_sampler_2d shadowSampler, float bias)
{
#if (!defined(xenon)) && (DX_VERSION != 11)
	return 1.0f;
#else

	float4 sample;
#ifdef xenon	
	asm
	{
		tfetch2D sample.x___, fragment_shadow_position.xy, shadowSampler, MinFilter = point, MagFilter = point
	};
#elif DX_VERSION == 11
	sample.x = sample2D(shadowSampler, fragment_shadow_position.xy).x;
#endif
	
	// regular shadow test
	return (fragment_shadow_position.z <= sample.x);
#endif
}

float calculateFalloff(float3 originalPosition)
{
	float3 fragment_to_light = LIGHT_POSITION - originalPosition;				// vector from fragment to light
	float  light_dist2 = dot(fragment_to_light, fragment_to_light);				// distance to the light, squared
	float distance = sqrt(light_dist2);
	fragment_to_light /= distance;									// normalized vector pointing to the light

	float2 falloff;
	if (ps_dynamic_light_physically_correct)
	{
		falloff.x = (1.0f - saturate(distance / LIGHT_FAR_ATTENUATION_END)) / light_dist2;
	}
	else
	{
		// linear^3 is a closer approximation to distance^2 than linear^2
		falloff.x = saturate((LIGHT_FAR_ATTENUATION_END  - distance) * LIGHT_FAR_ATTENUATION_RATIO); // distance based falloff (2 instructions)
		falloff.x *= falloff.x * falloff.x;
	}
	
	falloff.y = saturate((dot(fragment_to_light, LIGHT_DIRECTION) - LIGHT_COSINE_CUTOFF_ANGLE) * LIGHT_ANGLE_FALLOFF_RAIO);
	falloff.y = pow(falloff.y, LIGHT_ANGLE_FALLOFF_POWER);
	
	return falloff.x * falloff.y; // (1 instruction)
}

void calculate_forge_lightmap(in float2 texcoord, in LightmapVertexOutput input, in float3 normal, out float4 outColor)	
{	
	// we're only drawing objects that were drawn to the current shadow buffer bucket. However, because
	// objects may straddle two or more buckets, we'll inevitably pass through parts of the object
	// that lie outside of the current shadow buffer bucket. So, if we see shadow-UV coordinates that are out of range,
	// we don't want to draw anything
	if	(saturate(input.fragment_position_shadow_forward.x) != input.fragment_position_shadow_forward.x 
		|| saturate(input.fragment_position_shadow_forward.y) != input.fragment_position_shadow_forward.y)
	{
		clip(-1);
		return;
	}
	
	outColor = float4(0.0, 0.0, 0.0, 1.0);
#if defined(xenon) || (DX_VERSION == 11)
	
	float combined_falloff;
	
	float dotProduct = dot(LIGHT_DIRECTION, normal);
	float absDotProduct = abs(dotProduct);
	float testValue = 1.0 - absDotProduct;
	float bias = -0.08f * testValue;
	
	if (dotProduct < 0.0f)
	{	
		combined_falloff = depth_test(input.fragment_position_shadow_backward, ps_shadow_sampler_backward, bias);
	}
	else
	{
		combined_falloff = depth_test(input.fragment_position_shadow_forward, ps_shadow_depth_map, bias);
	}

	outColor.xyz = LIGHT_COLOR * combined_falloff * absDotProduct * 2.0f;
#else
#endif
}

void forge_lightmap_default_ps(in SCREEN_POSITION_INPUT(vpos), const in LightmapVertexOutput input, out float4 outColor: SV_Target0)
{	
	calculate_forge_lightmap(vpos, input, input.normal.xyz, outColor);
}

void spotlight(const LightmapSpotlightVertexOutput input, float2 vpos, out float4 outColor)
{	
	float3 shadowProjection = input.fragment_position_shadow_forward.xyz / input.fragment_position_shadow_forward.w; // projective transform on xy coordinates
	
	outColor = float4(0.0, 0.0, 0.0, 1.0);
	
	// if the surface is pointing away from the light, it shouldn't be lit at all. DURR
	if (	dot(LIGHT_DIRECTION, input.normal) < 0.0f)
	{		
		return;
	}	
	// we're only drawing objects that were drawn to the current shadow buffer bucket. However, because
	// objects may straddle two or more buckets, we'll inevitably pass through parts of the object
	// that lie outside of the current shadow buffer bucket. So, if we see shadow-UV coordinates that are out of range,
	// we don't want to draw anything
	else if	(saturate(shadowProjection.x) != shadowProjection.x || saturate(shadowProjection.y) != shadowProjection.y)
	{
		return;
	}
		
#if defined(xenon) || (DX_VERSION == 11)
	// shadowing
	float combined_falloff = depth_test(shadowProjection, ps_shadow_depth_map, 0.0) * calculateFalloff(input.original_position.xyz);
	
	float3 newColor = float3(lerp(float3(LIGHT_DATA(1, w), LIGHT_DATA(1, w), LIGHT_DATA(1, w)), LIGHT_COLOR / 3.141592653589793 * VMF_BANDWIDTH, combined_falloff) );
	outColor.xyz = newColor;
#else
#endif
}

void forge_lightmap_spotlight_ps(const in LightmapSpotlightVertexOutput input, in SCREEN_POSITION_INPUT(vpos), out float4 outColor: SV_Target0)
{	
	spotlight(input, vpos, outColor);
}

void forge_lightmap_spotlight_inverse_ps(const in LightmapSpotlightVertexOutput input, in SCREEN_POSITION_INPUT(vpos), out float4 outColor: SV_Target0)
{	
	spotlight(input, vpos, outColor);
}									

// regular
BEGIN_TECHNIQUE static_per_pixel
{
	pass _default
	{
		SET_PIXEL_SHADER(forge_lightmap_default_ps());
	}
	TECHNIQUE_VERTEX_SHADERS
}

/*
// spotlights
BEGIN_TECHNIQUE
{
	pass _default
	{
		SET_PIXEL_SHADER(forge_lightmap_spotlight_ps());
	}
	TECHNIQUE_VERTEX_SHADERS
}*/