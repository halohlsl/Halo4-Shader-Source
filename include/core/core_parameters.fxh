#if !defined(__CORE_PARAMETERS_FXH)
#define __CORE_PARAMETERS_FXH

#include "core/core.fxh"

#include "parameters/user_parameters.fxh"


#if defined(USER_PARAMETER_BOOL) && USER_PARAMETER_BOOL != 0
#error User constants must all be defined after including 'core_parameters.fxh'
#endif
#undef USER_PARAMETER_BOOL
#include "next_bool_parameter.fxh"
#if defined(USER_PARAMETER_VERTEX_BOOL) && USER_PARAMETER_VERTEX_BOOL != 40
#error User constants must all be defined after including 'core_parameters.fxh'
#endif
#undef USER_PARAMETER_VERTEX_BOOL
#include "next_vertex_bool_parameter.fxh"


// macros to create engine and user parameters
#if DX_VERSION == 9
#if !defined(cgfx)
#define DECLARE_PARAMETER_BOOL_AUTO(type, name)							STATIC_CONST type name = USER_PARAMETER_BOOL_REGISTER; type USER_PARAMETER_BOOL_NAME(name)
#define DECLARE_PARAMETER_VERTEX_BOOL_AUTO(type, name)					STATIC_CONST type name = USER_PARAMETER_VERTEX_BOOL_REGISTER; type USER_PARAMETER_VERTEX_BOOL_NAME(name)
#else
#define DECLARE_PARAMETER_BOOL_AUTO(type, name)							type name
#define DECLARE_PARAMETER_VERTEX_BOOL_AUTO(type, name)					type name
#endif
#elif DX_VERSION == 11
#define DECLARE_PARAMETER_BOOL_AUTO(type, name)							STATIC_CONST type name = USER_PARAMETER_BOOL_REGISTER; string BOOST_JOIN(BOOST_JOIN(USER_PARAMETER_BOOL_REGISTER,_annotations_),name)
#define DECLARE_PARAMETER_VERTEX_BOOL_AUTO(type, name)					STATIC_CONST type name = USER_PARAMETER_VERTEX_BOOL_REGISTER; string BOOST_JOIN(BOOST_JOIN(USER_PARAMETER_VERTEX_BOOL_REGISTER,_annotations_),name)
#endif

#define DECLARE_BOOL(name, ui_name, ui_group)									\
	DECLARE_PARAMETER_BOOL_AUTO(bool, name)										\
	<																			\
		string Name= ui_name;													\
		string Group = ui_group;												\
	>

#define DECLARE_VERTEX_BOOL(name, ui_name, ui_group)							\
	DECLARE_PARAMETER_VERTEX_BOOL_AUTO(bool, name)								\
	<																			\
		string Name= ui_name;													\
		string Group = ui_group;												\
	>

#if DX_VERSION == 9

#define DECLARE_BOOL_WITH_DEFAULT(name, ui_name, ui_group, default_value) DECLARE_BOOL(name, ui_name, ui_group) = default_value
#define DECLARE_VERTEX_BOOL_WITH_DEFAULT(name, ui_name, ui_group, default_value) DECLARE_VERTEX_BOOL(name, ui_name, ui_group) = default_value

#elif DX_VERSION == 11

#define DECLARE_BOOL_WITH_DEFAULT(name, ui_name, ui_group, default_value)		\
	DECLARE_PARAMETER_BOOL_AUTO(bool, name)										\
	<																			\
		string Name= ui_name;													\
		string Group = ui_group;												\
		bool Default = default_value;											\
	>

#define DECLARE_VERTEX_BOOL_WITH_DEFAULT(name, ui_name, ui_group, default_value)	\
	DECLARE_PARAMETER_VERTEX_BOOL_AUTO(bool, name)								\
	<																			\
		string Name= ui_name;													\
		string Group = ui_group;												\
		bool Default = default_value;											\
	>

#endif

	
#endif 	// !defined(__CORE_PARAMETERS_FXH)