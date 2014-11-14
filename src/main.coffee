


############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
#...........................................................................................................
TEXT                      = require 'coffeenode-text'
TYPES                     = require 'coffeenode-types'
# BNP                       = require 'coffeenode-bitsnpieces'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'TYPESETTER'
# log                       = TRM.get_logger 'plain',   badge
info                      = TRM.get_logger 'info',    badge
alert                     = TRM.get_logger 'alert',   badge
debug                     = TRM.get_logger 'debug',   badge
warn                      = TRM.get_logger 'warn',    badge
urge                      = TRM.get_logger 'urge',    badge
whisper                   = TRM.get_logger 'whisper', badge
help                      = TRM.get_logger 'help',    badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
RMY                       = require 'remarkably'
Htmlparser                = ( require 'htmlparser2' ).Parser
# XNCHR                     = require './XNCHR'
XNCHR                     = require './XNCHR'
#...........................................................................................................
P1                        = require 'pipedreams'
# options                   = require '../options'
#...........................................................................................................
verbose                   = yes
verbose                   = no


#-----------------------------------------------------------------------------------------------------------
@new_document = ( settings ) ->
  R =
    keep_x_grid:      no
    cells:            []
    cells_per_line:   8
    lines_per_page:   6
    idx:              0 # next glyph position
    size:             1
    # auto_space_chr:   '\u3000'
    auto_space_chr:   '＊'
  return R

#-----------------------------------------------------------------------------------------------------------
@new_observable_document = ( settings, handler ) ->
  require 'harmony-reflect'
  #.........................................................................................................
  switch arity = arguments.length
    when 1 then [ settings, handler, ] = [ null, settings ]
    when 2 then null
    else throw new Error "expect 2 arguments, got #{arity}"
  #.........................................................................................................
  get_observer = ( observee_name ) ->
    S =
      #.....................................................................................................
      get: ( target, name ) ->
        handler observee_name, 'get', target, name
        return target[ name ]
      #.....................................................................................................
      set: ( target, name, value ) ->
        handler observee_name, 'set', target, name, value
        return target[ name ] = value
    return S
  #.........................................................................................................
  R             = @new_document settings
  R[ 'cells' ]  = Proxy R[ 'cells' ], get_observer 'cells'
  return Proxy R, get_observer 'doc'

#-----------------------------------------------------------------------------------------------------------
@_get = ( me, pos, fallback ) ->
  idx = @idx_from_pos me, pos
  R = me[ 'cells' ][ idx ]
  if R is undefined
    return fallback if arguments.length > 2
    throw new Error "position #{@_rpr_pos me, pos} out of bounds"
  return R

#-----------------------------------------------------------------------------------------------------------
@_set = ( me, pos, content ) ->
  idx         = @idx_from_pos me, pos
  xy          = @xy_from_pos  me, pos
  { size, }   = me
  @_validate_xy me, xy, size
  me[ 'cells' ][ idx ] = content
  return me

#-----------------------------------------------------------------------------------------------------------
@put = ( me, content ) ->
  { idx, } = me
  @_set me, idx, content
  @advance_chr me

#-----------------------------------------------------------------------------------------------------------
@_put_auto_space = ( me ) ->
  idx = me[ 'idx' ] += 1
  me[ 'cells' ][ idx ] = me[ 'auto_space_chr' ]
  return me

#-----------------------------------------------------------------------------------------------------------
@advance_chr = ( me ) ->
  debug '### TAINT advance_chr simplified ###'
  { size }      = me
  if size is 1
    me[ 'idx' ] += 1
  else
    me[ 'size' ] = 1
    loop
      line_too_short  = ( @_get_remaining_line_length me ) < 1
      wrong_grid_line = ( ( @_get_y me ) %% size ) != 0
      debug '©4r1', line_too_short, wrong_grid_line, me
      break if ( not line_too_short ) and ( not wrong_grid_line )
      # me.observe 'advance_chr', if me.observe?
      @_put_auto_space me
    me[ 'size' ] = size
  return me

###
#===========================================================================================================



 .d8888b.   .d88888b.  888b     d888 8888888b.  8888888b.  8888888888  .d8888b.   .d8888b.
d88P  Y88b d88P" "Y88b 8888b   d8888 888   Y88b 888   Y88b 888        d88P  Y88b d88P  Y88b
888    888 888     888 88888b.d88888 888    888 888    888 888        Y88b.      Y88b.
888        888     888 888Y88888P888 888   d88P 888   d88P 8888888     "Y888b.    "Y888b.
888        888     888 888 Y888P 888 8888888P"  8888888P"  888            "Y88b.     "Y88b.
888    888 888     888 888  Y8P  888 888        888 T88b   888              "888       "888
Y88b  d88P Y88b. .d88P 888   "   888 888        888  T88b  888        Y88b  d88P Y88b  d88P
 "Y8888P"   "Y88888P"  888       888 888        888   T88b 8888888888  "Y8888P"   "Y8888P"


#===========================================================================================================
###

#-----------------------------------------------------------------------------------------------------------
@set_size = ( me, size ) ->
  throw new Error "unsupported size #{rpr size}" unless size in [ 1, 2, 3, 4, ]
  me[ 'size' ] = size
  return me

#-----------------------------------------------------------------------------------------------------------
@compress = ( me ) ->
  { size, idx, }  = me
  throw new Error "unsupported size #{rpr size} for compress" unless size > 1
  [ _, y, ]       = @xy_from_idx  me, idx
  [ y0, y1, ]     = @_get_grid_line_ys me, y, size
  debug "compressing lines #{y0} .. #{y1}"
  return me


