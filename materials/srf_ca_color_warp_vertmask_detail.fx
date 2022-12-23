//
// File:	 srf_ca_color_warp_vertmask_detail.fx
// Author:	 v-maozta
// Date:	 6/19/2013
//
// Surface Shader - A simple color shader with self-illumination that warps according to a mask, and applies a color detail map over the entire surface
//
// Copyright (c) 343 Industries. All rights reserved.
//

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

#define VERT_MASK
#define SECOND_UV_SET

// Texture Samplers
DECLARE_SAMPLER(diffuseMap, "Diffuse Map", "Diffuse Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(alphaMap, "Alpha Map", "Alpha Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(selfIllumMap, "SelfIllum Map", "SelfIllum Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(uvOffsetMap, "UV Offset Map", "UV Offset map", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(color_detail_map,       "Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"

// Shader Parameters
DECLARE_RGB_COLOR_WITH_DEFAULT(diffuseTint, "Diffuse Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuseIntensity, "Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(siColor, "SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(siIntensity, "SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(uvOffsetStrength, "UV Offset Strength", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(uvOffsetSpeed, "UV Offset Speed", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(uvOffsetFrequency, "UV Offset Frequency", "", 0, 10, float(1.0));
#include "used_float.fxh"
//DECLARE_FLOAT(fresnelIntensity, "Fresnel Intensity", "", 0, 1) = float(0.0);
//#include "used_float.fxh"
//DECLARE_FLOAT(fresnelPower, "Fresnel Power", "", 0, 10) = float(2.0);
//#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(detail_tint, "Detail Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_alpha_intensity, "Detail Alpha Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(detail_intensity, "Detail Intensity", "", 1, 10, float(1.0));
#include "used_float.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
	in s_pixel_shader_input pixelShaderInput,
	inout s_shader_data shaderData)
{
#if defined(xenon) || (DX_VERSION == 11)

	float2 uv = transform_texcoord(pixelShaderInput.texcoord.xy, uvOffsetMap_transform);
	
	float2 offsetValue = sample2D(uvOffsetMap, uv).rg;
	
    #if defined(SECOND_UV_SET)
	float2 uv2 = pixelShaderInput.texcoord.zw;
    #endif
	
	// Compute the uv offset
	float2 uvOffset = uvOffsetStrength * offsetValue * cos(uvOffsetFrequency + uvOffsetSpeed * float2(ps_time.x, ps_time.x));
	
	// Sample from our diffuse/selfIllum maps respecting UV distortion
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, diffuseMap_transform) + uvOffset;
	float4 diffuse = sample2DGamma(diffuseMap, uv) * float4(diffuseTint, 1) * diffuseIntensity;
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, selfIllumMap_transform) + uvOffset;
	float4 selfIllum = sample2DGamma(selfIllumMap, uv) * float4(siColor, 1) * siIntensity;
	
	// Grab our alpha value from the alpha mask -- no UV distortion applied -- strict mask
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, alphaMap_transform);
	float alphaMapMask = sample2DGamma(alphaMap, uv).r;

	// Compute fresnel to mask/smooth out the edges
	//float fresnel = 0.0f;
	//{
//		#if defined(USE_FRESNEL)
//
	//	float3 view = -shaderData.common.view_dir_distance.xyz;
//		float3 n = normalize( shaderData.common.geometricNormal );
	//	fresnel = saturate(dot(view, n));
	//	fresnel = lerp( 1.0, pow(fresnel, fresnelPower), fresnelIntensity );
	//	
	//	#endif 
	//}

	//shaderData.common.albedo = (diffuse + float4(selfIllum.rgb, 0)) * fresnel * alphaMapMask;
	//shaderData.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum) * fresnel * alphaMapMask;
	
	shaderData.common.albedo = (diffuse + float4(selfIllum.rgb, 0)) * alphaMapMask;
	shaderData.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum) * alphaMapMask;
	
    #if defined(SECOND_UV_SET)
	float2 color_detail_map_uv = transform_texcoord(uv2, color_detail_map_transform);
    #else
	float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
    #endif
    
    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);

    color_detail.rgb *= detail_tint * detail_intensity;
    color_detail.a *= detail_alpha_intensity;

	shaderData.common.albedo *= color_detail;
	
#else // PC

	// Just output the masked diffuse on the PC for speed
	float2 uv = transform_texcoord(pixelShaderInput.texcoord.xy, diffuseMap_transform);
	float4 diffuse = sample2DGamma(diffuseMap, uv);
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, alphaMap_transform);
	float alphaMapMask = sample2DGamma(alphaMap, uv).r;
	
    #if defined(SECOND_UV_SET)
	float2 uv2 = pixelShaderInput.texcoord.zw;
	float2 color_detail_map_uv = transform_texcoord(uv2, color_detail_map_transform);
    #else
	float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
    #endif
    
    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
	
	shaderData.common.albedo = diffuse * color_detail * alphaMapMask;
	
#endif
	
#ifdef VERT_MASK
	// Respect vertex alpha
	shaderData.common.albedo *= shaderData.common.vertexColor.a;
	shaderData.common.selfIllumIntensity *= shaderData.common.vertexColor.a;
#endif
}

float4 pixel_lighting(
	in s_pixel_shader_input pixelShaderInput,
	inout s_shader_data shaderData)
{
	// input from shader_data 
	return shaderData.common.albedo;
}

#include "techniques.fxh"