

#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "exposure.fxh"
#include "deform.fxh"
#include "light_apply_base_registers.fxh"
#include "ss_light_registers.fxh"


// default parameters

#ifndef COMBINE_LOBES
//#define COMBINE_LOBES(cosine_lobe, specular_lobe, albedo) (cosine_lobe * albedo.rgb + specular_lobe * albedo.a)
#define COMBINE_LOBES(cosine_lobe, specular_lobe, albedo) (cosine_lobe * albedo.rgb)
#endif // COMBINE_LOBES

#ifndef SHADER_ATTRIBUTES
#define SHADER_ATTRIBUTES /*[maxtempreg(3)]*/
#endif // SHADER_ATTRIBUTES

// light color should include exposure (and fog approximation?)
#ifndef LIGHT_COLOR
#define LIGHT_COLOR		(ps_screen_space_light_constants[4].rgb)
//#define LIGHT_COLOR		(ps_screen_space_light_constants[4.rgb * texCUBE(gel_sampler, light_to_fragment_lightspace.xyz).rgb)
//#define LIGHT_COLOR		(ps_screen_space_light_constants[4.rgb * tex2D(gel_sampler, light_to_fragment_lightspace.xy / light_to_fragment_lightspace.z).rgb)
//#define LIGHT_COLOR			float3(1.0f, 0.0f, 0.0f)
#endif // LIGHT_COLOR

#ifndef DEFORM
#define DEFORM				deform_tiny_position
//#define DEFORM					deform_tiny_position_projective
#endif // DEFORM

#define diffuse_light_cosine_raise 0.06f
#define pi 3.14159265358979323846

static float4x4 screen_to_relative_world=transpose(float4x4(ps_screen_space_light_constants[0], ps_screen_space_light_constants[1], ps_screen_space_light_constants[2], ps_screen_space_light_constants[3]));

// ps_screen_space_light_constants[4 is the light color tint

#define LIGHT_FAR_ATTENUATION_END	(ps_screen_space_light_constants[5].x)
#define LIGHT_FAR_ATTENUATION_RATIO	(ps_screen_space_light_constants[5].y)
#define LIGHT_COSINE_CUTOFF_ANGLE	(ps_screen_space_light_constants[5].z)
#define LIGHT_ANGLE_FALLOFF_RAIO	(ps_screen_space_light_constants[5].w)
#define LIGHT_ANGLE_FALLOFF_POWER	(ps_screen_space_light_constants[4].w)
#define CAMERA_TO_LIGHT				(ps_screen_space_light_constants[6].xyz)
#define CHEAP_ALBEDO_BLEND			(ps_screen_space_light_constants[9].w)

#define SPECULAR_COLOR_NORMAL 		(p_specular_material_properties[0])
#define SPECULAR_COLOR_GAZING 		(p_specular_material_properties[1])
#define MATERIAL_COEFF				(p_specular_material_properties[2])

LOCAL_SAMPLER2D(shadow_depth_map_1, 5);

float3 calculate_relative_world_position(float2 texcoord, float depth)
{
	float4 clip_space_position= float4(texcoord.xy, depth, 1.0f);
	float4 world_space_position= mul(clip_space_position, transpose(screen_to_relative_world));
	return world_space_position.xyz / world_space_position.w;
}

void default_vs(
	in s_tiny_position_vertex input,
	out float4 screen_position : SV_Position)
{
	s_vertex_shader_output output = (s_vertex_shader_output)0;
	float4 local_to_world_transform[3];
	apply_transform_position_only(DEFORM, input, output, local_to_world_transform, screen_position);
}

void albedo_vs(
   in s_tiny_position_vertex vertex,
	out float4 screen_position : SV_Position)
{
	default_vs(vertex, screen_position);
}


//	distance=					saturate(distance * LIGHT_DISTANCE_FALLOFF.x + LIGHT_DISTANCE_FALLOFF.y);
//	float distance_falloff=		clamped_distance;
//	float distance_falloff=		(2 - clamped_distance) * clamped_distance;
//	float distance_falloff=		saturate(((LIGHT_DISTANCE_FALLOFF.x * distance + LIGHT_DISTANCE_FALLOFF.y) * distance + LIGHT_DISTANCE_FALLOFF.z) * distance + LIGHT_DISTANCE_FALLOFF.w);
//	float distance_falloff=		saturate(LIGHT_DISTANCE_FALLOFF.x * distance + LIGHT_DISTANCE_FALLOFF.y);
//	float distance_falloff= 1 / (LIGHT_SIZE + distance2);											// distance based falloff				(2 instructions)
//	distance_falloff= max(0.0f, distance_falloff * LIGHT_FALLOFF_SCALE + LIGHT_FALLOFF_OFFSET);		// scale, offset, clamp result			(2 instructions)	


