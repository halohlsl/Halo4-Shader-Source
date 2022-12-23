#include "core/core.fxh"
#include "core/core_vertex_types.fxh"

#include "deform.fxh"
#include "exposure.fxh"
#include "../utility/wind.fxh"


#include "decorators_registers.fxh"

#define SIMPLE_LIGHT_DATA v_simple_lights
#define SIMPLE_LIGHT_COUNT v_simple_light_count
#undef dynamic_lights_use_array_notation			// decorators dont use array notation, they use loop-friendly notation
#include "lighting/simple_lights.fxh"

/*
#include "shared/atmosphere.fx"
#include "decorators/decorators.h"
*/

#if DX_VERSION == 11
#include "packed_vector.fxh"
#endif

#define k_decorator_alpha_test_threshold 0.5f

#define pi 3.14159265358979323846

// decorator shader is defined as 'world' vertex type, even though it really doesn't have a vertex type - it does its own custom vertex fetches
//@generate decorator

/*
	POSITION	0:		vertex position
	TEXCOORD	0:		vertex texcoord
	POSITION	1:		instance position
	NORMAL		1:		instance quaternion
	COLOR		1:		instance color
	POSITION	2:		vertex index
*/

// 228
#define sun_direction vs_analytical_light_direction
// 229
#define sun_color vs_analytical_light_intensity



//#include "templated/analytical_mask.fx"

float compute_antialias_blur_scalar(in float3 fragment_to_camera_world)
{
	float weighted_speed=	vs_object_velocity.w;
	float distance=			length(fragment_to_camera_world.xyz);
	float screen_speed=		weighted_speed / distance;						// approximate
	float output_alpha=		saturate(vs_antialias_scalars.z + vs_antialias_scalars.w * saturate(vs_antialias_scalars.x / (vs_antialias_scalars.y + screen_speed)));		// this provides a much smoother falloff than a straight linear scale
	return output_alpha;
}



#define vertex_compression_scale vs_mesh_position_compression_scale
#define vertex_compression_offset vs_mesh_position_compression_offset
#define texture_compression vs_mesh_uv_compression_scale_offset


LOCAL_SAMPLER2D(diffuse_texture, 0);			// pixel shader


#if !defined(xenon) && (DX_VERSION != 11)

struct s_decorator_vertex_output
{
	float4	position			:	SV_Position;
	float2	texcoord			:	TEXCOORD0;
	float3	world_position		:	TEXCOORD1;
};

s_decorator_vertex_output default_vs(
	float4 vertex_position : SV_Position0,
	float2 vertex_texcoord : TEXCOORD0)
{
	s_decorator_vertex_output output;

	// decompress position
	vertex_position.xyz = vertex_position.xyz * vertex_compression_scale.xyz + vertex_compression_offset.xyz;

	output.world_position= quaternion_transform_point(instance_quaternion, vertex_position.xyz) * instance_position_and_scale.w + instance_position_and_scale.xyz;
	output.position= mul(float4(output.world_position.xyz, 1.0f), vs_view_view_projection_matrix);
	output.texcoord= vertex_texcoord.xy * texture_compression.xy + texture_compression.zw;
	return output;
}

float4 default_ps(
	in float4 screen_position : SV_Position,
	in float2 texcoord : TEXCOORD0,
	in float3 world_position : TEXCOORD1) : SV_Target0
{
	float4 diffuse_albedo= sample2D(diffuse_texture, texcoord);
	clip(diffuse_albedo.a - k_decorator_alpha_test_threshold);				// alpha test

	float4 color= diffuse_albedo * pc_ambient_light * ps_view_exposure.rrrr;

	// blend in selection cursor
	float dist= distance(world_position, selection_point.xyz);
	float alpha= step(dist, selection_point.w);
	alpha *= selection_color.w;
	color.rgb= lerp(color.rgb, selection_color.rgb, alpha);

	// dim materials by wet
	//color.rgb*= k_ps_wetness_coefficients.x;
	return apply_exposure(color);
}



#else	// xenon

#if DX_VERSION == 11
struct s_decorator_vertex_input
{
	float4 position : POSITION0;
	float2 texcoord : TEXCOORD0;
	float3 normal : NORMAL0;
};

