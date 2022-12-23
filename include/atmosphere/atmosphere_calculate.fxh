#if !defined(__ATMOSPHERE_CALCULATE_FXH)
#define __ATMOSPHERE_CALCULATE_FXH

#include "engine/engine_parameters.fxh"

#if defined(xenon) || (DX_VERSION == 11)

// Constants for using the fog table
#define	_atmosphere_constant_LUT_0		s_atmosphere_constant_0
#define	_atmosphere_constant_LUT_1		s_atmosphere_constant_1
#define	_atmosphere_constant_LUT_2		s_atmosphere_constant_2
#define	_atmosphere_constant_LUT_3		s_atmosphere_constant_3

// Constants for generating the fog table
#define _sky_fog_color					s_atmosphere_constant_4.xyz
#define _sky_fog_thickness				s_atmosphere_constant_4.w
#define _sky_fog_height					s_atmosphere_constant_5.x
#define _sky_fog_base_height			s_atmosphere_constant_5.y
#define _sky_fog_max_distance			s_atmosphere_constant_5.z
#define _fog_distance_bias				s_atmosphere_constant_5.w

#define _ground_fog_color				s_atmosphere_constant_6.xyz
#define _ground_fog_thickness			s_atmosphere_constant_6.w
#define _ground_fog_height				s_atmosphere_constant_7.x
#define _ground_fog_base_height			s_atmosphere_constant_7.y
#define _ground_fog_max_distance		s_atmosphere_constant_7.z
//										s_atmosphere_constant_7.w		// unused

#define _ceiling_fog_color				s_atmosphere_constant_8.xyz
#define _ceiling_fog_thickness			s_atmosphere_constant_8.w
#define _ceiling_fog_height				s_atmosphere_constant_9.x
#define _ceiling_fog_base_height		s_atmosphere_constant_9.y
#define _ceiling_fog_max_distance		s_atmosphere_constant_9.z
//										s_atmosphere_constant_9.w		// unused

// Constants for lighting fog (at the same time as using the fog table)
#define _fog_light_1_direction			s_atmosphere_constant_4.xyz
#define _fog_light_1_radius_scale		s_atmosphere_constant_4.w
#define _fog_light_1_color				s_atmosphere_constant_5.xyz
#define _fog_light_1_radius_offset		s_atmosphere_constant_5.w

#define _fog_light_1_angular_falloff	s_atmosphere_constant_6.x
#define _fog_light_1_distance_falloff	s_atmosphere_constant_6.y
#define _fog_light_1_nearby_cutoff		s_atmosphere_constant_6.z		// Actually 1 / (nearby_cutoff - 1)

#if defined(ATMOSPHERE_TABLE_GENERATION)
#include "atmosphere_calculate_registers.fxh"
#endif // defined(ATMOSPHERE_TABLE_GENERATION)


// ---------------  translate constants for planar fog
//DECLARE_PARAMETER(			float4,		s_planar_fog_constant_0,												c220);
//DECLARE_PARAMETER(			float4,		s_planar_fog_constant_1,												c221);
//#define PLANAR_FOG_COLOR				s_planar_fog_constant_0.xyz
//#define PLANAR_FOG_THICKNESS			s_planar_fog_constant_0.w
//#define PLANAR_FOG_PLANE_COEFFS			s_planar_fog_constant_1


#define MAX_VIEW_DISTANCE							_atmosphere_constant_LUT_0.x
#define ONE_OVER_MAX_VIEW_DISTANCE					_atmosphere_constant_LUT_0.y
#define	LUT_Z_FLOOR									_atmosphere_constant_LUT_0.z
#define	LUT_Z_CEILING								_atmosphere_constant_LUT_0.w

#define	LUT_clamped_view_z							_atmosphere_constant_LUT_1.z
#define	LUT_Z_MIDDLE								_atmosphere_constant_LUT_1.w

#define	LUT_y_map_coeffs							_atmosphere_constant_LUT_3

#define PIN_LUT(z)									clamp(z, LUT_Z_FLOOR, LUT_Z_CEILING)

