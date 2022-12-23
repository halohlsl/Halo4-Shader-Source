#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "deform.fxh"
#include "exposure.fxh"


void shadow_geometry_tiny_position_vs(
	in s_tiny_position_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(deform_tiny_position_projective, input, output, local_to_world_transform, out_position);
}


float4 shadow_geometry_default_ps() : SV_Target
{
	return apply_exposure(ps_model_vmf_lighting[0]);
}


BEGIN_TECHNIQUE _default
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(shadow_geometry_tiny_position_vs());
		SET_PIXEL_SHADER(shadow_geometry_default_ps());
	}
}

