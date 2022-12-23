#if !defined(__VISION_MODE_BIPED_FXH)
#ifndef DEFINE_CPP_CONSTANTS
#define __VISION_MODE_BIPED_FXH
#endif

#if DX_VERSION == 9

DECLARE_PARAMETER(bool, psIsFriend, b0);
DECLARE_PARAMETER(bool, psIsEnemy, b1);

#elif DX_VERSION == 11

CBUFFER_BEGIN(VisionModeBipedPS)
	CBUFFER_CONST(VisionModeBipedPS,		bool, 		psIsFriend, 	k_ps_vision_mode_biped_bool_is_friend)
	CBUFFER_CONST(VisionModeBipedPS,		bool, 		psIsEnemy, 		k_ps_vision_mode_biped_bool_is_enemy)
CBUFFER_END

#endif

#endif 	// !defined(__VISION_MODE_BIPED_FXH)
