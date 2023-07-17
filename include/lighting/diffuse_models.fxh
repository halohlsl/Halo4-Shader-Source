#if !defined(__LIGHTING_DIFFUSE_MODELS_FXH)
#define __LIGHTING_DIFFUSE_MODELS_FXH

#include "core/core_types.fxh"
#include "lighting/vmf.fxh"
#include "lighting/sh.fxh"



////////////////////////////////////////////////////////////////////////////////
// Lambert diffuse model (N·L)

void calc_diffuse_lambert_initializer(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal)
{
    diffuse = 0.0f;
    #if defined(xenon) || (DX_VERSION == 11)
        diffuse += VMFDiffuse(common.lighting_data.vmf_data, common.normal, common.geometricNormal, common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, common.lighting_mode);
        diffuse = CompSH(common, diffuse, normal);
#if defined(DEBUG)
        diffuse += ps_debug_ambient_intensity.xyz;
#endif
    #endif

}

void calc_diffuse_lambert_inner_loop(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    int index)
{
    float3 direction= common.lighting_data.light_direction_specular_scalar[index].xyz;
    float4 intensity_diffuse_scalar= common.lighting_data.light_intensity_diffuse_scalar[index];

    float diffuse_ndotl = saturate(dot(direction, normal));

    diffuse += diffuse_ndotl * intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;
}

// build the loop
MAKE_ACCUMULATING_LOOP_1(float3, calc_diffuse_lambert, float3, MAX_LIGHTING_COMPONENTS);



////////////////////////////////////////////////////////////////////////////////
// Lambert Warp diffuse model

void calc_diffuse_lambert_wrap_initializer(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float wrap,
    const in bool applyShadow)
{
    diffuse = 0.0f;
    #if defined(xenon) || (DX_VERSION == 11)
	if (common.lighting_mode != LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE && common.lighting_mode != LM_PER_PIXEL_SIMPLE)
	{
        	diffuse += VMFDiffuseWrap(common.lighting_data.vmf_data, normal, common.lighting_data.shadow_mask.g, common.lighting_data.savedAnalyticScalar, wrap, applyShadow);
        	diffuse = CompSH(common, diffuse, normal);
	}
	#if defined(DEBUG)
		diffuse += ps_debug_ambient_intensity.xyz;
	#endif
    #endif
}


void calc_diffuse_lambert_wrap_inner_loop(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float wrap,
    const in bool applyShadow,
    int index)
{
    float3 direction= common.lighting_data.light_direction_specular_scalar[index].xyz;
    float4 intensity_diffuse_scalar= common.lighting_data.light_intensity_diffuse_scalar[index];
    
    if (applyShadow)
    {
    	intensity_diffuse_scalar *= common.lighting_data.shadow_mask.b;
    }

    float diffuse_ndotl = max(0, (dot(direction, normal) + wrap) / (1 + wrap));

    diffuse += diffuse_ndotl * intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;
}

// build the loop
MAKE_ACCUMULATING_LOOP_3(float3, calc_diffuse_lambert_wrap, float3, float, bool, MAX_LIGHTING_COMPONENTS);




////////////////////////////////////////////////////////////////////////////////
// Lambert diffuse "fill" model (N·L)

// [hcoulby: 06/03/2011]
// Not adding SH Lighting to this function becuase I will be removing it soon
void calc_diffuse_lambert_fill_initializer(
            inout float3 diffuse,
            const in s_common_shader_data common,
            const in float3 normal,
            const in float fill_vmf_direct,
            const in float fill_vmf_indirect)
{
    diffuse = 0.0f;

    #if defined(xenon) || (DX_VERSION == 11)
	if (common.lighting_mode != LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE && common.lighting_mode != LM_PER_PIXEL_SIMPLE)
	{
        diffuse += VMFDiffuseFill(
                        common.lighting_data.vmf_data,
                        normal,
                        fill_vmf_direct,
                        fill_vmf_indirect);
	}
	#if defined(DEBUG)
        diffuse += ps_debug_ambient_intensity.xyz;
	#endif
    #endif

}

void calc_diffuse_lambert_fill_inner_loop(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float fill,
    const in float roughness,
    int index)
{

    float3 direction= common.lighting_data.light_direction_specular_scalar[index].xyz;
    float4 intensity_diffuse_scalar= common.lighting_data.light_intensity_diffuse_scalar[index];

    float diffuse_ndotl = saturate(dot(direction, normal));

    // [hcoulby-12/2/2010] Square the diffuse falloff with a compensation factor 1.5
    // this macro is defined in core.fxh. compensation factor set in core_<platform>.fxh
    SQUARE_FALLOFF_DIRECT(diffuse_ndotl);

    diffuse += diffuse_ndotl * intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;

}

// build the loop
MAKE_ACCUMULATING_LOOP_3(float3, calc_diffuse_lambert_fill, float3, float, float, MAX_LIGHTING_COMPONENTS);





////////////////////////////////////////////////////////////////////////////////
// Lambert diffuse model (N·L) with Back Lighting

