#if !defined(__TRACER_FUNCTION_EVALUATION_FXH)
#define __TRACER_FUNCTION_EVALUATION_FXH

// Match with c_editable_property_base::e_output_modifier
// enum OutputModifier
#define eOM_none 0 //_output_modifier_none
#define eOM_add 1 //_output_modifier_add
#define eOM_multiply 2 //_output_modifier_multiply

float GetStateValue(const TracerProfileState profileState, int index)
{
	if (index == eTS_profileAge)
	{
		return profileState.age;
	}
	else if (index == eTS_profilePercentile)
	{
		return profileState.percentile;
	}
	else if (index <= eTS_profileCorrelation4)
	{
		return profileState.random[index - eTS_profileCorrelation1];
	}
	else // a state which is independent of profile
	{
		return vs_tracerOverallState.inputs[index].value;
	}
}

float GetConstantValue(GpuProperty p) { return p.innards.x; }
int GetIsConstant(GpuProperty p) { return EXTRACT_BITS(p.innards.y, 21, 22); }	// 1 bit always
int GetFunctionIndexGreen(GpuProperty p) { return EXTRACT_BITS(p.innards.z, 17, 22); }	// 5 bits often	
int GetInputIndexGreen(GpuProperty p) { return EXTRACT_BITS(p.innards.w, 17, 22); }	// 5 bits often	
int GetFunctionIndexRed(GpuProperty p) { return EXTRACT_BITS(p.innards.y, 0, 5); }	// 5 bits often	
int GetInputIndexRed(GpuProperty p) { return EXTRACT_BITS(p.innards.y, 5, 10); }	// 5 bits rarely	
int GetColorIndexLo(GpuProperty p) { return EXTRACT_BITS(p.innards.w, 0, 3); }	// 3 bits rarely	
int GetColorIndexHi(GpuProperty p) { return EXTRACT_BITS(p.innards.w, 3, 6); }	// 3 bits rarely	
int GetModifierIndex(GpuProperty p) { return EXTRACT_BITS(p.innards.z, 0, 2); }	// 2 bits often	
int GetInputIndexModifier(GpuProperty p) { return EXTRACT_BITS(p.innards.z, 2, 7); }	// 5 bits rarely	

// This generates multiple inlined calls to Evaluate and GetStateValue, which are 
// large functions.  If the inlining becomes an issue, we can use the loop 
// trick documented below.
float TracerProfileEvaluate(const TracerProfileState profileState, int type)
{
	GpuProperty property = vs_gpuProperties[type];
	if (GetIsConstant(property))
	{
		return GetConstantValue(property);
	}
	else
	{
		float input = GetStateValue(profileState, GetInputIndexGreen(property));
		float output;
		if (GetFunctionIndexRed(property) != _type_identity) // hack for ranged, since 0 isn't used
		{
			float interpolate = GetStateValue(profileState, GetInputIndexRed(property));
			output = evaluate_scalar_ranged(GetFunctionIndexGreen(property), GetFunctionIndexRed(property), input, interpolate);
		}
		else
		{
			output = evaluate_scalar(GetFunctionIndexGreen(property), input);
		}
		if (GetModifierIndex(property) != eOM_none)
		{
			float modifyBy = GetStateValue(profileState, GetInputIndexModifier(property));
			if (GetModifierIndex(property) == eOM_add)
			{
				output += modifyBy;
			}
			else // if (GetModifierIndex(property)== eOM_multiply)
			{
				output *= modifyBy;
			}
		}
		return output;
	}
}

float3 TracerMapToColorRange(int type, float scalar)
{
	GpuProperty property = vs_gpuProperties[type];
	return map_to_color_range(GetColorIndexLo(property), GetColorIndexHi(property), scalar);
}

float2 TracerMapToVector2dRange(int type, float scalar)
{
	GpuProperty property = vs_gpuProperties[type];
	return map_to_vector2d_range(GetColorIndexLo(property), GetColorIndexHi(property), scalar);
}

float3 TracerMapToVector3dRange(int type, float scalar)
{
	GpuProperty property = vs_gpuProperties[type];
	return map_to_vector3d_range(GetColorIndexLo(property), GetColorIndexHi(property), scalar);
}

typedef float preevaluatedFunctions[eTP_count]; // stupid compiler fails when I just write the type explicitly
preevaluatedFunctions PreevaluateTracerFunctions(TracerProfileState state)
{
	// The explicit initializations below are necessary to avoid uninitialized
	// variable errors.  I believe the excess initializations are stripped out.
	float preevaluatedScalar[eTP_count]= {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, };
	[loop]
	for (int loopCounter = 0; loopCounter < eTP_count; ++loopCounter)
	{
		preevaluatedScalar[loopCounter] = TracerProfileEvaluate(state, loopCounter);
	}

	return preevaluatedScalar;
}

#endif 	// !defined(__TRACER_FUNCTION_EVALUATION_FXH)