#define LUT_coeff_a									_atmosphere_constant_LUT_1.x
#define LUT_coeff_b									_atmosphere_constant_LUT_1.y

#define	LUT_one_over_coeff_b						_atmosphere_constant_LUT_2.x
#define	LUT_log_coeff_a								_atmosphere_constant_LUT_2.y
#define	LUT_exp2_neg_coeff_a						_atmosphere_constant_LUT_2.z
#define LUT_log_one_over_coeff_b					_atmosphere_constant_LUT_2.w

#define	FOG_DELTA									0.0001




float GetLUTDepthValue(in float LUTCoord)
{
	return pow(LUT_coeff_a * LUTCoord, LUT_coeff_b) + LUT_Z_FLOOR;
}

float ComputeExtinction(
	const float thickness,
	const float distance)
{
	// 7 ALU, hard to be parallalized
	return saturate(exp(-thickness * distance));
}

float ComputeBlendedExtinction(
	const float thicknessWeight,
	const float distance,
	const float maxDistance,
	const float4 functionTable[64])
{
	// thicknessWeight effectively scales the x-axis
#if DX_VERSION == 11
	float tableIndexFloat = (maxDistance == 0) ? 0 : (thicknessWeight * distance / (maxDistance));
#else	
	float tableIndexFloat = thicknessWeight * distance / (maxDistance);
#endif

	// Split the table index into integer and fractional components
	int tableIndexInt;
	float tableIndexFrac = modf(255 * tableIndexFloat, tableIndexInt);

	// Blend between the lower table value and the upper table value
	float lower = functionTable[tableIndexInt / 4][tableIndexInt % 4];
	float upper = functionTable[(tableIndexInt + 1) / 4][(tableIndexInt + 1) % 4];
	return lerp(lower, upper, tableIndexFrac);
}

float get_fog_thickness_weight_at_relative_height(
	in float point_relative_height,
	in float fog_height)
{
#if DX_VERSION == 11
	if (fog_height == 0)
	{
		return 0;
	}
#endif
	// 5 ALU, could be parallal for vector operation
	float weight= saturate((fog_height - point_relative_height) / fog_height);
	return weight*weight;
}

#if defined(ATMOSPHERE_TABLE_GENERATION)
float calc_solo_fog_extinction(
	in float view_distance,
	in float view_height_top,
	in float view_height_bottom,
	in float view_height_diff,
	in float fog_height,
	in float fog_base_height,
	// current fog
	in float fog_thickness,
	in float3 fog_color,
	in float fog_max_distance,
	in bool blendFunctions,
	out float fog_actual_travel_distance)
{
	view_height_top-= fog_base_height;
	view_height_bottom-= fog_base_height;

	view_height_top= min(view_height_top, fog_height);
	float dist_ratio_in_fog= saturate ( (view_height_top-view_height_bottom)/view_height_diff );

	float thicknessWeight = get_fog_thickness_weight_at_relative_height(view_height_bottom, fog_height);

	//add bias
	float fog_view_distance= (view_distance + _fog_distance_bias) * dist_ratio_in_fog;
	fog_view_distance= max(fog_view_distance, 0.0f);
	fog_view_distance= min(fog_view_distance, fog_max_distance);

	fog_actual_travel_distance= fog_view_distance;

	if (blendFunctions)
	{
		return ComputeBlendedExtinction(thicknessWeight, fog_view_distance, _sky_fog_max_distance, atmosphereSkyFunction);
	}
	else
	{
		return ComputeExtinction(thicknessWeight * fog_thickness, fog_view_distance);
	}
}

