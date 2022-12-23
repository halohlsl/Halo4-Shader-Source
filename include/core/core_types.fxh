#if !defined(__CORE_TYPES_FXH)
#define __CORE_TYPES_FXH


// If they're not independently defined, set the lighting outputs to the same
// as the albedo/single_pass outputs
#if defined(DISABLE_NORMAL)
#undef DISABLE_LIGHTING_NORMAL
#define DISABLE_LIGHTING_NORMAL
#endif

#if defined(DISABLE_TANGENT_FRAME)
#undef DISABLE_LIGHTING_TANGENT_FRAME
#define DISABLE_LIGHTING_TANGENT_FRAME
#endif

#if defined(DISABLE_VIEW_VECTOR)
#undef DISABLE_LIGHTING_VIEW_VECTOR
#define DISABLE_LIGHTING_VIEW_VECTOR
#endif

#if defined(DISABLE_VERTEX_COLOR)
#undef DISABLE_LIGHTING_VERTEX_COLOR
#define DISABLE_LIGHTING_VERTEX_COLOR
#endif

#if DX_VERSION == 9

typedef sampler1D texture_sampler_1d;
typedef sampler2D texture_sampler_2d; 
typedef sampler2D texture_sampler_2d_array; 
typedef sampler3D texture_sampler_3d; 
typedef samplerCUBE texture_sampler_cube;

#elif DX_VERSION == 11

struct texture_sampler_1d
{
	sampler s;
	texture1D<float4> t;
};

struct texture_sampler_2d
{
	sampler s;
	texture2D<float4> t;
};

struct texture_sampler_2d_array
{
	sampler s;
	Texture2DArray<float4> t;
};

struct texture_sampler_3d
{
	sampler s;
	texture3D<float4> t;
};

struct texture_sampler_cube
{
	sampler s;
	TextureCube<float4> t;
};

#endif

#include "engine/engine_parameters.fxh"

struct s_vmf_sample_data
{
	float4 coefficients[4];
};

struct s_vmf_ao_sample_data
{
	float4 coefficients;
};

#if DX_VERSION == 9

typedef struct
{
	float4 texcoord:				TEXCOORD0;

#if !defined(DISABLE_NORMAL)

	#if !defined(DISABLE_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		float4 normal:				TEXCOORD1;				// stick vertex color alpha in the w
	#else
		float3 normal:				TEXCOORD1;
	#endif

	#if !defined(DISABLE_TANGENT_FRAME)
		float3 binormal:			TEXCOORD2;
		float3 tangent:				TEXCOORD3;
	#endif

#endif

#if !defined(DISABLE_VIEW_VECTOR)
	#if defined(ENABLE_DEPTH_INTERPOLATER) || (defined(DISABLE_NORMAL) && !defined(DISABLE_VERTEX_COLOR))
		float4 view_vector:			TEXCOORD4; 				// stick depth in the w
	#else
		float3 view_vector:			TEXCOORD4;
	#endif
#endif

#if !defined(DISABLE_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	float4 vertexColor:				TEXCOORD5;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	float4 shadowProjection:		TEXCOORD10;
#endif

}	s_vertex_shader_output,
	s_pixel_shader_input;


// Output structure for the lighting passes
typedef struct
{
	float4 texcoord:				TEXCOORD0;

#if !defined(DISABLE_LIGHTING_NORMAL)

	#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		float4 normal:				TEXCOORD1;					// stick vertex color alpha in the w
	#else
		float3 normal:				TEXCOORD1;
	#endif

	#if !defined(DISABLE_LIGHTING_TANGENT_FRAME)
		float3 binormal:			TEXCOORD2;
		float3 tangent:				TEXCOORD3;
	#endif

#endif

#if !defined(DISABLE_LIGHTING_VIEW_VECTOR)
	#if defined(ENABLE_DEPTH_INTERPOLATER) || (defined(DISABLE_LIGHTING_NORMAL) && !defined(DISABLE_LIGHTING_VERTEX_COLOR))
		float4 view_vector:			TEXCOORD4;					// stick depth in the w
	#else
		float3 view_vector:			TEXCOORD4;
	#endif
#endif

#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	float4 vertexColor:				TEXCOORD5;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	float4 shadowProjection:		TEXCOORD10;
#endif

}	s_lighting_vertex_shader_output,
	s_lighting_pixel_shader_input;

	
