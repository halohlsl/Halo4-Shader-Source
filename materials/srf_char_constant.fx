// Author:hocoulby
// Date:03/28/11
//
// Character Surface Shader - Constant Self Illumination 
//
// Copyright (c) 343 Industries. All rights reserved.
//

#define DISABLE_LIGHTING_TANGENT_FRAME
#define DISABLE_LIGHTING_VERTEX_COLOR

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,"Color  Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(si_intensity,	"SelfIllum Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"



struct s_shader_data {
	s_common_shader_data common;
};


void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	    shader_data.common.albedo.rgb = albedo_tint;
		shader_data.common.albedo.a = 1.0;

}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	//..  Output Color
    float4 out_color = float4(0,0,0,1);

	// self illum
	if (AllowSelfIllum(shader_data.common)) {	 	
		out_color.rgb = shader_data.common.albedo.rgb * si_intensity;
		shader_data.common.selfIllumIntensity = GetLinearColorIntensity(out_color.rgb);
	}

	return out_color;
}


#include "techniques.fxh"