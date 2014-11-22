// Generated by CoffeeScript 1.8.0
(function() {
  var GM, TEMP, TRM, TYPES, alert, badge, debug, echo, help, info, log, njs_fs, njs_path, options, rpr, warn, whisper;

  njs_fs = require('fs');

  njs_path = require('path');

  TYPES = require('coffeenode-types');

  TRM = require('coffeenode-trm');

  rpr = TRM.rpr.bind(TRM);

  badge = 'MINGKWAI/TYPESETTER';

  log = TRM.get_logger('plain', badge);

  info = TRM.get_logger('info', badge);

  whisper = TRM.get_logger('whisper', badge);

  alert = TRM.get_logger('alert', badge);

  debug = TRM.get_logger('debug', badge);

  warn = TRM.get_logger('warn', badge);

  help = TRM.get_logger('help', badge);

  echo = TRM.echo.bind(TRM);

  GM = require('gm');

  TEMP = (require('temp')).track();

  options = {
    'px-per-mm': 15,
    'width': 243,
    'height': 183 - 5,
    'colors': {
      'red': '86000b',
      'blue': '21247b',
      'black': '000000'
    }
  };

  this.new_image = function(settings, route) {
    var R, colors, substrate, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    R = {
      '~isa': 'MINGKWAI/PLOTTER/image'
    };
    R['route'] = (_ref = route != null ? route : settings != null ? settings['route'] : void 0) != null ? _ref : TEMP.path({
      suffix: '.png'
    });
    R['px-per-mm'] = (_ref1 = settings != null ? settings['px-per-mm'] : void 0) != null ? _ref1 : 15;
    R['width'] = (_ref2 = settings != null ? settings['width'] : void 0) != null ? _ref2 : 297 - 29 - 25;
    R['height'] = (_ref3 = settings != null ? settings['height'] : void 0) != null ? _ref3 : 210 - 11 - 12 - 5;
    R['colors'] = colors = [];
    R['tex'] = "\\includegraphics[width=" + R['width'] + "mm]{" + R['route'] + "}";
    colors['red'] = (_ref4 = settings != null ? (_ref5 = settings['colors']) != null ? _ref5['red'] : void 0 : void 0) != null ? _ref4 : '#86000b';
    colors['blue'] = (_ref6 = settings != null ? (_ref7 = settings['colors']) != null ? _ref7['blue'] : void 0 : void 0) != null ? _ref6 : '#21247b';
    colors['black'] = (_ref8 = settings != null ? (_ref9 = settings['colors']) != null ? _ref9['black'] : void 0 : void 0) != null ? _ref8 : '#000000';
    substrate = GM(this.px_from_mm(R, R['width']), this.px_from_mm(R, R['height']), '#ffffffff');
    R['%self'] = substrate;
    return R;
  };

  this.px_from_mm = function(me, d_mm) {
    return d_mm * me['px-per-mm'];
  };

  this.fill = function(me, color) {
    return me['%self'].fill(this.get_color(me, color));
  };

  this.stroke = function(me, color, width) {
    return me['%self'].stroke(this.get_color(me, color), this.px_from_mm(me, width));
  };

  this.get_color = function(me, color) {
    var _ref, _ref1;
    return (_ref = (_ref1 = me['colors']) != null ? _ref1[color] : void 0) != null ? _ref : color;
  };

  this.write = function(me, handler) {
    return me['%self'].write(me['route'], handler);
  };

  this.line = function(me, xy0, xy1) {
    var x0, x1, y0, y1;
    x0 = this.px_from_mm(me, xy0[0]);
    y0 = this.px_from_mm(me, xy0[1]);
    x1 = this.px_from_mm(me, xy1[0]);
    y1 = this.px_from_mm(me, xy1[1]);
    me['%self'].drawLine(x0, y0, x1, y1);
    return me;
  };

  this.main = function(route, handler) {
    var PLOTTER, img, xy0, xy1;
    PLOTTER = this;
    img = PLOTTER.new_image(null, route);
    xy0 = [0, 0];
    xy1 = [243, 183 - 5];
    PLOTTER.fill(img, 'transparent');
    PLOTTER.stroke(img, 'red', 0.225);
    PLOTTER.line(img, xy0, xy1);
    PLOTTER.write(img, handler);
    info(img['tex']);
    return null;
  };

  if (module.parent == null) {
    this.main(null, function(error) {
      if (error != null) {
        throw error;
      }
      return help('ok');
    });
  }

}).call(this);