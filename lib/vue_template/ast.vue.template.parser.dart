import 'package:common/common.dart';
import 'package:parser_utils/vue_template/utils.dart';
import 'package:petitparser/petitparser.dart';
//import 'package:html/dom.dart' show DocumentFragment, Node, Element;
//const IDENT_SP_PTN   = '[:\r\n\*/\\]\}\{\%\(\)\[,+-]+';
//RegExp IDENT_SPLITER = new RegExp(IDENT_SP_PTN);

final _log = Logger(name: "templ.parser", levels: [ELevel.debug, ELevel.critical, ELevel.error, ELevel.warning, ELevel.sys ]);


const DIRECTIVES = [
   _DIRS.VBIND, _DIRS.VCLOAK, _DIRS.VELSE, _DIRS.VELSEIF, _DIRS.VFOR, _DIRS.VHTML,
   _DIRS.VIF, _DIRS.VMODEL, _DIRS.VON, _DIRS.VONCE, _DIRS.VPRE, _DIRS.VSHOW, _DIRS.VTXT
];

const JSKEYWORDS = [
   _KWS.ABSTRACT, _KWS.AWAIT, _KWS.ASYNC, _KWS.BREAK, _KWS.CATCH, _KWS.CLASS, _KWS.CONST,
   _KWS.CONSTRUCTOR, _KWS.CONTINUE, _KWS.DEFAULT, _KWS.DO, _KWS.ELSE, _KWS.EXPORTS,
   _KWS.FALSE, _KWS.FINALLY, _KWS.FOR, _KWS.IF, _KWS.IMPORT, _KWS.IN, _KWS.INSTANCEOF,
   _KWS.NEW, _KWS.NULL, _KWS.OF, _KWS.RETURN, _KWS.STATIC, _KWS.THIS, _KWS.THROW,
   _KWS.TRUE, _KWS.TRY, _KWS.VAR, _KWS.VOID, _KWS.YIELD, _KWS.WHILE, _KWS.LET
];

class _DIRS{
   static const VBIND   = 'v-bind';
   static const VCLOAK  = 'v-cloak';
   static const VELSE   = 'v-else';
   static const VELSEIF = 'v-else-if';
   static const VFOR    = 'v-for';
   static const VHTML   = 'v-html';
   static const VIF     = 'v-if';
   static const VMODEL  = 'v-model';
   static const VON     = 'v-on';
   static const VONCE   = 'v-once';
   static const VPRE    = 'v-pre';
   static const VSHOW   = 'v-show';
   static const VTXT    = 'v-text';
}

class _KWS{
   static const ABSTRACT   = 'abstract';
   static const AWAIT      = 'await';
   static const ASYNC      = 'async';
   static const BREAK      = 'break';
   static const CATCH      = 'catch';
   static const CLASS      = 'class';
   static const CONST      = 'const';
   static const CONSTRUCTOR= 'constructor';
   static const CONTINUE   = 'continue';
   static const DEFAULT    = 'default';
   static const DO         = 'do';
   static const ELSE       = 'else';
   static const EXPORTS    = 'exports';
   static const FALSE      = 'false';
   static const FINALLY    = 'finally';
   static const FOR        = 'for';
   static const IF         = 'if';
   static const IMPORT     = 'import';
   static const IN         = 'in';
   static const INSTANCEOF = 'instanceof';
   static const LET        = 'let';
   static const NEW        = 'new';
   static const NULL       = 'null';
   static const OF         = 'of';
   static const RETURN     = 'return';
   static const STATIC     = 'static';
   static const SUPER      = 'super';
   static const SWITCH     = 'switch';
   static const THIS       = 'this';
   static const THROW      = 'throw';
   static const TRUE       = 'true';
   static const TRY        = 'try';
   static const VAR        = 'var';
   static const VOID       = 'void';
   static const WHILE      = 'while';
   static const YIELD      = 'yield';
}




class XNode{
   int   _level = 0;
   XTag  tag;
   XTag  text;
   XTag  attrs;
   List<XNode> children;
   XNode       parent;
   
   get level => getLevel();
   
   int getLevel([l = 0]){
      if (parent != null)
         return parent.getLevel(l + 1);
      return l;
   }
   
   XNode getRoot(){
      if (parent != null) return parent.getRoot();
      return this;
   }
   
   void addParent(XNode p){
      if (!p.children.contains(this)){
         p.addChild(this);
      }
      parent = p;
   }
   
   void addChild(XNode c){
      if (!children.contains(c)){
         children.add(c);
         c.addParent(this);
      }
   }
   
   XNode({this.tag, this.attrs, this.text, this.children}){
      children ??= [];
   }
   
   String toString([String typename = 'XNode']) {
      String indent(int l) => '\t' * l;
      var tag = this.tag == null ? '' : 'tag: ${this.tag.tagname},';
      var att = attrs   == null ? '' : 'attrs: ${attrs.attrs},';
      var txt = text   == null ? '' : 'text: ${text.texts},';
      var chds = children.length > 0 ? '\n' + children.join('\n') : '';
      var pos  = this.tag?.pos ?? attrs?.pos ?? text?.pos;
      return '${indent(level)}<${typename}$pos> $tag $att $txt $chds';
   }
}

class XTag<E> {
   static const NAME  = 'Name';
   static const TAG   = 'Tag';
   static const ATTRS = 'Attrs';
   static const ELT   = 'Element';
   static const NODE  = 'Node';
   static const TEXT  = 'Text';
   
   int    start;     // column pos
   int    lineno;    // lineno pos
   XNode  segment;   // tag segments e.g: tag, attrs, texts, children...
   String tagname;   // name of tag
   String typename;  // type of current tag
   Map<String, String> attrs; // attributes
   List<String>        texts; // text contents
   
   List<XNode>
   get children => segment.children;
   
   String
   get pos => this.start == null ? '' : '[${this.lineno}:${this.start}]';
   
   _posInit(Token tok){
      start = tok.start;
      lineno = tok.line;
   }
   
   _addChild(XNode child_node){
      _log.info('addChild: ${child_node.level} ');
      _log.info('$child_node');
      segment.addChild(child_node);
      child_node.addParent(segment);
      _log.info('  addChild: ${child_node.level} ');
      _log.info('$child_node');
      _log.info('  parent: ${child_node.parent}');
   }
   
   XTag.NodeInit(XTag tag, List<List> content){
      typename = XTag.NODE;
      tagname  = tag.tagname;
      start    = tag.start;
      lineno   = tag.lineno;
      attrs    = tag.attrs;
      
      var _children  = [];
      content.forEach((set){
         var elt_or_node = set[0] as XTag;
         var txts        = set[1] as List<XTag>;
         
         if (txts != null){
            texts ??= [];
            texts.addAll(txts
               .fold(<String>[], (initial, t) =>
            t.texts  + initial) );
            _log.info('add texts: $texts');
         }
         if (elt_or_node.typename == XTag.ELT){
            _children.add(elt_or_node);
         } else if (elt_or_node.typename == XTag.NODE){
            _children.add(elt_or_node);
         } else{
            throw Exception('Unchaught Exception');
         }
      });
      segment = XNode(
         tag: tag, attrs: tag, text: this
      );

      _log.info('add children ${_children.length}: $_children');
      _children.forEach((ch){
         _addChild(ch.segment);
      });
     
   }
   