#elif DX_VERSION == 11

typedef struct
{
	float4 texcoord:				TEXCOORD0;

#if !defined(DISABLE_NORMAL)

	#if !defined(DISABLE_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		float4 normal:				TEXCOORD1;				// stick vertex color alpha in the w
	#else
		float3 normal:				TEXCOORD1;
	#endif

	#if !defined(DISABLE_TANGENT_FRAME)
		float3 binormal:			TEXCOORD2;
		float3 tangent:				TEXCOORD3;
	#endif

#endif

#if !defined(DISABLE_VIEW_VECTOR)
	#if defined(ENABLE_DEPTH_INTERPOLATER) || (defined(DISABLE_NORMAL) && !defined(DISABLE_VERTEX_COLOR))
		float4 view_vector:			TEXCOORD4; 				// stick depth in the w
	#else
		float3 view_vector:			TEXCOORD4;
	#endif
#endif

#if !defined(DISABLE_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	float4 vertexColor:				TEXCOORD5;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	float4 shadowProjection:		TEXCOORD10;
#endif

	float clipDistance:				SV_ClipDistance;

}	s_vertex_shader_output;

typedef struct
{
	float4 screenPosition:			SV_Position;

	float4 texcoord:				TEXCOORD0;

#if !defined(DISABLE_NORMAL)

	#if !defined(DISABLE_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		float4 normal:				TEXCOORD1;				// stick vertex color alpha in the w
	#else
		float3 normal:				TEXCOORD1;
	#endif

	#if !defined(DISABLE_TANGENT_FRAME)
		float3 binormal:			TEXCOORD2;
		float3 tangent:				TEXCOORD3;
	#endif

#endif

#if !defined(DISABLE_VIEW_VECTOR)
	#if defined(ENABLE_DEPTH_INTERPOLATER) || (defined(DISABLE_NORMAL) && !defined(DISABLE_VERTEX_COLOR))
		float4 view_vector:			TEXCOORD4; 				// stick depth in the w
	#else
		float3 view_vector:			TEXCOORD4;
	#endif
#endif

#if !defined(DISABLE_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	float4 vertexColor:				TEXCOORD5;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	float4 shadowProjection:		TEXCOORD10;
#endif

	float clipDistance:				SV_ClipDistance;

}	s_pixel_shader_input;


// Output structure for the lighting passes
typedef struct
{
	float4 texcoord:				TEXCOORD0;

#if !defined(DISABLE_LIGHTING_NORMAL)

	#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		float4 normal:				TEXCOORD1;					// stick vertex color alpha in the w
	#else
		float3 normal:				TEXCOORD1;
	#endif

	#if !defined(DISABLE_LIGHTING_TANGENT_FRAME)
		float3 binormal:			TEXCOORD2;
		float3 tangent:				TEXCOORD3;
	#endif

#endif

#if !defined(DISABLE_LIGHTING_VIEW_VECTOR)
	#if defined(ENABLE_DEPTH_INTERPOLATER) || (defined(DISABLE_LIGHTING_NORMAL) && !defined(DISABLE_LIGHTING_VERTEX_COLOR))
		float4 view_vector:			TEXCOORD4;					// stick depth in the w
	#else
		float3 view_vector:			TEXCOORD4;
	#endif
#endif

#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	float4 vertexColor:				TEXCOORD5;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	float4 shadowProjection:		TEXCOORD10;
#endif

	float clipDistance:				SV_ClipDistance;

}	s_lighting_vertex_shader_output;

