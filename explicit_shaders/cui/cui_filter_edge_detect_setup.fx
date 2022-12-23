#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "cui_registers.fxh"

LOCAL_SAMPLER2D(psSourceSampler,	0);
#define psSamplerTransform k_cui_pixel_shader_color0

#define epsilonColor float4(1.0/256.0, 1.0/256.0, 1.0/256.0, 1.0/256.0)

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position = float4(input.position.xy, 0.0, 1.0);
	output.texcoord = input.texcoord;
	return output;
}

float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	return step(epsilonColor, 1.0 - sample2D(psSourceSampler, input.texcoord).a) * psSamplerTransform.x + psSamplerTransform.y;
}

BEGIN_TECHNIQUE
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
