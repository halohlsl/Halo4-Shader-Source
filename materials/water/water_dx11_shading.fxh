// convert normalized 3d texture z coordinate to texture array coordinate
float4 convert_3d_texture_coord_to_array_texture(in texture_sampler_2d_array t, in float3 uvw)
{
	uint width, height, elements;
	t.t.GetDimensions(width, height, elements);
	uvw.z = (frac(uvw.z) * elements);
	float next_z = (uvw.z >= (elements - 1)) ? 0 : (uvw.z + 1);
	return float4(uvw, next_z);
}

void compose_slope_default(
				const float2 texcoord_in,
			   	const float height_scale,
			   	const float height_aux_scale,
			   	const float height_detail_scale,
			   	const float3 time_pt,
			   	const float4 wave_slopeArray_xform,
			   	const float4 displacementArray_xform,
			   	out float2 slope_shading,
			   	out float2 slope_refraction,
			   	out float wave_choppiness_ratio)
{
	//float4 displacement_aux_array_xform = float4(displacement_aux_scalar_x, displacement_aux_scalar_y, displacement_translate_u, displacement_translate_v);

	float mipmap_level = 0; // TODO Deano compute

	float3 texcoord     = float3( transform_texcoord(texcoord_in.xy, displacementArray_xform), time_pt.x);
	float3 texcoord_aux = float3( transform_texcoord(texcoord_in.xy, wave_slopeArray_xform), time_pt.y);

	float4 array_texcoord = convert_3d_texture_coord_to_array_texture(wave_slope_array, texcoord.xyz);
	float4 array_texcoord_aux = convert_3d_texture_coord_to_array_texture(wave_slope_array, texcoord_aux.xyz);
	float array_texcoord_t = frac(array_texcoord.z);
	float array_texcoord_aux_t = frac(array_texcoord_aux.z);
	array_texcoord.zw = floor(array_texcoord.zw);
	array_texcoord_aux.zw = floor(array_texcoord_aux.zw);
	
	float2 slope = lerp(
		wave_slope_array.t.Sample(wave_slope_array.s, array_texcoord.xyz),
		wave_slope_array.t.Sample(wave_slope_array.s, array_texcoord.xyw),
		frac(array_texcoord_t));
	float2 slope_aux = lerp(
		wave_slope_array.t.Sample(wave_slope_array.s, array_texcoord_aux.xyz),
		wave_slope_array.t.Sample(wave_slope_array.s, array_texcoord_aux.xyw),
		frac(array_texcoord_aux_t));

	slope     = restore_slope(slope);
	slope_aux = restore_slope(slope_aux);

	float wave_choppiness_ratio_1 = 1.0f - abs(slope.x) - abs(slope.y);
	float wave_choppiness_ratio_2 = 1.0f - abs(slope_aux.x) - abs(slope_aux.y);
	wave_choppiness_ratio         = max(wave_choppiness_ratio_1, wave_choppiness_ratio_2);
	float2 slope_detail = 0.0;
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

	float2 lm_tex = INTERPOLATORS.base_tex.zw;
	float3 binormal   = cross(INTERPOLATORS.normal.xyz, INTERPOLATORS.tangent.xyz);
	binormal = normalize(binormal);

	float3 output_color= 0;

	// interaction
	float2 ripple_slope= 0.0f;

	if (interaction)
	{
		float2 texcoord_ripple= INTERPOLATORS.ripple;
		float4 ripple = sample2D(tex_ripple_buffer_slope_height_ps, texcoord_ripple);
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

	float slopeScalar = INTERPOLATORS.time_pt.z;
	float3 slope_shading = 0.0f;
	float2 slope_refraction = 0.0f;
	float wave_choppiness_ratio = 0.0f;

	compose_slope_default(
	    INTERPOLATORS.texcoord,
	    ripple_slope_weak,
	    ripple_slope_weak,
	    detail_slope_steepness * ripple_slope_weak,
	    INTERPOLATORS.time_pt,
	    INTERPOLATORS.wave_slopeArray_xform,
	    INTERPOLATORS.displacementArray_xform,
	    slope_shading.xy,
	    slope_refraction,
	    wave_choppiness_ratio);

	// Adjust refraction slope
	slope_refraction = slopeScalar * slope_refraction + ripple_slope;

	//	adjust normal
	float normal_hack_ratio = 1.0f;//max(INTERPOLATORS.texcoord.w, 1.0f);
	slope_shading.xy = slopeScalar * slope_shading / normal_hack_ratio + ripple_slope;
	slope_shading.z = sqrt(saturate(1.0f + dot(slope_shading.xy, -slope_shading.xy)));

	float3x3 tangent_frame_matrix = { INTERPOLATORS.tangent.xyz, binormal.xyz, INTERPOLATORS.normal.xyz };
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
	lightmap_intensity = sample_lightprobe_texture_intensity_only(lm_tex.xy);
#endif


	///////////////////////////////////////////////////////////////////////////
	/// Water Color
	///////////////////////////////////////////////////////////////////////////
	float3 water_color = water_color_pure;

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
		uint width, height;
		tex_depth_buffer.t.GetDimensions(width, height);
		float2 position_ss =  INTERPOLATORS.position.xy * (1.0f/float2(width,height));

		float2 texcoord_ss= position_ss.xy; // 0-1
	//	texcoord_ss= k_ps_water_player_view_constant.xy + texcoord_ss*k_ps_water_player_view_constant.zw;

	 	position_ss = position_ss * 2 - 1;

		float depth_refraction= 0.0f;
		float depth_water= 0.0f;

		//	calculate water depth
		depth_water = tex_depth_buffer.t.Load(int3(INTERPOLATORS.position.xy,0)).r;

		//float4 point_underwater= float4(INTERPOLATORS.position_ss.xy, 1.0f - depth_water, 1.0f);
		float4 point_underwater= float4(position_ss, depth_water, 1.0f);
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
					   0 + delta,
					   1 - delta);

		// ###xwan this comparision need to some tolerance to avoid dirty boundary of refraction
		color_refraction = Sample2DOffset(tex_ldr_buffer, texcoord_refraction, 0.5, 0.5);
		color_refraction /= ps_view_exposure.r;
		color_refraction_bed = color_refraction;	// store the pure color of under water stuff
		color_refraction *= stream_bed_mult;

		// check real refraction
		depth_refraction= Sample2DOffset(tex_depth_buffer, texcoord_refraction, 0.5, 0.5).r;
//		texcoord_refraction.y= 1.0 - texcoord_refraction.y;
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
	float3 color_reflection = 0.0;

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

	//[branch]
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


