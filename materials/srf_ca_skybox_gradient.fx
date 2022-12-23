//
// File:	 srf_blinn.fx
// Author:	 hocoulby
// Date:	 06/16/10
//
// Surface Shader - Standard Blinn 
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

DECLARE_FLOAT_WITH_DEFAULT(ramp_falloff,     "Ram Falloff", "", 1, 10, float(1.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(ramp_offset,     "Ram Offset", "", -1, 1, float(0.0));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(top_color,        "Top Color", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(bottom_color,     "Bottom Color", "", float3(0,0,0));
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
    
	float2 uv = pixel_shader_input.texcoord.xy;
    shader_data.common.albedo.rgb = lerp(top_color, bottom_color , saturate(pow(uv.y ,ramp_falloff) + ramp_offset));    
    shader_data.common.albedo.a = 1.0f;     
    
}



float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
    // input from s_shader_data 
    float4 albedo         = shader_data.common.albedo * si_intensity;
	return albedo;
	
}


#include "techniques.fxh"