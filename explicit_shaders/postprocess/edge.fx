#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"

LOCAL_SAMPLER2D(Tex0, 0);

struct Interp 
{
    float4 position: SV_Position;
    float2 texcoord: TEXCOORD0;
};

Interp VS(const in s_screen_vertex input)
{
	Interp output;
	output.position = float4(input.position.xy, 1.0, 1.0);
	output.texcoord = 0;

#if defined(xenon)
	output.texcoord.xy = input.texcoord * vs_texture_size.xy + float2(0.25, 0.25); 
#endif

	return output;
}

float4 PS(Interp input) : SV_Target0
{
	float4 output = 1;

#if defined(xenon)

	float2 uv = input.texcoord;
	float4 ce, y0, y1, x0, x1;
    float e = 0.00001;

	// depth
	asm
	{
		tfetch2D ce, uv, Tex0, UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, OffsetX= 0, OffsetY= 0
		tfetch2D y0, uv, Tex0, UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, OffsetX= 0, OffsetY=-1
		tfetch2D y1, uv, Tex0, UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, OffsetX= 0, OffsetY= 1
		tfetch2D x0, uv, Tex0, UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, OffsetX=-1, OffsetY= 0
		tfetch2D x1, uv, Tex0, UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, OffsetX= 1, OffsetY= 0
	};

	// 3x3 thesholded laplacian
    float edge = abs(4*ce.x - y0.x - y1.x - x0.x - x1.x) > e ? 1 : -1;

	// clip
	clip(edge);

#endif	// !defined(xenon) 

	return output;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(VS());
		SET_PIXEL_SHADER(PS());
	}
}

