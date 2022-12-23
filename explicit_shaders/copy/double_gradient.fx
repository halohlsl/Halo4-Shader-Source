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

[reduceTempRegUsage(4)]
float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
#if !defined(xenon)
 	float4 color = sample2D(ps_source_sampler, input.texcoord);
#else // !defined(xenon)
	float4 color_o, color_px, color_nx, color_py, color_ny;
	float2 texcoord = input.texcoord;
	asm
	{
		tfetch2D color_o, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= 0
		tfetch2D color_px, texcoord, ps_source_sampler, OffsetX= 1, OffsetY= 0
		tfetch2D color_py, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= 1
		tfetch2D color_nx, texcoord, ps_source_sampler, OffsetX= -1, OffsetY= 0
		tfetch2D color_ny, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= -1
	};
	float4 laplacian_x = (color_px + color_nx - 2 * color_o);
	float4 laplacian_y = (color_py + color_ny - 2 * color_o);
	
	float4 gradient_magnitude = sqrt(laplacian_x * laplacian_x + laplacian_y * laplacian_y);
	float4 color = gradient_magnitude;
#endif
	return float4(saturate(color.rgb) * ps_scale.rgb, ps_scale.a);
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



