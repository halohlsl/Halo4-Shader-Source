#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "effects_debug_wireframe_registers.fxh"


void default_world_vs(
	in s_world_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;	
	float4 local_to_world_transform[3];
	apply_transform(deform_world, input, output, local_to_world_transform, out_position);
}

float4 default_ps() : SV_Target
{
	return debugColor;
}


BEGIN_TECHNIQUE _default
{
	pass world
	{
		SET_VERTEX_SHADER(default_world_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


