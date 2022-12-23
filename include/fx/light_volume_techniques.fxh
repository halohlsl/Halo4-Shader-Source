#if !defined(__LIGHT_VOLUME_TECHNIQUES_FXH)
#define __LIGHT_VOLUME_TECHNIQUES_FXH

#include "core/core.fxh"

#include "fx/entrypoints/light_volume.fxh"

#if !defined(cgfx)

BEGIN_TECHNIQUE _default <
	bool noPhysicsMaterial = true;
	>
{
	pass _default
	{
		SET_PIXEL_SHADER(DefaultDefaultPS());
	}

	pass light_volume
	{
		SET_VERTEX_SHADER(DefaultLightVolumeVS());
	}
}

#endif 	// !defined(cgfx)

#endif 	// !defined(__LIGHT_VOLUME_TECHNIQUES_FXH)