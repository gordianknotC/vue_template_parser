# vue template parser
__under development, not recommended.__

以 [petitparser] 寫 vue template parser, 目前 VueVariable[Parser] / VueMustacheBlock[Parser] / XMLGrammar[Parser] 可用，VueScriptGrammer／VueScript[Parser] 寫到一半發覺以dart 寫 Vue2的實作方式似乎不可行也不實用，因此暫停，封存以作為 petitparser 的參考，無單元測試。

__內容__
- XMLGrammarParser / XMLGrammarDefinition
- VueVariablePaser / VueVariableGrammarDefinition
- VueMustacheBlockParser / VueMustacheBlockDefinition
- VueScriptParser / VueScriptGrammarDefinition
- XMLGrammarParser / XMLGrammarDefinition (vue template xml)
- BaseGrammarParser / BaseGrammarDefinition
- vue tokens 

[petitparser]: https://pub.dev/packages/petitparser
[Parser]: /lib/src/ast.vue.template.parser.dart