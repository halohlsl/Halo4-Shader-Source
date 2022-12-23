#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "paint_constant_color_at_depth_registers.fxh"


struct s_vertex_output_screen
{
    float4 position:		SV_Position;
};

s_vertex_output_screen default_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen output;
	output.position=	float4(input.position.xy, ps_depth_value, 1.0);
	return output;
}

float4 default_ps() : SV_Target
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



