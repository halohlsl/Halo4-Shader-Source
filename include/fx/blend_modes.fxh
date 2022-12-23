#if !defined(__BLEND_MODES_FXH)
#define __BLEND_MODES_FXH

#if !defined(cgfx) && defined(HAS_ALPHA_BLEND_MODE)

#define IS_BLEND_MODE_VS(mode) (vs_alpha_blend_mode==BLEND_MODE_##mode)
#define IS_BLEND_MODE_PS(mode) (ps_alpha_blend_mode==BLEND_MODE_##mode)

#else // !defined(cgfx)

// since we don't have any defines passed in from the engine, we don't get to do anything here
#define IS_BLEND_MODE_VS(mode) false
#define IS_BLEND_MODE_PS(mode) false

#endif // !defined(cgfx)

#endif 	// !defined(__BLEND_MODES_FXH)