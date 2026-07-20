extends Node

const SIZEOF_VECTOR3 := 4 * 3
const TRIANGLE_VERTICES: PackedVector3Array = [
	Vector3( 0.0,  0.1, 0.0),
	Vector3(-0.1, -0.1, 0.0),
	Vector3( 0.1, -0.1, 0.0)
]

@export var vertex_shader_file: RDShaderFile = null
@export var fragment_shader_file: RDShaderFile = null
@export var instance_count := 1 : set = set_instance_count

var rd: RenderingDevice = null

var indirect_args := RID()

var shader := RID()
var pipeline := RID()

var vertex_format := 0
var vertex_buffer := RID()
var vertex_array := RID()


func side_compute(buffer):
	var rd = RenderingServer.get_rendering_device();
	var shader_file := load("res://cshader.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
#
	#var input := PackedInt32Array([2, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	#var input_bytes := input.to_byte_array()
#
	## Create a storage buffer that can hold our float values.
	## Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	#var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(buffer)
	var uniform_set := rd.uniform_set_create([uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	# this is where our triangle values would go
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 5, 1, 1)
	rd.compute_list_end()	
	# Submit to GPU and wait for sync
	#rd.submit()
	#rd.sync()
	# Read back the data from the buffer
	var output_bytes := rd.buffer_get_data(buffer)
	print(output_bytes)
	var output := output_bytes.to_int32_array()
	#print("Input: ", input)
	print("Output: ", output)
	#rd.free_rid(buffer)

func _ready() -> void:
	assert(vertex_shader_file)
	assert(fragment_shader_file)
	
	var rs := RenderingServer
	rd = rs.get_rendering_device()
	
	if true: #Indirect args
		var args := indirect_args_struct(TRIANGLE_VERTICES.size(), instance_count)
		indirect_args = rd.storage_buffer_create(args.size(), args, RenderingDevice.STORAGE_BUFFER_USAGE_DISPATCH_INDIRECT)
		side_compute(indirect_args)
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
		bundle.bytecode_vertex = vertex_shader_file.get_spirv().bytecode_vertex
		bundle.bytecode_fragment = fragment_shader_file.get_spirv().bytecode_fragment
		shader = rd.shader_create_from_spirv(bundle)
	
	if true: #Pipeline
		var framebuffer_format := rd.screen_get_framebuffer_format()
		var primitive := RenderingDevice.RENDER_PRIMITIVE_TRIANGLES
		
		var rasterization := RDPipelineRasterizationState.new()
		var multisample := RDPipelineMultisampleState.new()
		var depth := RDPipelineDepthStencilState.new()
		var blend := RDPipelineColorBlendState.new()
		blend.attachments = [RDPipelineColorBlendStateAttachment.new()]
		
		pipeline = rd.render_pipeline_create(shader, framebuffer_format, vertex_format, primitive, rasterization, multisample, depth, blend)

func _process(delta: float) -> void:
	var dlist := rd.draw_list_begin_for_screen()
	rd.draw_list_bind_render_pipeline(dlist, pipeline)
	rd.draw_list_bind_vertex_array(dlist, vertex_array)
	rd.draw_list_draw_indirect(dlist, false, indirect_args)
	rd.draw_list_end()

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