typedef struct
{
	float4 screenPosition:			SV_Position;

	float4 texcoord:				TEXCOORD0;

#if !defined(DISABLE_LIGHTING_NORMAL)

	#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		float4 normal:				TEXCOORD1;					// stick vertex color alpha in the w
	#else
		float3 normal:				TEXCOORD1;
	#endif

	#if !defined(DISABLE_LIGHTING_TANGENT_FRAME)
		float3 binormal:			TEXCOORD2;
		float3 tangent:				TEXCOORD3;
	#endif

#endif

#if !defined(DISABLE_LIGHTING_VIEW_VECTOR)
	#if defined(ENABLE_DEPTH_INTERPOLATER) || (defined(DISABLE_LIGHTING_NORMAL) && !defined(DISABLE_LIGHTING_VERTEX_COLOR))
		float4 view_vector:			TEXCOORD4;					// stick depth in the w
	#else
		float3 view_vector:			TEXCOORD4;
	#endif
#endif

#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	float4 vertexColor:				TEXCOORD5;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	float4 shadowProjection:		TEXCOORD10;
#endif

	float clipDistance:				SV_ClipDistance;

}	s_lighting_pixel_shader_input;

#endif
	
	
struct s_shader_output_atmosphere
{
	float3 inscatter:				COLOR0;
	float2 extinction:				COLOR1;
};


#define MAX_LIGHTING_COMPONENTS		3
struct s_lighting_components
{
	s_vmf_sample_data vmf_data;
	float4 light_direction_specular_scalar[MAX_LIGHTING_COMPONENTS];
	float4 light_intensity_diffuse_scalar[MAX_LIGHTING_COMPONENTS];
	float4 shadow_mask;
	float visibility;
	float savedAnalyticScalar;

	int light_component_count;
};


struct s_common_shader_data
{
#if !defined(s_platform_pixel_input)
	s_platform_pixel_input	platform_input;
#endif

	s_lighting_components	lighting_data;

	float4					albedo;
	float3					normal;
	float3					shaderValues;
	float					selfIllumIntensity;

	float3					geometricNormal;
	float3x3				tangent_frame;
	float4					vertexColor;
	float4					view_dir_distance;
	float3					position;
	int						lighting_mode;
	int						shaderPass;
	float4 					shadowProjection;
};


#include "core/core_functions.fxh"

float4 CalculateFloatingShadowFrustumSpacePosition(float3 worldPosition)
{
	float4 shadowPosition = float4(worldPosition, 1.0);
	shadowPosition.xyz = transform_point(shadowPosition, vs_floating_shadow_inverse_frustum_transform);
	return shadowPosition;
}

//
s_lighting_vertex_shader_output PackLightingShaderOutput(in s_vertex_shader_output output)
{
#if !defined(cgfx)
	s_lighting_vertex_shader_output lightingOutput = (s_lighting_vertex_shader_output)0;
#else
	s_lighting_vertex_shader_output lightingOutput;
#endif

	lightingOutput.texcoord		= output.texcoord;

#if !defined(DISABLE_LIGHTING_NORMAL)

	#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		lightingOutput.normal	= output.normal;
	#else
		lightingOutput.normal.xyz= output.normal;
	#endif

	#if !defined(DISABLE_LIGHTING_TANGENT_FRAME)
		lightingOutput.binormal	= output.binormal.xyz;
		lightingOutput.tangent	= output.tangent.xyz;
	#endif

#endif

#if !defined(DISABLE_LIGHTING_VIEW_VECTOR)
	lightingOutput.view_vector = output.view_vector;
#endif

#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	lightingOutput.vertexColor = output.vertexColor;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	lightingOutput.shadowProjection = output.shadowProjection;
#endif

#if DX_VERSION == 11
	lightingOutput.clipDistance = output.clipDistance;
#endif

	return lightingOutput;
}