float calc_mixed_fog_extinction(
	in float view_distance,
	in float view_height_top,
	in float view_height_bottom,
	in float view_height_diff,
	in float fog_height,
	in float fog_base_height,
	// current fog
	in float fog_thickness,
	in float3 fog_color,
	in float fog_max_distance,
	// base fog
	in float base_fog_thickness,
	in float3 base_fog_color,
	in float base_fog_max_distance,
	in bool blendFunctions,

	out float3 mixed_fog_color)
{
	view_height_top-= fog_base_height;
	view_height_bottom-= fog_base_height;

	view_height_top= min(view_height_top, fog_height);
	float dist_ratio_in_fog= saturate ( (view_height_top-view_height_bottom)/view_height_diff );

	float thicknessWeight = get_fog_thickness_weight_at_relative_height(view_height_bottom, fog_height);

	float fog_view_distance= (view_distance + _fog_distance_bias) * dist_ratio_in_fog;
	fog_view_distance= max(fog_view_distance, 0.0f);

	float base_fog_view_distance= min(fog_view_distance, base_fog_max_distance);
	fog_view_distance= min(fog_view_distance, fog_max_distance);

	float fogExtinction, baseFogExtinction;

	if (blendFunctions)
	{
		fogExtinction= ComputeBlendedExtinction(thicknessWeight, fog_view_distance, _ground_fog_max_distance, atmosphereGroundFunction);
		baseFogExtinction= ComputeBlendedExtinction(1.0f, base_fog_view_distance, _sky_fog_max_distance, atmosphereSkyFunction);
	}
	else
	{
		fogExtinction= ComputeExtinction(thicknessWeight * fog_thickness, fog_view_distance);
		baseFogExtinction= ComputeExtinction(base_fog_thickness, base_fog_view_distance);
	}

	const float weight= thicknessWeight * fog_thickness * fog_view_distance;
	const float base_weight= base_fog_thickness * base_fog_view_distance;
	
	float combined_weight = (weight + base_weight);
	
#if DX_VERSION == 11	
	if (combined_weight == 0.0)
	{
		mixed_fog_color = 0;
	} else
#endif	
	{
		mixed_fog_color=  (fog_color*weight + base_fog_color*base_weight)/combined_weight;
	}
	return fogExtinction * baseFogExtinction;
}


float calc_separate_fog_extinction(
	in float view_distance,
	in float view_point_z,
	in float scene_point_z,
	in float fog_height,
	in float fog_base_height,
	// current fog
	in float fog_thickness,
	in float3 fog_color,
	in float fog_max_distance,
	in bool blendFunctions,
	out float fog_actual_travel_distance)
{
	// Offset fog by base height
	view_point_z -= fog_base_height;
	scene_point_z -= fog_base_height;

	// Get the unmodified height range of the vector
	float view_height_diff = (scene_point_z - view_point_z);
	float relativeHeightRef;

	// Clamp the maximum offset
	if (fog_height >= 0.0)
	{
		scene_point_z = min(scene_point_z, fog_height);
		relativeHeightRef = min(scene_point_z, view_point_z);
	}
	else
	{
		scene_point_z = max(scene_point_z, fog_height);
		relativeHeightRef = max(scene_point_z, view_point_z);
	}

	float dist_ratio_in_fog = saturate((scene_point_z - view_point_z) / view_height_diff);

    float thicknessWeight = get_fog_thickness_weight_at_relative_height(relativeHeightRef, fog_height);

	//add bias
	float fog_view_distance= (view_distance + _fog_distance_bias) * dist_ratio_in_fog;
	fog_view_distance= max(fog_view_distance, 0.0f);
	fog_view_distance= min(fog_view_distance, fog_max_distance);

	fog_actual_travel_distance= fog_view_distance;

	if (blendFunctions)
	{
		return ComputeBlendedExtinction(thicknessWeight, fog_view_distance, _sky_fog_max_distance, atmosphereSkyFunction);
	}
	else
	{
		return ComputeExtinction(thicknessWeight * fog_thickness, fog_view_distance);
	}
}

