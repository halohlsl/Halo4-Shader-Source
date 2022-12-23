#include "core/core.fxh"

#define USER_VERTEX_PARAMETER_SIZE 1

#if (USER_VERTEX_PARAMETER_OFFSET + USER_VERTEX_PARAMETER_SIZE) == 4
#include "parameters/next_vertex_parameter.fxh"			// mark the next register as the current register.  We haven't touched it yet, but there is no room in this one.
#else

#if (USER_VERTEX_PARAMETER_OFFSET + USER_VERTEX_PARAMETER_SIZE) > 4
#include "parameters/next_vertex_parameter.fxh"			// mark the next register as the current register, and since we've already started using it fall through to offset block
#endif

#if defined(cgfx)

#define USER_VERTEX_PARAMETER_OFFSET 0

#else // defined(cgfx)

#if USER_VERTEX_PARAMETER_OFFSET == 0
#undef USER_VERTEX_PARAMETER_OFFSET
#define USER_VERTEX_PARAMETER_OFFSET 1
#elif USER_VERTEX_PARAMETER_OFFSET == 1
#undef USER_VERTEX_PARAMETER_OFFSET
#define USER_VERTEX_PARAMETER_OFFSET 2
#elif USER_VERTEX_PARAMETER_OFFSET == 2
#undef USER_VERTEX_PARAMETER_OFFSET
#define USER_VERTEX_PARAMETER_OFFSET 3
#elif USER_VERTEX_PARAMETER_OFFSET == 3
#undef USER_VERTEX_PARAMETER_OFFSET
#define USER_VERTEX_PARAMETER_OFFSET 4
#else
#error IMPOSSIBLE!
#endif

#endif // defined(cgfx)

#endif // (USER_VERTEX_PARAMETER_OFFSET + USER_VERTEX_PARAMETER_SIZE) == 4

#include "parameters/init_next_vertex_parameter.fxh"

#undef USER_VERTEX_PARAMETER_SIZE
