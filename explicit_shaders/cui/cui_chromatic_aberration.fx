#include "core/core.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cui_functions.fxh"

#include "cui_transform.fxh"		// adds the default vertex shader

#define k_baseOpacity k_cui_pixel_shader_scalar0
#define k_redChannelInfo k_cui_pixel_shader_color0
#define k_greenChannelInfo k_cui_pixel_shader_color1
#define k_blueChannelInfo k_cui_pixel_shader_color2

float4 default_ps(s_screen_vertex_output input) : SV_Target
{
	float2 texcoord = input.texcoord;
	float4 color = cui_tex2D(texcoord);
	color.rgb *= k_baseOpacity;
	color.a = 1.0f - ((1.0f - color.a) * k_baseOpacity);

#if (! defined(pc)) || (DX_VERSION == 11)

#ifdef xenon
	float4 gradients;
	asm {
		getGradients gradients, texcoord, source_sampler0
	};
#else
	float4 gradients = GetGradients(texcoord);
#endif

	float4 redSample = cui_tex2D(
		texcoord +
		(gradients.xy * k_redChannelInfo.x) +
		(gradients.zw * k_redChannelInfo.y));

	float4 greenSample = cui_tex2D(
		texcoord +
		(gradients.xy * k_greenChannelInfo.x) +
		(gradients.zw * k_greenChannelInfo.y));

	float4 blueSample = cui_tex2D(
		texcoord +
		(gradients.xy * k_blueChannelInfo.x) +
		(gradients.zw * k_blueChannelInfo.y));

	redSample.rgb *= float3(k_redChannelInfo.z, 0.0f, 0.0f);
	redSample.a = 1.0f - ((1.0f - redSample.a) * k_redChannelInfo.z);

	greenSample.rgb *= float3(0.0f, k_greenChannelInfo.z, 0.0f);
	greenSample.a = 1.0f - ((1.0f - greenSample.a) * k_greenChannelInfo.z);

	blueSample.rgb *= float3(0.0f, 0.0f, k_blueChannelInfo.z);
	blueSample.a = 1.0f - ((1.0f - blueSample.a) * k_blueChannelInfo.z);

	color.rgb = max(max(max(color.rgb, redSample.rgb), greenSample.rgb), blueSample.rgb);
	color.a = min(min(min(color.a, redSample.a), greenSample.a), blueSample.a);
#endif

	color = cui_tint(color, cui_linear_to_gamma2(k_cui_pixel_shader_tint*input.color));
	return color * ps_scale;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE curved_cui
{
	pass screen
	{
		SET_VERTEX_SHADER(curved_cui_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
