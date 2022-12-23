//
// File:	 srf_constant_lightshafts.fx
// Author:	hcoulby
// Date:	 07/18/11
//
// variation from srf_constant. This has seperate self illumination scroll rate and scroll rate scaler.
// as well as Light shaft visual elements like fresnal edge and distance based fading
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader
#define SELFILLUM_SCROLL
#define LIGHTSHAFT
#include "srf_constant.fx"