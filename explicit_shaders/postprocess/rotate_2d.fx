#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "rotate_2d_registers.fxh"


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
	float2 rotated_texcoord;
	rotated_texcoord.x = dot(ps_scale.xy, input.texcoord.xy) + ps_offset.x;
	rotated_texcoord.y = dot(ps_scale.zw, input.texcoord.xy) + ps_offset.y;

	float4 source =		sample2D(ps_source_sampler,			rotated_texcoord);
	float4 background;
#ifdef pc
	background=	sample2D(ps_background_sampler, input.texcoord);
#else
	background= Sample2DOffsetPoint(ps_background_sampler, input.texcoord, 0.0f, 0.0f);
#endif

	return background + source;
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


