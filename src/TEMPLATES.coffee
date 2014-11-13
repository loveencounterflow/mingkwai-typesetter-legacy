


############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = '明快排字机/server'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
BITSNPIECES               = require 'coffeenode-bitsnpieces'
#...........................................................................................................
TEACUP                    = require 'coffeenode-teacup'


#===========================================================================================================
# TEACUP NAMESPACE ACQUISITION
#-----------------------------------------------------------------------------------------------------------
for name_ of TEACUP
  eval "#{name_} = TEACUP[ #{rpr name_} ]"

#-----------------------------------------------------------------------------------------------------------
@main = ( request, response ) ->
  #.........................................................................................................
  return render =>
    DOCTYPE 5
    HTML =>
      #.....................................................................................................
      HEAD =>
        COMMENT '#head-top'
        META charset: 'utf-8'
        TITLE '明快排字机'
        COFFEESCRIPT ->
          #.................................................................................................
          after = ( seconds, method ) -> setTimeout method, seconds * 1000
          #.................................................................................................
          notification_options =
            sticky: no
            click:  ( event, notification ) -> notification.close()
          #.................................................................................................
          notify = ( title, text ) ->
            message =
              title:  title
              text:   text
            #...............................................................................................
            ( $ '#notify-wrap' ).notify 'create',
              'notify-default'
              message
              notification_options
          #.................................................................................................
          ( $ 'document' ).ready ->
            ################################################################################################
            ( $ '#notify-wrap' ).notify
              speed:    250   # i.e. effect duration
              expires:  5000  # fades out after so many ms
            ################################################################################################
            if ( flash_messages = $.cookie 'flash-messages' )?
              flash_messages = JSON.parse flash_messages
              for idx in [ flash_messages.length - 1 .. 0 ] by -1
                [ title, text, ] = flash_messages[ idx ]
                notify title, text
              flash_messages.length = 0
              $.cookie 'flash-messages', '[]'
            #...............................................................................................
            # after 0.5, -> notify "Attention Y'All", 'the sublime message is talking to you'
            # after 1.5, -> notify "Attention Y'All", 'hear hear'
        #===================================================================================================
        LINK rel: 'shortcut icon', href: '/public/favicon.ico?v6'
        COMMENT '#head-bottom'
      #.....................................................................................................
      BODY =>
        COMMENT '#body-top'
        COMMENT '#body-bottom'

