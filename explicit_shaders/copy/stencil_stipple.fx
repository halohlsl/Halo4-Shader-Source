#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "stencil_stipple_registers.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.5, 0.5);
	return output;
}

#ifdef durango

uint4 default_ps(SCREEN_POSITION_INPUT(position)) : SV_Target0
{
	uint2 ipos = uint2(position.xy);

	uint result = 0;
	result |= (ipos.y & 2) >> 1;
	result |= ((ipos.x ^ ipos.y) & 2);
	result |= (ipos.y & 1) << 2;
	result |= ((ipos.x ^ ipos.y) & 1) << 3;

	return result;
}

#else

float4 default_ps(SCREEN_POSITION_INPUT(position)) : SV_Target0
{
    // calculate which block we are in, modulo 2
    float2 block_position= floor(fmod(position / ps_block_size, 2.0f));
    float bit;

    if (ps_odd_bits)
    {
		// odd bits are (X xor Y)
		bit = abs(block_position.x - block_position.y);
	}
	else
	{
		// even bits are just the Y block position
		bit = block_position.y;
	}

    // clip pixel if bit is less than 0.5
    clip(bit - 0.5f);

    return 0;
}

#endif

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}



