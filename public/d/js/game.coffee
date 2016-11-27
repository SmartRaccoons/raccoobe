


class Game
  _step: 10

  constructor: ->
    @_object_id = 0
    @_mirror = []
    @_platform = []
    @_mirrors_correct = false
#    @_wall = []

  map: ->
    methods = {
      '0': null
      '1': 'mirror'
      '2': 'mirror_reverse'
      '8': 'beam_source'
      '9': 'target'
    }

    map_string = window.MAPS[0]
#    map = window.MAP(10, 4, [2, 4])
    map = map_string.split("\n").map (s)->
      s.trim().split('').map (ob)-> parseInt(ob)
    size = map[0].length
    middle = Math.floor(size/2)
    for fn in Object.keys(methods)
      methods[fn] = ((name, fn)=>
        (parent=null, x=0, y=0)=>
          if fn
            params = [[x*10, y*10, 0]]
            if parent
              params.unshift(parent)
            @[fn].apply(@, params)
      )(fn, methods[fn])

    methods[map[middle][middle]]()
    map.reverse()
    for m in [0...size]
      methods[map[0][m]](null, m - middle, -middle - 1)
    map.shift()
    for m in [1..middle]
      parent = @platform(m, m * 10)
      for y in [-m..m]
        methods[map[(y + middle)][m + middle]](parent, m, y)
        methods[map[(y + middle)][-m + middle]](parent, -m, y)
      for x in [(-m+1)...m]
        methods[map[m + middle][x + middle]](parent, x, m)
        methods[map[-m + middle][x + middle]](parent, x, -m)

  _name: ->
    @_object_id++
    "o_#{@_object_id}"

  beam_source: (coors)->
    @_beam_coors = coors
    ob = BABYLON.Mesh.CreateSphere(@_name(), 5, 4, @_scene)
    material = new BABYLON.StandardMaterial(@_name(), @_scene)
    ob.material = material
    ob._type = 'source'
    ob.position.x = coors[0]
    ob.position.y = coors[1]
    ob.position.z = coors[2]
    ob.material.emissiveColor = new BABYLON.Color3(1.0, 1.0, 0)

  platform: (name, size)->
    console.info 'platform', name, size
    width = size * 2 + @_step
    depth = 2
    ob = BABYLON.MeshBuilder.CreateBox(@_name(), {
      width: width
      height: width
      depth: depth
    }, @_scene)
    ob.material = new BABYLON.StandardMaterial(@_name(), @_scene)
    ob.material.alpha = 0.4
    ob._rotation_animations = []
    for c in [{
      size: [@_step, @_step]
      position: [size, size]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(space, -space, 0)
    }, {
      size: [@_step, @_step]
      position: [-size, -size]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(-space, space, 0)
    }, {
      size: [@_step, @_step]
      position: [size, -size]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(-space, -space, 0)
    }, {
      size: [@_step, @_step]
      position: [-size, size]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(space, space, 0)
    }, {
      size: [width - 2 * @_step, @_step]
      position: [0, size]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(space, 0, 0)
    }, {
      size: [width - 2 * @_step, @_step]
      position: [0, -size]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(-space, 0, 0)
    }, {
      size: [@_step, width - 2 * @_step]
      position: [-size, 0]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(0, space, 0)
    }, {
      size: [@_step, width - 2 * @_step]
      position: [size, 0]
      click: (space)-> ob._rotation_animations.push new BABYLON.Vector3(0, -space, 0)
    }]
      for space in [-1, 1]
        action = BABYLON.MeshBuilder.CreateBox(@_name(), {
          width: c.size[0]
          height: c.size[1]
          depth: @_step / 2
        }, @_scene)
        action.parent = ob
        action.position = new BABYLON.Vector3(-c.position[0], -c.position[1], space * @_step/4 )
        action.actionManager = new BABYLON.ActionManager(@_scene)
        action.actionManager.registerAction new BABYLON.ExecuteCodeAction BABYLON.ActionManager.OnPickTrigger, ((space, fn)->
          => fn(space)
        )(space, c.click)
        action.actionManager.registerAction new BABYLON.ExecuteCodeAction BABYLON.ActionManager.OnPointerOverTrigger, ((action)=>
          =>
            action.material._alpha_previous = action.material.alpha
            action.material.alpha = 0.7
        )(action)
        action.actionManager.registerAction new BABYLON.ExecuteCodeAction BABYLON.ActionManager.OnPointerOutTrigger, ((action)=>
          => action.material.alpha = action.material._alpha_previous
        )(action)
        action.material = new BABYLON.StandardMaterial(@_name(), @_scene)
        action.material.alpha = 0
    @_platform.push ob
    ob

  mirror_reverse: (parent, coors)->
    @mirror(parent, coors, Math.PI/4 + Math.PI/2)

  mirror: (parent, coors, angle=Math.PI/4)->
    ob = BABYLON.MeshBuilder.CreateBox(@_name(), {
      width: 10
      height: 1
      depth: 10
    }, @_scene)
    ob.parent = parent
    ob.position.x = coors[0]
    ob.position.y = coors[1]
    ob.position.z = coors[2]
    ob._type = 'mirror'
    ob.rotation.z = angle
    @_mirror.push ob
    ob

  obstacle: (parent, coors)->
    ob = BABYLON.Mesh.CreateBox(@_name(), 4, @_scene)
    ob.position.x = coors[0]
    ob.position.y = coors[1]
    ob.position.z = coors[2]
    ob._type = 'obstacle'
    ob

  _reflect: (v, mesh)->
    points = mesh._boundingInfo.boundingBox.vectorsWorld.reduce (actual, value)->
      return [
        if !actual[0] or actual[0].x > value.x then value else actual[0],
        if !actual[1] or actual[1].x < value.x then value else actual[1]
      ]
    right = points[0].y > points[1].y
    if (v.x is 0 and right) or (v.y is 0 and !right)
      return new BABYLON.Vector3(-v.y, v.x , 0)
    return new BABYLON.Vector3(v.y, -v.x , 0)

  beam_remove: ->
    if @_beam
      @_beam.dispose()
      @_beam = null

  beam: (angle = Math.PI/2)->
    console.info 'beam'
    @text('')
    length = 10**5
    @beam_remove()
    points = [new BABYLON.Vector3(@_beam_coors[0], @_beam_coors[1], @_beam_coors[2])]
    last_mirror = null
    end = new BABYLON.Vector3(Math.round(Math.cos(angle) * length), Math.round(Math.sin(angle) * length), 0)
    for i in [0..100]
      pick_info = @_scene.pickWithRay new BABYLON.Ray(points[points.length - 1], end, 1000), ((i)->
        (m)->
          if (i is 0 and m._type is 'source') or last_mirror is m.id
            return false
          ['mirror', 'target', 'obstacle', 'source'].indexOf(m._type) > -1
      )(i)
      pick_info_point = if pick_info.pickedPoint then new BABYLON.Vector3(Math.round(pick_info.pickedPoint.x/10)*10, Math.round(pick_info.pickedPoint.y/10)*10, Math.round(pick_info.pickedPoint.z/10)*10) else null
      points.push if pick_info_point then pick_info_point else end
      if not pick_info.hit
        break
      if pick_info.pickedMesh._type is 'target'
        @text('Well done!')
      if pick_info.pickedMesh._type isnt 'mirror'
        break
      end = @_reflect(end, pick_info.pickedMesh)
      if end is null
        break
      last_mirror = pick_info.pickedMesh.id
    @_beam = BABYLON.Mesh.CreateLines(@_name(), points, @_scene)
    @_beam_angle_prev = angle

  target: ->
    target = BABYLON.Mesh.CreateSphere(@_name(), 5, 2, @_scene)
    material = new BABYLON.StandardMaterial(@_name(), @_scene)
    material.emissiveColor = new BABYLON.Color3(1.0, 0, 0)
    target.material = material
    target._type = 'target'
    @_target = target
    target

  text: (t)->
    if t is @_text_last
      return
    @_text_last = t
    if not @_text_plane
      @_text_plane = BABYLON.Mesh.CreatePlane(@_name(), 60, @_scene, false)
