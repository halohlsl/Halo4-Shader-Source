#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cubemap_registers.fxh"

LOCAL_SAMPLERCUBE(source_a_sampler,	0);
LOCAL_SAMPLERCUBE(source_b_sampler,	1);

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

float4 default_ps_tex(const in s_vertex_output_screen_tex input) : SV_Target
{
	float2 sample0 = input.texcoord;
	
	float3 direction;
	direction= forward - (sample0.y*2-1)*up - (sample0.x*2-1)*left;
	direction= direction * (1.0 / sqrt(dot(direction, direction)));

	// flip for historical reasons
	direction.y=	-direction.y;

 	float4 a=	sampleCUBE(source_a_sampler, direction);
 	float4 b=	sampleCUBE(source_b_sampler, direction);
 
	float4 color=	max(a * scale_a, b * scale_b);
 	 	
 	color= ((isnan(color) || isinf(color)) ? 0.0f : color);		// if it's INF or NAN, replace with zero
 
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


