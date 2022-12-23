/*
VECTOR_HUD.HLSL
Copyright (c) Microsoft Corporation, 2009. all rights reserved.
05/22/2009 10:41 willclar
*/



#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "vector_hud_registers.fxh"

// ==== SHADER DOCUMENTATION
// shader: vector_hud
// 
// ---- COLOR OUTPUTS
// color output A= primary background color
// color output B= secondary background color
// color output C= highlight color
// color output D= flash color
// 
// ---- SCALAR OUTPUTS
// scalar output A= flash value; if 1, uses 'flash color', if 0 uses blended primary/secondary background
// scalar output B= unused
// scalar output C= unused
// scalar output D= unused
// scalar output E= unused
// scalar output F= unused


// rename entry points
#define vector_hud_line_vs		active_camo_vs
#define vector_hud_line_ps		active_camo_ps
#define vector_hud_geometry_vs	default_vs
#define vector_hud_geometry_ps	default_ps
#define vector_hud_text_vs		albedo_vs
#define vector_hud_text_ps		albedo_ps

#if defined(xenon)	/* implementation of xenon version */

struct s_vector_hud_interpolators
{
	float4 position : SV_Position;
	float2 texcoord : TEXCOORD0;
}; 


s_vector_hud_interpolators vector_hud_line_vs(s_chud_vertex_simple IN)
{
	s_vector_hud_interpolators OUT;
	float4 real_pos = float4(0.0, 0.0, 0.0, 1.0);
	real_pos.x = (IN.position.x * line_pos.z) + line_pos.x;
	real_pos.y = (IN.position.y * line_pos.w) + line_pos.y;
	OUT.position = mul(mat_wvp, real_pos);
	OUT.position.z = z_value.x;
	OUT.texcoord = float2(real_pos.x, real_pos.y);
	return OUT;
}

s_vector_hud_interpolators simple_vs(s_chud_vertex_simple IN)
{
	s_vector_hud_interpolators OUT;
	OUT.position = mul(mat_wvp, float4(IN.position.xy, 0, 1));
	OUT.texcoord = IN.texcoord;
	return OUT;
}

s_vector_hud_interpolators vector_hud_geometry_vs(s_chud_vertex_simple IN) { return simple_vs(IN); }
s_vector_hud_interpolators vector_hud_text_vs(s_chud_vertex_simple IN) { return simple_vs(IN); }



float3 get_chud_rgb()
{
	// LERP
	float3 color= chud_color_output_C*(1.0 - chud_scalar_output_ABCD.x) + chud_color_output_D*chud_scalar_output_ABCD.x;
	
	return color;
}

float4 vector_hud_line_ps(s_vector_hud_interpolators IN) : SV_Target
{
	float4 d;
	d.x =	dot(IN.texcoord.xy, e0.xy) + e0.z;
	d.y =	dot(IN.texcoord.xy, e1.xy) + e1.z;
	d.z =	dot(IN.texcoord.xy, e2.xy) + e2.z;
	d.w =	dot(IN.texcoord.xy, e3.xy) + e3.z;
	clip(d);
	float aa_value = saturate(min(d.x, d.z) / (line_params.w));
	return float4(get_chud_rgb(), vector_hud_alpha * aa_value);
}

float4 vector_hud_geometry_ps(s_vector_hud_interpolators IN) : SV_Target
{
	// We upload the opacity in the red component of the texcoord.
	return float4(get_chud_rgb(), vector_hud_alpha * IN.texcoord.r);
}

float4 vector_hud_text_ps(s_vector_hud_interpolators IN) : SV_Target
{
	float4 color = sample2D(texture_sampler, IN.texcoord);
	return float4(get_chud_rgb(), vector_hud_alpha * color.a);
}



#else /* implementation of pc version */

// NOTE: None of these work!

float4 vector_hud_line_vs(s_chud_vertex_simple IN) : SV_Position { return 0; }
float4 vector_hud_geometry_vs(s_chud_vertex_simple IN) : SV_Position { return 0; }
float4 vector_hud_text_vs(s_chud_vertex_simple IN) : SV_Position { return 0; }

float4 vector_hud_line_ps() : SV_Target { return float4(0, 1, 2, 3); }
float4 vector_hud_geometry_ps() : SV_Target { return float4(0, 1, 2, 3); }
float4 vector_hud_text_ps() : SV_Target { return float4(0, 1, 2, 3); }

#endif //pc/xenon


// end of rename macro
#undef vector_hud_line_vs
#undef vector_hud_line_ps
#undef vector_hud_geometry_vs
#undef vector_hud_geometry_ps
#undef vector_hud_text_vs
#undef vector_hud_text_ps


BEGIN_TECHNIQUE _default
{
	pass chud_simple
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}

BEGIN_TECHNIQUE albedo
{
	pass chud_simple
	{
		SET_VERTEX_SHADER(albedo_vs());
		SET_PIXEL_SHADER(albedo_ps());
	}
}

BEGIN_TECHNIQUE active_camo
{
	pass chud_simple
	{
		SET_VERTEX_SHADER(active_camo_vs());
		SET_PIXEL_SHADER(active_camo_ps());
	}
}
