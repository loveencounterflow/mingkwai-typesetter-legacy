


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
  colors[ 'red'       ] = settings?[ 'colors' ]?[ 'red'    ] ? '#86000b'
  colors[ 'blue'      ] = settings?[ 'colors' ]?[ 'blue'   ] ? '#21247b'
  colors[ 'black'     ] = settings?[ 'colors' ]?[ 'black'  ] ? '#000000'
  substrate     = GM ( @px_from_mm R, R[ 'width' ] ), ( @px_from_mm R, R[ 'height' ] ), '#ffffffff'
  R[ '%self' ]  = substrate
  return R

#-----------------------------------------------------------------------------------------------------------
@px_from_mm = ( me, d_mm )            -> d_mm * me[ 'px-per-mm' ]
@fill       = ( me, color         ) -> me[ '%self' ].fill   ( @get_color me, color )
@stroke     = ( me, color, width  ) -> me[ '%self' ].stroke ( @get_color me, color ), @px_from_mm me, width
@get_color  = ( me, color         ) -> me[ 'colors' ]?[ color ] ? color

#-----------------------------------------------------------------------------------------------------------
@write = ( me, handler  ) ->
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
  return me

#-----------------------------------------------------------------------------------------------------------
@main = ( route, handler ) ->
  PLOTTER   = @
  img       = PLOTTER.new_image null, route
  xy0       = [ 0, 0, ]
  xy1       = [ 243, 183 - 5, ]
  # img = GM options[ 'width.px' ], options[ 'height.px' ], "#ffffffff"
    # .fontSize 68
    # .fill 'transparent'
    # .stroke red, 3
  PLOTTER.fill    img, 'transparent'
  PLOTTER.stroke  img, 'red', 0.225
  PLOTTER.line    img, xy0, xy1
  # debug img
  #.........................................................................................................
  PLOTTER.write img, handler
  info img[ 'tex' ]
  return null


############################################################################################################
unless module.parent?
  @main null, ( error ) ->
    throw error if error?
    help 'ok'


