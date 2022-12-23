#if !defined(__RAW_PARTICLE_STATE_FXH)
#define __RAW_PARTICLE_STATE_FXH

#if DX_VERSION == 11

struct s_raw_particle_state
{
	float4 pos;
	uint2 vel;
	uint2 rnd;
	uint2 rnd2;
	uint2 rot;
	uint2 time;
	uint2 anm;
	uint anm2;
	uint axis;
	uint col;
	uint col2;	
};

#endif

#endif