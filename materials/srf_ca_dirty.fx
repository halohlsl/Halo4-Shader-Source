//
// File:	 srf_ca_dirty.fx
// Author:	 dvaley
// Date:	 08/19/11
//
// Surface Shader - Super controllable Vector defined directional blend
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
//

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters
// Texture Samplers
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( maskbias_map, "Mask Bias Map", "Mask Bias Map", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"

#if defined(REFLECTION)
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
#endif

// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Detail Color
#if defined(COLOR_DETAIL)
DECLARE_SAMPLER(color_detail_map,		"Color Detail Map", "Color Detail Map", "shaders/default_bitmaps/bitmaps/default_detail.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_mix_detail_alpha,		"Specular Mix Detail Alpha", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

//// Detail Normal Map
DECLARE_BOOL_WITH_DEFAULT(detail_normals, "Detail Normals Enabled", "", true);
#include "next_bool_parameter.fxh"

DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "detail_normals", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_detail_mask_influence, 	"Detail Mask Influence", "detail_normals", 0, 1, float(1.0));
#include "used_float.fxh"

// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular0_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular0_mix_albedo_alpha,		"Specular Mix Albedo Alpha", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if defined(DIFFSPEC)
DECLARE_FLOAT_WITH_DEFAULT(diffspec0_desaturate,		"Diffuse 0 As Specular Desaturate", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffdpec0_power,		"Diffuse 0 As Specular Power", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffspec0_scale,		"Diffuse 0 As Specular Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffspec0_offset,		"Diffuse 0 As Specular Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

#if defined(REFLECTION)
// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection0_color,	"Reflection0 Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection0_intensity,		"Reflection0 Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection0_normal,		"Reflection0 Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel0_intensity,		"Fresnel0 Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel0_power,			"Fresnel0 Power", "", 0, 10, float(3.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel0_mask_reflection,	"Fresnel0 Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel0_inv,				"Fresnel0 Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse0_mask_reflection,	"Diffuse0 Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif

// Self Illum
#if defined(SELFILLUM)
DECLARE_SAMPLER( control_map0_SpGlRf, "Control Map 0 SpGlRf", "Control Map SpGlRf", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(si_color0,	"SelfIllum Color", "", float3(0,0,0));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity0,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_amount0,	"SelfIllum Amount", "", 0, 1, float(1.0));
#include "used_float.fxh"

#endif


// Texture Samplers 1
DECLARE_SAMPLER( color1_map, "Color1 Map", "Color1 Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( normal1_map, "Normal1 Map", "Normal1 Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"

// Diffuse 1
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo1_tint,		"Color1 Tint", "", float3(1,1,1));
#include "used_float3.fxh"

// Specular 1
DECLARE_RGB_COLOR_WITH_DEFAULT(specular1_color,		"Specular1 Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_intensity,		"Specular1 Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_power_min,		"Specular1 Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_power_max,		"Specular1 Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_mix_albedo,		"Specular1 Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular1_mix_albedo_alpha,		"Specular1 Mix Albedo Alpha", "", 0, 1, float(0.0));
#include "used_float.fxh"

#if defined(DIFFSPEC)
DECLARE_FLOAT_WITH_DEFAULT(diffspec1_desaturate,		"Diffuse 1 As Specular Desaturate", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffdpec1_power,		"Diffuse 1 As Specular Power", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffspec1_scale,		"Diffuse 1 As Specular Scale", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffspec1_offset,		"Diffuse 1 As Specular Offset", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

#if defined(REFLECTION)
// Reflection1
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection1_color,	"Reflection1 Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection1_intensity,		"Reflection1 Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection1_normal,		"Reflection1 Normal", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Fresnel1
DECLARE_FLOAT_WITH_DEFAULT(fresnel1_intensity,		"Fresnel1 Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel1_power,			"Fresnel1 Power", "", 0, 10, float(3.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(fresnel1_mask_reflection,	"Fresnel1 Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel1_inv,				"Fresnel1 Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(diffuse1_mask_reflection,	"Diffuse1 Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
#endif

// Mask
DECLARE_FLOAT_WITH_DEFAULT(min_mask_angle,		"Mask Minimum Angle", "", -1, 1, float(-0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(max_mask_angle,		"Mask Maximum Angle", "", -1, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(min_mask_intensity,		"Mask Minimum Intensity", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(max_mask_intensity,		"Mask Maximum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(mask_normal_map_influence,		"Mask Normal Map Influence", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_diffuse_alpha_influence,		"Mask Diffuse Alpha Influence", "", 0, 1, float(0.5));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_x_direction,		"Mask X Direction", "", -1, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_y_direction,		"Mask Y Direction", "", -1, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(mask_z_direction,		"Mask Z Direction", "", -1, 1, float(0.0));
#include "used_float.fxh"

#if defined(PRIMARY_CHANGE_COLOR)
DECLARE_FLOAT_WITH_DEFAULT(pcc_amount, "Primary Change Color Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"
#endif

#if defined(PRIMARY_CHANGE_COLOR_MAP)
DECLARE_SAMPLER(pcc_amount_map,		"Color Change Map", "", "shaders/default_bitmaps/bitmaps/default_monochrome.tif");
#include "next_texture.fxh"
#endif

struct s_shader_data
{
	s_common_shader_data common;
};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
	const float DETAIL_MULTIPLIER = 4.59479f;		// 4.59479f == 2 ^ 2.2  (sRGB gamma)
	float3 geometry_normal = shader_data.common.normal;
	float3 maskNormal;
	float specularIntensity = 0;

    {// Sample base normal map, this will be used to calculate the direction for the blend.
    	float2 normal_map_uv	  = transform_texcoord(uv, normal_map_transform);
		float3 normal_map_sample  = sample_2d_normal_approx(normal_map, normal_map_uv);

		maskNormal = normal_map_sample;

		// composite detail normal map
		STATIC_BRANCH
		if (detail_normals)
		{
			float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);

			normal_map_sample = CompositeDetailNormalMap(shader_data.common,
															 normal_map_sample,
															 normal_detail_map,
															 detail_uv,
															 normal_detail_dist_min,
															 normal_detail_dist_max);

			// blend in detail normal for mask
			maskNormal = lerp(maskNormal,normal_map_sample,normal_detail_mask_influence);
		}

    	shader_data.common.normal = normal_map_sample;
    }

	float alphaMaskMap = 0;

	{// Sample color map and spec.
	    float2 color_map_uv 	   = transform_texcoord(uv, color_map_transform);
		float4 color_map_sample    = sample2DGamma(color_map, color_map_uv);

	    shader_data.common.albedo = color_map_sample;
        shader_data.common.albedo.rgb *= albedo_tint.rgb;

#if defined(PRIMARY_CHANGE_COLOR) || defined (PRIMARY_CHANGE_COLOR_MAP)
        // apply primary change color
        float4 primary_cc = ps_material_object_parameters[0];
        float albedo_lum = color_luminance(shader_data.common.albedo.rgb);

#if defined (PRIMARY_CHANGE_COLOR_MAP)
    	float2 pcc_amount_map_uv   = transform_texcoord(uv, pcc_amount_map_transform);
        float pcc_amount = sample2D(pcc_amount_map, pcc_amount_map_uv).r;
#endif

        shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb,
                                             albedo_lum * primary_cc.rgb,
                                             primary_cc.a * pcc_amount);
#endif

		// mix specular_color with albedo_color
		shader_data.common.albedo.a = lerp(1,color_map_sample.a, specular0_mix_albedo_alpha);;

		//Save off alpha map influance for later use as a mask
		alphaMaskMap = color_map_sample.a;

#if defined(COLOR_DETAIL)
		// Layer in detail color
	    float2 color_detail_map_uv = transform_texcoord(uv, color_detail_map_transform);
	    float4 color_detail = sample2DGamma(color_detail_map, color_detail_map_uv);
	    color_detail.rgb *= DETAIL_MULTIPLIER;

		shader_data.common.albedo.rgb *= color_detail;

		// Layer in detail spec
		specularIntensity *= lerp(1,color_detail.a, specular0_mix_detail_alpha);
#endif
    }

	// Create directional mask for snow using base normals
	maskNormal = mul(maskNormal, shader_data.common.tangent_frame);
#if defined(xenon) 
    float3 maskDirectionVector = float3(mask_z_direction, mask_x_direction, mask_y_direction);
#elif defined(pc)
    float3 maskDirectionVector = float3(mask_z_direction, mask_x_direction, mask_y_direction);
#else
    float3 maskDirectionVector = float3(mask_x_direction, mask_y_direction, mask_z_direction);
#endif

	float maskBias = 0.0;
#if defined(VERTEX_MASK)
	//Use vertex alpha to modify bias
	maskBias = ( ( shader_data.common.vertexColor.a * 4 ) - 2 );
#endif
	float4 maskbias_map_sample    = sample2DGamma(maskbias_map, transform_texcoord(uv, maskbias_map_transform));
	maskBias = lerp( maskBias, maskBias + (alphaMaskMap * -4 + 2.0) ,mask_diffuse_alpha_influence ) + (maskbias_map_sample * -4 + 2.0);
	float maskDirection = dot ( normalize( maskDirectionVector ) , lerp( geometry_normal, maskNormal, mask_normal_map_influence ) ) + maskBias;
	float baseMask = saturate( ( maskDirection - min_mask_angle ) / max( 0.01, max_mask_angle - min_mask_angle ) );
	float mask = lerp( min_mask_intensity, max_mask_intensity, baseMask );

	{// Blend in second normal
		float2 normal1_map_uv	  = transform_texcoord(uv, normal1_map_transform);
		float3 normal1_map_sample  = sample_2d_normal_approx(normal1_map, normal1_map_uv);

		shader_data.common.normal.xy = lerp(shader_data.common.normal.xy, normal1_map_sample.xy, mask);
		shader_data.common.normal.z = sqrt(saturate(1.0f + dot(shader_data.common.normal.xy, -shader_data.common.normal.xy)));

		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
	}

    {// Blend in second color map and spec masks.
	    float2 color1_map_uv 	   = transform_texcoord(uv, color1_map_transform);
		float4 color1_map_sample    = sample2DGamma(color1_map, color1_map_uv);

        color1_map_sample.rgb *= albedo1_tint.rgb;

		// mix specular_color with albedo_color
        shader_data.common.shaderValues.x = lerp(1,color1_map_sample.a, specular1_mix_albedo_alpha);

		// Blend color and spec based on mask
		shader_data.common.albedo.rgb = lerp(shader_data.common.albedo.rgb, color1_map_sample.rgb, mask);
    }

	shader_data.common.shaderValues.y = mask;
}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
	// input from s_shader_data
    float4 albedo         = shader_data.common.albedo;
	float3 normal         = shader_data.common.normal;
	float specular1_alpha = shader_data.common.shaderValues.x;
	float mask		      = shader_data.common.shaderValues.y;

 	float2 uv			  =	pixel_shader_input.texcoord.xy;

	float3 specular = 0.0f;
	{
		// Compute Specular

#if defined(DIFFSPEC)
		// Sample specular map
		float2 color_map_uv	= transform_texcoord(uv,  color_map_transform);//resample the color map.
		float3 specular_mask0 	= sample2DGamma(color_map, color_map_uv).rgb;  //we don't use the albedo because it has been altered by this point.  Not ideal, but this is no more expensive than a spec map, and less memory.

		specular_mask0.rgb = DesaturateGammaColor( specular_mask0.rgb, diffspec0_desaturate );
		specular_mask0.rgb = saturate( pow( specular_mask0.rgb, diffdpec0_power ) * diffspec0_scale + diffspec0_offset );

		float2 color1_map_uv	= transform_texcoord(uv,  color1_map_transform);//resample the color map.
		float3 specular_mask1 	= sample2DGamma(color1_map, color1_map_uv).rgb;  //we don't use the albedo because it has been altered by this point.  Not ideal, but this is no more expensive than a spec map, and less memory.

		specular_mask1.rgb = DesaturateGammaColor( specular_mask1.rgb, diffspec1_desaturate );
		specular_mask1.rgb = saturate( pow( specular_mask1.rgb, diffdpec1_power ) * diffspec1_scale + diffspec1_offset );

#else
		float3 specular_mask0 = 1;
		float3 specular_mask1 = 1;
#endif

		//compute specular mask
		specular_mask0 = specular0_color * lerp(1,  shader_data.common.albedo.rgb, specular0_mix_albedo) * specular_mask0;
		specular_mask1 = specular1_color * lerp(1,  shader_data.common.albedo.rgb, specular1_mix_albedo) * specular_mask1;
		float3 specular_mask = lerp(specular_mask0, specular_mask1, mask);



       // pre-computing roughness with independent control over white and black point in gloss map
        float specular0_power = calc_roughness(albedo.a, specular0_power_min, specular0_power_max);
        float specular1_power = calc_roughness(specular1_alpha, specular1_power_min, specular1_power_max);
		//combine specular powers
		float specular_power = lerp(specular0_power, specular1_power, mask);

	    // using blinn specular model
    	calc_specular_phong(specular, shader_data.common, normal, albedo.a , specular_power);

		//Find blend spec intensity
		float specular_intensity = lerp(specular0_intensity, specular1_intensity, mask);

        // modulate by mask
        specular *= specular_mask.rgb * specular_intensity;
	}

    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);

		// Store the mask for diffuse reflection
        diffuse_reflection_mask = diffuse;

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_intensity;
    }

#if defined(REFLECTION)
	float3 reflection = 0.0f;

	{
		// sample reflection
		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rNormal = lerp(shader_data.common.geometricNormal, shader_data.common.normal, lerp( reflection0_normal, reflection1_normal, mask ) );

		float3 rVec = reflect(view, rNormal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *										// reflection cube sample
			lerp( reflection0_color, reflection1_color, mask ) *		// RGB reflection color from material
			lerp( reflection0_intensity, reflection1_intensity, mask ) *									// scalar reflection intensity from material
//			control_mask.b *										// control mask reflection intensity channel
			reflectionMap.a;										// intensity scalar from reflection cube

		float fresnel = 0.0f;
		{ // Compute fresnel to modulate reflection

			float3 view = -shader_data.common.view_dir_distance.xyz;
			float  vdotn = saturate(dot( view, normal));
			fresnel = lerp(vdotn, saturate(1 - vdotn), lerp( fresnel0_inv, fresnel1_inv, mask ) );
			fresnel = pow(fresnel, lerp( fresnel0_power, fresnel1_power, mask ) ) * lerp( fresnel0_intensity, fresnel1_intensity, mask );
		}

		// Fresnel Reflection Masking
		reflection  = lerp(reflection, reflection * fresnel, lerp( fresnel0_mask_reflection, fresnel1_mask_reflection, mask ) );
		reflection  = lerp(reflection, reflection * diffuse_reflection_mask, lerp( diffuse0_mask_reflection, diffuse1_mask_reflection, mask ) );
	}
#endif


   //.. Finalize Output Color
    float4 out_color;
	//float4 out_color = float4(shader_data.common.vertexColor.aaa,1);

    out_color.rgb = diffuse + specular;
 	out_color.a   = shader_data.common.albedo.a;

	//self Illum
#if defined(SELFILLUM)
	if (AllowSelfIllum(shader_data.common))
	{
		// Sample control mask
		float2 control_map0_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map0_SpGlRf_transform);
		float4 control_mask		= sample2DGamma(control_map0_SpGlRf, control_map0_uv); //for now we are only using the self illum portion of the cotrol map. Could be added reflection to match blinn shader.

#if defined(PRIMARY_CHANGE_COLOR_MAP) //if we have a color change map, allow it to effect the color of the self illum map, fakes team colored glows/lights.
        float4 primary_cc = ps_material_object_parameters[0];

		float2 pcc_amount_map_uv  = transform_texcoord(pixel_shader_input.texcoord.xy, pcc_amount_map_transform);
        float pcc_amount = sample2D(pcc_amount_map, pcc_amount_map_uv).r;//TODO: find a way not to sample this twice.

		float3 selfIllumeColor = lerp( si_color0, primary_cc, pcc_amount );
		float3 selfIllum = albedo.rgb * selfIllumeColor * si_intensity0 * control_mask.a;
#else
		float3 selfIllum = albedo.rgb * si_color0 * si_intensity0 * control_mask.a;
#endif
		selfIllum = lerp( selfIllum, float3(0,0,0), mask );//TODO: ? if we want material 1 to have self illum mask it in here.

		float3 si_out_color = out_color.rgb + selfIllum;
		float3 si_no_color  = out_color.rgb * (1-control_mask.a);

		out_color.rgb = lerp(si_no_color, si_out_color, min(1, si_amount0));

		// Output self-illum intensity as linear luminance of the added value
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(selfIllum);
	}
#endif

 	#if defined(REFLECTION)
	out_color.rgb += reflection;
	#endif

	return out_color;
}


#include "techniques.fxh"