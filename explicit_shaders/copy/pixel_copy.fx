#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(ps_source_sampler, 0);

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
#if !defined(xenon)
 	return sample2D(ps_source_sampler, input.texcoord * ps_scale.xy);
#else // !defined(xenon)
	float2 texcoord = input.texcoord * ps_scale.xy;
	
	float4 result;
	asm
	{
		tfetch2D result, texcoord, ps_source_sampler, UnnormalizedTextureCoords=false, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
	};
	return result;
#endif // !defined(xenon)
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}

