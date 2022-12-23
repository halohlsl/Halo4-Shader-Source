//
// File:	 srf_constant_core.fxh
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Constant, no diffuse illumination model, may have specular though
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader
#define DISABLE_SH

#if ! defined(SPECULAR) && !defined(LIGHTSHAFT)
#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME
#endif

#if defined(REFLECTION)
#undef DISABLE_NORMAL
#endif

#if defined(DEPTH_FADE)
#define ENABLE_DEPTH_INTERPOLATER
#endif

#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

#if defined(DEPTH_FADE)
#include "depth_fade.fxh"
#endif

// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( selfillum_map, "SelfIllum Map", "SelfIllum Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

#if defined(SPECULAR)
DECLARE_SAMPLER( specular_map, "Specular Map", "Specular Map", "shaders/default_bitmaps/bitmaps/default_spec.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
#endif

// texture for modulating the intensity of the final surface color, requested by olliver
#if defined(INTENSITYMAP)
DECLARE_SAMPLER( intensity_map, "Intensity Map", "Intensity Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
#endif


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Specular
#if defined(SPECULAR)
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif



// Reflection
#if defined(REFLECTION)

DECLARE_SAMPLER_CUBE(reflection_map,	"Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,		"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_normal,		"Reflection Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,				"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

#endif

// Self Illum
DECLARE_RGB_COLOR_WITH_DEFAULT(si_color,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(scroll_rate_u, 	"Scroll Rate U", "", -1, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scroll_rate_v, 	"Scroll Rate V", "", -1, 1, float(0.0));
#include "used_float.fxh"


#if defined(SELFILLUM_SCROLL)
DECLARE_FLOAT_WITH_DEFAULT(selfillum_scroll_rate_u, 	"SelfIllum Scroll Rate U", "", -1, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(selfillum_scroll_rate_v, 	"SelfIllum Scroll Rate V", "", -1, 1, float(0.0));
#include "used_float.fxh"

#endif

#if defined(VERTEX_ALPHA)
DECLARE_FLOAT_WITH_DEFAULT(vertex_alpha_multiplicative, 	"Vertex alpha multiplies with texture alpha", "", -1, 1, float(0.0));
#include "used_float.fxh"
#endif

#if defined(LIGHTSHAFT)
	DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity,		"Fresnel Intensity", "", 0, 1, float(1.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(3.0));
	#include "used_float.fxh"

	DECLARE_FLOAT_WITH_DEFAULT(fade_dist_max,	"Fade Start Dist.", "", 0, 1, float(5.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(fade_dist_min, 	"Fade  End Dist.", "", 0, 1, float(1.0));
	#include "used_float.fxh"
#endif

#if defined(PRIMARY_CHANGE_COLOR)
DECLARE_FLOAT_WITH_DEFAULT(pcc_amount, "Primary Change Color Amount", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif

#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
static const float clip_threshold = 254.5f / 255.0f;
#endif

#if defined(ENABLE_WIREFRAME_OUTLINE)
DECLARE_BOOL_WITH_DEFAULT(wireframe_outline, "Wireframe Outline", "", false);
#include "next_bool_parameter.fxh"
#endif

struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv    		 = pixel_shader_input.texcoord.xy;


#if !defined(cgfx)
	uv += float2(scroll_rate_u, scroll_rate_v) * ps_time.z;
#else
	uv += float2(scroll_rate_u, scroll_rate_v) * frac(ps_time.x/600.0f);
#endif

#if defined(PRIMARY_CHANGE_COLOR)
	float4 primary_cc = ps_material_object_parameters[0];
#endif

    {// Sample color map.
	    float2 color_map_uv 	  = transform_texcoord(uv, color_map_transform);
	    shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
		shader_data.common.shaderValues.y = shader_data.common.albedo.a;

#if defined(PRIMARY_CHANGE_COLOR)
        // apply primary change color
        float albedo_lum = color_luminance(shader_data.common.albedo.rgb);

        shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb,
                                             albedo_lum * primary_cc.rgb,
                                             primary_cc.a * pcc_amount);
#endif

		shader_data.common.albedo.rgb *= albedo_tint.rgb;
	}


#if defined(SPECULAR)
    float2 normal_uv   = transform_texcoord(uv, normal_map_transform);
    float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);
    shader_data.common.normal = mul(base_normal, shader_data.common.tangent_frame);
#endif

#if defined(ALPHA_CLIP)
	// Snip snip
	clip(shader_data.common.shaderValues.y - clip_threshold);
#endif
}

// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
#if defined(xenon) && defined(ENABLE_WIREFRAME_OUTLINE)
	if (wireframe_outline)
	{
		pixel_pre_lighting(pixel_shader_input, shader_data);
	}
#endif

    // input from s_shader_data
    float3 albedo         = shader_data.common.albedo;


	//float3 H = normalize(direction - common.view_dir_distance.xyz);
	float3 specular = 0.0f;

#if defined(SPECULAR)
    // sample specular mask
    float2 specular_map_uv  = transform_texcoord(pixel_shader_input.texcoord.xy, specular_map_transform);
	float4 specular_map_sm  = sample2DGamma(specular_map, specular_map_uv);

    // set specular weighting
    float specular_weight = specular_intensity;

    // pre-computing roughness
    float power = calc_roughness(specular_map_sm.a, specular_power_min, specular_power_max );


	float3 lightdir = normalize(ps_camera_backward.xyz);
    float NdotL = saturate( dot(lightdir, shader_data.common.normal) );
    specular = pow(NdotL, power) * specular_weight * specular_map_sm * specular_color;

#endif


	float3 reflection = 0.0f;

#if defined(REFLECTION)
	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, reflection_normal);

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *							// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			reflectionMap.a;							// intensity scalar from reflection cube

		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection

			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot(view, shader_data.common.normal));
			fresnel = lerp(vdotn, saturate(1 - vdotn), fresnel_inv);
			fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
		}

		// Fresnel Reflection Masking
		reflection  = lerp(reflection, reflection * fresnel, fresnel_mask_reflection);
	}
#endif


     //.. Finalize Output Color
	float4 out_color = float4(0.0f, 0.0f, 0.0f, shader_data.common.shaderValues.y);

	if (AllowSelfIllum(shader_data.common))
	{
		out_color.rgb += albedo.rgb * diffuse_intensity + specular + reflection;
	}

	// self illum
    if (AllowSelfIllum(shader_data.common))
    {
		// sample self illum map
		float2 selfillum_uv  = pixel_shader_input.texcoord.xy;

#if defined(USEUV2)
		selfillum_uv = pixel_shader_input.texcoord.zw;
#endif


#if defined(SELFILLUM_SCROLL)
	#if !defined(cgfx)
		selfillum_uv += float2(selfillum_scroll_rate_u, selfillum_scroll_rate_v) * ps_time.z;
	#else
		selfillum_uv += float2(selfillum_scroll_rate_u, selfillum_scroll_rate_v) * frac(ps_time.x/600.0f);
	#endif
#else
	// if not using independent scroll value, scroll with the rest of the textures in the albdeo pass
	#if !defined(cgfx)
		selfillum_uv += float2(scroll_rate_u, scroll_rate_v) * ps_time.z;
	#else
		selfillum_uv += float2(scroll_rate_u, scroll_rate_v) * frac(ps_time.x/600.0f);
	#endif
#endif


		float2 si_map_uv 	   = transform_texcoord(selfillum_uv, selfillum_map_transform);
		float3 self_illum = sample2DGamma(selfillum_map, si_map_uv).rgb;
		self_illum *= si_color * si_intensity * shader_data.common.shaderValues.y;

#if defined(PRIMARY_CHANGE_COLOR)
		float4 primary_cc = ps_material_object_parameters[0];

		self_illum *= float4(primary_cc.rgb, primary_cc.a * pcc_amount);
#endif

		out_color.rgb += self_illum;

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(self_illum);
	}

#if defined(LIGHTMAP_AO)
	out_color.rgb *= VMFGetAOScalar(shader_data.common.lighting_data.vmf_data);
#endif

// ALPHA
#if defined(VERTEX_ALPHA)
    out_color.a = lerp(shader_data.common.vertexColor.a,
					   shader_data.common.vertexColor.a * out_color.a,
					   vertex_alpha_multiplicative);
#endif



# if defined(LIGHTSHAFT)
		//FRESNEL MASKING
		// geo normal for fresnel
		float3 geo_normal       = shader_data.common.geometricNormal;
		float3 view = shader_data.common.view_dir_distance.xyz;
		float fresnel  = saturate( dot(geo_normal, -view) );
		fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;

	    // DISTANCE BASED FADE
		float alpha_fade = float_remap( shader_data.common.view_dir_distance.w,
												 fade_dist_min,
												 fade_dist_max,
												 1, 0 );

		out_color.a *= fresnel;
		out_color.a = lerp(out_color.a, float3(0,0,0), alpha_fade);
		out_color.a = saturate(out_color.a);

#endif

#if defined(DEPTH_FADE)
	float depthFade = 1.0f;
#if defined(xenon) || (DX_VERSION == 11)
	float2 vPos = shader_data.common.platform_input.fragment_position.xy;
	depthFade = ComputeDepthFade(vPos * psDepthConstants.z, pixel_shader_input.view_vector.w); // stored depth in the view_vector w
#endif
	out_color.a *= depthFade;
#endif

#if defined(INTENSITYMAP)
	float4 intensity_map_sm  = sample2DGamma(intensity_map,  transform_texcoord(pixel_shader_input.texcoord.xy, intensity_map_transform));
	out_color.rgb *= intensity_map_sm.rgb;
#endif


	return out_color;


}


#include "techniques.fxh"
