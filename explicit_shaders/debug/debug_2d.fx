/// Explicit shader for rendering basic world positions in 2d with colors

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"

struct s_vertex_output_debug_color
{
    float4 position:		SV_Position;
    float4 color:			TEXCOORD0;
};

s_vertex_output_debug_color default_vs(const in s_debug_vertex input)
{
	s_vertex_output_debug_color output;

	output.position	= float4(input.position.xy, 1.0f, 1.0f);
	output.color	= input.color;
	return output;
}

float4 default_ps(const in s_vertex_output_debug_color input) : SV_Target
{
	return (input.color);
}


BEGIN_TECHNIQUE			// default entrypoint
{
	pass debug		// debug vertex type
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
