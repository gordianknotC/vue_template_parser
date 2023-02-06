import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:colorize/colorize.dart';
/*import 'package:front_end/src/scanner/token.dart'
   show BeginToken, KeywordToken, SimpleToken, StringToken;*/


/*var _AST_STRUCT = {
   *//*
            annotation related
         -------------------------
         
   *//*
   AnnotationImpl: [
      SimpleToken, //@
      SimpleIdentifierImpl, //AnnotationName
      ArgumentListImpl //[@AnnotationName](... see below ...)
   ],
   //notice: note: func all argument list
   ArgumentListImpl: [
      BeginToken, // call [(] ... )
      NamedExpressionImpl, // call( [named arguements] ... )
      SimpleToken, // call( ... [)]
      SimpleStringLiteralImpl, // call( ['stringliteral'] ... )
      PrefixedIdentifierImpl, // call( [Prefix.property] ... )
      StringInterpolationImpl, // call( ['abc $value, ${value.call()}']
      SimpleIdentifierImpl, // call( [simpleArg]
      BinaryExpressionImpl, // call( [3+1]
      MethodInvocationImpl, // call( [Logger(name)]
      FunctionExpressionImpl, // call( [(arg) {}]
      IndexExpressionImpl, // call( [list[i]]
      IntegerLiteralImpl // call( [12]
   ],
   
   CompilationUnitImpl: [
      ImportDirectiveImpl,
      TopLevelVariableDeclarationImpl,
      FunctionDeclarationImpl,
      ClassDeclarationImpl,
      GenericTypeAliasImpl,
      EnumDeclarationImpl
   ],
   ImportDirectiveImpl: [
      SimpleStringLiteralImpl,
      ShowCombinatorImpl,
      SimpleToken
   ],
   SimpleStringLiteralImpl: [StringToken],
   ShowCombinatorImpl: [KeywordToken, SimpleIdentifierImpl],
   SimpleIdentifierImpl: [StringToken, KeywordToken],
   TopLevelVariableDeclarationImpl: [
      AnnotationImpl,
      VariableDeclarationListImpl,
      SimpleToken
   ],
   
   
   NamedExpressionImpl: [
      LabelImpl,
      SimpleStringLiteralImpl,
      SetOrMapLiteralImpl,
      PrefixedIdentifierImpl,
      BooleanLiteralImpl,
      ListLiteralImpl
   ],
   LabelImpl: [SimpleIdentifierImpl, SimpleToken],
   
   //note: notice: used in class field
   VariableDeclarationListImpl: [
      KeywordToken, //note: like final, const, var
      VariableDeclarationImpl, // ex: options = value;
      TypeNameImpl // typename
   ],
   VariableDeclarationImpl: [
      DeclaredSimpleIdentifier,
      SimpleToken,
      InstanceCreationExpressionImpl,
      BinaryExpressionImpl,
      NullLiteralImpl,
      IntegerLiteralImpl,
      SimpleStringLiteralImpl,
      ListLiteralImpl,
      FunctionExpressionImpl,
      MethodInvocationImpl,
      PrefixedIdentifierImpl,
      ConditionalExpressionImpl,
      PrefixExpressionImpl
   ],
   DeclaredSimpleIdentifier: [StringToken, KeywordToken],
   InstanceCreationExpressionImpl: [
      KeywordToken,
      ConstructorNameImpl,
      ArgumentListImpl
   ],
   ConstructorNameImpl: [TypeNameImpl],
   TypeNameImpl: [SimpleIdentifierImpl, TypeArgumentListImpl],
   FunctionDeclarationImpl: [
      AnnotationImpl,
      TypeNameImpl,
      DeclaredSimpleIdentifier,
      FunctionExpressionImpl
   ],
   FunctionExpressionImpl: [
      FormalParameterListImpl,
      BlockFunctionBodyImpl,
      ExpressionFunctionBodyImpl
   ],
   
   SimpleFormalParameterImpl: [
      TypeNameImpl,
      DeclaredSimpleIdentifier,
      GenericFunctionTypeImpl
   ],
   TypeArgumentListImpl: [BeginToken, TypeNameImpl, SimpleToken],
   BlockFunctionBodyImpl: [BlockImpl, KeywordToken, SimpleToken],
   BlockImpl: [
      BeginToken,
      ReturnStatementImpl,
      SimpleToken,
      VariableDeclarationStatementImpl,
      ExpressionStatementImpl,
      FunctionDeclarationStatementImpl,
      EmptyStatementImpl,
      IfStatementImpl,
      SwitchStatementImpl,
      TryStatementImpl,
      YieldStatementImpl,
      WhileStatementImpl,
      ForStatementImpl
   ],
   ReturnStatementImpl: [
      KeywordToken,
      NullLiteralImpl,
      SimpleToken,
      BinaryExpressionImpl,
      SimpleStringLiteralImpl,
      FunctionExpressionImpl,
      MethodInvocationImpl,
      BooleanLiteralImpl,
      PrefixedIdentifierImpl,
      SimpleIdentifierImpl
   ],
   NullLiteralImpl: [KeywordToken],
   DefaultFormalParameterImpl: [
      SimpleFormalParameterImpl,
      FieldFormalParameterImpl,
      SimpleToken,
      SetOrMapLiteralImpl,
      SimpleIdentifierImpl,
      PrefixedIdentifierImpl,
      IntegerLiteralImpl,
      FunctionTypedFormalParameterImpl,
      SimpleStringLiteralImpl
   ],
   VariableDeclarationStatementImpl: [
      VariableDeclarationListImpl,
      SimpleToken
   ],
   BinaryExpressionImpl: [
      SimpleIdentifierImpl,
      SimpleToken,
      IntegerLiteralImpl,
      PrefixedIdentifierImpl,
      BinaryExpressionImpl,
      ParenthesizedExpressionImpl,
      SimpleStringLiteralImpl,
      MethodInvocationImpl,
      NullLiteralImpl,
      BeginToken
   ],
   *//*
   *
   *                 class ast related
   *
   *
   *
   * *//*
   ClassDeclarationImpl: [
      KeywordToken, // [class] ClsName
      DeclaredSimpleIdentifier, // class [ClsName]
      BeginToken, // class ClsName [{]
      FieldDeclarationImpl, //
      ConstructorDeclarationImpl, //
      SimpleToken, // [}]
      AnnotationImpl,
      WithClauseImpl,
      ExtendsClauseImpl,
      MethodDeclarationImpl,
      TypeParameterListImpl
   ],
   //NOTE: NOTICE: class field
   FieldDeclarationImpl: [
      KeywordToken, //note: static, external.
      VariableDeclarationListImpl,
      SimpleToken, //note: terminator symbol ";"
      AnnotationImpl
   ],
   ConstructorDeclarationImpl: [
      KeywordToken,
      SimpleIdentifierImpl,
      FormalParameterListImpl,
      EmptyFunctionBodyImpl,
      BlockFunctionBodyImpl
   ],
   FieldFormalParameterImpl: [
      KeywordToken, //this
      SimpleToken, // .
      SimpleIdentifierImpl // key
   ],
   FormalParameterListImpl: [
      BeginToken, // call [(] ... )
      SimpleFormalParameterImpl, // call( [simpleArg] )
      SimpleToken, // call( ... [)] )
      DefaultFormalParameterImpl, // call( ... [i] )
      FieldFormalParameterImpl, // see above
      FunctionTypedFormalParameterImpl // call( [bool search(arg] )
   ],
   TypeParameterListImpl: [
      BeginToken, // [<]T> Function
      TypeParameterImpl, // <[T]> Function
      SimpleToken // <T[>] Function
   ],
   TypeParameterImpl: [
      DeclaredSimpleIdentifier
   ],
   SetOrMapLiteralImpl: [
      KeywordToken,
      BeginToken,
      SimpleToken,
      MapLiteralEntryImpl
   ],
   EmptyFunctionBodyImpl: [SimpleToken],
   ExtendsClauseImpl: [KeywordToken, TypeNameImpl],
   IntegerLiteralImpl: [StringToken],
   MethodDeclarationImpl: [
      AnnotationImpl, //
      TypeNameImpl, // [String] funcName(){...}
      GenericFunctionTypeImpl, // [void FUnction(...)] funcName(){...}
      DeclaredSimpleIdentifier, // retType [funcName] (){...}
      FormalParameterListImpl, //
      BlockFunctionBodyImpl, //
      KeywordToken, // [static|external] funcName(){...}
      ExpressionFunctionBodyImpl, // funcName [=> value];
   
   ],
   ExpressionStatementImpl: [
      MethodInvocationImpl,
      SimpleToken,
      ThrowExpressionImpl,
      AssignmentExpressionImpl,
      RethrowExpressionImpl,
      PostfixExpressionImpl
   ],
   MethodInvocationImpl: [
      SimpleIdentifierImpl,
      ArgumentListImpl,
      SimpleToken,
      MethodInvocationImpl
   ],
   ExpressionFunctionBodyImpl: [
      SimpleToken,
      SimpleIdentifierImpl,
      PrefixedIdentifierImpl,
      MethodInvocationImpl
   ],
   MapLiteralEntryImpl: [SimpleStringLiteralImpl, SimpleToken],
   GenericFunctionTypeImpl: [
      TypeNameImpl,
      KeywordToken,
      FormalParameterListImpl
   ],
   FunctionDeclarationStatementImpl: [FunctionDeclarationImpl],
   EmptyStatementImpl: [SimpleToken],
   GenericTypeAliasImpl: [
      KeywordToken,
      DeclaredSimpleIdentifier,
      SimpleToken,
      GenericFunctionTypeImpl
   ],
   EnumDeclarationImpl: [
      KeywordToken,
      DeclaredSimpleIdentifier,
      BeginToken,
      EnumConstantDeclarationImpl,
      SimpleToken
   ],
   EnumConstantDeclarationImpl: [DeclaredSimpleIdentifier],
   ListLiteralImpl: [BeginToken, PrefixedIdentifierImpl, SimpleToken],
   PrefixedIdentifierImpl: [SimpleIdentifierImpl, SimpleToken],
   IfStatementImpl: [
      KeywordToken,
      BeginToken,
      BinaryExpressionImpl,
      SimpleToken,
      ExpressionStatementImpl,
      MethodInvocationImpl,
      BlockImpl,
      IfStatementImpl,
      IsExpressionImpl,
      ReturnStatementImpl,
      PrefixedIdentifierImpl
   ],
   ThrowExpressionImpl: [
      KeywordToken,
      MethodInvocationImpl,
      ParenthesizedExpressionImpl
   ],
   AssignmentExpressionImpl: [
      SimpleIdentifierImpl,
      SimpleToken,
      IntegerLiteralImpl,
      MethodInvocationImpl
   ],
   StringInterpolationImpl: [
      InterpolationStringImpl,
      InterpolationExpressionImpl
   ],
   InterpolationStringImpl: [StringToken],
   InterpolationExpressionImpl: [
      SimpleToken,
      SimpleIdentifierImpl,
      BeginToken,
      BinaryExpressionImpl,
      IndexExpressionImpl,
      MethodInvocationImpl
   ],
   SwitchStatementImpl: [
      KeywordToken,
      BeginToken,
      SimpleIdentifierImpl,
      SimpleToken,
      SwitchCaseImpl,
      SwitchDefaultImpl
   ],
   SwitchCaseImpl: [
      KeywordToken,
      PrefixedIdentifierImpl,
      SimpleToken,
      ExpressionStatementImpl,
      BreakStatementImpl
   ],
   BreakStatementImpl: [KeywordToken, SimpleToken],
   SwitchDefaultImpl: [
      KeywordToken,
      SimpleToken,
      ExpressionStatementImpl,
      BreakStatementImpl
   ],
   BooleanLiteralImpl: [KeywordToken],
   TryStatementImpl: [KeywordToken, BlockImpl, CatchClauseImpl],
   CatchClauseImpl: [
      KeywordToken,
      BeginToken,
      DeclaredSimpleIdentifier,
      SimpleToken,
      BlockImpl
   ],
   RethrowExpressionImpl: [KeywordToken],
   ParenthesizedExpressionImpl: [
      BeginToken,
      SimpleIdentifierImpl,
      SimpleToken,
      BinaryExpressionImpl
   ],
   ConditionalExpressionImpl: [
      BinaryExpressionImpl,
      SimpleToken,
      SimpleIdentifierImpl,
      ConditionalExpressionImpl
   ],
   
   IsExpressionImpl: [SimpleIdentifierImpl, KeywordToken, TypeNameImpl],
   FunctionTypedFormalParameterImpl: [
      TypeNameImpl,
      DeclaredSimpleIdentifier,
      FormalParameterListImpl
   ],
   *//*GenericFunctionTypeImpl: [
      TypeNameImpl,
      KeywordToken,
      FormalParameterListImpl
   ],*//*
   WhileStatementImpl: [
      KeywordToken,
      BeginToken,
      MethodInvocationImpl,
      SimpleToken,
      BlockImpl,
      BinaryExpressionImpl
   ],
   YieldStatementImpl: [KeywordToken, MethodInvocationImpl, SimpleToken],
   ForStatementImpl: [
      KeywordToken,
      BeginToken,
      VariableDeclarationListImpl,
      SimpleToken,
      BinaryExpressionImpl,
      PrefixExpressionImpl,
      BlockImpl
   ],
   PrefixExpressionImpl: [
      SimpleToken,
      SimpleIdentifierImpl,
      IntegerLiteralImpl
   ],
   IndexExpressionImpl: [SimpleIdentifierImpl, BeginToken, SimpleToken],
   PostfixExpressionImpl: [SimpleIdentifierImpl, SimpleToken]
};*/



