#[fragment]
#version 450
layout(push_constant) uniform PushConstants {
	float frame;
} push_constants;

layout(set = 0, binding = 1,std430)  buffer InvBuffer {
	int data[];
} inv_data;

layout (location = 0) out vec4 OutColor;

layout (location =0 ) in float vid;

void main() {
	// note we need to set this value because if the conditionals don't line up it still gets a greater than 0 value
	float red=0;
	if (vid > 1) {
		red =1;
	}

	//OutColor = vec4(red, sin(push_constants.frame*.05), cos(push_constants.frame*.02), 1);
	OutColor = vec4(vid/2.0,1,1, 1);
}
