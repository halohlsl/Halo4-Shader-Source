#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "engine/engine_parameters.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "shadow_apply_clouds_registers.fxh"

LOCAL_SAMPLER2D(ps_depth_sampler, 0);

float3 GetPixelWorldPosition(in float2 fragment_pixel_position)
{
	float depth = 0;
#if defined(xenon)
	asm
	{
		tfetch2D depth.x___, fragment_pixel_position, ps_depth_sampler, AnisoFilter= disabled, MagFilter= point, MinFilter= point, MipFilter= point, UnnormalizedTextureCoords= true, UseComputedLOD=false
	};
#endif

	float4 worldPosition = float4(fragment_pixel_position, depth, 1.0f);
	worldPosition = mul(worldPosition, transpose(ps_view_transform_inverse));

	return worldPosition.xyz / worldPosition.w;
}

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	return output;
}

float4 default_ps(in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target
{
#if defined(xenon)
	float3 worldSpacePosition = GetPixelWorldPosition(pixel_pos);
	
	
	// Calculate cloud texture coordinate to fetch from
	const float kCloudTextureScale = ps_cloud_constant.y;
	const float2 kCloudTextureOffset = ps_cloud_constant.zw;
	float2 cloudTexcoord = worldSpacePosition.xy * kCloudTextureScale + kCloudTextureOffset;

	// Fetch cloud texture
	float4 cloudSample = sample2DLOD(ps_cloud_texture, cloudTexcoord,0,false);

	// Multiply with the current alpha
	return float4(0.0, 0.0, cloudSample.x, 0.0);
#else
	return float4(0.0, 0.0, 0.0, 0.0);
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