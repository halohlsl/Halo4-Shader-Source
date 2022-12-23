#if defined(TENSION)
#define FULL_VERTEX_COLOR
#endif

#define MATERIAL_CONTROLS_SHADOW_MASK_READOUT

// no sh airporbe lighting needed for constant shader
#include "core/core.fxh"
#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"
#include "operations/color.fxh"

#if defined(TENSION)
DECLARE_BOOL_WITH_DEFAULT(show_tension, "Show Tension Only", "", false);
#include "next_bool_parameter.fxh"
#endif


DECLARE_SAMPLER_NO_TRANSFORM( color_map, "Color Map", "Color Map", "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER_NO_TRANSFORM( control_map_SpGlSc, "ControlMap SpGlSc", "ControlMap SpGlSc",  "shaders/default_bitmaps/bitmaps/default_diff.tif")
#include "next_texture.fxh"

DECLARE_SAMPLER_NO_TRANSFORM( normal_map, "Normal Map", "Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"


// Diffuse Lighting
DECLARE_RGB_COLOR_WITH_DEFAULT(albedo_tint,		"Color Tint", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_intensity,	"Diffuse Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"


// Scatter Settings
DECLARE_RGB_COLOR_WITH_DEFAULT(scatter_color,	"Scatter Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scatter_intensity,	"Scatter Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(scatter_mix_albedo,	"Scatter Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(wrap_diffuse,	"Wrap Diffuse Lighting", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(wrap_scatter,	"Wrap Scatter Lighting", "", 0, 1, float(0.0));
#include "used_float.fxh"


// Specular
DECLARE_RGB_COLOR_WITH_DEFAULT(specular_color,		"Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_intensity,		"Specular Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_min,		"Specular Power White", "", 0, 1, float(0.01));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_power_max,		"Specular Power Black", "", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(specular_mix_albedo,		"Specular Mix Albedo", "", 0, 1, float(0.0));
#include "used_float.fxh"
// Glancing specular
DECLARE_RGB_COLOR_WITH_DEFAULT(glancing_specular_color,"Glancing Specular Color", "", float3(1,1,1));
#include "used_float3.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_power,			"Fresnel Power", "", 0, 10, float(5.0));
#include "used_float.fxh"



// Detail Normal Map
#if defined(DETAIL_NORMAL)
	DECLARE_SAMPLER(normal_detail_map,		"Detail Normal Map", "Detail Normal Map", "shaders/default_bitmaps/bitmaps/default_normal.tif");
	#include "next_texture.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_max,	"Detail Start Dist.", "detail_normals", 0, 1, float(5.0));
	#include "used_float.fxh"
	DECLARE_FLOAT_WITH_DEFAULT(normal_detail_dist_min, 	"Detail End Dist.", "detail_normals", 0, 1, float(1.0));
	#include "used_float.fxh"
#endif


/*
DECLARE_RGB_COLOR_WITH_DEFAULT(scatter_color,	"Scatter Color", "", float3(1,1,1));
#include "used_float3.fxh"

DECLARE_FLOAT_WITH_DEFAULT(wrap_hard,	"Wrap Hard", "", 0, 1, float(0.0));
#include "used_float.fxh"

DECLARE_FLOAT_WITH_DEFAULT(wrap_soft,	"Wrap Soft", "", 0, 1, float(0.0));
#include "used_float.fxh"
*/

#if defined(TENSION)

#if defined(GENERIC_COLOR_WRINKLE)
	DECLARE_SAMPLER_NO_TRANSFORM( color_map_wrinkle, "Color Map Wrinkle", "Color Map Wrink;e", "shaders/default_bitmaps/bitmaps/default_50_diff.tif")
	#include "next_texture.fxh"
#else
	DECLARE_SAMPLER_NO_TRANSFORM( color_map_wrinkle, "Color Map Wrinkle", "Color Map Wrink;e", "shaders/default_bitmaps/bitmaps/default_diff.tif")
	#include "next_texture.fxh"
#endif

DECLARE_SAMPLER_NO_TRANSFORM( normal_map_wrinkle, "Normal Map Wrinkle", "Normal Map Wrinkle", "shaders/default_bitmaps/bitmaps/default_normal.tif")
#include "next_texture.fxh"

#endif



struct s_shader_data
{
	s_common_shader_data common;
    float3 normal_geo;
};



float3 Scatter(float ndotl, float3 color, float wrap){
    float3 diffuse_scatter = smoothstep(-wrap,1.0f,ndotl) - smoothstep(0.0f,1.0f,ndotl);
    diffuse_scatter = max(0.0f,diffuse_scatter);
    diffuse_scatter = diffuse_scatter * color;
    return diffuse_scatter;
}


void pixel_pre_lighting(
		in s_pixel_shader_input pixel_shader_input,
		inout s_shader_data shader_data)
{
	float2 uv		= pixel_shader_input.texcoord.xy;
    float2 color_map_uv      = transform_texcoord(uv, float4(1, 1, 0, 0));


#if defined(TENSION)
	// red  = compression
	// blue = stretch
    float2 tension = shader_data.common.vertexColor.rg;
#if !defined(cgfx)
	tension.r = 1.0f - tension.r;
#endif

	float4 colorBase    = sample2DGamma(color_map,  uv);
	float4 colorWrinkle = sample2DGamma(color_map_wrinkle,  uv);

	#if defined GENERIC_COLOR_WRINKLE
		colorWrinkle.rgb = lerp(float3(0.25, 0.25, 0.25), colorWrinkle.rgb, min(tension.r,1));
		shader_data.common.albedo.rgb = color_overlay(colorBase.rgb, colorWrinkle.rgb);		
	#else
		shader_data.common.albedo.rgb = lerp(colorBase.rgb, colorWrinkle.rgb, min(tension.r,1));	
	#endif
	

	

	//alpha
	shader_data.common.shaderValues.x = colorBase.a;
	shader_data.common.shaderValues.y = min(tension.r,1);
	
#else

    float4 color_map_sampled = sample2DGamma(color_map, color_map_uv);
    shader_data.common.albedo.rgb = color_map_sampled;
	shader_data.common.shaderValues.x = color_map_sampled.a;

#endif

    shader_data.common.albedo.rgb *= albedo_tint;
	shader_data.common.albedo.a = shader_data.common.shaderValues.x;


// Normals
    float2 normal_map_uv	  = transform_texcoord(uv, float4(1, 1, 0, 0));

#if defined(TENSION)
	float3 normal_base     = sample_2d_normal_approx(normal_map,  uv);
	float3 normal_wrinkle  = sample_2d_normal_approx(normal_map_wrinkle,  uv);

	shader_data.common.normal.xy = normal_base.xy + tension.r * normal_wrinkle.xy;
	shader_data.common.normal.z = sqrt(saturate(1.0f + dot( shader_data.common.normal.xy, -shader_data.common.normal.xy)));

#else
    shader_data.common.normal = sample_2d_normal_approx(normal_map, normal_map_uv);
#endif

		
#if defined(DETAIL_NORMAL)
		// Composite detail normal map onto the base normal map
		float2 detail_uv = transform_texcoord(uv, normal_detail_map_transform);
		shader_data.common.normal = CompositeDetailNormalMap(
															shader_data.common,
															 shader_data.common.normal,
															normal_detail_map,
															detail_uv,
															normal_detail_dist_min,
															normal_detail_dist_max);
#endif

		// Transform from tangent space to world space
		shader_data.common.normal = mul(shader_data.common.normal, shader_data.common.tangent_frame);


#if defined(TENSION)
	if (show_tension)
	{
		shader_data.common.albedo.rgb = float3(shader_data.common.vertexColor.r, shader_data.common.vertexColor.g, 0.0);
	}
#endif


}



// lighting
float4 pixel_lighting(
        in s_pixel_shader_input pixel_shader_input,
	    inout s_shader_data shader_data)
{

	float2 uv		= pixel_shader_input.texcoord.xy;

    // sample control map
    float4 control_mask = sample2DGamma(control_map_SpGlSc,  uv);


// blinn specular lighting
    float3 specular = 0.0f;
    // pre-computing roughness with independent control over white and black point in gloss map
    float power = calc_roughness(control_mask.g, specular_power_min, specular_power_max );
	// using blinn specular model
    calc_specular_blinn(specular, shader_data.common, shader_data.common.normal, shader_data.common.albedo.a, power);

    float3 specular_col = CalcSpecularColor(-shader_data.common.view_dir_distance.xyz,
                                            shader_data.common.normal,
                                            shader_data.common.albedo.rgb,
                                            specular_mix_albedo,
                                            specular_color,
                                            glancing_specular_color,
                                            fresnel_power);

    // modulate by mask, color, and intensity
    specular *= control_mask.r * specular_col * specular_intensity;


// simple diffuse scattering
    float3 diffuse = 0.0f;  // final diffuse lighting

    // hard lighting use the high res normal and detail normal map
    float3 diffuse_hard = 0.0f;
    calc_diffuse_lambert_wrap(diffuse_hard, shader_data.common, shader_data.common.normal, wrap_diffuse, true);
    diffuse_hard *= diffuse_intensity;

    // mask specular
    specular *= diffuse_hard;

    // aproximates scattered light
    float3 diffuse_soft = 0.0f;
    calc_diffuse_lambert_wrap(diffuse_soft, shader_data.common, shader_data.common.geometricNormal, wrap_scatter, true);
    diffuse_soft *= diffuse_intensity;


    // difference between two lobes
    float diffuse_diff = saturate(diffuse_soft-diffuse_hard);
    diffuse_diff = smoothstep(0,1,diffuse_diff);
    diffuse_diff *= scatter_intensity * control_mask.b;


    // surface colors
    float3 diffuse_hard_color = diffuse_hard * shader_data.common.albedo.rgb;
	float3 diffuse_soft_color = diffuse_soft * shader_data.common.albedo.rgb;
    float3 scatter_color_mix  = lerp(scatter_color, shader_data.common.albedo.rgb, scatter_mix_albedo);


    // layer in scatter color
    float3 scatColor = scatter_color_mix*float3(0.01,0.01,0.01);
    scatColor = pow(saturate(scatColor * 2), 0.25);
    float3 diffuse_mixture = lerp(diffuse_hard_color, diffuse_soft_color,  scatColor);

    diffuse_mixture = lerp(diffuse_mixture, diffuse_soft_color*scatter_color_mix, diffuse_diff);

    diffuse = diffuse_mixture + (diffuse_diff * scatter_color_mix * shader_data.common.albedo.rgb );

	
    float4 out_color = 0.0f;
    out_color.rgb = diffuse + specular;


#if defined(TENSION)
    // Vertex Occlusion from PCA data
    //out_color.rgb *= shader_data.common.vertexColor.g;
#endif

	out_color.a = shader_data.common.shaderValues.x;


#if defined(TENSION)
	if (show_tension)
	{
		out_color.rgb = shader_data.common.albedo.rgb;
	}
#endif

	
    return out_color;
}


#include "techniques.fxh"
