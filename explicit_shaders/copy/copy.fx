#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(source_sampler, 0);

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
 	return sample2D(source_sampler, input.texcoord.xy * ps_scale.xy);
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}



struct s_vertex_output_screen
{
    float4 position:		SV_Position;
};

s_vertex_output_screen default_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	return output;
}

BEGIN_TECHNIQUE albedo
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		// no pixel shader
	}
}