   XTag.TagInit(List<XTag<String>> list){
      XTag attrs_tag;
      typename = XTag.TAG;
      start = list[0].start;
      lineno = list[0].lineno;
      tagname = list[0].tagname;
      attrs_tag=list.length > 1 ? list[1] : null;
      attrs   = attrs_tag?.attrs;
      segment = XNode(
         tag: list[0], attrs: attrs_tag,
      );
   }
   
   XTag.ElementInit(List<XTag> list){
      XTag text_tag;
      typename = XTag.ELT;
      start = list[0].start;
      lineno = list[0].lineno;
      tagname = list[0].tagname;
      attrs   = list[0].attrs;
      text_tag= list.length > 1 ? list[1] : null;
      texts    = text_tag?.texts;
      segment = XNode(
         tag: list[0], attrs: list[0],
         text: text_tag
      );
   }
   
   _StringTypeInit(Token<String> token, String name){
      typename = name;
      _posInit(token);
   }
   
   XTag.NameInit(Token<String> token){
      segment = XNode(tag: this);
      tagname = token.value;
      _StringTypeInit(token, XTag.NAME);
   }
   XTag.AttrsInit(List<List<Token<String>>> data){
      data.forEach((pair){
         var tok_name = pair[0];
         var tok_val = pair[1];
         attrs ??= {};
         attrs[tok_name.value.trim()] = tok_val.value.trim();
      });
      segment = XNode(attrs: this);
      _StringTypeInit(data[0][0], XTag.ATTRS);
   }
   
   XTag.TextInit(Token<String> token){
      segment = XNode(text: this);
      texts = [token.value.trim()];
      _StringTypeInit(token, XTag.TEXT);
   }
   
   String toString(){
      return segment.toString(typename);
   }
}




class TArgs{
   List data;
   
   Iterable<TProp> get prop_accs =>
      data.where((arg) => arg is TProp)
         .map((arg) => arg);
   
   List<String> get vars =>
      List<String>.from(data.where((arg) => arg is Token)
         .map((arg) => arg.value)) ?? [];
   
   List<String> get idents =>
      vars + prop_accs.map((arg) => arg.root).toList();
   
   TArgs(this.data);
}

class TInvoke{
   Token<String> caller;
   TArgs         args;
   
   String       get caller_name => caller.value;
   List<String> get references =>
      [caller_name] +
      args.idents;
   
   TInvoke(this.caller, this.args);
}

class TProp{
   List<Token<String>> data;
   
   String get property => data.last.value;
   String get target   => data[data.length - 2].value;
   String get root     => data[0].value;
   
   TProp(this.data);
}





class BaseGrammarDefinition extends GrammarDefinition{
   Parser token(input) {
      if (input is String) {
         input = input.length == 1 ? char(input) : string(input);
      } else if (input is Function) {
         input = ref(input);
      }
      
      if (input is! Parser || input is TrimmingParser || input is TokenParser) {
         throw ArgumentError('Invalid token parser: $input');
      }
      return input.token().trim(ref(HIDDEN_STUFF));
   }
   
   LT()    => ref(token, '<');
   RT()    => ref(token, '>');
   LP()    => ref(token, '(');
   RP()    => ref(token, ')');
   LB()    => ref(token, '{');
   RB()    => ref(token, '}');
   LSB()    => ref(token, '[');
   RSB()    => ref(token, ']');
   EQ()    => ref(token, '=');
   COLON() => ref(token, ':');
   SLASH() => ref(token, '/');
   
   HIDDEN()       => ref(HIDDEN_STUFF).plus();
   WHITESPACE()   => whitespace();
   HIDDEN_STUFF() =>
      ref(WHITESPACE);
   
   STRING_CONTENT_DQ()  =>
      pattern('^\\"\n\r');
   
   STRING_CONTENT_SQ()  =>
      pattern("^\\'\n\r");
   
   DQ_STRING() =>
      char('"')
      & ref(STRING_CONTENT_DQ).star()
      & char('"');
   
   SQ_STRING() =>
      char("'")
      & ref(STRING_CONTENT_SQ).star()
      & char("'");

   Parser compassedByLR(Parser L, Parser R) =>
      L
         & R.neg().star().flatten().token()
            & R;
   
   Parser start() {
      return null;
   }
}
//@fmt:off
class BaseGrammarParser extends GrammarParser {
   String input;
   
   Result getErrorMessage(Result ret){
      if (!ret.isSuccess){
         var pos = ret.toPositionString().split(':').map((x) => int.parse(x));
         var line = input.split('\n')[pos.first -1];
         var indicator = List.filled(line.length-1, '-').join();
         var message = '\n$line\n${indicator}^ ${ret.message}';
         return ret.failure(message, pos.last);
      }
      return ret;
   }
   
   Result parse(String input) {
      var ret = super.parse(input);
      this.input = input;
      return getErrorMessage(ret);
   }
   
   BaseGrammarParser(BaseGrammarDefinition def) : super(def);
}




class XMLGrammarParser extends BaseGrammarParser {
   XMLGrammarParser() : super(XMLGrammarDefinition());
}

// arbitrary xml tag grammer definition
class XMLGrammarDefinition extends BaseGrammarDefinition {
   
   Parser varname() =>
      (letter() & pattern('a-zA-Z_0-9\-').star())
      .flatten().token();
      
   Parser tagname() =>
      ref(varname)
      .map((list){
         return XTag<String>.NameInit(list);
      });
   
   Parser attrname() =>
      (pattern('a-zA-Z_0-9\-:')).plus().flatten()
      /*(char(':').optional()
         & ref(varname))*/
      .token();
   
   Parser attrvalue() =>
      (ref(DQ_STRING) | ref(SQ_STRING))
      
      .flatten().token();
   
   Parser attr() =>
      (ref(attrname) & ref(EQ) & ref(attrvalue))
      
      .map((list) => [list[0], list[2]]);
   
   Parser attrs() =>
      (whitespace().star() & ref(attr) & whitespace().star()).plus()
      .map((lst){
         var ret = <List<Token<String>>>[];
         lst.forEach((at){
            //_log.log('parsing attrs: ${at.length} ${at[1][0]} ${at[1][1]}');
            ret.add( List<Token<String>>.from(at[1]));
         });
         return XTag<String>.AttrsInit(ret);
      });
   
   Parser start_tag() =>
      (ref(LT)
         & ref(tagname)
         & ref(attrs).optional()
            & ref(RT))
      
      .map((list){
         return XTag<XTag>.TagInit([list[1], list[2]] );
      });
   
   Parser self_tag() =>
      (ref(LT)
         & ref(tagname)
         & ref(attrs).optional()
            & char('/')
               & ref(RT))
      
      .map((list){
         return XTag<XTag>.TagInit(list);
      });
   
   Parser text_content() =>
      pattern('^<>').plus()
      
      .trim().flatten().token().map((list){
         return XTag.TextInit(list);
      });
   
   Parser end_tag() =>
      (ref(LT)
         & char('/')
            & ref(tagname)
               & ref(RT))
      
      .flatten().token();
   
   Parser element() =>
      (ref(start_tag)
         & ref(text_content).optional()
            & ref(end_tag)
      | ref(self_tag))
      
      .map((list){
         if      (list is List) return XTag.ElementInit([list[0], list[1]]);
         else if (list is XTag) return list;
         else                   throw  Exception('Uncaught Exception');
      });
   
