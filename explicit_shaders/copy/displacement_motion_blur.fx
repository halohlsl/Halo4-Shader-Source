#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "displacement_registers.fxh"

LOCAL_SAMPLER2D(ps_distortion_depth_buffer, 3);


DECLARE_FLOAT_WITH_DEFAULT(motion_blur_intensity_scale, "Overall intensity of motion blur", "", 1.0, 8.0, 2.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(motion_blur_step_scale, "Space between motion blur taps", "", 1.0, 4.0, 2.0);
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(motion_blur_max_steps, "Maximum taps for motion blur", "", 4.0, 16.0, 8.0);
#include "used_float.fxh"


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float4 iterator0:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position =	float4(input.position.xy, 1.0, 1.0);

	float2 uncentered_texture_coords = input.position.xy * float2(0.5f, -0.5f) + 0.5f;		// uncentered means (0, 0) is the center of the upper left pixel
	float2 pixel_coords =	uncentered_texture_coords * vs_resolution_constants.xy + 0.5f;	// pixel coordinates are centered [0.5, resolution-0.5]
	float2 texture_coords =	uncentered_texture_coords + 0.25f * vs_resolution_constants.zw;	// offset half a pixel to center these texture coordinates

	output.iterator0.xy = pixel_coords;
	output.iterator0.zw = texture_coords;

	return output;
}


float4 tex2D_unnormalized(texture_sampler_2d texture_sampler, float2 unnormalized_texcoord)
{
	float4 result;

#if defined(xenon)
	asm
	{
		tfetch2D result, unnormalized_texcoord, texture_sampler, UnnormalizedTextureCoords = true, MagFilter = point, MinFilter = linear, MipFilter = linear, AnisoFilter = disabled
	};
#else
	result= sample2D(texture_sampler, (unnormalized_texcoord + 0.5f) * ps_resolution_constants.zw);
#endif

	return result;
}

#if defined(xenon) || (DX_VERSION == 11)
void ApplyMotionSuck(in float2 suckVector, in float suckStrength, float2 pixelPos, inout float3 motionBlurOffset)
{
	float2 offset = suckVector - pixelPos;
	float displacement = length(offset);
	offset /= displacement;
	motionBlurOffset.rg += float2(offset.x, -offset.y) * displacement * suckStrength * 0.0001f * float2(1.0f, 1280.0f / 720.0f);
}
#endif // defined(xenon)