void light_calculation(
   in float2 pixel_pos,
   out float3 color,
   out float3 camera_to_fragment,
   out float4 normal)
{
#ifdef pc
 	color= 0.0f;
	camera_to_fragment= 0;
	normal= 0;
#else

	float3 light_to_fragment;		
	float4 albedo;			// alpha channel is spec scale	(mask * coeff)
	{
		float depth;
		asm
		{
			tfetch2D depth.x,	pixel_pos, depth_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
			tfetch2D normal,	pixel_pos, normal_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
			tfetch2D albedo,	pixel_pos, albedo_sampler,	UnnormalizedTextureCoords=true, MagFilter=point, MinFilter=point, MipFilter=point, AnisoFilter=disabled
		};		
		albedo.w*=albedo.w;
		normal.xyz = DecodeWorldspaceNormalSigned(normal.xy);
		light_to_fragment=	calculate_relative_world_position(pixel_pos, depth);	
		camera_to_fragment= CAMERA_TO_LIGHT + light_to_fragment;
	}

	// convert from worldspace to lightspace
	float3 light_to_fragment_lightspace= mul(light_to_fragment, ps_light_rotation);
	
	[isolate]
	float distance_falloff, cosine_lobe, angle_falloff;
	{	
		float distance2=		dot(light_to_fragment, light_to_fragment);
		float distance= sqrt(distance2);
		light_to_fragment=		light_to_fragment / distance;
		

		//float distance=			saturate(sqrt(distance2) * LIGHT_FALLOFF_SCALE + LIGHT_FALLOFF_OFFSET);
//		float distance=			saturate(light_to_fragment_lightspace.z * LIGHT_FALLOFF_SCALE + LIGHT_FALLOFF_OFFSET);		// 'straight' non-spherical falloff

		cosine_lobe=			saturate(dot(-light_to_fragment, normal) + diffuse_light_cosine_raise );			//  * LIGHT_FALLOFF_SCALE + LIGHT_DIFFUSE_OFFSET);	
#ifdef USE_EXPENSIVE_MATERIAL
		cosine_lobe*= MATERIAL_COEFF.x;
#endif

		distance_falloff=		saturate((LIGHT_FAR_ATTENUATION_END - distance) * LIGHT_FAR_ATTENUATION_RATIO);
		distance_falloff*=distance_falloff;
		angle_falloff= saturate((light_to_fragment_lightspace.z/distance - LIGHT_COSINE_CUTOFF_ANGLE ) * LIGHT_ANGLE_FALLOFF_RAIO);
		angle_falloff= pow(angle_falloff, LIGHT_ANGLE_FALLOFF_POWER);
	}
	
	float3 specular_lobe;
	{
		// phong lobe
		
#if 1
		float3 view_dir=			-normalize(camera_to_fragment);
		float view_dot_normal=		dot(view_dir, normal);
		float3 view_reflect_dir=	view_dot_normal * normal * 2 - view_dir;
		
		
		if (normal.w<1)
		{
			float specular_power= 50 - ( 50 - 8 ) * normal.w / 0.66f;
			
			//specular_lobe= specular_model(view_dir, view_dot_normal, view_reflect_dir, specular_power, light_to_fragment);
			
			float specular_cosine_lobe= saturate(dot(-light_to_fragment, view_reflect_dir));
			
#ifdef USE_EXPENSIVE_MATERIAL
			float fresnel_blend= saturate(pow((1.0f - view_dot_normal ), SPECULAR_COLOR_NORMAL.w)); 
			float restored_specular_power= max(0,MATERIAL_COEFF.y + specular_power);
			
		    float3 normal_specular_blend_albedo_color= lerp(SPECULAR_COLOR_NORMAL.xyz, albedo.xyz, MATERIAL_COEFF.z);
			float3 final_specular_color= lerp(normal_specular_blend_albedo_color, SPECULAR_COLOR_GAZING, fresnel_blend);
			
			float power_result= pow(specular_cosine_lobe, restored_specular_power);
			
			specular_lobe= power_result * (1+restored_specular_power) * final_specular_color;
			
#else
			float3 final_specular_color= lerp(float3(1,1,1), albedo.xyz, CHEAP_ALBEDO_BLEND);
			
			specular_lobe= pow(specular_cosine_lobe, specular_power) * (1+specular_power) * final_specular_color;
#endif
			
			//specular_lobe=				tex1D(albedo_sampler, dot(-light_to_fragment, view_reflect_dir));
		}
		else
		{
			specular_lobe= 0;
		}

#else
		// blinn-phong lobe
		float3 half_to_fragment=	normalize(light_to_fragment + normalize(camera_to_fragment));
		float half_dot_normal=		saturate(dot(-half_to_fragment, normal));

//		specular_lobe=				pow(half_dot_normal, specular_power) * specular_power;
		specular_lobe=				10 * sample2D(specular_curve_sampler, float2(half_dot_normal, normal.w));
#endif
	}
	
	{
		[predicateBlock]
		if (normal.w > 0.9f)
		{
			albedo.rgba= float4(0.09, 0.09f, 0.09f, 0.0f);
		}
		else
		{
			asm
			{
			};
		}
	}
	
	float3 irradiance= LIGHT_COLOR * distance_falloff * angle_falloff;
	
	color=	irradiance * COMBINE_LOBES( (cosine_lobe / pi), (specular_lobe.rgb), albedo);
	
#endif
}