void calc_diffuse_backlighting_initializer(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float3 translucence)
{
    diffuse = 0.0f;
    #if defined(xenon) || (DX_VERSION == 11)
	if (common.lighting_mode != LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE && common.lighting_mode != LM_PER_PIXEL_SIMPLE)
	{
        diffuse += VMFDiffuse_BackLighting( common.lighting_data.vmf_data, normal, common.view_dir_distance.xyz, translucence);
        diffuse = CompSH(common, diffuse, normal);
	}
	#if defined(DEBUG)
        diffuse += ps_debug_ambient_intensity.xyz;
	#endif
    #endif
}

void calc_diffuse_backlighting_inner_loop(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float3 translucence,
    int index)
{
    float3 direction= common.lighting_data.light_direction_specular_scalar[index].xyz;
    float4 intensity_diffuse_scalar= common.lighting_data.light_intensity_diffuse_scalar[index];
    float3 view = common.view_dir_distance.xyz;
    float ldotv = saturate(dot(direction, view));

    float diffuse_ndotl  = saturate(dot(direction, normal));

    // [hcoulby-12/2/2010] Square the diffuse falloff with a compensation factor *= 1.5
    // this macro is defined in core.fxh. compensation factor set in core_<platform>.fxh
    SQUARE_FALLOFF_DIRECT(diffuse_ndotl);


    float  diffuse_back   = (1-diffuse_ndotl);
    float3 diffuse_back_color = (diffuse_back + ldotv) * translucence;
    diffuse += (diffuse_ndotl + diffuse_back_color) * intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;

}

// build the loop
MAKE_ACCUMULATING_LOOP_2(float3, calc_diffuse_backlighting, float3, float3, MAX_LIGHTING_COMPONENTS);



////////////////////////////////////////////////////////////////////////////////
// simple lighting model, returning just the total intensity


void calc_simple_lighting_initializer(
    inout float3 diffuse,
    const in s_common_shader_data common
    )
{
    diffuse = 0.0f;

#if defined(xenon) || (DX_VERSION == 11)
	if (common.lighting_mode != LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE && common.lighting_mode != LM_PER_PIXEL_SIMPLE)
	{
		diffuse += VMFSimpleLighting(common.lighting_data.vmf_data, common.normal);
	}
	#if defined(DEBUG)
		diffuse += ps_debug_ambient_intensity.xyz;
	#endif
#endif

}

void calc_simple_lighting_inner_loop(
    inout float3 diffuse,
    const in s_common_shader_data common,
    int index)
{
    float4 intensity_diffuse_scalar = common.lighting_data.light_intensity_diffuse_scalar[index];
    diffuse += intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;
}

// build the loop
MAKE_ACCUMULATING_LOOP(float3, calc_simple_lighting, MAX_LIGHTING_COMPONENTS);



////////////////////////////////////////////////////////////////////////////////
// A simple diffuse skin model

void calc_diffuse_lambert_skin_basic_initializer(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float3 scatter_color,
    const in float wrap)
{
    diffuse = 0.0f;
    #if defined(xenon) || (DX_VERSION == 11)
	if (common.lighting_mode != LM_PER_PIXEL_FLOATING_SHADOW_SIMPLE && common.lighting_mode != LM_PER_PIXEL_SIMPLE)
	{
        diffuse += VMFSkinSimple(common.lighting_data.vmf_data, normal, scatter_color,wrap);
        diffuse = CompSH(common, diffuse, normal);
	}
	#if defined(DEBUG)
        diffuse += ps_debug_ambient_intensity.xyz;
	#endif
    #endif
}

void calc_diffuse_lambert_skin_basic_inner_loop(
    inout float3 diffuse,
    const in s_common_shader_data common,
    const in float3 normal,
    const in float3 scatter_color,
    const in float wrap,
    int index)
{
    float3 direction= common.lighting_data.light_direction_specular_scalar[index].xyz;
    float4 intensity_diffuse_scalar= common.lighting_data.light_intensity_diffuse_scalar[index];

    float diffuse_ndotl = saturate(dot(direction, normal));

    // [hcoulby-12/2/2010] Square the diffuse falloff with a compensation factor *= 1.5
    SQUARE_FALLOFF_DIRECT(diffuse_ndotl);

    float3 diffuse_scatter = smoothstep(-wrap,1.0f,diffuse_ndotl) - smoothstep(0.0f,1.0f,diffuse_ndotl) ;
    diffuse_scatter = max(0.0f,diffuse_scatter);// * diffuse_ndotl ;
    diffuse_scatter = diffuse_scatter * scatter_color;

    diffuse += (diffuse_ndotl + diffuse_scatter) * intensity_diffuse_scalar.rgb * intensity_diffuse_scalar.a;

}

// build the loop
MAKE_ACCUMULATING_LOOP_3(float3, calc_diffuse_lambert_skin_basic, float3, float3, float, MAX_LIGHTING_COMPONENTS);


#endif