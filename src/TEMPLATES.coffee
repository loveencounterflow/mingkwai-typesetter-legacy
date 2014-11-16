


############################################################################################################
njs_path                  = require 'path'
njs_fs                    = require 'fs'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '明快排字机/TEMPLATES'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
#...........................................................................................................
MKTS                      = require './main'
TEACUP                    = require 'coffeenode-teacup'
STYLUS                    = require 'stylus'
#...........................................................................................................
as_css                    = STYLUS.render.bind STYLUS
style_route               = njs_path.join __dirname, '../public/mingkwai-typesetter.styl'
css                       = as_css njs_fs.readFileSync style_route, encoding: 'utf-8'


#===========================================================================================================
# TEACUP NAMESPACE ACQUISITION
#-----------------------------------------------------------------------------------------------------------
for name_ of TEACUP
  eval "#{name_} = TEACUP[ #{rpr name_} ]"

#-----------------------------------------------------------------------------------------------------------
@layout = ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      HEAD =>
        META charset: 'utf-8'
        TITLE '明快排字机'
        LINK rel: 'shortcut icon', href: '/public/favicon.ico?v6'
        STYLE css
      #=====================================================================================================
      BODY =>
        FORM "#controller", =>
          BUTTON name: 'record',      '⏺'
          BUTTON name: 'reset',       '⏮'
          BUTTON name: 'back',        '⏴'
          BUTTON name: 'pause',       '⏸'
          BUTTON name: 'play',        '⏵'
          BUTTON name: 'next',        '⏯'
          # BUTTON name: 'previous', "⏯"
          # BUTTON name: '', "⏭"
        BR()
        DIV "#table-container", =>
          DIV "#doc-table-plain"
          DIV "#doc-table-sized"
        PRE "#json-display-doc", ''
        PRE "#json-display-cells", ''
        #===================================================================================================
        SCRIPT src: 'http://code.jquery.com/jquery-1.11.1.js'
        SCRIPT src: '/socket.io/socket.io.js'
        COFFEESCRIPT ->
          log     = console.log.bind console
          socket  = io()
          #.................................................................................................
          ( $ 'document' ).ready ->
            #...............................................................................................
            ( $ 'button' ).on 'click', ->
              self = $ @
              event_type  = 'playback'
              event_name  = self.attr 'name'
              socket.emit event_type, event_name
              return false
            #...............................................................................................
            socket.on 'new-table', ( style, table_html ) ->
              ( $ "#doc-table-#{style}" ).html table_html
              ( $ 'html, body' ).stop().animate { scrollTop: ( $ '#bottom' ).offset().top }, 2000
            #...............................................................................................
            socket.on 'change', ( observee, action, target_txt, name, value ) ->
              log observee, target_txt
              switch observee
                # when 'doc'
                #   ( $ '#json-display-doc' ).text target_txt, null, '  '
                when 'cells'
                  ( $ '#json-display-cells' ).text JSON.stringify value
            # #...............................................................................................
            # ( $ window ).on 'beforeunload', ->
            #   socket.close
            #...............................................................................................
            log 'ok.'
            return null
        #===================================================================================================
        DIV '#bottom'

#-----------------------------------------------------------------------------------------------------------
@doc_table = ( doc, style = 'plain' ) ->
  return render =>
    { auto_space_chr
      block_space_chr
      free_cell_chr
      cells_per_line }  = doc
    #.......................................................................................................
    [ x1, y1, ]         = MKTS.get_next_xy doc
    [ xc, yc, ]         = MKTS.xy_from_idx doc, doc[ 'idx' ]
    #.......................................................................................................
    switch style
      #.....................................................................................................
      when 'plain'
        TABLE '.doc-table', =>
          TH(); TH x for x in [ 0 ... cells_per_line ]; TH()
          for y in [ 0 .. y1 ]
            TR =>
              TH y
              for x in [ 0 ... cells_per_line ]
                cell      = MKTS._get doc, [ x, y, ], undefined
                cell_txt  = MKTS._rpr_cell doc, cell
                clasz     = []
                clasz.push '.this-col'    if x is xc
                clasz.push '.this-row'    if y is yc
                clasz.push '.this-cell'   if x is xc and y is yc
                clasz.push '.auto-space'  if cell_txt is auto_space_chr
                clasz.push '.block-space' if cell_txt is block_space_chr
                clasz.push '.free-cell'   if cell_txt is free_cell_chr
                TD ( clasz.join '' ), => cell_txt
              TH y
          TH(); TH x for x in [ 0 ... cells_per_line ]; TH()
      #.....................................................................................................
      when 'sized'
        TABLE '.doc-table', =>
          TH(); TH x for x in [ 0 ... cells_per_line ]; TH()
          for y in [ 0 .. y1 ]
            TR =>
              TH y
              for x in [ 0 ... cells_per_line ]
                cell            = MKTS._get doc, [ x, y, ], undefined
                # continue if cell is undefined
                continue if cell is MKTS.blockade
                cell_txt        = MKTS._rpr_cell doc, cell
                size            = cell?[ 'size' ] ? 1
                Q               = {}
                Q[ 'rowspan' ]  = Q[ 'colspan' ] = size if size isnt 1
                clasz           = []
                clasz.push ".size-#{size}"
                clasz.push '.this-col'    if x is xc
                clasz.push '.this-row'    if y is yc
                clasz.push '.this-cell'   if x is xc and y is yc
                clasz.push '.auto-space'  if cell_txt is auto_space_chr
                clasz.push '.free-cell'   if cell_txt is free_cell_chr
                TD ( clasz.join '' ), Q, => cell_txt
              TH y
          TH(); TH x for x in [ 0 ... cells_per_line ]; TH()
      #.....................................................................................................
      else
        throw new Error "unknown table style #{rpr style}"




