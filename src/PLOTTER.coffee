


############################################################################################################
# njs_util                  = require 'util'
njs_fs                    = require 'fs'
njs_path                  = require 'path'
#...........................................................................................................
# BAP                       = require 'coffeenode-bitsnpieces'
TYPES                     = require 'coffeenode-types'
TRM                       = require 'coffeenode-trm'
# FS                        = require 'coffeenode-fs'
rpr                       = TRM.rpr.bind TRM
badge                     = 'MINGKWAI/TYPESETTER'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
GM                        = require 'gm'
# FI                        = require 'coffeenode-fillin'
TEMP                      = ( require 'temp' ).track()


#-----------------------------------------------------------------------------------------------------------
options =
  'px-per-mm':        15
  'width':            243
  'height':           183 - 5
  'colors':
    'red':      '86000b'
    'blue':     '21247b'
    'black':    '000000'

#-----------------------------------------------------------------------------------------------------------
@new_image = ( settings, route ) ->
  R                     = '~isa': 'MINGKWAI/PLOTTER/image'
  R[ 'route'          ] = route ? settings?[ 'route' ] ? TEMP.path { suffix: '.png'}
  R[ 'px-per-mm'      ] = settings?[ 'px-per-mm'      ] ? 15
  R[ 'width'          ] = settings?[ 'width'          ] ? 297 - 29 - 25
  R[ 'height'         ] = settings?[ 'height'         ] ? 210 - 11 - 12 - 5
  R[ 'colors'         ] = colors = []
  R[ 'tex'            ] = "\\includegraphics[width=#{R[ 'width' ]}mm]{#{R[ 'route' ]}}"
  #.........................................................................................................
  R[ 'stack'          ] = []
  R[ 'fill-color'     ] = null
  R[ 'line-color'     ] = null
  R[ 'line-width'     ] = null
  R[ 'line-caps'      ] = 'round'
  #.........................................................................................................
  colors[ 'red'       ] = settings?[ 'colors' ]?[ 'red'    ] ? '#86000b'
  colors[ 'blue'      ] = settings?[ 'colors' ]?[ 'blue'   ] ? '#21247b'
  colors[ 'black'     ] = settings?[ 'colors' ]?[ 'black'  ] ? '#000000'
  substrate             = GM ( @px_from_mm R, R[ 'width' ] ), ( @px_from_mm R, R[ 'height' ] ), '#ffffff00'
  substrate.options { imageMagick: true, }
  R[ '%self' ]          = substrate
  return R

#-----------------------------------------------------------------------------------------------------------
@push_style = ( me ) ->
  style = {}
  for name in [ 'fill-color', 'line-color', 'line-width', 'line-caps', ]
    style[ name ] = me[ name ]
  me[ 'stack' ].push style
  return me

#-----------------------------------------------------------------------------------------------------------
@pop_style = ( me ) ->
  style = me[ 'stack' ].pop()
  @fill   me, style[ 'fill-color' ]
  @stroke me, style[ 'line-color' ], style[ 'line-width' ], style[ 'line-caps'  ]
  return me

#-----------------------------------------------------------------------------------------------------------
@px_from_mm = ( me, d_mm ) ->
  return d_mm * me[ 'px-per-mm' ]

#-----------------------------------------------------------------------------------------------------------
@fill = ( me, color ) ->
  me[ 'fill-color' ] = color
  me[ '%self' ].fill ( @get_color me, color )
  return me

#-----------------------------------------------------------------------------------------------------------
@stroke = ( me, color, width = 1, line_caps = 'round' ) ->
  me[ 'line-color' ] = color
  me[ 'line-width' ] = width
  me[ 'line-caps'  ] = line_caps
  me[ '%self' ].stroke ( @get_color me, color ), ( @px_from_mm me, width )
  return me

#-----------------------------------------------------------------------------------------------------------
@print = ( me, xy, text ) ->
  me[ '%self' ].font 'Helvetica'
  me[ '%self' ].fontSize me[ 'px-per-mm' ] * 3
  me[ '%self' ].drawText xy[ 0 ], xy[ 1 ], text
  return me

#-----------------------------------------------------------------------------------------------------------
@move_xys = ( me, xys..., d_xy ) ->
  arity = xys.length + if d_xy? then 1 else 0
  throw new Error "expected at least 2 arguments, got #{arity}" unless arity >= 2
  for xy in xys
    xy[ 0 ] += d_xy[ 0 ]
    xy[ 1 ] += d_xy[ 1 ]
  return me

#-----------------------------------------------------------------------------------------------------------
@get_color = ( me, color ) ->
  return me[ 'colors' ]?[ color ] ? color

#-----------------------------------------------------------------------------------------------------------
@write_file = ( me, handler  ) ->
  # switch arity = arguments.length
  #   when 2
  #     handler = route
  #     route   = null
  me[ '%self' ].write me[ 'route' ], handler


#-----------------------------------------------------------------------------------------------------------
@line = ( me, xy0, xy1 ) ->
  x0 = @px_from_mm me, xy0[ 0 ]
  y0 = @px_from_mm me, xy0[ 1 ]
  x1 = @px_from_mm me, xy1[ 0 ]
  y1 = @px_from_mm me, xy1[ 1 ]
  me[ '%self' ].drawLine x0, y0, x1, y1
  switch style = me[ 'line-caps' ]
    when 'round'
      @push_style me
      radius    = me[ 'line-width' ] / 2
      @fill       me, me[ 'line-color' ]
      @stroke     me, 'transparent', 0
      # debug '©CwCj1', me[ 'stack' ]
      # debug '©CwCj1', me[ 'fill-color' ], me[ 'line-color' ]
      @circle     me, xy0, radius
      @circle     me, xy1, radius
      @pop_style  me
    else
      throw new Error "unknown line-caps style #{rpr style}"
  return me

#-----------------------------------------------------------------------------------------------------------
@circle = ( me, xy0, r ) ->
  x0 = @px_from_mm me, xy0[ 0 ]
  y0 = @px_from_mm me, xy0[ 1 ]
  x1 = x0 + @px_from_mm me, r
  y1 = y0
  me[ '%self' ].drawCircle x0, y0, x1, y1
  return me

#-----------------------------------------------------------------------------------------------------------
@main = ( route, handler ) ->
  PLOTTER   = @
  settings  = null # imageMagick: true
  img       = PLOTTER.new_image settings, route
  xy0       = [ 10, 10, ]
  xy1       = [ 24, 18, ]
  # img = GM options[ 'width.px' ], options[ 'height.px' ], "#ffffffff"
    # .fontSize 68
    # .fill 'transparent'
    # .stroke red, 3
  substrate = img[ '%self' ]
  PLOTTER.fill    img, 'white'
  PLOTTER.fill    img, 'transparent'
  PLOTTER.stroke  img, 'red', 5
  PLOTTER.line    img, xy0, xy1
  PLOTTER.line    img, [ 20, 20, ], [ 30, 30, ]
  # PLOTTER.circle  img, xy0, xy1
  #.........................................................................................................
  PLOTTER.write_file img, handler
  info img[ 'tex' ]
  return null


############################################################################################################
unless module.parent?
  # @main null, ( error ) ->
  @main '/tmp/img.png', ( error ) ->
    throw error if error?
    help 'ok'


