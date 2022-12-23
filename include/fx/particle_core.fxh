#if !defined(__PARTICLE_CORE_FXH)
#define __PARTICLE_CORE_FXH

#define EXCLUDE_MODEL_MATRICES

#include "core/core.fxh"
#include "fx/particle_parameters.fxh"
#include "fx/particle_types.fxh"
#include "fx/fx_functions.fxh"
#include "blend_modes.fxh"

DECLARE_VERTEX_BOOL_WITH_DEFAULT(NewSchoolFrameIndex, "New-School Frame Index", "", false);
#include "next_vertex_bool_parameter.fxh"

DECLARE_VERTEX_BOOL_WITH_DEFAULT(ConstantScreenSize, "Constant Screen Size", "", false);
#include "next_vertex_bool_parameter.fxh"

#if !defined(RENDER_DISTORTION)
DECLARE_VERTEX_BOOL_WITH_DEFAULT(LightingPerParticle, "Lighting Per Particle", "", false);
#include "next_vertex_bool_parameter.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(lighting_per_particle_strength, "Lighting Per Particle Strength", "LightingPerParticle", 0, 1, float(1));
#include "used_vertex_float.fxh"

DECLARE_VERTEX_FLOAT_WITH_DEFAULT(lighting_bright_intensity_decrease, "Lighting Bright Intensity Decrease", "LightingPerParticle", 0, 1, float(1));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(lighting_dim_alpha_increase, "Lighting Dim Alpha Increase", "LightingPerParticle", 0, 1, float(0.4));
#include "used_vertex_float.fxh"
DECLARE_VERTEX_FLOAT_WITH_DEFAULT(lighting_bright_alpha_decrease, "Lighting Bright Alpha Decrease", "LightingPerParticle", 0, 1, float(0));
#include "used_vertex_float.fxh"

DECLARE_BOOL_WITH_DEFAULT(LightingSmooth, "Lighting Smooth", "", false);
#include "next_bool_parameter.fxh"

DECLARE_FLOAT_WITH_DEFAULT(LightingContrastScale, "Lighting Contrast Scale", "LightingSmooth", 0, 2, float(1));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(LightingContrastOffset, "Lighting Contrast Offset", "LightingSmooth", 0, 2, float(0));
#include "used_float.fxh"
DECLARE_FLOAT_WITH_DEFAULT(LightingStrength, "Lighting Strength", "LightingSmooth", 0, 1, float(1));
#include "used_float.fxh"
#endif // !defined(RENDER_DISTORTION)

DECLARE_FLOAT_WITH_DEFAULT(SphereWarpStrength, "Texcoord Sphere Warp", "", 0, 1, float(0));
#include "used_float.fxh"

DECLARE_BOOL_WITH_DEFAULT(DepthFadeAsVCoord, "Depth Fade As V-Coord", "", false);
#include "next_bool_parameter.fxh"

#endif 	// !defined(__PARTICLE_CORE_FXH)