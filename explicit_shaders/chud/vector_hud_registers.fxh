#if DX_VERSION == 9

#undef VERTEX_CONSTANT
#undef PIXEL_CONSTANT
#ifdef VERTEX_SHADER
	#define VERTEX_CONSTANT(type, name, register_index)   type name : register(c##register_index);
	#define PIXEL_CONSTANT(type, name, register_index)   type name;
#else
	#define VERTEX_CONSTANT(type, name, register_index)   type name;
	#define PIXEL_CONSTANT(type, name, register_index)   type name : register(c##register_index);
#endif
#define BOOL_CONSTANT(name, register_index)   bool name : register(b##register_index);
#define SAMPLER_CONSTANT(name, register_index)	sampler name : register(s##register_index);

// GPU ranges
// vs constants: 40 - 45
// ps constants: 60 - 65
// samplers: 0

VERTEX_CONSTANT(float4x4, mat_wvp, 40)
VERTEX_CONSTANT(float4, line_pos, 44)
VERTEX_CONSTANT(float, z_value, 45)

PIXEL_CONSTANT(float4, line_params, 60)
PIXEL_CONSTANT(float4, e0, 61)
PIXEL_CONSTANT(float4, e1, 62)
PIXEL_CONSTANT(float4, e2, 63)
PIXEL_CONSTANT(float4, e3, 64)
PIXEL_CONSTANT(float, vector_hud_alpha, 65)

SAMPLER_CONSTANT(texture_sampler, 0)

// Unfortunately copied from chud_util.fx cause that file's full of other garbage.
PIXEL_CONSTANT(float4, chud_color_output_A, 24)
PIXEL_CONSTANT(float4, chud_color_output_B, 25)
PIXEL_CONSTANT(float4, chud_color_output_C, 26)
PIXEL_CONSTANT(float4, chud_color_output_D, 27)
PIXEL_CONSTANT(float4, chud_color_output_E, 28)
PIXEL_CONSTANT(float4, chud_color_output_F, 29)
PIXEL_CONSTANT(float4, chud_scalar_output_ABCD, 30)// [a, b, c, d]
PIXEL_CONSTANT(float4, chud_scalar_output_EF, 31)// [e, f, 0, global_hud_alpha]

#elif DX_VERSION == 11

CBUFFER_BEGIN(VectorHUDVS)
	CBUFFER_CONST(VectorHUDVS,	float4x4,	mat_wvp,		_register_mat_wvp)
	CBUFFER_CONST(VectorHUDVS,	float4,		line_pos,		_register_line_pos)
	CBUFFER_CONST(VectorHUDVS,	float,		z_value,		_register_z_value)
CBUFFER_END

CBUFFER_BEGIN(VectorHUDPS)
	CBUFFER_CONST(VectorHUDPS,	float4,		line_params,				_register_line_params)
	CBUFFER_CONST(VectorHUDPS,	float4,		e0,							_register_e0)
	CBUFFER_CONST(VectorHUDPS,	float4,		e1,							_register_e1)
	CBUFFER_CONST(VectorHUDPS,	float4,		e2,							_register_e2)
	CBUFFER_CONST(VectorHUDPS,	float4,		e3,							_register_e3)
	CBUFFER_CONST(VectorHUDPS,	float,		vector_hud_alpha,			_register_vector_hud_alpha)
	CBUFFER_CONST(VectorHUDPS,	float3,		vector_hud_alpha_pad,		_register_vector_hud_alpha_pad)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_color_output_A,		_register_chud_color_output_A)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_color_output_B,		_register_chud_color_output_B)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_color_output_C,		_register_chud_color_output_C)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_color_output_D,		_register_chud_color_output_D)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_color_output_E,		_register_chud_color_output_E)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_color_output_F,		_register_chud_color_output_F)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_scalar_output_ABCD,	_register_chud_scalar_output_ABCD)
	CBUFFER_CONST(VectorHUDPS,	float4,		chud_scalar_output_EF,		_register_chud_scalar_output_EF)
CBUFFER_END

PIXEL_TEXTURE_AND_SAMPLER(_2D,	texture_sampler, 	k_vector_hud_texture_sampler,	0)

#endif