#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(source_sampler, 0);

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
    float4 color:			TEXCOORD1;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	output.color=		input.color;
	return output;
}

float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
  	float4 color= sample2D(source_sampler, input.texcoord);
 	color*= input.color;
 	return color*ps_scale;
}

// to be able copy D32_FLOAT surface into R8G8B8A8 surface
float4 depth_to_rgba_pack_ps(const in s_screen_vertex_output input) : SV_Target
{
	// I expect to sample here the viewport space hyperbolic depth
	// then expect a value in the [0..1) range
	float depth = sample2D(source_sampler, input.texcoord).r;

	float4 encoded = float4(1.f, 255.f, 65025.f, 16581375.f) * depth;

	encoded = frac(encoded);

	encoded -= encoded.yzww * float4(1.f / 255.f, 1.f / 255.f, 1.f / 255.f, 0.f);

	return encoded;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE depth_to_rgba_pack
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(depth_to_rgba_pack_ps());
	}
}