


############################################################################################################
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
as_css                    = STYLUS.render.bind STYLUS

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
        STYLE as_css """
            body
              font-family:        'Sun-ExtA'
              font-size:          200%

            .this-col
            .this-row
              background-color:   rgba(227, 166, 81, 0.2)

            .this-cell
              background-color:   rgba(227, 166, 81, 0.6)
              border:             3px solid red

            #json-display-doc
            #json-display-cells
              border:             1px solid red
            """
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
        DIV "#doc-table", =>
          COMMENT '#{content}'
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
            socket.on 'new-table', ( table_html ) ->
              ( $ '#doc-table' ).html table_html
            #...............................................................................................
            socket.on 'change', ( observee, action, target_txt, name, value ) ->
              log observee, target_txt
              switch observee
                when 'doc'
                  ( $ '#json-display-doc' ).text target_txt, null, '  '
                when 'cells'
                  ( $ '#json-display-cells' ).text JSON.stringify value
            #...............................................................................................
            ( $ window ).on 'beforeunload', ->
              socket.close
            #...............................................................................................
            log 'ok.'
            return null

#-----------------------------------------------------------------------------------------------------------
@doc_table = ( doc ) ->
  return render =>
    [ x1, y1, ] = MKTS.get_next_xy doc
    [ xc, yc, ] = MKTS.xy_from_idx doc, doc[ 'idx' ]
    TABLE border: 1, =>
      for y in [ 0 .. y1 ]
        TR =>
          for x in [ 0 ... doc[ 'cells_per_line' ] ]
            cell  = MKTS._get doc, [ x, y, ], undefined
            cell  = MKTS._rpr_cell doc, cell
            clasz = []
            clasz.push '.this-col'   if x is xc
            clasz.push '.this-row'   if y is yc
            clasz.push '.this-cell'  if x is xc and y is yc
            TD ( clasz.join '' ), => cell




