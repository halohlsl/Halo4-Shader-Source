#if !defined(___FLOATING_SHADOW_FXH)
#define ___FLOATING_SHADOW_FXH

#include "core/core.fxh"

void add_analytic_light_to_light_data(
	inout s_common_shader_data shader_data)
{
#if (defined(xenon) || (DX_VERSION == 11)) && !defined(DISABLE_ANALYTIC_LIGHT)
	shader_data.lighting_data.light_direction_specular_scalar[shader_data.lighting_data.light_component_count] = float4(-ps_floating_shadow_light_direction.xyz, 1.0f);
	shader_data.lighting_data.light_intensity_diffuse_scalar[shader_data.lighting_data.light_component_count] = float4(ps_floating_shadow_light_intensity.xyz, 1.0/pi);
	++shader_data.lighting_data.light_component_count;
#endif
}



void add_analytic_light_to_light_data(
	inout s_common_shader_data shader_data,
	const in s_vmf_sample_data vmf_data,
	bool useFloatingShadow,
	bool useAnalyticLight)
{
#if (defined(xenon)  || (DX_VERSION == 11)) && !defined(DISABLE_ANALYTIC_LIGHT)

	// [mboulton 5/30/2012] Fix for boolean inheritance issue on dynamic objects : these booleans are set outside of the command buffer record, but if any other booleans are set inside (for instance by the material
	//  system) then they are welded in place for the life time of the command buffer, and cannot be fixed up.  So in those cases we use dynamic branching based on the floating point constants, which should be inherited
	//  with no problem.
	bool floatingShadowEnabled;
	bool analyticLightEnabled;
	bool analyticLightGoboEnabled;
	if (shader_data.lighting_mode == LM_PROBE || shader_data.lighting_mode == LM_PROBE_AO)
	{
		floatingShadowEnabled = dot(ps_floating_shadow_light_intensity.xyz, ps_floating_shadow_light_intensity.xyz) > 0.0f ? true : false;
		analyticLightEnabled = dot(ps_analytic_light_intensity.xyz, ps_analytic_light_intensity.xyz) > 0.0f ? true : false;
		
		// [jliechty 8/18/2012] We should be safe to disallow rotating gobo on this entry point.  
		// Common case perf should outweigh the risk of minor visual inconsistency.
		if (shader_data.lighting_mode == LM_PROBE_AO) 
		{ 
			analyticLightGoboEnabled = false; 
		} 
		else
		{
			analyticLightGoboEnabled = dot(ps_analytic_light_gobo_rotation_matrix_0.xyz, ps_analytic_light_gobo_rotation_matrix_0.xyz) > 0.0f ? true : false;		
		}
	}
	else
	{
		floatingShadowEnabled = useFloatingShadow;
		analyticLightEnabled = useAnalyticLight;
		
		// [jliechty 8/18/2012] Definitely do not need rotating gobo on forge objects.
		// And all instances of rotating gobos in the per-pixel IO case occur where LM_PER_PIXEL_ANALYTIC_HR is our entry point
		if (shader_data.lighting_mode == LM_PER_PIXEL_FORGE || shader_data.lighting_mode == LM_PER_PIXEL_ANALYTIC)
		{ 
			analyticLightGoboEnabled = false; 
		} 
		else
		{
			analyticLightGoboEnabled = ps_boolean_using_analytic_light_gobo;
		}
	}
	
	[branch]
	if (floatingShadowEnabled)
	{
		float analyticScalar = VMFGetAnalyticLightScalar(vmf_data);
		
		// Apply static shadow sharpening
		if (shader_data.lighting_mode == LM_PER_PIXEL)
		{
			analyticScalar = saturate(analyticScalar * ps_static_floating_shadow_sharpening.x - ps_static_floating_shadow_sharpening.y);
		}
		
		shader_data.lighting_data.light_direction_specular_scalar[shader_data.lighting_data.light_component_count] = float4(-ps_floating_shadow_light_direction.xyz, 1.0f);
		shader_data.lighting_data.light_intensity_diffuse_scalar[shader_data.lighting_data.light_component_count] = float4(analyticScalar * VMFGetAOScalar(vmf_data) * ps_floating_shadow_light_intensity.xyz, 1.0/pi);
		++shader_data.lighting_data.light_component_count;
	}
	else if (analyticLightEnabled)
	{
		float3 direction = normalize(ps_analytic_light_position - shader_data.position);

		// Optional gobo
		float3 gobo = ps_bsp_lightmap_scale_constants.x;		// Scale by per-bsp analytic lightmap factor
		if (analyticLightGoboEnabled)
		{
			float3 rotatedDirection;
			rotatedDirection.x = dot(direction, ps_analytic_light_gobo_rotation_matrix_0);
			rotatedDirection.y = dot(direction, ps_analytic_light_gobo_rotation_matrix_1);
			rotatedDirection.z = dot(direction, ps_analytic_light_gobo_rotation_matrix_2);
			gobo *= sampleCUBE(ps_dynamic_light_texture_cube, rotatedDirection);
		}

		shader_data.lighting_data.light_direction_specular_scalar[shader_data.lighting_data.light_component_count] = float4(direction, 1.0f);
		shader_data.lighting_data.light_intensity_diffuse_scalar[shader_data.lighting_data.light_component_count] = float4(VMFGetAnalyticLightScalar(vmf_data) * gobo * ps_analytic_light_intensity.xyz, 1.0/pi);
		++shader_data.lighting_data.light_component_count;
	}

#endif
}


#endif 	// !defined(___FLOATING_SHADOW_FXH)