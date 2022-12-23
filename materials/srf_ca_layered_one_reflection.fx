//
// File:	 srf_ca_layered_three_reflection.fx
// Author:	 v-jcleav
// Date:	 04/10/12
//
// Surface Shader - Layered shader that blends three color/spec/normal materials, except the 3rd material has reflection instead of spec
//
// Copyright (c) 343 Industries. All rights reserved.
//
// Notes:
/*
Started from layered_three_height
Blends three sets of terrain textures using R and G channel of blend map -- G channel supports reflection
Heightmap threshold is painted in blend map
Heightmap threshold softness is controlled by vertex color
Heightmap threshold softness is also controlled by B channel of blend map(cloud map parameter), to quickly add variation.
*/


#define USE_LAYER2_REFLECTMAP
#define DISABLE_USE_ALL_LAYERS_COLOR_DETAIL
// Material is non-zero in lower hemisphere.  Use this if it does not cause bias issues in dynamic sun shadow.
#define DISABLE_SUN_CLAMP

#include "srf_ca_layered_three_height_detailnormal.fx"