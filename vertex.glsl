#[vertex]
#version 450

layout (location = 0) in vec3 Vertex;
layout(set = 0, binding = 0, std430) buffer MyDataBuffer {
	float data[];
} my_data_buffer;
void main() {
	vec3 offset = vec3(gl_InstanceIndex * 0.2, 0, 0);
	gl_Position = vec4(Vertex + offset, 1);
}
