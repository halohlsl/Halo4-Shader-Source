#if !defined(__TECHNIQUES_FXH)
#define __TECHNIQUES_FXH

#include "core/core.fxh"

#include "entrypoints/cgfx.fxh"

#if !defined(cgfx)

#include "entrypoints/albedo.fxh"
#include "entrypoints/static_lighting.fxh"
#include "entrypoints/single_pass_lighting.fxh"
#include "entrypoints/shadow_generate.fxh"
#include "entrypoints/dynamic_lighting.fxh"
#include "entrypoints/active_camo.fxh"
#include "entrypoints/motion_blur.fxh"

// Defines all the MAKE_TECHNIQUE macros
#include "techniques_base.fxh"


MAKE_TECHNIQUE(albedo)

#if !defined(FORCE_SINGLE_PASS)
MAKE_TECHNIQUE_XENON(static_per_pixel)
MAKE_TECHNIQUE_XENON(static_per_pixel_hybrid_refinement)
MAKE_TECHNIQUE_XENON(static_per_pixel_analytic)
MAKE_TECHNIQUE_XENON(static_per_pixel_analytic_hybrid_refinement)
MAKE_TECHNIQUE_XENON(static_per_pixel_floating_shadow)
MAKE_TECHNIQUE_XENON(static_per_pixel_object)
MAKE_TECHNIQUE_XENON(static_per_vertex_object)
MAKE_TECHNIQUE_XENON(static_per_pixel_forge)
MAKE_TECHNIQUE_XENON(static_per_pixel_floating_shadow_simple)
MAKE_TECHNIQUE_XENON(static_per_pixel_simple)
MAKE_TECHNIQUE_XENON(static_per_pixel_ao)
MAKE_TECHNIQUE_XENON(static_per_vertex)
MAKE_TECHNIQUE_XENON(static_per_vertex_ao)
MAKE_TECHNIQUE_XENON(static_probe)
MAKE_TECHNIQUE_XENON(active_camo)

MAKE_TECHNIQUE_XENON(single_pass_per_pixel)
MAKE_TECHNIQUE_XENON(single_pass_per_vertex)
MAKE_TECHNIQUE_XENON(single_pass_single_probe)

MAKE_TECHNIQUE_XENON(single_pass_shadowed_no_fog_per_pixel)
MAKE_TECHNIQUE_XENON(single_pass_shadowed_no_fog_per_vertex)
MAKE_TECHNIQUE_XENON(single_pass_shadowed_no_fog_single_probe)

MAKE_TECHNIQUE_XENON(single_pass_as_decal)
#endif

MAKE_TECHNIQUE_XENON(midnight_spotlight)
#if defined(REQUIRE_SPOTLIGHT_TRANSPARENT)
MAKE_TECHNIQUE_XENON(midnight_spotlight_transparents)
#endif

#if !defined(REQUIRE_Z_PASS_PIXEL_SHADER)
MAKE_TECHNIQUE_VS_ONLY_XENON(shadow_generate)
#else
MAKE_TECHNIQUE_OVERRIDE_XENON(shadow_generate, shadow_generate_textured)
#endif

MAKE_TECHNIQUE_XENON(motion_blur)


#elif defined(cgfx)

#include "techniques_cgfx.fxh"

#endif 	// !defined(cgfx)


#endif 	// !defined(__TECHNIQUES_FXH)