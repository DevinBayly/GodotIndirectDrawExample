#[fragment]
#version 450
layout(push_constant) uniform PushConstants {
	mat4 cam;
} push_constants;

layout(set = 0, binding = 1,std430)  buffer InvBuffer {
	int data[];
} inv_data;

layout (location = 0) out vec4 OutColor;

layout (location =0 ) flat in int vid;
layout (location =1 ) flat in int iid;
layout (location =2 ) flat in int mid;


void main() {
	// note we need to set this value because if the conditionals don't line up it still gets a greater than 0 value

	//OutColor = vec4(red, sin(push_constants.frame*.05), cos(push_constants.frame*.02), 1);
	vec3 outColor = vec3(float(mid/10)/10.0,mod(mid,10.0)/10.0,float(mid/100)/100.0);
	OutColor = vec4(outColor, 1);
}
