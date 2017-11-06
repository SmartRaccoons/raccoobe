window.o.GameMap = class Map extends MicroEvent
  constructor: ->
    @clear()
    @_before_render_fn = []
    super
    in_action_active = 0
    triggered_start = false
    window.App.events.bind 'map:animation', (animation, callback, steps = 30, in_action=false)=>
      if !@_animations[animation]
        @_animations[animation] = []
      if in_action
        in_action_active++
        if not triggered_start
          @trigger 'animation_start'
          triggered_start = true
      @_animations[animation].push {
        callback: (m, steps)=>
          callback.apply(@, arguments)
          if steps isnt 0
            return
          if in_action
            in_action_active--
            if in_action_active is 0
              @trigger 'animation_end'
              triggered_start = false
        steps: steps
        steps_total: steps
      }
    @bind 'animation_start', =>
      @_source.beam_remove()
    @bind 'animation_end', =>
      @_before_render_fn.push =>
        @position_check()
        @_source.beam()
        @solved = @_source.solved
        @trigger 'beam', @_source._mirror.length

  clear: ->
    @_blank = []
    @_mirror = []
    @_animations = {}
    @solved = false

  load: (map_string)->
    methods = {
      '-': null
      '0': 'blank'
      '1': 'mirror'
      '2': 'mirror_reverse'
      '8': 'beam_source'
      '9': 'target'
    }
    call = (method, x=0, y=0)=>
      if methods[method]
        @[methods[method]]([x, y])

    map = map_string.split("\n").map (s)-> s.trim().split('')
    middle = Math.floor(map[0].length/2)
    @_map = {}
    map.forEach (row, j)=>
      row.forEach (cell, i)=>
        y = -j + middle
        x = i - middle
        if not @_map[y]
          @_map[y] = {}
        @_map[y][x] = call(cell, x, y)
    setTimeout =>
      @trigger 'animation_end'
    , 10

  remove_controls: ->
    @_mirror.forEach (m)-> m._controls_remove()

  remove: ->
    super
    if @_source
      @_source.remove()
    if @_target
      @_target.remove()
    @_blank.forEach (ob)-> ob.remove()
    @_mirror.forEach (ob)-> ob.remove()
    @clear()

  render: ->
    if @_before_render_fn.length > 0
      @_before_render_fn.pop()()
    (=>
      for name, params of @_animations
        if params.length is 0
          delete @_animations[name]
          continue
        params[0].steps--
        params[0].callback((params[0].steps_total - params[0].steps)/params[0].steps_total, params[0].steps)
        if params[0].steps is 0
          @_animations[name].shift()
    )()

  position_check: ->
    @_mirror.forEach (m)=>
      for i in [0..3]
        nr = (m._move_position + i) % 4
        p = m.get_move_position(nr, true)
        if @_map[p.y] and @_map[p.y][p.x] and @_map[p.y][p.x]._switch
          m.set_move_position(nr)
          return
      m.set_move_position(null)

  beam_source: (coors)->
    @_source = new window.o.ObjectBeamSource({position: [coors[0] * 10, coors[1] * 10, -0.55 * 4.2]})
    @_source

  target: (coors)->
    @_target = new window.o.ObjectBeamTarget({position: [coors[0] * 10, coors[1] * 10, -0.55 * 4.2]})
    @_target

  blank: (coors)-> new window.o.ObjectBlank({pos: coors})

  mirror_reverse: (coors)-> @mirror(coors, true)

  mirror: (coors, reverse=false)->
    m = new window.o.ObjectMirror({pos: [coors[0], coors[1]], reverse: reverse})
    position = [m.mesh.position.x, m.mesh.position.y]
    m.bind 'move', (position)=>
      @trigger 'rotate'
      blank = @_map[m.position.y + position.y][m.position.x + position.x]
      @_map[m.position.y][m.position.x] = blank
      @_map[m.position.y + position.y][m.position.x + position.x] = m
      blank.move({x: -position.x, y: -position.y})
      m.move(position)
    @_mirror.push m
    m
