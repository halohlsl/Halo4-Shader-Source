#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(ps_source_sampler,		0);


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


float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	float4 color = 0.0f;

	// this is a 4x4 box filter
	color += Sample2DOffset(ps_source_sampler, input.texcoord, -1, -1);
	color += Sample2DOffset(ps_source_sampler, input.texcoord, +1, -1);
	color += Sample2DOffset(ps_source_sampler, input.texcoord, -1, +1);
	color += Sample2DOffset(ps_source_sampler, input.texcoord, +1, +1);
	color = color / 4.0f;

	return color;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