   Parser node_content() =>
      (ref(text_content).optional()
         & (ref(element) | ref(node))
            & ref(text_content).optional())
      .map((list){
         List<XTag> text; XTag el_or_nd;
        
         for (var i = 0; i < list.length; ++i) {
            var lst = list[i];
            if (lst is XTag && (lst.typename == XTag.ELT || lst.typename == XTag.NODE))
               el_or_nd = lst;
            if (lst is XTag && lst.typename == XTag.TEXT) {
               text ??= [];
               text.add(lst);
            }
         }
         return [el_or_nd, text];
      });
   
   Parser node() =>
      (ref(start_tag)
         & ref(node_content).plus()
            & ref(end_tag))
      
      .map((list){
         XTag       tag     = list[0];
         List<List> content = List<List>.from(list[1]);
         return XTag.NodeInit(tag, content);
      });
   
   // -----------------------------------------------------------
   //                      U T I L S
   // -----------------------------------------------------------
   Parser head(Parser p) =>
      take(p, start: 0, num: p.children.length -1);
   
   Parser take(Parser p, {int start, int num}) =>
      p.castList().map((list) {
         return list.sublist(start, start + num);
      });
   
   // -----------------------------------------------------------
   //                      E N T R Y
   // -----------------------------------------------------------
   Parser xml() =>
      ref(node) | ref(element)  ;
   
   Parser start() {
      return ref(xml).end();
   }
}





//@fmt:off
class VueVariableParser extends BaseGrammarParser{
   Result  parse(String input){
      return super.parse(input);
   }
   VueVariableParser() : super(VueVariableGrammarDefinition());
}

class VueMustacheBlockParser extends BaseGrammarParser{
   Set<String> _references;
   
   Set<String>
   get references {
      if (_references != null) return _references;
      _referenceInit();
      return _references;
   }
   
   @nullable Iterable<String>
   getIdentsFromAttrs(XNode elt, List<String> scoped_vars) =>
      elt.attrs?.attrs?.keys?.where((attr_name) => !scoped_vars.contains(attr_name))?.whereType();
   
   
   @nullable Iterable<String>
   getIdentsFromScript(XNode elt, List<String> scoped_vars){
      return elt.text?.texts?.fold(<String>[], (initial, text){
         List<String> idents = List<String>.from(parse(text).value);
         return idents.where((txt) => !scoped_vars.contains(txt)).toList() + initial;
      });
   }
   
   travelElts(XNode elts, List<String> scoped_vars, Iterable<String> cb(XNode elt, List<String> scoped_vars)){
      if (elts.children.length == 0) return;
      elts.children.forEach((child){
         var _scoped_vars = cb(child, scoped_vars);
         travelElts(child, _scoped_vars, cb);
      });
   }
   
   _referenceInit(){
      var xml_parser  = XMLGrammarParser();
      var scoped_vars = <String>[];
      XTag nodes      = xml_parser.parse(input).value;
      
      @nullable Iterable<String>
      getScopedVars(XNode elt) {
         var scoped_elts = elt.attrs?.attrs?.entries?.where((e) => e.key == 'slot-scope' );
         return scoped_elts?.map((e) => e.value);
      }
      
      _references ??= Set();
      _log.log('referenceInit');
      
      travelElts(nodes.segment, scoped_vars, (XNode elt, List<String> s_vars){
         var vars  = getScopedVars(elt);
         if (vars != null)
            scoped_vars.addAll(vars);
         
         _log.info('forChild: $elt, ${elt.children}, ${elt.children.length} ');
         _log.info('scoped_vars: $scoped_vars');
         
         var attributes = getIdentsFromAttrs(elt, scoped_vars);
         var variables  = getIdentsFromScript(elt, scoped_vars);
         _log.info('  attr: ${attributes.toList()}');
         _log.info('  vars: $variables');
         
         if (variables != null)
            _references.addAll(variables);
         
         if (attributes != null)
            _references.addAll(attributes);
      });
   }
   
   Result parse(String input){
      return super.parse(input);
   }
   VueMustacheBlockParser() : super(VueMustacheBlockGrammarDefinition());
}



class VueVariableGrammarDefinition extends BaseGrammarDefinition{
   Parser DOLLAR() => ref(token, r'$');
   Parser VARS  () => (LETTER() & pattern('a-zA-Z_0-9').star()).flatten();
   Parser LETTER() => letter();
   Parser LBLOCK() => LB().times(2).flatten();
   Parser RBLOCK() => RB().times(2).flatten();
   
   Parser number() =>
      digit().plus().flatten();
   
   Parser arg() =>
      (number().flatten()
         | ref(DQ_STRING).flatten()
         | ref(SQ_STRING).flatten()
         | ref(variable));
   
   Parser args() =>
      ref(arg).separatedBy(ref(token, char(',')), includeSeparators: false)
      
      .map((list) => TArgs(list));
   
   Parser variable() =>
      (char(r'$').optional() & VARS()).flatten().token();
   
   Parser property_acc() =>
      ((variable() & char('.')).plus()  // [[t1, t2], [t1, t2], ...]
         & variable())                  // t
      
      .map((list){
         var ret = <Token<String>>[];
         var fore_part = list[0] as List<List> ;
         var rear_part = list[1] as Token<String>;
         for (var i = 0; i < fore_part.length; ++i) {
            var lst = fore_part[i];
            ret.add(lst[0]);
         }
         ret.add(rear_part);
         return TProp(ret);
      });
   
   Parser invoke() =>
      (ref(variable)
         & LP()
            & ref(args).optional()
               & RP())
   
      .map((list){
         var ident = list[0] as Token<String>;
         var args  = list.length == 4
               ? list[2]
               : null;
         return TInvoke(ident, args);
      });
   
   Parser nonIdentifier() =>
      ref(identifier).neg().flatten();
   
   Parser identifier() =>
      (ref(invoke) | ref(property_acc) | ref(variable));
   
   // -----------------------------------------------------------
   //                      U T I L S
   // -----------------------------------------------------------
   bool
   isOdd(int num) => num != 0 && ((num - 1) % 2 == 0);
   
   bool
   isEven(int num) => num != 0 && (num % 2 == 0);
   
   // -----------------------------------------------------------
   //                      E N T R Y
   // -----------------------------------------------------------
   Parser references() =>
      (ref(identifier) | ref(nonIdentifier) ).star()
      .map((lst){
         var props   = <String>[];
         var invokes = <String>[];
         var vars    = <String>[];
         
         lst.forEach((list){
            if (list is TProp){
               // prop, invoke
               props.add(list.root);
            } else if (list is TInvoke){
               invokes.addAll(list.references);
            } else if (list is Token){
               // variable
               vars.add(list.value);
            }
         });
         return props + invokes + vars;
      });
   Parser start() =>
      ref(references);
}

class VueMustacheBlockGrammarDefinition extends VueVariableGrammarDefinition{
   VueVariableParser variable_parser;
   
   
   
   Parser single_code_block() =>
      compassedByLR(LBLOCK(), RBLOCK())
      .map((list){
         if (list.length == 3) return list[1];
         return null;
      });
   
   Parser text_contentL() =>
         LBLOCK().neg().plus().flatten();
   
   Parser text_contentR() =>
         ((RBLOCK() | LBLOCK()).neg().plus()).flatten();
   
   Parser text_content() =>
      LBLOCK().neg().plus().flatten();
   
