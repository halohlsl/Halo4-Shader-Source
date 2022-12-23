#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(source_sampler, 0);
LOCAL_SAMPLER2D(add_sampler, 1);
LOCAL_SAMPLER2D(add_2_sampler, 2);

struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen_tex default_vs_tex(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

float4 default_ps_tex(const in s_vertex_output_screen_tex input) : SV_Target
{
	float4 source = sample2D(source_sampler, input.texcoord);
	float4 add = sample2D(add_sampler, input.texcoord);

	float4 color;
	color.rgb = (ps_scale.rgb * source.rgb * add.a) + add.rgb;
	color.a = add.a;

	return color;
}

float4 add_three_ps(const in s_vertex_output_screen_tex input) : SV_Target
{
	float4 add_2 = sample2D(add_2_sampler, input.texcoord);

	float4 color = default_ps_tex(input);
	color.rgb += ps_scale.a * add_2.rgb;

	return color;
}



BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}

BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(add_three_ps());
	}
}

