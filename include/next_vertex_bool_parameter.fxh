#ifndef USER_BOOL_VERTEX_PARAMETERS_DEFINED
#define USER_BOOL_VERTEX_PARAMETERS_DEFINED

#if DX_VERSION == 9
bool user_parameter_vertex_bool_40 : register(b40);
bool user_parameter_vertex_bool_41 : register(b41);
bool user_parameter_vertex_bool_42 : register(b42);
bool user_parameter_vertex_bool_43 : register(b43);
bool user_parameter_vertex_bool_44 : register(b44);
bool user_parameter_vertex_bool_45 : register(b45);
bool user_parameter_vertex_bool_46 : register(b46);
bool user_parameter_vertex_bool_47 : register(b47);
#elif DX_VERSION == 11
cbuffer UserBoolParametersVS : register(b12)
{
	bool user_parameter_vertex_bool_40;
	bool user_parameter_vertex_bool_41;
	bool user_parameter_vertex_bool_42;
	bool user_parameter_vertex_bool_43;
	bool user_parameter_vertex_bool_44;
	bool user_parameter_vertex_bool_45;
	bool user_parameter_vertex_bool_46;
	bool user_parameter_vertex_bool_47;
};
#endif

#endif

#if !defined(USER_PARAMETER_VERTEX_BOOL)
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 40
#elif USER_PARAMETER_VERTEX_BOOL== 40
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 41
#elif USER_PARAMETER_VERTEX_BOOL== 41
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 42
#elif USER_PARAMETER_VERTEX_BOOL== 42
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 43
#elif USER_PARAMETER_VERTEX_BOOL== 43
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 44
#elif USER_PARAMETER_VERTEX_BOOL== 44
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 45
#elif USER_PARAMETER_VERTEX_BOOL== 45
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 46
#elif USER_PARAMETER_VERTEX_BOOL== 46
#undef USER_PARAMETER_VERTEX_BOOL
#define USER_PARAMETER_VERTEX_BOOL 47
#else
#error TOO MANY BOOL VERTEX REGISTERS
#endif

#if DX_VERSION == 9

#undef USER_PARAMETER_VERTEX_BOOL_REG
#undef USER_PARAMETER_VERTEX_BOOL_REG_HELPER
#define USER_PARAMETER_VERTEX_BOOL_REG_HELPER(b) BOOST_JOIN(b, USER_PARAMETER_VERTEX_BOOL)
#define USER_PARAMETER_VERTEX_BOOL_REG USER_PARAMETER_VERTEX_BOOL_REG_HELPER(b)

#undef USER_PARAMETER_VERTEX_BOOL_HELPER
#undef USER_PARAMETER_VERTEX_BOOL_REGISTER
#undef USER_PARAMETER_VERTEX_BOOL_NAME
#define USER_PARAMETER_VERTEX_BOOL_HELPER(b) BOOST_JOIN(b, USER_PARAMETER_VERTEX_BOOL)
#define USER_PARAMETER_VERTEX_BOOL_REGISTER USER_PARAMETER_VERTEX_BOOL_HELPER(user_parameter_vertex_bool_)
#define USER_PARAMETER_VERTEX_BOOL_NAME(name) BOOST_JOIN(USER_PARAMETER_VERTEX_BOOL_REGISTER, _##name) : register(USER_PARAMETER_VERTEX_BOOL_HELPER(b))

#elif DX_VERSION == 11

#undef USER_PARAMETER_VERTEX_BOOL_REGISTER
#define USER_PARAMETER_VERTEX_BOOL_REGISTER BOOST_JOIN(user_parameter_vertex_bool_, USER_PARAMETER_VERTEX_BOOL)

#endif
