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
#if !defined(xenon)
 	float4 color = sample2D(ps_source_sampler, input.texcoord);
#else // !defined(xenon)
	float4 color_o, color_x, color_y;
	float2 texcoord = input.texcoord;
	asm
	{
		tfetch2D color_o, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= 0
		tfetch2D color_x, texcoord, ps_source_sampler, OffsetX= 1, OffsetY= 0
		tfetch2D color_y, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= 1
	};
	float4 gradient_x = (color_x - color_o);
	float4 gradient_y = (color_y - color_o);
	
	float4 gradient_magnitude = sqrt(gradient_x * gradient_x + gradient_y * gradient_y);
	float4 color = gradient_magnitude;
#endif // !defined(xenon)
	return color * ps_scale;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



