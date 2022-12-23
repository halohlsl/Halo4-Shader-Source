/// Explicit shader for rendering basic world positions with colors

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"
#include "debug_registers.fxh"

struct s_vertex_output_debug_color
{
    float4 position:		SV_Position;
    float4 color:			TEXCOORD0;
};

s_vertex_output_debug_color default_vs(const in s_debug_vertex input)
{
	s_vertex_output_debug_color output;

	// transform by model to world transform
	float3 pos = transform_point(float4(input.position, 1.0), vs_model_world_matrix);

	// camera and projection
	output.position	= mul(float4(pos, 1.0f), vs_view_view_projection_matrix);

	// pass in color
	output.color	= input.color;
	return output;
}

float4 default_ps(const in s_vertex_output_debug_color input) : SV_Target
{
	return lerp(input.color, debug_color, debug_interp);
}


BEGIN_TECHNIQUE			// default entrypoint
{
	pass debug		// debug vertex type
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
