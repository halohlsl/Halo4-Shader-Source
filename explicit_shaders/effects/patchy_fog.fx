#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "exposure.fxh"
#include "patchy_fog_registers.fxh"




struct s_patchy_prepass_vertex_out
{
	float4 position : SV_Position;
	float4 texcoord : TEXCOORD0;
	float4 world_space : TEXCOORD1;
};

s_patchy_prepass_vertex_out patchy_prepass_vs(s_screen_vertex input)
{
	s_patchy_prepass_vertex_out output;
	output.position.xy=	input.position;
	output.position.zw=	float2(k_vs_z_epsilon.x, 1.0f);
	output.texcoord.xy=	input.texcoord;
	output.texcoord.zw=	input.texcoord * float2(2, -2) + float2(-1, 1);

	float4 world_space=	mul(output.position.xyzw, transpose(k_vs_proj_to_world_relative));
	output.world_space=	float4(world_space.xyz / world_space.w, 1.0f);

	return output;
}



struct s_patchy_prepass_output
{
	float4 color0 : SV_Target0;
	float4 color1 : SV_Target1;
};



float2 calc_warp_offset(float2 texcoord_biased)			// [-1, 1] across warp area (center of warp is 0,0)
{
	float2 delta=		texcoord_biased * k_ps_projective_to_tangent_space;
	float delta2=		dot(delta.xy, delta.xy);
	float delta4=		delta2 * delta2;
	float delta6=		delta4 * delta2;

//	better approximation, but more expensive:
//	float delta6=			delta2 * delta2 * delta2;
//	float delta_offset=		delta2 * 0.05f + delta6 * 0.37f;				// ###ctchou $TODO we could give artists control of this polynomial if they want..  maybe default it to the sphere control, but let them do whatever..

	// best, but more expensive
//	float delta_offset=		delta2 * -0.108f + delta4 * -0.167f + delta6 * 0.06f;

	// really good over low angles (<80 degrees fov), sucks over that
//	float delta_offset=		delta2 * -0.15f + delta4 * -0.06f;

	// not as good at low angles, but better over larger angles	
	float delta_offset=		delta2 * -0.185f + delta4 * -0.023f;

	// exact (and EXTREMELY expensive)
//	float delta_offset=		atan(sqrt(delta2)) - sqrt(delta2);
	
	float2 offset=			(delta.xy * delta_offset) / k_ps_projective_to_tangent_space;

	return offset;
}


s_patchy_prepass_output patchy_prepass_ps(s_patchy_prepass_vertex_out input)
{
	// Window coordinates with [0,0] at the center, [1,1] at the upper right, and [-1,-1] at the lower left
	float2 screen_normalized_biased = input.texcoord.zw + calc_warp_offset(input.texcoord.zw);

	float4 noise_values0, noise_values1;	
	{
		float4 noise_uvs;
		
		// the texcoord transforms are computed using a single matrix multiplication per sheet, and we go double-wide to compute two texcoords at once
		noise_uvs=			k_ps_texcoord_offsets[0].xyzw +
							k_ps_texcoord_x_scale[0].xyzw * screen_normalized_biased.x +
							k_ps_texcoord_y_scale[0].xyzw * screen_normalized_biased.y;
		noise_values0.x=	sample2D(k_ps_sampler_tex_noise, noise_uvs.xy).x;
		noise_values0.y=	sample2D(k_ps_sampler_tex_noise, noise_uvs.zw).x;

		noise_uvs=			k_ps_texcoord_offsets[1].xyzw +
							k_ps_texcoord_x_scale[1].xyzw * screen_normalized_biased.x +
							k_ps_texcoord_y_scale[1].xyzw * screen_normalized_biased.y;
		noise_values0.z=	sample2D(k_ps_sampler_tex_noise, noise_uvs.xy).x;
		noise_values0.w=	sample2D(k_ps_sampler_tex_noise, noise_uvs.zw).x;

		noise_uvs=			k_ps_texcoord_offsets[2].xyzw +
							k_ps_texcoord_x_scale[2].xyzw * screen_normalized_biased.x +
							k_ps_texcoord_y_scale[2].xyzw * screen_normalized_biased.y;
		noise_values1.x=	sample2D(k_ps_sampler_tex_noise, noise_uvs.xy).x;
		noise_values1.y=	sample2D(k_ps_sampler_tex_noise, noise_uvs.zw).x;

		noise_uvs=			k_ps_texcoord_offsets[3].xyzw +
							k_ps_texcoord_x_scale[3].xyzw * screen_normalized_biased.x +
							k_ps_texcoord_y_scale[3].xyzw * screen_normalized_biased.y;
		noise_values1.z=	sample2D(k_ps_sampler_tex_noise, noise_uvs.xy).x;
		noise_values1.w=	sample2D(k_ps_sampler_tex_noise, noise_uvs.zw).x;
	}

	noise_values0 *= pow(saturate(k_ps_height_fade_scales[0].xyzw * input.world_space.z + k_ps_height_fade_offset[0].xyzw), 2) * k_ps_sheet_fade[0];
	noise_values1 *= pow(saturate(k_ps_height_fade_scales[1].xyzw * input.world_space.z + k_ps_height_fade_offset[1].xyzw), 2) * k_ps_sheet_fade[1];
	
	s_patchy_prepass_output output;
	output.color0=	noise_values0;
	output.color1=	noise_values1;
	return output;
}





