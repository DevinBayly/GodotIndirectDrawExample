#[vertex]
#version 450


layout(push_constant) uniform PushConstants {
	float frame;
} push_constants;

layout(set = 0, binding = 0,std430)  buffer FloatBuffer {
	float data[];
} float_buffer;
layout (location = 0) in vec3 Vertex;
layout (location = 0 ) out float vid;

void main() {
	// ah yes, so the bottom triangle was only created when the vertex index was all zero
	vid = float(gl_VertexIndex);
	float offset2 = float_buffer.data[gl_InstanceIndex];
	float x = float_buffer.data[gl_InstanceIndex*9 +   gl_VertexIndex*3 +0  ];
	float y = float_buffer.data[gl_InstanceIndex*9 +   gl_VertexIndex*3 +1  ];
	float z = float_buffer.data[gl_InstanceIndex*9 +   gl_VertexIndex*3 +2  ];
	//x = sin(push_constants.frame*.01)*.5 + x;
	vec3 offset = vec3(gl_InstanceIndex * 0.2, 0, 0);
	gl_Position = vec4(vec3(x,y,z), 1);
}
