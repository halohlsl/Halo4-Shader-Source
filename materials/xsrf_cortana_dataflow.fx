// Author:	 xsr_cortana_bridge
// Date:	 06/20/11
//
// Cortana Light Bridge
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader
#define DISABLE_SH


#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

// Texture Samplers
DECLARE_SAMPLER( codeflow_map, "CodeFlow Map", "Codeflow Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER(circuit_map, "Circuit Map", "Circuit Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(circuit_amount, "Circuit Amount", "", 0, 1, float(0.0));
#include "used_float.fxh"


DECLARE_RGB_COLOR_WITH_DEFAULT(data_flow_color,	"Dataflow Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(data_flow_intensity,	"Data Flow Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(data_burst_reference, "Data Burst Reference", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(data_burst_tightness, "Data Burst Tightness", "", 1, 2000, float(1500.0));
#include "used_float.fxh"



float GaussianDataFilter(float value, float reference)
{
   float x = frac(value - reference);
   return saturate(exp2(-data_burst_tightness * x * x));
}



struct s_shader_data
{
	s_common_shader_data common;
};


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv    		= pixel_shader_input.texcoord.xy;

	shader_data.common.albedo.rgb = 0.0f;
	shader_data.common.albedo.a   = 1.0;
    
	float2 data_uv = transform_texcoord(uv, codeflow_map_transform);
	float4 data_sample   = sample2DGamma(codeflow_map, data_uv);
	
	float data_flow = float_threshold(data_sample.r, 0.98, 1) * GaussianDataFilter(data_sample.a, data_burst_reference);

	float4 circuit = sample2D(circuit_map, transform_texcoord(uv, circuit_map_transform));	
	circuit *= circuit_amount;
	
	shader_data.common.albedo.rgb = circuit.rgb * data_sample.g;
	shader_data.common.shaderValues.x = data_flow * circuit.b * data_sample.g;

}




// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{
	float4 out_color = 1.0;
	
	float3 dataflow_color = shader_data.common.shaderValues.x * data_flow_color * data_flow_intensity;	
	shader_data.common.albedo.rgb += dataflow_color;	
	out_color.rgb = shader_data.common.albedo.rgb;
	
	out_color.a *= circuit_amount;
	return out_color;
}

#include "techniques.fxh"
