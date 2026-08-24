#[fragment]
#version 450

layout(set = 0, binding = 1,std430)  buffer InvBuffer {
	int data[];
} inv_data;

layout (location = 0) out vec4 OutColor;

layout (location =0 ) flat in int vid;
layout (location =1 ) flat in int iid;

void main() {
	// note we need to set this value because if the conditionals don't line up it still gets a greater than 0 value
	float red=0;
	int compute_value = inv_data.data[iid];
	if (vid > 1) {
		red =1;
	}

	//OutColor = vec4(red, sin(push_constants.frame*.05), cos(push_constants.frame*.02), 1);
	OutColor = vec4(float(iid)/12.0,1,1, 1);
}