struct s_patchy_vertex_out
{
	float4 position : SV_Position;
	float4 texcoord : TEXCOORD0;
};

s_patchy_vertex_out patchy_vs(s_screen_vertex input)
{
	s_patchy_vertex_out output;
	output.position.xy=	input.position;
	output.position.zw=	float2(k_vs_z_epsilon.x, 1.0f);
	output.texcoord.xy=	input.texcoord;
	output.texcoord.zw=	input.texcoord * float2(2, -2) + float2(-1, 1);
	return output;
}

float4 patchy_ps(const in s_patchy_vertex_out input) : SV_Target
{
	// Screen coordinates with [0,0] in the upper left and [1,1] in the lower right
	float2 screen_normalized_uv = input.texcoord;
	float scene_depth=					sample2D(k_ps_sampler_tex_scene_depth, screen_normalized_uv).x;
	
	// Convert the depth from [0,1] to view-space homogenous (.xy = _33 and _43, .zw = _34 and _44 from the projection matrix)
	float2 view_space_scene_depth=		k_ps_inverse_z_transform.xy * scene_depth + k_ps_inverse_z_transform.zw;
	
	// Homogenous divide
//	view_space_scene_depth.x /= -view_space_scene_depth.y;
	// optimized -- relies on the fact that we know view_space_scene_depth.x == -1.0 for our standard projections
	view_space_scene_depth.x=	1.0f / view_space_scene_depth.y;
	
	// evaluate patchy effect
	float inv_inscatter;
	{
		float4 fade_factor0=	saturate(view_space_scene_depth.xxxx * k_ps_depth_fade_scales[0] + k_ps_depth_fade_offset[0]);
		float4 fade_factor1=	saturate(view_space_scene_depth.xxxx * k_ps_depth_fade_scales[1] + k_ps_depth_fade_offset[1]);
	
		float4 noise_values0=	sample2D(k_ps_sampler_patchy_buffer0, screen_normalized_uv);
		float4 noise_values1=	sample2D(k_ps_sampler_patchy_buffer1, screen_normalized_uv);
		noise_values0 *= noise_values0;
		noise_values1 *= noise_values1;
				
		// The line integral of fog is simply the sum of the products of fade factors and noise values
		float optical_depth= dot(fade_factor0, noise_values0) + dot(fade_factor1, noise_values1);

		// scattering calculations	
//		inscatter=		1.0f-exp2(optical_depth * k_ps_optical_depth_scale.x);			// optical depth scale
		inv_inscatter=	exp2(optical_depth * k_ps_optical_depth_scale.x);			// optical depth scale
	}
	
	float3 patchyColor = lerp(k_ps_tint_color2.rgb, k_ps_tint_color.rgb, inv_inscatter);

	return apply_exposure(float4(patchyColor, inv_inscatter));
}



BEGIN_TECHNIQUE albedo
{
	pass screen
	{
		SET_VERTEX_SHADER(patchy_prepass_vs());
		SET_PIXEL_SHADER(patchy_prepass_ps());
	}
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(patchy_vs());
		SET_PIXEL_SHADER(patchy_ps());
	}
}

