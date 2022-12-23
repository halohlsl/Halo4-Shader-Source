#include "core/core.fxh"
#include "ripple_registers.fxh"
#include "../materials/water/water_registers.fxh"

struct s_ripple_vertex_input
{
	uint index 		: SV_VertexID;
	uint instance	: SV_instanceID;
};

struct s_ripple_interpolators
{
	float4 position			:SV_Position;
	float4 texcoord			:TEXCOORD0;
	float4 pendulum			:TEXCOORD1;	
	float4 foam				:TEXCOORD2;	
};

// grabbed from function.fx
#define _transition_function_linear		0
#define _transition_function_early		1 // x^0.5
#define _transition_function_very_early	2 // x^0.25
#define _transition_function_late		3 // x^2.0
#define _transition_function_very_late	4 // x^4.0
#define _transition_function_cosine		5 // accelerates in and out
#define _transition_function_one		6
#define _transition_function_zero		7
#define _transition_function_max		8

#define _2pi 6.28318530718f

// grabbed from function.fx
float evaluate_transition_internal(int transition_type, float input)
{
	float output;							
	if (transition_type==_transition_function_linear)
	{
		output= input;
	}
	else if (transition_type==_transition_function_early)
	{
		output= sqrt(input);
	}
	else if (transition_type==_transition_function_very_early)
	{
		output= sqrt(sqrt(input));
	}
	else if (transition_type==_transition_function_late)
	{
		output= input * input;
	}
	else if (transition_type==_transition_function_very_late)
	{
		output= input * input * input * input;
	}
	else if (transition_type==_transition_function_cosine)
	{
		output= cos(_2pi*(input+1));
	}
	else if (transition_type==_transition_function_one)
	{
		output= 1;
	}
	else //if (transition_type==_transition_function_zero)
	{
		output= 0;
	}
	return output;
}

#define k_ripple_corners_number 16
static const float2 k_ripple_corners[k_ripple_corners_number]= 
{ 
	float2(-1, -1), float2(0, -1),  float2(-1, 0), float2(0, 0),
	float2(0, -1), float2(1, -1),  float2(0, 0), float2(1, 0),
	float2(0, 0), float2(1, 0),  float2(0, 1), float2(1, 1),
	float2(-1, 0), float2(0, 0),  float2(-1, 1), float2(0, 1),
};


s_ripple_interpolators ripple_apply_vs(s_ripple_vertex_input IN)
{			
	// fetch ripple
	int ripple_index = IN.instance / 4;
	s_ripple ripple = vs_ripple_buffer[ripple_index];
	
	s_ripple_interpolators OUT;
	if (ripple.life > 0)
	{		
		int corner_index = IN.index + ((IN.instance & 3) * 4);

		float3 shock_dir;
		if ( length(ripple.shock) < 0.01f ) 
		{
			shock_dir= float3(1.0f, 0.0f, 0.0f);
		}
		else
		{
			shock_dir= normalize(float3(ripple.shock, 0.0f));
		}

		float2 corner= k_ripple_corners[corner_index];

		float2 position;
		//position.x= -corner.x * shock_dir.x - corner.y * shock_dir.y;
		//position.y= corner.x * shock_dir.y - corner.y * shock_dir.x;

		position.y= -corner.x * shock_dir.x - corner.y * shock_dir.y;
		position.x= corner.x * shock_dir.y - corner.y * shock_dir.x;

		position= position*ripple.size + ripple.position;		

		position= (position - k_vs_camera_position.xy) / k_ripple_buffer_radius;					
		float len= length(position);
		position*= rsqrt(len);		

		position+= k_view_dependent_buffer_center_shifting;		

		float period_in_life= 1.0f - ripple.life/ripple.duration;
		float pattern_index= lerp(ripple.pattern_start_index, ripple.pattern_end_index, evaluate_transition_internal(ripple.func_pattern, period_in_life));

		float ripple_height;
		if ( period_in_life < ripple.rise_period )
		{
			float rise_percentage= max(ripple.rise_period, 0.001f); // avoid to be divded by zero
			ripple_height= lerp(0.0f, ripple.height, evaluate_transition_internal(ripple.func_rise, period_in_life / rise_percentage));
		}
		else
		{
			float descend_percentage= max(1.0f-ripple.rise_period, 0.001f); // avoid to be divded by zero
			ripple_height= lerp(ripple.height, 0.0f, evaluate_transition_internal(ripple.func_descend, (period_in_life - ripple.rise_period)/descend_percentage));			
		}

		// calculate foam 
		float foam_opacity= 0.0f;
		float foam_out_radius= 0.0f;
		float foam_fade_distance= 0.0f; 
		if (ripple.flag_foam && ripple.foam_life>0)		
		{
			float period_in_foam_life= 1.0f - ripple.foam_life/ripple.foam_duration;
			foam_opacity= lerp(1.0f, 0.0f, evaluate_transition_internal(ripple.func_foam, period_in_foam_life));						

			// convert distances from object space into texture space
			if (ripple.flag_foam_game_unit)
			{
				foam_out_radius= ripple.foam_out_radius / ripple.size;
				foam_fade_distance= ripple.foam_fade_distance / ripple.size;
			}
			else
			{
				foam_out_radius= ripple.foam_out_radius;
				foam_fade_distance= ripple.foam_fade_distance;
			}
		}				

		// calculate pendulum
		if ( ripple.flag_pendulum )
		{
			ripple.pendulum_phase= abs(ripple.pendulum_phase); // guarantee always positive
		}
		else
		{
			ripple.pendulum_phase= -1.0f;	
		}

		// output
		OUT.position= float4(position.xy, 0.0f, 1.0f);
		OUT.texcoord= float4(corner*0.5f + 0.5f, pattern_index, ripple_height);
		OUT.pendulum= float4(ripple.pendulum_phase, ripple.pendulum_repeat, 0.0f, 0.0f); 
		OUT.foam= float4(foam_opacity, foam_out_radius, foam_fade_distance, 0.0f);

	}
	else 
	{
		OUT.position= 0.0f;	// invalidate position, kill primitive
		OUT.texcoord= 0.0f;
		OUT.pendulum= 0.0f;
		OUT.foam= 0.0f;
	}
	return OUT;
}

