//
// File:	 srf_ca_hologram.fx
// Author:	 v-jcleav
// Date:	 1/25/12
//
// Surface Shader - Hologram shader that supports team color for our game modes
//
// Copyright (c) 343 Industries. All rights reserved.
//

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER(diffuseMap, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(scanMap, "Scan Map", "Scan Map", "shaders/default_bitmaps/bitmaps/alpha_black.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(staticMap, "Static Map", "Static Map", "shaders/default_bitmaps/bitmaps/tight_mono_noise.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(uvOffsetMap, "UV Offset Map", "UV Offset map", "shaders/default_bitmaps/bitmaps/alpha_white.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(fresnelRamp, "Fresnel Ramp", "Fresnel Ramp", "shaders/default_bitmaps/bitmaps/alpha_black.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnelRampOffset, "Fresnel Ramp Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnelRampIntensity, "Fresnel Ramp Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(uvOffsetStrength, "UV Offset Strength", "", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(uvOffsetSpeed, "UV Offset Speed", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(uvOffsetFrequency, "UV Offset Frequency", "", 0, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(intensity, "Global Intensity", "", 0, 5, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(holoIntensity, "Holo Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnelIntensity, "Fresnel Intensity", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnelPower, "Fresnel Power", "", 0, 10, float(2.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(staticIntensity, "Static Intensity", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scanIntensity, "Scan Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(heatIntensity, "Heat Intensity", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(staticScale, "Static Scale", "", 0, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(changeColorAmount, "Primary Change Color Amount", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(hotTint, "Hot Tint", "", float3(1,1,1));
#include "used_float3.fxh"

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
		in s_pixel_shader_input pixelShaderInput,
		inout s_shader_data shaderData)
{
#if defined(xenon) || (DX_VERSION == 11)

	// Base hologram color
	float2 uv = transform_texcoord(pixelShaderInput.texcoord.xy, uvOffsetMap_transform);
	float2 offsetValue = sample2D(uvOffsetMap, uv).rg;
	float2 uvOffset = uvOffsetStrength * offsetValue * cos(uvOffsetFrequency + uvOffsetSpeed * float2(ps_time.x, ps_time.x));
	float2 fresnelRampUV = (float2)0;
	
	// Compute fresnel to mask/smooth out the edges, as well as apply the ramp
	float fresnel = 0.0f;
	{
		float3 view = -shaderData.common.view_dir_distance.xyz;
		float3 n = normalize( shaderData.common.geometricNormal );
		fresnel = saturate(dot(view, n));
		fresnelRampUV.x = fresnel;
		fresnel = lerp( 1.0, pow(fresnel, fresnelPower), fresnelIntensity );
	}
	
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, diffuseMap_transform) + uvOffset;
	float4 diffuse = sample2DGamma(diffuseMap, uv);
	float4 hologramColor = float4(diffuse.rgb, 1.0) * holoIntensity;
	
	// Fresnel ramp contribution
	fresnelRampUV.x += fresnelRampOffset;
	float4 fresnelRampColor = sample2D(fresnelRamp, fresnelRampUV);
	hologramColor += fresnelRampColor * fresnelRampIntensity;
	
	// Scan contribution (gets more offset, too)
	uv = transform_texcoord(pixelShaderInput.texcoord.xy, scanMap_transform) + uvOffset * 2.0;
	float4 scanColor = sample2D(scanMap, uv) * scanIntensity;
	hologramColor += scanColor;
	
	// The alpha channel of the diffuse texture is revealed by the scan texture
	hologramColor += scanColor * diffuse.a;
	
	float4 changeColor = ps_material_object_parameters[0] * changeColorAmount;
	
	// Hotness is applied to the upper ranges
	hologramColor.rgb += hotTint * ((max(hologramColor.r, 0.5) - 0.5) * 2.0) * heatIntensity;
	
	// Add our static
	float2 uvStatic = pixelShaderInput.texcoord.xy * staticScale * (cos(ps_time.x * 20.0f) * 0.5f + 1.5f);
	uvStatic = transform_texcoord(uvStatic, staticMap_transform);
	float4 staticColor = sample2DGamma(staticMap, uvStatic) * staticIntensity;
	
	shaderData.common.albedo = (hologramColor * changeColor + staticColor) * intensity * fresnel;
	
#else // PC

	// Just output the diffuse on the PC for speed
	float2 uv = transform_texcoord(pixelShaderInput.texcoord.xy, diffuseMap_transform);
	float4 diffuse = sample2DGamma(diffuseMap, uv);
	
	shaderData.common.albedo = diffuse;

#endif
	
#ifdef VERT_MASK
	// Respect vertex alpha
	shaderData.common.albedo *= shaderData.common.vertexColor.a;
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
