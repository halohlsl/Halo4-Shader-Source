#if !defined(__PARTICLE_TYPES_FXH)
#define __PARTICLE_TYPES_FXH

#if defined(RENDER_DISTORTION) && !defined(PASS_TANGENT_FRAME)
#define PASS_TANGENT_FRAME
#endif // defined(RENDER_DISTORTION) && !defined(PASS_TANGENT_FRAME)

struct s_particle_interpolators_internal
{
	float4 position0	:SV_Position0;
	float4 color0		:COLOR0;
	float4 color1 : COLOR1;
	float4 texcoord0	:TEXCOORD0;
	float4 texcoord1	:TEXCOORD1;
	float4 texcoord2	:TEXCOORD2;
#if defined(PARTICLE_EXTRA_INTERPOLATOR)
	float4 texcoord3	:TEXCOORD3;
#endif //defined(PARTICLE_EXTRA_INTERPOLATOR)
#if defined(PASS_TANGENT_FRAME)
	float4 texcoord4	:TEXCOORD4;
	float4 color2		:COLOR2;
#endif // defined(PASS_TANGENT_FRAME)
#if defined(FRESNEL_ENABLED)
	float3 texcoord5 		:TEXCOORD5;
#endif // defined(FRESNEL_ENABLED)
};

struct s_particle_interpolated_values
{
    float4 position;
    float2 texcoord_sprite0; // consecutive frames of an animated bitmap
    float2 texcoord_billboard;
    float black_point; // avoid using interpolator for constant-per-particle value?
    float white_point; // avoid using interpolator for constant-per-particle value?
    float palette; // avoid using interpolator for constant-per-particle value?
    float4 color; // COLOR semantic will not clamp to [0,1].
    float3 colorAdd;
#if defined(PASS_TANGENT_FRAME)
	float3 tangent;
	float3 binormal;
#endif // defined(PASS_TANGENT_FRAME)
	float3 normal;
	float depth;
  float2 custom_value;
#if defined(PARTICLE_EXTRA_INTERPOLATOR)
	float4 custom_value2;
#endif //defined(PARTICLE_EXTRA_INTERPOLATOR)
#if defined(FRESNEL_ENABLED)
	float3 viewDir;
#endif // defined(FRESNEL_ENABLED)
};

// Bungie sez:
// We can save interpolator cost by eliminating unused interpolators from particular pixel shaders.
// But that causes the vertex shader to get patched at runtime, which is a big CPU hit.
// So instead we share interpolators for various purposes, and hope they never conflict
// end Bungie sez
s_particle_interpolators_internal write_particle_interpolators(s_particle_interpolated_values particle_values)
{
	s_particle_interpolators_internal interpolators = (s_particle_interpolators_internal)0;
	
	interpolators.position0= particle_values.position;
	interpolators.color0= particle_values.color;
	
	interpolators.color1 = float4(particle_values.colorAdd, particle_values.black_point);
	
#if defined(PASS_TANGENT_FRAME)
	interpolators.color2= float4(particle_values.tangent, 0.0f);
	interpolators.texcoord4 = float4(particle_values.binormal, 0.0f);
#endif // defined(PASS_TANGENT_FRAME)
	
	interpolators.texcoord0= float4(particle_values.texcoord_sprite0, particle_values.texcoord_billboard);
	interpolators.texcoord1= float4(particle_values.normal, particle_values.white_point);
	interpolators.texcoord2= float4(particle_values.custom_value, particle_values.depth, particle_values.palette);
#if defined(PARTICLE_EXTRA_INTERPOLATOR)
	interpolators.texcoord3= particle_values.custom_value2;
#endif //defined(PARTICLE_EXTRA_INTERPOLATOR)

#if defined(FRESNEL_ENABLED)
	interpolators.texcoord5= float4(particle_values.viewDir, 0.0);
#endif // defined(FRESNEL_ENABLED)

	return interpolators;
}

s_particle_interpolated_values read_particle_interpolators(s_particle_interpolators_internal interpolators)
{
	s_particle_interpolated_values particle_values = (s_particle_interpolated_values)0;
	
	particle_values.position= interpolators.position0;
	particle_values.color= interpolators.color0;
	particle_values.colorAdd = interpolators.color1.xyz;
	particle_values.black_point= interpolators.color1.w;
	
#if defined(PASS_TANGENT_FRAME)
	particle_values.tangent = interpolators.color2.xyz;
	particle_values.binormal = interpolators.texcoord4.xyz;
#endif // defined(PASS_TANGENT_FRAME)

	particle_values.texcoord_sprite0= interpolators.texcoord0.xy;
	particle_values.texcoord_billboard= interpolators.texcoord0.zw;
	particle_values.normal= interpolators.texcoord1.xyz;
	particle_values.white_point= interpolators.texcoord1.w;
	particle_values.custom_value= interpolators.texcoord2.xy;
	particle_values.depth= interpolators.texcoord2.z;
	particle_values.palette= interpolators.texcoord2.w;
#if defined(PARTICLE_EXTRA_INTERPOLATOR)
	particle_values.custom_value2= interpolators.texcoord3;
#endif //defined(PARTICLE_EXTRA_INTERPOLATOR)

#if defined(FRESNEL_ENABLED)
	particle_values.viewDir = interpolators.texcoord5.xyz;
#endif // defined(FRESNEL_ENABLED)

	return particle_values;
}

struct s_particle_memexported_state
{
	float3	m_position;
	float3	m_velocity;
	float3	m_axis;
	float	m_physical_rotation;
	float	m_manual_rotation;
	float	m_animated_frame;
	float	m_manual_frame;
	float	m_rotational_velocity;
	float	m_frame_velocity;
	float	m_birth_time;
	float	m_inverse_lifespan;
	float	m_age;
	float4	m_color;
	float4	m_initial_color;
	float4	m_random;
	float4	m_random2;
	float	m_size;
	float	m_aspect;
	float	m_intensity;
	float	m_black_point;
	float	m_white_point;
	float	m_palette_v;
	float	m_game_simulation_a;
	float	m_game_simulation_b;
};


#endif 	// !defined(__PARTICLE_TYPES_FXH)