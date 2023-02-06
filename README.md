# vue template parser
__under development, not recommended.__

以 [petitparser] 寫 vue template parser, 目前 VueVariable[variable_grammar] / VueMustacheBlock[mustache_block] / XMLGrammar[xml_grammar] 可用，VueScriptGrammer／VueScript[vue_grammar] 寫到一半發覺以dart 寫 Vue2的實作方式似乎不可行也不實用，因此暫停，封存以作為 petitparser 的參考，無單元測試。

__內容__
- XMLGrammarParser / XMLGrammarDefinition [xml_grammar]
- VueVariablePaser / VueVariableGrammarDefinition [variable_grammar]
- VueMustacheBlockParser / VueMustacheBlockDefinition [mustache_block]
- VueScriptParser / VueScriptGrammarDefinition [vue_grammar]
- BaseGrammarParser / BaseGrammarDefinition [base_grammar]
- vue tokens [vue_token]

[petitparser]: https://pub.dev/packages/petitparser
[base_grammar]: /lib/src/vue.grammar.base.dart
[mustache_block]: /lib/src/vue.grammar.mustache_block.dart
[vue_grammar]: /lib/src/vue.grammar.script.dart
[variable_grammar]: /lib/src/vue.grammar.variable.dart
[xml_grammar]: /lib/src/vue.grammar.xml.dart
[vue_token]: /lib/src/vue.tokens.dart
