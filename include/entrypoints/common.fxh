#if !defined(__ENTRYPOINTS_COMMON_FXH)
#define __ENTRYPOINTS_COMMON_FXH

#include "core/core.fxh"

#include "core/core_vertex_types.fxh"
#include "deform.fxh"
#include "exposure.fxh"
#include "lighting/vmf.fxh"
#include "lighting/sh.fxh"

s_shader_data init_shader_data(
	s_pixel_shader_input pixel_shader_input,
	s_platform_pixel_input platformInput,
	uniform int lightingMode)
{
#if !defined(cgfx)
	s_shader_data shader_data= (s_shader_data)0;
#else
	s_shader_data shader_data;
#endif

	// Initialize the common portion of the shader data structure
	shader_data.common = init_common_shader_data(pixel_shader_input, lightingMode);

	//Initialize the platform portion of the shader
	shader_data.common.platform_input = platformInput;

	return shader_data;
}

#endif 	// !defined(__ENTRYPOINTS_CGFX_FXH)