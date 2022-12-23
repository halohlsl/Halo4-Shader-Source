#include "core/core.fxh"
#include "core/core_vertex_types.fxh"
#include "postprocessing/postprocess_parameters.fxh"
#include "cubemap_registers.fxh"


LOCAL_SAMPLERCUBE(source_sampler,	0);


struct s_vertex_output_screen_tex
{
    float4 position:		SV_Position;
    float2 texcoord:		TEXCOORD0;
};

s_vertex_output_screen_tex default_vs_tex(const in s_screen_vertex input)
{
	s_vertex_output_screen_tex output;
	output.position=	float4(input.position.xy, 1.0, 1.0);
	output.texcoord=	input.texcoord;
	return output;
}


void direction_to_theta_phi(in float3 direction, out float theta, out float phi)
{
	theta= atan2(direction.y, direction.x);
	phi= acos(direction.z);
}

float3 theta_phi_to_direction(in float theta, float phi)
{
	float3 direction;
	float sin_phi;
	direction.z= cos(phi);
	direction.x= sin(phi) * cos(theta);
	direction.y= sin(phi) * sin(theta);
	return direction;
}

float4 sample_cube_map(float3 direction)
{
	direction.y= -direction.y;
	return sampleCUBE(source_sampler, direction);
}

float4 default_ps_tex(const in s_vertex_output_screen_tex input) : SV_Target
{
	float2 sample0 = input.texcoord;
	
	float3 direction;
	direction= forward - (sample0.y*2-1)*up - (sample0.x*2-1)*left;
	direction= direction * (1.0 / sqrt(dot(direction, direction)));

	float theta, phi;
	direction_to_theta_phi(direction, theta, phi);
		
	float4 color= 0.0f;
	
	color += 1   * sample_cube_map(theta_phi_to_direction(theta, phi - delta*5));
	color += 10  * sample_cube_map(theta_phi_to_direction(theta, phi - delta*4));
	color += 45  * sample_cube_map(theta_phi_to_direction(theta, phi - delta*3));
	color += 120 * sample_cube_map(theta_phi_to_direction(theta, phi - delta*2));
	color += 210 * sample_cube_map(theta_phi_to_direction(theta, phi - delta));
	color += 252 * sample_cube_map(direction);
	color += 210 * sample_cube_map(theta_phi_to_direction(theta, phi + delta));
	color += 120 * sample_cube_map(theta_phi_to_direction(theta, phi + delta*2));
	color += 45  * sample_cube_map(theta_phi_to_direction(theta, phi + delta*3));
	color += 10  * sample_cube_map(theta_phi_to_direction(theta, phi + delta*4));
	color += 1   * sample_cube_map(theta_phi_to_direction(theta, phi + delta*5));
	color *= (1/1024.0);

	return color;
}

BEGIN_TECHNIQUE _default
{
	pass screen
	{
		SET_VERTEX_SHADER(default_vs_tex());
		SET_PIXEL_SHADER(default_ps_tex());
	}
}

