//
// File:	 srf_constant_illumscroll_uv2.fx
// Author:	 v-inyang
// Date:	 02/27/12
//
// variation from srf_constant. This has seperate self illumination scroll rate and scroll rate scaler.
// requested by Justin Dinge
//
// Copyright (c) 343 Industries. All rights reserved.
//
//

// no sh airporbe lighting needed for constant shader

#define USEUV2
#define SELFILLUM_SCROLL
#include "srf_constant.fx"