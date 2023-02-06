import 'package:dart_common/dart_common.dart';
import 'package:petitparser/petitparser.dart';
import 'package:vue_template_parser/src/vue.grammar.variable.dart';
import '../src/ast.utils.dart';
import 'package:vue_template_parser/src/vue.tokens.dart';

import '../vue_template_parser.dart';


final _log = print;



class VueMustacheBlockGrammarDefinition extends VueVariableGrammarDefinition {
  VueVariableParser variable_parser;

  Parser single_code_block() => compassedByLR(LBLOCK(), RBLOCK()).map((list) {
        if (list.length == 3) return list[1];
        return null;
      });

  Parser text_contentL() => LBLOCK().neg().plus().flatten();

  Parser text_contentR() => ((RBLOCK() | LBLOCK()).neg().plus()).flatten();

  Parser text_content() => LBLOCK().neg().plus().flatten();

  Parser code_blocks() =>
      (ref(text_content) | ref(single_code_block)).star().map((list) {
        var ret = <Token<String>>[];
        list.forEach((match) {
          if (match is Token) {
            ret.add(match);
          }
        });
        return ret;
      });

  // -----------------------------------------------------------
  //                      E N T R Y
  // -----------------------------------------------------------
  Parser parsed_code() => ref(code_blocks).map((list) {
        var ret = <String>[];
        var data = List<Token<String>>.from(list);
        ret = data.fold(<String>[], (initial, tok) {
          return variable_parser.parse(tok.value).value + initial;
        });
        return ret.where((name) => !JS_KW_ARR.contains(name)).toSet();
      });

  Parser start() {
    return ref(parsed_code);
  }

  VueMustacheBlockGrammarDefinition() {
    variable_parser = VueVariableParser();
  }
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
    _log('referenceInit');

    travelElts(nodes.segment, scoped_vars, (XNode elt, List<String> s_vars){
      var vars  = getScopedVars(elt);
      if (vars != null)
        scoped_vars.addAll(vars);

      _log('forChild: $elt, ${elt.children}, ${elt.children.length} ');
      _log('scoped_vars: $scoped_vars');

      var attributes = getIdentsFromAttrs(elt, scoped_vars);
      var variables  = getIdentsFromScript(elt, scoped_vars);
      _log('  attr: ${attributes.toList()}');
      _log('  vars: $variables');

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

