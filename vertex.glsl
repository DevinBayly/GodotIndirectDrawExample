#[vertex]
#version 450
layout(set = 0, binding = 0,std430)  buffer FloatBuffer {
	float data[];
} float_buffer;
layout (location = 0) in vec3 Vertex;

void main() {
	float offset2 = float_buffer.data[gl_InstanceIndex];
	vec3 offset = vec3(gl_InstanceIndex * 0.2, 0, 0);
	gl_Position = vec4(vec3(0,offset2/10,0) + Vertex, 1);
}
