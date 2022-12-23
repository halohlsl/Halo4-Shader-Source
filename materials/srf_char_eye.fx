// character eye shader
// hcoulby
// 8.18.2011
// Copyright (c) 343 Industries. All rights reserved.



#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"


DECLARE_SAMPLER_NO_TRANSFORM( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

//DECLARE_SAMPLER_NO_TRANSFORM( normal_map, "Normal Map", "Iris Out Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
//#include "next_texture.fxh"

DECLARE_SAMPLER_NO_TRANSFORM( iris_in_normal_map, "Iris In Normal Map", "Iris In Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( iris_out_normal_map, "Iris Out Normal Map", "Iris Out Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


DECLARE_SAMPLER_NO_TRANSFORM( eye_control_map, "Eye Control Map", "Eye Control Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"



DECLARE_RGB_COLOR_WITH_DEFAULT(iris_in_spec_color,	"Iris In Spec Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_in_albedo_mix,	"Iris In Spec Albedo Mix", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_in_spec_intensity,	"Iris In Spec Itensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_in_spec_power,	"Iris In Spec Power", "", 0, 1, float(30));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(iris_out_spec_color,	"Iris Out Spec Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_out_albedo_mix,	"Iris Out Spec Albedo Mix", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_out_spec_intensity,	"Iris Out Spec Itensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_out_power_min,		"Iris Out Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_out_power_max,		"Iris Out Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity1,		"Reflection Intensity 1", "", 0, 1, float(0.02));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity2,		"Reflection Intensity 2", "", 0, 1, float(0.01));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(iris_tint,		"Iris Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,		"Diffuse Mask Reflection", "", 0, 1, float(0.0));
#include "used_float.fxh"





struct s_shader_data
{
	s_common_shader_data common;
   float3 normal_iris_in;
   float3 normal_iris_out;

};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv		= pixel_shader_input.texcoord.xy;


    { // sample color maps
        float2 color_map_uv      = transform_texcoord(uv, float4(1, 1, 0, 0));
        float4 color_map_sampled = sample2DGamma(color_map, color_map_uv);
        shader_data.common.albedo.rgb = color_map_sampled * albedo_tint;
    }



    {// Sample normal maps.
    	float2 normal_map_uv	  = transform_texcoord(uv, float4(1, 1, 0, 0));		
	    float3 normal_iris_in  = sample_2d_normal_approx(iris_in_normal_map, normal_map_uv);
		float3 normal_iris_out = sample_2d_normal_approx(iris_out_normal_map, normal_map_uv);		
    	//shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
        //shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

        shader_data.normal_iris_in  = mul(normal_iris_in, shader_data.common.tangent_frame);
        shader_data.normal_iris_out = mul(normal_iris_out, shader_data.common.tangent_frame);
    }

}



// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{

    // sample control map
  	float2 uv		= pixel_shader_input.texcoord.xy;
    float2 control_map_uv      = transform_texcoord(uv, float4(1, 1, 0, 0));
    float4 control_map_sampled = sample2DGamma(eye_control_map, control_map_uv);

	
	shader_data.common.albedo.rgb *= lerp(float3(1,1,1) , iris_tint, control_map_sampled.a);
	
    float3 specular = 0.0f;
    { // Specular
        float  specular_weight = 0.0f;

        float3 spec_iris_in = 0.0f;
        calc_specular_blinn(
                    spec_iris_in ,
                    shader_data.common,
                    shader_data.normal_iris_in,
                    shader_data.common.albedo.a,
                    iris_in_spec_power);

        float3 spec_iris_in_col = lerp(iris_in_spec_color, shader_data.common.albedo.rgb,  iris_in_albedo_mix);
        spec_iris_in *= spec_iris_in_col * iris_in_spec_intensity * control_map_sampled.r;

        float3 spec_iris_out = 0.0f;

        float iris_out_power = calc_roughness(control_map_sampled.b, iris_out_power_min, iris_out_power_max );

        calc_specular_blinn(
                    spec_iris_out,
                    shader_data.common,
                    shader_data.normal_iris_out,
                    shader_data.common.albedo.a,
                    iris_out_power);

        float3 spec_iris_out_col = lerp(iris_out_spec_color, shader_data.common.albedo.rgb,  iris_out_albedo_mix);
        spec_iris_out *= spec_iris_out_col * iris_out_spec_intensity * control_map_sampled.g;

        specular = spec_iris_in + spec_iris_out;

    }


    float3 diffuse = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.normal_iris_out);
    float diffuse_mask_ref = lerp(1.0, diffuse, diffuse_mask_reflection);
    diffuse *= shader_data.common.albedo.rgb * diffuse_intensity ;
	

    // reflection
    float3 reflection = 0.0f;
    float3 view = shader_data.common.view_dir_distance.xyz;
    float3 rVec = reflect(view, shader_data.normal_iris_out);
	float fresnel  = 1-saturate( dot(shader_data.normal_iris_in, -view) );
	reflection = sampleCUBEGamma(reflection_map, rVec);
	fresnel = lerp(reflection_intensity1, reflection_intensity2, fresnel);	
	reflection *= fresnel * diffuse_mask_ref;


    float4 out_color = 0.0f;
    out_color.rgb = reflection + diffuse + specular;

	if (AllowReflection(shader_data.common))
	{
		out_color.rgb = color_screen(out_color.rgb, reflection);
	}

    return out_color;
}


#include "techniques.fxh"
