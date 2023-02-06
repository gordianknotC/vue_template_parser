import 'package:dart_common/dart_common.dart';
import 'package:petitparser/petitparser.dart';
import '../src/ast.utils.dart';


final _log = print;

const DIRECTIVES_ARR = [
  Directive.VBIND,
  Directive.VCLOAK,
  Directive.VELSE,
  Directive.VELSEIF,
  Directive.VFOR,
  Directive.VHTML,
  Directive.VIF,
  Directive.VMODEL,
  Directive.VON,
  Directive.VONCE,
  Directive.VPRE,
  Directive.VSHOW,
  Directive.VTXT
];

const JS_KW_ARR = [
  JSKeywords.ABSTRACT,
  JSKeywords.AWAIT,
  JSKeywords.ASYNC,
  JSKeywords.BREAK,
  JSKeywords.CATCH,
  JSKeywords.CLASS,
  JSKeywords.CONST,
  JSKeywords.CONSTRUCTOR,
  JSKeywords.CONTINUE,
  JSKeywords.DEFAULT,
  JSKeywords.DO,
  JSKeywords.ELSE,
  JSKeywords.EXPORTS,
  JSKeywords.FALSE,
  JSKeywords.FINALLY,
  JSKeywords.FOR,
  JSKeywords.IF,
  JSKeywords.IMPORT,
  JSKeywords.IN,
  JSKeywords.INSTANCEOF,
  JSKeywords.NEW,
  JSKeywords.NULL,
  JSKeywords.OF,
  JSKeywords.RETURN,
  JSKeywords.STATIC,
  JSKeywords.THIS,
  JSKeywords.THROW,
  JSKeywords.TRUE,
  JSKeywords.TRY,
  JSKeywords.VAR,
  JSKeywords.VOID,
  JSKeywords.YIELD,
  JSKeywords.WHILE,
  JSKeywords.LET
];

class Directive {
  static const VBIND = 'v-bind';
  static const VCLOAK = 'v-cloak';
  static const VELSE = 'v-else';
  static const VELSEIF = 'v-else-if';
  static const VFOR = 'v-for';
  static const VHTML = 'v-html';
  static const VIF = 'v-if';
  static const VMODEL = 'v-model';
  static const VON = 'v-on';
  static const VONCE = 'v-once';
  static const VPRE = 'v-pre';
  static const VSHOW = 'v-show';
  static const VTXT = 'v-text';
}

class JSKeywords {
  static const ABSTRACT = 'abstract';
  static const AWAIT = 'await';
  static const ASYNC = 'async';
  static const BREAK = 'break';
  static const CATCH = 'catch';
  static const CLASS = 'class';
  static const CONST = 'const';
  static const CONSTRUCTOR = 'constructor';
  static const CONTINUE = 'continue';
  static const DEFAULT = 'default';
  static const DO = 'do';
  static const ELSE = 'else';
  static const EXPORTS = 'exports';
  static const FALSE = 'false';
  static const FINALLY = 'finally';
  static const FOR = 'for';
  static const IF = 'if';
  static const IMPORT = 'import';
  static const IN = 'in';
  static const INSTANCEOF = 'instanceof';
  static const LET = 'let';
  static const NEW = 'new';
  static const NULL = 'null';
  static const OF = 'of';
  static const RETURN = 'return';
  static const STATIC = 'static';
  static const SUPER = 'super';
  static const SWITCH = 'switch';
  static const THIS = 'this';
  static const THROW = 'throw';
  static const TRUE = 'true';
  static const TRY = 'try';
  static const VAR = 'var';
  static const VOID = 'void';
  static const WHILE = 'while';
  static const YIELD = 'yield';
}

class XNode {
  int _level = 0;
  XTag tag;
  XTag text;
  XTag attrs;
  List<XNode> children;
  XNode parent;

  get level => getLevel();

  int getLevel([l = 0]) {
    if (parent != null) return parent.getLevel(l + 1);
    return l;
  }

  XNode getRoot() {
    if (parent != null) return parent.getRoot();
    return this;
  }

  void addParent(XNode p) {
    if (!p.children.contains(this)) {
      p.addChild(this);
    }
    parent = p;
  }

  void addChild(XNode c) {
    if (!children.contains(c)) {
      children.add(c);
      c.addParent(this);
    }
  }

  XNode({this.tag, this.attrs, this.text, this.children}) {
    children ??= [];
  }

  String toString([String typename = 'XNode']) {
    String indent(int l) => '\t' * l;
    var tag = this.tag == null ? '' : 'tag: ${this.tag.tagname},';
    var att = attrs == null ? '' : 'attrs: ${attrs.attrs},';
    var txt = text == null ? '' : 'text: ${text.texts},';
    var chds = children.length > 0 ? '\n' + children.join('\n') : '';
    var pos = this.tag?.pos ?? attrs?.pos ?? text?.pos;
    return '${indent(level)}<${typename}$pos> $tag $att $txt $chds';
  }
}

