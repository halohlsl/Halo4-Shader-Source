#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

#include "entrypoints/common.fxh"


void deform_world(inout s_world_vertex vertex)
{
}

void default_world_vs(
	in s_world_vertex input,
	ISOLATE_OUTPUT out float4 out_position: SV_Position
#if DX_VERSION == 11
	,out float4 out_transformed_position : TEXCOORD0
#endif	
	)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;	
	float4 local_to_world_transform[3];
	apply_transform(deform_world, input, output, local_to_world_transform, out_position);
#if DX_VERSION == 11	
	out_transformed_position = out_position;
#endif	
}


float4 default_ps(
	in float4 screenPosition : SV_Position,
	in float4 position : TEXCOORD0) : SV_Target
{
	return float4(position.z, position.z, position.z, 1.0f);
}

BEGIN_TECHNIQUE _default
{
	pass world
	{
		SET_VERTEX_SHADER(default_world_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


void memexport_blank_vs(
	out float4 position : SV_Position)
{
	position= 0.0f;
}

float4 memexport_blank_ps() :SV_Target0
{
	return float4(0,1,2,3);
}

BEGIN_TECHNIQUE active_camo
{
	pass world
	{
		SET_VERTEX_SHADER(memexport_blank_vs());
		SET_PIXEL_SHADER(memexport_blank_ps());
	}
}
