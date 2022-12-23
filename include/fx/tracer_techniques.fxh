#if !defined(__TRACER_TECHNIQUES_FXH)
#define __TRACER_TECHNIQUES_FXH

#include "core/core.fxh"

#include "fx/entrypoints/tracer.fxh"

#if !defined(cgfx)

BEGIN_TECHNIQUE _default <
#if defined(RENDER_DISTORTION)
	bool is_distortion = true;
#endif // defined(RENDER_DISTORTION)
	bool noPhysicsMaterial = true;
	>
{
	pass _default
	{
		SET_PIXEL_SHADER(DefaultDefaultPS());
	}

	pass tracer
	{
		SET_VERTEX_SHADER(DefaultTracerVS());
	}
}

#endif 	// !defined(cgfx)

#endif 	// !defined(__TRACER_TECHNIQUES_FXH)