   Parser code_blocks() =>
      (ref(text_content) | ref(single_code_block)).star()
      .map((list){
         var ret = <Token<String>>[];
         list.forEach((match){
            if (match is Token){
               ret.add(match);
            }
         });
         return ret;
      });
   
   
   // -----------------------------------------------------------
   //                      E N T R Y
   // -----------------------------------------------------------
   Parser parsed_code() =>
      ref(code_blocks)
      .map((list){
         var ret = <String>[];
         var data = List<Token<String>>.from(list);
         ret = data.fold(<String>[], (initial, tok){
            return variable_parser.parse(tok.value).value + initial;
         });
         return ret.where((name) => !JSKEYWORDS.contains(name)).toSet();
      });
   
   Parser  start(){
      return ref(parsed_code);
   }
   
   VueMustacheBlockGrammarDefinition(){
      variable_parser = VueVariableParser();
   }
}





/*
class BaseVueTemplateParser{
   DocumentFragment  data;
   Set<String>       references;
   
   SettableParser _invoke        = undefined(); // resolve recursive referencing
   bool           _invoke_setted = false;
   SettableParser _node        = undefined(); // resolve recursive referencing
   bool           _node_setted = false;
   
   Parser get _dollar    => pattern(r'$');
   Parser get _dot       => pattern('.');
   Parser get _lp        => pattern('(').trim();  //(
   Parser get _rp        => pattern(')').trim();  //)
   Parser get _dq        => pattern('"');
   Parser get _sq        => pattern("'");
   Parser get _sep       => pattern(',').trim();
   Parser get _lt        => char('<').trim();
   Parser get _rt        => char('>').trim();
   // code block
   Parser get _code_lb  => pattern('{').times(2).trim();
   Parser get _code_rb  => pattern('}').times(2).trim();
   Parser get _within   => ((_code_rb.not() & any() & _code_lb.not()).pick(1)).plus().flatten();
   // variables
   Parser get variable  => (_dollar.optional() & letter() & pattern('a-zA-Z_0-9').star()).flatten();
   // propacc
   Parser get _target   => (variable & _dot).pick(0);
   Parser get propacc   => _target.plus() & variable ;
   // identifiers
   Parser get ident     => invoke | propacc | variable ;
   // invoke
   Parser get invoke {
      if (_invoke_setted == true) return _invoke;
      _invoke_setted = true;
      _invoke.set(
         variable & _lp & args.optional() & _rp
      );
      return _invoke;
   }
   // string
   Parser get _dq_text => (_dq.not() & any()).plus().flatten();
   Parser get _sq_text => (_sq.not() & any()).plus().flatten();
   Parser get sq_str   => (_sq & _sq_text & _sq).flatten();
   Parser get dq_str   => (_dq & _dq_text & _dq).flatten();
   // number
   Parser get number => (pattern('0-9.').plus()).flatten();
   // args
   Parser get _arg   => (number | dq_str | sq_str | ident);
   Parser get args   => _arg.separatedBy(_sep, includeSeparators: false); //arg & (sep & arg).pick(1).star() & sep.optional();
   // code
   Parser<List<Token>>
   get code_blocks {
      var code = (_code_lb & _within  & _code_rb).pick(1);
      var l = (code.not() & any()).plus();
      var r = (code.not() & any()).plus();
      return (l.optional() & code.token() & r.optional()).pick(1).plus().castList<Token>();
   }
   
   Iterable<String>
   getIdents(String code, List<String> scoped_vars){
      scoped_vars ??= [];
      return code.split(IDENT_SPLITER).map((name) {
         name = name.trim();
         var parsed_ident = ident.parse(name);
         if (parsed_ident.isSuccess){
            if (parsed_ident.value is List){
               var target = parsed_ident.value[0];
               return target[0];
            }; // property acc
            return parsed_ident.value;
         }
         return null;
      }).where((name)
            => name != null && !scoped_vars.contains(name) )
         .whereType();
   }
   
   BaseVueTemplateParser(this.data){
      referenceInit() ;
   }

   Set<String>
   getIdentsFromAttrs(Element elts, List<String> scoped_vars){
      Iterable<MapEntry<Object, String>>
      attrs = elts.attributes.entries.where((entry){
         var key = (entry.key as String);
         print('     key: $key, ${key.startsWith(':') || DIRECTIVES.contains(key)}');
         return !JSKEYWORDS.contains(key)
                && (key.startsWith(':') || DIRECTIVES.contains(key));
      }) ?? [];
      
      return attrs.fold<Set<String>>
         (Set<String>(), (initial, entry){
            initial.addAll(getIdents(entry.value, scoped_vars));
            return initial;
         });
   }
   
   Set<String>
   getIdentsFromScript(Element elt, List<String> scoped_vars){
      var ret     = Set<String>();
      var content = elt.text.trim();//.split(RegExp('[\n\r]+'))?.first; //fixme:
      var data    = code_blocks.parse(content);
      print('content: $content');
      
      String code;
      if (data.isSuccess){
         data.value.forEach((v){
            code = v.value;
            ret.addAll(getIdents(code, scoped_vars));
         });
      }
      return ret;
   }
   
   travelElts(Node elts, List<String> scoped_vars, Iterable<String> cb(Element elt, List<String> scoped_vars)){
      if (elts.children.length == 0) return;
      elts.children.forEach((child){
         var _scoped_vars = cb(child, scoped_vars);
         travelElts(child, _scoped_vars, cb);
      });
   }
   
   _addReference(Iterable<String> refs, Iterable<String> excludes){
      //references.addAll(refs.where((ref) => !excludes.contains(ref) ));
   }
   
   referenceInit(){
      references ??= Set();
      print('referenceInit: $data');
      
      Iterable<String>
      getScopedVars(Element elt){
         var scoped_elts = elt.attributes.entries.where((e) => e.key == 'slot-scope');
         return scoped_elts?.map((e) => e.value);
      }
      
      var scoped_vars = <String>[];
      
      travelElts(data, scoped_vars, (Element elt, List<String> s_vars){
         var vars  = getScopedVars(elt);
         if (vars != null)
            scoped_vars.addAll(vars);
         
         print('forChild: $elt, ${elt.children}, ${elt.children.length} ');
         print('scoped_vars: $scoped_vars');
         
         var attributes = getIdentsFromAttrs(elt, scoped_vars);
         var variables  = getIdentsFromScript(elt, scoped_vars);
         print('  attr: ${attributes.toList()}');
         print('  vars: $variables');
         
         if (variables != null)
            references.addAll(variables);
         
         if (attributes != null)
            references.addAll(attributes);
      });
   }
}*/

