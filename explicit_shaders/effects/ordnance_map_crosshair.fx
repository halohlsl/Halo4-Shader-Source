#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "fx/ordnance_map_core.fxh"
#include "ordnance_map_crosshair_registers.fxh"


DECLARE_SAMPLER(alpha_map, "Crosshair Texture", "Crosshair Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(indicator_size_x, "Crosshair Size X", "", 0, 50, float(1.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(indicator_size_y, "Crosshair Size Y", "", 0, 50, float(1.0));
#include "used_vertex_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(crosshair_color, "Crosshair Color", "", float3(1.0, 1.0, 1.0));

struct s_vertex_output_screen
{
    float4 position: SV_Position;
    float2 texcoord: TEXCOORD0;
};

s_vertex_output_screen default_vs(const in s_screen_vertex input)
{
    float2 quadPosition = input.position.xy * float2(indicator_size_x, indicator_size_y);

    s_vertex_output_screen output;
    float2 position = vsCrosshairPosition.xy;
    position += quadPosition;
    position -= vsVisibleScreenBounds.xy;
    position /= vsVisibleScreenBounds.zw;
		
		// fit it on -1 to 1
    position = -1.0 + position * 2.0;
    
    output.position = float4(position.xy, 0.0, 1.0);    
    output.texcoord = input.texcoord;
    return output;
}

float4 default_ps(
	const in s_vertex_output_screen input,
	SCREEN_POSITION_INPUT(fragment_position)) : SV_Target
{
	float2 texcoord = input.texcoord.xy;
	float alpha = sample2D(alpha_map, texcoord).r;
	
 	return float4(crosshair_color, alpha);
}

BEGIN_TECHNIQUE _default <bool no_physics_material = true;>
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}