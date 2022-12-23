#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "deform.fxh"
#include "exposure.fxh"
#include "model_dissolve_registers.fxh"

DECLARE_SAMPLER(texture_map, "Texture Map", "Texture Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_FLOAT_WITH_DEFAULT(crack_intensity, "Crack Intensity", "", 0, 1, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edge_falloff_power, "Edge Falloff Power", "", 0, 10, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edge_intensity, "Edge Intensity", "", 0, 1, float(1));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(crack_color, "Color", "", float3(1, 1, 1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(edge_color, "Color", "", float3(1, 1, 1));
#include "used_float3.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(gradient_size, "Inner Gradient Size", "", 0, 1, float(0.1));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(crack_fat_power, "Crack Fat Power", "", 0, 1, float(1));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(crack_fat_offset, "Crack Fat Offset", "", 0, 1, float(0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(crack_fat_multiplier, "Crack Fat Multiplier", "", 0, 1, float(1));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(crack_thin_power, "Crack Fat Power", "", 0, 1, float(1));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(crack_thin_offset, "Crack Fat Offset", "", 0, 1, float(0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(crack_thin_multiplier, "Crack Fat Multiplier", "", 0, 1, float(1));
#include "used_vertex_float.fxh"

void ModelDissolveVS(
	in float3 position,
	in float2 texcoord,
	out float3 dissolveDistance,
	out float3 crackParameters)
{
	dissolveDistance.x = length(position - vs_dissolvePointAndRadius.xyz) - vs_dissolvePointAndRadius.w;
	dissolveDistance.y = gradient_size - dissolveDistance.x;
	dissolveDistance.z = 1.0f - dissolveDistance.x / gradient_size;
	
	crackParameters.x = lerp(crack_thin_power, crack_fat_power, dissolveDistance.z);
	crackParameters.y = lerp(crack_thin_offset, crack_fat_offset, dissolveDistance.z);
	crackParameters.z = lerp(crack_thin_multiplier, crack_fat_multiplier, dissolveDistance.z);
}

// we're gonna put this in the shield_impact pass
#define BUILD_SHIELD_IMPACT_VS(vertex_type)										\
void shield_impact_##vertex_type##_vs(												\
	in s_##vertex_type##_vertex input,													\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,					\
	out float2 texcoord : TEXCOORD0,														\
	out float3 dissolveDistance : TEXCOORD1,										\
	out float3 crackParameters : TEXCOORD2)											\
{																															\
	s_vertex_shader_output output = (s_vertex_shader_output)0;	\
	output = (s_vertex_shader_output)0;													\
	float4 local_to_world_transform[3];													\
	apply_transform(deform_##vertex_type, input, output, local_to_world_transform, out_position);\
	texcoord = input.texcoord.xy;																\
	ModelDissolveVS(input.position, texcoord, dissolveDistance, crackParameters);\
}

// Build vertex shaders for the shield_impact pass
BUILD_SHIELD_IMPACT_VS(world);											// shield_impact_world_vs
BUILD_SHIELD_IMPACT_VS(rigid);											// shield_impact_rigid_vs
BUILD_SHIELD_IMPACT_VS(skinned);										// shield_impact_skinned_vs
BUILD_SHIELD_IMPACT_VS(rigid_boned);								// shield_impact_rigid_boned_vs
BUILD_SHIELD_IMPACT_VS(rigid_blendshaped);					// shield_impact_rigid_blendshaped_vs
BUILD_SHIELD_IMPACT_VS(skinned_blendshaped);				// shield_impact_skinned_blendshaped_vs

float4 shield_impact_default_ps(
	in float4 position				: SV_Position,
	in float2 texcoord				: TEXCOORD0,
	in float3 dissolveDistance: TEXCOORD1,
	in float3 crackParameters : TEXCOORD2) : SV_Target0
{
#if defined(xenon) || (DX_VERSION == 11)
	float4 finalColor = float4(0, 0, 0, 0);
	
	clip(dissolveDistance.xy);
	
	// we want the "gradient" to be 1 at the dissolve surface, and 0 at a point outside of that
	float gradient = dissolveDistance.z;
	
	float textureSample = sample2D(texture_map, transform_texcoord(texcoord, texture_map_transform)).r;
	
	float crackPower = crackParameters.x;
	float crackOffset = crackParameters.y;
	float crackMultiplier = crackParameters.z;
	
	float cracks = saturate(pow(textureSample, crackPower) - crackOffset) * crackMultiplier * crack_intensity;
	
	float edge = pow(gradient, edge_falloff_power) * edge_intensity;
	
	finalColor = float4(crack_color, 1.0f) * cracks + float4(edge_color, 1.0f) * edge;
	
	finalColor.a = saturate(finalColor.a);

#else // pc
	float4	finalColor=		0.0f;
#endif // xenon

	return ApplyExposureScaleSelfIllum(finalColor, GetLinearColorIntensity(finalColor));
}

#include "techniques_base.fxh"

MAKE_TECHNIQUE_OVERRIDE(_default, shield_impact)
