#ifndef __SSAO_REGISTERS_H_
#ifndef DEFINE_CPP_CONSTANTS
#define __SSAO_REGISTERS_H_
#endif

#define NUMBER_OF_SSAO_SAMPLES 16				// this is used for array declarations

#if DX_VERSION == 9

// declares layout of GPU constants for screen-space occlusion effects

#ifndef FLOAT_CONSTANT_NAME
#define FLOAT_CONSTANT_NAME(n) c##n
#endif
#ifndef INT_CONSTANT_NAME
#define INT_CONSTANT_NAME(n) i##n
#endif

#define k_SSAO_texture_to_camera_matrix_register_index			FLOAT_CONSTANT_NAME(136)
#define k_SSAO_camera_to_texture_matrix_register_index			FLOAT_CONSTANT_NAME(140)
#define k_SSAO_world_to_camera_matrix_register_index    		FLOAT_CONSTANT_NAME(144)

#define k_SSAO_parameters_register_index						FLOAT_CONSTANT_NAME(148)	// this packs the following constants as: x = SSAO contribution strength, 
																							//										  y = screen-space SSAO radius scale
																							//										  z = SSAO vertical angle contribution strength
																							//										  w = distant occlusion drop-off strength
#define k_SSAO_pixel_size_register_index						FLOAT_CONSTANT_NAME(152)
#define k_SSAO_filter_parameters_register_index					FLOAT_CONSTANT_NAME(156)	// This packs the following parameters as: x = depth delta threshold, y = normals delta threshold
#define k_SSAO_number_ssao_samples_register_index				FLOAT_CONSTANT_NAME(157)
#define k_SSAO_cutoff_far_away_distance_depth_register_index	FLOAT_CONSTANT_NAME(158)

#define k_SSAO_random_offsets_register_index					FLOAT_CONSTANT_NAME(160)	// This packs the offsets for our samples, which can be from 4 to 32 float4 constants

#define k_SSAO_number_sample_iterations_register_index			INT_CONSTANT_NAME(0)	

DECLARE_PARAMETER( float4x4,   texture_to_camera_matrix,   			k_SSAO_texture_to_camera_matrix_register_index			);
DECLARE_PARAMETER( float4x4,   camera_to_texture_matrix,   			k_SSAO_camera_to_texture_matrix_register_index			);
DECLARE_PARAMETER( float4x4,   world_to_camera_matrix,     			k_SSAO_world_to_camera_matrix_register_index			);
DECLARE_PARAMETER( float4,		ssao_parameters,						k_SSAO_parameters_register_index						);	// this packs the following constants as: x = SSAO contribution strength,
																																//										  y = screen-space SSAO radius scale
																																//										  z = SSAO vertical angle contribution strength
																																//										  w = distant occlusion drop-off strength

DECLARE_PARAMETER( float4,     pixel_size,								k_SSAO_pixel_size_register_index						);
DECLARE_PARAMETER( float4,		ssao_filter_parameters,					k_SSAO_filter_parameters_register_index					);  // This packs the following parameters as: x = depth delta threshold,
																																//										   y = normals delta threshold

DECLARE_PARAMETER( float,      number_of_ssao_samples,					k_SSAO_number_ssao_samples_register_index				);
DECLARE_PARAMETER( int,        number_of_sample_iterations,			k_SSAO_number_sample_iterations_register_index			);
DECLARE_PARAMETER( float,      cutoff_far_away_distance_depth,			k_SSAO_cutoff_far_away_distance_depth_register_index	);


DECLARE_PARAMETER( float4,		random_offsets[NUMBER_OF_SSAO_SAMPLES], k_SSAO_random_offsets_register_index );

//................................................
// Samplers:
//................................................

sampler2D depth_sampler			 : register( s0 );
sampler2D normals_sampler		 : register( s1 );
sampler2D random_offsets_sampler : register( s2 );
sampler2D ssao_sampler			 : register( s3 );
sampler2D depth_low_res_sampler	 : register( s4 );

#elif DX_VERSION == 11

CBUFFER_BEGIN(SSAOPS)
	CBUFFER_CONST(SSAOPS,			float4x4,   texture_to_camera_matrix,   				k_SSAO_texture_to_camera_matrix_register_index)
	CBUFFER_CONST(SSAOPS,			float4x4,   camera_to_texture_matrix,   				k_SSAO_camera_to_texture_matrix_register_index)
	CBUFFER_CONST(SSAOPS,			float4x4,   world_to_camera_matrix,     				k_SSAO_world_to_camera_matrix_register_index)
	CBUFFER_CONST(SSAOPS,			float4,		ssao_parameters,							k_SSAO_parameters_register_index)
	CBUFFER_CONST(SSAOPS,			float4,     pixel_size,									k_SSAO_pixel_size_register_index)
	CBUFFER_CONST(SSAOPS,			float4,		ssao_filter_parameters,						k_SSAO_filter_parameters_register_index)
	CBUFFER_CONST(SSAOPS,			float,      number_of_ssao_samples,						k_SSAO_number_ssao_samples_register_index)
	CBUFFER_CONST(SSAOPS,			float3,     number_of_ssao_samples_pad,					k_SSAO_number_ssao_samples_register_index_pad)
	CBUFFER_CONST(SSAOPS,			int,        number_of_sample_iterations,				k_SSAO_number_sample_iterations_register_index)
	CBUFFER_CONST(SSAOPS,			int3,       number_of_sample_iterations_pad,			k_SSAO_number_sample_iterations_register_index_pad)
	CBUFFER_CONST(SSAOPS,			float,      cutoff_far_away_distance_depth,				k_SSAO_cutoff_far_away_distance_depth_register_index)
	CBUFFER_CONST(SSAOPS,			float3,     cutoff_far_away_distance_depth_pad,			k_SSAO_cutoff_far_away_distance_depth_register_index_pad)
	CBUFFER_CONST_ARRAY(SSAOPS,	float4,		random_offsets, [NUMBER_OF_SSAO_SAMPLES], 	k_SSAO_random_offsets_register_index)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_sampler,				k_SSAO_depth_sampler,			0)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	normals_sampler,		 	k_SSAO_normals_sampler,			1)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	random_offsets_sampler,		k_SSAO_random_offsets_sampler,	2)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	ssao_sampler,			 	k_SSAO_ssao_sampler,			3)
PIXEL_TEXTURE_AND_SAMPLER(_2D,	depth_low_res_sampler,		k_SSAO_depth_low_res_sampler,	4)

#endif

#endif // __SSAO_REGISTERS_H_