/*class BaseVueTemplateVariableParser{
   static const LB      = '{';
   static const RB      = '}';
   static const LP      = '(';
   static const RP      = ')';
   static const LS      = '[';
   static const RS      = ']';
   static const DOLLAR  = r'$';
   static const SEP     = ',';
   static const DOT     = '.';
   static const VAR     = 'a-zA-Z_0-9';
   static const NUM     = '0-9.';
   static const SQ      = "'";
   static const DQ      = '"';
   static const COLON   = ':';
   static const SCOLON  = ';';
   // ------------------------
   String lbound        = LB;
   String rbound        = RB;
   int    repeat        = 2;
   // ------------------------
   SettableParser _invoke        = undefined(); // resolve recursive referencing
   bool           _invoke_setted = false;
   // type infer
   bool isVar    (Token v)   => v.value is String;
   bool isPropAcc(Token v)   => v.value is List && !v.value.contains('(');
   bool isInvoke (Token v)   => v.value is List && v.value.contains('(');

   // simple token
   Parser get code_lb   => pattern(lbound).times(repeat).trim();
   Parser get code_rb   => pattern(rbound).times(repeat).trim();
   Parser get lp        => pattern(LP).trim();  //(
   Parser get rp        => pattern(RP).trim();  //)
   Parser get lb        => pattern(LB).trim();  //{
   Parser get rb        => pattern(RB).trim();  //}
   Parser get sep       => pattern(SEP).trim(); //,
   Parser get dollar    => pattern(DOLLAR);
   Parser get colon     => pattern(COLON);
   Parser get dq        => pattern(DQ);
   Parser get sq        => pattern(SQ);
   Parser get dot       => pattern(DOT);
   Parser get ls        => pattern(LS).trim();  //[
   Parser get rs        => pattern(RS).trim();  //]
   // variable
   Parser get variable  => (dollar.optional() & letter() & pattern(VAR).star()).flatten();
   // number
   Parser get number    => (pattern(NUM).plus()).flatten();
   // string
   Parser get dq_text   => (dq.not() & any()).plus().flatten();
   Parser get sq_text   => (sq.not() & any()).plus().flatten();
   Parser get sq_str    => (sq & sq_text & sq).flatten();
   Parser get dq_str    => (dq & dq_text & dq).flatten();
   // property access
   Parser get target    => (variable & dot).pick(0);
   Parser get propacc   => target.plus() & variable ;
   // invocation
   Parser get invoke {
      if (_invoke_setted == true) return _invoke;
      _invoke_setted = true;
      _invoke.set(
         variable & lp & args.optional() & rp
      );
      return _invoke;
   }
   // arg element and argList
   Parser get arg   => (number | dq_str | sq_str | ident);
   Parser get args  => arg.separatedBy(sep, includeSeparators: false); //arg & (sep & arg).pick(1).star() & sep.optional();
   // identifier
   Parser get ident => invoke | propacc | variable ;
   // expr todo: enhancement
   Parser get expr        => throw Exception('Not Implemented yet');
   Parser get assign_expr => throw Exception('Not Implemented yet');
   Parser get op_expr     => throw Exception('Not Implemented yet');
   Parser get ternary_expr=> throw Exception('Not Implemented yet');
   Parser get arrow       => string('=>');
   Parser get closure_expr => lp & args.optional() & rp & arrow & expr;
   // ternary
   // ...
   // condition
   // ...
   // list
   Parser get list      => (ls & args.optional() & rs).pick(1);
   // object
   Parser get olabel    => (variable & colon.trim()).pick(0);
   Parser get ovalue    => arg;
   Parser get opair     =>
      olabel
         & ovalue;
   Parser get opairs    => opair.separatedBy(sep, includeSeparators: false);
   Parser get object    => (lb & opairs.optional() & rb).pick(1);
   // code block
   Parser get before_block => (code_lb.not() & any() & code_rb.not()).plus();
   Parser get after_block  => (code_rb.not() & any() & code_lb.not()).plus();
   Parser get within_block => ((code_rb.not() & any() & code_lb.not()).pick(1)).plus().flatten();
   Parser get vue_block    => (code_lb & within_block  & code_rb).pick(1);
   // filters
   E
   filter<E extends Parser<List<Token>>> (Parser p, [E cb(E arg)]){
      var l = (p.not() & any()).plus();
      var r = (p.not() & any()).plus();
      cb ??= (arg) => arg;
      
      return cb((l.optional() & p.token() & r.optional()).pick(1).plus()
         .castList<Token>());
   }
   
   BaseVueTemplateVariableParser({this.lbound = LB, this.rbound = RB, this.repeat = 2});
}//@fmt:on

class VueTemplateVariableParser extends BaseVueTemplateVariableParser {
   String      template;
   Set<String> references;
   
   Parser<List<Token>>
   get filtered_code_blocks => filter(vue_block);
   
   List<String> _argListToIdents(List<String> args) {
      var result = args.map((arg) => ident.parse(arg)).where((res) => res.isSuccess);
      return List<String>.from(result.map((p) => p.value));
   }
   
   Set<String> getIdentifiers(String template) {
      var result = Set<String>();
      var idents = filter(ident).parse(template);
      idents.value.forEach((tok) {
         if (isVar(tok))
            result.add(tok.value);
         else if (isPropAcc(tok)) {
            List target = tok.value[0];
            result.add(target[0]);
         } else if (isInvoke(tok)) {
            var method_name = tok.value[0];
            var args = List<String>.from(tok.value[2]);
            var ident_args = _argListToIdents(args);
            result.add(method_name);
            result.addAll(ident_args);
         };
      });
      return result;
   }
   
   void _parseTemplate(String t) {
      template = t;
      references = getIdentifiers(template);
   }
   
   VueTemplateVariableParser({this.template}) : super() {
      if (template != null) _parseTemplate(template);
   }
}*/


@deprecated
class VueScriptGrammer extends GrammarParser {
   VueScriptGrammer() : super(VueScriptGrammerDefinition());
}
//@fmt:off
//untested: incompleted:
@deprecated
class VueScriptGrammerDefinition<E extends Parser> extends BaseGrammarDefinition {
   // -------------------------------------
   //             simple tokens
   // -------------------------------------
   NEWLINE()    => pattern('\n\r');
   LETTER()     => letter();
   WHITESPACE() => whitespace();
   CODE_L()     => char('{').times(2);
   CODE_R()     => char('}').times(2);
   
   // -----------------------------------------------------------------
   // Keyword definitions.
   // -----------------------------------------------------------------
   ASYNC()    => ref(token, _KWS.ASYNC);
   AWAIT()    => ref(token, _KWS.AWAIT);
   BREAK()    => ref(token, 'break');
   CASE()     => ref(token, 'case');
   CATCH()    => ref(token, 'catch');
   CONST()    => ref(token, 'const');
   CONSTRUCTOR()=> ref(token, 'constructor');
   CONTINUE() => ref(token, 'continue');
   DEFAULT()  => ref(token, 'default');
   DO()       => ref(token, 'do');
   ELSE()     => ref(token, 'else');
   FALSE()    => ref(token, 'false');
   FINALLY()  => ref(token, 'finally');
   FOR()      => ref(token, 'for');
   IF()       => ref(token, 'if');
   IN()       => ref(token, 'in');
   NEW()      => ref(token, 'new');
   NULL()     => ref(token, 'null');
   RETURN()   => ref(token, 'return');
   SUPER()    => ref(token, 'super');
   SWITCH()   => ref(token, 'switch');
   THIS()     => ref(token, 'this');
   THROW()    => ref(token, 'throw');
   TRUE()     => ref(token, 'true');
   TRY()      => ref(token, 'try');
   VAR()      => ref(token, 'var');
   LET()      => ref(token, 'let');
   VOID()     => ref(token, 'void');
   WHILE()    => ref(token, 'while');
   YIELD()    => ref(token, _KWS.YIELD);
   TERMINATE() => ref(token, ';');
   
   // Pseudo-keywords that should also be valid identifiers.
   CLASS()      => ref(token, 'class');
   EXPORTS()    => ref(token, 'exports');
   EXTENDS()    => ref(token, 'extends');
   IMPORT()     => ref(token, 'import');
   OF()         => ref(token, 'of');
   STATIC()     => ref(token, 'static');
   IS()         => ref(token, 'instanceof');
   FUNC()       => ref(token, 'function');
   ARROW()      => ref(token, '=>');
   
   GET() => ref(token, 'get');
   SET() => ref(token, 'set');
   Parser start() {
      return ref(compilationUnit).end();;
   }
   
   
   //@fmt:off
   compilationUnit() =>
      ref(topLevelDefinition).star()
      //& ref(importDirective).star()
         & ref(statements);
   
