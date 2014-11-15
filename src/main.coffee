


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
    idx:              -1 # next glyph position
    size:             1
    auto_space_chr:   '\u3000'
    # auto_space_chr:   '＊'
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
@_new_block = ( me, content ) ->
  { size, } = me
  return content if size is 1
  R =
    '~isa':   'MINGKWAI/TYPESETTER/block'
    size:     size
    content:  content
  return R

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
  @advance_chr me
  { idx
    size
    cells
    block_space_chr }   = me
  [ x0, y0, ]           = @_get_xy me
  #.........................................................................................................
  @_set me, idx, @_new_block me, content
  #.........................................................................................................
  for dx in [ 0 ... size ]
    for dy in [ 0 ... size ]
      continue if dx is dy is 0
      cells[ @idx_from_xy me, [ x0 + dx, y0 + dy, ] ] = block_space_chr
  #.........................................................................................................
  return me


### TAINT next two methods have a lot of duplicated code ###
#-----------------------------------------------------------------------------------------------------------
@advance_chr = ( me ) ->
  { size, cells, idx, } = me
  if idx < 0
    me[ 'idx' ] = 0
    return me
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
  x1 = if y is y0 then x else cells_per_line - 1
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
  chr_count           = ( Math.max 0, y - y0 ) * width + ( x - x0 + 1 )
  blank_count         = chr_count %% height
  blank_count         = height - blank_count if blank_count > 0
  cell_count          = chr_count + blank_count
  idx0                = @idx_from_xy me, [ x0, y0, ]
  tmp_cells_per_line  = cell_count / height
  tmp_cells           = []
  #.........................................................................................................
  for doc_y in [ y0 .. y1 ]
    for doc_x in [ x0 .. x1 ]
      doc_idx           = @idx_from_xy me, [ doc_x, doc_y, ]
      cell              = cells[ doc_idx ]
      tmp_cells.push cell if cell?
      cells[ doc_idx ]  = undefined
  tmp_cells.push auto_space_chr for d in [ 0 ... blank_count ]
  #.........................................................................................................
  me[ 'idx' ]         = idx0 + tmp_cells_per_line - 1
  #.........................................................................................................
  for tmp_cell, tmp_idx in tmp_cells
    [ dx, dy, ]         = @xy_from_idx null, tmp_idx, tmp_cells_per_line
    idx1                = @idx_from_xy me, [ x0 + dx, y0 + dy, ]
    cells[ idx1 ]       = tmp_cell
  #.........................................................................................................
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



 .d8888b.  88888888888 8888888b.  8888888888        d8888 888b     d888  .d8888b.
d88P  Y88b     888     888   Y88b 888              d88888 8888b   d8888 d88P  Y88b
Y88b.          888     888    888 888             d88P888 88888b.d88888 Y88b.
 "Y888b.       888     888   d88P 8888888        d88P 888 888Y88888P888  "Y888b.
    "Y88b.     888     8888888P"  888           d88P  888 888 Y888P 888     "Y88b.
      "888     888     888 T88b   888          d88P   888 888  Y8P  888       "888
Y88b  d88P     888     888  T88b  888         d8888888888 888   "   888 Y88b  d88P
 "Y8888P"      888     888   T88b 8888888888 d88P     888 888       888  "Y8888P"



#===========================================================================================================
###

#-----------------------------------------------------------------------------------------------------------
@$get_doc = ( handler = null ) ->
  #.........................................................................................................
  if handler?
    return P1.remit ( event, send ) =>
      [ type, doc, ... ] = event
      handler null, doc if type is 'doc'
      send event
  #.........................................................................................................
  return P1.remit ( event, send ) =>
    [ type, doc, ... ] = event
    send doc if type is 'doc'

#-----------------------------------------------------------------------------------------------------------
@$show_doc = ->
  return P1.remit ( event, send ) =>
    [ type, doc, ... ] = event
    log '\n' + @rpr doc if type is 'doc'
    send event

#-----------------------------------------------------------------------------------------------------------
@create_readstream = ( me ) ->
  R = P1.create_throughstream()
  R.pause()
  @walk_in_text_order me, ( error, event ) ->
    ### TAINT should respect buffering ###
    ### TAINT how to deal with errors? ###
    throw error if error
    R.write event
  return R

#-----------------------------------------------------------------------------------------------------------
@$assemble_html_events = ( settings ) ->
  ###
((畢昇發明活字印刷術))

