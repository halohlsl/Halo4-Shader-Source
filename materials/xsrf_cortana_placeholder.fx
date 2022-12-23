// Author:	 hocoulby
//
// Cortana Hologram Shader
//
// Copyright (c) 343 Industries. All rights reserved.
//

//#define FORCE_SINGLE_PASS
#define DISABLE_EXPOSURE
#define DISABLE_ATMOSPHERICS
#define DISABLE_VMF
#define DISABLE_SH
#define DISABLE_ANALYTIC_LIGHT


#if !defined(TENSION)
	#define DISABLE_VERTEX_COLOR
#endif

#define SPECULAR

#if defined(TENSION) 
	#define FULL_VERTEX_COLOR
#endif

#if !defined(NO_BODY_MASK)
#define BODY_MASK
#endif

// Core Includes
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"

//.. Artistic Parameters

// Texture Samplers
DECLARE_SAMPLER_GRADIENT( lighting_ramp, "Key Gradient Map", "Key Gradient Map", "shaders/default_bitmaps/bitmaps/default_ramp_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

#if !defined(IRIS_NORMALS)

DECLARE_SAMPLER( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

#else

DECLARE_SAMPLER_NO_TRANSFORM( iris_in_normal_map, "Iris In Normal Map", "Iris In Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
DECLARE_SAMPLER_NO_TRANSFORM( iris_out_normal_map, "Iris Out Normal Map", "Iris Out Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

#endif


DECLARE_SAMPLER( body_mask, "Body Control Mask", "Body Control Mask", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

#if defined(DATAFLOW)
DECLARE_SAMPLER( dataflow_map, "Data Map", "Data Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"
#endif

#if defined(TENSION) && !defined(AMBIENT_MASK)
DECLARE_SAMPLER_NO_TRANSFORM( normal_map_wrinkle, "Normal Map Wrinkle", "Normal Map Wrinkle", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"
#endif

DECLARE_RGB_COLOR_WITH_DEFAULT(srf_color, "Surface Color", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(maximum_opacity, "Maximum Opacity", "", 0, 1, float(1.0f));
#include "used_float.fxh"

#if defined(BODY_MASK)

DECLARE_FLOAT_WITH_DEFAULT(surface_opacity, "Surface Opacity", "", 0, 1, float(0.8));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(tattoo_opacity, "Tattoo Opacity", "", 0, 1, float(0.05));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(circuit_opacity_01, "Circutry Opacity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(circuit_opacity_02, "Circutry 2 Opacity", "", 0, 1, float(0.8));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(tat_color,		"Tattoo Color", "", float3(0.492,0.551,0.627));
#include "used_float3.fxh"
#include "used_float.fxh"		// force better alignment

DECLARE_RGB_COLOR_WITH_DEFAULT(cir_color,		"Circutry Color", "", float3(1,1,1));
#include "used_float3.fxh"
#include "used_float.fxh"		// force better alignment

DECLARE_RGB_COLOR_WITH_DEFAULT(cir_02_color,		"Circutry 2 Color", "", float3(1,1,1));
#include "used_float3.fxh"
#include "used_float.fxh"		// force better alignment

#endif

#if defined(IRIS_NORMALS)

DECLARE_SAMPLER_NO_TRANSFORM(eye_control_map, "Eye Control Map", "Eye Control Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

#if defined(REFLECTION)
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Map", "Reflection Map", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
#endif


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

DECLARE_FLOAT_WITH_DEFAULT(iris_spec_rampancy,	"Iris Spec Rampancy", "Iris Spec Rampancy", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(iris_spec_dist_fade_off,	"Iris Dist Fade Off", "Iris Dist Fade Off", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_spec_dist_max,	"Iris Spec Start Dist.", "detail_normals", 0, 1, float(0.1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iris_spec_dist_min, 	"Iris Spec End Dist.", "detail_normals", 0, 1, float(0.35));
#include "used_float.fxh"


#endif


#if defined(SPECULAR)
	#if defined(BODY_MASK)
		DECLARE_FLOAT_WITH_DEFAULT(specular_intensity_tat,	"Specular Intensity Tattoos", "", 0, 1, float(0.8));
		#include "used_float.fxh"
		DECLARE_FLOAT_WITH_DEFAULT(specular_intensity_cir,	"Specular Intensity Circuts", "", 0, 1, float(1.0));
		#include "used_float.fxh"
		DECLARE_FLOAT_WITH_DEFAULT(specular_power_tat,		"Specular Power Tattoos", "", 10, 1000, float(5.0));
		#include "used_float.fxh"
		DECLARE_FLOAT_WITH_DEFAULT(specular_power_cir,		"Specular Power Circuts", "", 10, 1000, float(40.0));
		#include "used_float.fxh"
	#else
		DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(0.8));
		#include "used_float.fxh"
		DECLARE_FLOAT_WITH_DEFAULT(specular_power,			"Specular Power", "", 10, 1000, float(5.0));
		#include "used_float.fxh"
	#endif

	#if defined(HAIR_SPECULAR)
		DECLARE_SAMPLER(control_map_hair,		"Control Map SpShift", "Control Map SpShift", "shaders/default_bitmaps/bitmaps/default_hair_diff.tif")
		#include "next_texture.fxh"
		DECLARE_FLOAT_WITH_DEFAULT(specular_shift,			"Specular Shift", "", -1, 1, float(-0.45));
		#include "used_float.fxh"
		DECLARE_FLOAT_WITH_DEFAULT(albedo_mask_specular,		"Albedo Mask Specular", "", 0, 1, float(1.0));
		#include "used_float.fxh"
	#endif
#endif


#if defined(FRESNEL)
	DECLARE_FLOAT_WITH_DEFAULT(fresnel_power, "Frensnel Power", "", 0, 20, float(0.5));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(fresnel_in_min, "Frensnel minIn", "", 0, 0, float(0.1));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(fresnel_in_max, "Frensnel maxIn", "", 0, 1, float(10.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(fresnel_maxOut, "Frensnel maxOut", "", 0, 1, float(30.0));
	#include "used_float.fxh"
#endif


#if defined(DATAFLOW)
DECLARE_RGB_COLOR_WITH_DEFAULT(data_flow_color,	"Dataflow Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(data_flow_intensity,	"Data Flow Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(data_burst_reference, "Data Burst Reference", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(data_burst_tightness, "Data Burst Tightness", "", 1, 2000, float(1500.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(threshold_min, "threshold_min", "", 0, 1, float(0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(threshold_max, "threshold_max", "", 0, 1, float(1));
#include "used_float.fxh"

#endif


DECLARE_FLOAT_WITH_DEFAULT(lgt_key_intensity, "Key Light Intensity", "", 0, 2, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_intensity, "Fill Light Intensity", "", 0, 2, float(0.25));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_intensity, "Rim Light Intensity", "", 0, 2, float(0.8));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(lgt_key_back_intensity, "Key Light Backside Intensity", "", 0, 2, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_back_intensity, "Fill Light Backside Intensity", "", 0, 2, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_back_intensity, "Rim Light Backside Intensity", "", 0, 2, float(0.0));
#include "used_float.fxh"


DECLARE_FLOAT_WITH_DEFAULT(lgt_key_forward_value, "lgt_key_forward", "", -1, 1, float(-20.525));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_key_right_value, "lgt_key_right", "", -1, 1, float(20.046));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_key_up_value, "lgt_key_up", "", -1, 1, float(20.691));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_forward_value, "lgt_fill_forward", "", -1, 1, float(27.482));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_right_value, "lgt_fill_right", "", -1, 1, float(-29.55));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_fill_up_value, "lgt_fill_up", "", -1, 1, float(20.324));
#include "used_float.fxh"


DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_forward_value, "lgt_rim_forward", "", -1, 1, float(100.547));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_right_value, "lgt_rim_right", "", -1, 1, float(100.667));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(lgt_rim_up_value, "lgt_rim_up", "", -1, 1, float(-180.837));
#include "used_float.fxh"

#if defined(AMBIENT_MASK)
DECLARE_FLOAT_WITH_DEFAULT(diffuse_ambient, "Diffuse Ambient", "", 0, 1, float(0.0f));
#include "used_float.fxh"

DECLARE_SAMPLER( body_mask_ambient, "Body Mask Ambient", "Body Mask Ambient", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

#endif




struct s_shader_data
{
	s_common_shader_data common;
#if defined(IRIS_NORMALS)
	float3 normal_iris_in;
	float3 normal_iris_out;
#endif
};


float3 calcNormalWithTension(
			const texture_sampler_2d normalMap,
			float2 uv_normalMap,
			const texture_sampler_2d wrinkleMap,
			float2 uv_wrinkleMap,
			float tension)
{
	float3 normal      = sample_2d_normal_approx(normalMap, uv_normalMap);
	float3 compression = sample_2d_normal_approx(wrinkleMap, uv_wrinkleMap);
	// red  = compression, blue = stretch
	compression = lerp(float3(0,0,0), compression, tension);
	normal.xy  += compression.xy;
	normal.z = sqrt(saturate(1.0f + dot( normal.xy, -normal.xy)));
	return normal;
}


void build_lighting_data( inout s_shader_data shader_data )
{
#if defined(cgfx)
	float4 objectToWorld[3];
	objectToWorld[0] = float4(0,-1,0,0);
	objectToWorld[1] = float4(0,0,1,0);
	objectToWorld[2] = float4(-1,0,0,0);

	// Hard coding the rig for maya to simulate the default in engine.
	lgt_key_forward_value = -100;
	lgt_key_right_value = 100;
	lgt_key_up_value = 100;

	lgt_fill_forward_value = -100;
	lgt_fill_right_value = -100;
	lgt_fill_up_value = -50;

	lgt_rim_forward_value = 100;
	lgt_rim_right_value = -50;
	lgt_rim_up_value = 50;

#else
	float4 objectToWorld[3] = {ps_material_generic_parameters[0], ps_material_generic_parameters[1], ps_material_generic_parameters[2]};
#endif

#if (DX_VERSION == 11) || defined(xenon)

	shader_data.common.lighting_data.light_direction_specular_scalar[0].xyz = objectToWorld[0].xyz;
	shader_data.common.lighting_data.light_direction_specular_scalar[1].xyz = objectToWorld[1].xyz;
	shader_data.common.lighting_data.light_direction_specular_scalar[2].xyz = objectToWorld[2].xyz;

#else

	shader_data.common.lighting_data.light_direction_specular_scalar[0].xyz =
		normalize(transform_vector(float3(lgt_key_forward_value, lgt_key_right_value, lgt_key_up_value), objectToWorld));

	shader_data.common.lighting_data.light_direction_specular_scalar[1].xyz =
		normalize(transform_vector(float3(lgt_fill_forward_value, lgt_fill_right_value, lgt_fill_up_value), objectToWorld));

	shader_data.common.lighting_data.light_direction_specular_scalar[2].xyz =
		normalize(transform_vector(float3(lgt_rim_forward_value, lgt_rim_right_value, lgt_rim_up_value), objectToWorld));


#endif

	shader_data.common.lighting_data.light_direction_specular_scalar[0].w = 1.0;
	shader_data.common.lighting_data.light_direction_specular_scalar[1].w = 1.0;
	shader_data.common.lighting_data.light_direction_specular_scalar[2].w = 1.0;

	shader_data.common.lighting_data.light_intensity_diffuse_scalar[0] = (float4)lgt_key_intensity;
	shader_data.common.lighting_data.light_intensity_diffuse_scalar[1] = (float4)lgt_fill_intensity;
	shader_data.common.lighting_data.light_intensity_diffuse_scalar[2] = (float4)lgt_rim_intensity;

	shader_data.common.lighting_data.light_component_count = 3;
}



void calc_diffuse(
			inout float3 ramp_color_out,
			const in s_shader_data shader_data,
			const in float ambient,
			const in float index)
{

    float3 direction = shader_data.common.lighting_data.light_direction_specular_scalar[index].xyz;
    float4 intensity_diffuse_scalar= shader_data.common.lighting_data.light_intensity_diffuse_scalar[index];

	float ndotl = saturate(dot(direction, shader_data.common.normal)) * intensity_diffuse_scalar.a;

	#if defined(AMBIENT_MASK)
		ndotl += saturate(1-ndotl) * ambient;
	#endif
	
	float2 ramp_lookup = transform_texcoord(float2(ndotl, 0.0), lighting_ramp_transform);
	float3 ramp_color = sample2DLOD(lighting_ramp, ramp_lookup, 0, true);

	ramp_color *= ramp_color;

	ramp_color_out = color_screen(ramp_color_out, ramp_color);
}


void calc_spec(
	inout float3 specular,
	const in s_common_shader_data common,
	const in float3 normal,
	const in float specular_mask,
	const in float specular_power,
	int index)
{

	float4 direction_specular_scalar= common.lighting_data.light_direction_specular_scalar[index];
	float3 intensity= common.lighting_data.light_intensity_diffuse_scalar[index].rgb;

	float3 H = normalize(direction_specular_scalar.xyz - common.view_dir_distance.xyz);
	float NdotH = saturate(dot(H, normal));

	float blinnPower = log2(NdotH);
	blinnPower = blinnPower * specular_power - log2(pi);
	blinnPower = exp2(blinnPower);

	specular+= specular_mask * blinnPower * intensity * direction_specular_scalar.w;
}

// compute the three lights for specular
void calc_specular_three(
	inout float3 specular,
	const in s_common_shader_data common,
	const in float3 normal,
	const in float specular_mask,
	const in float specular_power)
{
	calc_spec(specular, common, normal, specular_mask, specular_power, 0 ); // key
	calc_spec(specular, common, normal, specular_mask, specular_power, 1 ); // filll
	calc_spec(specular, common, normal, specular_mask, specular_power, 2 ); // rim
}


void calc_spec_hair(
	inout float3 specular,
	const in s_common_shader_data common,
	const in float3 direction,	// the vector used to calc the asio look. Currently srf_char_hair passes in the binormal.
	const in float specular_mask,
	const in float specular_power,
	int index)
{
	float4  direction_specular_scalar = common.lighting_data.light_direction_specular_scalar[index];
	float3 intensity = common.lighting_data.light_intensity_diffuse_scalar[index].rgb;
	float3 specular_result = HairSpecular(direction, common.view_dir_distance.xyz, direction_specular_scalar.xyz, specular_power);
	specular += specular_mask * intensity * direction_specular_scalar.w * specular_result;
}


void calc_spec_hair_three(
			inout float3 specular,
			const in s_common_shader_data common,
			const in float3 direction,
			const in float specular_mask,
			const in float specular_power)
{
	calc_spec_hair(specular, common, direction, specular_mask, specular_power, 0); // key
	calc_spec_hair(specular, common, direction, specular_mask, specular_power, 1 ); // fill
	calc_spec_hair(specular, common, direction, specular_mask, specular_power, 2 ); // rim
}




#if defined(DATAFLOW)
float GaussianDataFilter(float value, float reference)
{
   float x = frac(value - reference);
   return saturate(exp2(-data_burst_tightness * x * x));
}
#endif




// ALBEDO PASS
void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 uv= pixel_shader_input.texcoord.xy;

 
    // Sample color map.
	float2 color_map_uv      = transform_texcoord(uv, float4(1, 1, 0, 0));
	float4 color_map_sampled = sample2DGamma(color_map, color_map_uv);
	float  color_map_shadow  = color_map_sampled.a;

	shader_data.common.albedo.rgb = color_map_sampled.rgb;
	shader_data.common.shaderValues.x = color_map_sampled.a;
	shader_data.common.albedo.a = 1.0f;

	// Compute Normal
	float2 normal_map_uv	  = transform_texcoord(uv, float4(1, 1, 0, 0));

#if defined(TENSION) && !defined(AMBIENT_MASK)

	shader_data.common.normal = calcNormalWithTension(
										normal_map,
										normal_map_uv,
										normal_map_wrinkle,
										normal_map_uv,
#if !defined(cgfx)
										1.0 - shader_data.common.vertexColor.r);
#else
										shader_data.common.vertexColor.r);
#endif
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);


#elif defined(IRIS_NORMALS) // defined(TENSION)

	float3 normal_iris_in  = sample_2d_normal_approx(iris_in_normal_map, normal_map_uv);
	shader_data.normal_iris_in = normalize(mul(normal_iris_in, shader_data.common.tangent_frame));

	float3 normal_iris_out = sample_2d_normal_approx(iris_out_normal_map, normal_map_uv);
	shader_data.normal_iris_out = normalize(mul(normal_iris_out, shader_data.common.tangent_frame));

#else // defined(IRIS_NORMALS)

	shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
	shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);

#endif // !defined(TENSION) && !defined(IRIS_NORMALS)



}


// Shifts vector along the tangent
float3 shiftVector(float3 dirVector, float3 normal, float amount)
{
	float3 shifted = dirVector + amount * normal;
	return normalize(shifted);
}


float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
	        inout s_shader_data shader_data)
{
// input from s_shader_data
	float2 uv		= pixel_shader_input.texcoord.xy;
    float4 albedo   = shader_data.common.albedo;
	float4 out_color = 0.0f;

	// CORTANA SURFACE MASK
#if defined(BODY_MASK)
	float2 map_uv = transform_texcoord(uv, float4(1, 1, 0, 0));
	float4 cor_mask  = sample2D(body_mask, map_uv);
	float cor_mask_cir_01  = cor_mask.a;
	float cor_mask_cir_02  = cor_mask.r;
 	float cor_mask_tattoo  = cor_mask.g;
	float cor_mask_surface = cor_mask.b;
#endif

// DIFFUSE Lighting
	float3 diffuse = 0.0f;
	build_lighting_data(shader_data);
	
	float ambient_mask = 0;
	#if defined AMBIENT_MASK 
		ambient_mask = sample2DGamma(body_mask_ambient, transform_texcoord(uv, float4(1, 1, 0, 0)));
		ambient_mask *= diffuse_ambient;
	#endif
	
	calc_diffuse( diffuse, shader_data, ambient_mask, 0); // key
	calc_diffuse( diffuse, shader_data, ambient_mask, 1); // fill
	calc_diffuse( diffuse, shader_data, ambient_mask, 2); // rim


#if defined(SPECULAR)
	float3 specular = 0.0f;

#if defined(BODY_MASK)

	float3 specular_tat = 0.0f;
	float3 specular_circuts = 0.0f;

	//calc_specular_three(specular_tat, shader_data, shader_data.common.normal, cor_mask.a, specular_power_tat);
	calc_specular_three(specular_circuts, shader_data.common, shader_data.common.normal, cor_mask.a, specular_power_cir);

	float2 grad_uv_0 = float2(specular_circuts.r, 0.5);
	specular_circuts *= color_screen(diffuse, sample2DGamma(lighting_ramp, grad_uv_0).rgb);

	specular = (specular_circuts * specular_intensity_cir * (1-cor_mask_tattoo)); //(specular_tat * specular_intensity_tat)


#elif defined(IRIS_NORMALS)

	// sample the eye control map
	float4 control_map_sampled = sample2DGamma(eye_control_map, transform_texcoord(uv, float4(1, 1, 0, 0)));

	float3 spec_iris_in = 0.0f;
	calc_specular_three(
				spec_iris_in,
				shader_data.common,
				shader_data.normal_iris_in,
				shader_data.common.albedo.a,
				iris_in_spec_power);

	float3 spec_iris_in_col = lerp(iris_in_spec_color, shader_data.common.albedo.rgb, iris_in_albedo_mix);
	spec_iris_in *= spec_iris_in_col * iris_in_spec_intensity * control_map_sampled.r;

	float3 spec_iris_out = 0.0f;
	float iris_out_power = calc_roughness(control_map_sampled.b, iris_out_power_min, iris_out_power_max );
	calc_specular_three(
				spec_iris_out,
				shader_data.common,
				shader_data.normal_iris_out,
				shader_data.common.albedo.a,
				iris_out_power);

	float3 spec_iris_out_col = lerp(iris_out_spec_color, shader_data.common.albedo.rgb, iris_out_albedo_mix);
	spec_iris_out *= spec_iris_out_col * iris_out_spec_intensity * control_map_sampled.g;

	specular = spec_iris_in + spec_iris_out;
	
	// reduce the intensity of the iris specular when camera pulls out.  MN-58135
	float specDistAmt = float_remap( shader_data.common.view_dir_distance.w, iris_spec_dist_min, iris_spec_dist_max, 0, 1 );
	specDistAmt = lerp(specDistAmt, 1, iris_spec_rampancy); 
	specular *= lerp(saturate(specDistAmt), 1, iris_spec_dist_fade_off);
	
	
#elif defined(HAIR_SPECULAR)

	// compute the direction for ansio incorporating the normal map
	float3 T	= cross(shader_data.common.tangent_frame[1], shader_data.common.normal);
	float3 B	= cross(shader_data.common.normal,T);
	B *= sign(dot(B, shader_data.common.tangent_frame[1]));

	// flipping the binormal in maya to align with engine results
#if defined(cgfx)
	B = -B;
#endif
	// Control Map for Specular, Gloss, Reflection , SelfIllum
	float2 hair_control_map_uv	= transform_texcoord(uv, control_map_hair_transform);
	float4 hair_control			= sample2DGamma(control_map_hair, hair_control_map_uv);

	// first layer specular
	float3 dirVector1 = shiftVector(B, shader_data.common.normal, specular_shift + hair_control.g);
	calc_spec_hair_three(specular, shader_data.common, dirVector1, specular_intensity * hair_control.r, specular_power);

	// non-body-mask specular is multiplied with albedo
	specular *= lerp(1.0f, shader_data.common.albedo.rgb * diffuse, albedo_mask_specular);

#else

	// Basic blinn model
	calc_specular_three(specular, shader_data.common, shader_data.common.normal, specular_intensity, specular_power);

	// non-body-mask specular is multiplied with albedo
	specular *= shader_data.common.albedo.rgb;

#endif

#endif


#if defined(FRESNEL)
	float fresnel = 0.0f;
	float3 view = -shader_data.common.view_dir_distance.xyz;
	float  vdotn = saturate(dot(view, shader_data.common.normal));
	fresnel = pow(vdotn, fresnel_power);
	fresnel = 1-fresnel;
	fresnel = float_remap(fresnel, fresnel_in_min, fresnel_in_max, 0.0f, fresnel_maxOut);
	fresnel = saturate(fresnel * cor_mask.g);
#endif


// SURFACE color
	float3 surface_color;
#if defined(BODY_MASK)
	surface_color = lerp(diffuse, cir_color, cor_mask.a * diffuse);
	surface_color *= lerp(1.0, cir_color, cor_mask.a);
	surface_color *= lerp(1.0, tat_color, cor_mask.g);
#else
	surface_color = diffuse;
#endif
	surface_color *= shader_data.common.albedo.rgb;

// DATA scroll
#if defined(DATAFLOW)
	float2 data_uv = transform_texcoord(pixel_shader_input.texcoord.zw, dataflow_map_transform);
	float4 data_sample = sample2DGamma(dataflow_map, data_uv);


	float dataflow_value = data_flow_intensity;

	#if defined(BODY_MASK)
	dataflow_value = lerp(dataflow_value, dataflow_value*0.5, cor_mask.g);
	#endif

	float  data_flow = float_threshold(data_sample.r, 0.98, 1) * dataflow_value * GaussianDataFilter(data_sample.a+data_sample.g, data_burst_reference);
	float3 dataflow_color = data_flow * data_flow_color;
#endif


// ALPHA masking
	float srf_alpha = shader_data.common.shaderValues.x;

#if defined(BODY_MASK)

	cor_mask_surface = cor_mask_surface * surface_opacity;
	cor_mask_tattoo  = cor_mask_tattoo * tattoo_opacity;
	cor_mask_cir_01  = cor_mask_cir_01 * circuit_opacity_01;
	cor_mask_cir_02  = cor_mask_cir_02 * circuit_opacity_02;

	srf_alpha  =  saturate(cor_mask_tattoo +
					cor_mask_cir_01 +
					cor_mask_cir_02 +
					cor_mask_surface);

#endif

//..... OUTPUT COLOR

    out_color.rgb = surface_color;

#if defined(DATAFLOW)
	out_color.rgb += dataflow_color;
#endif

#if defined(SPECULAR)
	out_color.rgb += specular;
#endif

#if defined(REFLECTION)
    // reflection
    float3 reflection = 0.0f;
    float3 view = shader_data.common.view_dir_distance.xyz;
    float3 rVec = reflect(view, shader_data.normal_iris_out);

	float fresnel  = 1-saturate( dot(shader_data.normal_iris_in, -view) );

	reflection = sampleCUBEGamma(reflection_map, rVec);
    reflection *= control_map_sampled.g * fresnel * diffuse;

	if (AllowReflection(shader_data.common))
	{
		out_color.rgb += reflection;
	}
#endif

//..... OUTPUT ALPHA
	out_color.a  = srf_alpha;

#if defined(FRESNEL)
	out_color.a += fresnel;
#endif

#if defined(SPECULAR)
	#if !defined(HAIR_SPECULAR)
		out_color.a += specular;
	#endif
#endif


	clip(out_color.a - ps_material_generic_parameters[3].x);
	out_color.a = saturate(out_color.a) * maximum_opacity;

#if !defined(DISABLE_ORDER_INDEPENDENT_TRANSPARENCY) && !defined(cgfx)		// Maya does its own form of transparency sorting, so do not modify the output for OIT

	if (shader_data.common.lighting_mode != LM_PROBE)
	{
		// Maya does its own form of transparency sorting, so do not modify the output for OIT
		// Need to premultiply the alpha into the color to work with order-independent transparency
		out_color.rgb *= out_color.a;

		if (out_color.a <= 254.0 / 255.0)
		{
			out_color /= 3.0f;
		}
	}

#endif

	return out_color;
}



// Mark this shader as a hologram shader
#if !defined(DISABLE_ORDER_INDEPENDENT_TRANSPARENCY)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_hologram = true;>
#else
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_hologram = true; bool is_blended_hologram = true;>
#endif


#if !defined(cgfx)

#include "techniques_base.fxh"

#include "entrypoints/single_pass_lighting.fxh"

MAKE_TECHNIQUE(single_pass_per_vertex)
MAKE_TECHNIQUE(single_pass_single_probe)

#elif defined(cgfx)

#include "techniques_cgfx.fxh"


#endif 	// !defined(cgfx)
