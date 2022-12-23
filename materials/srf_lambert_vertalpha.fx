//
// File:	 srf_lambert_vertalpah.fx
// Author:	 hocoulby
// Date:	 12/04/10
//
// Surface Shader - uses the vertex color set as the alpha value of the shader.
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
DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Texture controls
DECLARE_FLOAT_WITH_DEFAULT(color_tile_u, 			"Color Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(color_tile_v, 			"Color Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_u, 			"Normal Tile U", "", 1, 10, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(normal_tile_v, 			"Normal Tile V", "", 1, 10, float(1.0));
#include "used_float.fxh"


// Diffuse
DECLARE_RGB_COLOR_WITH_DEFAULT(diffuse_color,		"Diffuse Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,		"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


#if defined(HEIGHT_MASK)
    DECLARE_FLOAT_WITH_DEFAULT(height_influence, "Height Map Influence", "", 0, 1, float(1.0));
    #include "used_float.fxh"
    DECLARE_FLOAT_WITH_DEFAULT(threshold_softness, "Height Map Threshold Softness", "", 0.01, 1, float(0.1));
    #include "used_float.fxh"
#endif

#if defined(ALPHA_CLIP)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_alpha_clip = true;>
DECLARE_FLOAT_WITH_DEFAULT(clip_threshold,		"Clipping Threshold", "", 0, 1, float(0.3));
#include "used_float.fxh"
#endif


struct s_shader_data
{
	s_common_shader_data common;
    float alpha;

};


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv= pixel_shader_input.texcoord.xy;

    {// Sample color map.
		float2 color_map_uv 	   = transform_texcoord(uv, float4(color_tile_u, color_tile_v, 0, 0));
		shader_data.common.albedo = sample2DGamma(color_map, color_map_uv);
		
		float out_alpha = 1.0f;
		
		#if defined(HEIGHT_MASK)
			// When using a height mask we solve alpha here, as opposed to pixel_lighting
			out_alpha = shader_data.common.vertexColor.a;
			
			out_alpha = saturate( (shader_data.common.vertexColor.a - ( 1 - shader_data.common.albedo.a )) / max(0.001, threshold_softness)  );
			out_alpha = lerp( shader_data.common.vertexColor.a, out_alpha, height_influence );
		#endif
		
		#if defined(ALPHA_CLIP)
			// Tex kill pixel
			clip(out_alpha - clip_threshold);
		#endif
		
		shader_data.common.albedo.a = out_alpha;
    }


    {// Sample normal map.
    	float2 normal_map_uv	  = transform_texcoord(uv, float4(normal_tile_u, normal_tile_v, 0, 0));
    	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
    	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);
    }

}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
    // input from s_shader_data
    float4 albedo         = shader_data.common.albedo;


    float3 diffuse = 0.0f;
    { // Compute Diffuse

        // using standard lambert model
        calc_diffuse_lambert(diffuse, shader_data.common, shader_data.common.normal);

        // modulate by albedo, color, and intensity
    	diffuse *= albedo.rgb * diffuse_color * diffuse_intensity;
    }

    //.. Finalize Output Color
    float4 out_color;
    
    out_color.rgb = diffuse;
    
    #if defined(HEIGHT_MASK)
	// When using height mask the vertex color is applied during pre_lighting, so we just grab it here
	out_color.a = albedo.a;
    #else
	out_color.a   = shader_data.common.vertexColor.a;
    #endif

    return out_color;
}


#include "techniques.fxh"