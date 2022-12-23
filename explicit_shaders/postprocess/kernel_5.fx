#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "kernel_5_registers.fxh"


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


float4 convolve_5_ps(const in s_screen_vertex_output input)
{
	float4 color =  ps_kernel[0].z * sample2D(ps_source_sampler, input.texcoord + ps_kernel[0].xy * ps_pixel_size.xy) +
					ps_kernel[1].z * sample2D(ps_source_sampler, input.texcoord + ps_kernel[1].xy * ps_pixel_size.xy) +
					ps_kernel[2].z * sample2D(ps_source_sampler, input.texcoord + ps_kernel[2].xy * ps_pixel_size.xy) +
					ps_kernel[3].z * sample2D(ps_source_sampler, input.texcoord + ps_kernel[3].xy * ps_pixel_size.xy) +
					ps_kernel[4].z * sample2D(ps_source_sampler, input.texcoord + ps_kernel[4].xy * ps_pixel_size.xy);

	return color * ps_scale;
}

float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	return convolve_5_ps(input);
}

float4 default_add_ps(const in s_screen_vertex_output input) : SV_Target
{
	return convolve_5_ps(input) + sample2D(ps_source_add_sampler, input.texcoord);
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_add_ps());
	}
}

