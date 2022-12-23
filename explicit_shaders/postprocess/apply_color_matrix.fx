#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "apply_color_matrix_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

//[reduceTempRegUsage(3)]
float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	float4 color = sample2D(ps_source_sampler, input.texcoord);

	float4 dest_color;
	dest_color.r = dot(dest_red.rgba,	color.rgba);
	dest_color.g = dot(dest_green.rgba,	color.rgba);
	dest_color.b = dot(dest_blue.rgba,	color.rgba);
	dest_color.a = dot(dest_alpha.rgba,	color.rgba);

	return dest_color;
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



