#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "particleize_registers.fxh"


#if !defined(xenon)
// PC doesn't do anything and isn't run

struct s_screen_vertex_output
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
    float4 color:			TEXCOORD1;
};

s_screen_vertex_output default_vs(const in s_screen_vertex input)
{
	s_screen_vertex_output output;
	output.position=	float4(input.position.xy, 0.0, 1.0);
	output.texcoord=	input.texcoord;
	output.color=		input.color;
	return output;
}


float4 default_ps(const in s_screen_vertex_output input) : SV_Target
{
 	return input.color;
}

#else

void default_vs(
	in uint index : SV_VertexID,
	out float4 position : SV_Position,
	out float4 color : SV_Target0,
	out float psize : PSIZE)
{
	// setup frame
	float4 frame[3] = { vs_forward, vs_right, vs_up };

	// set base psize
	psize = vs_pointsize_time_radius.x;
	
	// grab time 
	float t0 = vs_pointsize_time_radius.y;
	float t1 = vs_pointsize_time_radius.z;
	
	// get location in pixel coords based upon index
	// wrap index at window_width
	// have care, these need to exactly iterate over the window or else you'll get artifacts!
	float2 loc;
	float findex = index+0.5;
	loc.x = trunc(fmod(findex,vs_window_size.x));
	loc.y = floor(findex/vs_window_size.x);
	
	// scale and offset normalized uv on the texture for sampling
	float2 texture_uv = loc.xy/vs_texture_size.xy + vs_texture_size.zw;
	
	// sample depth	
	float4 input;
	asm
	{
		tfetch2D input, texture_uv.xy, depth_sampler, MinFilter=point, MagFilter=point, MipFilter=point, AnisoFilter=disabled, UnnormalizedTextureCoords=false, UseComputedLOD=false,  UseRegisterGradients=false
	};
	
	// reconstruct depth
	input *= 255;
	float depth = (input.w*65536 + input.z*256 + input.y) / 16777215;
	
	// save off stencil
	float stencil = input.x;
	
	// was anything rendered at this pixel?
	if (stencil == 0)
	{
		position = float4(0, 0, -1, 1);
		color = 0;
	}
	else
	{
		// get output color
		asm
		{
			tfetch2D color, texture_uv.xy, accum_sampler, MinFilter=point, MagFilter=point, MipFilter=point, AnisoFilter=disabled, UnnormalizedTextureCoords=false, UseComputedLOD=false,  UseRegisterGradients=false
		};
		
		// clip space location, scale and offset uv in the window + depth
		float3 clip;
		clip.xy = loc.xy/vs_window_size.xy;
		clip.x = clip.x * 2 - 1;
		clip.y = (1-clip.y) * 2 - 1;
		clip.z = depth;
		
		// undo the projection 
		float4 world = mul( float4(clip,1), vs_shadow_projection);
		world /= world.w;
		
		// extract motion frame data
		float3 forward = frame[0].xyz;
		float3 right = frame[1].xyz;
		float3 up = frame[2].xyz;
		float distance = frame[0].w;
		float spread = frame[1].w;
		
		// world space simulation
		float r0 = (frac(world.x*343 + world.y*6561 + world.z*15)*2-1) * spread;
		float r1 = (frac(world.x*15 + world.y*343 + world.z*6561)*2-1) * spread;
		float r2 = (frac(world.x*6561 + world.y*15 + world.z*343)*2-1) * spread;
		
		// forward motion
		world.xyz += t0 * forward * distance;
		
		// random cloud
		world.xyz += forward * t1 * r0;
		world.xyz += right * t1 * r1;
		world.xyz += up * t1 * r2;
		
		// project into current camera 
		position = mul(world, vs_view_view_projection_matrix);
	}
}

float4 default_ps(
	in float4 screen_position : SV_Position,
	in float4 color : COLOR0, 
	in float2 uv : SPRITETEXCOORD) : SV_Target0
{
	uv = uv*2 - 1;
	float d = 1 - sqrt(uv.x*uv.x + uv.y*uv.y);
	clip(d);
	return color;
}

#endif



BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

