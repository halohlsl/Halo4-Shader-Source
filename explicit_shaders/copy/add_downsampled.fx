#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(downsampled_sampler, 0);
LOCAL_SAMPLER2D(original_sampler, 1);

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


float3 get_pixel_bilinear(float2 texcoord)
{
	texcoord= (texcoord / ps_pixel_size) - 0.5;
	float2 texel0= floor(texcoord);

	float4 blend;
	blend.xy= texcoord - texel0;
	blend.zw= 1.0 - blend.xy;
	
	blend.xyzw= blend.zxzx * blend.wwyy;

	texel0= (texel0 + 0.5) * ps_pixel_size;

	float2 texel1= texel0;
	texel1.x += ps_pixel_size.x;

	float2 texel2= texel0;
	texel2.y += ps_pixel_size.y;

	float2 texel3= texel2;
	texel3.x = texel1.x;

	float3 color =	blend.x * sample2D(downsampled_sampler, texel0).rgb +
					blend.y * sample2D(downsampled_sampler, texel1).rgb +
					blend.z * sample2D(downsampled_sampler, texel2).rgb +
					blend.w * sample2D(downsampled_sampler, texel3).rgb;

	return color;
}

[reduceTempRegUsage(5)]
float4 default_ps_tex(const in s_vertex_output_screen_tex input) : SV_Target
{
	float3 color = sample2D(original_sampler, input.texcoord).rgb;
	color += ps_scale * get_pixel_bilinear(input.texcoord);

	return float4(color, 1.0f);
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}



