#if !defined(__LIGHT_CONE_TECHNIQUES_FXH)
#define __LIGHT_CONE_TECHNIQUES_FXH

#include "fx/entrypoints/light_cone.fxh"

BEGIN_TECHNIQUE _default <
	bool noPhysicsMaterial = true;
	>
{
	pass _default
	{
		SET_PIXEL_SHADER(DefaultPS());
	}

	pass screen
	{
		SET_VERTEX_SHADER(DefaultVS());
	}
}

#endif 	// !defined(__LIGHT_CONE_TECHNIQUES_FXH)