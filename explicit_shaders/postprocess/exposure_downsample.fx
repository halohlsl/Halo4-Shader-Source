
#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"

LOCAL_SAMPLER2D(ps_source_sampler,			0);
LOCAL_SAMPLER2D(ps_weight_sampler,			1);

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
	float3 average= 0.0f;		// weighted_sum(log(intensity)), log(weighted_sum(intensity)), total_weight

	// [mboulton 12/9/2010] The source_sampler texture is now 24 x 16, but the intensity texture is still 18 x 10 (16 x 8 with a single texel of black border)
	for (int x= -11; x <= 11; x += 2)
	{
		[unroll]
		for (int y= -7; y <= 7; y += 2)
		{
			float2 texcoordOffset = float2(x / 24.0f, y / 16.0f);

			float weight = sample2D(ps_weight_sampler, input.texcoord + texcoordOffset).g;
			float intensity = GetLinearColorIntensity(sample2D(ps_source_sampler, input.texcoord + texcoordOffset));
			average.xyz += weight * float3(log2( 0.00001f + intensity ), intensity, 1.0f);
		}
	}

	average.xy /= average.z;
	average.y= log2( 0.00001f + average.y );

	return (average.y * ps_scale.x + average.x * (1.0f - ps_scale.x));
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

