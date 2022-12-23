#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"


LOCAL_SAMPLER2D(ps_surface_sampler0, 0);
LOCAL_SAMPLER2D(ps_surface_sampler1, 1);

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
 


float4 default_ps(const in s_screen_vertex_output input, in SCREEN_POSITION_INPUT(unnormalizedTexCoord)) : SV_Target0
{
    float4 texel0, texel1;
   
#if defined(xenon) || (DX_VERSION == 11)
		
    if(frac(0.5f * unnormalizedTexCoord.x) == 0.0f)
    {
#ifdef xenon
        asm
        {
            tfetch2D texel0, unnormalizedTexCoord, ps_surface_sampler0, OffsetX =  0.0, OffsetY =  0.0, \
                UnnormalizedTextureCoords = true, MinFilter = point, MagFilter = point, MipFilter = point
            tfetch2D texel1, unnormalizedTexCoord, ps_surface_sampler0, OffsetX = +1.0, OffsetY =  0.0, \
                UnnormalizedTextureCoords = true, MinFilter = point, MagFilter = point, MipFilter = point
        };
#else
		texel0 = ps_surface_sampler0.t.Load(int3(unnormalizedTexCoord.xy, 0));
		texel1 = ps_surface_sampler0.t.Load(int3(unnormalizedTexCoord.xy, 0), int2(1, 0));
#endif
    }
    else
    {
#ifdef xenon
        asm
        {
            tfetch2D texel0, unnormalizedTexCoord, ps_surface_sampler1, OffsetX = -1.0, OffsetY =  0.0, \
                UnnormalizedTextureCoords = true, MinFilter = point, MagFilter = point, MipFilter = point
            tfetch2D texel1, unnormalizedTexCoord, ps_surface_sampler1, OffsetX =  0.0, OffsetY =  0.0, \
                UnnormalizedTextureCoords = true, MinFilter = point, MagFilter = point, MipFilter = point
        };
#else
		texel0 = ps_surface_sampler1.t.Load(int3(unnormalizedTexCoord.xy, 0), int2(-1, 0));
		texel1 = ps_surface_sampler1.t.Load(int3(unnormalizedTexCoord.xy, 0));
#endif
    }
    
	return float4(texel0.rg, texel1.rg);
#else
    return float4(1.0, 0.0, 0.0, 0.0);
	
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

