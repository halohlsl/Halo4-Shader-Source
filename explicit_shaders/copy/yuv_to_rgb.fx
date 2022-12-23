#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "yuv_to_rgb_registers.fxh"


struct s_bink_vertex_output
{
    float4 position:		SV_Position;
    float4 texcoord:		TEXCOORD0;
};

s_bink_vertex_output default_vs(const in s_bink_vertex input)
{
	s_bink_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}

[reduceTempRegUsage(2)]
float4 default_ps(const in s_bink_vertex_output input) : SV_Target
{
#if DX_VERSION==9

	//Bink1 Xenon XDK implementation
	float4 c;                   
	float4 p;                   
	c.x = sample2D( tex0, input.texcoord ).x;
	c.y = sample2D( tex1, input.texcoord ).x;
	c.z = sample2D( tex2, input.texcoord ).x;
	c.w = consts.x;
	p.w = sample2D( tex3, input.texcoord ).x;
	p.x = dot( tor, c );
	p.y = dot( tog, c );
	p.z = dot( tob, c );
	p.w*= consts.w;
	return p;

#elif DX_VERSION==11

	//Bink2 March XDK implementation
	float4 p;
	float y =	sample2D( tex0, input.texcoord.xy ).x;
	float cr =	sample2D( tex1, input.texcoord.zw ).x;
	float cb =	sample2D( tex2, input.texcoord.zw ).x;

	p = y * yscale;
	p += (crc * cr) + (cbc * cb) + adj;
	p.w = 1.0f;

	if(consta.z>0)
	{
		float a =	sample2D( tex3, input.texcoord ).x;
		p.w = a;
	}

	p *= consta.xyyw;	
	return p;
#endif
}



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


