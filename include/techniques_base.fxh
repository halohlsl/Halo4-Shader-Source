#if !defined(__TECHNIQUES_BASE_FXH)
#define __TECHNIQUES_BASE_FXH

#include "core/core.fxh"

#if !defined(cgfx)

// Add any shader-specific annotations
#if !defined(MATERIAL_SHADER_ANNOTATIONS)
#if defined(BLENDED_MATERIAL_COUNT)
#define MATERIAL_SHADER_ANNOTATIONS 	<int blendMaterialCount = BLENDED_MATERIAL_COUNT;>
#elif defined(BLENDED_MATERIAL)
#define MATERIAL_SHADER_ANNOTATIONS 	<bool blended_materials = true;>
#endif
#endif

#if !defined(MATERIAL_SHADER_ANNOTATIONS)
#define MATERIAL_SHADER_ANNOTATIONS
#endif

#define MAKE_DEFAULT_PASS(entrypoint_name)\
	pass _default\
	{\
		SET_PIXEL_SHADER(entrypoint_name##_default_ps());\
	}

#define MAKE_PASS(entrypoint_name, vertextype_name)\
	pass vertextype_name\
	{\
		SET_VERTEX_SHADER(entrypoint_name##_##vertextype_name##_vs());\
	}

#define MAKE_TECHNIQUE(entrypoint_name)\
	BEGIN_TECHNIQUE entrypoint_name\
	MATERIAL_SHADER_ANNOTATIONS\
	{\
		MAKE_DEFAULT_PASS(entrypoint_name)\
		MAKE_PASS(entrypoint_name, world)\
		MAKE_PASS(entrypoint_name, rigid)\
		MAKE_PASS(entrypoint_name, skinned)\
		MAKE_PASS(entrypoint_name, rigid_boned)\
		MAKE_PASS(entrypoint_name, rigid_blendshaped)\
		MAKE_PASS(entrypoint_name, skinned_blendshaped)\
	}

#define MAKE_TECHNIQUE_VS_ONLY(entrypoint_name)\
	BEGIN_TECHNIQUE entrypoint_name\
	MATERIAL_SHADER_ANNOTATIONS\
	{\
		MAKE_PASS(entrypoint_name, world)\
		MAKE_PASS(entrypoint_name, rigid)\
		MAKE_PASS(entrypoint_name, skinned)\
		MAKE_PASS(entrypoint_name, rigid_boned)\
		MAKE_PASS(entrypoint_name, rigid_blendshaped)\
		MAKE_PASS(entrypoint_name, skinned_blendshaped)\
	}

#define MAKE_TECHNIQUE_OVERRIDE(entrypoint_name, shader_entrypoint_name)\
	BEGIN_TECHNIQUE entrypoint_name\
	MATERIAL_SHADER_ANNOTATIONS\
	{\
		MAKE_DEFAULT_PASS(shader_entrypoint_name)\
		MAKE_PASS(shader_entrypoint_name, world)\
		MAKE_PASS(shader_entrypoint_name, rigid)\
		MAKE_PASS(shader_entrypoint_name, skinned)\
		MAKE_PASS(shader_entrypoint_name, rigid_boned)\
		MAKE_PASS(shader_entrypoint_name, rigid_blendshaped)\
		MAKE_PASS(shader_entrypoint_name, skinned_blendshaped)\
	}


#if (!defined(pc)) || (DX_VERSION == 11)

#define MAKE_TECHNIQUE_XENON(entrypoint_name)									MAKE_TECHNIQUE(entrypoint_name)
#define MAKE_TECHNIQUE_VS_ONLY_XENON(entrypoint_name)							MAKE_TECHNIQUE_VS_ONLY(entrypoint_name)
#define MAKE_TECHNIQUE_OVERRIDE_XENON(entrypoint_name, shader_entrypoint_name)	MAKE_TECHNIQUE_OVERRIDE(entrypoint_name, shader_entrypoint_name)

#else	// !defined(pc)

#define MAKE_TECHNIQUE_XENON(entrypoint_name)
#define MAKE_TECHNIQUE_VS_ONLY_XENON(entrypoint_name)
#define MAKE_TECHNIQUE_OVERRIDE_XENON(entrypoint_name, shader_entrypoint_name)

#endif	// !defined(pc)

#else

#define MAKE_TECHNIQUE(entrypoint_name)
#define MAKE_TECHNIQUE_XENON(entrypoint_name)

#endif

#endif 	// !defined(__TECHNIQUES_FXH)