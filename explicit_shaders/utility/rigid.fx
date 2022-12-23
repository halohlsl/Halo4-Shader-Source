#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"

#define rigid_node0 vs_model_world_matrix[0]
#define rigid_node1 vs_model_world_matrix[1]
#define rigid_node2 vs_model_world_matrix[2]

struct s_vertex_output_transparent
{
	float4 position:	SV_Position;
	float2 texcoord:	TEXCOORD0;
	float4 color:		COLOR0;
};

s_vertex_output_transparent default_vs(s_transparent_vertex input)
{
	s_vertex_output_transparent output;

	output.position.x = dot(float4(input.position, 1.f), rigid_node0);
	output.position.y = dot(float4(input.position, 1.f), rigid_node1);
	output.position.z = dot(float4(input.position, 1.f), rigid_node2);
	output.position.w = 1.f;

	output.position = mul(output.position, vs_view_view_projection_matrix);

	output.color = input.color;
	output.texcoord = input.texcoord;

    return output;
}


float4 default_ps(const in s_vertex_output_transparent input) : SV_Target
{
	return apply_exposure(float4(1,1,1,1));
}


BEGIN_TECHNIQUE _default
{
	pass transparent
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

