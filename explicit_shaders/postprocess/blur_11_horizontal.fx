#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"


LOCAL_SAMPLER2D(source_sampler, 0);

struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float2 texcoordCenter:	TEXCOORD0;
	float4 texcoordInner:	TEXCOORD1;
	float4 texcoordOuter:	TEXCOORD2;
};

s_vertex_output_screen_tex default_vs_tex(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 0.0, 1.0);

	const float offset[4] =
	{
		-4.0 - 1.0	/	(1.0+9.0),			// -4.1
		-2.0 - 36.0	/	(36.0+84.0),		// -2.3
		+2.0 - 84.0	/	(84.0+36.0),		//  1.3
		+4.0 - 9.0	/	(1.0+9.0),			//  3.1
	};

	output.texcoordCenter = input.texcoord;
	output.texcoordInner.xy = input.texcoord + vs_texture_size.zw * float2(offset[1].x, 0.0f);
	output.texcoordInner.zw = input.texcoord + vs_texture_size.zw * float2(offset[2].x, 0.0f);
	output.texcoordOuter.xy = input.texcoord + vs_texture_size.zw * float2(offset[0].x, 0.0f);
	output.texcoordOuter.zw = input.texcoord + vs_texture_size.zw * float2(offset[3].x, 0.0f);

	return output;
}

float4 tex2DOffsetLinear(texture_sampler_2d map, float2 texcoord, float offX, float offY)
{
#if defined(xenon)
    float4 result;
    asm
	{
        tfetch2D result, texcoord, map, OffsetX = offX, OffsetY = offY, UseComputedLOD = false, MinFilter = linear, MagFilter = linear, MipFilter = linear
    };
    return result;
#else
    return sample2D(map, texcoord + ps_pixel_size * float2(offX, offY));
#endif
}

[reduceTempRegUsage(5)]
float4 default_ps_tex(const in s_vertex_output_screen_tex input) : SV_Target
{
	// solution using bilinear filtering:
	// actually this is a 10 wide blur - you get the 11th pixel by offsetting the vertical blur by half a pixel
	//
	// horizontal pass has the effect of shifting the center half a pixel to the left and down
	// vertical pass shifts it half a pixel up and right
	// result is an 11x11 gaussian blur that is perfectly centered
	//
	//   C = center pixel
	//   x = horizontal sample positions
	//   y = vertical sample positions
	//
	//
	//                      .---.---.
	//                      |   |   |
	//                      |---y---|
	//                      |   |   |
	//                      |---|---|
	//                      |   |   |
	//                      |---y---|
	//                      |   |   |
	//                      |---|---|
	//                      |   |   |
	//  .---.---.---.---.---|---y---|---.---.---. . .
	//  |   |   |   |   |   | C |   |   |   |   |   .
	//  '---|x--|---|x--|---x---|--x|---|--x|---| . .
	//  |   |   |   |   |   |   |   |   |   |   |   .
	//  '---'---'---'---'---'---y---'---'---'---' . .
	//                      |   |   |
	//                      |---|---|
	//                      |   |   |
	//                      |---y---|
	//                      |   |   |
	//                      '---'---'
	//						`   `   `
	//                      ' - ' - '
	//
	//
	// hard-coded kernel
	//
	//		[1  9]  [36  84]  [126  126]  [84  36]  [9  1]			/ 512
	//
	// Note:  with the half-pixel offset in the other direction, this kernel becomes:
	//
	//		1  10  45  120  210  252  210  120  45  10  1			/ 1024

	float4 color =	(1.0   + 9.0) / 512.0	* tex2DOffsetLinear(source_sampler, input.texcoordOuter.xy, -0.5, 0.5) +
					(1.0   + 9.0) / 512.0	* tex2DOffsetLinear(source_sampler, input.texcoordOuter.zw, -0.5, 0.5) +
					(36.0  + 84.0) / 512.0	* tex2DOffsetLinear(source_sampler, input.texcoordInner.zw, -0.5, 0.5) +
					(36.0  + 84.0) / 512.0	* tex2DOffsetLinear(source_sampler, input.texcoordInner.xy, -0.5, 0.5) +
					(126.0 + 126.0) / 512.0	* tex2DOffsetLinear(source_sampler, input.texcoordCenter, -0.5, 0.5);

	return color;
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}