   //todo:
   // 1) import
   // 2) export
   // 3) yield
   // 4)
   /*importDirective() =>
      ref(IMPORT) &
      ref(STRING) &
      ref(DEFERRED).optional() &
      (ref(AS) & ref(identifier)).optional() &
      ((ref(SHOW) | ref(HIDE)) &
      ref(identifier).separatedBy(ref(token, ',')))
         .optional() &
      ref(token, ';') |
      ref(EXPORT) &
      ref(STRING) &
      ((ref(SHOW) | ref(HIDE)) &
      ref(identifier).separatedBy(ref(token, ',')))
         .optional() &
      ref(token, ';') |
      ref(PART) & ref(STRING) & ref(token, ';');*/
   
   topLevelDefinition() =>
      ref(classDefinitionJS)
      | ref(functionDeclarationJS)
      | ref(initializedVariableDeclaration);
   
   superclass() => ref(EXTENDS) & ref(type);
   
   classDefinitionJS() =>
      ref(CLASS)
         & ref(identifier)
         & ref(superclass).optional()
            & ref(token, '{')
            & ref(classMemberDefinitionJS).star()
               & ref(token, '}');
   
   classMemberDefinitionJS() =>
      ref(fieldDeclarationJS)
         & ref(token, ';') //a terminator is necessary
      | ref(constructorDeclarationJS)
         & ref(TERMINATE)
      | ref(methodDeclarationJS)
         & ref(TERMINATE);
   
   methodDeclarationJS() =>
      ref(STATIC).optional()
         & ref(getOrSet).optional()
         & ref(functionDeclarationJS) ;
   
   fieldDeclarationJS() =>
      ref(STATIC).optional()
         & ref(identifier())
            & (ref(token, '=')
            & ref(conditionalExpression)).optional();
   
   fieldInitializer() =>
      (ref(THIS) & ref(token, '.')).optional()
         & ref(identifier)
            & ref(token, '=')
               & ref(conditionalExpression);
   
   superCallOrFieldInitializer() =>
      ref(SUPER)
         & ref(arguments)
      | ref(SUPER)
         & ref(token, '.')
            & ref(identifier)
               & ref(arguments)
      | ref(fieldInitializer);
   
   constructorDeclarationJS() =>
      ref(CONSTRUCTOR)
         & ref(formalParameterListJS)
            & ref(functionBody);
   
   getOrSet() => ref(GET) | ref(SET);
   
   
   
   
   
   
   
   
   // note: followings cleared
   
   // async? get_set? method(){}
   functionDeclarationJSObj() =>
      ref(ASYNC).optional()
         & ref(getOrSet).optional()
         & ref(identifier)
            & ref(formalParameterListJS)
               & ref(block);
   
   functionDeclarationJS() =>
      ref(ASYNC).optional()
         & ref(FUNC)
            & ref(identifier).optional()
            & ref(formalParameterListJS)
               & ref(block);
   
   functionBody() =>
      ref(token, '=>')
         & ref(expression)
            & ref(TERMINATE)
      | ref(block);
   
   functionExpressionBody() =>
      ref(token, '=>')
         & ref(expression)
      | ref(block);
   
   functionExpressionJSObj() =>
      // ident (arg, ...) {}
      ref(identifier)
         & ref(formalParameterListJS)
            & ref(block)
      // (arg, ...) =>
      | ref(formalParameterListJS)
         & ref(token, '=>')
            & ref(expression);
   
   functionExpressionJS() =>
      // function ident? (arg, ...) {}
      ref(FUNC)
         & ref(identifier).optional()
            & ref(formalParameterListJS)
               & ref(block)
      // (arg, ...) =>
      | ref(formalParameterListJS)
         & ref(token, '=>')
            & ref(expression);
   
   
   
   
   
   
   // note: followings cleared
   formalParameterListJS() =>
      // ({a = 1, b = 2, ...})
      // (a = 1, b = 2, ...)
      // (a, b, c, ...)
      ref(token, '(')
         & ref(namedFormalParametersJS).optional()      // named
         & ref(token, ')')
      | ref(token, '(')
         & ref(normalFormalParameterJS).optional()
         & ref(normalFormalParameterTailJS).optional()  // normal
            & ref(token, ')');
   
   normalFormalParameterTailJS() =>
      ref(token, ',')
         & ref(defaultFormalParameterJS)
      | ref(token, ',')
         & ref(namedFormalParametersJS)
      | ref(token, ',')
         & ref(normalFormalParameterJS)
            & ref(normalFormalParameterTailJS).optional();
   
   normalFormalParameterJS() =>
      // (a, ...) | (a = 1 ...)
   ref(identifier)
   | ref(defaultFormalParameterJS);
   
   namedFormalParametersJS() =>
      ref(token, '{')
         & ref(namedFormatParameterJS)
            & (ref(token, ',') & ref(namedFormatParameterJS)).star()
            & ref(token, '}');
   
   namedFormatParameterJS() =>
      ref(identifier)
         & (ref(token, '=') & ref(expression)).optional();
   
   defaultFormalParameterJS() =>
      ref(normalFormalParameterJS)
         & (ref(token, '=') & ref(expression)).optional();
   
   
   
   
   
   
   
   //note: followings cleared, except somewhere tagged with refinement:
   
   // -------------------------------------------------------
   //       statement can be seen as terminated expression
   // -------------------------------------------------------
   // ident : {}
   // ident : var decl = value;
   // ident : break ident;
   // ident : continue ident;
   // ident : return target.ident;
   // ident : throw target.ident;
   // ident : target.ident + som;
   // ident : void FN() {}
   statement() =>
      ref(label).star()
         & ref(nonLabelledStatement);
   
   block() =>
      ref(token, '{')
         & ref(statements)
            & ref(token, '}');
   
   statements() =>
      ref(statement).star();
   
   nonLabelledStatement() =>
      ref(block)
      | ref(initializedVariableDeclaration)
         & TERMINATE()
      | ref(iterationStatement)
      | ref(selectionStatementJS)
      | ref(tryStatementJS)
      // break somewhere;
      | ref(BREAK)
         & ref(identifier).optional()
            & TERMINATE()
      // continue ident ;
      | ref(CONTINUE)
         & ref(identifier).optional()
            & TERMINATE()
      // return (some.expresion + another)?;
      | ref(RETURN)
         & ref(expression).optional()
            & TERMINATE()
      // throw (some.expression)? ;
      | ref(THROW)
         & ref(expression).optional()
            & TERMINATE()
      // (some.expresion + another.expression)?;
      | ref(expression).optional()
         & TERMINATE()
      | ref(functionDeclarationJS);
   
   returnType() => ref(VOID) | ref(type);
   
   iterationStatement() =>
      ref(WHILE)
         & ref(token, '(')
            & ref(expression)
               & ref(token, ')')
                  & ref(statement)
      | ref(DO)
         & ref(statement)
            & ref(WHILE)
               & ref(token, '(')
                  & ref(expression)
                     & ref(token, ')')
                        & TERMINATE()
      | ref(FOR)
         & ref(token, '(')
            & ref(forLoopParts)
               & ref(token, ')')
                  & ref(statement);
   
