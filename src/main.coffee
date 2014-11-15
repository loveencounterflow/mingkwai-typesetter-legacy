


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
    block_space_chr:  '＃'
    free_cell_chr:    '〇'
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
        value = target[ name ]
        handler observee_name, 'get', target, name
        return value
      #.....................................................................................................
      set: ( target, name, value ) ->
        target[ name ] = value
        handler observee_name, 'set', target, name, value
        return value
    return S
  #.........................................................................................................
  R             = @new_document settings
  # R[ 'cells' ]  = Proxy R[ 'cells' ], get_observer 'cells'
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
  ### TAINT `put` doesn't honor `size` ###
  { idx
    size
    cells
    block_space_chr }   = me
  [ x0, y0, ]           = @_get_xy me
  #.........................................................................................................
  @_set me, idx, content
  #.........................................................................................................
  for dx in [ 0 ... size ]
    for dy in [ 0 ... size ]
      continue if dx is dy is 0
      cells[ @idx_from_xy me, [ x0 + dx, y0 + dy, ] ] = block_space_chr
  #.........................................................................................................
  return @advance_chr me

### TAINT next two methods have a lot of duplicated code ###
#-----------------------------------------------------------------------------------------------------------
@advance_chr = ( me ) ->
  { size, cells, } = me
  #.........................................................................................................
  ### If character size is 1, we can simply advance to the next cell. Since it is not allowed to
    retroactively change cell contents, this should always put on a free cell. ###
  if size is 1
    loop
      me[ 'idx' ]  += 1
      cell_is_free  = cells[ me[ 'idx' ] ] is undefined
      break if cell_is_free
    return me
  #.........................................................................................................
  ### If character size `s` is greater than 1, we must advance to a position on a line that has both an
    integer multiple of `s` free cells left and that is a multiple integer (including 0) of `s` lines from
    the top. We go step by step, filling up blank cells with `auto_space_chr`. ###
  loop
    me[ 'idx' ]        += 1
    enough_free_cells   = ( @_get_remaining_line_length me ) >= 1
    on_grid_line        = ( ( @_get_y me ) %% size ) is 0
    cell_is_free        = cells[ me[ 'idx' ] ] is undefined
    break if enough_free_cells and on_grid_line and cell_is_free
    me[ 'cells' ][ me[ 'idx' ] ] = me[ 'auto_space_chr' ] if cell_is_free
  return me

#-----------------------------------------------------------------------------------------------------------
@advance_chr_if_necessary = ( me ) ->
  ### Like `advance_chr`, but assuming that an advance has just been taken place and we have too look
    whther the new position is suitable for a character of (a new) `size`. ###
  { size, cells, } = me
  #.........................................................................................................
  ### If character size is 1, we can simply stay where we are. ###
  if size is 1
    loop
      cell_is_free  = cells[ me[ 'idx' ] ] is undefined
      break if cell_is_free
      me[ 'idx' ]  += 1
    return me
  #.........................................................................................................
  ### If character size `s` is greater than 1, we must advance to a position on a line that has both an
    integer multiple of `s` free cells left and that is a multiple integer (including 0) of `s` lines from
    the top. We go step by step, filling up blank cells with `auto_space_chr`. ###
  # count = 0
  loop
    enough_free_cells   = ( @_get_remaining_line_length me ) >= 1
    on_grid_line        = ( ( @_get_y me ) %% size ) is 0
    cell_is_free        = cells[ me[ 'idx' ] ] is undefined
    # debug '©2a1', ( @_rpr_pos me, me[ 'idx' ] ), enough_free_cells, on_grid_line
    break if enough_free_cells and on_grid_line and cell_is_free
    me[ 'cells' ][ me[ 'idx' ] ] = me[ 'auto_space_chr' ] if cell_is_free
    me[ 'idx' ] += 1
    # count += 1; break if count > 10
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
  { size
    idx
    cells
    cells_per_line
    block_space_chr
    auto_space_chr  } = me
  throw new Error "unsupported size #{rpr size} for compress" if size is 1
  #.........................................................................................................
  ### Find top and bottom boundaries. ###
  [ x,  y,  ]         = @xy_from_idx  me, idx
  [ y0, y1, ]         = @_get_grid_line_ys me, y, size
  #.........................................................................................................
  ### Find left and right boundaries. ###
  ### If we're on the first line of the compressible region, we're already behind the last compressible
    position; if we're on any following line, the first line must be full, so `x1` is the line cellcount
    minus one: ###
  x1 = if y is y0 then Math.max 0, x - 1 else cells_per_line - 1
  #.........................................................................................................
  ### Since we don't support ragged left borders, all lines must start at the same index `x0`. ###
  x0 = x
  loop
    ### Walking leftwards until we're at the margin or see a blocking signal to the left: ###
    break if x0 is 0
    break if ( @_get me, [ x0 - 1, y0, ] ) is block_space_chr
    x0 -= 1
  #.........................................................................................................
  width               = x1 - x0 + 1
  height              = size
  chr_count           = ( Math.max 0, y - y0 - 1 ) * width + x
  blank_count         = chr_count %% height
  blank_count         = height - blank_count if blank_count > 0
  idx0                = @idx_from_xy me, [ x0, y0, ]
  tmp_cells_per_line  = ( chr_count + blank_count ) / height
  tmp_cells           = cells.splice idx0, chr_count
  me[ 'idx' ]         = idx0 + tmp_cells_per_line
  tmp_cells.push auto_space_chr for d in [ 0 ... blank_count ]
  #.........................................................................................................
  for tmp_cell, tmp_idx in tmp_cells
    [ dx, dy, ]   = @xy_from_idx null, tmp_idx, tmp_cells_per_line
    idx1          = @idx_from_xy me, [ x0 + dx, y0 + dy, ]
    cells[ idx1 ] = tmp_cell
  #.........................................................................................................
  # debug """
  #   compressing #{@_rpr_xy me, [ x0, y0, ]} .. #{@_rpr_xy me, [ x1, y1, ]}
  #   with #{chr_count} chrs and #{blank_count} blanks"""
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
@xy_from_idx = ( me, idx, cells_per_line ) ->
  cells_per_line ?= me[ 'cells_per_line' ]
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
  # return '\u3000' if cell is undefined
  # return '〼'     if cell is null
  return me[ 'free_cell_chr' ]  if cell is undefined
  return cell                   if TYPES.isa_text cell
  return rpr cell

#-----------------------------------------------------------------------------------------------------------
@_get_remaining_line_length = ( me ) ->
  return ( me[ 'cells_per_line' ] - @_get_x me ) // me[ 'size' ]


############################################################################################################
unless module.parent?
  @serve()


