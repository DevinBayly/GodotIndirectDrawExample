#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

// in theory this is the vertex list
layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
	float data[];
}
my_data_buffer;


// this one would be the subdivided positions that we are going to put out after
layout(set = 0, binding = 1, std430) buffer MyPosDataBuffer {
	float data[];
}
pos_data;
// this is the buffer we will use to control the individual colors of the triangles

layout(set = 0, binding = 2, std430) buffer InvocationBuffer {
	int data[];
}
inv_data;

// bring in meshlet data somehow, include a specific vec3 holding the centroid that we will perform the camera operation on 

struct CamDetails {
    float my_float;
    int my_int1;
    int my_int2;
    float _pad; 
    mat4 camera_mat;
};

layout(set = 0, binding = 3, std430) buffer CameraBuffer {
	CamDetails data[];
} cam_data;



// The code we want to execute in each invocation
void main() {
	// gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
	//my_data_buffer.data[gl_GlobalInvocationID.x] *= 1;

	// multiply centroid vec3 by cam mat which has the whole model, cam,view  process baked into it, and check whether the position is outside of 0-1 or the final range which constitutes "inside" the region the camera should be able to see 

	// if we decide the meshlet belongs in the region we will write out to thatstorage buffer 

	// use index and vertex buffer to construct 

}
