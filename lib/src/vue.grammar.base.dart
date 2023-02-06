import 'package:dart_common/dart_common.dart';
import 'package:petitparser/petitparser.dart';
import '../src/ast.utils.dart';


final _log = print;




class BaseGrammarDefinition extends GrammarDefinition {
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

  LT() => ref(token, '<');

  RT() => ref(token, '>');

  LP() => ref(token, '(');

  RP() => ref(token, ')');

  LB() => ref(token, '{');

  RB() => ref(token, '}');

  LSB() => ref(token, '[');

  RSB() => ref(token, ']');

  EQ() => ref(token, '=');

  COLON() => ref(token, ':');

  SLASH() => ref(token, '/');

  HIDDEN() => ref(HIDDEN_STUFF).plus();

  WHITESPACE() => whitespace();

  HIDDEN_STUFF() => ref(WHITESPACE);

  STRING_CONTENT_DQ() => pattern('^\\"\n\r');

  STRING_CONTENT_SQ() => pattern("^\\'\n\r");

  DQ_STRING() => char('"') & ref(STRING_CONTENT_DQ).star() & char('"');

  SQ_STRING() => char("'") & ref(STRING_CONTENT_SQ).star() & char("'");

  Parser compassedByLR(Parser L, Parser R) =>
      L & R.neg().star().flatten().token() & R;

  Parser start() {
    return null;
  }
}

//@fmt:off
class BaseGrammarParser extends GrammarParser {
  String input;

  Result getErrorMessage(Result ret) {
    if (!ret.isSuccess) {
      var pos = ret.toPositionString().split(':').map((x) => int.parse(x));
      var line = input.split('\n')[pos.first - 1];
      var indicator = List.filled(line.length - 1, '-').join();
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
