import 'package:petitparser/petitparser.dart';
import 'package:vue_template_parser/src/vue.grammar.base.dart';
import 'package:vue_template_parser/src/vue.tokens.dart';

final _log = print;


class VueVariableParser extends BaseGrammarParser {
  Result parse(String input) {
    return super.parse(input);
  }

  VueVariableParser() : super(VueVariableGrammarDefinition());
}

class VueVariableGrammarDefinition extends BaseGrammarDefinition {
  Parser DOLLAR() => ref(token, r'$');

  Parser VARS() => (LETTER() & pattern('a-zA-Z_0-9').star()).flatten();

  Parser LETTER() => letter();

  Parser LBLOCK() => LB().times(2).flatten();

  Parser RBLOCK() => RB().times(2).flatten();

  Parser number() => digit().plus().flatten();

  Parser arg() => (number().flatten() |
      ref(DQ_STRING).flatten() |
      ref(SQ_STRING).flatten() |
      ref(variable));

  Parser args() => ref(arg)
      .separatedBy(ref(token, char(',')), includeSeparators: false)
      .map((list) => TArgs(list));

  Parser variable() => (char(r'$').optional() & VARS()).flatten().token();

  Parser property_acc() =>
      ((variable() & char('.')).plus() // [[t1, t2], [t1, t2], ...]
              &
              variable()) // t

          .map((list) {
        var ret = <Token<String>>[];
        var fore_part = list[0] as List<List>;
        var rear_part = list[1] as Token<String>;
        for (var i = 0; i < fore_part.length; ++i) {
          var lst = fore_part[i];
          ret.add(lst[0]);
        }
        ret.add(rear_part);
        return TProp(ret);
      });

  Parser invoke() =>
      (ref(variable) & LP() & ref(args).optional() & RP()).map((list) {
        var ident = list[0] as Token<String>;
        var args = list.length == 4 ? list[2] : null;
        return TInvoke(ident, args);
      });

  Parser nonIdentifier() => ref(identifier).neg().flatten();

  Parser identifier() => (ref(invoke) | ref(property_acc) | ref(variable));

  // -----------------------------------------------------------
  //                      U T I L S
  // -----------------------------------------------------------
  bool isOdd(int num) => num != 0 && ((num - 1) % 2 == 0);

  bool isEven(int num) => num != 0 && (num % 2 == 0);

  // -----------------------------------------------------------
  //                      E N T R Y
  // -----------------------------------------------------------
  Parser references() =>
      (ref(identifier) | ref(nonIdentifier)).star().map((lst) {
        var props = <String>[];
        var invokes = <String>[];
        var vars = <String>[];

        lst.forEach((list) {
          if (list is TProp) {
            // prop, invoke
            props.add(list.root);
          } else if (list is TInvoke) {
            invokes.addAll(list.references);
          } else if (list is Token) {
            // variable
            vars.add(list.value);
          }
        });
        return props + invokes + vars;
      });

  Parser start() => ref(references);
}