   forLoopParts() =>
      ref(forInitializerStatement)     //refinement:
         & ref(expression).optional()
         & ref(token, ';')
            & ref(expressionList).optional()
      | ref(declaredIdentifier)
         & ref(IN)
            & ref(expression)
      | ref(identifier)
         & ref(IN)
            & ref(expression)
      | ref(declaredIdentifier)
         & ref(OF)
            & ref(expression)
      | ref(identifier)
         & ref(OF)
            & ref(expression);
   
   forInitializerStatement() =>
      ref(initializedVariableDeclaration)
         & ref(token, ';')
      | ref(expression).optional()
         & ref(token, ';');
   
   
   elseIfStatement () =>
      ref(ELSE)
         & ref(ifStatement);
   
   elseStatement() =>
      ref(ELSE)
         & ref(statement);
   
   ifStatement() =>
      ref(IF)
         &  ref(token, '(')
            &  ref(expression)
               &  ref(token, ')')
                  &  ref(statement)
                     &  ref(elseIfStatement).optional()
                     &  ref(elseStatement).optional();
   
   selectionStatementJS() =>
      ref(ifStatement)
      | ref(SWITCH)
         & ref(token, '(')
            &  ref(expression)
               &  ref(token, ')')
                  &  ref(token, '{')
                     &  ref(switchCaseJS).star()
                     & ref(defaultCaseJS).optional()
                        & ref(token, '}');
   
   switchCaseJS() =>
      (ref(CASE)
         & ref(expression)
            & ref(token, ':')).plus()
         & ref(statements);
   
   defaultCaseJS() =>
      ref(DEFAULT)
         & ref(token, ':')
            & ref(statements);
   
   @deprecated
   selectionStatement() =>
      ref(ifStatement)
      | ref(SWITCH)
         & ref(token, '(')
            &  ref(expression)
               & ref(token, ')')
                  & ref(token, '{')
                     & ref(switchCase).star()
                     & ref(defaultCase).optional()
                        & ref(token, '}');
   
   @deprecated
   switchCase() =>
      ref(label).optional()
         & (ref(CASE)
            & ref(expression)
               & ref(token, ':')).plus()
            & ref(statements);
   
   @deprecated
   defaultCase() =>
      ref(label).optional()
      & ref(DEFAULT)
         & ref(token, ':')
            & ref(statements);
   
   tryStatementJS() =>
      ref(TRY)
         & ref(block)
            & (ref(catchPartJS).plus()
               & ref(finallyPart).optional()
            | ref(finallyPart));
   
   catchPartJS() =>
      ref(CATCH)
         & ref(token, '(')
            & ref(identifier)
               & ref(conditionalExpression).optional() //untested: refinement:
                  & ref(token, ')')
                     & ref(block);
   
   finallyPart() => ref(FINALLY) & ref(block);
   
   
   
   
   
   
   
   // note: followings cleared
   declaredIdentifier() =>
      // var ident
      ref(VAR)
         & ref(identifier)
      // let ident
      | ref(LET)
         & ref(identifier)
      // const ident
      | ref(CONST)
         & ref(identifier);
   
   initializedVariableDeclaration() =>
      // var|let|const ident = expr?
      // var|let|const ident = expr?, ...
      // var|let|const ident, ...
      ref(declaredIdentifier)
         & (ref(token, '=')
            & ref(expression)).optional()
         & (ref(token, ',')
            & ref(initializedIdentifier)).star();
   
   initializedIdentifierList() =>
      // ident, ...
      // ident = expr?, ...
      ref(initializedIdentifier)
         & (ref(token, ',') & ref(initializedIdentifier)).star();
   
   initializedIdentifier() =>
      // ident | ident = expr?
      ref(identifier)
         & (ref(token, '=') & ref(expression)).optional();
   
   identifier() => ref(token, ref(IDENTIFIER));
   
   
   
   
   
   
   
   
   
   
   propacc()    =>
      ref(identifier)
         & (ref(token, '.')
            & ref(identifier)).plus();
   
   qualified()  =>
      ref(identifier)
         & (ref(token, '.')
            & ref(identifier)).star();
   
   invoke() =>
      ref(qualified)
         & ref(arguments);
   
   label() =>
      ref(identifier)
         & ref(token, ':');
   
   arguments() =>
      ref(token, '(')
         & ref(argumentList).optional()
         & ref(token, ')');
   
   argumentList() => ref(argumentElement).separatedBy(ref(token, ','));
   
   argumentElement() =>
      (ref(label) & ref(expression))
      | ref(expression);
   
   // -----------------------------------------------
   // Selector ::
   //    | arguments             :: ... (arg)
   //    | assignableSelector    ::
   //       | propSelectorA          :: ... [expression]
   //       | propSelectorB          :: ... .select
   
   selector() =>
      ref(assignableSelector)
      | ref(arguments);
   
   assignableSelector() =>
      ref(token, '[')
         & ref(expression)
           & ref(token, ']')
      | ref(token, '.')
         & ref(identifier);
   
   // PostfixExpression ::
   // -------------------------------------------
   //    | assignable expression
   //       & ... ++
   //    | primary
   //       & ... [selector] | & ... .selector
   
   postfixExpression() =>
      ref(assignableExpression)
         & ref(postfixOperator)
      | ref(primary)
         & ref(selector).star();
   
   // unaryExpression ::
   // -------------------------------------------
   //    | postfix_expresstion++
   //    | ++, --
   //       & ... [selector], ... .selector
   
   unaryExpression() =>
      ref(postfixExpression)
      | ref(prefixOperator)
         & ref(unaryExpression)
      | ref(incrementOperator)
         & ref(assignableExpression);
   
   // multiplicativeExpression ::
   // --------------------------------------------
   //    | unaryExpression
   //       & ... *, /, %
   //          & ... unaryExpression
   multiplicativeExpression() =>
      ref(unaryExpression)
         & (ref(multiplicativeOperator) & ref(unaryExpression)).star();
   
   additiveExpression() =>
      ref(multiplicativeExpression)
         & (ref(additiveOperator) & ref(multiplicativeExpression)).star();
   
   shiftExpression() =>
      ref(additiveExpression)
         & (ref(shiftOperator) & ref(additiveExpression)).star();
   
   relationalExpression() =>
      ref(shiftExpression)
         & (
            ref(qualified)
            & ref(instanceof)
            & ref(type)
            | ref(relationalOperator)
            & ref(shiftExpression)
         ).optional();
   
   equalityExpression() =>
      ref(relationalExpression)
         & (ref(equalityOperator) & ref(relationalExpression)).optional() ;
   
   
   bitwiseAndExpression() =>
      ref(equalityExpression)
         & (ref(token, '&') & ref(equalityExpression)).star()  ;
   
   bitwiseXorExpression() =>
      ref(bitwiseAndExpression)
         & (ref(token, '^') & ref(bitwiseAndExpression)).star() ;
   
   bitwiseOrExpression() =>
      ref(bitwiseXorExpression)
         & (ref(token, '|')
            & ref(bitwiseXorExpression)).star()
      | ref(SUPER)
         & (ref(token, '|')
            & ref(bitwiseXorExpression)).plus();
   
   logicalAndExpression() =>
      ref(bitwiseOrExpression)
         & (ref(token, '&&') & ref(bitwiseOrExpression)).star();
   
   logicalOrExpression() =>
      ref(logicalAndExpression)
         & (ref(token, '||') & ref(logicalAndExpression)).star();
   
   
   // -------------------------------------
   // Expression        ::
   //    & assignableExpression     ::
   //    & assignmentOperator       ::
   //    & Expression               ::
   //       Expression
   //       | conditionalExpression :: ? Expression : Expression
   
