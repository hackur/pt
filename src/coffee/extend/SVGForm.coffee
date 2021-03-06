class SVGForm

  @_domId = 0

  # ## Create a new Form which is based on SVG
  # @param `space` A space that has a valid context for this form. In this case, the space should represent an html canvas.
  # @return a new Form object
  constructor: ( space ) ->

    # ## a property to reference the space's rendering context
    @cc = space.ctx || {}

    # keep track of dom id names
    @cc.group = @cc.group || null
    @cc.groupID = "ptx"
    @cc.groupCount = 0
    @cc.currentID = "ptx0"

    # default style or false for no fill
    @cc.style = {
      fill: "#999"
      stroke: "#666"
      "stroke-width": 1
      "stroke-linejoin": false
      "stroke-linecap": false
    }
    @cc.font = "11px sans-serif"

    # ## a property to specify the current font size
    @cc.fontSize = 11

    # ## a property to specify the current font face
    @cc.fontFace = "sans-serif"


  # ## Set current fill style
  # @param `c` fill color which can be as color, gradient, or pattern. (See [canvas documentation](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/fillStyle)) Default is `false` (transparent)
  # @eg `form.fill("#F90")` `form.fill("rgba(0,0,0,.5")` `form.fill(false)`
  # @return this Form
  fill: (c) ->
    @cc.style.fill = if c then c else false
    return @


  # ## Set current stroke style
  # @param `c` stroke color which can be as color, gradient, or pattern. (See [canvas documentation](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/strokeStyle)) Default is false (transparent)
  # @param `width` Optional value (can be floating point) to set line width
  # @param `joint` Optional string to set line joint style. Can be "miter", "bevel", or "round".
  # @eg `form.stroke("#F90")` `form.stroke("rgba(0,0,0,.5")` `form.stroke(false)` `form.stroke("#000", 0.5, 'round')`
  # @return this Form
  stroke: (c, width, joint, cap) ->
    @cc.style.stroke = if c then c else false
    if width then @cc.style["stroke-width"] = width
    if joint then @cc.style["stroke-linejoin"] = joint
    if cap then @cc.style["stroke-linecap"] = joint
    return @


  # ## Set the current group scope by an ID, and optionally define the group's parent element
  # @param `group_id` a string to use as prefix for the group's id. For example, group_id "hello" will create elements with id like "hello-1", "hello-2", etc
  # @param `group` optional dom element to define this group's parent element
  # @eg `form.scope("dot")` `form.scope("dot", elem)`
  # @demo svgform.scope
  # @return context object
  scope: ( group_id, group=false ) ->
    if (group) then @cc.group = group
    @cc.groupID = group_id
    @cc.groupCount = 0

    @nextID()
    return @cc


  # ## Set the current group scope based on an item added to Space. The item must have an `animateID` property. Its group id will become "item-##".
  # @param `item` an item that's added to space.
  # @return context object
  getScope: ( item ) ->
    if (!item || item.animateID == null )
      throw "getScope()'s item must be added to a Space, and has an animateID property. Otherwise, use scope() instead."
    return @scope( SVGForm._scopeID( item ) )


  # ## Get next available id in the current group
  # @return an id string
  nextID: () ->
    @cc.groupCount++
    @cc.currentID = @cc.groupID+"-"+@cc.groupCount
    return @cc.currentID


  # ## A static function to context
  @id: (ctx) ->
    return ctx.currentID || "p-"+SVGForm._domId++


  # compose a scope id
  @_scopeID: (item) ->
    return "item"+item.animateID

  # ## A static function to help adding style object to an element. This put all styles into `style` attribute instead of individual attributes, so that the styles can be parsed by Adobe Illustrator.
  # @param `elem` a dom element to add to
  # @param `styles` an object of style properties
  # @eg `SVGForm.style(elem, {fill: "#f90", stroke: false})`
  @style: (elem, styles) ->
    st = []

    for k,v of styles
      if (!v)
        if (k=="fill")
          st.push( "fill: none" )
        else if (k=="stroke")
          st.push( "stroke: none" )
      else
        st.push( k+":"+v )

    return DOMSpace.attr( elem, {style: st.join(";")} )


  # ## A static function to draw a point
  # @param `ctx` canvas rendering context
  # @param `pt` a Point object
  # @param `halfsize` radius or half size of the point. Default is 2.
  # @param `fill` not used - already defined in ctx
  # @param `stroke` not used - already defined in ctx
  # @param `circle` a boolean value to specify if the points should be drawn as a circle. Default to false.
  @point: (ctx, pt, halfsize=2, fill=true, stroke=true, circle=false ) ->

    elem = SVGSpace.svgElement( ctx.group, (if (circle) then "circle" else "rect"), SVGForm.id(ctx) )
    if (!elem) then return;

    if (circle)
      DOMSpace.attr( elem, {
        cx: pt.x
        cy: pt.y
        r: halfsize
      })
    else
      DOMSpace.attr( elem, {
        x: pt.x - halfsize
        y: pt.y - halfsize
        width: halfsize + halfsize
        height: halfsize + halfsize
      })

    SVGForm.style(elem, ctx.style)
    return elem


  # ## Draw a point
  # @param `p` a Point object
  # @param `halfsize` radius or half size of the point. Default is 2.
  # @param `isCircle` a boolean value to specify if the point should be drawn as a circle. Default is false.
  # @return this Form
  point: (p, halfsize=2, isCircle=false) ->
    @nextID()
    SVGForm.point(@cc, p, halfsize, true, true, isCircle )
    return @


  # ## A static function similar to `SVGForm.point()` but draw a series of points
  # @param `ctx` canvas rendering context
  # @param `pts` an array of Points
  # @param `halfsize, fill, stroke, circle` same parameters as in `SVGForm.point()`
  @points: (ctx, pts, halfsize=2, fill=true, stroke=true, circle=false ) ->
    return (SVGForm.point( ctx, p, halfsize, fill, stroke, circle ) for p in pts)


  # ## Draw a series of points
  # @param `ps` an array of Points
  # @param `halfsize` radius or half size of the point. Default is 2.
  # @param `isCircle` a boolean value to specify if the point should be drawn as a circle. Default is false.
  # @return this Form
  points: (ps, halfsize=2, isCircle=false) ->
    for p in ps
      @point(p, halfsize, isCircle )
    return @


  # ## A static function to draw a line
  # @param `ctx` canvas rendering context
  # @param `pair` a Pair object
  @line: (ctx, pair) ->
    if !pair.p1 then throw "#{pair.toString()} is not a Pair"
    elem = SVGSpace.svgElement( ctx.group, "line", SVGForm.id(ctx) )

    DOMSpace.attr( elem, {
      x1: pair.x
      y1: pair.y
      x2: pair.p1.x
      y2: pair.p1.y
    })

    SVGForm.style(elem, ctx.style)
    return elem


  # ## Draw a line
  # @param `p` a Pair object
  # @return this Form
  line: (p) ->
    @nextID()
    SVGForm.line( @cc, p )
    return @


  # ## A static function to draw a line
  # @param `ctx` canvas rendering context
  # @param `pairs` an array of Pair objects
  @lines: (ctx, pairs) ->
    return ( SVGForm.line( ctx, ln ) for ln in pairs )


  # ## Draw a series of lines
  # @param `ps` an array of Lines
  # @return this Form
  lines: (ps) ->
    for p in ps
      @line(p)
    return @


  # ## A static function to draw a rectangle
  # @param `ctx` canvas rendering context
  # @param `pair` a Pair object
  # @param `fill` not used - already defined in ctx
  # @param `stroke` not used - already defined in ctx
  @rect: (ctx, pair, fill=true, stroke=true) ->
    if !pair.p1 then throw "#{pair.toString() is not a Pair}"
    elem = SVGSpace.svgElement( ctx.group, "rect", SVGForm.id(ctx) )

    size = pair.size()
    DOMSpace.attr( elem, {
      x: pair.x
      y: pair.y
      width: size.x
      height: size.y
    })

    SVGForm.style(elem, ctx.style)
    return elem


  # ## Draw a rectangle
  # @param `p` a Pair object
  # @return this Form
  rect: (p, checkBounds=true) ->
    @nextID()
    r = if (checkBounds) then p.bounds() else p
    SVGForm.rect( @cc, r )
    return @


  # ## A static  function to draw a circle
  # @param `ctx` canvas rendering context
  # @param `c` a Circle object
  # @param `fill` not used - already defined in ctx
  # @param `stroke` not used - already defined in ctx
  @circle: (ctx, c, fill=true, stroke=false) ->

    elem = SVGSpace.svgElement( ctx.group, "circle", SVGForm.id(ctx) )
    if (!elem) then return

    DOMSpace.attr( elem, {
      cx: c.x
      cy: c.y
      r: c.radius
    })

    SVGForm.style(elem, ctx.style)
    return elem


  # ## Draw a circle
  # @param `c` a Circle object
  # @demo svgform.circle
  # @return this Form
  circle: (c) ->
    @nextID()
    SVGForm.circle( @cc, c )
    return @



  # ## A static function to draw a polygon
  # @param `ctx` canvas rendering context
  # @param `pts` an array of Points
  # @param `closePath` a boolean value to specify if the path should be closed (joining last point with first point)
  # @param `fill` not used - already defined in ctx
  # @param `stroke` not used - already defined in ctx
  @polygon: ( ctx, pts, closePath=true, fill=true, stroke=true) ->

    elem = SVGSpace.svgElement( ctx.group, (if (closePath) then "polygon" else "polyline"), SVGForm.id(ctx) )
    if (!elem) then return

    if pts.length <= 1 then return;

    points = ("#{pts[i].x},#{pts[i].y}" for i in [0...pts.length] by 1)
    DOMSpace.attr( elem, {
      points: points.join(" ")
    })

    SVGForm.style(elem, ctx.style)
    return elem


  # ## Draw a polygon
  # @param `ps` an array of Points
  # @param `closePath` a boolean value to specify if the path should be closed (joining last point with first point)
  # @return this Form
  polygon: (ps, closePath) ->
    @nextID()
    SVGForm.polygon( @cc, ps, closePath)
    return @

  # ## A static function to draw a triangle
  # @param `ctx` canvas rendering context
  # @param `tri` a Triangle object
  # @param `fill` not used - already defined in ctx
  # @param `stroke` not used - already defined in ctx
  @triangle: ( ctx, tri, fill=true, stroke=false) ->
    return SVGForm.polygon(ctx, tri.toArray() )


  # ## Draw a triangle
  # @param `tri` a Triangle object
  # @return this Form
  triangle: (tri) ->
    @nextID()
    SVGForm.triangle( @cc, tri )
    return @


  # ## A static function to draw a curve as straight polygon segments. In future, this should be converted to bezier curves.
  # @param `ctx` canvas rendering context
  # @param `pts` an array of Points
  @curve: ( ctx, pts, closePath=false ) ->
    SVGForm.polygon( ctx, pts, closePath )


  # ## Draw a curve
  # @param `ps` an array of Points
  # @return this Form
  curve: (ps, closePath=false ) ->
    @nextID()
    SVGForm.curve( @cc, ps, closePath )
    return @


  # ## A static function to draw text
  # @param `ctx` canvas rendering context
  # @param `pt` a Point object to specify the anchor point
  # @param `txt` a string of text to draw
  # @param `maxWidth` not applicable in svg
  # @param `dx` optional shift in x position
  # @param `dy` optional shift in y position
  @text: ( ctx, pt, txt, maxWidth=0, dx=0, dy=0 ) ->
    elem = SVGSpace.svgElement( ctx.group, "text", SVGForm.id(ctx) )
    if (!elem) then return

    DOMSpace.attr( elem, {
      "pointer-events": "none",
      x: pt.x,
      y: pt.y,
      dx: 0,
      dy: 0
    })

    elem.textContent = txt

    SVGForm.style(elem, {
      fill: ctx.style.fill
      stroke: ctx.style.stroke
      "font-family": ctx.fontFace or false
      "font-size": ctx.fontSize or false
    })
    return elem


  # ## Draw text
  # @param `p` a Point to specify anchor position
  # @param `txt` a string of text
  # @param `maxWidth` not applicable in svg
  # @param `xoff, yoff` x and y positional offset values
  text: (p, txt, maxWidth=1000, xoff, yoff) ->
    @nextID()
    SVGForm.text( @cc, p, txt, maxWidth, xoff, yoff)
    return @



  # ## Set font size and font face
  # @param `size` an integer value to specify font size in pixels
  # @param `face` optional name to change the font face, such as "sans-serif" or "Helvetica"
  # @eg `form.font(24)` `form.font(12, "Georgia")`
  # @return this Form
  font: (size, face=false) ->
    @cc.fontFace = face
    @cc.fontSize = size
    @cc.font = "#{size}px #{face}"
    return @


  # ## Draw a shape. Defaults to `sketch()`. Override this function to draw differently.
  # @return this Form
  draw: ( shape ) ->
    @sketch( shape )


  # ## Default draw based on the types of shape (Point, Line, Circle, etc)
  # @param `shape` any shape such as `Point` or `Line`, or an array of Points
  # @return this Form
  sketch: ( shape ) ->
    shape.floor()

    if shape instanceof Circle
      SVGForm.circle(@cc, shape, @filled, @stroked)

    else if shape instanceof Rectangle
      SVGForm.rect( @cc, shape, @filled, @stroked)

    else if shape instanceof Triangle
      SVGForm.triangle( @cc, shape, @filled, @stroked)

    else if shape instanceof Line or shape instanceof Pair
      SVGForm.line(@cc, shape)

    else if shape instanceof PointSet
      SVGForm.polygon(@cc, shape.points )

    else if shape instanceof Vector or shape instanceof Point
      SVGForm.point(@cc, shape)


    return @


# namespace
this.SVGForm = SVGForm