//
// File:	 srf_special_cavern_rock_blinn_sepuv_layer0.fx
// Date:	 08/8/12
//
// Surface Shader - srf_special_cavern_rock variation with cavity occlusion map and second normal map using 
// a blinn specular model and independent tiling for each texture on layer 0
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
// requested by David Lesperance <dalesper@microsoft.com>

#define SPECULAR_BLINN
#define LAYER0_INDEPENDENT_TILE
#include "srf_special_cavern_rock.fx"