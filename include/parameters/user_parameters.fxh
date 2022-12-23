#if !defined(__USER_PARAMETERS_FXH)
#define __USER_PARAMETERS_FXH

#include "next_parameter.fxh"
#include "next_vertex_parameter.fxh"
#include "next_texture.fxh"
#include "next_texture_only.fxh"

////////////////////////////////////////////////////////////////////////////////
// Macros to declare engine parameters
#if !defined(cgfx)
#define DECLARE_PARAMETER(type, name, reg)								type name : register(reg)			< string Options = "Hide"; >
#define DECLARE_PARAMETER_NAME(type, name, ui_name, reg)				DECLARE_PARAMETER(type, name, reg)
#define DECLARE_PARAMETER_NAME_HIDE(type, name, ui_name, reg)			DECLARE_PARAMETER(type, name, reg)
#define DECLARE_PARAMETER_SEMANTIC(type, name, sem, reg)				type name : sem : register(reg)		< string Options = "Hide"; >
#define DECLARE_PARAMETER_OVERLAY(type, name, overlay, reg)				DECLARE_PARAMETER(type, name, reg)
#else
#define DECLARE_PARAMETER(type, name, reg)								type name
#define DECLARE_PARAMETER_NAME(type, name, ui_name, reg)				type name 							< string Name = ui_name; string Options = "Show"; >
#define DECLARE_PARAMETER_NAME_HIDE(type, name, ui_name, reg)			type name 							< string Name = ui_name; string Options = "Hide"; >
#define DECLARE_PARAMETER_SEMANTIC(type, name, sem, reg)				type name : sem						< string Options = "Show"; >
#define DECLARE_PARAMETER_OVERLAY(type, name, overlay, reg)				STATIC_CONST type name = overlay
#endif

////////////////////////////////////////////////////////////////////////////////
// Macros to declare user parameters
//   The NEXT_FLOAT macros leave open annotation brackets
#define DECLARE_FLOAT(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_FLOAT1(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float"; float Minimum = ui_min; float Maximum = ui_max; >
#define DECLARE_FLOAT2(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_FLOAT2(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float2"; float Minimum = ui_min; float Maximum = ui_max; >
#define DECLARE_FLOAT3(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float3"; float Minimum = ui_min; float Maximum = ui_max; >
#define DECLARE_FLOAT4(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float4"; float Minimum = ui_min; float Maximum = ui_max; >

#if DX_VERSION == 9
#define DECLARE_FLOAT_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_FLOAT(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#define DECLARE_FLOAT2_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_FLOAT2(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#define DECLARE_FLOAT3_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_FLOAT3(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#define DECLARE_FLOAT4_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_FLOAT4(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#elif DX_VERSION == 11
#define DECLARE_FLOAT_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value)	NEXT_FLOAT1(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float"; float Minimum = ui_min; float Maximum = ui_max; float Default = default_value;>
#define DECLARE_FLOAT2_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value)	NEXT_FLOAT2(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float2"; float Minimum = ui_min; float Maximum = ui_max; float2 Default = default_value;>
#define DECLARE_FLOAT3_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value)	NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float3"; float Minimum = ui_min; float Maximum = ui_max; float3 Default = default_value;>
#define DECLARE_FLOAT4_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value)	NEXT_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float4"; float Minimum = ui_min; float Maximum = ui_max; float4 Default = default_value;>
#endif

#define DECLARE_VERTEX_FLOAT(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_VERTEX_FLOAT1(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float"; float Minimum = ui_min; float Maximum = ui_max; >
#define DECLARE_VERTEX_FLOAT2(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_VERTEX_FLOAT2(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float2"; float Minimum = ui_min; float Maximum = ui_max; >
#define DECLARE_VERTEX_FLOAT3(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_VERTEX_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float3"; float Minimum = ui_min; float Maximum = ui_max; >
#define DECLARE_VERTEX_FLOAT4(shader_name, ui_name, ui_group, ui_min, ui_max)	NEXT_VERTEX_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float4"; float Minimum = ui_min; float Maximum = ui_max; >

