#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "deform.fxh"
#include "exposure.fxh"


void shadow_geometry_world_vs(
	in s_world_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(deform_world, input, output, local_to_world_transform, out_position);
}

void shadow_geometry_tiny_position_vs(
	in s_tiny_position_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(deform_tiny_position, input, output, local_to_world_transform, out_position);
}

void shadow_geometry_position_only_vs(
	in s_tiny_position_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(deform_position_only, input, output, local_to_world_transform, out_position);
}



float4 shadow_geometry_default_ps() : SV_Target
{
	return apply_exposure(ps_model_vmf_lighting[0]);
}


BEGIN_TECHNIQUE _default
{
	pass _default
	{
		SET_PIXEL_SHADER(shadow_geometry_default_ps());
	}
	pass world
	{
		SET_VERTEX_SHADER(shadow_geometry_world_vs());
	}
	pass tiny_position
	{
		SET_VERTEX_SHADER(shadow_geometry_tiny_position_vs());
	}
	pass position_only
	{
		SET_VERTEX_SHADER(shadow_geometry_position_only_vs());
	}
}

// for stencils that have a fixed screen-space location

void shadow_geometry_tiny_position_fixed_vs(
	in s_tiny_position_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	DecompressPosition(input.position);
	out_position = input.position;
}

BEGIN_TECHNIQUE albedo
{
	pass _default
	{
		SET_PIXEL_SHADER(shadow_geometry_default_ps());
	}
	pass world
	{
		SET_VERTEX_SHADER(shadow_geometry_world_vs());
	}
	pass tiny_position
	{
		SET_VERTEX_SHADER(shadow_geometry_tiny_position_fixed_vs());
	}
	pass position_only
	{
		SET_VERTEX_SHADER(shadow_geometry_position_only_vs());
	}
}