class Nullable {
   const Nullable();
}
const nullable = Nullable();



/*

                    U T I L S
   
   --------------------------------------------
   


 */
//@fmt:off
final _DUMP_COLOR = {
   'AnnotationImpl'                 : Styles.LIGHT_RED,
   // top level related
   'ImportDirectiveImpl'            : Styles.LIGHT_MAGENTA,
   'TopLevelVariableDeclarationImpl': Styles.LIGHT_MAGENTA,
   // Function related
   'MethodDeclarationImpl'          : Styles.LIGHT_CYAN,
   'FunctionDeclarationImpl'        : Styles.LIGHT_CYAN,
   'ArgumentListImpl'               : Styles.LIGHT_CYAN,
   // class, typedef, and enum related
   'ClassDeclarationImpl'           : Styles.LIGHT_YELLOW,
   'GenericTypeAliasImpl'           : Styles.LIGHT_YELLOW,
   'EnumDeclarationImpl'            : Styles.LIGHT_YELLOW,
   // tokens
   'StringToken'                    : Styles.LIGHT_GREEN,
   'KeywordToken'                   : Styles.LIGHT_GREEN,
};
//@fmt:on

/*

    dump AST Nodes into colorized and readable tree nodes
    
*/
Object dumpAst(dynamic node, [int level = 0, bool initial = true]) {
   var output = '';
   if (node is! Token) {
      var typename ,type_style, type, literal;
      AstNode _node = node;
      //output +=  _node.toString();
      //AST_STRUCT[_node.runtimeType.toString()] ??= Set();
      output += (initial ? _node.runtimeType.toString() : '') + '\n';
      output += _node.childEntities.map((SyntacticEntity n) {
         typename = n.runtimeType.toString();
         type_style = _DUMP_COLOR.containsKey(typename)
                         ? _DUMP_COLOR[typename]
                         : Styles.LIGHT_BLUE;
         type = '${Colorize(typename).apply(type_style)}';
         literal = dumpAst(n, level + 2, false);
         //AST_STRUCT[_node.runtimeType.toString()].add(typename);
         return '${"\t" * (level + 2)}[($type) $literal]';
      }).join('\n');
      return output;
   }
   output += node.toString();
   var c = Colorize(output);
   c.apply(Styles.LIGHT_GREEN);
   c.apply(Styles.BOLD);
   return c;
}

