extends Node

var SIZEOF_VECTOR3 := 4 * 3
var TRIANGLE_VERTICES: PackedVector3Array = [
	Vector3( 0.0,  0.5, 0.0),
	Vector3(-0.5, -0.5, 1.0),
	Vector3( 0.5, -0.5, 0.0)
]
# make a new list for the vertices we will pretend we got from compute shader
# also include the index buffer for re-using the index values
var json_vertices: PackedVector3Array = []
var json_indices: PackedInt32Array = []
var meshlet_indices: PackedInt32Array =[]
# now make the buffer rid's for each of them
var json_vertices_buffer = RID()
var json_indices_buffer = RID()
var meshlet_indices_buffer= RID()

@export var camera :Camera3D = null
@export var vertex_shader_file: RDShaderFile = null
@export var fragment_shader_file: RDShaderFile = null
@export var instance_count := 1 : set = set_instance_count

var rd: RenderingDevice = null

var indirect_args := RID()
var pos_buffer:= RID()
var invocation_buffer := RID()


var shader := RID()
var pipeline := RID()

var vertex_format := 0
var vertex_buffer := RID()
var vertex_array := RID()
var posUniset
var temp_buffer
var frame =0;
var push_byte_array:PackedByteArray=[];


func side_compute():
	var rd = RenderingServer.get_rendering_device();
	var shader_file := load("res://cshader.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	var vertex_bytes := TRIANGLE_VERTICES.to_byte_array()
	var inv_array = PackedInt32Array()
	inv_array.resize(instance_count*3)
	var inv_array_bytes = inv_array.to_byte_array()
	
	# test out making an array of structs to pass to the shader
	var stream = StreamPeerBuffer.new()
	stream.big_endian = false
	# could be something like fov, but I guess that's often in the matrix when it's turned into a matrix
	stream.put_float(5.0)
	stream.put_32(1)
	stream.put_32(2)
	# spare alignment bytes
	stream.put_float(0.0)
	# camera data
	var model_transform = Projection(Transform3D())
	var cam_view = Projection(camera.global_transform.affine_inverse())
	var camera_projection = camera.get_camera_projection()
	var combined = camera_projection*cam_view*model_transform
	# then iterate over and put the float values into stream
	print(combined)
	for i in range(4):
		for j in range(4):
			var mat_cell = combined[i][j]
			stream.put_float(mat_cell)
			print(mat_cell)
	var streamByteArray = stream.data_array
	var arrayOfStructBuffer = rd.storage_buffer_create(streamByteArray.size(),streamByteArray)
	
	
	## Create a storage buffer that can hold our float values.
	## Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	var buffer := rd.storage_buffer_create(vertex_bytes.size(), vertex_bytes)
	invocation_buffer = rd.storage_buffer_create(inv_array_bytes.size(),inv_array_bytes) 
	# Create a uniform to assign the buffer to the rendering device

	# send in the first triangle as a small array  
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(buffer)
	var uniform2 := RDUniform.new()
	uniform2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform2.binding = 1 # this needs to match the "binding" in our shader file
	uniform2.add_id(temp_buffer)
	var uniform3 := RDUniform.new()
	uniform3.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform3.binding =2
	uniform3.add_id(invocation_buffer)
	var uniform4 := RDUniform.new()
	uniform4.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform4.binding =3
	uniform4.add_id(arrayOfStructBuffer)
	var uniform_set := rd.uniform_set_create([uniform,uniform2,uniform3,uniform4], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	# make the sencond uniform set
	#print(uniform_set)
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	# this is where our triangle values would go
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()	

func _ready() -> void:
	
	var rs := RenderingServer
	rd = rs.get_rendering_device()
	
	# process the json
	var f = FileAccess.open("meshlets.json",FileAccess.READ)
	var text = f.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	if err:
		print(err)
	else:
		print("ok!")
		# read the vertex data into the triangles at the top instead of the defaault
		
		#TRIANGLE_VERTICES.resize(0)
		for v in json.data["vertex_positions"]:
			var tempv = Vector3(v[0],v[1],v[2]+1)
			json_vertices.push_back(tempv)
		for m in json.data["meshlets"]:
			var m_ind = m["index"]
			# so it's sort of nested because the meshlet has both a triangle id and a vertex vertex_
			# vertices map back to the above list, triangles map into the index of the meshlet vertex list
			var m_vs = m["vertices"]
			var m_tris = m["triangles"]
			for t in m_tris:
				for tv_ind in t:
					json_indices.push_back(m_vs[tv_ind])
				meshlet_indices.push_back(m_ind)
		#print(json_vertices)
		#print(json_indices)
		#print(meshlet_indices)
	# make the buffers for the json/meshlet data
	json_vertices_buffer =  rd.storage_buffer_create(json_vertices.to_byte_array().size(),json_vertices.to_byte_array())
	json_indices_buffer = rd.storage_buffer_create(json_indices.to_byte_array().size(),json_indices.to_byte_array())
	meshlet_indices_buffer= rd.storage_buffer_create(meshlet_indices.to_byte_array().size(),meshlet_indices.to_byte_array())

	
	
	var temp_data = PackedFloat32Array([])
	temp_data.resize(500*3)
	for i in range(temp_data.size()):
		temp_data[i] = 0.0
	var temp_buffer_bytes = temp_data.to_byte_array()
	temp_buffer = rd.storage_buffer_create(temp_buffer_bytes.size(),temp_buffer_bytes)
	
	# setup compute shader to put new positions in buffer shared with vertex shader
	side_compute()
	
	if true: #Indirect args
		var args := indirect_args_struct(TRIANGLE_VERTICES.size(), instance_count)
		indirect_args = rd.storage_buffer_create(args.size(), args, RenderingDevice.STORAGE_BUFFER_USAGE_DISPATCH_INDIRECT)
		
	if true: #Vertex format
		var attributes := []
		
		if true:
			var attribute := RDVertexAttribute.new()
			attribute.frequency = RenderingDevice.VERTEX_FREQUENCY_VERTEX
			attribute.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT
			attribute.stride = SIZEOF_VECTOR3
			attribute.offset = 0
			attributes.push_back(attribute)
		
		vertex_format = rd.vertex_format_create(attributes)
	
	if true: #Vertex buffer
		var bytes := TRIANGLE_VERTICES.to_byte_array()
		vertex_buffer = rd.vertex_buffer_create(bytes.size(), bytes)
	
	if true: #Vertex array
		vertex_array = rd.vertex_array_create(TRIANGLE_VERTICES.size(), vertex_format, [vertex_buffer])
	
	if true: #Shader
		var bundle := RDShaderSPIRV.new()
		var vfile = load("res://vertex.glsl")
		var vspirv = vfile.get_spirv()
		bundle.bytecode_vertex = vspirv.bytecode_vertex
		var ffile = load("res://fragment.glsl")
		var fspirv = ffile.get_spirv()
		bundle.bytecode_fragment = fspirv.bytecode_fragment
		shader = rd.shader_create_from_spirv(bundle)
	# uniform set binding
	# try making our own position buffer
	
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding =0 # this needs to match the "binding" in our shader file
	uniform.add_id(temp_buffer)
	var uniform2 := RDUniform.new()
	uniform2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform2.binding =1
	uniform2.add_id(invocation_buffer)
	
	# here we will add in the json/meshlet data as uniforms
	var jvertuniform = RDUniform.new()
	jvertuniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	jvertuniform.binding = 2
	jvertuniform.add_id(json_vertices_buffer)
	var jinduniform = RDUniform.new()
	jinduniform.uniform_type= RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	jinduniform.binding = 3
	jinduniform.add_id(json_indices_buffer)
	var meshinduniform = RDUniform.new()
	meshinduniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	meshinduniform.binding = 4
	meshinduniform.add_id(meshlet_indices_buffer)
	#posUniset = rd.uniform_set_create([uniform,uniform2], shader, 0)
	posUniset = rd.uniform_set_create([uniform,uniform2,jvertuniform,jinduniform,meshinduniform],shader,0)
	#print(posUniset)
	update_camera()
	

	#push_byte_array.encode_float(0,frame)
	
	# try to make a push constant for the camera
	#push_byte_array.encode_float()
	
	if true: #Pipeline
		var framebuffer_format := rd.screen_get_framebuffer_format()
		var primitive := RenderingDevice.RENDER_PRIMITIVE_TRIANGLES
		
		var rasterization := RDPipelineRasterizationState.new()
		rasterization.cull_mode = RenderingDevice.POLYGON_CULL_BACK
		rasterization.front_face = RenderingDevice.POLYGON_FRONT_FACE_CLOCKWISE # or CLOCKWISE depending on your index buffer
		var multisample := RDPipelineMultisampleState.new()
		var depth := RDPipelineDepthStencilState.new()
		depth.enable_depth_test = true
		depth.enable_depth_write = true
		depth.depth_compare_operator = RenderingDevice.COMPARE_OP_LESS
		var blend := RDPipelineColorBlendState.new()
		blend.attachments = [RDPipelineColorBlendStateAttachment.new()]
		
		pipeline = rd.render_pipeline_create(shader, framebuffer_format, vertex_format, primitive, rasterization, multisample, depth, blend)
func update_camera():
	# add push constant so we can have visual update over timed
	var model_transform = Projection(Transform3D())
	var cam_view = Projection(camera.global_transform.affine_inverse())
	var camera_projection = camera.get_camera_projection()
	var combined = camera_projection*cam_view*model_transform
	push_byte_array = PackedVector4Array([combined.x,combined.y,combined.z,combined.w]).to_byte_array()
func _process(delta: float) -> void:
	var dlist := rd.draw_list_begin_for_screen()
	rd.draw_list_bind_render_pipeline(dlist, pipeline)
	rd.draw_list_bind_vertex_array(dlist, vertex_array)
	# set the uniform in the next draw list
	rd.draw_list_bind_uniform_set(dlist,posUniset,0)
	frame +=1
	#push_byte_array.encode_float(0,frame)
	update_camera()
	rd.draw_list_set_push_constant(dlist,push_byte_array,push_byte_array.size())
	rd.draw_list_draw_indirect(dlist, false, indirect_args)
	rd.draw_list_end()
	#var output_bytes := rd.buffer_get_data(invocation_buffer)
	#var output := output_bytes.to_int32_array()
	##print("Input: ", input)
	#print("Output: ", output)
	pass

func set_instance_count(new_instance_count: int) -> void:
	instance_count = new_instance_count
	
	if indirect_args.is_valid():
		var args := indirect_args_struct(TRIANGLE_VERTICES.size(), instance_count)
		rd.buffer_update(indirect_args, 0, args.size(), args)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		rd.free_rid(indirect_args)
		rd.free_rid(shader)
		rd.free_rid(vertex_buffer)

static func indirect_args_struct(vertex_count: int, instance_count: int, first_vertex := 0, first_instance := 0) -> PackedByteArray:
	var layout: PackedInt32Array = [
		vertex_count,
		instance_count,
		first_vertex,
		first_instance
	]
	return layout.to_byte_array()
