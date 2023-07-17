// Author:	 hocoulby
//

#define DISABLE_LIGHTING_TANGENT_FRAME
#define DISABLE_LIGHTING_VERTEX_COLOR

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
DECLARE_SAMPLER( control_map_SpGlRf, "Control Map SpGlRfSi", "Control Map SpGlRfSi", "shaders/default_bitmaps/bitmaps/default_control.tif")
#include "next_texture.fxh"
		

DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"


// Albedo
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,	"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,	"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity, "Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,	"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,	 "Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,	 "Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"

// Reflection
DECLARE_RGB_COLOR_WITH_DEFAULT(reflection_color,	"Reflection Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(reflection_intensity,		"Reflection Intensity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_mask_reflection,	"Diffuse Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"

// Fresnel
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,	"Fresnel Power", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_intensity, "Fresnel Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_mask_reflection,	"Fresnel Mask Reflection", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_inv,	"Fresnel Invert", "", 0, 1, float(1.0));
#include "used_float.fxh"	

// Layer 1
DECLARE_SAMPLER( layer1_color_map, "Layer1 Color Map", "Layer1 Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_normal_map, "Layer1 Normal Map", "Layer1 Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER( layer1_spec_map, "Layer1 Specular Map", "Layer1 Spec Map", "shaders/default_bitmaps/bitmaps/default_spec.tif");
#include "next_texture.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_albedo_tint,	"Layer1 Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(layer1_spec_color,	"Layer1 Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_spec_intensity, "Layer1 Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(layer1_spec_power, "Layer1 Specular Power", "", 10, 1000, float(100));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;
};


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv = pixel_shader_input.texcoord.xy;
    float blend = shader_data.common.vertexColor.a;
    
// Color 
    float2 color_map_uv = transform_texcoord(uv, color_map_transform);
    float3 base_color = sample2DGamma(color_map, color_map_uv);
    base_color *= albedo_tint;
    
    float2 layer1_color_map_uv = transform_texcoord(uv, layer1_color_map_transform);
    float3 layer1_color = sample2DGamma(layer1_color_map, layer1_color_map_uv);
    layer1_color *= layer1_albedo_tint;
    
    shader_data.common.albedo.rgb = lerp(base_color, layer1_color, blend);
    shader_data.common.albedo.a = 1.0;

// Normals
    float2 normal_uv    = transform_texcoord(uv, normal_map_transform);
    float3 base_normal = sample_2d_normal_approx(normal_map, normal_uv);
    base_normal *= 1-blend;
    
    float2 layer1_normal_uv    = transform_texcoord(uv, layer1_normal_map_transform);
    float3 layer1_normal = sample_2d_normal_approx(layer1_normal_map, layer1_normal_uv);    
    layer1_normal.xy *= blend;
    
    shader_data.common.normal.xy = base_normal.xy + layer1_normal.xy;
    shader_data.common.normal.z = sqrt(saturate(1.0f + dot(shader_data.common.normal.xy, -shader_data.common.normal.xy)));	
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

    
    float fresnel = 0.0f;
    { // Compute fresnel to modulate reflection
        float3 view = -shader_data.common.view_dir_distance.xyz;
        float  vdotn = saturate(dot(view, shader_data.common.normal));
        fresnel = vdotn + fresnel_inv - 2 * fresnel_inv * vdotn;	// equivalent to lerp(vdotn, 1 - vdotn, fresnel_inv);
        fresnel = pow(fresnel, fresnel_power) * fresnel_intensity;
   
    }

    // Fresnel mask for reflection
    shader_data.common.shaderValues.x = lerp(1.0, fresnel, fresnel_mask_reflection);


}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	//..  Output Color
    float4 out_color = float4(1,1,1,shader_data.common.albedo.a);
	float blend = shader_data.common.vertexColor.a;
	
	// Control Map for Specular, Gloss, Reflection , SelfIllum
	float2 control_map_uv	= transform_texcoord(pixel_shader_input.texcoord.xy, control_map_SpGlRf_transform);
	float4 control_mask		= sample2DGamma(control_map_SpGlRf, control_map_uv);
	
	
//!-- Diffuse Lighting
    float3 diffuse = 0.0f;
	float3 diffuse_reflection_mask = 0.0f;
    calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);
    diffuse_reflection_mask = diffuse;
    diffuse *= shader_data.common.albedo.rgb;

		
//!-- Specular Lighting				
    float3 specular = 0.0f;
	// pre-computing roughness with independent control over white and black point in gloss map
	float power = calc_roughness(control_mask.g, specular_power_min, specular_power_max );
    float blended_power = lerp(power, layer1_spec_power, blend);
    
    // sample layer1 spec map
  
    float3 spec0_color = control_mask.r * specular_color * specular_intensity;
    spec0_color = lerp(spec0_color, shader_data.common.albedo.rgb, specular_mix_albedo);    

   	float2 layer1_spec_map_uv= transform_texcoord(pixel_shader_input.texcoord.xy, layer1_spec_map_transform);
	float3 layer1_spec	= sample2DGamma(layer1_spec_map, layer1_spec_map_uv).rgb;    
    layer1_spec = layer1_spec * layer1_spec_intensity * layer1_spec_color;
    
    float3 blended_spec_color = lerp(spec0_color, layer1_spec, blend);
    
	calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, shader_data.common.albedo.a, blended_power);		
	specular *= blended_spec_color;

	
// Add diffuse and specular to outcolor
	out_color.rgb = diffuse + specular;	

	
//!-- Reflection 
	float3 reflection = 0.0f;
	if (AllowReflection(shader_data.common)) {

		float3 view = shader_data.common.view_dir_distance.xyz;
		float3 rVec = reflect(view,  shader_data.common.normal);
		float4 reflectionMap = sampleCUBEGamma(reflection_map, rVec);

		reflection =
			reflectionMap.rgb *							// reflection cube sample
			reflection_color *								// RGB reflection color from material
			reflection_intensity *						// scalar reflection intensity from material
			control_mask.b *								// control mask reflection intensity channel 
			shader_data.common.shaderValues.x * // Fresnel Intensity
			reflectionMap.a;								// intensity scalar from reflection cube

		reflection = lerp(reflection, reflection * diffuse_reflection_mask, diffuse_mask_reflection);
        
        // apply reflection only to base layer
        reflection *= 1-blend;
        
		out_color.rgb += reflection;		
	}

   
	return out_color;
}


#include "techniques.fxh"