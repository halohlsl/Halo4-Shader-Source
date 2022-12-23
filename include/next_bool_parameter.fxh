#if 0

#if !defined(USER_PARAMETER_BOOL)
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 64
#elif USER_PARAMETER_BOOL== 64
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 65
#elif USER_PARAMETER_BOOL== 65
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 66
#elif USER_PARAMETER_BOOL== 66
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 67
#elif USER_PARAMETER_BOOL== 67
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 68
#elif USER_PARAMETER_BOOL== 68
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 69
#elif USER_PARAMETER_BOOL== 69
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 70
#elif USER_PARAMETER_BOOL== 70
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 71
#elif USER_PARAMETER_BOOL== 71
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 72
#elif USER_PARAMETER_BOOL== 72
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 73
#elif USER_PARAMETER_BOOL== 73
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 74
#elif USER_PARAMETER_BOOL== 74
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 75
#elif USER_PARAMETER_BOOL== 75
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 76
#elif USER_PARAMETER_BOOL== 76
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 77
#elif USER_PARAMETER_BOOL== 77
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 78
#elif USER_PARAMETER_BOOL== 78
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 79
#elif USER_PARAMETER_BOOL== 79
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 80
#elif USER_PARAMETER_BOOL== 80
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 81
#elif USER_PARAMETER_BOOL== 81
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 82
#elif USER_PARAMETER_BOOL== 82
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 83
#elif USER_PARAMETER_BOOL== 83
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 84
#elif USER_PARAMETER_BOOL== 84
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 85
#elif USER_PARAMETER_BOOL== 85
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 86
#elif USER_PARAMETER_BOOL== 86
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 87
#elif USER_PARAMETER_BOOL== 87
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 88
#elif USER_PARAMETER_BOOL== 88
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 89
#elif USER_PARAMETER_BOOL== 89
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 90
#elif USER_PARAMETER_BOOL== 90
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 91
#elif USER_PARAMETER_BOOL== 91
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 92
#elif USER_PARAMETER_BOOL== 92
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 93
#elif USER_PARAMETER_BOOL== 93
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 94
#elif USER_PARAMETER_BOOL== 94
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 95
#endif

#else

#ifndef USER_BOOL_PARAMETERS_DEFINED
#define USER_BOOL_PARAMETERS_DEFINED

#if DX_VERSION == 9
bool user_parameter_bool_0 : register(b0);
bool user_parameter_bool_1 : register(b1);
bool user_parameter_bool_2 : register(b2);
bool user_parameter_bool_3 : register(b3);
bool user_parameter_bool_4 : register(b4);
bool user_parameter_bool_5 : register(b5);
bool user_parameter_bool_6 : register(b6);
bool user_parameter_bool_7 : register(b7);
bool user_parameter_bool_8 : register(b8);
bool user_parameter_bool_9 : register(b9);
bool user_parameter_bool_10 : register(b10);
bool user_parameter_bool_11 : register(b11);
bool user_parameter_bool_12 : register(b12);
bool user_parameter_bool_13 : register(b13);
bool user_parameter_bool_14 : register(b14);
bool user_parameter_bool_15 : register(b15);
#elif DX_VERSION == 11
cbuffer UserBoolParametersPS : register(b12)
{
	bool user_parameter_bool_0;
	bool user_parameter_bool_1;
	bool user_parameter_bool_2;
	bool user_parameter_bool_3;
	bool user_parameter_bool_4;
	bool user_parameter_bool_5;
	bool user_parameter_bool_6;
	bool user_parameter_bool_7;
	bool user_parameter_bool_8;
	bool user_parameter_bool_9;
	bool user_parameter_bool_10;
	bool user_parameter_bool_11;
	bool user_parameter_bool_12;
	bool user_parameter_bool_13;
	bool user_parameter_bool_14;
	bool user_parameter_bool_15;
};
#endif

#endif

#if !defined(USER_PARAMETER_BOOL)
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 0
#elif USER_PARAMETER_BOOL== 0
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 1
#elif USER_PARAMETER_BOOL== 1
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 2
#elif USER_PARAMETER_BOOL== 2
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 3
#elif USER_PARAMETER_BOOL== 3
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 4
#elif USER_PARAMETER_BOOL== 4
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 5
#elif USER_PARAMETER_BOOL== 5
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 6
#elif USER_PARAMETER_BOOL== 6
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 7
#elif USER_PARAMETER_BOOL== 7
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 8
#elif USER_PARAMETER_BOOL== 8
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 9
#elif USER_PARAMETER_BOOL== 9
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 10
#elif USER_PARAMETER_BOOL== 10
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 11
#elif USER_PARAMETER_BOOL== 11
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 12
#elif USER_PARAMETER_BOOL== 12
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 13
#elif USER_PARAMETER_BOOL== 13
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 14
#elif USER_PARAMETER_BOOL== 14
#undef USER_PARAMETER_BOOL
#define USER_PARAMETER_BOOL 15
#endif

#endif

#if DX_VERSION == 9

#undef USER_PARAMETER_BOOL_HELPER
#undef USER_PARAMETER_BOOL_REGISTER
#undef USER_PARAMETER_BOOL_NAME
#define USER_PARAMETER_BOOL_HELPER(b) BOOST_JOIN(b, USER_PARAMETER_BOOL)
#define USER_PARAMETER_BOOL_REGISTER USER_PARAMETER_BOOL_HELPER(user_parameter_bool_)
#define USER_PARAMETER_BOOL_NAME(name) BOOST_JOIN(USER_PARAMETER_BOOL_REGISTER, _##name) : register(USER_PARAMETER_BOOL_HELPER(b))

#elif DX_VERSION == 11

#undef USER_PARAMETER_BOOL_REGISTER
#define USER_PARAMETER_BOOL_REGISTER BOOST_JOIN(user_parameter_bool_, USER_PARAMETER_BOOL)

#endif
