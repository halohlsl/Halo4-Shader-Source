#if !defined(__ENTRYPOINTS_DECALS_FXH)
#define __ENTRYPOINTS_DECALS_FXH

#include "entrypoints/common.fxh"
#include "decals_registers.fxh"

struct ActiveCamoInterpolaters
{
	float4 texcoord : TEXCOORD1;
	float4 perturb : TEXCOORD0;
};

struct DecalInterpolators
{
	float4 texcoord:				TEXCOORD0;
};

void calc_clip(inout s_vertex_shader_output output, in float4 out_position)
{
#if DX_VERSION == 11
	output.clipDistance = dot(out_position, vs_clip_plane);
#endif
}

void default_default_ps(
	in s_pixel_shader_input pixel_shader_input,
	in SCREEN_POSITION_INPUT(screenPosition)
#if defined(DECAL_OUTPUT_COLOR)
	, out float4 outColor: SV_Target0
#endif
#if defined(DECAL_OUTPUT_NORMAL)
	, out float4 outNormal: SV_Target1
#endif
	)
{
#if !defined(DECAL_DISABLE_TEXCOORD_CLIP)
	clip(float4(pixel_shader_input.texcoord.xy, 1.0f - pixel_shader_input.texcoord.xy));
#endif
	s_shader_data shader_data = init_shader_data(pixel_shader_input, get_default_platform_input(), LM_DEFAULT);
	shader_data.common.shaderPass = SP_DECALS;

	pixel_pre_lighting(pixel_shader_input, shader_data);

#if defined(DECAL_OUTPUT_COLOR)
	outColor = shader_data.common.albedo;
#endif

#if defined(DECAL_OUTPUT_NORMAL)
	outNormal.xy = EncodeWorldspaceNormal(shader_data.common.normal);
	outNormal.z = 0.0f;							// note: these are masked out in code
	outNormal.w = shader_data.common.albedo.a;	// via set_color_write_enable()
#endif
}

void default_world_vs(
	in s_world_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output
	)
{
	output= (s_vertex_shader_output)0;
#if defined(DECAL_OUTPUT_NORMAL)
	input.tangent.w = -1.0f;
#endif

	float creationTime = input.position.w;
	input.position.w = 1.0f;
	float4 realOutPosition = mul(input.position, vs_view_view_projection_matrix);

	float4 local_to_world_transform[3];
	apply_transform(deform_world, input, output, local_to_world_transform, out_position);
	output.texcoord= input.texcoord.xyxy;

	float normalizedLifetime = (vs_time - creationTime) / vsCurrentTimeLifetime.x;
#if defined(DECAL_MODULATED_TINT) || defined(DECAL_UNMODULATED_TINT) || defined(DECAL_GRADIENT_MODULATED_TINT)
	if (normalizedLifetime > 0.99f && vsCurrentTimeLifetime.x > 0.001f)
	{
		realOutPosition = vsNaN;
	}
#endif
	output.texcoord.z = 1.0f - clamp(normalizedLifetime, 0.0f, 0.99f);
	out_position = realOutPosition;
	calc_clip(output, out_position);
}

void default_rigid_vs(
	in s_rigid_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output
	)
{
	output= (s_vertex_shader_output)0;
#if defined(DECAL_OUTPUT_NORMAL)
	input.tangent.w = -1.0f;
#endif

	float4 local_to_world_transform[3];
	apply_transform(deform_rigid, input, output, local_to_world_transform, out_position);
	output.texcoord= input.texcoord.xyxy;
	output.texcoord.z = 1.0f;
	calc_clip(output, out_position);
}

void default_skinned_vs(
	in s_skinned_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output
	)
{
	output= (s_vertex_shader_output)0;
#if defined(DECAL_OUTPUT_NORMAL)
	input.tangent.w = -1.0f;
#endif

	float4 local_to_world_transform[3];
	apply_transform(deform_skinned, input, output, local_to_world_transform, out_position);
	output.texcoord= input.texcoord.xyxy;
	output.texcoord.z = 1.0f;
	calc_clip(output, out_position);
}

void default_rigid_boned_vs(
	in s_rigid_boned_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output
	)
{
	output= (s_vertex_shader_output)0;
#if defined(DECAL_OUTPUT_NORMAL)
	input.tangent.w = -1.0f;
#endif

	float4 local_to_world_transform[3];
	apply_transform(deform_rigid_boned, input, output, local_to_world_transform, out_position);
	output.texcoord= input.texcoord.xyxy;
	output.texcoord.z = 1.0f;
	calc_clip(output, out_position);
}


void default_flat_world_vs(
	in s_flat_world_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output
	)
{
	output= (s_vertex_shader_output)0;
#if defined(DECAL_OUTPUT_NORMAL)
	input.tangent.w = -1.0f;
#endif

	float creationTime = input.position.w;
	input.position.w = 1.0f;
	float4 realOutPosition = mul(input.position, vs_view_view_projection_matrix);

	float4 local_to_world_transform[3];
	apply_transform(deform_flat_world, input, output, local_to_world_transform, out_position);
	output.texcoord= input.texcoord.xyxy;

	float normalizedLifetime = (vs_time - creationTime) / vsCurrentTimeLifetime.x;
#if defined(DECAL_MODULATED_TINT) || defined(DECAL_UNMODULATED_TINT) || defined(DECAL_GRADIENT_MODULATED_TINT)
	if (normalizedLifetime > 0.99f && vsCurrentTimeLifetime.x > 0.001f)
	{
		realOutPosition = vsNaN;
	}
#endif
	output.texcoord.z = 1.0f - clamp(normalizedLifetime, 0.0f, 0.99f);
	out_position = realOutPosition;
	calc_clip(output, out_position);
}

void default_flat_rigid_vs(
	in s_flat_rigid_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output
	)
{
	output= (s_vertex_shader_output)0;
#if defined(DECAL_OUTPUT_NORMAL)
	input.tangent.w = -1.0f;
#endif

	float4 local_to_world_transform[3];
	apply_transform(deform_flat_rigid, input, output, local_to_world_transform, out_position);
	output.texcoord= input.texcoord.xyxy;
	output.texcoord.z = 1.0f;
	calc_clip(output, out_position);
}

void default_flat_skinned_vs(
	in s_flat_skinned_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position,
	out s_vertex_shader_output output
	)
{
	output= (s_vertex_shader_output)0;
#if defined(DECAL_OUTPUT_NORMAL)
	input.tangent.w = -1.0f;
#endif

	float4 local_to_world_transform[3];
	apply_transform(deform_flat_skinned, input, output, local_to_world_transform, out_position);
	output.texcoord= input.texcoord.xyxy;
	output.texcoord.z = 1.0f;
	calc_clip(output, out_position);
}

#endif 	// !defined(__ENTRYPOINTS_ACTIVE_CAMO_FXH)