struct s_decorator_instance_input
{
	uint position : POSITION1;
	uint4 auxilary_info : COLOR2;
	float4 quaternion : NORMAL1;
	float4 color : COLOR1;
};
#endif


void default_vs(
#if DX_VERSION == 11
	in s_decorator_vertex_input vertex_input,
	in s_decorator_instance_input instance_input,
	in uint vertex_index : SV_VertexID,
#else
	in int index						:	INDEX,
#endif
	out float4	out_position			:	SV_Position,
	out float4	out_texcoord			:	TEXCOORD0,
	out float4	out_ambient_light		:	TEXCOORD1
	)
{
#ifdef XENON
	// what instance are we? - compute index to fetch from the instance stream
	int instance_index = floor(( index + 0.5 ) / instance_data.y);
#endif
	
	// fetch instance data
	float4 instance_position;
	float4 instance_auxilary_info;
#ifdef XENON	
	asm
	{
		vfetch instance_auxilary_info,	instance_index, color2;
		vfetch instance_position,	instance_index, position1;
	};
#else
	instance_position = float4(UnpackUHEND3N(instance_input.position), 0);
	instance_auxilary_info = instance_input.auxilary_info.wzyx;
#endif
	instance_position.xyz= instance_position.xyz * instance_compression_scale.xyz + instance_compression_offset.xyz;

	float3 camera_to_vertex= (instance_position.xyz - vs_view_camera_position);
	float distance= sqrt(dot(camera_to_vertex, camera_to_vertex));
	out_ambient_light.a= 1;


	// if the decorator is not completely faded
	{
		float4 instance_quaternion;
		float4 instance_color;
#ifdef XENON		
		asm
		{
			vfetch instance_quaternion, instance_index, normal1;
			vfetch instance_color, instance_index.x, color1;
		};
#else
		instance_quaternion = instance_input.quaternion.wzyx;
		instance_color = instance_input.color;
#endif

		{
			float type_index= instance_auxilary_info.x;
			float motion_scale= instance_auxilary_info.y/256;

#ifdef XENON			
			// compute the index index to fetch from the index buffer stream
			float vertex_index= index - instance_index* instance_data.y;


			vertex_index=min(vertex_index,instance_data.y-2);
#endif			
			out_ambient_light.a=1-saturate((vertex_index-instance_data.z)*instance_data.w);

			{

#ifdef XENON			
				vertex_index+= type_index * instance_data.x;
#endif


				// fetch the actual vertex
				float4 vertex_position;
				float2 vertex_texcoord;
				float3 vertex_normal;
#ifdef XENON				
				asm
				{
					vfetch vertex_position,	vertex_index.x, position0;
					vfetch vertex_texcoord.xy, vertex_index.x, texcoord0;
					vfetch vertex_normal.xyz, vertex_index.x, normal0;
				};
#else
				vertex_position = vertex_input.position;
				vertex_texcoord = vertex_input.texcoord;
				vertex_normal = vertex_input.normal;				
#endif				
				vertex_position.xyz= vertex_position.xyz * vertex_compression_scale.xyz + vertex_compression_offset.xyz;
				vertex_texcoord= vertex_texcoord.xy * texture_compression.xy + texture_compression.zw;

				float height_scale= 1.0f;
				float2 wind_vector= 0.0f;

		#ifdef DECORATOR_WIND
				// apply wind
				wind_vector= sample_wind(instance_position.xy);
				motion_scale *= saturate(vertex_position.z);										// apply model motion scale (increases linearly up to the top)
				wind_vector.xy *= motion_scale;														// modulate wind vector by motion scale

				// calculate height offset	(change in height because of bending from wind)
				float wind_squared= dot(wind_vector.xy, wind_vector.xy);							// how far did we move?
				float instance_scale= dot(instance_quaternion.xyzw, instance_quaternion.xyzw);		// scale value
				float height_squared= (instance_scale * vertex_position.z) + 0.01;
				height_scale= sqrt(height_squared / (height_squared + wind_squared));
		#endif // DECORATOR_WIND

		#ifdef DECORATOR_WAVY
				float phase= vertex_position.z * wave_flow.w + wind_data2.w * wave_flow.z + dot(instance_position.xy, wave_flow.xy);
				float wave= motion_scale * saturate(abs(vertex_position.z)) * sin(phase);
				vertex_position.x += wave;
		#endif // DECORATOR_WAVY

				// combine the instance position with the mesh position
				float4 world_position= vertex_position;
				vertex_position.z *= height_scale;

				float3 rotated_position= quaternion_transform_point(instance_quaternion, vertex_position.xyz);
				world_position.xyz= rotated_position + instance_position.xyz;										// max scale of 2.0 is built into vertex compression
				world_position.xy += wind_vector.xy * height_scale;													// apply wind vector after transformation

				out_position= mul(float4(world_position.xyz, 1.0f), vs_view_view_projection_matrix);

		#ifdef DECORATOR_SHADED_LIGHT
				float3 world_normal= rotated_position;
		#else
				float3 world_normal= quaternion_transform_point(instance_quaternion, vertex_normal.xyz);
		#endif
				world_normal= normalize(world_normal);					// get rid of scale

				float3 fragment_to_camera_world = vs_view_camera_position - world_position.xyz;
				float3 view_dir= normalize(fragment_to_camera_world);

				float3 diffuse_dynamic_light= 0.0f;
		#ifdef DECORATOR_DYNAMIC_LIGHTS
				// point normal towards camera (two-sided only!)
				float3 two_sided_normal= world_normal * sign(dot(world_normal, fragment_to_camera_world));

				// accumulate dynamic lights
				calc_simple_lights_analytical_diffuse_translucent(
					world_position,
					two_sided_normal,
					translucency,
					diffuse_dynamic_light);
		#endif // DECORATOR_DYNAMIC_LIGHTS

				out_texcoord.xy= vertex_texcoord;
				out_texcoord.zw= 0.0f;

				// unpack RGBk
				instance_color.rgb = UnpackRGBk(instance_color.rgba);
				out_ambient_light.rgb = instance_color.rgb + diffuse_dynamic_light;

				if (instance_auxilary_info.w>1)
				{
					// recover sun percentage
					float sunamount = instance_auxilary_info.w / 255.0;

					// sun, back to calculation in the vertex shader to get to the tint
					float sunfactor = abs(dot(sun_direction,world_normal))*0.75 + 0.25;
					sunfactor *= sunamount;

					// we need to factor in the tint, but we don't really have it
					float scale = maxcomp(instance_color.rgb);
					out_ambient_light.rgb += sunfactor * sun_color * instance_color.rgb / scale;
				}

			#ifdef DECORATOR_SHADED_LIGHT
				float z = dot(rotated_position, sun_direction);
				float w = sqrt(dot(rotated_position, rotated_position));
				out_texcoord.z = z / w;
			#endif
			}
		}
	}
}

