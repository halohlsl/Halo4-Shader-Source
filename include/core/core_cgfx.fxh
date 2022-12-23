#if defined(cgfx) && !defined(__CORE_CGFX_FXH)
#define __CORE_CGFX_FXH

// No isolation necessary
#define ISOLATE
#define ISOLATE_OUTPUT
#define STATIC_BRANCH


#define DEFAULT_TEXTURE_GAMMA	2.2
#define DEFAULT_OUTPUT_GAMMA	1.0/DEFAULT_TEXTURE_GAMMA

// Squared Falloff Trick for Analytic and VMF Lighting with a compensation term set below
// used in macro SQUARE_FALLOFF_DIRECT/VMF in core.fxh
#define FALLOFF_COMPENSATION_DIRECT      1.0
#define FALLOFF_COMPENSATION_VMF         1.0

// cgfx gets a full vertex color anytime that vertex color is used
#define FULL_VERTEX_COLOR

// CG doesn't support empty structures, so define the platform data as garbage for now
struct s_platform_pixel_input
{
	static const float garbageGalore;
};

s_platform_pixel_input get_default_platform_input()
{
	s_platform_pixel_input outPlatformInput;
	outPlatformInput.garbageGalore = 0;
	
	return outPlatformInput;
}

#endif 	// !defined(__CORE_CGFX_FXH)