#if defined(pc) && !defined(__CORE_PC_FXH)
#define __CORE_PC_FXH

// No isolation necessary
#define ISOLATE
#define ISOLATE_OUTPUT
#define STATIC_BRANCH	[branch]

#if DX_VERSION == 11
#define HARDWARE_TEXTURE_GAMMA
#endif
#define DEFAULT_TEXTURE_GAMMA	1.0
#define DEFAULT_OUTPUT_GAMMA	1.0/DEFAULT_TEXTURE_GAMMA

// Squared Falloff Trick for Analytic and VMF Lighting with a compensation term set below
// used in macro SQUARE_FALLOFF_DIRECT/VMF in core.fxh
#define FALLOFF_COMPENSATION_DIRECT      1.0
#define FALLOFF_COMPENSATION_VMF         1.0


struct s_platform_pixel_input
{
#if DX_VERSION == 11
	SCREEN_POSITION_INPUT(fragment_position);
#endif
};

s_platform_pixel_input get_default_platform_input()
{
	s_platform_pixel_input outPlatformInput;	
#if DX_VERSION == 11
	outPlatformInput.fragment_position = 0;
#endif
	return outPlatformInput;
}

#endif 	// !defined(__CORE_PC_FXH)