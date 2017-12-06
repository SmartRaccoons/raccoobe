class MirrorTube extends window.o.Object
  _default: {
    color: [187, 230, 239]
    color_active: window.o.ObjectBeam::_default.color
  }
  constructor: ->
    super
    @mesh.position = new BABYLON.Vector3(0, 0, -0.55)
    @mesh._class = @
    @deactive()
    @mesh.rotate(new BABYLON.Vector3(0, 0, 1), @options.rotation * Math.PI / 2, BABYLON.Space.WORLD)
    @

  mirror_id: -> @parent.options.parent._name()

  active: (silent=false)->
    @color(@options.color_active)
    if !silent
      @trigger 'active'

  deactive: -> @color()

  reflect: (v)->
    @active()


class MirrorTubeConnect extends MirrorTube
  name: 'mirrorTube'

  reflect: (v)->
    super
    new BABYLON.Vector3(v.y, -v.x , v.z)


class MirrorTubeConnectOut extends MirrorTube
  name: 'mirrorTube'
  mesh_build: ->
    mesh = super
    mesh.rotate(new BABYLON.Vector3(0, 1, 0), Math.PI, BABYLON.Space.WORLD)
    mesh.rotate(new BABYLON.Vector3(0, 0, 1), Math.PI/2, BABYLON.Space.WORLD)
    return mesh

  reflect: (v)->
    super
    new BABYLON.Vector3(-v.y, v.x , v.z)


class MirrorTubeEmpty extends MirrorTube
  name: 'mirrorTubeEmpty'


class MirrorTubeStraight extends MirrorTube
  name: 'mirrorTubeStraight'

  reflect: (v)->
    super
    new BABYLON.Vector3(v.x, v.y , v.z)


class MirrorTubeStraightOut extends MirrorTubeStraight
  mesh_build: ->
    mesh = super
    mesh.rotate(new BABYLON.Vector3(0, 0, 1), Math.PI, BABYLON.Space.WORLD)
    mesh


class MirrorNormal extends window.o.Object
  name: 'mirror'
  connectors: [[MirrorTubeConnect, MirrorTubeConnectOut], null, [MirrorTubeConnect, MirrorTubeConnectOut]]
  constructor: ->
    super
    @color(null, 0)
    @tubes = []
    @connectors.forEach (connectors, i)=>
      if !connectors
        return
      tubes = (if Array.isArray(connectors) then connectors else [connectors]).map (connector)=> new connector({parent: @, rotation: i})
      tubes.forEach (t1, i)->
        tubes.forEach (t2, j)->
          if i is j
            return
          t1.bind('active', -> t2.active(true) )
          t2.bind('active', -> t1.active(true) )
      @tubes = @tubes.concat(tubes)

  deactive: -> @tubes.forEach (t)-> t.deactive()


class MirrorReverse extends MirrorNormal
  connectors: [null, [MirrorTubeConnect, MirrorTubeConnectOut], null, [MirrorTubeConnect, MirrorTubeConnectOut]]


class MirrorEmpty extends MirrorNormal
  connectors: [MirrorTubeEmpty, MirrorTubeEmpty, MirrorTubeEmpty, MirrorTubeEmpty]


class MirrorStraight extends MirrorNormal
  connectors: [[MirrorTubeStraight, MirrorTubeStraightOut], MirrorTubeEmpty, null, MirrorTubeEmpty]


class MirrorCross extends MirrorNormal
  connectors: [MirrorTubeEmpty, [MirrorTubeStraight, MirrorTubeStraightOut], MirrorTubeEmpty]

_angle_to_xy = (angle)-> {y: Math.round(Math.sin(angle)), x: Math.round(Math.cos(angle))}
_move_positions = [Math.PI*3/2, Math.PI, Math.PI/2, 0]
_move_positions_coors = _move_positions.map _angle_to_xy

window.o.ObjectMirror = class MirrorContainer extends window.o.ObjectBlank
  _default: {
    color: [103, 181, 229, 0.4]
    color_active: [103, 181, 229]
  }
  _move_reverse: false
  _move_positions: _move_positions
  _move_positions_coors: _move_positions_coors
  classes:
    'normal': MirrorNormal
    'reverse': MirrorReverse
    'empty': MirrorEmpty
    'straight': MirrorStraight
    'cross': MirrorCross
  constructor: ->
    super
    @mirror = new @classes[@options.type]({parent: @})
    @_move_position = 0
    @_static = 's' in @options.params
    if !@_static
      @_connector = new @_connector_class({parent: @})
    @out()

  _controls_add: ->
    if @_controls_added
      return
    @_controls_added = true
    @mirror._action
      mouseover: => @over()
      mouseout: => @out()
      click: =>
        @out()
        @trigger 'move', @get_move_position()

  _controls_remove: ->
    @_controls_added = false
    @out()
    @mirror._action_remove()

  get_move_position: (n = @_move_position, full = false)->
    p = @_move_positions_coors[n]
    if !full
      return p
    {x: p.x + @position.x, y: p.y + @position.y}

  set_move_position: (nr)->
    if nr is null
      @_controls_remove()
      return @_connector.hide()
    @_controls_add()
    @_move_position = nr
    @_connector.angle(@_move_positions[nr], @_move_reverse)

  move: (position)->
    @position.x = @position.x + position.x
    @position.y = @position.y + position.y
    @_update_position()

  _update_position: (without_animation = false)->
    position_new = [@position.x * @_step, @position.y * @_step, 0]
    position_set = => @mesh.position = new BABYLON.Vector3(position_new[0], position_new[1], position_new[2])
    if without_animation
      return position_set()
    position = [@mesh.position.x, @mesh.position.y]
    position_diff = [position_new[0] - position[0], position_new[1] - position[1]]
    @_animation (m, steps)=>
      if steps is 0
        position_set()
        @trigger 'move_end'
        return
      @mesh.position = new BABYLON.Vector3(position[0] + position_diff[0] * m, position[1] + position_diff[1] * m, position_new[2])
    , 20

  over: ->
    @color(@options.color_active)
    @_connector.color(@options.color_active)

  out: ->
    if @_static
      return @color(window.o.ObjectBlank::_default.color, 0)
    @color()
    @_connector.color(window.o.ObjectBlank::_default.color)


_move_positions_reverse = [_move_positions[0], _move_positions[3], _move_positions[2], _move_positions[1]]
_move_positions_coors_reverse = _move_positions_reverse.map _angle_to_xy

window.o.ObjectMirrorReverse = class MirrorContainerReverse extends MirrorContainer
  _move_reverse: true
  _default: {
    color: [188, 105, 43, 0.4]
    color_active: [188, 105, 43]
  }
  _move_positions: _move_positions_reverse
  _move_positions_coors: _move_positions_coors_reverse
