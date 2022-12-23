#if defined(xenon) && !defined(__CORE_XENON_FXH)
#define __CORE_XENON_FXH

// Need to mark some parts of the code to isolate during compile
#define ISOLATE			[isolate]
#define ISOLATE_OUTPUT
#define STATIC_BRANCH	[branch]

#define HARDWARE_TEXTURE_GAMMA
#define DEFAULT_TEXTURE_GAMMA   1.0
#define DEFAULT_OUTPUT_GAMMA    1.0/DEFAULT_TEXTURE_GAMMA

// Squared Falloff Trick for Analytic and VMF Lighting with a compensation term set below
// used in macro SQUARE_FALLOFF_DIRECT/VMF in core.fxh
#define FALLOFF_COMPENSATION_DIRECT      1.25
#define FALLOFF_COMPENSATION_VMF         1.25

#if !defined(USE_SKINNING_MATRICES)
#define USE_VERTEX_STREAM_SKINNING
#endif

struct s_platform_pixel_input
{
    SCREEN_POSITION_INPUT(fragment_position);
};

s_platform_pixel_input get_default_platform_input()
{
	s_platform_pixel_input outPlatformInput;
	outPlatformInput.fragment_position = 0;
	return outPlatformInput;
}


#endif  // !defined(__CORE_XENON_FXH)