   expression() =>
      ref(assignableExpression)
         & ref(assignmentOperator)
            & ref(expression)
      | ref(conditionalExpression);
   
   expressionList() => ref(expression).separatedBy(ref(token, ','));
   
   conditionalExpression() =>
      // all conditional expression
      ref(logicalOrExpression)
      // ternary expression
      & (
         ref(token, '?')
         & ref(expression)
         & ref(token, ':')
         & ref(expression)
      ).optional();
      
   // ---------------------------------------------------
   // assignableExpression :: primary (args)* assignable+
   //    & primary
   //       & args and assignable
   //          args               :: ... (arg1, ...argN)(...
   //          assignable         :: ... [selector] | ... .selector
   //    | assignable      :: ... [selector] | ... .selector
   //    | identifier      :: ... ident
   assignableExpression() =>
      ref(primary)
         & (ref(arguments).star() & ref(assignableSelector)).plus()
      | ref(assignableSelector)
      | ref(identifier);
   
   assignmentOperator() =>
      ref(token, '=')
      | ref(token, '*=')
      | ref(token, '/=')
      | ref(token, '%=')
      | ref(token, '+=')
      | ref(token, '-=');
   
   equalityOperator() =>
      ref(token, '===')
      | ref(token, '!==')
      | ref(token, '==')
      | ref(token, '!=');
   
   relationalOperator() =>
      ref(token, '>=')
      | ref(token, '>')
      | ref(token, '<=')
      | ref(token, '<');
   
   additiveOperator() =>
      ref(token, '+')
      | ref(token, '-');
   
   incrementOperator() =>
      ref(token, '++')
      | ref(token, '--');
   
   shiftOperator() =>
      ref(token, '<<')
      | ref(token, '>>>')
      | ref(token, '>>');
   
   instanceof() =>
      ref(IS) ;
   
   multiplicativeOperator() =>
      ref(token, '*')
      | ref(token, '/')
      | ref(token, '%')
      | ref(token, '~/');
   
   prefixOperator() =>
      ref(additiveOperator)
      | ref(negateOperator);
   
   negateOperator() =>
      ref(token, '!')
      | ref(token, '~');
   
   postfixOperator() => ref(incrementOperator);
   
   type() =>
      ref(qualified);
   
   // Primary  ::
   // ---------------------------------------------------
   //    This
   //       & ... [propname] | ... .propname
   //          & [a, b, ...n] | {a:a, b :b, ... n: n}
   //    | new
   //       & ... type<TypeArg>
   //          & ... .ident?
   //             & ... (a, b, ...n)
   //    |
   primary() =>
      ref(THIS)
         & ref(assignableSelector)
            & ref(compoundLiteral)
      | ref(NEW)
         & ref(type)
            & (ref(token, '.') & ref(identifier)).optional()
               & ref(arguments)
      | ref(functionExpressionJS)
      | ref(expressionInParentheses)
      | ref(literal)
      | ref(identifier);
   
   expressionInParentheses() =>
      ref(token, '(')
         & ref(expression)
            & ref(token, ')');
   
   literal() => ref(token,
      ref(NULL)
      | ref(TRUE)
      | ref(FALSE)
      | ref(HEX_NUMBER)
      | ref(NUMBER)
      | ref(STRING));
   
   compoundLiteral() => ref(listLiteral) | ref(mapLiteral);
   
   listLiteral() =>
      ref(token, '[')
         & (ref(expressionList)
            & ref(token, ',').optional() ).optional()
         & ref(token, ']');
   
   labelValuePairs() =>
      ref(mapLiteralEntry)
         & (ref(token, ',')
            & ref(mapLiteralEntry)).star()
         & ref(token, ',').optional();
   
   mapLiteral() =>
      ref(token, '{')
         & labelValuePairs().optional()
            & ref(token, '}');
   
   mapLiteralEntry() =>
      ref(STRING)
      | ref(identifier)
         & ref(token, ':')
            & ref(expression)
      | ref(functionDeclarationJSObj);
   
   
   // --------------------------------------
   //              identifiers
   // --------------------------------------
   
   IDENTIFIER_START_NO_DOLLAR() =>
      ref(LETTER)
      | char('_');
   
   IDENTIFIER_START() =>
      ref(IDENTIFIER_START_NO_DOLLAR)
      | char('\$');
   
   IDENTIFIER_PART()  =>
      ref(IDENTIFIER_START)
      | ref(DIGIT);
   
   IDENTIFIER() =>
      ref(IDENTIFIER_START)
         & ref(IDENTIFIER_PART).star();
   
   STRING() =>
      DQ_STRING()
      | SQ_STRING()
      | TMP_STRING();
   
   STRING_CONTENT_TMP() =>
      pattern("^\\`\n\r")
      | char('\\')
         & NEWLINE();
   
   TMP_STRING() =>
      char('`')
         & ref(STRING_CONTENT_DQ).star()
         & char('`');
   
   STRING_CONTENT_DQ()  =>
      pattern('^\\"\n\r')
      | char('\\')
         & NEWLINE();
   
   STRING_CONTENT_SQ()  =>
      pattern("^\\'\n\r")
      | char('\\')
      & NEWLINE();
   
   DQ_STRING() =>
      char('"')
         & ref(STRING_CONTENT_DQ).star()
         & char('"');
   
   SQ_STRING() =>
      char("'")
         & ref(STRING_CONTENT_SQ).star()
         & char("'");
   
   TEMPLATE_CONTENT() =>
      ref(CODE_L).not()
         & ref(CODE_R).not();
   
   TEMPLATE_BLOCK() =>
      ref(CODE_L)
         & ref(TEMPLATE_CONTENT()).star()
         & ref(CODE_R) ;
   
   // --------------------------------------
   //                 number
   // --------------------------------------
   HEX_NUMBER() =>
      string('0x')
         & ref(HEX_DIGIT).plus()
      | string('0X')
         & ref(HEX_DIGIT).plus();
   
   NUMBER() =>
      ref(DIGIT).plus() //123
         & ref(NUMBER_OPT_FRACTIONAL_PART) //.123?
            & ref(EXPONENT).optional() //(E+?123)?
               & ref(NUMBER_OPT_ILLEGAL_END)
      | char('.')
         & ref(DIGIT).plus()
            & ref(EXPONENT).optional()
            & ref(NUMBER_OPT_ILLEGAL_END);
   
   HEX_DIGIT() => pattern('0-9a-fA-F');
   DIGIT()     => digit();
   EXPONENT()  =>
      pattern('eE')
         & pattern('+-').optional()
         & ref(DIGIT).plus();
   
   NUMBER_OPT_FRACTIONAL_PART() =>
      char('.')
         & ref(DIGIT).plus()
      | epsilon();
   
   NUMBER_OPT_ILLEGAL_END() => epsilon();
   
   // -----------------------------------------------------------------
   // Whitespace and comments.
   // -----------------------------------------------------------------
   HIDDEN() => ref(HIDDEN_STUFF).plus();
   
   HIDDEN_STUFF() =>
      ref(WHITESPACE)
      | ref(SINGLE_LINE_COMMENT)
      | ref(MULTI_LINE_COMMENT);
   
   SINGLE_LINE_COMMENT() =>
      string('//')
         & ref(NEWLINE).neg().star()
            & ref(NEWLINE).optional();
   
   MULTI_LINE_COMMENT() =>
      string('/*')
         & (ref(MULTI_LINE_COMMENT) | string('*/').neg()).star()
         & string('*/');
   
}