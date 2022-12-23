#if !defined(USER_PARAMETERS_DEFINED)
#define USER_PARAMETERS_DEFINED
#if DX_VERSION == 9
float4 user_parameter_160 : register(c160);
float4 user_parameter_161 : register(c161);
float4 user_parameter_162 : register(c162);
float4 user_parameter_163 : register(c163);
float4 user_parameter_164 : register(c164);
float4 user_parameter_165 : register(c165);
float4 user_parameter_166 : register(c166);
float4 user_parameter_167 : register(c167);
float4 user_parameter_168 : register(c168);
float4 user_parameter_169 : register(c169);
float4 user_parameter_170 : register(c170);
float4 user_parameter_171 : register(c171);
float4 user_parameter_172 : register(c172);
float4 user_parameter_173 : register(c173);
float4 user_parameter_174 : register(c174);
float4 user_parameter_175 : register(c175);
float4 user_parameter_176 : register(c176);
float4 user_parameter_177 : register(c177);
float4 user_parameter_178 : register(c178);
float4 user_parameter_179 : register(c179);
float4 user_parameter_180 : register(c180);
float4 user_parameter_181 : register(c181);
float4 user_parameter_182 : register(c182);
float4 user_parameter_183 : register(c183);
float4 user_parameter_184 : register(c184);
float4 user_parameter_185 : register(c185);
float4 user_parameter_186 : register(c186);
float4 user_parameter_187 : register(c187);
float4 user_parameter_188 : register(c188);
float4 user_parameter_189 : register(c189);
float4 user_parameter_190 : register(c190);
float4 user_parameter_191 : register(c191);
#elif DX_VERSION == 11
cbuffer UserParametersPS : register(b13)
{
	float4 user_parameter_160;
	float4 user_parameter_161;
	float4 user_parameter_162;
	float4 user_parameter_163;
	float4 user_parameter_164;
	float4 user_parameter_165;
	float4 user_parameter_166;
	float4 user_parameter_167;
	float4 user_parameter_168;
	float4 user_parameter_169;
	float4 user_parameter_170;
	float4 user_parameter_171;
	float4 user_parameter_172;
	float4 user_parameter_173;
	float4 user_parameter_174;
	float4 user_parameter_175;
	float4 user_parameter_176;
	float4 user_parameter_177;
	float4 user_parameter_178;
	float4 user_parameter_179;
	float4 user_parameter_180;
	float4 user_parameter_181;
	float4 user_parameter_182;
	float4 user_parameter_183;
	float4 user_parameter_184;
	float4 user_parameter_185;
	float4 user_parameter_186;
	float4 user_parameter_187;
	float4 user_parameter_188;
	float4 user_parameter_189;
	float4 user_parameter_190;
	float4 user_parameter_191;
};
#endif
#endif // !defined(USER_PARAMETERS_DEFINED)

#if defined(cgfx)

#define USER_PARAMETER_NEXT		161
#define USER_PARAMETER_CURRENT	160

#else // defined(cgfx)

#if !defined(USER_PARAMETER_SIZE)

#if defined(USER_PARAMETER_CURRENT)
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#endif // defined(USER_PARAMETER_CURRENT)
#define USER_PARAMETER_NEXT		161
#define USER_PARAMETER_CURRENT	160

#else // !defined(USER_PARAMETER_SIZE)

