#if !defined(__TECHNIQUES_CGFX_FXH)
#define __TECHNIQUES_CGFX_FXH

#include "core/core.fxh"

#if defined(cgfx)

#include "entrypoints/cgfx.fxh"

#if !defined(NOT_REALLY_CGFX)

#define VERTEX_PROFILE	glslv
#define PIXEL_PROFILE	glslf

BEGIN_TECHNIQUE opaque
{
	pass p0
	{
		VertexProgram= 	compile VERTEX_PROFILE combined_vs();
		FragmentProgram=compile PIXEL_PROFILE combined_opaque_ps();

		DepthTestEnable = true;
		DepthFunc = LEqual;

		BlendEnable = false;

		CullFace  = Back;
	}
}


BEGIN_TECHNIQUE alpha_blend
{
	pass p0
	{
		VertexProgram= 	compile VERTEX_PROFILE combined_vs();
		FragmentProgram=compile PIXEL_PROFILE combined_alpha_ps();

		DepthTestEnable = true;
		DepthFunc = LEqual;

		BlendEnable = true;
		BlendFunc = int2(SrcAlpha, OneMinusSrcAlpha);

		CullFace = back;
	}
}

BEGIN_TECHNIQUE additive < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE multiply < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE double_multiply < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE pre_multiplied_alpha < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE maximum < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE multiply_add < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE add_src_times_dstalpha < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE add_src_times_srcalpha < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE inv_alpha_blend < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE motion_blur_static < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE motion_blur_inhibit < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE apply_shadow_into_shadow_mask < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE alpha_blend_constant < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE overdraw_apply < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE wet_screen_effect < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE minimum < string OverrideTechnique = "opaque"; > {}
BEGIN_TECHNIQUE revsubtract < string OverrideTechnique = "opaque"; > {}

BEGIN_TECHNIQUE albedo_display
{
	pass p0
	{
		VertexProgram= 	compile VERTEX_PROFILE combined_vs();
		FragmentProgram=compile PIXEL_PROFILE combined_albedo_ps();

		DepthTestEnable = true;
		DepthFunc = LEqual;

		BlendEnable = false;

		CullFace  = Back;
	}
}

#endif

#endif 	// !defined(cgfx)


#endif 	// !defined(__TECHNIQUES_CGFX_FXH)