void compute_scattering_mixed(
	in float view_point_z,
	in float scene_point_z,
	in float view_distance,
	in bool blendFunctions,
	out float3 inscatter,
	out float extinction)
{
	const float view_height_top= max(view_point_z, scene_point_z) + 0.001f;
	const float view_height_bottom= min(view_point_z, scene_point_z);
	const float view_height_diff= view_height_top - view_height_bottom;
	const float ground_fog_absolute_height= _ground_fog_height + _ground_fog_base_height;

	// tweak ground fog color
	float fog_actual_travel_distance;
	const float sky_fog_extinction= calc_solo_fog_extinction(
		view_distance,
		view_height_top, max(view_height_bottom, ground_fog_absolute_height), view_height_diff,
		_sky_fog_height,
		_sky_fog_base_height,
		_sky_fog_thickness, _sky_fog_color, _sky_fog_max_distance, blendFunctions,
		fog_actual_travel_distance);

	float3 mixed_fog_color;
	const float mixed_fog_extinction= calc_mixed_fog_extinction(
		view_distance,
		min(view_height_top, ground_fog_absolute_height), view_height_bottom, view_height_diff,
		_ground_fog_height,
		_ground_fog_base_height,
		_ground_fog_thickness, _ground_fog_color, _ground_fog_max_distance,
		_sky_fog_thickness, _sky_fog_color, _sky_fog_max_distance - fog_actual_travel_distance, blendFunctions,
		mixed_fog_color);

	const float3 sky_fog_inscatter= lerp(_sky_fog_color, 0, sky_fog_extinction);
	const float3 mixed_fog_inscatter= lerp(mixed_fog_color, 0, mixed_fog_extinction);

	extinction= sky_fog_extinction * mixed_fog_extinction;
	float3 inscatter_a=
			sky_fog_inscatter * mixed_fog_extinction +
			mixed_fog_inscatter;
	float3 inscatter_b=
			sky_fog_inscatter +
			mixed_fog_inscatter * sky_fog_extinction;

	float low_rate= ((ground_fog_absolute_height - view_point_z)/_ground_fog_height);
	low_rate= (low_rate * _ground_fog_thickness/max(_sky_fog_thickness, 0.00001f) );
	low_rate= saturate(low_rate);

	inscatter= lerp(inscatter_b, inscatter_a, low_rate);
}

void compute_scattering_separate(
	in float view_point_z,
	in float scene_point_z,
	in float view_distance,
	in bool blendFunctions,
	out float3 inscatter,
	out float extinction)
{
	// tweak ground fog color
	float fog_actual_travel_distance;
	const float sky_fog_extinction= calc_separate_fog_extinction(
		view_distance,
		view_point_z, scene_point_z,
		_sky_fog_height,
		_sky_fog_base_height,
		_sky_fog_thickness, _sky_fog_color, _sky_fog_max_distance, blendFunctions,
		fog_actual_travel_distance);
	const float3 sky_fog_inscatter= lerp(_sky_fog_color, 0, sky_fog_extinction);
	extinction= sky_fog_extinction;

	const float ground_fog_extinction= calc_separate_fog_extinction(
		view_distance,
		view_point_z, scene_point_z,
		_ground_fog_height,
		_ground_fog_base_height,
		_ground_fog_thickness, _ground_fog_color, _ground_fog_max_distance, blendFunctions,
		fog_actual_travel_distance);
	const float3 ground_fog_inscatter= lerp(_ground_fog_color, 0, ground_fog_extinction);

	const float ceiling_fog_extinction= calc_separate_fog_extinction(
		view_distance,
		view_point_z, scene_point_z,
		_ceiling_fog_height,
		_ceiling_fog_base_height,
		_ceiling_fog_thickness, _ceiling_fog_color, _ceiling_fog_max_distance, blendFunctions,
		fog_actual_travel_distance);
	const float3 ceiling_fog_inscatter= lerp(_ceiling_fog_color, 0, ceiling_fog_extinction);

	extinction *= (ground_fog_extinction + ceiling_fog_extinction);
//	inscatter = sky_fog_inscatter + ground_fog_inscatter;

	float3 inscatter_a = sky_fog_inscatter * ground_fog_extinction + ground_fog_inscatter;
	float3 inscatter_b = (ground_fog_inscatter + ceiling_fog_inscatter) * sky_fog_extinction + sky_fog_inscatter;

	inscatter = max(inscatter_a, inscatter_b);
}
#endif // defined(ATMOSPHERE_TABLE_GENERATION)

#endif

#endif // __ATMOSPHERE_CALCULATE_FXH