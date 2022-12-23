#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "deform.fxh"
#include "fx/vision_mode_core.fxh"
#include "fx/esoteric/vision_mode_biped.fxh"
#include "exposure.fxh"
#include "vision_obj_registers.fxh"

#define FALLOFF_MAX psFalloffMax_FalloffStart_Alpha.x
#define FALLOFF_START psFalloffMax_FalloffStart_Alpha.y
#define ALPHA_MULTIPLIER psFalloffMax_FalloffStart_Alpha.z

DECLARE_FLOAT(depth_fudge_factor, "", "", 0, 1);
#include "used_float.fxh"

DECLARE_FLOAT(edge_threshold, "", "", 0, 1);
#include "used_float.fxh"
DECLARE_FLOAT(edge_feather_range, "", "", 0, 1);
#include "used_float.fxh"

DECLARE_FLOAT(edge_alpha, "", "", 0, 1);
#include "used_float.fxh"
DECLARE_FLOAT(obscured_alpha, "", "", 0, 1);
#include "used_float.fxh"
DECLARE_FLOAT(visible_alpha, "", "", 0, 1);
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(friend_color_visible, "Friend Visible", "", float3(0,1,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(friend_color_obscured, "Friend Obscured", "", float3(0,.5,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(friend_color_edge, "Friend Edge", "", float3(0,1,0));
#include "used_float3.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(friend_vehicle_color_visible, "Friend Vehicle Visible", "", float3(0,1,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(friend_vehicle_color_obscured, "Friend Vehicle Obscured", "", float3(0,.5,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(friend_vehicle_color_edge, "Friend Vehicle Edge", "", float3(0,1,0));
#include "used_float3.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(enemy_color_visible, "Enemy Visible", "", float3(1,0,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(enemy_color_obscured, "Enemy Obscured", "", float3(.5,0,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(enemy_color_edge, "Enemy Edge", "", float3(1,0,0));
#include "used_float3.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(enemy_vehicle_color_visible, "Enemy Vehicle Visible", "", float3(1,0,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(enemy_vehicle_color_obscured, "Enemy Vehicle Obscured", "", float3(.5,0,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(enemy_vehicle_color_edge, "Enemy Vehicle Edge", "", float3(1,0,0));
#include "used_float3.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(neutral_color_visible, "Neutral Visible", "", float3(1,1,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(neutral_color_obscured, "Neutral Obscured", "", float3(.5,.5,0));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(neutral_color_edge, "Neutral Edge", "", float3(1,1,0));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(vision_wave_depth, "", "", 0, 100, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(vision_wave_width, "", "", 0, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(vision_wave_peak_intensity_multiplier, "", "", 0, 2, float(1.5));
#include "used_float.fxh"

void GetDepthStencil(in float2 vpos, out float depth, out float stencil, out float sceneDepth, out float depthLaplacian)
{
#if defined(xenon) || (DX_VERSION == 11)
	float4 stencilValue;
	float4 objectDepthValue, objectDepthValuePx, objectDepthValueNx, objectDepthValuePy, objectDepthValueNy;
	float4 sceneDepthValue;
	
#ifdef xenon	
	asm {
		tfetch2D stencilValue, vpos, stencilSampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
		tfetch2D objectDepthValue, vpos, objectDepthSampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
		tfetch2D objectDepthValuePx, vpos, objectDepthSampler, UnnormalizedTextureCoords = true, OffsetX= 1, OffsetY= 0, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
		tfetch2D objectDepthValueNx, vpos, objectDepthSampler, UnnormalizedTextureCoords = true, OffsetX= -1, OffsetY= 0, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
		tfetch2D objectDepthValuePy, vpos, objectDepthSampler, UnnormalizedTextureCoords = true, OffsetX= 0, OffsetY= 1, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
		tfetch2D objectDepthValueNy, vpos, objectDepthSampler, UnnormalizedTextureCoords = true, OffsetX= 0, OffsetY= -1, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
		tfetch2D sceneDepthValue, vpos, depthSampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
	};
#else
	uint3 ivpos = uint3(vpos, 0);
#ifdef durango
	// G8 SRVs are broken on Durango - components are swapped
	stencilValue.x = stencilTexture.Load(ivpos).x;
#else
	stencilValue.x = stencilTexture.Load(ivpos).y;
#endif
	objectDepthValue.x = objectDepthSampler.t.Load(ivpos).x;
	objectDepthValuePx.x = objectDepthSampler.t.Load(ivpos, uint2(1, 0)).x;
	objectDepthValueNx.x = objectDepthSampler.t.Load(ivpos, uint2(-1, 0)).x;
	objectDepthValuePy.x = objectDepthSampler.t.Load(ivpos, uint2(0, 1)).x;
	objectDepthValueNy.x = objectDepthSampler.t.Load(ivpos, uint2(0, -1)).x;
	sceneDepthValue.x = depthSampler.t.Load(ivpos);
#endif
	
	// convert to real depth
	depth = 1.0f - objectDepthValue.x;
	depth = 1.0f / (psDepthConstants.x + depth * psDepthConstants.y);
	
	// save off stencil
#ifdef xenon	
	stencil = stencilValue.x * 255;
#else
	stencil = stencilValue.x;
#endif
	
	sceneDepth = sceneDepthValue.r;
	// convert to real depth
	sceneDepth = 1.0f - sceneDepth;
	sceneDepth = 1.0f / (psDepthConstants.x + sceneDepth * psDepthConstants.y);
	
	// I can do this in non-world space
	float4 laplacianX = (objectDepthValuePx.x + objectDepthValueNx.x - 2 * objectDepthValue.x);
	float4 laplacianY = (objectDepthValuePy.x + objectDepthValueNy.x - 2 * objectDepthValue.x);
	
	depthLaplacian = 100 * sqrt(laplacianX * laplacianX + laplacianY * laplacianY); // arbitrary scale
#else // defined(xenon)
	depth = stencil = sceneDepth = depthLaplacian = 0;
#endif // defined(xenon)
}
struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 1.0, 1.0);
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
	
	float depth, stencil, sceneDepth, depthLaplacian;
	
	GetDepthStencil(pixel_coordinates, depth, stencil, sceneDepth, depthLaplacian);
	
	#if defined(xenon) || (DX_VERSION == 11)
		clip(100.0 - stencil); // we cleared to 255
	#endif

	float3 obscuredColor, visibleColor, edgeColor;
	if (stencil < 0.5) // 0
	{
		obscuredColor = friend_color_obscured;
		visibleColor = friend_color_visible;
		edgeColor = friend_color_edge;
	}
	else if (stencil < 1.5) // 1
	{
		obscuredColor = enemy_color_obscured;
		visibleColor = enemy_color_visible;
		edgeColor = enemy_color_edge;
	}
	else if (stencil < 2.5) // 2
	{
		obscuredColor = neutral_color_obscured;
		visibleColor = neutral_color_visible;
		edgeColor = neutral_color_edge;
	}
	else if (stencil < 3.5) // 3
	{
		obscuredColor = friend_vehicle_color_obscured;
		visibleColor = friend_vehicle_color_visible;
		edgeColor = friend_vehicle_color_edge;
	}
	else // 4
	{
		obscuredColor = enemy_vehicle_color_obscured;
		visibleColor = enemy_vehicle_color_visible;
		edgeColor = enemy_vehicle_color_edge;	
	}
	
	bool obscured = (depth > sceneDepth + depth_fudge_factor);
	float4 color = float4(obscured ? obscuredColor : visibleColor, obscured ? obscured_alpha : visible_alpha);
	
	float edgeValue = edge_feather_range > 0 ? saturate((depthLaplacian - edge_threshold) / edge_feather_range) : (depthLaplacian > edge_threshold ? 1 : 0);
		
	color = lerp(color, float4(edgeColor, edge_alpha), edgeValue);
	
	// scale by distance
	float falloffValue = (depth - FALLOFF_START) / (FALLOFF_MAX - FALLOFF_START);
	color.a *= clamp(1 - falloffValue, 0, 1);
	
	float visionWaveDepthDelta = vision_wave_depth - depth;
	color.a *= saturate((visionWaveDepthDelta + vision_wave_width) / vision_wave_width);
	float visionWaveIntensityMultiplier = saturate((vision_wave_width - abs(visionWaveDepthDelta)) / vision_wave_width) * vision_wave_peak_intensity_multiplier;
	visionWaveIntensityMultiplier = max(visionWaveIntensityMultiplier, (visionWaveDepthDelta > 0) ? 1.0f : 0.0f);
	color.rgb *= visionWaveIntensityMultiplier;
	
	color = apply_exposure(color);
	
	return color;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}