###
#===========================================================================================================



 .d8888b.   .d88888b.   .d88888b.  8888888b.  8888888b.  8888888 888b    888        d8888 88888888888 8888888888  .d8888b.
d88P  Y88b d88P" "Y88b d88P" "Y88b 888   Y88b 888  "Y88b   888   8888b   888       d88888     888     888        d88P  Y88b
888    888 888     888 888     888 888    888 888    888   888   88888b  888      d88P888     888     888        Y88b.
888        888     888 888     888 888   d88P 888    888   888   888Y88b 888     d88P 888     888     8888888     "Y888b.
888        888     888 888     888 8888888P"  888    888   888   888 Y88b888    d88P  888     888     888            "Y88b.
888    888 888     888 888     888 888 T88b   888    888   888   888  Y88888   d88P   888     888     888              "888
Y88b  d88P Y88b. .d88P Y88b. .d88P 888  T88b  888  .d88P   888   888   Y8888  d8888888888     888     888        Y88b  d88P
 "Y8888P"   "Y88888P"   "Y88888P"  888   T88b 8888888P"  8888888 888    Y888 d88P     888     888     8888888888  "Y8888P"



#===========================================================================================================
###

#-----------------------------------------------------------------------------------------------------------
@idx_from_xy = ( me, xy, allow_wrap = no ) ->
  throw new Error "wrapping not implemented" if allow_wrap
  { cells_per_line,
    lines_per_page, } = me
  [ x, y, ]           = xy
  throw Error "illegal x #{rpr x}" unless x < cells_per_line
  return y * cells_per_line + x

#-----------------------------------------------------------------------------------------------------------
@xy_from_idx = ( me, idx ) ->
  { cells_per_line,
    lines_per_page, } = me
  return [ idx %% cells_per_line, idx // cells_per_line, ]

#-----------------------------------------------------------------------------------------------------------
@idx_from_pos = ( me, pos ) ->
  return pos if TYPES.isa_number pos
  return @idx_from_xy me, pos

#-----------------------------------------------------------------------------------------------------------
@xy_from_pos = ( me, pos ) ->
  return pos if TYPES.isa_list pos
  return @xy_from_idx me, pos

#-----------------------------------------------------------------------------------------------------------
@get_next_idx = ( me ) ->
  return me[ 'cells' ].length

#-----------------------------------------------------------------------------------------------------------
@get_next_xy = ( me, pos ) ->
  return @xy_from_idx me, @get_next_idx me

#-----------------------------------------------------------------------------------------------------------
@_validate_xy = ( me, xy, size ) ->
  { keep_x_grid, }  = me
  [ x, y, ]         = xy
  if keep_x_grid and size > 1
    throw new Error "#{@_rpr_xy me, xy} not within x grid size #{size}" unless x %% size is 0
  throw new Error "#{@_rpr_xy me, xy} not within y grid size #{size}" unless y %% size is 0
  old_content = me[ 'cells' ][ @idx_from_xy me, xy ]
  unless old_content is undefined
    throw new Error "cannot overwrite #{@_rpr_xy me, xy} #{rpr old_content}"
  return me

#-----------------------------------------------------------------------------------------------------------
@_rpr_pos   = ( me, pos  ) -> if TYPES.isa_number pos then @_rpr_idx me, pos else @_rpr_xy me, pos
@_rpr_xy    = ( me, xy   ) -> "@( #{xy[ 0 ]}, #{xy[ 1 ]} )"
@_rpr_idx   = ( me, idx  ) -> @_rpr_xy me, @xy_from_pos me, idx

#-----------------------------------------------------------------------------------------------------------
@_get_idx   = ( me ) -> me[ 'idx' ]
@_get_xy    = ( me ) -> @xy_from_idx me, me[ 'idx' ]
@_get_x     = ( me ) -> ( @_get_xy me )[ 0 ]
@_get_y     = ( me ) -> ( @_get_xy me )[ 1 ]


###
#===========================================================================================================



888    888 8888888888 888      8888888b.  8888888888 8888888b.   .d8888b.
888    888 888        888      888   Y88b 888        888   Y88b d88P  Y88b
888    888 888        888      888    888 888        888    888 Y88b.
8888888888 8888888    888      888   d88P 8888888    888   d88P  "Y888b.
888    888 888        888      8888888P"  888        8888888P"      "Y88b.
888    888 888        888      888        888        888 T88b         "888
888    888 888        888      888        888        888  T88b  Y88b  d88P
888    888 8888888888 88888888 888        8888888888 888   T88b  "Y8888P"



#===========================================================================================================
###
# @_next_odd_int  = ( n ) -> ( ( n // 2 ) * 2 ) + 1
# @_is_even       = ( n ) -> n / 2 is Math.floor n / 2

#-----------------------------------------------------------------------------------------------------------
@_get_grid_line_ys       = ( me, n, module ) ->
  y0 = ( n // module ) * module
  return [ y0, y0 + module - 1, ]

#-----------------------------------------------------------------------------------------------------------
@_rpr_cell = ( me, cell ) ->
  return '\u3000' if cell is undefined
  return '〼'     if cell is null
  return cell     if TYPES.isa_text cell
  return rpr cell

#-----------------------------------------------------------------------------------------------------------
@_get_remaining_line_length = ( me ) ->
  return ( me[ 'cells_per_line' ] - @_get_x me ) // me[ 'size' ]


############################################################################################################
unless module.parent?
  @serve()


