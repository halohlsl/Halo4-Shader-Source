#if !defined(__PARTICLE_TECHNIQUES_FXH)
#define __PARTICLE_TECHNIQUES_FXH

#include "core/core.fxh"

#include "fx/entrypoints/particle.fxh"

#if !defined(cgfx)

BEGIN_TECHNIQUE _default <
#if defined(RENDER_DISTORTION)
	bool is_distortion = true;
#endif // defined(RENDER_DISTORTION)
	bool no_physics_material = true;
	>
{
	pass _default
	{
		SET_PIXEL_SHADER(default_default_ps());
	}

	pass particle
	{
		SET_VERTEX_SHADER(default_particle_vs());
	}

	pass particle_model
	{
		SET_VERTEX_SHADER(default_particle_model_vs());
	}
}

#endif 	// !defined(cgfx)


#endif 	// !defined(__PARTICLE_TECHNIQUES_FXH)