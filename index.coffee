_ = require 'lodash'
{Transform} = require 'stream'

class Gcode extends Transform
  moveZ: 0.1 # default 0.1 in

  drillZ: -0.1 # default -0.1 in

  tool:
    '0': 'empty'

  constructor: (opts={}) ->
    super _.defaults opts, writableObjectMode: true
    {moveZ, drillZ} = opts
    if moveZ?
      @moveZ = moveZ
    if drillZ
      @drillZ = drillZ

  setUnits: ({value}) ->
    """
      (set units #{value})
      #{if value == 'in' then 'G20' else 'G21'}
    """
 
  setTool: ({value}) ->
    "(setTool #{JSON.stringify @tool[value]})"
    
  set: ({prop}) ->
    switch prop
      when 'tool'
        @setTool arguments[0]
      when 'units'
        @setUnits arguments[0]
      
  addTool: ({code, tool})->
    @tool[code] = tool
    "(addTool #{JSON.stringify tool})"

  op: ({op, coord}) ->
    {x, y} = coord
    """
      M03
      G0F3Z#{@moveZ}
      G1F100X#{x}Y#{y}
      G0F3Z#{@drillZ}
      M05
    """

  _transform: (chunk, encoding, cb) ->
    {type, line, prop, value, code, tool, op, coord} = chunk
    ret = switch type
      when 'set'
        @set chunk
      when 'tool'
        @addTool chunk
      when 'op'
        @op chunk
      else
        "(#{type})"
    @push "#{ret}\n", 'ascii'
    cb()

gerberParser = require 'gerber-parser'
parser = gerberParser filetype: 'drill'

process.stdin
  .pipe parser
#  .on 'data', (chunk) ->
#    console.log chunk
  .pipe new Gcode()
  .pipe process.stdout
