#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
};

s_vertex_output_screen_tex default_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	return output;
}

float4 default_ps(in s_vertex_output_screen_tex input) : SV_Target
{
	return ps_scale.rgba;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


