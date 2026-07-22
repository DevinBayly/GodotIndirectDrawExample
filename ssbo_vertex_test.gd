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
var pos_buffer:= RID()
var shader := RID()
var pipeline := RID()

var vertex_format := 0
var vertex_buffer := RID()
var vertex_array := RID()
var posUniset

func _ready() -> void:
	
	
	var rs := RenderingServer
	rd = rs.get_rendering_device()
	
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
	var temp_data = PackedFloat32Array([])
	temp_data.resize(500*3)
	for i in range(temp_data.size()):
		temp_data[i] = randf()
	var temp_buffer_bytes = temp_data.to_byte_array()
	var temp_buffer = rd.storage_buffer_create(temp_buffer_bytes.size(),temp_buffer_bytes)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding =0 # this needs to match the "binding" in our shader file
	uniform.add_id(temp_buffer)
	posUniset = rd.uniform_set_create([uniform], shader, 0)
	print(posUniset)
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
	rd.draw_list_bind_uniform_set(dlist,posUniset,0)

	rd.draw_list_draw_indirect(dlist, false, indirect_args)
	rd.draw_list_end()
	#var output_bytes := rd.buffer_get_data(pos_buffer)
	#var output := output_bytes.to_float32_array()
	#print("Input: ", input)
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