static const float2 k_screen_corners[4]= 
{ 
	float2(-1, -1), 
	float2(1, -1), 
	float2(-1, 1),
	float2(1, 1)
};

s_ripple_interpolators ripple_slope_vs(s_ripple_vertex_input IN)
{		
	float2 corner= k_screen_corners[IN.index];

	s_ripple_interpolators OUT;
	OUT.position= float4(corner, 0, 1);
	OUT.texcoord= float4(corner / 2 + 0.5, 0.0f, 0.0f);
	OUT.pendulum= 0.0f;
	OUT.foam= 0.0f;
	return OUT;
}

// convert normalized 3d texture z coordinate to texture array coordinate
float4 convert_3d_texture_coord_to_array_texture(in texture_sampler_2d_array t, in float3 uvw)
{
	uint width, height, elements;
	t.t.GetDimensions(width, height, elements);
	uvw.z = (frac(uvw.z) * elements);
	float next_z = (uvw.z >= (elements - 1)) ? 0 : (uvw.z + 1);
	return float4(uvw, next_z);
}

float4 ripple_apply_ps( s_ripple_interpolators IN ) :SV_Target0
{	
	//float height= tex3D(tex_ripple_pattern, IN.texcoord.xyz).r ;	
	float4 height_tex;
	float4 texcoord= IN.texcoord;

	float4 ripple_texcoord = convert_3d_texture_coord_to_array_texture(tex_ripple_pattern, texcoord.xyz);
	height_tex = lerp(
		tex_ripple_pattern.t.Sample(tex_ripple_pattern.s, ripple_texcoord.xyz),
		tex_ripple_pattern.t.Sample(tex_ripple_pattern.s, ripple_texcoord.xyw),
		frac(ripple_texcoord.z));

	float height= (height_tex.r - 0.5f) * IN.texcoord.w;
	
	// for pendulum
	[branch]
	if ( IN.pendulum.x > -0.01f)
	{
		float2 direction= IN.texcoord.xy*2.0f - 1.0f;
		float phase= IN.pendulum.x - length(direction) * IN.pendulum.y;
		height*= cos(phase);	
	}

	float4 OUT= 0.0f;	
	OUT.r= height.r;

	// for foam
	[branch]
	if ( IN.foam.x > 0.01f )
	{
		float2 direction= IN.texcoord.xy*2.0f - 1.0f;
		float distance= length(direction);

		distance= max(IN.foam.y - distance, 0.0f);
		float edge_fade= min( distance/max(IN.foam.z, 0.001f), 1.0f);
		OUT.g= edge_fade * IN.foam.x * height_tex.a;			
	}
	
	return OUT;
}

float4 ripple_slope_ps( s_ripple_interpolators IN ) :SV_Target0
{	
	float4 OUT= float4(0.5f, 0.5f, 0.5f, 0.0f);
	float4 texcoord= IN.texcoord;
	float4 tex_x1_y1 = sample2D(tex_ripple_buffer_height, float4(texcoord.xy, 0, 0));

	//[branch]
	//if ( tex_x1_y1.a > 0.1f )
	{
		float4 tex_x2_y1 = tex_ripple_buffer_height.t.Sample(tex_ripple_buffer_height.s, texcoord.xy, int2(1, 0));
		float4 tex_x1_y2 = tex_ripple_buffer_height.t.Sample(tex_ripple_buffer_height.s, texcoord.xy, int2(0, 1));

		float2 slope;
		slope.x= tex_x2_y1.r - tex_x1_y1.r;
		slope.y= tex_x1_y2.r - tex_x1_y1.r;
	   
		// Scale to [0 .. 1]		
		slope= saturate(slope * 0.5f + 0.5f);
		
		float4 org_OUT;
		org_OUT.r= saturate( (tex_x1_y1.r + 1.0f) * 0.5f );
		org_OUT.g= slope.x;
		org_OUT.b= slope.y;
		org_OUT.a= tex_x1_y1.g;

		// damping the brim	
		float2 distance_to_brim= saturate(100.0f *(0.497f - abs(IN.texcoord.xy-0.5f)));
		float lerp_weight= min(distance_to_brim.x, distance_to_brim.y);
		OUT= lerp(OUT, org_OUT, lerp_weight);
	}
	
	return OUT;
}

BEGIN_TECHNIQUE
{
	pass ripple
	{
		SET_VERTEX_SHADER(ripple_apply_vs());
		SET_PIXEL_SHADER(ripple_apply_ps());
	}
}

BEGIN_TECHNIQUE
{
	pass ripple
	{
		SET_VERTEX_SHADER(ripple_slope_vs());
		SET_PIXEL_SHADER(ripple_slope_ps());
	}
}
