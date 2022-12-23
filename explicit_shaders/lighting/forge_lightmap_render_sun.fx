#include "lighting/forge_lightmap.fxh"

void forge_lightmap_sun_ps(
	in float4 screenPosition : SV_Position,
	const in float4 fragment_position_shadow_forward : TEXCOORD0, 
	in float3 normal : NORMAL, 
	in SCREEN_POSITION_INPUT(vpos), 
	out float4 outColor: SV_Target0)
{	
	float3 shadowProjection = fragment_position_shadow_forward.xyz;
	
	outColor = (1.0 / 255.0);	
	// we're only drawing objects that were drawn to the current shadow buffer bucket. However, because
	// objects may straddle two or more buckets, we'll inevitably pass through parts of the object
	// that lie outside of the current shadow buffer bucket. So, if we see shadow-UV coordinates that are out of range,
	// we don't want to draw anything
	if	(saturate(shadowProjection.x) != shadowProjection.x || saturate(shadowProjection.y) != shadowProjection.y)
	{
		clip(-1);
		return;
	}
	// if the surface is pointing away from the light, it shouldn't be lit at all. DURR
	else if (	dot(LIGHT_DIRECTION, normal) < 0.0f)
	{		
		return;
	}
						
	outColor = max(1.0 / 255.0, sample_percentage_closer_PCF_5x5_block_predicated(shadowProjection, -0.001f));
}									
					
BEGIN_TECHNIQUE static_per_pixel
{
	pass _default
	{
		SET_PIXEL_SHADER(forge_lightmap_sun_ps());
	}
	TECHNIQUE_SUN_VERTEX_SHADERS
}