宋沈括著《夢溪筆談》卷十八記載
((版印書籍唐人尚未盛為之))
自馮瀛王始印五經已後典籍皆為版本
((慶歷中，有布衣畢昇，又為活版。))
其法用膠泥刻字，薄如錢唇，每字為一印，火燒令堅。先設一鐵版，其上以松脂臘和紙灰之類冒之。
欲印則以一鐵範置鐵板上，乃密布字印。滿鐵範為一板，
持就火煬之，藥稍鎔，則以一平板按其面，則字平如砥。
((若止印三、二本，未為簡易；若印數十百千本，則極為神速。))
常作二鐵板，一板印刷，一板已自布字。此印者才畢，則第二板已具。
更互用之，瞬息可就。每一字皆有數印，如之、也等字，每字有二十餘印，
以備一板內有重複者。不用則以紙貼之，每韻為一貼，木格貯之。
((有奇字素無備者，旋刻之，以草火燒，瞬息可成。))
不以木為之者，木理有疏密，沾水則高下不平，兼與藥相粘，不可取。
不若燔土，用訖再火令藥熔，以手拂之，其印自落，
殊不沾汙。昇死，其印為余群從所得，
((至今保藏。))

  ###
  me              = @new_document settings
  is_first_event  = yes
  is_first_block  = yes
  par_on_next_chr = no
  sizes           = []
  #.........................................................................................................
  advance_later   =           => par_on_next_chr = true
  advance_now     =           => @advance_column me if par_on_next_chr
  advance         =           => @advance_column me
  get_size        =           => sizes[ sizes.length - 1 ]
  next_odd_int    = ( n )     => ( ( n // 2 ) * 2 ) + 1
  #.........................................................................................................
  stop_size = =>
    sizes.pop()
    start_size get_size()
  #.........................................................................................................
  start_size = ( size )  =>
    justify() if size isnt '1' and get_size() is '1'
    sizes.push size
    @set_size me, size
  #.........................................................................................................
  justify = =>
    debug '©6c1', me[ 'ysc' ], next_odd_int me[ 'y' ]
    @justify me, me[ 'ysc' ], next_odd_int me[ 'y' ]
  #.........................................................................................................
  return P1.remit ( event, send, end ) =>
    if is_first_event
      start_size 1
      send [ 'doc', me, ]
      is_first_event = no
    #.......................................................................................................
    if event?
      [ type, tail..., ]  = event
      ok                  = no
      #.....................................................................................................
      switch type
        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when 'text'
          # @set_size me, get_size()
          advance_now()
          for chr in XNCHR.chrs_from_text tail[ 0 ]
            continue if ( chr isnt '\u3000' ) and /^\s*$/.test chr
            @put me, chr
          ok = yes
        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when 'open-tag'
          [ name, attributes, ] = tail
          #.................................................................................................
          switch name
            #...............................................................................................
            when 'span'
              if attributes[ 'class' ]? and ( match = attributes[ 'class' ].match /^size-([0-9]+)$/ )?
                size = match[ 1 ]
              else
                size = get_size()
              debug '©9v1', event
              start_size size
              ok = yes
            #...............................................................................................
            when 'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
              justify me
              advance() unless is_first_block
              is_first_block  = no
              ok              = yes
        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when 'close-tag'
          switch name = tail[ 0 ]
            when 'span'
              stop_size()
              ok = yes
        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        when 'end'
          justify()
          ok = yes
      #.....................................................................................................
      warn "ignored event: #{rpr event}" unless ok
    #.......................................................................................................
    if end?
      input = @create_readstream me
        .pipe P1.remit ( event, _ ) =>
          send event
          end() if event[ 0 ] is 'end'
      #.....................................................................................................
      P1.resume input

# #-----------------------------------------------------------------------------------------------------------
# @assemble_html_events = ( me, type, tail... ) ->
#   #.........................................................................................................
#   switch type
#     #.......................................................................................................
#     when 'chr'
#       #.....................................................................................................
#     #.......................................................................................................
#     when 'par'
#       advance_later()
#       return me
#     #.......................................................................................................
#     when 'cmd'
#       [ name, parameters..., ] = tail
#       #.....................................................................................................
#       switch name
#         #...................................................................................................
#         when '1', '2', '3', '4'
#           @set_size me, parseInt name, 10
#           advance_now()
#           @put      me, chr if ( chr = parameters[ 0 ] )?
#           return me
#         #...................................................................................................
#         when '<', 'justify'
#           ### TAINT must determine scope of justification ###
#           y = ( ( me[ 'y' ] // 2 ) * 2 ) + 1
#           @justify me, me[ 'ysc' ], y
#           return me
#   #.........................................................................................................
#   warn "ignoring event #{rpr [ type, tail..., ]}"
#   return me

#===========================================================================================================
# MDX PARSER
#-----------------------------------------------------------------------------------------------------------
@_new_mdx_parser = ->
  #.........................................................................................................
  feature_set = 'full'
  #.........................................................................................................
  settings    =
    html:           yes,            # Enable HTML tags in source
    xhtmlOut:       no,             # Use '/' to close single tags (<br />)
    breaks:         no,             # Convert '\n' in paragraphs into <br>
    langPrefix:     'language-',    # CSS language prefix for fenced blocks
    linkify:        yes,            # Autoconvert URL-like text to links
    typographer:    yes,
    quotes:         '“”‘’'
  #.........................................................................................................
  R = RMY.new_parser feature_set, settings
  RMY.use R, RMY.get.examples.brackets opener: '《',  closer: '》', arity: 1, name: 'book-title'
  RMY.use R, RMY.get.examples.brackets opener: '(',  closer: ')', arity: 1, name: 'size-1'
  RMY.use R, RMY.get.examples.brackets opener: '(',  closer: ')', arity: 2, name: 'size-2'
  RMY.use R, RMY.get.examples.brackets opener: '(',  closer: ')', arity: 3, name: 'size-3'
  RMY.use R, RMY.get.examples.brackets opener: '(',  closer: ')', arity: 4, name: 'size-4'
  RMY.use R, RMY.get.examples.xncrs()
  return R


#===========================================================================================================
# HTML PARSER
#-----------------------------------------------------------------------------------------------------------
@_new_html_parser = ( stream ) ->
  settings =
    xmlMode:                 no   # Indicates whether special tags (<script> and <style>) should get special
                                  # treatment and if "empty" tags (eg. <br>) can have children. If false,
                                  # the content of special tags will be text only.
                                  # For feeds and other XML content (documents that don't consist of HTML),
                                  # set this to true. Default: false.
    decodeEntities:          no   # If set to true, entities within the document will be decoded. Defaults
                                  # to false.
    lowerCaseTags:           no   # If set to true, all tags will be lowercased. If xmlMode is disabled,
                                  # this defaults to true.
    lowerCaseAttributeNames: no   # If set to true, all attribute names will be lowercased. This has
                                  # noticeable impact on speed, so it defaults to false.
    recognizeCDATA:          yes  # If set to true, CDATA sections will be recognized as text even if the
                                  # xmlMode option is not enabled. NOTE: If xmlMode is set to true then
                                  # CDATA sections will always be recognized as text.
    recognizeSelfClosing:    yes  # If set to true, self-closing tags will trigger the onclosetag event even
                                  # if xmlMode is not set to true. NOTE: If xmlMode is set to true then
                                  # self-closing tags will always be recognized.
  #.........................................................................................................
  handlers =
    onopentag:  ( name, attributes )  -> stream.write [ 'open-tag',  name, attributes, ]
    ontext:     ( text )              -> stream.write [ 'text',      text, ]
    onclosetag: ( name )              -> stream.write [ 'close-tag', name, ]
    onend:                            -> stream.write [ 'end', ]; stream.end()
    onerror:    ( error )             -> stream.error error
  #.........................................................................................................
  return new Htmlparser handlers, settings

#-----------------------------------------------------------------------------------------------------------
@create_html_readstream_from_mdx_text = ( text, settings ) ->
  throw new Error "settings currently unsupported" if settings?
  #.........................................................................................................
  R = P1.create_throughstream()
  R.pause()
  #.........................................................................................................
  setImmediate =>
    mdx_parser  = @_new_mdx_parser()
    html        = mdx_parser.render text
    info html
    html_parser = @_new_html_parser R
    html_parser.write html
    html_parser.end()
  #.........................................................................................................
  return R

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
  switch type = TYPES.type_of cell
    when 'jsundefined'                then return me[ 'free_cell_chr' ]
    when 'text'                       then return cell
    when 'MINGKWAI/TYPESETTER/block'  then return cell[ 'content' ]
  return rpr cell

#-----------------------------------------------------------------------------------------------------------
@_get_remaining_line_length = ( me ) ->
  return ( me[ 'cells_per_line' ] - @_get_x me ) // me[ 'size' ]


############################################################################################################
unless module.parent?
  @serve()


