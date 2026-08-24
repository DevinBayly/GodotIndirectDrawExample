#[vertex]
#version 450


layout(push_constant) uniform PushConstants {
	mat4 cam;
} push_constants;

layout(set = 0, binding = 0,std430)  buffer FloatBuffer {
	float data[];
} float_buffer;
layout(set = 0, binding = 2,std430)  buffer VertBuffer {
	float data[];
} jvertbuffer;
layout(set = 0, binding = 3,std430)  buffer IndBuffer {
	int data[];
} jindbuffer;
layout(set = 0, binding = 4,std430)  buffer MeshletBuffer {
	int data[];
} meshindbuffer;
layout (location = 0) in vec3 Vertex;
layout (location = 0 ) flat out int vid;
layout (location = 1 ) flat out int iid;
layout (location = 2 ) flat out int mid;

void main() {
	// ah yes, so the bottom triangle was only created when the vertex index was all zero
	vid = gl_VertexIndex;
	iid = gl_InstanceIndex;
	//pid = gl_PrimitiveID;
	mid = meshindbuffer.data[iid];
	

	// for testing use the frame push constant to give a rotation of our cube

	//float offset2 = float_buffer.data[gl_InstanceIndex];
	int point_ind = jindbuffer.data[iid*3 + vid];	
	// the point ind will be multiplied by the number of components stored for each point (x,y,z)==3

	float x = jvertbuffer.data[point_ind*3 +0  ];
	float y = jvertbuffer.data[point_ind*3 +1  ];
	float z = jvertbuffer.data[point_ind*3 +2  ];
	//x = sin(push_constants.frame*.01)*.5 + x;
	vec3 offset = vec3(gl_InstanceIndex * 0.2, 0, 0);
	gl_Position = push_constants.cam*vec4(vec3(x,y,z), 1);
}
