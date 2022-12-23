#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(position_age_sampler, 0);
LOCAL_SAMPLER2D(parameters_sampler, 1);


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
	float4	position_age=	0;
	float4	parameters=		0;
	float2	texcoord=		input.texcoord.xy;

#if defined(xenon)
	asm
	{
		tfetch2D	position_age,
					texcoord,
					position_age_sampler,
					MagFilter=		point,
					MinFilter=		point,
					MipFilter=		point,
					AnisoFilter=	disabled
		tfetch2D	parameters,
					texcoord,
					parameters_sampler,
					MagFilter=		point,
					MinFilter=		point,
					MipFilter=		point,
					AnisoFilter=	disabled
	};
#endif

	float			type=		parameters.z * 255.0f * (1.0f / 7.2736f);
	
	float3			color=	float3(
										sin((type + 0.00f) * 6.28) * 0.5f + 0.5f,
										sin((type + 0.33f) * 6.28) * 0.5f + 0.5f,
										sin((type + 0.66f) * 6.28) * 0.5f + 0.5f
								);

	color=			normalize(color);

	float			age=	sqrt(saturate(1.0f - abs(position_age.a)));
	
	float4 result=	float4(color * age, 1.0f);
		
	if (ps_scale.a <= 0.0f)
	{
		result=	float4(1.0f, 0.0f, 0.0f, 1.0f);
	}
		
 	return result;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

