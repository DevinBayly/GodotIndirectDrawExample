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

	////use the x value offset by 3s so that we can store the results in a flat array
	//// try making small triangle centered on the corners of each existing one

	//float side_size = .05;
	//pos_data.data[gl_GlobalInvocationID.x] = gl_GlobalInvocationID.x/10.0;	
	
	// optional to have each invocation write out 9 coordinates so we've basically made 1 new triangle each invocation
	if (gl_GlobalInvocationID.x ==0) {
	pos_data.data[gl_GlobalInvocationID.x ] = v1.x;
	pos_data.data[gl_GlobalInvocationID.x + 1] = v1.y;
	pos_data.data[gl_GlobalInvocationID.x + 2] = v1.z;
	}
	if (gl_GlobalInvocationID.x ==1) {
	pos_data.data[gl_GlobalInvocationID.x*3 ] = v1.x +.2;
	pos_data.data[gl_GlobalInvocationID.x*3 + 1] = v1.y +.2;
	pos_data.data[gl_GlobalInvocationID.x*3 + 2] = v1.z;
	}
	if (gl_GlobalInvocationID.x ==2) {
	pos_data.data[gl_GlobalInvocationID.x*3 ] = v1.x +.2;
	pos_data.data[gl_GlobalInvocationID.x*3 + 1] = v1.y -.2;
	pos_data.data[gl_GlobalInvocationID.x*3 + 2] = v1.z;
	}
}