// ***************************************
// WARNING   WARNING   WARNING
// ***************************************
//    be careful changing this code.  it is optimized to use very few GPRs + interpolators
//			current optimized shader:	7 instructions, 2 gprs
[reduceTempRegUsage(3)]
float4 default_ps(
	in float4	screen_position		:	SV_Position,
	in float4	texcoord	:	TEXCOORD0,	// z coordinate is unclamped cosine lobe for the DECORATOR_SHADED_LIGHT 'sun'
	in float4	light		:	TEXCOORD1	// w: cut from decimation
	) : SV_Target0								// this is RGBk
{
	// these decorators mod light by this term
	float4 lightMod = 1;
#ifdef DECORATOR_SHADED_LIGHT
	lightMod.rgb = saturate(texcoord.z) * contrast.y + contrast.x;
#endif

	// modify lighting
	light = light * lightMod;

	// texture sample
	float4 color = sample2DGamma(diffuse_texture, texcoord.xy);

	// modulate by vertex calculations of color, DECORATOR_SHADED_LIGHT, sun
	color *= light;

	// alpha-clip
	clip(color.a - k_decorator_alpha_test_threshold);

	// return it as RGBk
	color = PackRGBk(color.rgb);
	return color;
}

#endif // XENON

BEGIN_TECHNIQUE _default
{
	pass decorator
	{
		SET_VERTEX_SHADER(default_vs());
		SET_PIXEL_SHADER(default_ps());
	}
}
