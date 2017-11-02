
_object_id = 0

meshes = {}
vertexes = null
_scene = null
_engine = null
_light = null
_camera = null

window.App.events.bind 'game:init', (scene, engine, light, camera)->
  _scene = scene
  _engine = engine
  _light = light
  _camera = camera
  meshes = {}
  for k, v of window.o.ObjectData
    vertex = new BABYLON.VertexData()
    vertex.positions = v.positions.slice()
    vertex.normals = v.normals.slice()
    vertex.indices = v.indices.slice()
    meshes[k] = new BABYLON.Mesh("preload_#{k}", _scene)
    vertex.applyToMesh(meshes[k])
    meshes[k].convertToFlatShadedMesh()
    meshes[k].isVisible = false
  _convertToFlat = true


window.o.Object = class Object extends MicroEvent
  _default: {}
  constructor: (options)->
    _object_id++
    @_id = _object_id
    @options = _.extend({}, @_default, options)
    if @options.parent_class
      @parent = @options.parent_class
    @mesh = @mesh_build()
    @mesh._type = @name
    if @options.parent
      @mesh.parent = @options.parent
    if @options.position
      @mesh.position = new BABYLON.Vector3(@options.position[0], @options.position[1] or 0, @options.position[2] or 0)
    if @options.action
      @_action(@options.action)
    @

  _action: (action)->
    @mesh.actionManager = new BABYLON.ActionManager(@scene())
    if action.click
      @mesh.actionManager.registerAction new BABYLON.ExecuteCodeAction BABYLON.ActionManager.OnPickTrigger, action.click
    if action.mouseover
      @mesh.actionManager.registerAction new BABYLON.ExecuteCodeAction BABYLON.ActionManager.OnPointerOverTrigger, action.mouseover
    if action.mouseout
      @mesh.actionManager.registerAction new BABYLON.ExecuteCodeAction BABYLON.ActionManager.OnPointerOutTrigger, action.mouseout

  mesh_build: ->
    mesh = meshes[@name].clone(meshes[@name].name)
    mesh.id = @_name()
    mesh.isVisible = true
    mesh

  color: (red, green, blue, alpha = 1)->
    if !@mesh.material
      @mesh.material = new BABYLON.StandardMaterial("material_#{@_name()}", @scene())
    @mesh.material.diffuseColor = new BABYLON.Color3(red/255, green/255, blue/255)
    @mesh.material.alpha = alpha

  scene: -> _scene

  godrays: ->
    new BABYLON.VolumetricLightScatteringPostProcess("godrays_#{@_name()}", 1, _camera, @mesh, 50, BABYLON.Texture.BILINEAR_SAMPLINGMODE, _engine, false)

  _name: ->
    if not @__name
      name = ['ob']
      if @name
        name.push @name
      name.push @_id
      @__name = name.join('_')
    return @__name

  remove: ->
    @trigger 'remove'
    super
    @mesh.dispose()


window.o.ObjectSphere = class ObjectSphere extends Object
  _default: {
    segments: 5
  }
  mesh_build: ->
    BABYLON.Mesh.CreateSphere(@_name(), @options.segments, @options.diameter, @scene())


window.o.ObjectBox = class ObjectSphere extends Object
  mesh_build: ->
    BABYLON.MeshBuilder.CreateBox(@_name(), {
      width: @options.dimension[0]
      height: @options.dimension[1]
      depth: @options.dimension[2]
    }, @scene())
