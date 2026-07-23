#[fragment]
#version 450
layout(push_constant) uniform PushConstants {
	float frame;
} push_constants;

layout(set = 0, binding = 1,std430)  buffer InvBuffer {
	int data[];
} inv_data;

layout (location = 0) out vec4 OutColor;

layout (location =0 ) flat in int vid;

void main() {
	float red;
	if (vid ==0) {
		red = 1.0;
	} 
	if (vid == 1) {
		red = .5;
	}
	if (vid == 2) {
		red =0;
	}
	//OutColor = vec4(red, sin(push_constants.frame*.05), cos(push_constants.frame*.02), 1);
	OutColor = vec4(red,0,0, 1);
}
