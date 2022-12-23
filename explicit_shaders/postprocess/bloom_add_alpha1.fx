#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(ps_original_sampler, 0);
LOCAL_SAMPLER2D(ps_add_sampler, 1);

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
	float4 original= sample2D(ps_original_sampler, input.texcoord);
	float4 add= sample2D(ps_add_sampler, input.texcoord);

	float4 color;
	color = float4(ps_scale.rgb, GetGammaColorIntensity(ps_scale.rgb)) * original.rgba + add.rgba;

	return color;
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}


