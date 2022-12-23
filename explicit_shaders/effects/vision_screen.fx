#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "fx/vision_mode_core.fxh"
#include "exposure.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(edge_fog_color, "Edge Fog Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edge_fog_falloff_begin, "Edge Fog Falloff Begin", "", 0, 10, .9);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edge_fog_falloff_end, "Edge Fog Falloff End", "", 0, 10, 1.25);
#include "used_float.fxh"

struct s_screen_vertex_output
{
	float4 position:                            SV_Position;
	float2 texcoord:                            TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position = float4(input.position.xy, 1.0, 1.0);
#if defined(pc) && (DX_VERSION == 9)
	output.texcoord = input.texcoord;
#else
	output.texcoord = input.texcoord * vs_texture_size.xy + vs_texture_size.zw;
#endif
	return output;
}

float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
	float2 pixel_coordinates = input.texcoord;
	
	float plasmaValue;
	float plasmaEdgeValue;
	
	ApplyPlasmaWarping(pixel_coordinates, plasmaValue, plasmaEdgeValue);
		
	// get color and depth at this screen coord
	// remember that depth isn't linear if that is important to you
	float3 color0;
	float depth;
	sampleFramebuffer(pixel_coordinates, color0, depth);
	
	// calculate edge fog value
	float2 normalizedScreenCoord = -1.0 + 2.0 * ps_pixel_size.xy * pixel_coordinates;
	float falloff = saturate((length(normalizedScreenCoord) - edge_fog_falloff_begin) / (edge_fog_falloff_end - edge_fog_falloff_begin));
	
	float3 outColor = lerp(color0, edge_fog_color, falloff);
	
#if DX_VERSION == 11	
	outColor = max(outColor, 0);
#endif
	
	return float4(outColor,1);
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