class XTag<E> {
  static const NAME = 'Name';
  static const TAG = 'Tag';
  static const ATTRS = 'Attrs';
  static const ELT = 'Element';
  static const NODE = 'Node';
  static const TEXT = 'Text';

  int start; // column pos
  int lineno; // lineno pos
  XNode segment; // tag segments e.g: tag, attrs, texts, children...
  String tagname; // name of tag
  String typename; // type of current tag
  Map<String, String> attrs; // attributes
  List<String> texts; // text contents

  List<XNode> get children => segment.children;

  String get pos => this.start == null ? '' : '[${this.lineno}:${this.start}]';

  _posInit(Token tok) {
    start = tok.start;
    lineno = tok.line;
  }

  _addChild(XNode child_node) {
    _log('addChild: ${child_node.level} ');
    _log('$child_node');
    segment.addChild(child_node);
    child_node.addParent(segment);
    _log('  addChild: ${child_node.level} ');
    _log('$child_node');
    _log('  parent: ${child_node.parent}');
  }

  XTag.NodeInit(XTag tag, List<List> content) {
    typename = XTag.NODE;
    tagname = tag.tagname;
    start = tag.start;
    lineno = tag.lineno;
    attrs = tag.attrs;

    var _children = [];
    content.forEach((set) {
      var elt_or_node = set[0] as XTag;
      var txts = set[1] as List<XTag>;

      if (txts != null) {
        texts ??= [];
        texts.addAll(txts.fold(<String>[], (initial, t) => t.texts + initial));
        _log('add texts: $texts');
      }
      if (elt_or_node.typename == XTag.ELT) {
        _children.add(elt_or_node);
      } else if (elt_or_node.typename == XTag.NODE) {
        _children.add(elt_or_node);
      } else {
        throw Exception('Unchaught Exception');
      }
    });
    segment = XNode(tag: tag, attrs: tag, text: this);

    _log('add children ${_children.length}: $_children');
    _children.forEach((ch) {
      _addChild(ch.segment);
    });
  }

  XTag.TagInit(List<XTag<String>> list) {
    XTag attrs_tag;
    typename = XTag.TAG;
    start = list[0].start;
    lineno = list[0].lineno;
    tagname = list[0].tagname;
    attrs_tag = list.length > 1 ? list[1] : null;
    attrs = attrs_tag?.attrs;
    segment = XNode(
      tag: list[0],
      attrs: attrs_tag,
    );
  }

  XTag.ElementInit(List<XTag> list) {
    XTag text_tag;
    typename = XTag.ELT;
    start = list[0].start;
    lineno = list[0].lineno;
    tagname = list[0].tagname;
    attrs = list[0].attrs;
    text_tag = list.length > 1 ? list[1] : null;
    texts = text_tag?.texts;
    segment = XNode(tag: list[0], attrs: list[0], text: text_tag);
  }

  _StringTypeInit(Token<String> token, String name) {
    typename = name;
    _posInit(token);
  }

  XTag.NameInit(Token<String> token) {
    segment = XNode(tag: this);
    tagname = token.value;
    _StringTypeInit(token, XTag.NAME);
  }

  XTag.AttrsInit(List<List<Token<String>>> data) {
    data.forEach((pair) {
      var tok_name = pair[0];
      var tok_val = pair[1];
      attrs ??= {};
      attrs[tok_name.value.trim()] = tok_val.value.trim();
    });
    segment = XNode(attrs: this);
    _StringTypeInit(data[0][0], XTag.ATTRS);
  }

  XTag.TextInit(Token<String> token) {
    segment = XNode(text: this);
    texts = [token.value.trim()];
    _StringTypeInit(token, XTag.TEXT);
  }

  String toString() {
    return segment.toString(typename);
  }
}

class TArgs {
  List data;

  Iterable<TProp> get prop_accs =>
      data.where((arg) => arg is TProp).map((arg) => arg);

  List<String> get vars =>
      List<String>.from(
          data.where((arg) => arg is Token).map((arg) => arg.value)) ??
      [];

  List<String> get idents => vars + prop_accs.map((arg) => arg.root).toList();

  TArgs(this.data);
}

class TInvoke {
  Token<String> caller;

  TArgs args;

  String get caller_name => caller.value;

  List<String> get references => [caller_name] + args.idents;

  TInvoke(this.caller, this.args);
}

class TProp {
  List<Token<String>> data;

  String get property => data.last.value;

  String get target => data[data.length - 2].value;

  String get root => data[0].value;

  TProp(this.data);
}
