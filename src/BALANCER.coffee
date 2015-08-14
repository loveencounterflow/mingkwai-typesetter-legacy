


############################################################################################################
# njs_util                  = require 'util'
# njs_fs                    = require 'fs'
# njs_path                  = require 'path'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'MINGKWAI/BALANCER'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
echo                      = TRM.echo.bind TRM
LODASH                    = require 'LODASH'
MATHJS                    = require 'mathjs'


#-----------------------------------------------------------------------------------------------------------
@prepare_items = ( cols ) ->
  R = []
  for col in cols
    R.push item for item in col
  return R

#-----------------------------------------------------------------------------------------------------------
@balance_columns = ( lines_per_page, col_count, items ) ->
  R           = ( [] for idx in [ 1 .. col_count ] )
  item_count  = items.length
  #.........................................................................................................
  if item_count <= col_count
    R[ idx ].push item for item, idx in items
  #.........................................................................................................
  else
    R[ 0 ].push item for item, idx in items
    #.......................................................................................................
    if col_count > 1
      min_penalty = Infinity
      #.....................................................................................................
      ### TAINT magic number ###
      for x in [ 1 .. col_count * 50 ]
        #...................................................................................................
        [ over, global_penalty, penalties, R, ] = @get_penalties lines_per_page, col_count, items, R
        #...................................................................................................
        if global_penalty < min_penalty
          best_R      = LODASH.cloneDeep R
          min_penalty = global_penalty
        #...................................................................................................
        break if over
        #...................................................................................................
        max_penalty   = -Infinity
        worst_col_idx = 0
        #...................................................................................................
        for penalty, col_idx in penalties
          break if col_idx >= col_count - 1
          if penalty > max_penalty
            max_penalty   = penalty
            worst_col_idx = col_idx
        #...................................................................................................
        if R[ worst_col_idx ].length > 0
          @move R, worst_col_idx
      #.....................................................................................................
      R = best_R
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@move = ( cols, col_idx ) ->
    unless 0 <= col_idx < cols.length - 1
      throw new Error "illegal column index #{rpr col_idx}"
    unless ( col = cols[ col_idx ] ).length > 0
      throw new Error "illegal empty column at index #{rpr col_idx}"
    cols[ col_idx + 1 ].push cols[ col_idx ].shift()
    return cols

#-----------------------------------------------------------------------------------------------------------
@get_penalties = ( lines_per_page, col_count, items, cols ) ->
  penalties = ( 0 for idx in [ 1 .. col_count ] )
  lengths   = ( 0 for idx in [ 1 .. col_count ] )
  for col, col_idx in cols
    for item, item_idx in col
      lengths[ col_idx ] += item
    lengths[ col_idx ] = 1e6 if lengths[ col_idx ] > lines_per_page
  over        = lengths[ col_count - 1 ] is 1e6
  penalty     = MATHJS.std  lengths
  mean_length = MATHJS.mean lengths
  penalties   = ( Math.abs length - mean_length for length in lengths )
  return [ over, penalty, penalties, cols, ]

#-----------------------------------------------------------------------------------------------------------
@demo = ->
  BNP = require 'coffeenode-bitsnpieces'
  #.........................................................................................................
  s0                  = 2
  s1                  = 8
  n                   = 3  # demo runs
  m                   = 20 # items per page
  lines_per_page      = 54
  col_count           = 3
  get_random_integer  = ( s0, s1 ) -> s0 + Math.floor rnd() * ( s1 - s0 ) + 0.5
  #.........................................................................................................
  for i in [ 1 .. n ]
    rnd   = BNP.get_rnd i / 7
    items = ( ( get_random_integer s0, s1 ) for idx in [ 1 .. m ] )
    help @balance_columns lines_per_page, col_count, items

############################################################################################################
unless module.parent?
  @demo()
