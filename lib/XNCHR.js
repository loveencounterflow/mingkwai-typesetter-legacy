// Generated by CoffeeScript 1.8.0
(function() {
  var BNP, CHR, TEXT, TRM, TYPES, alert, badge, debug, echo, help, info, log, rpr, settings, warn, whisper;

  TEXT = require('coffeenode-text');

  TYPES = require('coffeenode-types');

  CHR = require('coffeenode-chr');

  BNP = require('coffeenode-bitsnpieces');

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  badge = 'XNCR_CHR';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  alert = TRM.get_logger('alert', badge);

  debug = TRM.get_logger('debug', badge);

  warn = TRM.get_logger('warn', badge);

  whisper = TRM.get_logger('whisper', badge);

  help = TRM.get_logger('help', badge);

  echo = TRM.echo.bind(TRM);


  /* TAINT there should be a unified way to obtain copies of libraries with certain settings that
    differ from that library's default options. Interface could maybe sth like this:
    ```
    settings              = _.deep_copy CHR.options
    settings[ 'input' ]   = 'xncr'
    XNCR_CHR              = OPTIONS.new_library CHR, settings
    ```
   */


  /* TAINT additional settings silently ignored */

  settings = {
    input: 'xncr'
  };

  this.analyze = function(glyph) {
    return CHR.analyze(glyph, settings);
  };

  this.as_csg = function(glyph) {
    return CHR.as_csg(glyph, settings);
  };

  this.as_chr = function(glyph) {
    return CHR.as_chr(glyph, settings);
  };

  this.as_uchr = function(glyph) {
    return CHR.as_uchr(glyph, settings);
  };

  this.as_cid = function(glyph) {
    return CHR.as_cid(glyph, settings);
  };

  this.as_rsg = function(glyph) {
    return CHR.as_rsg(glyph, settings);
  };

  this.as_sfncr = function(glyph) {
    return CHR.as_sfncr(glyph, settings);
  };

  this.as_fncr = function(glyph) {
    return CHR.as_fncr(glyph, settings);
  };

  this.chrs_from_text = function(text) {
    return CHR.chrs_from_text(text, settings);
  };

  this.is_inner_glyph = function(glyph) {
    var _ref;
    return (_ref = this.as_csg(glyph)) === 'u' || _ref === 'jzr';
  };

  this.chr_from_cid_and_csg = function(cid, csg) {
    return CHR.as_chr(cid, {
      csg: csg
    });
  };

  this.cid_range_from_rsg = function(rsg) {
    return CHR.cid_range_from_rsg(rsg);
  };

  this.normalize = function(glyph) {
    var cid, csg, rsg;
    rsg = this.as_rsg(glyph);
    cid = this.as_cid(glyph);
    csg = rsg === 'u-pua' ? 'jzr' : 'u';
    return this.chr_from_cid_and_csg(cid, csg);
  };

}).call(this);