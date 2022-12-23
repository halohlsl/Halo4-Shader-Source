#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(ps_source_sampler,		0);
#ifdef xenon
LOCAL_SAMPLER2D(ps_stencil_sampler,		1);
#elif DX_VERSION == 11
texture2D<uint2> ps_stencil_texture : register(t1);
#endif


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
#if (!defined(xenon)) && (DX_VERSION != 11)
	float4 result= sample2D(ps_source_sampler, input.texcoord);
#else
   float4 line0_x, line0_y, line0_z;
   float4 line1_x, line1_y, line1_z;
   float4 line2_x, line2_y;
   float2 texcoord= input.texcoord;
#ifdef xenon
   asm
   {
	   tfetch2D line0_x, texcoord, ps_source_sampler, OffsetX= -1, OffsetY= -1
	   tfetch2D line0_y, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= -1
	   tfetch2D line0_z, texcoord, ps_source_sampler, OffsetX= 1, OffsetY= -1
	   tfetch2D line1_x, texcoord, ps_source_sampler, OffsetX= -1, OffsetY= 0
	   tfetch2D line1_y, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= 0
	   tfetch2D line1_z, texcoord, ps_source_sampler, OffsetX= 1, OffsetY= 0
	   tfetch2D line2_x, texcoord, ps_source_sampler, OffsetX= -1, OffsetY= 1
	   tfetch2D line2_y, texcoord, ps_source_sampler, OffsetX= 0, OffsetY= 1
   };
#elif DX_VERSION == 11
	line0_x = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(-1, -1));
	line0_y = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(0, -1));
	line0_z = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(1, -1));
	line1_x = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(-1, 0));
	line1_y = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(0, 0));
	line1_z = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(1, 0));
	line2_x = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(-1, 1));
	line2_y = ps_source_sampler.t.Sample(ps_source_sampler.s, texcoord, int2(0, 1));
#endif
   float3 line0= float3(line0_x.x, line0_y.x, line0_z.x);
   float3 line1= float3(line1_x.x, line1_y.x, line1_z.x);
   float2 line2= float2(line2_x.x, line2_y.x);

   float4 gradients_x;
   gradients_x.xy= (line0.yz - line0.xy);
   gradients_x.zw= (line1.yz - line1.xy);
   gradients_x *= gradients_x;

   float4 gradients_y;
   gradients_y.xy= line1.xy - line0.xy;
   gradients_y.zw= line2.xy - line1.xy;
   gradients_y *= gradients_y;

   float4 gradient_magnitudes= saturate(sqrt(gradients_x + gradients_y));

   float average_magnitude= dot(gradient_magnitudes, float4(1.0f, 1.0f, 1.0f, 1.0f));

   float4 result= 0.0f;
   result.r= average_magnitude;
   
#ifdef xenon
	float stencil = sample2D(ps_stencil_sampler, texcoord).b;
#elif DX_VERSION == 11
	float2 stencil_dim;
	ps_stencil_texture.GetDimensions(stencil_dim.x, stencil_dim.y);
	
#ifdef durango
	// G8 SRVs are broken on Durango - components are swapped
	uint raw_stencil = ps_stencil_texture.Load(int3(texcoord * stencil_dim, 0)).r;
#else
	uint raw_stencil = ps_stencil_texture.Load(int3(texcoord * stencil_dim, 0)).g;
#endif
	float stencil =  raw_stencil / 255.0f;
#endif   
   
   result.g= step(64.0f / 255.0f, stencil);
#endif
   return ps_scale * result;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}




