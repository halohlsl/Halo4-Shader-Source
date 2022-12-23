#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"

#include "poisson_blur_common.fxh"

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


[reduceTempRegUsage(3)]
float4 PoissonBlurAlpha(const in s_vertex_output_screen_tex input, uniform int numPoissonTaps) : SV_Target0
{
	float2 texcoord = input.texcoord;
	float4 color = sample2DLOD(source_sampler, texcoord, 0, false);
	float blurIntensity = color.a;

	const float minThreshold = 1.0f / 256.0f;
	clip(blurIntensity - minThreshold);

	float4 blur = PoissonBlur(source_sampler, texcoord, blurIntensity, color, numPoissonTaps);

//	color.rgb = color_overlay(color, blur);
	color = lerp(color, blur, 0.5);

	return color;

}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(PoissonBlurAlpha(6));
	}
}

BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(PoissonBlurAlpha(12));
	}
}

