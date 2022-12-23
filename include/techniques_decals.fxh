#if !defined(__TECHNIQUES_DECALS_FXH)
#define __TECHNIQUES_DECALS_FXH

#include "core/core.fxh"

#include "entrypoints/cgfx.fxh"

#if !defined(cgfx)

#include "entrypoints/decals.fxh"

BEGIN_TECHNIQUE _default
<
	bool is_decal = true;
#if defined(DECAL_IS_EMBLEM)
	bool is_emblem = true;
#endif
>
{
	pass _default
	{
		SET_PIXEL_SHADER(default_default_ps());
	}
	pass world
	{
		SET_VERTEX_SHADER(default_world_vs());
	}
	pass rigid
	{
		SET_VERTEX_SHADER(default_rigid_vs());
	}
	pass skinned
	{
		SET_VERTEX_SHADER(default_skinned_vs());
	}
	pass rigid_boned
	{
		SET_VERTEX_SHADER(default_rigid_boned_vs());
	}
	pass flat_world
	{
		SET_VERTEX_SHADER(default_flat_world_vs());
	}
	pass flat_rigid
	{
		SET_VERTEX_SHADER(default_flat_rigid_vs());
	}
	pass flat_skinned
	{
		SET_VERTEX_SHADER(default_flat_skinned_vs());
	}
}

#endif

#endif 	// !defined(__TECHNIQUES_FXH)