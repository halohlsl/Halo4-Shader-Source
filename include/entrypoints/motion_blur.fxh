#if !defined(__ENTRYPOINTS_MOTION_BLUR_FXH)
#define __ENTRYPOINTS_MOTION_BLUR_FXH

#include "entrypoints/common.fxh"
#include "entrypoints/static_lighting.fxh"

struct MotionBlurVertexOutput
{
	float4 currentFramePosition : TEXCOORD0;
	float4 previousFramePosition : TEXCOORD1;
};


float4 motion_blur_default_ps(
	in MotionBlurVertexOutput interpolaters) : SV_Target0
{
	float3 currentScreenPos = interpolaters.currentFramePosition.xyz / interpolaters.currentFramePosition.w;
	float3 previousScreenPos = interpolaters.previousFramePosition.xyz / interpolaters.previousFramePosition.w;

	float2 offset = (currentScreenPos.xy - previousScreenPos.xy);

	// Take the cube root of the value to increase precision in low motion
//	offset = sign(offset) * pow(offset, 1.0f / 3.0f);

	return float4(0.5 + 0.5 * offset, 0, 0);
}

////////////////////////////////////////////////////////////////////////////////
/// Motion blur pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

#if !defined(EXCLUDE_MODEL_MATRICES) && defined(USE_VERTEX_STREAM_SKINNING)

#define BUILD_MOTION_BLUR_VS(vertex_type)										\
void motion_blur_##vertex_type##_vs(											\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	out MotionBlurVertexOutput motionBlurOutput)								\
{																				\
	s_vertex_shader_output output = (s_vertex_shader_output)0;					\
	float4 local_to_world_transform[3];											\
	s_##vertex_type##_vertex inputVert = input;									\
	float4 oldOutPos;															\
	apply_transform_position_only(deform_previous_##vertex_type, inputVert, output, local_to_world_transform, oldOutPos);\
	oldOutPos= mul(inputVert.position, vs_previousViewProjectionMatrix);		\
	motionBlurOutput.previousFramePosition = oldOutPos;							\
	apply_transform_position_only(deform_##vertex_type, input, output, local_to_world_transform, out_position);\
	motionBlurOutput.currentFramePosition = out_position;						\
	float3 viewVector = (vs_view_camera_position.xyz - input.position.xyz);		\
	float viewVectorLength = length(viewVector);								\
	float scaleLength = max(viewVectorLength/50.0f, 0.005);						\
	input.position.xyz += viewVector * scaleLength / viewVectorLength;			\
	transform_identity(local_to_world_transform);								\
	world_projection_transform(input, local_to_world_transform, out_position);	\
}

#else

#define BUILD_MOTION_BLUR_VS(vertex_type)										\
void motion_blur_##vertex_type##_vs(											\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	out MotionBlurVertexOutput motionBlurOutput)								\
{																				\
	s_vertex_shader_output output = (s_vertex_shader_output)0;					\
	BUILD_BASE_VS(vertex_type);													\
	motionBlurOutput.previousFramePosition = motionBlurOutput.currentFramePosition = out_position;\
}

#endif

// Build vertex shaders for the motion blur pass
BUILD_MOTION_BLUR_VS(world);								// motion_blur_world_vs
BUILD_MOTION_BLUR_VS(rigid);								// motion_blur_rigid_vs
BUILD_MOTION_BLUR_VS(skinned);								// motion_blur_skinned_vs
BUILD_MOTION_BLUR_VS(rigid_boned);							// motion_blur_rigid_boned_vs
BUILD_MOTION_BLUR_VS(rigid_blendshaped);					// motion_blur_rigid_blendshaped_vs
BUILD_MOTION_BLUR_VS(skinned_blendshaped);					// motion_blur_skinned_blendshaped_vs


#endif 	// !defined(__ENTRYPOINTS_MOTION_BLUR_FXH)