#if DX_VERSION == 9
#define DECLARE_VERTEX_FLOAT_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_VERTEX_FLOAT(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#define DECLARE_VERTEX_FLOAT2_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_VERTEX_FLOAT2(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#define DECLARE_VERTEX_FLOAT3_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_VERTEX_FLOAT3(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#define DECLARE_VERTEX_FLOAT4_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) DECLARE_VERTEX_FLOAT4(shader_name, ui_name, ui_group, ui_min, ui_max) = default_value
#elif DX_VERSION == 11
#define DECLARE_VERTEX_FLOAT_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) NEXT_VERTEX_FLOAT1(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float"; float Minimum = ui_min; float Maximum = ui_max; float Default = default_value;>
#define DECLARE_VERTEX_FLOAT2_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) NEXT_VERTEX_FLOAT2(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float2"; float Minimum = ui_min; float Maximum = ui_max; float2 Default = default_value;>
#define DECLARE_VERTEX_FLOAT3_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) NEXT_VERTEX_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float3"; float Minimum = ui_min; float Maximum = ui_max; float3 Default = default_value;>
#define DECLARE_VERTEX_FLOAT4_WITH_DEFAULT(shader_name, ui_name, ui_group, ui_min, ui_max, default_value) NEXT_VERTEX_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "float4"; float Minimum = ui_min; float Maximum = ui_max; float4 Default = default_value;>
#endif

#define DECLARE_ARGB_COLOR(shader_name, ui_name, ui_group)				NEXT_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = false; >
#define DECLARE_RGB_COLOR(shader_name, ui_name, ui_group)				NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = false; >
#define DECLARE_LINEAR_ARGB_COLOR(shader_name, ui_name, ui_group)		NEXT_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = true; >
#define DECLARE_LINEAR_RGB_COLOR(shader_name, ui_name, ui_group)		NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = true; >

#if DX_VERSION == 9
#define DECLARE_ARGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) DECLARE_ARGB_COLOR(shader_name, ui_name, ui_group) = default_value
#define DECLARE_RGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) DECLARE_RGB_COLOR(shader_name, ui_name, ui_group) = default_value
#define DECLARE_LINEAR_ARGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) DECLARE_LINEAR_ARGB_COLOR(shader_name, ui_name, ui_group) = default_value
#define DECLARE_LINEAR_RGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) DECLARE_LINEAR_RGB_COLOR(shader_name, ui_name, ui_group) = default_value
#elif DX_VERSION == 11
#define DECLARE_ARGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) NEXT_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = false; float4 Default = default_value;>
#define DECLARE_RGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = false; float3 Default = default_value;>
#define DECLARE_LINEAR_ARGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) NEXT_FLOAT4(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = true; float4 Default = default_value;>
#define DECLARE_LINEAR_RGB_COLOR_WITH_DEFAULT(shader_name, ui_name, ui_group, default_value) NEXT_FLOAT3(shader_name) string Name = ui_name; string Group = ui_group; string Type = "color"; bool Linear = true; float3 Default = default_value;>
#endif

////////////////////////////////////////////////////////////////////////////////
// Macros to declare user textures and samplers
#if defined(cgfx) && !defined(NOT_REALLY_CGFX)
#define DEFAULT_SAMPLER_STATE		WrapS = Repeat; WrapT = Repeat; WrapR = Repeat; MinFilter = LinearMipMapLinear; MagFilter = Linear; MaxAnisotropy = 4;
#define DEFAULT_CUBE_SAMPLER_STATE	WrapS = Clamp; WrapT = Clamp; WrapR = Clamp; MinFilter = LinearMipMapLinear; MagFilter = Linear;
#define DECLARE_GRADIENT_SAMPLER_STATE      WrapS = ClampToEdge; WrapT = ClampToEdge; WrapR = Clamp; MinFilter = LinearMipMapLinear; MagFilter = Linear;
#else
#define DEFAULT_SAMPLER_STATE
#define DEFAULT_CUBE_SAMPLER_STATE
#define DECLARE_GRADIENT_SAMPLER_STATE
#endif


#if DX_VERSION == 9

#define DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)\
	texture shader_name##Texture												\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	>;																			\
	sampler shader_name : register(USER_TEXTURE_SAMPLER_REG)					\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	> = sampler_state															\
	{																			\
		Texture = <shader_name##Texture>;										\
		DEFAULT_SAMPLER_STATE													\
	};

#define DECLARE_SAMPLER_CUBE(shader_name, ui_name, ui_group, default_path)		\
	texture shader_name##Texture												\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string Type = "cube";													\
		string DefaultPath = default_path;										\
	>;																			\
	samplerCUBE shader_name : register(USER_TEXTURE_SAMPLER_REG)				\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string Type = "cube";													\
		string DefaultPath = default_path;										\
	> = sampler_state															\
	{																			\
		Texture = <shader_name##Texture>;										\
		DEFAULT_CUBE_SAMPLER_STATE												\
	};

#define DECLARE_SAMPLER_GRADIENT_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	texture shader_name##Texture												\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	>;																			\
	sampler shader_name : register(USER_TEXTURE_SAMPLER_REG)					\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	> = sampler_state															\
	{																			\
		Texture = <shader_name##Texture>;										\
		DECLARE_GRADIENT_SAMPLER_STATE											\
	};

