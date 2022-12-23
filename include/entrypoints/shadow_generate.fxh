#if !defined(__ENTRYPOINTS_SHADOW_GENERATE_FXH)
#define __ENTRYPOINTS_SHADOW_GENERATE_FXH

#include "entrypoints/common.fxh"



////////////////////////////////////////////////////////////////////////////////
/// Basic shadow generate pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

#define BUILD_SHADOW_GENERATE_VS(vertex_type)									\
void shadow_generate_##vertex_type##_vs(										\
	in s_##vertex_type##_vertex input,											\
	CLIP_OUTPUT																	\
	ISOLATE_OUTPUT out float4 out_position: SV_Position)						\
{																				\
	s_vertex_shader_output output = (s_vertex_shader_output)0;					\
	BUILD_BASE_VS(vertex_type);													\
	SET_CLIP_OUTPUT(output);													\
}

// Build vertex shaders for the shadow generate pass
BUILD_SHADOW_GENERATE_VS(world);							// shadow_generate_world_vs
BUILD_SHADOW_GENERATE_VS(rigid);							// shadow_generate_rigid_vs
BUILD_SHADOW_GENERATE_VS(skinned);							// shadow_generate_skinned_vs
BUILD_SHADOW_GENERATE_VS(rigid_boned);						// shadow_generate_rigid_boned_vs
BUILD_SHADOW_GENERATE_VS(rigid_blendshaped);				// shadow_generate_rigid_blendshaped_vs
BUILD_SHADOW_GENERATE_VS(skinned_blendshaped);				// shadow_generate_skinned_blendshaped_vs




////////////////////////////////////////////////////////////////////////////////
/// Shadow generate pass vertex shaders (with lightmap UVs)
////////////////////////////////////////////////////////////////////////////////

#define BUILD_SHADOW_GENERATE_TEXTURED_VS(vertex_type)							\
void shadow_generate_textured_##vertex_type##_vs(								\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 outPosition : SV_Position,						\
	CLIP_OUTPUT																	\
	out float4 outTexcoord: TEXCOORD0)											\
{																				\
	s_lighting_vertex_shader_output output = (s_lighting_vertex_shader_output)0; \
	static_default_##vertex_type##_vs(input, outPosition, output);				\
	outTexcoord = output.texcoord;												\
	SET_CLIP_OUTPUT(output);													\
}

// Build vertex shaders for the shadow generate pass
// Only gets used when REQUIRE_Z_PASS_PIXEL_SHADER is defined
BUILD_SHADOW_GENERATE_TEXTURED_VS(world);					// shadow_generate_textured_world_vs
BUILD_SHADOW_GENERATE_TEXTURED_VS(rigid);					// shadow_generate_textured_rigid_vs
BUILD_SHADOW_GENERATE_TEXTURED_VS(skinned);					// shadow_generate_textured_skinned_vs
BUILD_SHADOW_GENERATE_TEXTURED_VS(rigid_boned);				// shadow_generate_textured_rigid_boned_vs
BUILD_SHADOW_GENERATE_TEXTURED_VS(rigid_blendshaped);		// shadow_generate_textured_rigid_blendshaped_vs
BUILD_SHADOW_GENERATE_TEXTURED_VS(skinned_blendshaped);		// shadow_generate_textured_skinned_blendshaped_vs

void shadow_generate_textured_default_ps(
#if DX_VERSION == 11
	in float4 screenPosition : SV_Position,
#endif
	CLIP_INPUT
	in float4 inputTexcoord : TEXCOORD0,
	out float4 out_color: SV_Target0)
{
	s_pixel_shader_input pixel_shader_input = (s_pixel_shader_input)0;

	pixel_shader_input.texcoord = inputTexcoord;

	s_shader_data shader_data= init_shader_data(pixel_shader_input, get_default_platform_input(), LM_DEFAULT);
	pixel_pre_lighting(pixel_shader_input, shader_data);

	out_color = float4(0,0,0,0);
}


#endif 	// !defined(__ENTRYPOINTS_SHADOW_GENERATE_FXH)