#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "fx/ordnance_map_core.fxh"
#include "fx/esoteric/vision_mode_biped.fxh"
#include "ordnance_map_biped_registers.fxh"


DECLARE_SAMPLER(alpha_map, "Biped Texture", "Biped Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(indicator_size_x, "Indicator Size X", "", 0, 50, float(1.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(indicator_size_y, "Indicator Size Y", "", 0, 50, float(1.0));
#include "used_vertex_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(under_cover_multiplier, "Under Cover Color Multiplier", "", 0, 1, float(0.35));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(friend_color, "Friend Color", "", float3(0,1,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(neutral_color, "Neutral Color", "", float3(1,1,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(enemy_color, "Enemy Color", "", float3(1,0,0));
#include "used_float3.fxh"

struct s_vertex_output_screen
{
    float4 position: SV_Position;
    float3 texcoord_depth: TEXCOORD0;
    float2 mapCoord: TEXCOORD1;
};

s_vertex_output_screen default_vs(const in s_screen_vertex input)
{
    float2 quadPosition = input.position.xy * float2(indicator_size_x, indicator_size_y);

    s_vertex_output_screen output;
    float2 position = vsBipedPosition.xy;
    float2 forward = normalize(vsBipedFacing.xy);
    float2 right = normalize(cross(float3(forward, 0), float3(0, 0, 1)).xy);
    position += (forward * (-quadPosition.y) + right * quadPosition.x);
    position -= vsVisibleScreenBounds.xy;
    position /= vsVisibleScreenBounds.zw;
    
    output.mapCoord = (position * vsVisibleScreenBounds.zw + vsVisibleScreenBounds.xy - vsWholeMapBounds.xy) / vsWholeMapBounds.zw;
    output.mapCoord.y = 1.0 - output.mapCoord.y;
			
    position = -1.0 + position * 2.0;
    output.position = float4(position.xy, 0.0, 1.0);
    
    float depth = (vsBipedPosition.z - vsZBounds.x) / vsZBounds.y;
    
    output.texcoord_depth = float3(input.texcoord, depth);
    return output;
}

float4 default_ps(
	const in s_vertex_output_screen input,
	SCREEN_POSITION_INPUT(fragment_position)) : SV_Target
{
	float2 texcoord = input.texcoord_depth.xy;
	float depth = input.texcoord_depth.z;
	float alpha = sample2D(alpha_map, texcoord).r;
	
	float mapDepth = sample2D(psMapSampler, input.mapCoord).b;
	
	float3 color;
	if (psIsFriend)
	{
		color = friend_color;
	}
	else if (psIsEnemy)
	{
		color = enemy_color;
	}
	else
	{
		color = neutral_color;
	}
	
 	return float4(color * (mapDepth <= depth ? 1.0 : under_cover_multiplier), alpha);
}

BEGIN_TECHNIQUE _default <bool no_physics_material = true;>
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}