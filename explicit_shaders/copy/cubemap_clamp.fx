#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cubemap_registers.fxh"


LOCAL_SAMPLERCUBE(source_sampler,	0);



struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen_tex default_vs_tex(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 1.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

float4 sample_cube_map(float3 direction)
{
	direction.y= -direction.y;
	return sampleCUBE(source_sampler, direction);
}

float4 default_ps_tex(const in s_vertex_output_screen_tex input) : SV_Target
{
	float2 sample0 = input.texcoord;

	float3 direction;
	direction= forward - (sample0.y*2-1)*up - (sample0.x*2-1)*left;
	direction= direction * (1.0 / sqrt(dot(direction, direction)));

 	float4 color= sample_cube_map(direction);

	color.rgb= ((isnan(color.rgb) || any(color.rgb < 0)) ? 0.0f : isinf(color.rgb) ? scale.rgb : min(color.rgb, scale.rgb));		// if it's NAN, replace with zero, if it's INF, replace with max, otherwise, clamp
 	
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