float4 default_ps(in s_screen_vertex_output input, in SCREEN_POSITION_INPUT(pixelPos)) : SV_Target0
{
	// unpack iterators
	float2 pixel_coords = input.iterator0.xy;
	float2 texture_coords = input.iterator0.zw;

	float3 motion_blur_offset = sample2D(ps_displacement_sampler, texture_coords);

	// center motion blur around 0
	motion_blur_offset.xy -= 512.0f/1023.0f;
	motion_blur_offset.xy *= 2.0;

	// cube the value if we took the cube root in the generation step (for precision enhancement during low motion)
//	motion_blur_offset.xy = motion_blur_offset.xy * motion_blur_offset.xy * motion_blur_offset.xy;

#if defined(xenon) || (DX_VERSION == 11)
	if (ps_motionSuckEnabled)
	{
		ApplyMotionSuck(ps_motionSuckVectorAndLength.xy, ps_motionSuckVectorAndLength.w, pixelPos, motion_blur_offset);
	}
#endif // defined(xenon)

	float distortion_intensity = motion_blur_offset.z;
	float motion_blur_intensity = 1.0 - motion_blur_offset.z;

	if (do_distortion)
	{
		// the blue channel enables pure displacement versus blur
		pixel_coords += lerp(0, motion_blur_offset.xy * ps_distort_constants.xy, distortion_intensity);
		pixel_coords = clamp(pixel_coords, ps_window_bounds.xy, ps_window_bounds.zw);
	}

#if defined(xenon) || (DX_VERSION == 11)

	float4 center_color = tex2D_unnormalized(ps_ldr_buffer, pixel_coords);
	float4 accum_color = center_color * motion_blur_intensity;
	float4 displaced_pixel = center_color;

	float combined_weight = saturate(dot(motion_blur_offset.xy, motion_blur_offset.xy) * motion_blur_intensity);

	[branch]
	if (combined_weight > 0.0f)
	{
#if 1

#if DX_VERSION == 9
		float2 screen_resolution = float2(1280, 720);
#elif DX_VERSION == 11
		float2 screen_resolution = float2(1920, 1080);
#endif

		// scale and clamp the pixel delta
		float2 pixel_delta= screen_resolution * float2(1, -1) * (motion_blur_offset.xy);

		float delta_length= sqrt(dot(pixel_delta, pixel_delta));
		float scale = saturate(ps_pixel_blur_constants.y / delta_length);

		// NOTE:  uv_delta.zw == 2 * uv_delta.xy    (the factor of 2 is stored in ps_pixel_blur_constants.zw...  this is an optimization to save calculation later on)
		float4 uv_delta= ps_pixel_blur_constants.zzww * pixel_delta.xyxy * scale;// * combined_weight;
		uv_delta /= float4(screen_resolution, screen_resolution);

		// the current pixel coordinates are offset by 1 and 2 deltas (we already have the original point sampled above)
		float4 current_pixel_coords= texture_coords.xyxy + uv_delta.xyzw;

		{
			// sample twice in each loop to minimize loop overhead
			for (int i = 0; i < 3; ++ i)
			{
				float4 sample0, sample1;
#ifdef xenon
				asm {
					tfetch2D	sample0, current_pixel_coords.xy, ps_ldr_buffer, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
					tfetch2D	sample1, current_pixel_coords.zw, ps_ldr_buffer, MagFilter = point, MinFilter = point, MipFilter = point, AnisoFilter = disabled
				};
#else
				sample0 = ps_ldr_buffer.t.SampleLevel(ps_bsp_point_sampler, current_pixel_coords.xy, 0);
				sample1 = ps_ldr_buffer.t.SampleLevel(ps_bsp_point_sampler, current_pixel_coords.zw, 0);
#endif

				accum_color += sample0;// * (1 - sample0.a);
				accum_color += sample1;// * (1 - sample1.a);
				current_pixel_coords += uv_delta.zwzw;
			}
		}

		displaced_pixel = accum_color / (6 + motion_blur_intensity); // 6 = 2 taps * 3 loops
#else

		float2 delta_vec = (motion_blur_offset.xy);
		float delta_steps;

		// If we're not doing distortion, improve quality of motion blur by maximizing the usage of the bits
		delta_vec = delta_vec.xy * ps_resolution_constants.xy * motion_blur_intensity_scale;

		float inv_delta_length = 1.0f / length(delta_vec);
		delta_steps = floor(min(1 / (motion_blur_step_scale * inv_delta_length), motion_blur_max_steps));

		delta_vec = delta_vec * inv_delta_length;
		delta_vec = delta_vec * motion_blur_step_scale * ps_resolution_constants.zw;

		float4 coords = texture_coords.xyxy - 0.5 * delta_steps * delta_vec.xyxy;

		for (float i = 0; i < delta_steps && i < 32; i += 2)
		{
			float4 sample0, sample1;
			asm
			{
				tfetch2D sample0, coords.xy, ps_ldr_buffer, MagFilter=point, MinFilter=point, MipFilter=point, UseComputedLOD=false
				tfetch2D sample1, coords.zw, ps_ldr_buffer, MagFilter=point, MinFilter=point, MipFilter=point, UseComputedLOD=false
			};

			accum_color += sample0;
			accum_color += sample1;
			coords += delta_vec.xyxy;
		}

		displaced_pixel = accum_color / (i + motion_blur_intensity);
#endif
	}


#else // xenon

	float4 displaced_pixel = tex2D_unnormalized(ps_ldr_buffer, pixel_coords);

#endif // xenon

	return displaced_pixel;
}


s_screen_vertex_output motion_blur_offset_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position =	float4(input.position.xy, 1.0, 1.0);

	float2 uncentered_texture_coords = input.position.xy * float2(0.5f, -0.5f) + 0.5f;		// uncentered means (0, 0) is the center of the upper left pixel
	float2 pixel_coords =	uncentered_texture_coords * vs_resolution_constants.xy + 0.5f;	// pixel coordinates are centered [0.5, resolution-0.5]
	float2 texture_coords =	uncentered_texture_coords + 0.5f * vs_resolution_constants.zw;	// offset half a pixel to center these texture coordinates

	output.iterator0.xy = (texture_coords - 0.5) * float2(2, -2);
	output.iterator0.zw = texture_coords;

	return output;
}


float4 motion_blur_offset_ps(in s_screen_vertex_output input) : SV_Target0
{
#if defined(xenon) || (DX_VERSION == 11)

	float4 cur_proj = float4(input.iterator0.xy, sample2D(ps_distortion_depth_buffer, input.iterator0.zw).r, 1.0);
	float4 last_proj = mul(cur_proj, transpose(ps_reprojectionMatrix));

	// perspective divide to get back to homogenous screen-space coordinates
	last_proj.xy /= last_proj.w;

	float2 delta_vec = (cur_proj.xy - last_proj.xy);

	if (!do_distortion)
	{
		// If we're not doing distortion, improve quality of motion blur by maximizing the usage of the bits
		delta_vec = delta_vec.xy * ps_resolution_constants.xy * 2 * motion_blur_intensity_scale;

		float inv_delta_length = 1.0f / length(delta_vec);
		float delta_steps = min(1.0 / (motion_blur_step_scale * inv_delta_length), motion_blur_max_steps);

		delta_vec = delta_vec * inv_delta_length * delta_steps;
		delta_vec /= motion_blur_max_steps;
	}

	return float4(0.5 + 0.5 * delta_vec.xy + 0.5f / 1023.0f, 0, 0);


#else // xenon

	return float4(0.5, 0.5, 0, 0);

#endif // xenon
}


BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE albedo
{
	pass screen
	{
		SET_VERTEX_SHADER(motion_blur_offset_vs());
		SET_PIXEL_SHADER(motion_blur_offset_ps());
	}
}




