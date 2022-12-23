#include "../core/core.fxh"

#if defined(cgfx)

#define NEXT_VERTEX_FLOAT4(parameter_name) float4 parameter_name <
#define NEXT_VERTEX_FLOAT3(parameter_name) float3 parameter_name <
#define NEXT_VERTEX_FLOAT2(parameter_name) float2 parameter_name <
#define NEXT_VERTEX_FLOAT1(parameter_name) float  parameter_name <

#else

#undef NEXT_VERTEX_FLOAT4
#undef NEXT_VERTEX_FLOAT3
#undef NEXT_VERTEX_FLOAT2
#undef NEXT_VERTEX_FLOAT1

#if DX_VERSION == 9

// The NEXT_VERTEX_FLOAT macros must leave open annotation brackets
#if USER_VERTEX_PARAMETER_OFFSET == 0
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.xyzw		; float4 USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.xyz		; float3 USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.xy		; float2 USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.x		; float  USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#elif USER_VERTEX_PARAMETER_OFFSET == 1
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyzw		; float4 USER_VERTEX_PARAMETER_NEXT_NAME(parameter_name) < int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.yzw		; float3 USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.yz		; float2 USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.y		; float  USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#elif USER_VERTEX_PARAMETER_OFFSET == 2
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyzw		; float4 USER_VERTEX_PARAMETER_NEXT_NAME(parameter_name) < int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyz			; float3 USER_VERTEX_PARAMETER_NEXT_NAME(parameter_name) < int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.zw		; float2 USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.z		; float  USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#elif USER_VERTEX_PARAMETER_OFFSET == 3
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyzw		; float4 USER_VERTEX_PARAMETER_NEXT_NAME(parameter_name) < int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyz			; float3 USER_VERTEX_PARAMETER_NEXT_NAME(parameter_name) < int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xy			; float2 USER_VERTEX_PARAMETER_NEXT_NAME(parameter_name) < int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.w		; float  USER_VERTEX_PARAMETER_CURRENT_NAME(parameter_name) < int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#else
#error Invalid user parameter offset
#endif

#elif DX_VERSION == 11

#if USER_VERTEX_PARAMETER_OFFSET == 0
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.xyzw		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 4; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.xyz		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 3; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.xy		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 2; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.x		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 1; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#elif USER_VERTEX_PARAMETER_OFFSET == 1                                                                                           
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyzw		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_NEXT_REGISTER,_annotations_),parameter_name) < int Dim = 4; int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.yzw		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 3; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.yz		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 2; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.y		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 1; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#elif USER_VERTEX_PARAMETER_OFFSET == 2                                                                                           
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyzw		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_NEXT_REGISTER,_annotations_),parameter_name) < int Dim = 4; int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyz			; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_NEXT_REGISTER,_annotations_),parameter_name) < int Dim = 3; int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.zw		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 2; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.z		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 1; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#elif USER_VERTEX_PARAMETER_OFFSET == 3                                                                                           
#define NEXT_VERTEX_FLOAT4(parameter_name) STATIC_CONST float4 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyzw		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_NEXT_REGISTER,_annotations_),parameter_name) < int Dim = 4; int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT3(parameter_name) STATIC_CONST float3 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xyz			; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_NEXT_REGISTER,_annotations_),parameter_name) < int Dim = 3; int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT2(parameter_name) STATIC_CONST float2 parameter_name = USER_VERTEX_PARAMETER_NEXT_REGISTER.xy			; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_NEXT_REGISTER,_annotations_),parameter_name) < int Dim = 2; int RegisterOffset = 0;
#define NEXT_VERTEX_FLOAT1(parameter_name) STATIC_CONST float  parameter_name = USER_VERTEX_PARAMETER_CURRENT_REGISTER.w		; string BOOST_JOIN(BOOST_JOIN(USER_VERTEX_PARAMETER_CURRENT_REGISTER,_annotations_),parameter_name) < int Dim = 1; int RegisterOffset = USER_VERTEX_PARAMETER_OFFSET;
#else
#error Invalid user parameter offset
#endif

#endif

#endif