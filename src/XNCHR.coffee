

############################################################################################################
TEXT                      = require 'coffeenode-text'
TYPES                     = require 'coffeenode-types'
CHR                       = require 'coffeenode-chr'
BNP                       = require 'coffeenode-bitsnpieces'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'XNCR_CHR'
log                       = TRM.get_logger 'plain',   badge
info                      = TRM.get_logger 'info',    badge
alert                     = TRM.get_logger 'alert',   badge
debug                     = TRM.get_logger 'debug',   badge
warn                      = TRM.get_logger 'warn',    badge
whisper                   = TRM.get_logger 'whisper', badge
help                      = TRM.get_logger 'help',    badge
echo                      = TRM.echo.bind TRM


### TAINT there should be a unified way to obtain copies of libraries with certain settings that
  differ from that library's default options. Interface could maybe sth like this:
  ```
  settings              = _.deep_copy CHR.options
  settings[ 'input' ]   = 'xncr'
  XNCR_CHR              = OPTIONS.new_library CHR, settings
  ```
###

### TAINT additional settings silently ignored ###

#-----------------------------------------------------------------------------------------------------------
settings              = { input: 'xncr' }
#...........................................................................................................
@analyze              = ( glyph     ) -> CHR.analyze          glyph, settings
@as_csg               = ( glyph     ) -> CHR.as_csg           glyph, settings
@as_chr               = ( glyph     ) -> CHR.as_chr           glyph, settings
@as_uchr              = ( glyph     ) -> CHR.as_uchr          glyph, settings
@as_cid               = ( glyph     ) -> CHR.as_cid           glyph, settings
@as_rsg               = ( glyph     ) -> CHR.as_rsg           glyph, settings
@as_sfncr             = ( glyph     ) -> CHR.as_sfncr         glyph, settings
@as_fncr              = ( glyph     ) -> CHR.as_fncr          glyph, settings
# @_as_xncr             = ( csg, cid  ) -> CHR._as_xncr         csg, cid
@chrs_from_text       = ( text      ) -> CHR.chrs_from_text    text, settings
@is_inner_glyph       = ( glyph     ) -> ( @as_csg glyph ) in [ 'u', 'jzr', ]
@chr_from_cid_and_csg = ( cid, csg  ) -> CHR.as_chr cid, { csg: csg }
@cid_range_from_rsg   = ( rsg       ) -> CHR.cid_range_from_rsg rsg

#-----------------------------------------------------------------------------------------------------------
@normalize = ( glyph ) ->
  rsg = @as_rsg glyph
  cid = @as_cid glyph
  csg = if rsg is 'u-pua' then 'jzr' else 'u'
  return @chr_from_cid_and_csg cid, csg





