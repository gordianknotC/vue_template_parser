import 'package:dart_common/dart_common.dart';
import 'package:petitparser/petitparser.dart';
import 'package:vue_template_parser/src/vue.grammar.base.dart';
import '../src/ast.utils.dart';
import 'package:vue_template_parser/src/vue.tokens.dart';


final _log = print;




@deprecated
class VueScriptGrammer extends GrammarParser {
  VueScriptGrammer() : super(VueScriptGrammerDefinition());
}

//@fmt:off
//untested: incompleted:
@deprecated
class VueScriptGrammerDefinition<E extends Parser>
    extends BaseGrammarDefinition {
  // -------------------------------------
  //             simple tokens
  // -------------------------------------
  NEWLINE() => pattern('\n\r');

  LETTER() => letter();

  WHITESPACE() => whitespace();

  CODE_L() => char('{').times(2);

  CODE_R() => char('}').times(2);

  // -----------------------------------------------------------------
  // Keyword definitions.
  // -----------------------------------------------------------------
  ASYNC() => ref(token, JSKeywords.ASYNC);

  AWAIT() => ref(token, JSKeywords.AWAIT);

  BREAK() => ref(token, 'break');

  CASE() => ref(token, 'case');

  CATCH() => ref(token, 'catch');

  CONST() => ref(token, 'const');

  CONSTRUCTOR() => ref(token, 'constructor');

  CONTINUE() => ref(token, 'continue');

  DEFAULT() => ref(token, 'default');

  DO() => ref(token, 'do');

  ELSE() => ref(token, 'else');

  FALSE() => ref(token, 'false');

  FINALLY() => ref(token, 'finally');

  FOR() => ref(token, 'for');

  IF() => ref(token, 'if');

  IN() => ref(token, 'in');

  NEW() => ref(token, 'new');

  NULL() => ref(token, 'null');

  RETURN() => ref(token, 'return');

  SUPER() => ref(token, 'super');

  SWITCH() => ref(token, 'switch');

  THIS() => ref(token, 'this');

  THROW() => ref(token, 'throw');

  TRUE() => ref(token, 'true');

  TRY() => ref(token, 'try');

  VAR() => ref(token, 'var');

  LET() => ref(token, 'let');

  VOID() => ref(token, 'void');

  WHILE() => ref(token, 'while');

  YIELD() => ref(token, JSKeywords.YIELD);

  TERMINATE() => ref(token, ';');

  // Pseudo-keywords that should also be valid identifiers.
  CLASS() => ref(token, 'class');

  EXPORTS() => ref(token, 'exports');

  EXTENDS() => ref(token, 'extends');

  IMPORT() => ref(token, 'import');

  OF() => ref(token, 'of');

  STATIC() => ref(token, 'static');

  IS() => ref(token, 'instanceof');

  FUNC() => ref(token, 'function');

  ARROW() => ref(token, '=>');

  GET() => ref(token, 'get');

  SET() => ref(token, 'set');

  Parser start() {
    return ref(compilationUnit).end();
    ;
  }

  //@fmt:off
  compilationUnit() =>
      ref(topLevelDefinition).star()
      //& ref(importDirective).star()
      &
      ref(statements);

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
      ref(classDefinitionJS) |
      ref(functionDeclarationJS) |
      ref(initializedVariableDeclaration);

  superclass() => ref(EXTENDS) & ref(type);

  classDefinitionJS() =>
      ref(CLASS) &
      ref(identifier) &
      ref(superclass).optional() &
      ref(token, '{') &
      ref(classMemberDefinitionJS).star() &
      ref(token, '}');

  classMemberDefinitionJS() =>
      ref(fieldDeclarationJS) & ref(token, ';') //a terminator is necessary
      |
      ref(constructorDeclarationJS) & ref(TERMINATE) |
      ref(methodDeclarationJS) & ref(TERMINATE);

  methodDeclarationJS() =>
      ref(STATIC).optional() &
      ref(getOrSet).optional() &
      ref(functionDeclarationJS);

  fieldDeclarationJS() =>
      ref(STATIC).optional() &
      ref(identifier()) &
      (ref(token, '=') & ref(conditionalExpression)).optional();

  fieldInitializer() =>
      (ref(THIS) & ref(token, '.')).optional() &
      ref(identifier) &
      ref(token, '=') &
      ref(conditionalExpression);

  superCallOrFieldInitializer() =>
      ref(SUPER) & ref(arguments) |
      ref(SUPER) & ref(token, '.') & ref(identifier) & ref(arguments) |
      ref(fieldInitializer);

  constructorDeclarationJS() =>
      ref(CONSTRUCTOR) & ref(formalParameterListJS) & ref(functionBody);

  getOrSet() => ref(GET) | ref(SET);

  // note: followings cleared

  // async? get_set? method(){}
  functionDeclarationJSObj() =>
      ref(ASYNC).optional() &
      ref(getOrSet).optional() &
      ref(identifier) &
      ref(formalParameterListJS) &
      ref(block);

  functionDeclarationJS() =>
      ref(ASYNC).optional() &
      ref(FUNC) &
      ref(identifier).optional() &
      ref(formalParameterListJS) &
      ref(block);

  functionBody() =>
      ref(token, '=>') & ref(expression) & ref(TERMINATE) | ref(block);

  functionExpressionBody() => ref(token, '=>') & ref(expression) | ref(block);

  functionExpressionJSObj() =>
      // ident (arg, ...) {}
      ref(identifier) & ref(formalParameterListJS) & ref(block)
      // (arg, ...) =>
      |
      ref(formalParameterListJS) & ref(token, '=>') & ref(expression);

  functionExpressionJS() =>
      // function ident? (arg, ...) {}
      ref(FUNC) &
          ref(identifier).optional() &
          ref(formalParameterListJS) &
          ref(block)
      // (arg, ...) =>
      |
      ref(formalParameterListJS) & ref(token, '=>') & ref(expression);

  // note: followings cleared
  formalParameterListJS() =>
      // ({a = 1, b = 2, ...})
      // (a = 1, b = 2, ...)
      // (a, b, c, ...)
      ref(token, '(') &
          ref(namedFormalParametersJS).optional() // named
          &
          ref(token, ')') |
      ref(token, '(') &
          ref(normalFormalParameterJS).optional() &
          ref(normalFormalParameterTailJS).optional() // normal
          &
          ref(token, ')');

  normalFormalParameterTailJS() =>
      ref(token, ',') & ref(defaultFormalParameterJS) |
      ref(token, ',') & ref(namedFormalParametersJS) |
      ref(token, ',') &
          ref(normalFormalParameterJS) &
          ref(normalFormalParameterTailJS).optional();

  normalFormalParameterJS() =>
      // (a, ...) | (a = 1 ...)
      ref(identifier) | ref(defaultFormalParameterJS);

  namedFormalParametersJS() =>
      ref(token, '{') &
      ref(namedFormatParameterJS) &
      (ref(token, ',') & ref(namedFormatParameterJS)).star() &
      ref(token, '}');

  namedFormatParameterJS() =>
      ref(identifier) & (ref(token, '=') & ref(expression)).optional();

  defaultFormalParameterJS() =>
      ref(normalFormalParameterJS) &
      (ref(token, '=') & ref(expression)).optional();

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
  statement() => ref(label).star() & ref(nonLabelledStatement);

  block() => ref(token, '{') & ref(statements) & ref(token, '}');

  statements() => ref(statement).star();

  nonLabelledStatement() =>
      ref(block) |
      ref(initializedVariableDeclaration) & TERMINATE() |
      ref(iterationStatement) |
      ref(selectionStatementJS) |
      ref(tryStatementJS)
      // break somewhere;
      |
      ref(BREAK) & ref(identifier).optional() & TERMINATE()
      // continue ident ;
      |
      ref(CONTINUE) & ref(identifier).optional() & TERMINATE()
      // return (some.expresion + another)?;
      |
      ref(RETURN) & ref(expression).optional() & TERMINATE()
      // throw (some.expression)? ;
      |
      ref(THROW) & ref(expression).optional() & TERMINATE()
      // (some.expresion + another.expression)?;
      |
      ref(expression).optional() & TERMINATE() |
      ref(functionDeclarationJS);

  returnType() => ref(VOID) | ref(type);

  iterationStatement() =>
      ref(WHILE) &
          ref(token, '(') &
          ref(expression) &
          ref(token, ')') &
          ref(statement) |
      ref(DO) &
          ref(statement) &
          ref(WHILE) &
          ref(token, '(') &
          ref(expression) &
          ref(token, ')') &
          TERMINATE() |
      ref(FOR) &
          ref(token, '(') &
          ref(forLoopParts) &
          ref(token, ')') &
          ref(statement);

  forLoopParts() =>
      ref(forInitializerStatement) //refinement:
          &
          ref(expression).optional() &
          ref(token, ';') &
          ref(expressionList).optional() |
      ref(declaredIdentifier) & ref(IN) & ref(expression) |
      ref(identifier) & ref(IN) & ref(expression) |
      ref(declaredIdentifier) & ref(OF) & ref(expression) |
      ref(identifier) & ref(OF) & ref(expression);

  forInitializerStatement() =>
      ref(initializedVariableDeclaration) & ref(token, ';') |
      ref(expression).optional() & ref(token, ';');

  elseIfStatement() => ref(ELSE) & ref(ifStatement);

  elseStatement() => ref(ELSE) & ref(statement);

  ifStatement() =>
      ref(IF) &
      ref(token, '(') &
      ref(expression) &
      ref(token, ')') &
      ref(statement) &
      ref(elseIfStatement).optional() &
      ref(elseStatement).optional();

  selectionStatementJS() =>
      ref(ifStatement) |
      ref(SWITCH) &
          ref(token, '(') &
          ref(expression) &
          ref(token, ')') &
          ref(token, '{') &
          ref(switchCaseJS).star() &
          ref(defaultCaseJS).optional() &
          ref(token, '}');

  switchCaseJS() =>
      (ref(CASE) & ref(expression) & ref(token, ':')).plus() & ref(statements);

  defaultCaseJS() => ref(DEFAULT) & ref(token, ':') & ref(statements);

  @deprecated
  selectionStatement() =>
      ref(ifStatement) |
      ref(SWITCH) &
          ref(token, '(') &
          ref(expression) &
          ref(token, ')') &
          ref(token, '{') &
          ref(switchCase).star() &
          ref(defaultCase).optional() &
          ref(token, '}');

  @deprecated
  switchCase() =>
      ref(label).optional() &
      (ref(CASE) & ref(expression) & ref(token, ':')).plus() &
      ref(statements);

  @deprecated
  defaultCase() =>
      ref(label).optional() & ref(DEFAULT) & ref(token, ':') & ref(statements);

  tryStatementJS() =>
      ref(TRY) &
      ref(block) &
      (ref(catchPartJS).plus() & ref(finallyPart).optional() |
          ref(finallyPart));

  catchPartJS() =>
      ref(CATCH) &
      ref(token, '(') &
      ref(identifier) &
      ref(conditionalExpression).optional() //untested: refinement:
      &
      ref(token, ')') &
      ref(block);

  finallyPart() => ref(FINALLY) & ref(block);

  // note: followings cleared
  declaredIdentifier() =>
      // var ident
      ref(VAR) & ref(identifier)
      // let ident
      |
      ref(LET) & ref(identifier)
      // const ident
      |
      ref(CONST) & ref(identifier);

  initializedVariableDeclaration() =>
      // var|let|const ident = expr?
      // var|let|const ident = expr?, ...
      // var|let|const ident, ...
      ref(declaredIdentifier) &
      (ref(token, '=') & ref(expression)).optional() &
      (ref(token, ',') & ref(initializedIdentifier)).star();

  initializedIdentifierList() =>
      // ident, ...
      // ident = expr?, ...
      ref(initializedIdentifier) &
      (ref(token, ',') & ref(initializedIdentifier)).star();

  initializedIdentifier() =>
      // ident | ident = expr?
      ref(identifier) & (ref(token, '=') & ref(expression)).optional();

  identifier() => ref(token, ref(IDENTIFIER));

  propacc() => ref(identifier) & (ref(token, '.') & ref(identifier)).plus();

  qualified() => ref(identifier) & (ref(token, '.') & ref(identifier)).star();

  invoke() => ref(qualified) & ref(arguments);

  label() => ref(identifier) & ref(token, ':');

  arguments() =>
      ref(token, '(') & ref(argumentList).optional() & ref(token, ')');

  argumentList() => ref(argumentElement).separatedBy(ref(token, ','));

  argumentElement() => (ref(label) & ref(expression)) | ref(expression);

  // -----------------------------------------------
  // Selector ::
  //    | arguments             :: ... (arg)
  //    | assignableSelector    ::
  //       | propSelectorA          :: ... [expression]
  //       | propSelectorB          :: ... .select

  selector() => ref(assignableSelector) | ref(arguments);

  assignableSelector() =>
      ref(token, '[') & ref(expression) & ref(token, ']') |
      ref(token, '.') & ref(identifier);

  // PostfixExpression ::
  // -------------------------------------------
  //    | assignable expression
  //       & ... ++
  //    | primary
  //       & ... [selector] | & ... .selector

  postfixExpression() =>
      ref(assignableExpression) & ref(postfixOperator) |
      ref(primary) & ref(selector).star();

  // unaryExpression ::
  // -------------------------------------------
  //    | postfix_expresstion++
  //    | ++, --
  //       & ... [selector], ... .selector

  unaryExpression() =>
      ref(postfixExpression) |
      ref(prefixOperator) & ref(unaryExpression) |
      ref(incrementOperator) & ref(assignableExpression);

  // multiplicativeExpression ::
  // --------------------------------------------
  //    | unaryExpression
  //       & ... *, /, %
  //          & ... unaryExpression
  multiplicativeExpression() =>
      ref(unaryExpression) &
      (ref(multiplicativeOperator) & ref(unaryExpression)).star();

  additiveExpression() =>
      ref(multiplicativeExpression) &
      (ref(additiveOperator) & ref(multiplicativeExpression)).star();

  shiftExpression() =>
      ref(additiveExpression) &
      (ref(shiftOperator) & ref(additiveExpression)).star();

  relationalExpression() =>
      ref(shiftExpression) &
      (ref(qualified) & ref(instanceof) & ref(type) |
              ref(relationalOperator) & ref(shiftExpression))
          .optional();

  equalityExpression() =>
      ref(relationalExpression) &
      (ref(equalityOperator) & ref(relationalExpression)).optional();

  bitwiseAndExpression() =>
      ref(equalityExpression) &
      (ref(token, '&') & ref(equalityExpression)).star();

  bitwiseXorExpression() =>
      ref(bitwiseAndExpression) &
      (ref(token, '^') & ref(bitwiseAndExpression)).star();

  bitwiseOrExpression() =>
      ref(bitwiseXorExpression) &
          (ref(token, '|') & ref(bitwiseXorExpression)).star() |
      ref(SUPER) & (ref(token, '|') & ref(bitwiseXorExpression)).plus();

  logicalAndExpression() =>
      ref(bitwiseOrExpression) &
      (ref(token, '&&') & ref(bitwiseOrExpression)).star();

  logicalOrExpression() =>
      ref(logicalAndExpression) &
      (ref(token, '||') & ref(logicalAndExpression)).star();

  // -------------------------------------
  // Expression        ::
  //    & assignableExpression     ::
  //    & assignmentOperator       ::
  //    & Expression               ::
  //       Expression
  //       | conditionalExpression :: ? Expression : Expression

  expression() =>
      ref(assignableExpression) & ref(assignmentOperator) & ref(expression) |
      ref(conditionalExpression);

  expressionList() => ref(expression).separatedBy(ref(token, ','));

  conditionalExpression() =>
      // all conditional expression
      ref(logicalOrExpression)
      // ternary expression
      &
      (ref(token, '?') & ref(expression) & ref(token, ':') & ref(expression))
          .optional();

  // ---------------------------------------------------
  // assignableExpression :: primary (args)* assignable+
  //    & primary
  //       & args and assignable
  //          args               :: ... (arg1, ...argN)(...
  //          assignable         :: ... [selector] | ... .selector
  //    | assignable      :: ... [selector] | ... .selector
  //    | identifier      :: ... ident
  assignableExpression() =>
      ref(primary) & (ref(arguments).star() & ref(assignableSelector)).plus() |
      ref(assignableSelector) |
      ref(identifier);

  assignmentOperator() =>
      ref(token, '=') |
      ref(token, '*=') |
      ref(token, '/=') |
      ref(token, '%=') |
      ref(token, '+=') |
      ref(token, '-=');

  equalityOperator() =>
      ref(token, '===') |
      ref(token, '!==') |
      ref(token, '==') |
      ref(token, '!=');

  relationalOperator() =>
      ref(token, '>=') | ref(token, '>') | ref(token, '<=') | ref(token, '<');

  additiveOperator() => ref(token, '+') | ref(token, '-');

  incrementOperator() => ref(token, '++') | ref(token, '--');

  shiftOperator() => ref(token, '<<') | ref(token, '>>>') | ref(token, '>>');

  instanceof() => ref(IS);

  multiplicativeOperator() =>
      ref(token, '*') | ref(token, '/') | ref(token, '%') | ref(token, '~/');

  prefixOperator() => ref(additiveOperator) | ref(negateOperator);

  negateOperator() => ref(token, '!') | ref(token, '~');

  postfixOperator() => ref(incrementOperator);

  type() => ref(qualified);

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
      ref(THIS) & ref(assignableSelector) & ref(compoundLiteral) |
      ref(NEW) &
          ref(type) &
          (ref(token, '.') & ref(identifier)).optional() &
          ref(arguments) |
      ref(functionExpressionJS) |
      ref(expressionInParentheses) |
      ref(literal) |
      ref(identifier);

  expressionInParentheses() =>
      ref(token, '(') & ref(expression) & ref(token, ')');

  literal() => ref(
      token,
      ref(NULL) |
          ref(TRUE) |
          ref(FALSE) |
          ref(HEX_NUMBER) |
          ref(NUMBER) |
          ref(STRING));

  compoundLiteral() => ref(listLiteral) | ref(mapLiteral);

  listLiteral() =>
      ref(token, '[') &
      (ref(expressionList) & ref(token, ',').optional()).optional() &
      ref(token, ']');

  labelValuePairs() =>
      ref(mapLiteralEntry) &
      (ref(token, ',') & ref(mapLiteralEntry)).star() &
      ref(token, ',').optional();

  mapLiteral() =>
      ref(token, '{') & labelValuePairs().optional() & ref(token, '}');

  mapLiteralEntry() =>
      ref(STRING) |
      ref(identifier) & ref(token, ':') & ref(expression) |
      ref(functionDeclarationJSObj);

  // --------------------------------------
  //              identifiers
  // --------------------------------------

  IDENTIFIER_START_NO_DOLLAR() => ref(LETTER) | char('_');

  IDENTIFIER_START() => ref(IDENTIFIER_START_NO_DOLLAR) | char('\$');

  IDENTIFIER_PART() => ref(IDENTIFIER_START) | ref(DIGIT);

  IDENTIFIER() => ref(IDENTIFIER_START) & ref(IDENTIFIER_PART).star();

  STRING() => DQ_STRING() | SQ_STRING() | TMP_STRING();

  STRING_CONTENT_TMP() => pattern("^\\`\n\r") | char('\\') & NEWLINE();

  TMP_STRING() => char('`') & ref(STRING_CONTENT_DQ).star() & char('`');

  STRING_CONTENT_DQ() => pattern('^\\"\n\r') | char('\\') & NEWLINE();

  STRING_CONTENT_SQ() => pattern("^\\'\n\r") | char('\\') & NEWLINE();

  DQ_STRING() => char('"') & ref(STRING_CONTENT_DQ).star() & char('"');

  SQ_STRING() => char("'") & ref(STRING_CONTENT_SQ).star() & char("'");

  TEMPLATE_CONTENT() => ref(CODE_L).not() & ref(CODE_R).not();

  TEMPLATE_BLOCK() =>
      ref(CODE_L) & ref(TEMPLATE_CONTENT()).star() & ref(CODE_R);

  // --------------------------------------
  //                 number
  // --------------------------------------
  HEX_NUMBER() =>
      string('0x') & ref(HEX_DIGIT).plus() |
      string('0X') & ref(HEX_DIGIT).plus();

  NUMBER() =>
      ref(DIGIT).plus() //123
          &
          ref(NUMBER_OPT_FRACTIONAL_PART) //.123?
          &
          ref(EXPONENT).optional() //(E+?123)?
          &
          ref(NUMBER_OPT_ILLEGAL_END) |
      char('.') &
          ref(DIGIT).plus() &
          ref(EXPONENT).optional() &
          ref(NUMBER_OPT_ILLEGAL_END);

  HEX_DIGIT() => pattern('0-9a-fA-F');

  DIGIT() => digit();

  EXPONENT() => pattern('eE') & pattern('+-').optional() & ref(DIGIT).plus();

  NUMBER_OPT_FRACTIONAL_PART() => char('.') & ref(DIGIT).plus() | epsilon();

  NUMBER_OPT_ILLEGAL_END() => epsilon();

  // -----------------------------------------------------------------
  // Whitespace and comments.
  // -----------------------------------------------------------------
  HIDDEN() => ref(HIDDEN_STUFF).plus();

  HIDDEN_STUFF() =>
      ref(WHITESPACE) | ref(SINGLE_LINE_COMMENT) | ref(MULTI_LINE_COMMENT);

  SINGLE_LINE_COMMENT() =>
      string('//') & ref(NEWLINE).neg().star() & ref(NEWLINE).optional();

  MULTI_LINE_COMMENT() =>
      string('/*') &
      (ref(MULTI_LINE_COMMENT) | string('*/').neg()).star() &
      string('*/');
}
