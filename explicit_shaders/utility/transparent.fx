#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "exposure.fxh"

LOCAL_SAMPLER2D(source_sampler, 0);

struct s_vertex_output_transparent
{
	float4 position:	SV_Position;
	float2 texcoord:	TEXCOORD0;
	float4 color:		COLOR0;
};

s_vertex_output_transparent default_vs_tex(s_transparent_vertex input)
{
	s_vertex_output_transparent output;
    output.position = mul(float4(input.position, 1.0f), vs_view_view_projection_matrix);
	output.color = input.color;
	output.texcoord = input.texcoord;

    return output;
}


float4 default_ps_tex(const in s_vertex_output_transparent input) : SV_Target
{
	return apply_exposure(input.color * sample2D(source_sampler, input.texcoord));
}


BEGIN_TECHNIQUE _default
{
	pass transparent
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}