#      @_text_plane.billboardMode = BABYLON.AbstractMesh.BILLBOARDMODE_ALL
      @_text_plane.position = new BABYLON.Vector3(0, 0, 10)
      @_text_plane.material = new BABYLON.StandardMaterial(@_name(), @_scene)
      @_text_plane.material.backFaceCulling = false
      @_text_plane.material.diffuseTexture = texture = new BABYLON.DynamicTexture(@_name(), {
        width: 512
        height: 512
      }, @_scene, true)
      texture.hasAlpha = true
    else
      texture = @_text_plane.material.diffuseTexture
    texture.getContext().clearRect(0, 0, 512, 512)
    texture.drawText(t, null, 256, "bold 40px verdana", '#11ee00', null)

  _render_loop: ->

  _render_before_loop: ->
    changes = false
    @_platform.forEach (ob)=>
      if not ob._rotation_animation
        if ob._rotation_animations.length is 0
          return
        ob._rotation_animation = {
            vector: ob._rotation_animations.shift()
            steps: 30
            step: Math.PI/30
          }
      changes = true
      ob.rotate(ob._rotation_animation.vector, ob._rotation_animation.step, BABYLON.Space.LOCAL)
      ob._rotation_animation.steps--
      if ob._rotation_animation.steps is 0
        ob._rotation_animation = null
    if changes and @_beam
      @beam_remove()
    if not changes and not @_beam
      @beam()

  render: ->
    canvas = document.createElement('canvas')
    document.body.appendChild(canvas)
    engine = new BABYLON.Engine(canvas, true)
    engine.runRenderLoop =>
      @_render_loop()
      scene.render()
    window.addEventListener 'resize', ->
      engine.resize()

    scene = @_scene = new BABYLON.Scene(engine)
    scene.registerBeforeRender @_render_before_loop.bind(@)
    camera = new BABYLON.ArcRotateCamera("Camera", 0, 0, 200, BABYLON.Vector3.Zero(), scene)
    camera.setPosition(new BABYLON.Vector3(-50, -60, -200))
    camera.attachControl(canvas, false)
    @map()
    scene.render()
    @beam()


g = new Game()
g.render()