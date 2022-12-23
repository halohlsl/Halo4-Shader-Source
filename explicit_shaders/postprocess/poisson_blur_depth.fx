#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"

#include "poisson_blur_common.fxh"

LOCAL_SAMPLER2D(source_sampler, 0);
LOCAL_SAMPLER2D(depth_sampler, 1);


struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen_tex default_vs_tex(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, dofDistanceVS.y, 1.0);		// draw at the 'far' plane
	output.texcoord=	input.texcoord;
	return output;
}


[reduceTempRegUsage(3)]
float4 PoissonBlurDepth(const in s_vertex_output_screen_tex input, uniform int numPoissonTaps) : SV_Target0
{
	float2 texcoord = input.texcoord;

	float4 color = sample2DLOD(source_sampler, texcoord, 0, false);
	float  depth;

#if defined(xenon)
	asm
	{
		tfetch2D depth.x___, depth_sampler, texcoord.xy, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled, UseComputedLOD=false
	};
#else
	depth = sample2DLOD(depth_sampler, texcoord, 0, false).r;
#endif

	float blurIntensity = saturate((depth - dofDistance.y) * dofDistance.z);

	return PoissonBlur(source_sampler, texcoord, blurIntensity, color, numPoissonTaps);
}


BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(PoissonBlurDepth(6));
	}
}

BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(PoissonBlurDepth(12));
	}
}

