#if !defined(DISABLE_WATER_ALPHA_FADE)
#define DO_WATER_ALPHA_FADE
#endif

#if !defined(DISABLE_WATER_REFLECTION)
#define DO_WATER_REFLECTION
#endif

#if !defined(DISABLE_WATER_REFRACTON)
#define DO_WATER_REFRACTION
#endif


#define DISABLE_NORMAL
#define DISABLE_TANGENT_FRAME

// Core Includes
#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "deform.fxh"
#include "exposure.fxh"

#include "engine/engine_parameters.fxh"
#include "lighting/lighting.fxh"


#include "fx/fx_functions.fxh"

#include "water_registers.fxh"

// GPU ranges
// vs constants: 130 - 139
// ps constants: 213 - 221
// bool constants: 100 - 104
// samplers: 0 - 1


#define k_is_camera_underwater false
#define k_is_under_screenshot false





/// ======================================================================================================


#include "water_tessellation.fxh"

// fresnel approximation
float compute_fresnel(
			float3 incident,
			float3 normal,
			float r0,
			float r1)
{
 	float eye_dot_normal=	saturate(dot(incident, normal));
	eye_dot_normal=			saturate(r1 - eye_dot_normal);
	return saturate(r0 * eye_dot_normal * eye_dot_normal);			//pow(eye_dot_normal, 2.5);
}

float compute_fog_transparency(
			float murkiness,
			float negative_depth)
{
	return saturate(exp2(murkiness * negative_depth));
}


float compute_fog_factor(
			float murkiness,
			float depth)
{
	return 1.0f - compute_fog_transparency(murkiness, -depth);
}

/* Water profile contants and textures from tag*/

// displacement maps
DECLARE_SAMPLER_2D_ARRAY(displacement_array, "Wave Displacement Array", "Wave Displacement Array", "rasterizer/water/wave_test7/wave_test7_displ_water.tif");
#include "next_texture.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_scalar_x, "wave displacement scalar x", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_scalar_y, "wave displacement scalar y", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_translate_u, "displacement translate u", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_translate_v, "displacement translate v", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT(displacement_height, "", "", 0, 1);
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT(displacement_time, "", "", 0, 1);
#include "used_vertex_float.fxh"
// secondary displacement maps
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_aux_scalar_x, "wave displacement scalar x", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_aux_scalar_y, "wave displacement scalar y", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_aux_translate_u, "displacement aux translate u", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_aux_translate_v, "displacement aux translate v", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT(displacement_aux_height, "", "", 0, 1);
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT(displacement_aux_time, "", "", 0, 1);
#include "used_vertex_float.fxh"


// wave slope maps
DECLARE_SAMPLER_2D_ARRAY(wave_slope_array, "Wave Slope Array", "Wave Slope Array", "rasterizer/water/wave_test7/wave_test7_displ_water.tif");
#include "next_texture.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(slope_scalar_x, "wave displacement scalar x", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(slope_scalar_y, "wave displacement scalar y", "", 0, 1, float(1.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(slope_translate_u, "slope translate u", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(slope_translate_v, "slope translate v", "", 0, 1, float(0.0));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT(slope_time, "", "", 0, 1);
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT(slope_scalar, "", "", 0, 1);
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(displacement_scale, "overall displacement scale", "", 0, 1, float(0.2f));
#include "used_vertex_float.fxh"
// wave shape
DECLARE_VERTEX_FLOAT(choppiness_forward, "", "", 0, 1);
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT(choppiness_backward, "", "", 0, 1);
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT(choppiness_side, "", "", 0, 1);
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT(choppiness_height_scale, "", "", 0, 1);
#include "used_vertex_float.fxh"

DECLARE_FLOAT(detail_slope_steepness, "", "", 0, 1);
#include "used_float.fxh"
DECLARE_FLOAT(minimal_wave_disturbance, "", "", 0, 1);
#include "used_float.fxh"


// water appearance ------------------------------------------------------

// Reflection
DECLARE_SAMPLER_CUBE(reflection_map,  "Reflection Texture", "Reflection Texture", "shaders/default_bitmaps/bitmaps/default_cube.tif")
#include "next_texture.fxh"
DECLARE_FLOAT(reflection_intensity, "", "", 0, 1);
#include "used_float.fxh"
DECLARE_FLOAT(reflection_sunspot_cut, "", "", 0, 1);
#include "used_float.fxh"

DECLARE_FLOAT(fresnel_intensity, "", "", 0, 1);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(fresnel_dark_spot, "", "", 0, 1, 1.0f);
#include "used_float.fxh"

DECLARE_FLOAT(shadow_intensity_mark, "", "", 0, 1);
#include "used_float.fxh"
DECLARE_FLOAT(reflection_normal_intensity, "Reflection Normal Intensity", "", 0, 1);
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(water_color_pure, "Water Color Pure", "", float3(0.5, 0.5, 0.5));
#include "used_float3.fxh"
DECLARE_RGB_COLOR_WITH_DEFAULT(water_diffuse, "Water Diffuse Color", "", float3(0.5, 0.5, 0.5));
#include "used_float3.fxh"

