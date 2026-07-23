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

// The code we want to execute in each invocation
void main() {
	// gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
	//my_data_buffer.data[gl_GlobalInvocationID.x] *= 1;


	// use the float buffer at binding 1 to make a collection of 3 vertices
	vec3 v1 = vec3(
	my_data_buffer.data[0],
	my_data_buffer.data[1],
	my_data_buffer.data[2]
	);
	vec3 v2 = vec3(
	my_data_buffer.data[3],
	my_data_buffer.data[4],
	my_data_buffer.data[5]
	);
	vec3 v3 = vec3(
	my_data_buffer.data[6],
	my_data_buffer.data[7],
	my_data_buffer.data[8]
	);

	vec3 points[3];
	points[0] = v1;
	points[1] = v2;
	points[2] = v3;

	////use the x value offset by 3s so that we can store the results in a flat array
	//// try making small triangle centered on the corners of each existing one

	//float side_size = .05;
	//pos_data.data[gl_GlobalInvocationID.x] = gl_GlobalInvocationID.x/10.0;	
	
	// optional to have each invocation write out 9 coordinates so we've basically made 1 new triangle each invocation


	// calculate off of the idx
	// out corner (so the part of the subdivided triangle)
	
	uint ocornerId = gl_GlobalInvocationID.x%3;
	// in corner
	int icornerId = int(gl_GlobalInvocationID.x)/3;

	vec3 mid;
	if (ocornerId ==0) {
		mid = points[icornerId];
	}
	if (gl_GlobalInvocationID.x ==1) {
	// split difference to v2
	mid = (v1+v2)/2;
	}
	if (gl_GlobalInvocationID.x ==2) {
	mid = (v1+v3)/2;

	}
	if (gl_GlobalInvocationID.x ==4) {
	mid = (v2+v3)/2;

	}
	if (gl_GlobalInvocationID.x ==5) {
	mid = (v2 +v1)/2;
	}
	if (gl_GlobalInvocationID.x ==7) {
	mid = (v3+v1)/2;

	}
	if (gl_GlobalInvocationID.x ==8) {
	mid = (v3 + v2)/2;
	}
	pos_data.data[gl_GlobalInvocationID.x*3 ] = mid.x;
	pos_data.data[gl_GlobalInvocationID.x*3 + 1] = mid.y;
	pos_data.data[gl_GlobalInvocationID.x*3 + 2] = mid.z;
	// update the invocation buffer
	inv_data.data[gl_GlobalInvocationID.x] = int(gl_GlobalInvocationID.x);

}
