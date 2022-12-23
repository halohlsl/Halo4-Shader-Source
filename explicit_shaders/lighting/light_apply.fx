//###ctchou $TODO optimize this shader -- we should be able to drop it to 3 registers (it used to work with 3 registers in the old compiler..  boooo!)
//#define SHADER_ATTRIBUTES										[maxtempreg(3)]
#define COMBINE_LOBES(cosine_lobe, specular_lobe, albedo)		(cosine_lobe * albedo.rgb)
#define LIGHT_COLOR												(ps_screen_space_light_constants[4].rgb)
#define DEFORM													deform_tiny_position


#include "light_apply_base.fxh"

