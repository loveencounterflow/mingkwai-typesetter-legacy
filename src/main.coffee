


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
XNCHR                     = require '/Volumes/Storage/cnd/node_modules/jizura-datasources/src/XNCHR.coffee'
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
    # xy:               [ 0, 0, ]
    idx:              0
    size:             1
  return R

#-----------------------------------------------------------------------------------------------------------
@_get = ( me, pos, fallback ) ->
  idx = @idx_from_pos me, pos
  R = me[ 'cells' ][ idx ]
  if R is undefined
    return fallback if arguments.length > 2
    throw new Error "position #{@_rpr_pos pos} out of bounds"
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
@advance_chr = ( me ) ->
  debug '### TAINT advance_chr simplified ###'
  me[ 'idx' ] += 1
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
@get_last_idx = ( me ) ->
  return me[ 'cells' ].length - 1

#-----------------------------------------------------------------------------------------------------------
@get_last_xy = ( me, pos ) ->
  return @xy_from_idx me, @get_last_idx me

#-----------------------------------------------------------------------------------------------------------
@_validate_xy = ( me, xy, size ) ->
  { keep_x_grid, }  = me
  [ x, y, ]         = xy
  if keep_x_grid and size > 1
    throw new Error "#{@_rpr_xy xy} not within x grid size #{size}" unless x % size is 0
  throw new Error "#{@_rpr_xy xy} not within y grid size #{size}" unless y % size is 0
  old_content = me[ 'cells' ][ @idx_from_xy me, xy ]
  unless old_content is undefined
    throw new Error "cannot overwrite #{rpr old_content} with #{rpr content} #{@_rpr_xy xy}"
  return me

#-----------------------------------------------------------------------------------------------------------
@_rpr_pos   = ( pos  ) -> if TYPES.isa_number pos then @_rpr_idx pos else @_rpr_xy pos
@_rpr_xy    = ( xy   ) -> "@( #{xy[ 0 ]}, #{xy[ 0 ]} )"
@_rpr_idx   = ( idx  ) -> @_rpr_xy @xy_from_pos idx


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

#-----------------------------------------------------------------------------------------------------------
@_is_even       = ( n ) -> n / 2 is Math.floor n / 2
@_next_odd_int  = ( n ) -> ( ( n // 2 ) * 2 ) + 1



###
#===========================================================================================================



 .d8888b.  8888888888 8888888b.  888     888 8888888888 8888888b.
d88P  Y88b 888        888   Y88b 888     888 888        888   Y88b
Y88b.      888        888    888 888     888 888        888    888
 "Y888b.   8888888    888   d88P Y88b   d88P 8888888    888   d88P
    "Y88b. 888        8888888P"   Y88b d88P  888        8888888P"
      "888 888        888 T88b     Y88o88P   888        888 T88b
Y88b  d88P 888        888  T88b     Y888P    888        888  T88b
 "Y8888P"  8888888888 888   T88b     Y8P     8888888888 888   T88b



#===========================================================================================================
###



#-----------------------------------------------------------------------------------------------------------
@_rpr_cell = ( cell ) ->
  return '\u3000' if cell is undefined
  return '〼'     if cell is null
  return cell     if TYPES.isa_text cell
  return rpr cell

#-----------------------------------------------------------------------------------------------------------
@serve = ->
  express   = require 'express'
  #.........................................................................................................
  me        = @new_document()
  app       = express()
  #---------------------------------------------------------------------------------------------------------
  app.get "/", do =>
    chrs          = XNCHR.chrs_from_text '畢昇發明活字印刷術宋沈括著《夢溪筆談》卷十八記載'
    chr_idx       = 0
    last_chr_idx  = chrs.length - 1
    #.......................................................................................................
    return ( request, response ) =>
      @put me, if chr_idx <= last_chr_idx then chrs[ chr_idx ] else '〓'
      chr_idx  += 1
      [ x1, y1, ] = @get_last_xy me
      debug '©3q1', 'last xy:', [ x1, y1, ]
      response.write "<table border=1>\n"
      for y in [ 0 .. y1 ]
        response.write "<tr>"
        for x in [ 0 ... me[ 'cells_per_line' ] ]
          cell = @_rpr_cell @_get me, [ x, y, ], undefined
          response.write "<td>#{cell}</td>"
        response.write "</tr>\n"
      response.write "</table>\n"
      response.end()
  #---------------------------------------------------------------------------------------------------------
  server = app.listen 3000, ->
    host = server.address().address
    port = server.address().port
    help "明快排字机 listening at http://#{host}:#{port}"

############################################################################################################


#-----------------------------------------------------------------------------------------------------------
@get_cell_count_to_row_end = ( me, pos ) ->
  [ x, y, ] = @xy_from_pos me, pos
  return me[ 'cells_per_line' ] - ( x %% me[ 'cells_per_line' ] )

############################################################################################################
unless module.parent?
  # me    = @new_document()
  # debug @_get me, [ 1, 1, ], undefined
  @serve()



