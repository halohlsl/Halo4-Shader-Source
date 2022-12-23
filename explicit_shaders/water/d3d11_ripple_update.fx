#include "core/core.fxh"
#include "ripple_registers.fxh"

// magic number concentration camp, finally will be executed.
static const float k_ripple_time_per_frame= 0.03f;

void ripple_update_main(inout s_ripple ripple)
{
	if (ripple.life > 0)
	{		
		ripple.size+= ripple.spread * k_vs_ripple_real_frametime_ratio;
		ripple.pendulum_phase+= ripple.pendulum_revolution * k_vs_ripple_real_frametime_ratio;

		if ( ripple.flag_drift )
		{
			ripple.position+= ripple.flow * k_vs_ripple_real_frametime_ratio;
		}

		ripple.life-= k_ripple_time_per_frame * k_vs_ripple_real_frametime_ratio;
		ripple.foam_life-= k_ripple_time_per_frame * k_vs_ripple_real_frametime_ratio;
	}
}

[numthreads(CS_RIPPLE_UPDATE_THREADS,1,1)]
void ripple_update_cs(in uint raw_index : SV_DispatchThreadID)
{
	uint index = raw_index + ripple_index_range.x;
	if (index < ripple_index_range.y)
	{
		s_ripple ripple = cs_ripple_buffer[index];
		ripple_update_main(ripple);
		cs_ripple_buffer[index] = ripple;
	}
}

BEGIN_TECHNIQUE _default
{
	pass ripple
	{
		SET_COMPUTE_SHADER(ripple_update_cs());
	}
}
