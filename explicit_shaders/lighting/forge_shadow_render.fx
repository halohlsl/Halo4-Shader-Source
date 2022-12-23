#include "lighting/shadows.fxh"
#include "core/core_vertex_types.fxh"
#include "deform.fxh"


////////////////////////////////////////////////////////////////////////////////
/// Forge shadow pass vertex shaders
////////////////////////////////////////////////////////////////////////////////
#define BUILD_FORGE_SHADOW_VS(vertex_type)								\
void forge_shadow_##vertex_type##_vs(									\
	in s_##vertex_type##_vertex input,								\
	ISOLATE_OUTPUT out float4 out_position : SV_Position)						\
{													\
	s_vertex_shader_output output = (s_vertex_shader_output)0;					\
	float4 local_to_world_transform[3];								\
	apply_transform(deform_##vertex_type, input, output, local_to_world_transform, out_position);	\
	output.texcoord= float4(input.texcoord.xy, input.texcoord1.xy);					\
}

// Build vertex shaders for the forge shadow passes
BUILD_FORGE_SHADOW_VS(world);			// forge_shadow_world_vs
BUILD_FORGE_SHADOW_VS(rigid);			// forge_shadow_rigid_vs
BUILD_FORGE_SHADOW_VS(skinned);			// forge_shadow_skinned_vs
BUILD_FORGE_SHADOW_VS(rigid_blendshaped);	// forge_shadow_rigid_blendshaped_vs
BUILD_FORGE_SHADOW_VS(skinned_blendshaped);	// forge_shadow_skinned_blendshaped_vs

void forge_shadow_position_only_vs(
	in s_tiny_position_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(deform_position_only, input, output, local_to_world_transform, out_position);
}


BEGIN_TECHNIQUE _default
{
	pass position_only
	{
		SET_VERTEX_SHADER(forge_shadow_position_only_vs());
	}
	pass world
	{
		SET_VERTEX_SHADER(forge_shadow_world_vs());
	}	
	pass rigid
	{
		SET_VERTEX_SHADER(forge_shadow_rigid_vs());
	}
	pass skinned
	{
		SET_VERTEX_SHADER(forge_shadow_skinned_vs());
	}	
	pass rigid_blendshaped
	{
		SET_VERTEX_SHADER(forge_shadow_rigid_blendshaped_vs());
	}
	pass skinned_blendshaped
	{
		SET_VERTEX_SHADER(forge_shadow_skinned_blendshaped_vs());
	}
}