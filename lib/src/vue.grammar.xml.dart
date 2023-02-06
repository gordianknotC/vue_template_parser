import 'package:dart_common/dart_common.dart';
import 'package:petitparser/petitparser.dart';
import 'package:vue_template_parser/src/vue.grammar.base.dart';
import 'package:vue_template_parser/src/vue.tokens.dart';
import '../src/ast.utils.dart';


final _log = print;





//@fmt:off
class XMLGrammarParser extends BaseGrammarParser {
  XMLGrammarParser() : super(XMLGrammarDefinition());
}

// arbitrary xml tag grammer definition
class XMLGrammarDefinition extends BaseGrammarDefinition {
  Parser varname() =>
      (letter() & pattern('a-zA-Z_0-9\-').star()).flatten().token();

  Parser tagname() => ref(varname).map((list) {
        return XTag<String>.NameInit(list);
      });

  Parser attrname() => (pattern('a-zA-Z_0-9\-:'))
      .plus()
      .flatten()
      /*(char(':').optional()
         & ref(varname))*/
      .token();

  Parser attrvalue() => (ref(DQ_STRING) | ref(SQ_STRING)).flatten().token();

  Parser attr() => (ref(attrname) & ref(EQ) & ref(attrvalue))
      .map((list) => [list[0], list[2]]);

  Parser attrs() =>
      (whitespace().star() & ref(attr) & whitespace().star()).plus().map((lst) {
        var ret = <List<Token<String>>>[];
        lst.forEach((at) {
          //_log.log('parsing attrs: ${at.length} ${at[1][0]} ${at[1][1]}');
          ret.add(List<Token<String>>.from(at[1]));
        });
        return XTag<String>.AttrsInit(ret);
      });

  Parser start_tag() =>
      (ref(LT) & ref(tagname) & ref(attrs).optional() & ref(RT)).map((list) {
        return XTag<XTag>.TagInit([list[1], list[2]]);
      });

  Parser self_tag() =>
      (ref(LT) & ref(tagname) & ref(attrs).optional() & char('/') & ref(RT))
          .map((list) {
        return XTag<XTag>.TagInit(list);
      });

  Parser text_content() =>
      pattern('^<>').plus().trim().flatten().token().map((list) {
        return XTag.TextInit(list);
      });

  Parser end_tag() =>
      (ref(LT) & char('/') & ref(tagname) & ref(RT)).flatten().token();

  Parser element() =>
      (ref(start_tag) & ref(text_content).optional() & ref(end_tag) |
              ref(self_tag))
          .map((list) {
        if (list is List)
          return XTag.ElementInit([list[0], list[1]]);
        else if (list is XTag)
          return list;
        else
          throw Exception('Uncaught Exception');
      });

  Parser node_content() => (ref(text_content).optional() &
              (ref(element) | ref(node)) &
              ref(text_content).optional())
          .map((list) {
        List<XTag> text;
        XTag el_or_nd;

        for (var i = 0; i < list.length; ++i) {
          var lst = list[i];
          if (lst is XTag &&
              (lst.typename == XTag.ELT || lst.typename == XTag.NODE))
            el_or_nd = lst;
          if (lst is XTag && lst.typename == XTag.TEXT) {
            text ??= [];
            text.add(lst);
          }
        }
        return [el_or_nd, text];
      });

  Parser node() =>
      (ref(start_tag) & ref(node_content).plus() & ref(end_tag)).map((list) {
        XTag tag = list[0];
        List<List> content = List<List>.from(list[1]);
        return XTag.NodeInit(tag, content);
      });

  // -----------------------------------------------------------
  //                      U T I L S
  // -----------------------------------------------------------
  Parser head(Parser p) => take(p, start: 0, num: p.children.length - 1);

  Parser take(Parser p, {int start, int num}) => p.castList().map((list) {
        return list.sublist(start, start + num);
      });

  // -----------------------------------------------------------
  //                      E N T R Y
  // -----------------------------------------------------------
  Parser xml() => ref(node) | ref(element);

  Parser start() {
    return ref(xml).end();
  }
}