showFlatTree(node) async {
   print('===============================');
   print('        show flatten tree      ');
   print('_______________________________');
   
   CompilationUnit ast = parseCompilationUnit(node, parseFunctionBodies: true);
   var nodes = flatten_tree(ast).toList();
   var types = {};
   for (var n in nodes) {
      types[n.runtimeType] ??= [];
      types[n.runtimeType].add(n);
   }
   var data = Set();
   for (var k in types.keys) {
      data.add(k.toString());
      for (var e in types[k]) {
         data.add('\t' + e.toString());
      }
   }
   print(data.join('\n'));
   print('        -----------------      ');
   print('_______________________________');
}

List<SyntacticEntity>
flatten_tree(AstNode n, [int depth = 9999999]) {
   var que = [];
   que.add(n);
   var nodes = <SyntacticEntity>[];
   int nodes_count = que.length;
   int dep = 0;
   int c = 0;
   if (depth == 0) return [n];
   while (que.isNotEmpty) {
      var node = que.removeAt(0);
      if (node is! AstNode) continue;
      for (var cn in node.childEntities) {
         nodes.add(cn);
         que.add(cn);
      }
      //Keeping track of how deep in the tree
      ++c;
      if (c == nodes_count) {
         ++dep; // One layer done
         if (depth <= dep) return nodes;
         c = 0;
         nodes_count = que.length;
      }
   }
   return nodes;
}