// water diffuse -------------------------------------
DECLARE_SAMPLER( diffuse_map, "Diffuse Map", "Diffuse Map", "shaders/default_bitmaps/bitmaps/default_diff.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(diffuse_map_mix, "Diffuse Map Mix", "Diffuse Map Mix", 0, 1, float(0.0));
#include "used_float.fxh"

// Refraction settings
DECLARE_FLOAT_WITH_DEFAULT(refraction_texcoord_shift,   "Refraction Texcoord Shift",   "", 0, 1, float(0.03));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(refraction_extinct_distance, "Refraction Extinct Distance", "", 0, 100, float(30));
#include "used_float.fxh"

DECLARE_RGB_COLOR_WITH_DEFAULT(stream_bed_mult, "Stream Bed Tint", "", float3(1, 1, 1));
#include "used_float3.fxh"
DECLARE_FLOAT(water_murkiness, "", "", 0, 1);
#include "used_float.fxh"

// refraction edge fade
DECLARE_BOOL_WITH_DEFAULT(do_uv_refraction_fade,    "Do UV Refraction Fade", "", true);
#include "next_bool_parameter.fxh"
DECLARE_FLOAT_WITH_DEFAULT(refraction_fade_start_u, "Opacity Refraction Fade Start U","do_uv_refraction_fade", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(refraction_fade_end_u,   "Opacity Refraction Fade End U",  "do_uv_refraction_fade", 0, 1, float(1.0));
#include "used_float.fxh"

// Foam settings
DECLARE_SAMPLER(foam_texture,        "Foam Texture", "Foam Texture", "");
#include "next_texture.fxh"
DECLARE_SAMPLER(foam_palette,        "Foam Palette Texture", "Foam Palette Texture", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(foam_texture_detail, "Foam Texture Detail", "Foam Texture Detail", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(foam_intensity,        "Foam Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(foam_wobble,           "Foam Displacement Wobble", "", 0, 1, float(0));
#include "used_float.fxh"
    //DECLARE_FLOAT_WITH_DEFAULT(foam_opac_whitepoint,  "Foam Opacity Whitepoint", "", 0, 1, float(1));
    //#include "used_float.fxh"

// Edge fade
DECLARE_BOOL_WITH_DEFAULT(do_uv_edge_fade,    "Do UV Edge Fade", "", true);
#include "next_bool_parameter.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edge_fade_start_u, "Edge Fade Start U", "do_uv_edge_fade", 0, 1, float(0.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(edge_fade_end_u,   "Edge Fade End U", "do_uv_edge_fade", 0, 1, float(1.0));
#include "used_float.fxh"

#define DO_ALPHA_MAP		// define this so we know when the alpha map needs to be sampled

// Alpha Fade
DECLARE_SAMPLER(alpha_map, "Alpha Map", "Alpha Map", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"

DECLARE_BOOL_WITH_DEFAULT( alpha_map_controls_refraction_fade, "Do Alpha Refraction Fade", "", false);
#include "next_bool_parameter.fxh"
DECLARE_FLOAT_WITH_DEFAULT( alpha_map_refraction_whitepoint, "refraction alpha whitepoint","alpha_map_controls_refraction_fade", 0, 1, float(1.0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT( alpha_map_refraction_blackpoint, "refraction alpha blackpoint","alpha_map_controls_refraction_fade", 0, 1, float(0.0));
#include "used_float.fxh"


// Iridescenece
DECLARE_SAMPLER(iridescence_basemap, "Iridescent Base Texture", "Iridescent Base Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(iridescence_palette, "Iridescent Palette Texture", "Iridescent Palette Texture", "shaders/default_bitmaps/bitmaps/gray_50_percent.tif");
#include "next_texture.fxh"
DECLARE_SAMPLER(iridescence_detail, "Iridescent Detail Texture", "Iridescent Detail Texture", "shaders/default_bitmaps/bitmaps/color_white.tif");
#include "next_texture.fxh"
DECLARE_FLOAT_WITH_DEFAULT(iridescence_intensity, "Iridescence Intensity", "", 0, 1, float(1.0));
#include "used_float.fxh"

#if defined(xenon)

////////////////////////////////////////////////////////////////////////////////
/// Water pass vertex shaders
////////////////////////////////////////////////////////////////////////////////


float3 restore_displacement(
			float3 displacement,
			float height)
{
	displacement= displacement*2.0f - 1.0f;
	displacement*= height;
	return displacement;
}

float3 apply_choppiness(
			float3 displacement,
			float chop_forward,
			float chop_backward,
			float chop_side)
{
	displacement.y*= chop_side;	//	backward choppiness
	displacement.x*= (displacement.x<0) ? chop_forward : chop_backward; //forward scale, y backword scale
	return displacement;
}

float2 calculate_ripple_coordinate_by_world_position(
			float2 position)
{
	float2 texcoord_ripple= (position - vs_view_camera_position.xy) / k_ripple_buffer_radius;
	float len= length(texcoord_ripple);
	texcoord_ripple*= rsqrt(len);

	texcoord_ripple+= k_view_dependent_buffer_center_shifting;
	texcoord_ripple= texcoord_ripple*0.5f + 0.5f;
	texcoord_ripple= saturate(texcoord_ripple);
	return texcoord_ripple;
}


// transform vertex position, normal etc according to wave
s_water_interpolators transform_vertex(
	s_water_render_vertex IN,
	uniform bool tessellated,
	uniform bool interaction)
{
	//	vertex to eye displacement
	float4 incident_ws;
	incident_ws.xyz= vs_view_camera_position - IN.position.xyz;
	incident_ws.w= length(incident_ws.xyz);
	incident_ws.xyz= normalize(incident_ws.xyz);
	float mipmap_level= 0;//max(incident_ws.w / wave_visual_damping_distance, 0.0f);

	// calculate displacement of vertex
	float4 position= IN.position;
	float water_height_relative= 0.0f;
	float max_height_relative= 1.0f;

	float4 original_texcoord= IN.texcoord;
	float2 texcoord_ripple= 0.0f;
	float waterIntensity = IN.normal.w;

	float4 displacement_array_xform     = float4(displacement_scalar_x, displacement_scalar_y, displacement_translate_u, displacement_translate_v);
	float4 displacement_aux_array_xform = float4(displacement_aux_scalar_x, displacement_aux_scalar_y, displacement_aux_translate_u, displacement_aux_translate_v);

	//float slope_trans_u = slope_translate_u;
	//float slope_trans_v = slope_translate_v;
	float4 wave_slope_array_xform       = float4(slope_scalar_x, slope_scalar_y, slope_translate_u, slope_translate_v);

	if (tessellated)
	{
		// apply global shape control
		float3 displacement     = 0.0f;
		float3 displacement_aux = 0.0f;
		{

			//	re-assemble constants
			float4 texcoord     = float4(transform_texcoord(original_texcoord.xy, displacement_array_xform),  displacement_time, mipmap_level);
			float4 texcoord_aux = float4(transform_texcoord(original_texcoord.xy, displacement_aux_array_xform),  displacement_aux_time, mipmap_level);
			//float4 texcoord_aux = float4(transform_texcoord(original_texcoord.xy, wave_slope_array_xform),  slope_time, mipmap_level);

			displacement     = sample3DLOD(displacement_array, texcoord.xyz, texcoord.w, false).xyz;
			displacement_aux = sample3DLOD(displacement_array, texcoord_aux.xyz, texcoord.w, false).xyz;

			// restore displacement
			displacement     = restore_displacement(displacement, displacement_height);
			displacement_aux = restore_displacement(displacement_aux, displacement_aux_height);
			displacement     = displacement + displacement_aux;
			displacement     = apply_choppiness( displacement,
							     choppiness_forward * waterIntensity,
							     choppiness_backward * waterIntensity,
							     choppiness_side * waterIntensity);

			// apply global height control
			displacement.z *= choppiness_height_scale;
		}

		// preserve the height
		water_height_relative= displacement.z;

		// get ripple texcoord
		if (interaction)
		{
		}

		// apply vertex displacement
		position.xyz +=
		  IN.tangent  * displacement.x +
		  IN.binormal * displacement.y +
		  IN.normal   * displacement.z;

		// consider interaction	after displacement
		if (interaction)
		{
			texcoord_ripple= calculate_ripple_coordinate_by_world_position(position.xy);
			float4 ripple_hei= sample2DLOD(tex_ripple_buffer_slope_height_vs, texcoord_ripple.xy, 0, false);

			float ripple_height= ripple_hei.r*2.0f - 1.0f;

			// low down ripple for shallow water
			ripple_height*= displacement_scale * waterIntensity;

			position+= IN.normal * ripple_height;
		}
	}
	else if (interaction)
	{
		// get ripple texcoord
		texcoord_ripple= calculate_ripple_coordinate_by_world_position(IN.position.xy);
	}

	s_water_interpolators OUT;

	OUT.position    = mul( float4(position.xyz, 1.0), vs_view_view_projection_matrix );
	OUT.texcoord    = float4(original_texcoord.xyz, mipmap_level);
	OUT.normal      = IN.normal;
	OUT.tangent     = IN.tangent;
	OUT.binormal    = IN.binormal;
	OUT.position_ss = OUT.position;
	OUT.incident_ws = incident_ws;
	OUT.position_ws = position;
	OUT.base_tex    = float4(IN.base_tex.xy, water_height_relative, max_height_relative);
	OUT.lm_tex      = float4(IN.lm_tex.xy, texcoord_ripple);

	return OUT;
}




float2 restore_slope(
			float2 slope)
{
	slope-= 0.5f;
	return slope;
}

float2 compute_detail_slope(
			float2 base_texcoord,
			float4 base_texture_xform,
			float slope_time,
			float mipmap_level)
{
	float2 slope_detail= 0.0f;
	/*
	if ( TEST_CATEGORY_OPTION(detail, repeat) )
	{
		float4 wave_detail_xform= base_texture_xform * float4(detail_slope_scale_x, detail_slope_scale_y, 1, 1);
		float4 texcoord_detail= float4(transform_texcoord(base_texcoord, wave_detail_xform),  displacement_time*detail_slope_scale_z, mipmap_level);
		asm{
			tfetch3D slope_detail.xy, texcoord_detail.xyz, wave_slope_array, MagFilter= linear, MinFilter= linear, MipFilter= linear, VolMagFilter= linear, VolMinFilter= linear
		};
		slope_detail= restore_slope(slope_detail);
	}
*/
	return slope_detail;
}


void compose_slope_default(float4 texcoord_in,
			   float height_scale,
			   float height_aux_scale,
			   float height_detail_scale,
			   out float2 slope_shading,
			   out float2 slope_refraction,
			   out float wave_choppiness_ratio)
{
	float4 displacement_array_xform     = float4(displacement_scalar_x, displacement_scalar_y, displacement_translate_u, displacement_translate_v);
	float4 displacement_aux_array_xform = float4(displacement_aux_scalar_x, displacement_aux_scalar_y, displacement_translate_u, displacement_translate_v);
	float4 wave_slope_array_xform       = float4(slope_scalar_x, slope_scalar_y, slope_translate_u, slope_translate_v);

	float mipmap_level  = texcoord_in.w;
	float4 texcoord     = float4(transform_texcoord(texcoord_in.xy, displacement_array_xform),     displacement_time, mipmap_level);
	//float4 texcoord_aux = float4(transform_texcoord(texcoord_in.xy, displacement_aux_array_xform), displacement_aux_time, mipmap_level);
	float4 texcoord_aux = float4(transform_texcoord(texcoord_in.xy, wave_slope_array_xform),  slope_time, mipmap_level);

	float2 slope;
	float2 slope_aux;

	asm{
	    tfetch3D slope.xy, texcoord.xyz, wave_slope_array, MagFilter= linear, MinFilter= linear, MipFilter= linear, VolMagFilter= linear, VolMinFilter= linear
	    tfetch3D slope_aux.xy, texcoord_aux.xyz, wave_slope_array, MagFilter= linear, MinFilter= linear, MipFilter= linear, VolMagFilter= linear, VolMinFilter= linear
	};

	slope     = restore_slope(slope);
	slope_aux = restore_slope(slope_aux);

	float wave_choppiness_ratio_1 = 1.0f - abs(slope.x) - abs(slope.y);
	float wave_choppiness_ratio_2 = 1.0f - abs(slope_aux.x) - abs(slope_aux.y);
	wave_choppiness_ratio         = max(wave_choppiness_ratio_1, wave_choppiness_ratio_2);

	float2 slope_detail = compute_detail_slope( texcoord_in.xy,
						    wave_slope_array_xform,
						    slope_time,
						    mipmap_level+1);

	// apply scale
	slope_aux        = (slope_aux * height_aux_scale) + (slope_detail * height_detail_scale);
	slope_shading    = (slope * height_scale) + slope_aux;
	slope_refraction =  slope * max(height_scale, minimal_wave_disturbance) + slope_aux;
}



// shade water surface ---------------------------------------------------------------------------------------------------------
float4 water_shading(
	s_water_interpolators INTERPOLATORS,
	uniform bool refraction,
	uniform bool interaction)
{
	float3 output_color= 0;

	// interaction
	float2 ripple_slope= 0.0f;

	if (interaction)
	{
		float2 texcoord_ripple= INTERPOLATORS.lm_tex.zw;
		float4 ripple;
		asm {tfetch2D ripple, texcoord_ripple, tex_ripple_buffer_slope_height_ps, MagFilter= linear, MinFilter= linear};
		ripple_slope= (ripple.gb - 0.5f) * 6.0f;	// hack
		//ripple_foam_factor= ripple.a;
	}

	float ripple_slope_length= ripple_slope.x + ripple_slope.y + 1.0f;
	ripple_slope_length= max(ripple_slope_length, 0.3f);
	ripple_slope_length= min(ripple_slope_length, 2.1f);

	float ripple_slope_weak= 1.0f / ripple_slope_length;

	// hack
	ripple_slope_weak= 1.0f;
	//ripple_foam_factor= 0.0f;

	float3 slope_shading = 0.0f;
	float2 slope_refraction = 0.0f;
	float wave_choppiness_ratio = 0.0f;

	compose_slope_default(
	    INTERPOLATORS.texcoord,
	    ripple_slope_weak,
	    ripple_slope_weak,
	    detail_slope_steepness * ripple_slope_weak,
	    slope_shading.xy,
	    slope_refraction,
	    wave_choppiness_ratio);

	// Adjust refraction slope
	slope_refraction = slope_scalar * slope_refraction + ripple_slope;

	//	adjust normal
	float normal_hack_ratio = max(INTERPOLATORS.texcoord.w, 1.0f);
	slope_shading.xy = slope_scalar * slope_shading / normal_hack_ratio + ripple_slope;
	slope_shading.z = sqrt(saturate(1.0f + dot(slope_shading.xy, -slope_shading.xy)));

	float3x3 tangent_frame_matrix = { INTERPOLATORS.tangent.xyz, INTERPOLATORS.binormal.xyz, INTERPOLATORS.normal.xyz };
	float3 normal = mul(slope_shading, tangent_frame_matrix);
	normal = normalize(normal);			// Do we need to renormalize?


	///////////////////////////////////////////////////////////////////////////
	/// Alpha map
	///////////////////////////////////////////////////////////////////////////
#if defined(DO_ALPHA_MAP)

	float2 alpha_map_uv = transform_texcoord(INTERPOLATORS.texcoord.xy, alpha_map_transform);
	float4 alpha_map_val = sample2DGamma(alpha_map, alpha_map_uv);

#endif


	///////////////////////////////////////////////////////////////////////////
	/// Fade Effects
	///////////////////////////////////////////////////////////////////////////
	float waterFade = INTERPOLATORS.normal.w;

#if defined(DO_WATER_EDGE_FADE)
	// since our depth is not always great, give an option to find edges with UVs
	// Alpha fade - do this first as we use this for fake water depth
	if (do_uv_edge_fade)
	{
		// normalize with 0 in center, 1 at edge
		float norm_u = 2 * abs(INTERPOLATORS.texcoord.x - 0.5);
		waterFade *= (1 - smoothstep(edge_fade_start_u, edge_fade_end_u, norm_u));
	}
#endif

#if defined(DO_WATER_ALPHA_FADE)

	// Use the alpha map to fade effects
	waterFade *= alpha_map_val.a;

#endif


	///////////////////////////////////////////////////////////////////////////
	/// Lighting
	///////////////////////////////////////////////////////////////////////////
	float3 lightmap_intensity= 1.0f;

#if defined(DO_WATER_LIGHTING)
	lightmap_intensity = sample_lightprobe_texture_intensity_only(INTERPOLATORS.lm_tex.xy);
#endif


	///////////////////////////////////////////////////////////////////////////
	/// Water Color
	///////////////////////////////////////////////////////////////////////////
	float3 water_color = water_color_pure;

#if defined(DO_WATER_COLOR_TEXTURE)

	float4 water_color_from_texture = sample2D(watercolor_texture, transform_texcoord(INTERPOLATORS.base_tex.xy, watercolor_texture_transform));
	water_color_from_texture.xyz *= watercolor_coefficient;
	water_color = water_color_from_texture.xyz;

#endif

	water_color *= lightmap_intensity;


	///////////////////////////////////////////////////////////////////////////
	/// Refraction
	///////////////////////////////////////////////////////////////////////////
	float3 color_refraction = water_color;
	float3 color_refraction_bed = water_color;

#if defined(DO_WATER_REFRACTION)
	float2 bump = 0.0f;
	if (refraction)
	{
		// calcuate texcoord in screen space
		INTERPOLATORS.position_ss/= INTERPOLATORS.position_ss.w;
		float2 texcoord_ss= INTERPOLATORS.position_ss.xy;
		texcoord_ss= texcoord_ss / 2 + 0.5;
		texcoord_ss.y= 1 - texcoord_ss.y;
		texcoord_ss= k_ps_water_player_view_constant.xy + texcoord_ss*k_ps_water_player_view_constant.zw;


		float depth_refraction= 0.0f;
		float depth_water= 0.0f;

		//	calculate water depth
		depth_water = sample2D(tex_depth_buffer, texcoord_ss).r;

		//float4 point_underwater= float4(INTERPOLATORS.position_ss.xy, 1.0f - depth_water, 1.0f);
		float4 point_underwater= float4(INTERPOLATORS.position_ss.xy, depth_water, 1.0f);
		point_underwater= mul(point_underwater, k_ps_water_view_xform_inverse);
		point_underwater.xyz/= point_underwater.w;
		depth_water= length(point_underwater.xyz - INTERPOLATORS.position_ws.xyz);

		// since our depth is not always great, give an option to find edges with UVs
		// Alpha fade - do this first as we use this for fake water depth
		float depth_scale = 1.0f;
		if (do_uv_refraction_fade)
		{
			// normalize with 0 in center, 1 at edge
			float norm_u = 2 * abs(INTERPOLATORS.texcoord.x - 0.5);
			depth_scale  = (1 - smoothstep(refraction_fade_start_u, refraction_fade_end_u, norm_u));
		}

		// read in the alpha for refraction if so desired
		if (alpha_map_controls_refraction_fade)
		{
			 depth_scale *= ApplyBlackPointAndWhitePoint(alpha_map_refraction_blackpoint,
									alpha_map_refraction_whitepoint,
									alpha_map_val.a);
		}


		bump = slope_refraction.xy * INTERPOLATORS.incident_ws.yx * refraction_texcoord_shift  * saturate(3 * depth_water) * depth_scale;
		bump *= min(max(2 / INTERPOLATORS.incident_ws.w, 0.0f), 1.0f);
		bump *= k_ps_water_player_view_constant.zw;
		bump *= ripple_slope_length;
		bump *= waterFade;

		// modify refraction lookup based on depth - not working

		float2 texcoord_refraction = texcoord_ss + bump;

		float2 delta = 0.001f;	//###xwan avoid fetch back pixel, it could be considered into k_ps_water_player_view_constant
		texcoord_refraction= clamp(texcoord_refraction,
					   k_ps_water_player_view_constant.xy + delta,
					   k_ps_water_player_view_constant.xy + k_ps_water_player_view_constant.zw - delta);

		// ###xwan this comparision need to some tolerance to avoid dirty boundary of refraction
		color_refraction = Sample2DOffset(tex_ldr_buffer, texcoord_refraction, 0.5, 0.5);
		color_refraction /= ps_view_exposure.r;
		color_refraction_bed = color_refraction;	// store the pure color of under water stuff
		color_refraction *= stream_bed_mult;

		// check real refraction
		depth_refraction= Sample2DOffset(tex_depth_buffer, texcoord_refraction, 0.5, 0.5).r;
		texcoord_refraction.y= 1.0 - texcoord_refraction.y;
		texcoord_refraction= texcoord_refraction*2 - 1.0f;

		float4 point_refraction= float4(texcoord_refraction, depth_refraction, 1.0f);
		point_refraction= mul(point_refraction, k_ps_water_view_xform_inverse);
		point_refraction.xyz/= point_refraction.w;

		// world space depth
		float negative_refraction_depth = point_refraction.z - INTERPOLATORS.position_ws.z;

		// compute refraction
		const float one_over_camera_distance = INTERPOLATORS.position_ws.w;
		float transparency= compute_fog_transparency(water_murkiness, negative_refraction_depth);
		transparency *= saturate(refraction_extinct_distance * one_over_camera_distance);							// turns opaque at distance

		if (k_is_camera_underwater)
		{
			transparency *= 0.02f;
		}

		// use depth to modify transparence separately  - not working
		color_refraction = lerp(water_color, color_refraction, transparency);
	}
#endif


	///////////////////////////////////////////////////////////////////////////
	/// Basic diffuse lighting
	///////////////////////////////////////////////////////////////////////////
	// compute diffuse by n dot l
	float3 water_kd= water_diffuse;
	float3 sun_dir_ws= float3(0.0, 0.0, 1.0);	//	sun direction

	float n_dot_l= saturate(dot(sun_dir_ws, normal));
	float3 color_diffuse= water_kd * n_dot_l;

	float2 diffuse_map_uv  = transform_texcoord(INTERPOLATORS.texcoord.xy, diffuse_map_transform);
	float4 diffuse_map_val = sample2DGamma(diffuse_map, diffuse_map_uv);
	color_diffuse = lerp(color_diffuse, diffuse_map_val, diffuse_map_mix);

	// only apply lightmap_intensity on diffuse and reflection, watercolor of refrection has already considered
	color_diffuse  *= lightmap_intensity;


	///////////////////////////////////////////////////////////////////////////
	/// Reflection
	///////////////////////////////////////////////////////////////////////////
	float3 color_reflection = 0;

#if defined(DO_WATER_REFLECTION)

	// calculate reflection direction
	float3 reflectionNormal = slope_shading * reflection_normal_intensity;
	reflectionNormal.z = sqrt(saturate(1.0f + dot(reflectionNormal.xy, -reflectionNormal.xy)));
	reflectionNormal = normalize(mul(reflectionNormal, tangent_frame_matrix));

	float3 reflect_dir = reflect(-INTERPOLATORS.incident_ws.xyz, reflectionNormal);

	// sample environment map
	float4 environment_sample;
	environment_sample = sampleCUBE(reflection_map, reflect_dir);

	// evualuate HDR color with considering of shadow
	float2 parts;
	parts.x = saturate(environment_sample.a - reflection_sunspot_cut);
	parts.y = min(environment_sample.a, reflection_sunspot_cut);

	float3 sun_light_rate = saturate(lightmap_intensity - shadow_intensity_mark);
	float  sun_scale = dot(sun_light_rate, sun_light_rate);

	const float shadowed_alpha = (parts.x * sun_scale) + parts.y;
	color_reflection =
		environment_sample.rgb *
		shadowed_alpha *
		reflection_intensity;

#endif


	///////////////////////////////////////////////////////////////////////////
	/// Iridescence
	///////////////////////////////////////////////////////////////////////////

#if defined(DO_WATER_IRIDESCENCE)

	// sample shape texture map
	float2 iridescence_basemap_uv = transform_texcoord(INTERPOLATORS.texcoord.xy, iridescence_basemap_transform);
	float4 iridescence = sample2DPalettizedScrolling(
		iridescence_basemap,
		iridescence_palette,
		iridescence_basemap_uv,
		0.5,
		0); //iridPaletteTextureSuppliesAlpha);

	float4 irid_mod = sample2D(iridescence_detail, transform_texcoord(INTERPOLATORS.texcoord.xy, iridescence_detail_transform));

	// mask into reflection
	iridescence *= iridescence_intensity * irid_mod;

	// add iridescence to reflection, where it will get fresnel applied
	color_reflection += iridescence;

#endif


	///////////////////////////////////////////////////////////////////////////
	/// Fresnel
	///////////////////////////////////////////////////////////////////////////
	// computer fresnel and output color
	float3 fresnel_normal = normal * 2 * (0.5f - k_is_camera_underwater);
	float  fresnel = compute_fresnel(INTERPOLATORS.incident_ws.xyz, fresnel_normal, fresnel_intensity, fresnel_dark_spot);

	// blend in reflection with fresnel
	output_color = lerp(color_refraction, color_reflection, fresnel);

	// add diffuse
	output_color = output_color + color_diffuse;



	///////////////////////////////////////////////////////////////////////////
	/// Foam
	///////////////////////////////////////////////////////////////////////////
#if defined(DO_WATER_FOAM)

	float4 foam_color = 0.0f;

	// compute foam
	float foam_factor = foam_intensity;
	foam_factor *= min(max(20 / INTERPOLATORS.incident_ws.w, 0.0f), 1.0f);

	[branch]
	if ( foam_factor > 0.002f )
	{
		// blend textures
		float2 bumpmod = bump * foam_wobble;
		float2 foam_texture_uv = transform_texcoord(INTERPOLATORS.texcoord.xy + bumpmod, foam_texture_transform);
		float4 foam = sample2DPalettizedScrolling(foam_texture, foam_palette, foam_texture_uv, 0.5, false);
		float4 foam_detail = sample2D(foam_texture_detail, transform_texcoord(INTERPOLATORS.texcoord.xy, foam_texture_detail_transform));

		foam_color.rgb  = foam.rgb * foam_detail.rgb; // * foam_colormult;
		foam_color.a = foam.a * foam_detail.a;
		foam_color.a = clamp( (foam_color.a * foam_intensity), 0, 1);
		//foam_color *= foam_factor;
		foam_factor = foam_color.w * foam_factor;
	}
	foam_color.rgb *= lightmap_intensity;

	// foam - A over B
	output_color.rgb = (output_color.rgb * (1-foam_color.a)) + (foam_color.rgb*foam_color.a);

#endif

	///////////////////////////////////////////////////////////////////////////
	/// Output
	///////////////////////////////////////////////////////////////////////////
	if (refraction)
	{
		// Fade between the water bed color and the 'full effects' color
		output_color = lerp(color_refraction_bed, output_color, waterFade);

		return apply_exposure(float4(output_color, 1), true);
	}
	else
	{
		return apply_exposure(float4(output_color * waterFade, waterFade), true);
	}
}


// Vertex shaders for the water pass

s_water_interpolators water_vs(
	in s_vertex_type_water_shading input,
	uniform bool tessellated,
	uniform bool interaction)
{
	s_water_render_vertex output = GetWaterVertex(input, tessellated);
	return transform_vertex(output, tessellated, interaction);
}

// Pixel shaders for the water pass

float4 water_ps(
	in const s_water_interpolators INTERPOLATORS,
	uniform bool alphaBlend,
	uniform bool interaction) : SV_Target0
{
	return water_shading(INTERPOLATORS, !alphaBlend, interaction);
}

#if !defined(cgfx)

// Mark this shader as water
#define MATERIAL_SHADER_ANNOTATIONS 	<bool is_water = true;>

#include "techniques_base.fxh"

// Build the techniques

#define MAKE_WATER_TECHNIQUE(tessellation, alpha_blend, interaction)							\
BEGIN_TECHNIQUE																						\
MATERIAL_SHADER_ANNOTATIONS																		\
{																								\
	pass water																					\
	{																							\
		SET_VERTEX_SHADER(water_vs(tessellation, interaction));						\
		SET_PIXEL_SHADER(water_ps(alpha_blend, interaction));						\
	}																							\
}

// Tessellated water entrypoints
MAKE_WATER_TECHNIQUE(true, false, false)		// tessellated, refractive, non-interactive
MAKE_WATER_TECHNIQUE(true, true, false)			// tessellated, blended, non-interactive
MAKE_WATER_TECHNIQUE(true, false, true)			// tessellated, refractive, interactive
MAKE_WATER_TECHNIQUE(true, true, true)			// tessellated, blended, interactive

// Non-tessellated entrypoints
MAKE_WATER_TECHNIQUE(false, false, false)		// untessellated, refractive, non-interactive
MAKE_WATER_TECHNIQUE(false, true, false)		// untessellated, blended, non-interactive
MAKE_WATER_TECHNIQUE(false, false, true)		// untessellated, refractive, interactive
MAKE_WATER_TECHNIQUE(false, true, true)			// untessellated, blended, interactive

#else


struct s_shader_data {
	s_common_shader_data common;

};

void pixel_pre_lighting(
            in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float2 diffuse_map_uv  = transform_texcoord(pixel_shader_input.texcoord.xy, diffuse_map_transform);
	float4 diffuse_map_val = sample2DGamma(diffuse_map, diffuse_map_uv);

	shader_data.common.albedo = diffuse_map_val;

	shader_data.common.normal = shader_data.common.tangent_frame[2];
}

float4 pixel_lighting(
	        in s_pixel_shader_input pixel_shader_input,
            inout s_shader_data shader_data)
{
	float3 output_color= 0;

	float3 normal = shader_data.common.normal;


	///////////////////////////////////////////////////////////////////////////
	/// Alpha map
	///////////////////////////////////////////////////////////////////////////
#if defined(DO_ALPHA_MAP)

	float2 alpha_map_uv = transform_texcoord(pixel_shader_input.texcoord.xy, alpha_map_transform);
	float4 alpha_map_val = sample2DGamma(alpha_map, alpha_map_uv);

#endif


	///////////////////////////////////////////////////////////////////////////
	/// Fade Effects
	///////////////////////////////////////////////////////////////////////////
	float waterFade = 1.0f;

#if !defined(DISABLE_VERTEX_COLOR)
	waterFade = shader_data.common.vertexColor.a;
#endif

#if defined(DO_WATER_EDGE_FADE)
	// since our depth is not always great, give an option to find edges with UVs
	// Alpha fade - do this first as we use this for fake water depth
	if (do_uv_edge_fade)
	{
		// normalize with 0 in center, 1 at edge
		float norm_u = 2 * abs(pixel_shader_input.texcoord.x - 0.5);
		waterFade *= (1 - smoothstep(edge_fade_start_u, edge_fade_end_u, norm_u));
	}
#endif


#if defined(DO_WATER_ALPHA_FADE)

	// Use the alpha map to fade effects
	waterFade *= alpha_map_val.a;

#endif


	///////////////////////////////////////////////////////////////////////////
	/// Water Color
	///////////////////////////////////////////////////////////////////////////
	float3 water_color = water_color_pure;



	///////////////////////////////////////////////////////////////////////////
	/// Basic diffuse lighting
	///////////////////////////////////////////////////////////////////////////
	// compute diffuse by n dot l
	float3 water_kd= water_diffuse;
	float3 sun_dir_ws= float3(0.0, 0.0, 1.0);	//	sun direction

	float n_dot_l= saturate(dot(sun_dir_ws, normal));
	float3 color_diffuse= water_kd * n_dot_l;

	color_diffuse = lerp(color_diffuse, shader_data.common.albedo.rgb, diffuse_map_mix);


	///////////////////////////////////////////////////////////////////////////
	/// Reflection
	///////////////////////////////////////////////////////////////////////////
	float3 color_reflection = 0;

	// calculate reflection direction
	float3 reflectionNormal = normal * reflection_normal_intensity;
	reflectionNormal.z = sqrt(saturate(1.0f + dot(reflectionNormal.xy, -reflectionNormal.xy)));
	reflectionNormal = normalize(mul(reflectionNormal, shader_data.common.tangent_frame));

	float3 reflect_dir = reflect(-shader_data.common.view_dir_distance.xyz, reflectionNormal);

	// sample environment map
	float4 environment_sample;
	environment_sample = sampleCUBE(reflection_map, reflect_dir);

	// evualuate HDR color with considering of shadow
	float2 parts;
	parts.x = saturate(environment_sample.a - reflection_sunspot_cut);
	parts.y = min(environment_sample.a, reflection_sunspot_cut);

	float3 sun_light_rate = saturate(1.0 - shadow_intensity_mark);
	float  sun_scale = dot(sun_light_rate, sun_light_rate);

	const float shadowed_alpha = (parts.x * sun_scale) + parts.y;
	color_reflection =
		environment_sample.rgb *
		shadowed_alpha *
		reflection_intensity;


	///////////////////////////////////////////////////////////////////////////
	/// Fresnel
	///////////////////////////////////////////////////////////////////////////
	// computer fresnel and output color
	float3 fresnel_normal = normal * 2 * (0.5f - k_is_camera_underwater);
	float  fresnel = compute_fresnel(shader_data.common.view_dir_distance.xyz, fresnel_normal, fresnel_intensity, fresnel_dark_spot);

	// blend in reflection with fresnel
	output_color = lerp(water_color, color_reflection, fresnel);

	// add diffuse
	output_color = output_color + color_diffuse;


	return float4(output_color, waterFade);
}


#include "techniques_cgfx.fxh"

#endif
#else

#include "water_dx11.fxh"

#endif