#if !defined(USER_PARAMETER_CURRENT)
#define USER_PARAMETER_NEXT		161
#define USER_PARAMETER_CURRENT	160
#elif USER_PARAMETER_CURRENT == 160
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		162
#define USER_PARAMETER_CURRENT	161
#elif USER_PARAMETER_CURRENT == 161
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		163
#define USER_PARAMETER_CURRENT	162
#elif USER_PARAMETER_CURRENT == 162
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		164
#define USER_PARAMETER_CURRENT	163
#elif USER_PARAMETER_CURRENT == 163
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		165
#define USER_PARAMETER_CURRENT	164
#elif USER_PARAMETER_CURRENT == 164
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		166
#define USER_PARAMETER_CURRENT	165
#elif USER_PARAMETER_CURRENT == 165
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		167
#define USER_PARAMETER_CURRENT	166
#elif USER_PARAMETER_CURRENT == 166
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		168
#define USER_PARAMETER_CURRENT	167
#elif USER_PARAMETER_CURRENT == 167
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		169
#define USER_PARAMETER_CURRENT	168
#elif USER_PARAMETER_CURRENT == 168
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		170
#define USER_PARAMETER_CURRENT	169
#elif USER_PARAMETER_CURRENT == 169
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		171
#define USER_PARAMETER_CURRENT	170
#elif USER_PARAMETER_CURRENT == 170
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		172
#define USER_PARAMETER_CURRENT	171
#elif USER_PARAMETER_CURRENT == 171
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		173
#define USER_PARAMETER_CURRENT	172
#elif USER_PARAMETER_CURRENT == 172
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		174
#define USER_PARAMETER_CURRENT	173
#elif USER_PARAMETER_CURRENT == 173
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		175
#define USER_PARAMETER_CURRENT	174
#elif USER_PARAMETER_CURRENT == 174
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		176
#define USER_PARAMETER_CURRENT	175
#elif USER_PARAMETER_CURRENT == 175
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		177
#define USER_PARAMETER_CURRENT	176
#elif USER_PARAMETER_CURRENT == 176
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		178
#define USER_PARAMETER_CURRENT	177
#elif USER_PARAMETER_CURRENT == 177
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		179
#define USER_PARAMETER_CURRENT	178
#elif USER_PARAMETER_CURRENT == 178
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		180
#define USER_PARAMETER_CURRENT	179
#elif USER_PARAMETER_CURRENT == 179
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		181
#define USER_PARAMETER_CURRENT	180
#elif USER_PARAMETER_CURRENT == 180
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		182
#define USER_PARAMETER_CURRENT	181
#elif USER_PARAMETER_CURRENT == 181
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		183
#define USER_PARAMETER_CURRENT	182
#elif USER_PARAMETER_CURRENT == 182
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		184
#define USER_PARAMETER_CURRENT	183
#elif USER_PARAMETER_CURRENT == 183
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		185
#define USER_PARAMETER_CURRENT	184
#elif USER_PARAMETER_CURRENT == 184
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		186
#define USER_PARAMETER_CURRENT	185
#elif USER_PARAMETER_CURRENT == 185
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		187
#define USER_PARAMETER_CURRENT	186
#elif USER_PARAMETER_CURRENT == 186
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		188
#define USER_PARAMETER_CURRENT	187
#elif USER_PARAMETER_CURRENT == 187
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		189
#define USER_PARAMETER_CURRENT	188
#elif USER_PARAMETER_CURRENT == 188
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		190
#define USER_PARAMETER_CURRENT	189
#elif USER_PARAMETER_CURRENT == 189
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		191
#define USER_PARAMETER_CURRENT	190
#elif USER_PARAMETER_CURRENT == 190
#undef USER_PARAMETER_CURRENT
#undef USER_PARAMETER_NEXT
#define USER_PARAMETER_NEXT		192
#define USER_PARAMETER_CURRENT	191
#else
#error Too many user parameters
#endif

#endif // !defined(USER_PARAMETER_SIZE)

#undef USER_PARAMETER_CURRENT_HELPER
#undef USER_PARAMETER_CURRENT_REGISTER
#undef USER_PARAMETER_CURRENT_NAME
#undef USER_PARAMETER_NEXT_HELPER
#undef USER_PARAMETER_NEXT_REGISTER
#undef USER_PARAMETER_NEXT_NAME
#undef USER_PARAMETER_OFFSET

#endif // defined(cgfx)

#if DX_VERSION == 9

// Set up the register for the current parameter
#define USER_PARAMETER_CURRENT_HELPER(c)		BOOST_JOIN(c, USER_PARAMETER_CURRENT)
#define USER_PARAMETER_CURRENT_REGISTER			USER_PARAMETER_CURRENT_HELPER(user_parameter_)
#define USER_PARAMETER_CURRENT_NAME(name)		BOOST_JOIN(USER_PARAMETER_CURRENT_REGISTER, _##name) : register(USER_PARAMETER_CURRENT_HELPER(c))

// Set up the register for the next parameter (in case we need it)
#define USER_PARAMETER_NEXT_HELPER(c)			BOOST_JOIN(c, USER_PARAMETER_NEXT)
#define USER_PARAMETER_NEXT_REGISTER			USER_PARAMETER_NEXT_HELPER(user_parameter_)
#define USER_PARAMETER_NEXT_NAME(name)			BOOST_JOIN(USER_PARAMETER_NEXT_REGISTER, _##name) : register(USER_PARAMETER_NEXT_HELPER(c))

#elif DX_VERSION == 11

#define USER_PARAMETER_CURRENT_REGISTER			BOOST_JOIN(user_parameter_, USER_PARAMETER_CURRENT)
#define USER_PARAMETER_NEXT_REGISTER			BOOST_JOIN(user_parameter_, USER_PARAMETER_NEXT)

#endif

// Reset the offset to 0
#define USER_PARAMETER_OFFSET 0

#include "init_next_parameter.fxh"