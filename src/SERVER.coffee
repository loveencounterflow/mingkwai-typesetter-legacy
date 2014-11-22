
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



############################################################################################################
# njs_path                  = require 'path'
# njs_fs                    = require 'fs'
#...........................................................................................................
TEXT                      = require 'coffeenode-text'
TYPES                     = require 'coffeenode-types'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '明快排字机/SERVER'
info                      = TRM.get_logger 'info',    badge
alert                     = TRM.get_logger 'alert',   badge
debug                     = TRM.get_logger 'debug',   badge
warn                      = TRM.get_logger 'warn',    badge
urge                      = TRM.get_logger 'urge',    badge
whisper                   = TRM.get_logger 'whisper', badge
help                      = TRM.get_logger 'help',    badge
#...........................................................................................................
RMY                       = require 'remarkably'
Htmlparser                = ( require 'htmlparser2' ).Parser
XNCHR                     = require './XNCHR'
#...........................................................................................................
MKTS                      = require './main'
TEMPLATES                 = require './TEMPLATES'
#...........................................................................................................
app                       = ( require 'express'   )()
server                    = ( require 'http'      ).Server app
sio                       = ( require 'socket.io' ) server
port                      = 3000
layout                    = TEMPLATES.layout()
# [ preamble, postscript, ] = layout.split '<!--#{content}-->'

#-----------------------------------------------------------------------------------------------------------
get_doc_updater = ->
  chrs          = XNCHR.chrs_from_text """(畢昇發明活字印刷術)

    宋沈括著夢溪筆談卷十八記載
    (版印書籍唐人尚未盛為之)
    自馮瀛王始印五經已後典籍皆為版本
    (慶歷中有布衣畢昇又為活版)
    """#.replace /\s+/g, ''
  # debug '©Jq7C9', rpr chrs
  chr_count     = chrs.length
  chr_idx       = null
  doc           = null
  nl_state      = 'none' # 'pending', 'ignore'
  last_size     = 1
  #.........................................................................................................
  self = ( command, event_emitter ) ->
    #.......................................................................................................
    switch command
      #-----------------------------------------------------------------------------------------------------
      when 'play'
        loop
          self 'next', event_emitter
          break if chr_idx % 5 is 0
      #-----------------------------------------------------------------------------------------------------
      when 'new', 'reset'
        #...................................................................................................
        handler = ( observee, action, target, name, value ) ->
          unless action is 'get'
            ### `JSON.stringify target` strangely causes an `illegal access` error: ###
            target_txt = rpr target
            event_emitter.emit 'change', observee, action, target_txt, name, value if event_emitter?
            return null
        #...................................................................................................
        chr_idx = 0
        doc     = MKTS.new_observable_document handler
      #-----------------------------------------------------------------------------------------------------
      when 'next'
        done = no
        until done
          MKTS.advance_page doc if chr_idx % chr_count is 0 # ??????????
          chr       = chrs[ chr_idx % chr_count ]
          chr_idx  += 1
          nl_state  = 'none' if chr isnt '\n'
          #.................................................................................................
          switch chr
            #...............................................................................................
            when '\n'
              switch nl_state
                when 'none'
                  nl_state = 'pending'
                when 'pending'
                  # debug '©OKr1W', 'last_size', last_size
                  MKTS.advance_line doc, last_size
                  nl_state = 'ignore'
                when 'ignore'
                  null
                else
                  throw new Error "unknown newline state #{rpr nl_state}"
            #...............................................................................................
            when '('
              MKTS.set_size doc, 2
              MKTS.compress doc
              # MKTS.advance_chr_if_necessary doc, true
              # done = no
              done = yes
            #...............................................................................................
            when ')'
              MKTS.set_size doc, 1
              # MKTS.advance_chr_if_necessary doc, true
              # done = no
              done = yes
            #...............................................................................................
            else
              last_size = doc[ 'size' ]
              MKTS.put doc, chr
              done = yes
          # debug '©0g1', chr, doc
      #-----------------------------------------------------------------------------------------------------
      else
        # throw new Error 'xxx' if command is undefined
        warn "ignored MKTS command: #{command}"
    #.......................................................................................................
    return doc
  #.........................................................................................................
  return self

#-----------------------------------------------------------------------------------------------------------
update_doc = get_doc_updater()

#-----------------------------------------------------------------------------------------------------------
sio.on 'connection', ( socket ) ->
  doc = null
  urge "a user connected"
  #.........................................................................................................
  socket.on 'disconnect', ->
    warn 'user disconnected'
  #.........................................................................................................
  socket.on 'playback', ( command ) ->
    switch command
      when 'next'   then render command
      when 'reset'  then render command
      when 'play'   then render command
      else warn "ignored client event: playback/#{command}"
  #.........................................................................................................
  render = ( command ) ->
    doc  ?= update_doc 'new', socket
    doc   = update_doc command
    sio.emit 'new-table', 'plain', TEMPLATES.doc_table doc, 'plain'
    sio.emit 'new-table', 'sized', TEMPLATES.doc_table doc, 'sized'
  #.........................................................................................................
  render 'new'
  return null

#---------------------------------------------------------------------------------------------------------
app.get '/', do =>
  return ( request, response ) =>
    response.writeHead 200, { 'Access-Control-Allow-Origin': '*', }
    response.write layout
    # response.write preamble
    # response.write TEMPLATES.doc_table doc
    # response.write postscript
    response.end()


#-----------------------------------------------------------------------------------------------------------
@serve = ->
  # { port: port, origins: '*:*', }
  server = server.listen port, ->
    { address: host, port, } = server.address()
    help "明快排字机 listening at http://#{host}:#{port}"


############################################################################################################
unless module.parent?
  @serve()
