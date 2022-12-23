#if !defined(__ENTRYPOINTS_ACTIVE_CAMO_FXH)
#define __ENTRYPOINTS_ACTIVE_CAMO_FXH

#include "entrypoints/common.fxh"
#include "entrypoints/static_lighting.fxh"

struct ActiveCamoVertexOutput
{
	float4 texcoord : TEXCOORD1;
	float4 perturb : TEXCOORD0;
};


#include "active_camo_registers.fxh"

void active_camo_default_ps(
	in SCREEN_POSITION_INPUT(screenPosition),
	CLIP_INPUT
	in ActiveCamoVertexOutput interpolaters,
	out float4 outColor: SV_Target0)
{
	float2 uv = float2((screenPosition.x + 0.5f) / ps_textureSize.x, (screenPosition.y + 0.5f) / ps_textureSize.y);

	// ###kuttas $TODO: expose these "magic" constants to artists for direct control via the tag
	float2 uvdelta = ps_activeCamoFactor.yz * interpolaters.perturb.xy * 0.25f * float2(1.0f / 16.0f, 1.0f / 9.0f);
	
	[branch]
	if (distortionTextureEnabled)
	{
		float2 distortionTextureValue = sample2D(distortionTexture, transform_texcoord(interpolaters.texcoord.xy, ps_distortionTextureTransform)).xy;
		distortionTextureValue *= ps_activeCamoFactor.yz * ps_activeCamoFactor.w;
		uvdelta += distortionTextureValue;
	}

	// Perspective correction so we don't distort too much in the distance
	// (and clamp the amount we distort in the foreground too)
	uv.xy += uvdelta / max(0.5f, interpolaters.texcoord.w);

	outColor.rgb = sample2D(sceneTexture, uv.xy).rgb;
	outColor.a = ps_activeCamoFactor.x * ps_view_exposure.w;
}


void ActiveCamoVS(
	in float4 position,
	in float3 normal,
	in float2 texcoord,
	out ActiveCamoVertexOutput interpolaters)
{
	interpolaters.perturb.x = dot(normal, -vs_view_camera_right);
   	interpolaters.perturb.y = dot(normal, vs_view_camera_up);

   	// Spherical texture projection
   	interpolaters.perturb.z = atan2((position.x - 0.5f) * vs_mesh_position_compression_scale.x, (position.y - 0.5f) * vs_mesh_position_compression_scale.y);
   	float aspect = vs_mesh_position_compression_scale.z / length(vs_mesh_position_compression_scale.xy);
   	interpolaters.perturb.w = acos(position.z - 0.5f) * aspect;

   	interpolaters.texcoord.xy = texcoord;
   	interpolaters.texcoord.z = 0.0f;
   	interpolaters.texcoord.w = length(position.xyz - vs_view_camera_position);
}


////////////////////////////////////////////////////////////////////////////////
/// Active camo pass vertex shaders
////////////////////////////////////////////////////////////////////////////////

#define BUILD_ACTIVE_CAMO_VS(vertex_type)										\
void active_camo_##vertex_type##_vs(											\
	in s_##vertex_type##_vertex input,											\
	ISOLATE_OUTPUT out float4 out_position : SV_Position,						\
	CLIP_OUTPUT																	\
	out ActiveCamoVertexOutput activeCamoOutput)								\
{																				\
	s_vertex_shader_output output = (s_vertex_shader_output)0;					\
	BUILD_BASE_VS(vertex_type);													\
	ActiveCamoVS(input.position, input.normal, input.texcoord, activeCamoOutput); \
	SET_CLIP_OUTPUT(output);													\
}

// Build vertex shaders for the active camo pass
BUILD_ACTIVE_CAMO_VS(world);								// active_camo_world_vs
BUILD_ACTIVE_CAMO_VS(rigid);								// active_camo_rigid_vs
BUILD_ACTIVE_CAMO_VS(skinned);								// active_camo_skinned_vs
BUILD_ACTIVE_CAMO_VS(rigid_boned);							// active_camo_rigid_boned_vs
BUILD_ACTIVE_CAMO_VS(rigid_blendshaped);					// active_camo_rigid_blendshaped_vs
BUILD_ACTIVE_CAMO_VS(skinned_blendshaped);					// active_camo_skinned_blendshaped_vs


#endif 	// !defined(__ENTRYPOINTS_ACTIVE_CAMO_FXH)