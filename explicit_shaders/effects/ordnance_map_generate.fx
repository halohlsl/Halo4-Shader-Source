#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "fx/vision_mode_core_registers.fxh"


LOCAL_SAMPLER2D(psNormalSampler, 0);
LOCAL_SAMPLER2D(psDepthSampler, 1);

struct s_vertex_output_screen
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen default_vs(const in s_screen_vertex input)
{
	s_vertex_output_screen output;
	output.position = float4(input.position.xy, 0.0, 1.0);
	output.texcoord = input.texcoord;
	return output;
}

float4 default_ps(const in s_vertex_output_screen input) : SV_Target
{
	float3 normal = normalize(sample2D(psNormalSampler, input.texcoord.xy * ps_scale.xy).rgb);
	
	float depth = sample2D(psDepthSampler, input.texcoord.xy * ps_scale.xy).r;
		
 	return float4(normal.x, normal.y, depth, 1.0f);
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
