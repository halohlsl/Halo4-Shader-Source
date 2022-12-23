#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "antialias_blur_combine_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float4 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 1.0, 1.0);
	output.texcoord.xy = transform_texcoord(input.texcoord, vs_texcoord_xform0);
	output.texcoord.zw = transform_texcoord(input.texcoord, vs_texcoord_xform1);
	return output;
}



#define tfetch(color, texcoord, sampler, offsetx, offsety)																																	\
		asm																																													\
		{																																													\
			tfetch2D	color,	texcoord,	sampler,	MagFilter= point, MinFilter= point, MipFilter= point, AnisoFilter= disabled, OffsetX=  offsetx, OffsetY=  offsety					\
		};																																													\
		color.rgb	*=	color.rgb;


float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	float2 texcoord0=	input.texcoord.xy;
	float2 texcoord1=	input.texcoord.zw;

#if !defined(xenon)
 	float4 color0= sample2D(ps_source_sampler0, texcoord0);	// centered sample
 	float4 color1= sample2D(ps_source_sampler1, texcoord1);	// offset sample

	// linearize values
	float4 linear0= float4(exp2(color0.rgb * 8.0f - 8.0f), color0.a);
	float4 linear1= float4(exp2(color1.rgb * 8.0f - 8.0f), color1.a);
	
#else

	float4	linear1;
	{	
//*		
		float4 temp;
		tfetch(linear1, texcoord1, ps_source_sampler1,  0.5f,  0.5f);
		tfetch(temp,	texcoord1, ps_source_sampler1, -0.5f,  0.5f);
			linear1.rgb	+=	temp.rgb;
			linear1.a	=	max(linear1.a, temp.a);
		tfetch(temp,	texcoord1, ps_source_sampler1, -0.5f, -0.5f);
			linear1.rgb	+=	temp.rgb;
			linear1.a	=	max(linear1.a, temp.a);
		tfetch(temp,	texcoord1, ps_source_sampler1,  0.5f, -0.5f);
			linear1.rgb	+=	temp.rgb;
			linear1.a	=	max(linear1.a, temp.a);
		linear1.rgb	*=	0.25f;
/*/
		linear1=		sample2D(source_sampler1, texcoord1);
		linear1 *= linear1;
//*/
	}

	float4	linear0;
	tfetch(linear0, texcoord0, ps_source_sampler0, 0.0f, 0.0f);
	
#endif


	// scale.xy is the centered/offset weights for a fully antialiased pixel (which we want when the pixel is expected to be relatively stationary)
	// scale.zw is the centered/offset weights for a non-antialiased pixel (which we want when the pixel is expected to be moving quickly)
	// we blend between the two based on our expected velocity
	
	float min_velocity=			max(linear0.a, linear1.a);
	float expected_velocity=	min_velocity;								// if we write estimated velocity into the alpha channel, we can use them here
	float2 weights=				lerp(ps_scale.xy, ps_scale.zw, expected_velocity);

	float3 linear_blend=		weights.x * linear0 + weights.y * linear1;			// ###ctchou $PERF might be able to optimize this by playing around with the log space..  maybe
	
	float3 final_blend=			sqrt(linear_blend);

 	return float4(final_blend, expected_velocity);

}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