#define DECLARE_SAMPLER(shader_name, ui_name, ui_group, default_path)			\
	DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	DECLARE_PARAMETER_NAME(float4, shader_name##_transform, ui_name##" Transform", USER_TEXTURE_CONSTANT_REG) = float4(1,1,0,0);

#define DECLARE_SAMPLER_HIDE_TRANSFORM(shader_name, ui_name, ui_group, default_path)			\
	DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	DECLARE_PARAMETER_NAME_HIDE(float4, shader_name##_transform, ui_name##" Transform", USER_TEXTURE_CONSTANT_REG) = float4(1,1,0,0);
	
#define DECLARE_SAMPLER_3D(shader_name, ui_name, ui_group, default_path) DECLARE_SAMPLER(shader_name, ui_name, ui_group, default_path)
#define DECLARE_SAMPLER_3D_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path) DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)
#define DECLARE_SAMPLER_3D_HIDE_TRANSFORM(shader_name, ui_name, ui_group, default_path) DECLARE_SAMPLER_HIDE_TRANSFORM(shader_name, ui_name, ui_group, default_path)
	
#define DECLARE_SAMPLER_GRADIENT(shader_name, ui_name, ui_group, default_path)			\
	DECLARE_SAMPLER_GRADIENT_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	DECLARE_PARAMETER_NAME(float4, shader_name##_transform, ui_name##" Transform", USER_TEXTURE_CONSTANT_REG) = float4(1,1,0,0);

#define DECLARE_SAMPLER_2D_ARRAY(shader_name, ui_name, ui_group, default_path) DECLARE_SAMPLER(shader_name, ui_name, ui_group, default_path)
#define DECLARE_SAMPLER_2D_ARRAY_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path) DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)
#define DECLARE_SAMPLER_2D_ARRAY_HIDE_TRANSFORM(shader_name, ui_name, ui_group, default_path) DECLARE_SAMPLER_HIDE_TRANSFORM(shader_name, ui_name, ui_group, default_path)
	
#elif DX_VERSION == 11

#define DECLARE_SAMPLER_NO_TRANSFORM_HELPER(texture_type, struct_type, shader_name, ui_name, ui_group, default_path)\
	texture_type<float4> shader_name##Texture : register(BOOST_JOIN(t, USER_TEXTURE_SAMPLER))	\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	>;																			\
	sampler UserSampler_##shader_name : register(USER_TEXTURE_SAMPLER_REG)		\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	> = sampler_state															\
	{																			\
		Texture = <shader_name##Texture>;										\
		DEFAULT_SAMPLER_STATE													\
	};																			\
																				\
	static struct_type shader_name = { UserSampler_##shader_name, shader_name##Texture };

#define DECLARE_SAMPLER_CUBE(shader_name, ui_name, ui_group, default_path)		\
	TextureCube<float4> shader_name##Texture : register(BOOST_JOIN(t, USER_TEXTURE_SAMPLER))	\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string Type = "cube";													\
		string DefaultPath = default_path;										\
	>;																			\
	sampler UserSampler_##shader_name : register(USER_TEXTURE_SAMPLER_REG)		\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string Type = "cube";													\
		string DefaultPath = default_path;										\
	> = sampler_state															\
	{																			\
		Texture = <shader_name##Texture>;										\
		DEFAULT_CUBE_SAMPLER_STATE												\
	};																			\
																				\
	static texture_sampler_cube shader_name = { UserSampler_##shader_name, shader_name##Texture };

#define DECLARE_SAMPLER_GRADIENT_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	texture2D<float4> shader_name##Texture : register(BOOST_JOIN(t, USER_TEXTURE_SAMPLER))	\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	>;																			\
	sampler UserSampler_##shader_name : register(USER_TEXTURE_SAMPLER_REG)		\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	> = sampler_state															\
	{																			\
		Texture = <shader_name##Texture>;										\
		DECLARE_GRADIENT_SAMPLER_STATE											\
	};																			\
																				\
	static texture_sampler_2d shader_name = { UserSampler_##shader_name, shader_name##Texture };

#define DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path) \
	DECLARE_SAMPLER_NO_TRANSFORM_HELPER(texture2D, texture_sampler_2d, shader_name, ui_name, ui_group, default_path)
	
#define DECLARE_SAMPLER(shader_name, ui_name, ui_group, default_path)			\
	DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	static float4 shader_name##_transform = USER_TEXTURE_CONSTANT_REG;

#define DECLARE_SAMPLER_HIDE_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	DECLARE_SAMPLER_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)			\
	static float4 shader_name##_transform = USER_TEXTURE_CONSTANT_REG;

#define DECLARE_SAMPLER_NO_TRANSFORM_3D(shader_name, ui_name, ui_group, default_path) \
	DECLARE_SAMPLER_NO_TRANSFORM_HELPER(texture3D, texture_sampler_3d, shader_name, ui_name, ui_group, default_path)
	
#define DECLARE_SAMPLER_3D(shader_name, ui_name, ui_group, default_path)			\
	DECLARE_SAMPLER_NO_TRANSFORM_3D(shader_name, ui_name, ui_group, default_path)	\
	static float4 shader_name##_transform = USER_TEXTURE_CONSTANT_REG;

#define DECLARE_SAMPLER_HIDE_TRANSFORM_3D(shader_name, ui_name, ui_group, default_path)	\
	DECLARE_SAMPLER_NO_TRANSFORM_3D(shader_name, ui_name, ui_group, default_path)		\
	static float4 shader_name##_transform = USER_TEXTURE_CONSTANT_REG;
	
#define DECLARE_SAMPLER_GRADIENT(shader_name, ui_name, ui_group, default_path)			\
	DECLARE_SAMPLER_GRADIENT_NO_TRANSFORM(shader_name, ui_name, ui_group, default_path)	\
	static float4 shader_name##_transform = USER_TEXTURE_CONSTANT_REG;
	
#define DECLARE_SAMPLER_NO_TRANSFORM_2D_ARRAY(shader_name, ui_name, ui_group, default_path) \
	DECLARE_SAMPLER_NO_TRANSFORM_HELPER(Texture2DArray, texture_sampler_2d_array, shader_name, ui_name, ui_group, default_path)
	
#define DECLARE_SAMPLER_2D_ARRAY(shader_name, ui_name, ui_group, default_path)			\
	DECLARE_SAMPLER_NO_TRANSFORM_2D_ARRAY(shader_name, ui_name, ui_group, default_path)	\
	static float4 shader_name##_transform = USER_TEXTURE_CONSTANT_REG;

#define DECLARE_SAMPLER_HIDE_TRANSFORM_2D_ARRAY(shader_name, ui_name, ui_group, default_path)	\
	DECLARE_SAMPLER_NO_TRANSFORM_2D_ARRAY(shader_name, ui_name, ui_group, default_path)		\
	static float4 shader_name##_transform = USER_TEXTURE_CONSTANT_REG;

#define DECLARE_TEXTURE_2D(texture_name, ui_name, ui_group, default_path) 		\
	texture2D<float4> texture_name##Texture : register(BOOST_JOIN(t, USER_TEXTURE))	\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	>;

#define DECLARE_TEXTURE_2D_ARRAY(texture_name, ui_name, ui_group, default_path) 		\
	texture2DArray<float4> texture_name##Texture : register(BOOST_JOIN(t, USER_TEXTURE))	\
	<																			\
		string Name = ui_name;													\
		string Group = ui_group;												\
		string DefaultPath = default_path;										\
	>;

#define GET_SAMPLER_NAME( sampler_name ) UserSampler_##sampler_name
	
#endif

#if DX_VERSION == 9

#define LOCAL_SAMPLER2D(shader_name, slot) sampler2D shader_name : register(BOOST_JOIN(s, slot))
#define LOCAL_SAMPLER3D(shader_name, slot) sampler3D shader_name : register(BOOST_JOIN(s, slot))
#define LOCAL_SAMPLERCUBE(shader_name, slot) samplerCUBE shader_name : register(BOOST_JOIN(s, slot))

#elif DX_VERSION == 11

#define LOCAL_SAMPLER2D(shader_name, slot)										\
	texture2D<float4> shader_name##Texture : register(BOOST_JOIN(t, slot));		\
	sampler shader_name##Sampler : register(BOOST_JOIN(s, slot));				\
	static texture_sampler_2d shader_name = { shader_name##Sampler, shader_name##Texture };

#define LOCAL_SAMPLER3D(shader_name, slot)										\
	texture3D<float4> shader_name##Texture : register(BOOST_JOIN(t, slot));		\
	sampler shader_name##Sampler : register(BOOST_JOIN(s, slot));				\
	static texture_sampler_3d shader_name = { shader_name##Sampler, shader_name##Texture };

#define LOCAL_SAMPLERCUBE(shader_name, slot)										\
	TextureCube<float4> shader_name##Texture : register(BOOST_JOIN(t, slot));		\
	sampler shader_name##Sampler : register(BOOST_JOIN(s, slot));				\
	static texture_sampler_cube shader_name = { shader_name##Sampler, shader_name##Texture };
	
	
#endif

#include "cbuffer.fxh"

#endif 	// !defined(__USER_PARAMETERS_FXH)
