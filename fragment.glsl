#[fragment]
#version 450
layout(push_constant) uniform PushConstants {
	float frame;
} push_constants;

layout (location = 0) out vec4 OutColor;

void main() {
	OutColor = vec4(1, sin(push_constants.frame*.05), cos(push_constants.frame*.02), 1);
}
