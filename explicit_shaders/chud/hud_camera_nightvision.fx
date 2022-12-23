#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "postprocessing/postprocess_textures.fxh"
#include "exposure.fxh"
#include "hud_camera_nightvision_registers.fxh"


float3 calculate_world_position(float2 texcoord, float depth)
{
	float4 clip_space_position = float4(texcoord.xy, depth, 1.0f);
	float4 world_space_position = mul(clip_space_position, transpose(ps_screen_to_world));
	return world_space_position.xyz / world_space_position.w;
}

float calculate_pixel_distance(float2 texcoord, float depth)
{
	float3 delta= calculate_world_position(texcoord, depth);
	float pixel_distance= sqrt(dot(delta, delta));
	return pixel_distance;
}


float evaluate_smooth_falloff(float distance)
{
//	constant 1.0, then smooth falloff to zero at a certain distance:
//
//	at distance D
//	has value (2^-C)		C=8  (1/256)
//	falloff sharpness S		S=8
//	let B= (C^(1/S))/D		stored in falloff.x
//	
//		equation:	f(x)=	2^(-(x*B)^S)			NOTE: for small S powers of 2, this can be expanded almost entirely in scalar ops
//

	return exp2(-pow(distance * ps_falloff.x, 8));
}


struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}


float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
#if !defined(xenon)

	float4 color = sample2D(ps_depth_sampler, input.texcoord);

#else // !defined(xenon)

	float2 texcoord = input.texcoord;
	
	float mask= sample2D(ps_mask_sampler, texcoord).r;

	// active values:	mask, texcoord (3)
	
	float4 color= 0.0f;	
	if (mask > 0.0f)
	{
		float color_o;
		{
			asm
			{
				tfetch2D color_o.x, texcoord, ps_depth_sampler, OffsetX= 0, OffsetY= 0
			};	
		}

		// active values:	mask, texcoord, color_o (4)

		int index;
		float pulse_boost;
		[isolate]
		{
			float value;
			asm
			{
				tfetch2D value.b, texcoord, ps_color_sampler, OffsetX= 0, OffsetY= 0
			};	
			index= floor(value * 4 + 0.5f);
		
			float pixel_distance= calculate_pixel_distance(texcoord, color_o);
			mask *= evaluate_smooth_falloff(pixel_distance);
			// calculate pulse
			{
				float ping_distance= ps_ping.x;
				float after_ping= (ping_distance - pixel_distance);		// 0 at wavefront, positive closer to player
				pulse_boost= pow(saturate(1.0f + ps_ping.z * after_ping), 4.0f) * step(pixel_distance, ping_distance);
			}
		}

		// active values:	mask, texcoord, color_o, pulse_boost, index (5/6)

		float gradient_magnitude;
//		[isolate]
		{
			float color_px, color_nx;
			float color_py, color_ny;
			asm
			{
				tfetch2D color_px.x, texcoord, ps_depth_sampler, OffsetX= 1, OffsetY= 0
				tfetch2D color_nx.x, texcoord, ps_depth_sampler, OffsetX= -1, OffsetY= 0
				tfetch2D color_py.x, texcoord, ps_depth_sampler, OffsetX= 0, OffsetY= 1
				tfetch2D color_ny.x, texcoord, ps_depth_sampler, OffsetX= 0, OffsetY= -1
			};
			float2 laplacian;
			laplacian.x= (color_px + color_nx) - 2 * color_o;
			laplacian.y= (color_py + color_ny) - 2 * color_o;
			gradient_magnitude= saturate(sqrt(dot(laplacian.xy, laplacian.xy)) / color_o.r);		//
		}
		
		// active values:	mask, pulse_boost, index (2/3)	
		
		{
			// convert to [0..4]
			float3 pulse_color= ps_colors[index][1];
			float4 default_color= ps_colors[index][0];
			
			color.rgb= gradient_magnitude * (default_color.rgb + pulse_color.rgb * pulse_boost);
			color.a= apply_exposure_alpha(default_color.a);
			
			color *= mask;
		}
	}
#endif // !defined(xenon)

	return color;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
