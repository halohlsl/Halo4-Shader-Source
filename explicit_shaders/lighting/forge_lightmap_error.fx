#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(ps_surface_sampler,	0);



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
#if defined(xenon) || (DX_VERSION == 11)
	float2 texcoord2Left = 	float2(input.texcoord.x / 2, input.texcoord.y);
	float2 texcoord2Right = float2(input.texcoord.x / 2 + 0.5, input.texcoord.y);
	float3 texcoord3Left = 	float3(texcoord2Left, 0.0);
	float3 texcoord3Right = float3(texcoord2Right, 0.0);
	
	float4 uncompressedTexLeft = sample2D(ps_surface_sampler, texcoord2Left);
	float4 uncompressedTexRight = sample2D(ps_surface_sampler, texcoord2Right);
		
	float4 compressedTexLeft, compressedTexRight;
#ifdef xenon
	asm{ tfetch3D compressedTexLeft.xyzw, texcoord3Left, ps_bsp_lightprobe_hdr_color, OffsetZ= 0.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
	asm{ tfetch3D compressedTexRight.xyzw, texcoord3Right, ps_bsp_lightprobe_hdr_color, OffsetZ= 0.5,VolMinFilter=point,VolMagFilter=point,MipFilter=point,MinFilter=linear,MagFilter=linear };
#else
	compressedTexLeft = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, texcoord3Left);
	compressedTexRight = ps_bsp_lightprobe_hdr_color.t.Sample(ps_bsp_lightprobe_hdr_color.s, texcoord3Right);
#endif

	return float4(0.0, (uncompressedTexLeft.w - compressedTexLeft.w) * 0.5 + 0.5, 0.0, (uncompressedTexRight.w - compressedTexRight.w) * 0.5 + 0.5);
#endif

	return sample2D(ps_surface_sampler, input.texcoord);
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