//
s_pixel_shader_input UnpackLightingShaderInput(in s_lighting_pixel_shader_input input)
{
	s_pixel_shader_input unpacked = (s_pixel_shader_input)0;

	unpacked.texcoord = input.texcoord;

#if !defined(DISABLE_LIGHTING_NORMAL)

	#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
		unpacked.normal = input.normal;
	#else
		unpacked.normal.xyz = input.normal;
	#endif

	#if !defined(DISABLE_LIGHTING_TANGENT_FRAME)
		unpacked.binormal = input.binormal;
		unpacked.tangent = input.tangent;
	#endif
#endif

#if !defined(DISABLE_LIGHTING_VIEW_VECTOR)
	unpacked.view_vector = input.view_vector;
#endif

#if !defined(DISABLE_LIGHTING_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	unpacked.vertexColor = input.vertexColor;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	unpacked.shadowProjection = input.shadowProjection;
#endif

	return unpacked;
}

s_common_shader_data init_common_shader_data(
	s_pixel_shader_input pixel_shader_input,
	uniform int lightingMode)
{
	s_common_shader_data common_shader_data;

	// zero the structure to start
#if !defined(cgfx)
	common_shader_data= (s_common_shader_data)0;
#else
	common_shader_data.lighting_data.light_direction_specular_scalar[0]= 0;
	common_shader_data.lighting_data.light_direction_specular_scalar[1]= 0;
	common_shader_data.lighting_data.light_direction_specular_scalar[2]= 0;
	common_shader_data.lighting_data.light_intensity_diffuse_scalar[0]= 0;
	common_shader_data.lighting_data.light_intensity_diffuse_scalar[1]= 0;
	common_shader_data.lighting_data.light_intensity_diffuse_scalar[2]= 0;
	common_shader_data.lighting_data.light_component_count= 0;
	common_shader_data.view_dir_distance = 0;
	common_shader_data.shaderValues = 0;
	common_shader_data.selfIllumIntensity = 0;
#endif

	// set lighting mode to be default
	common_shader_data.lighting_mode = lightingMode;
	common_shader_data.shaderPass = SP_DEFAULT;

	// initialize the shadow mask
	common_shader_data.lighting_data.shadow_mask= 1.0f;

	// set up the tangent frame
	common_shader_data.tangent_frame= get_tangent_frame(pixel_shader_input);
	common_shader_data.normal.xyz= common_shader_data.tangent_frame[2].xyz;
	common_shader_data.geometricNormal = common_shader_data.normal;

	// set up the view vector and camera distance parameter
	float3 view_vector = get_view_vector(pixel_shader_input);
	common_shader_data.view_dir_distance.xyz = view_vector;
	common_shader_data.view_dir_distance.w = length(common_shader_data.view_dir_distance);
	common_shader_data.view_dir_distance.xyz /= common_shader_data.view_dir_distance.w;

#if defined(cgfx)
	// Rescale the view distance by the 'maya to game unit' factor
	common_shader_data.view_dir_distance.w /= 10.0f;
#endif

	// set up the world space position
	common_shader_data.position.xyz = ps_camera_position + view_vector;

#if !defined(DISABLE_VERTEX_COLOR) && !defined(FULL_VERTEX_COLOR)
	#if !defined(DISABLE_NORMAL)
		common_shader_data.vertexColor = float4(1, 1, 1, pixel_shader_input.normal.w);
	#else
		common_shader_data.vertexColor = float4(1, 1, 1, pixel_shader_input.view_vector.w);
	#endif
#elif !defined(DISABLE_VERTEX_COLOR) && defined(FULL_VERTEX_COLOR)
	common_shader_data.vertexColor = pixel_shader_input.vertexColor;
#else
	common_shader_data.vertexColor = 1;
#endif

#if defined(xenon) || (DX_VERSION == 11)
	common_shader_data.shadowProjection = pixel_shader_input.shadowProjection;
#endif

	return common_shader_data;
}


#endif 	// !defined(__CORE_TYPES_FXH)