SHADER_ATTRIBUTES
float4 default_ps(
	in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target0
{
	float3 color;
	float3 camera_to_fragment;
	float4 normal;
	light_calculation(
		pixel_pos, color, camera_to_fragment,normal);   
	
	return apply_exposure(float4(color.rgb, 1.0f));
}


#define pixel_size			screen_light_shadow_aux_constant_1


float sample_percentage_closer_PCF_cheap(float3 fragment_shadow_position, float depth_bias)					// 9 samples, 0 predicated
{
	float2 texel= fragment_shadow_position.xy;
	
	float max_depth= fragment_shadow_position.z *(1 + depth_bias);
	
	float shadow_ngbr=	step(max_depth, Sample2DOffsetPoint(shadow_depth_map_1, texel, -1.0f, -1.0f).r) + 					
						step(max_depth, Sample2DOffsetPoint(shadow_depth_map_1, texel, +1.0f, -1.0f).r) +
						step(max_depth, Sample2DOffsetPoint(shadow_depth_map_1, texel, -1.0f, +1.0f).r) +					
						step(max_depth, Sample2DOffsetPoint(shadow_depth_map_1, texel, +1.0f, +1.0f).r);
					
	return shadow_ngbr*0.25f;					
}


SHADER_ATTRIBUTES
float4 albedo_ps(
	in SCREEN_POSITION_INPUT(pixel_pos)) : SV_Target0
{
	float3 color;
	float3 camera_to_fragment;
	float4 normal;
	light_calculation(
		pixel_pos, color, camera_to_fragment,normal);

	float3 fragment_position_world= vs_view_camera_position + camera_to_fragment;

	float4 fragment_position_shadow= mul(float4(fragment_position_world, 1.0f), screen_light_shadow_matrix);
	fragment_position_shadow.xyz/= fragment_position_shadow.w;


	// calculate shadow
	float unshadowed_percentage= 1.0f;	
	{		
		unshadowed_percentage= sample_percentage_closer_PCF_cheap(fragment_position_shadow, 0.0005);	// ###xwan, it's a really hack number, but make everything work!
		unshadowed_percentage= lerp(1.0f, unshadowed_percentage, screen_light_shadow_aux_constant_1.w);
	}
	color*= unshadowed_percentage;
	
	return apply_exposure(float4(color.rgb, 1.0f));
}



BEGIN_TECHNIQUE _default
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}


BEGIN_TECHNIQUE albedo
{
	pass tiny_position
	{
		SET_VERTEX_SHADER(albedo_vs());
		SET_PIXEL_SHADER(albedo_ps());
	}
}

