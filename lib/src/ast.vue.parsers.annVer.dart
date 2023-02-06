/*
//import 'package:astMacro/src/common.dart';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'ast.utils.dart' show dumpAst;
import 'ast.vue.spell.dart';
import 'common.dart' show FN, raise, tryRaise;
import 'common.spell.dart';
import 'ast.vue.annotation.dart';
import 'ast.parsers.dart';
import 'ast.codegen.dart';
import 'package:path/path.dart' as Path;
import 'io.util.dart' show getScriptPath;

class BaseAnnotationTransformer {
}

enum EContext {
   topVar,
   topVarConst,
   topVarFinal,
   topDecl,
   topMethod,
   classField,
   classMethod,
   staticField,
   staticMethod,
   classGetter,
   classSetter,
   private,
   public
}

enum EDefTypes{
   method, watch, computed, option, prop, data, on, once
}

enum EJSType{
   string, number, object, list, boolean, function, date, symbol
}

const IPROP     = 'IPropDefs';
const IWATCHER  = 'IWatcherDefs';
const IDATA     = 'IDataDefs';
const ICOMPUTED = 'IComputedDefs';
const IOPTION   = 'IOptionDefs';
const IOn       = 'IOnEventDefs';
const IOnce     = 'IOnceEventDefs';


class BaseDefTransformer {

}

class BaseVueDefinitions<E> {
   E                    host_comp;
   ClassDeclParser      host_parser;
   EDefTypes            def_type;
   SimpleIdentifierImpl def_name;
   BaseDefTransformer   transformer;
   
   
   use(BaseDefTransformer transformer) {
      this.transformer = transformer;
   }

   _warningForTypoField(FieldsParser parser) {
      var names = parser.names.map((name) => name.toString()).toList();
      var typo = TypoSuggest();
      names.forEach((name) {
         if (typo.isCamelCase(name)) {
            var words = CamelCaseTyping(name).words;
            var suggest = TypoSuggest().correct(name);
            if (words.length == suggest.length) {
               raise(StackTrace.fromString('found typo on method:$name, did you mean:$suggest'));
            }
         }
      });
   }

   _warningForTypoMethod(MethodsParser parser) {
      var fn_name = parser.name.name;
      var typo = TypoSuggest();
      if (typo.isCamelCase(fn_name)) {
         var words = CamelCaseTyping(fn_name).words;
         var suggest = TypoSuggest().correct(fn_name);
         if (VUE_HOOKS.any((hook) => suggest.contains(hook))) {
            return raise(StackTrace.fromString('found typo on life hook:$fn_name, did you mean:$suggest'));
         }
         if (words.length == suggest.length) {
            raise(StackTrace.fromString('found typo on method:$fn_name, did you mean:$suggest'));
         }
      }
   }

   _warningForNotSupported(BaseDeclParser _member, String annName) {
      var is_annotated_with_vue_annotation, is_allowed;
      _member.annotationNames.forEach((a) {
         is_annotated_with_vue_annotation = VUE_ANNOTATIONS.contains(a);
         if (is_annotated_with_vue_annotation) {
            _assertAnnConsistency(_member, a);
         }
      });
   }
   
   _assertAnnConsistency(BaseDeclParser member, String annName) {
      void unsupportedFieldAnn(names) => raise(StackTrace.fromString('annotation: $annName is not supported to be annotated on class Field: ${names}'));
      void unsupportedMethodAnn(name) => raise(StackTrace.fromString('annotation: $annName is not supported to be annotated on class Method: ${name}'));
   
      if (member is FieldsParser) {
         switch (annName.toLowerCase()) {
            case "data" :
            case "prop" :
            case "inject" :
            case "provide":
            case "option" :
               return true;
            case "on" :
            case "once" :
            case "pragma" :
            case "method" :
            case "computed":
               return unsupportedFieldAnn(member.variables.map((v) => v.name).toList());
         }
      } else if (member is MethodsParser) {
         switch (annName.toLowerCase()) {
            case "method" :
            case "computed":
               if (!(member.is_getter || member.is_setter))
                  raise(StackTrace.fromString('Computed properties only supported on annotating on getter methods or setter methods'));
               break;
            case "watch" :
               if ((member.is_getter || member.is_setter))
                  raise(StackTrace.fromString('Watch properties cannot annotate on getter methods or setter methods'));
               break;
            case "pragma" :
               throw Exception('Pragma is not implemented yet');
               break;
            case "inject" :
            case "provide" :
               if (!(member.is_getter || member.is_setter))
                  raise(StackTrace.fromString('Provide/Inject annotation cannot be annotated on getter methods or setter methods'));
               break;
            case "on" :
            case "once" :
            case "option" :
               return true;
            case "data":
            case "prop":
               return unsupportedMethodAnn(member.name.name);
         }
      } else if (member is ClassDeclParser){
         switch( annName.toLowerCase()){
            case 'component':
               return true;
         }
      }
      return false;
   }

   tryWarning(String annName) {
      warning(BaseDeclParser member,  List<String> names){
         if (!isPublic(names.first))
            return raise(StackTrace.fromString('cannot annotate on private fields/methods ${names.first}'));
         _warningForNotSupported(member, annName);
         if (member is FieldsParser)
            _warningForTypoField(member);
         if (member is MethodsParser)
            _warningForTypoMethod(member);
      };
      host_parser.fields.forEach((field){
         var names = field.variables.map((s) => s.name).toList();
         warning(field, names);
      });
      host_parser.methods.forEach((method){
         var name = method.name.name;
         warning(method, [name]);
      });
   }
}




*/
/*


                             A N N O T A T I O N S
      
      
      
*//*




class BaseVueAnnotation<E extends DeclarationImpl, P extends BaseDeclParser> {
   List<AnnotationImpl> annotations;
   E host;
   P host_parser;
   SimpleIdentifier name;
   ArgumentListParser arguments;
   BaseAnnotationTransformer transformer;
   
   BaseVueAnnotation(AnnotationImpl node, [E host]) {
      this.host = host;
      name = node.name;
      if(node.arguments != null)
         arguments = ArgumentListParser(node.arguments);
      annotations ??= [];
      annotations.add(node);
   }
   
   use(BaseAnnotationTransformer transformer) {
      this.transformer = transformer;
   }
   
   _warningForTypoField() {
      var names = (host_parser as FieldsParser).names.map((name) => name.toString()).toList();
      var typo = TypoSuggest();
      names.forEach((name) {
         if (typo.isCamelCase(name)) {
            var words = CamelCaseTyping(name).words;
            var suggest = TypoSuggest().correct(name);
            if (words.length == suggest.length) {
               raise(StackTrace.fromString('found typo on method:$name, did you mean:$suggest'));
            }
         }
      });
   }
   
   _warningForTypoMethod() {
      var fn_name = (host_parser as MethodsParser).name.name;
      var typo = TypoSuggest();
      if (typo.isCamelCase(fn_name)) {
         var words = CamelCaseTyping(fn_name).words;
         var suggest = TypoSuggest().correct(fn_name);
         if (VUE_HOOKS.any((hook) => suggest.contains(hook))) {
            return raise(StackTrace.fromString('found typo on life hook:$fn_name, did you mean:$suggest'));
         }
         if (words.length == suggest.length) {
            raise(StackTrace.fromString('found typo on method:$fn_name, did you mean:$suggest'));
         }
      }
   }
   
   _warningForNotSupported(BaseDeclParser _member, String annName) {
      var is_annotated_with_vue_annotation, is_allowed;
      _member.annotationNames.forEach((a) {
         is_annotated_with_vue_annotation = VUE_ANNOTATIONS.contains(a);
         if (is_annotated_with_vue_annotation) {
            _assertAnnConsistency(_member, a);
         }
      });
   }
   
   
   _assertAnnConsistency(BaseDeclParser member, String annName) {
      void unsupportedFieldAnn(names) => raise(StackTrace.fromString('annotation: $annName is not supported to be annotated on class Field: ${names}'));
      void unsupportedMethodAnn(name) => raise(StackTrace.fromString('annotation: $annName is not supported to be annotated on class Method: ${name}'));
      
      if (member is FieldsParser) {
         switch (annName.toLowerCase()) {
            case "data" :
            case "prop" :
            case "inject" :
            case "provide":
            case "option" :
               return true;
            case "on" :
            case "once" :
            case "pragma" :
            case "method" :
            case "computed":
               return unsupportedFieldAnn(member.variables.map((v) => v.name).toList());
         }
      } else if (member is MethodsParser) {
         switch (annName.toLowerCase()) {
            case "method" :
            case "computed":
               if (!(member.is_getter || member.is_setter))
                  raise(StackTrace.fromString('Computed properties only supported on annotating on getter methods or setter methods'));
               break;
            case "watch" :
               if ((member.is_getter || member.is_setter))
                  raise(StackTrace.fromString('Watch properties cannot annotate on getter methods or setter methods'));
               break;
            case "pragma" :
               throw Exception('Pragma is not implemented yet');
               break;
            case "inject" :
            case "provide" :
               if (!(member.is_getter || member.is_setter))
                  raise(StackTrace.fromString('Provide/Inject annotation cannot be annotated on getter methods or setter methods'));
               break;
            case "on" :
            case "once" :
            case "option" :
               return true;
            case "data":
            case "prop":
               return unsupportedMethodAnn(member.name.name);
         }
      } else if (member is ClassDeclParser){
         switch( annName.toLowerCase()){
            case 'component':
               return true;
         }
      }
      return false;
   }
   
   tryWarning(BaseDeclParser _member, String annName) {
      if (_member is FieldsParser) {
         var names = _member.variables.map((s) => s.name).toList();
         if (!isPublic(_member.names.first))
            return raise(StackTrace.fromString('cannot annotate on private field: ${_member.names.first}'));
         _warningForNotSupported(_member, annName);
         _warningForTypoField();
      } else if (_member is MethodsParser) {
         if (!isPublic(_member.name.name))
            return raise(StackTrace.fromString('cannot annotate on private method: ${_member.name.name}'));
         _warningForNotSupported(_member, annName);
         _warningForTypoMethod();
      } else {
         throw Exception("Invalid type");
      }
   }
}



mixin FieldAnnProperty{
   FieldsParser host_parser;
   
   List<String>
   get host_names => host_parser.names;
   
   TypeNameImpl
   get host_type => host_parser.named_type;
   
   ExpressionImpl
   get host_defaults => host_parser.assigned_value;
}

mixin MethodAnnProperty{
   MethodsParser host_parser;
   
   FunctionBody
   get body => host_parser.body;
   
   TypeParameterListImpl
   get type_param => host_parser.type_params;
   
   String
   get host_name => host_parser.name.name;
   
   AType
   get ret_type => host_parser.ret_type;
   
   bool
   get is_static => host_parser.is_static;
   
   bool
   get is_getter => host_parser.is_getter;
   
   bool
   get is_setter => host_parser.is_setter;
   
   List<Refs<AstNode, SimpleIdentifierImpl>>
   get refs_in_body => host_parser.refs_in_body;
   
   List<MethodsParser>
   get referenced_methods => null; //fixme: host_parser.getReferencedClassMethods([THIS, SELF]);
}

mixin ClassAnnProperty  {
   ClassDeclParser host_parser;
   get host_name => host_parser.name.name;
   
}


mixin HybridAnnProperty<E extends BaseDeclParser> {
   E host_parser;
   
   List<String>
   get host_names =>
      host_parser is FieldsParser
      ? (host_parser as FieldsParser).names
      : host_parser is MethodsParser
         ? [(host_parser as MethodsParser).name.name]
         : [(host_parser as ClassDeclParser).name.name ] ;
   
   TypeNameImpl
   get host_type =>
      host_parser is FieldsParser
      ? (host_parser as FieldsParser).named_type
      : null;
   
   ExpressionImpl
   get host_defaults =>
      host_parser is FieldsParser
      ? (host_parser as FieldsParser).assigned_value
      : null;
   
   FunctionBody
   get body =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).body
      : null;
   
   TypeParameterListImpl
   get type_param =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).type_params
      : host_parser is MethodsParser
         ? null : null;
   
   String
   get host_name =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).name.name
      : host_parser is FieldsParser
         ? (host_parser as FieldsParser).variables.first.name
         : (host_parser as ClassDeclParser).name.name;
   
   AType
   get ret_type =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).ret_type
      : null;
   
   bool
   get is_static => host_parser.is_static;
   
   bool
   get is_getter =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).is_getter
      : null;
   
   bool
   get is_setter =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).is_setter
      : null;
   
   List<Refs<AstNode, SimpleIdentifierImpl>>
   get refs_in_body =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).refs_in_body
      : null;
   
   List<MethodsParser>
   get referenced_methods =>
      host_parser is MethodsParser
      ? (host_parser as MethodsParser).getReferencedClassMethods([THIS, SELF])
      : null;
}






class VueAnnotation<D extends DeclarationImpl, P extends BaseDeclParser> extends BaseVueAnnotation<D, P> with HybridAnnProperty<P> {
   VueAnnotation(AnnotationImpl node, D host ) : super(node, host);
}





//incompleted:
class ClassAnnotation extends VueAnnotation<ClassDeclarationImpl, ClassDeclParser> {
   VueDartFileParser vue_owner;
   
   ClassAnnotation(AnnotationImpl node, ClassDeclarationImpl host, VueDartFileParser vue_owner) : super(node, host) {
     host_parser = ClassDeclParser(host);
     this.vue_owner = vue_owner;
   }
}

class FieldAnnotation extends VueAnnotation<FieldDeclarationImpl, FieldsParser> {
   VueClassParser vue_owner;
   
   FieldAnnotation(AnnotationImpl node, FieldDeclarationImpl host, VueClassParser vue_owner) : super(node, host ) {
      var host_owner = vue_owner.cls_parser;
      host_parser = FieldsParser(host, host_owner);
   }
}

class MethodAnnotation extends VueAnnotation<MethodDeclarationImpl, MethodsParser> {
   VueClassParser vue_owner;
   
   dynamic
   _getNamedArgValue(NamedArgParser parser, dynamic Function() getter){
      return parser != null
             ? getter()
             : _isOnChangeConvention(name.name, vue_owner)
               ? _getFieldByConvention('on', 'Changed', name.name, vue_owner)?.names?.first
               : null;
   }
   
   MethodAnnotation(AnnotationImpl node, MethodDeclarationImpl host, VueClassParser vue_owner) : super(node, host ) {
      var host_owner = vue_owner.cls_parser;
      host_parser = MethodsParser(host, host_owner);
   }
}

class HybridAnnotation extends VueAnnotation {
   VueClassParser vue_owner;
   
   HybridAnnotation(AnnotationImpl node, DeclarationImpl host, VueClassParser vue_owner) : super(node, host ) {
      var host_owner = vue_owner.cls_parser;
      host_parser = host is MethodDeclarationImpl
        ? MethodsParser(host, host_owner)
        : host is FieldDeclarationImpl
          ? FieldsParser(host, host_owner)
          : () {
               throw new Exception('Invalid Usage');
            }();
   }
}







class DataAnn extends FieldAnnotation {
   DataAnn(AnnotationImpl node, FieldDeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner);
}

class PropAnn<E> extends FieldAnnotation {
   bool required;
   List<MethodsParser> validator_bodies;
   
   PropAnn(AnnotationImpl node, FieldDeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner) {
      var host_owner = vue_owner.cls_parser;
      validator_bodies =
         host_names.map((name) {
            var snake_name = 'on_${name}_validated';
            var camel_name = 'on${name}Validated';
            if (host_owner
                   .getMethod(camel_name)
                   ?.first != null)
               return host_owner
                  .getMethod(camel_name)
                  ?.first;
            if (host_owner
                   .getMethod(snake_name)
                   ?.first != null)
               return host_owner
                  .getMethod(snake_name)
                  ?.first;
         }).toList();
      required = arguments.named_args.containsKey('required')
                 ? arguments.named_args['required'].expression.toSource() == 'true'
                 : false;
   }
}



class ComputedAnn<E> extends MethodAnnotation {
   ComputedAnn(AnnotationImpl node, MethodDeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner);
}

class WatchAnn<E> extends MethodAnnotation {
   String var_name;
   bool   immediate;
   bool   deep;
   
   WatchAnn(AnnotationImpl node, MethodDeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner) {
      var var_name_parser   = NamedArgParser(arguments.named_args['var_name']);
      var immediate_parser = NamedArgParser(arguments.named_args['immediate']);
      var deep_parser      = NamedArgParser(arguments.named_args['deep']);
      
      var_name   = _getNamedArgValue(var_name_parser,   () => var_name_parser.stringValue);
      immediate = _getNamedArgValue(immediate_parser, () => immediate_parser.boolValue) ?? false;
      deep      = _getNamedArgValue(deep_parser,      () => deep_parser.boolValue)      ?? false;
      
      if(var_name == null)
         throw Exception('var_name is required');
   }
}

class Template{
   String template;
   String style;
   Template(String content){
      template = fetchTemplate(content);
      style = fetchStyle(content);
   }
   String
   fetchTemplate(String content){
      return content;
   }
   String
   fetchStyle(String content){
      return content;
   }
}




class Component<E> extends ClassAnnotation {
   List<MapLiteralEntry> components;
   String el;
   String template;
   String style;
   
   Iterable<SimpleStringLiteralImpl>
   get keys => components.map((entry) => (entry.key as SimpleStringLiteralImpl));
   
   Iterable<ExpressionImpl>
   get values => components.map((entry) => entry.value);
   
   Component(AnnotationImpl node, ClassDeclarationImpl host, VueDartFileParser vue_owner) : super(node, host, vue_owner) {
      var el_parser = NamedArgParser(arguments.named_args['el']);
      el = el_parser.stringValue ?? el_parser.identValue
           ?? (){throw Exception('Uncaught error');}();
      
      preparseTemplate();
      components = NamedArgParser(arguments.named_args['components']).mapValue.entries.toList();
      //assertComponentsValidity();
   }
   
   preparseTemplate(){
      var template_parser = NamedArgParser(arguments.named_args['template']);
      if (template_parser.stringValue != null){
         template = template_parser.stringValue;
      }else if (template_parser.identValue != null){
         template = template_parser.identValue;
      }else{
         throw Exception('Uncaught error');
      }
   }
   
   assertComponentsValidity(){
      // not necessary, since dart analysis already done this!!
      var comp_names    = components.map((entry)=> entry.value.toString()).toList();
      var vuecls_names  = vue_owner.vue_classes.map((cls) => cls.cls_parser.name.name).toList();
      var referenced_vuecomps_from_current_file =
         vuecls_names.where((clsname) => comp_names.contains(clsname));
      
      var referenced_vuecomps_from_import = <String>[];
         vue_owner.vue_imports.forEach((imp){
            var show_names = imp.shows.map((s) => s.name);
            
            if (imp.shows.length > 0 && show_names.any((impname) => comp_names.contains(impname)))
               referenced_vuecomps_from_import += show_names.where((impname) => comp_names.contains(impname)).toList();
            
            if (imp.decl_as != null)
               referenced_vuecomps_from_import += imp.content_parser.cls_decls
                  .where((cls) =>
                     cls.annotationNames.any((name) =>
                        comp_names.contains('${imp.decl_as.name}.$name')
                     )
                  ).map((cls) => cls.name.name).toList();
         });

      if (comp_names.length > referenced_vuecomps_from_import.length + referenced_vuecomps_from_current_file.length)
         throw Exception('one of following compoonents not found: $comp_names');
   }
}






class On extends MethodAnnotation {
   String event_name;
   bool   life_hook;
   On(AnnotationImpl node, MethodDeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner){
      event_name = (arguments.args.first as SimpleStringLiteralImpl).toSource();
      if (arguments.args.length > 1)
         life_hook = (arguments.args[1] as BooleanLiteralImpl).value;
   }
}

class Once extends MethodAnnotation {
   String event_name;
   bool   life_hook;
   Once(AnnotationImpl node, MethodDeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner){
      event_name = (arguments.args.first as SimpleStringLiteralImpl).toSource();
      if (arguments.args.length > 1)
         life_hook = (arguments.args[1] as BooleanLiteralImpl).value;
   }
}






class Provide extends HybridAnnotation {
   Provide(AnnotationImpl node, DeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner);
}

class Injection extends HybridAnnotation {
   Injection(AnnotationImpl node, DeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner);
}

class Options extends HybridAnnotation {
   Options(AnnotationImpl node, DeclarationImpl host, VueClassParser vue_owner) : super(node, host, vue_owner);
}






FieldsParser
_getFieldByConvention(String prefix, String suffix, String name, VueClassParser vueOwner){
   var field_name = FN.dePrefix(name, prefix, suffix);
   var lfield_name = '${field_name.substring(0, 1).toLowerCase()}${field_name.substring(1)}';
   print('## name: $name, field_name: $field_name, $lfield_name');
   var field = vueOwner.cls_parser.getField(field_name);
   var lfield = vueOwner.cls_parser.getField(lfield_name);
   return field ?? lfield;
}

bool
_isPrefixConvention(String prefix, String suffix, String name, VueClassParser vueOwner) {
   var l = prefix.length;
   if (name.startsWith(prefix) && name.endsWith(suffix)) {
      var field = _getFieldByConvention(prefix, suffix, name, vueOwner);
      return field != null;
   };
   return false;
}

bool
_isOnChangeConvention(String name, VueClassParser vueOwner) {
   if (IS.snakeCase(name))
      name = FN.toCamelCase(name);
   return _isPrefixConvention('on', 'Changed', name, vueOwner);
}

bool
_isValidatorConvention(String name, VueClassParser vueOwner) {
   if (IS.snakeCase(name))
      name = FN.toCamelCase(name);
   return _isPrefixConvention('on', 'Validated', name, vueOwner);
}







class VueMethodsParser<E extends DeclarationImpl> extends MethodsParser {
   List<FieldsParser> _vueDataRefs;
   List<MethodsParser> _vueMethodOrComputedRefs;
   VueAnnotation vueAnnotation;
   VueClassParser vueOwner;
   
   bool is_method;
   bool is_computed;
   bool is_prop;
   bool is_on;
   bool is_once;
   bool is_hook;
   bool is_option;
   bool is_provide;
   bool is_watch;
   
   //need refinement:
   List<FieldsParser>
   get vueDataRefs {
      // 1) annotated with Data + public method
      // 2) no annotation + public method
      if (_vueDataRefs != null) return _vueDataRefs;
      return _vueDataRefs = getReferencedClassFields([THIS, SELF]).where((field) {
         if (field.annotations != null) {
            if (IS.vueData(field)) {
               return field.variables.every((v) => isPublic(v.name));
            }
            return false;
         }
         return field.variables.every((v) => isPublic(v.name));
      }).toList();
   }
   
   //need refinement:
   List<MethodsParser>
   get vueMethodOrComputedRefs {
      // 1) annotated with Method, and Computed + public method
      // 2) no annotation + public method
      if (_vueMethodOrComputedRefs != null) return _vueMethodOrComputedRefs;
      return _vueMethodOrComputedRefs = getReferencedClassMethods([THIS, SELF]).where((method) {
         if (method.annotations != null) {
            if (IS.vueMethod(method) || IS.vueComputed(method)) {
            
            }
         }
      });
   }
   
   AnnotationImpl
   _getAnnotationByName(List<String> names) {
      return annotations.firstWhere((a) => names.contains(a.name.name), orElse: () => null);
   }
   
   */
/*
   *
   *           1) on[Data]Changed
   *           2) on[Prop]Validated
   * *//*

   void
   _setConventionAnnotation(String prefix, String suffix) {
      String ann_name, prop_name, converted_name;
      ann_name = suffix == 'changed'
                 ? 'watch'
                 : suffix == 'validated'
                   ? 'prop'
                   : () {
                        throw Exception('Invalid Usage');
                     }();
      var arguments;
           if (IS.camelCase(name.name)) converted_name = name.name;
      else if (IS.snakeCase(name.name)) converted_name = FN.toCamelCase(name.name);
      else                              throw Exception('uncaught error');
      
      prop_name = _getFieldByConvention('on', suffix, converted_name, vueOwner)?.names?.first;

      if (ann_name == 'watch') {
         arguments = [
            TArg(arg_name: 'var_name', arg_value: astString(prop_name)),
         ];
         vueAnnotation = WatchAnn(astMeta(ann_name, arguments), this.origin, vueOwner);
         print('onChanged found: $prop_name, generated annotation: $vueAnnotation');
   
      } else {
         //ann_name == prop
         try{
            arguments = astArgumentsList([
               TArg(arg_name: 'var_name', arg_value: astString(prop_name)),
            ]);
            var prop = vueOwner.prop_fields.firstWhere((field) {
               return field.names.contains(prop_name);
            }, orElse: () => null);
   
            if (prop != null) (prop.vueAnnotation as PropAnn).validator_bodies ??= [this];
            else              throw Exception('Vue Prop: $prop_name not found.');
         }catch(e){
            if (vueOwner.prop_fields == null)
               throw Exception('Vue Prop:$prop_name not defined yet.\n$e');
            throw Exception('\n$e');
         }
         
      }
   }
   
   void
   annotationInit(MethodDeclarationImpl node) {
      AnnotationImpl annotation;
      print('method name: ${node.name.name}');
      if (is_method) {
         // no transformation
         // fixme: ?
      } else if (is_computed) {
         annotation = _getAnnotationByName(COMPUTED_META);
         vueAnnotation = ComputedAnn(annotation, node, vueOwner);
      } else if (is_on) {
         annotation = _getAnnotationByName(ON_META);
         vueAnnotation = On(annotation, node, vueOwner);
      } else if (is_once) {
         annotation = _getAnnotationByName(ONCE_META);
         vueAnnotation = Once(annotation, node, vueOwner);
      } else if (is_option) {
         annotation = _getAnnotationByName(OPTION_META);
         vueAnnotation = Options(annotation, node, vueOwner);
      } else if (is_provide) {
         annotation = _getAnnotationByName(PROVIDE_META);
         vueAnnotation = Provide(annotation, node, vueOwner);
      } else if (is_watch) {
         annotation = _getAnnotationByName(WATCH_META);
         vueAnnotation = WatchAnn(annotation, node, vueOwner);
      } else if (is_hook) {
         //no transformation
      } else {
         print('@@convention:${node.name.name}');
         if (_isOnChangeConvention(name.name, vueOwner)) {
            return _setConventionAnnotation('on', 'changed');
         } else if (_isValidatorConvention(name.name, vueOwner)) {
            return _setConventionAnnotation('on', 'validated');
         }
         //throw Exception('Uncaught error');
      }
   }
   
   VueMethodsParser(MethodDeclarationImpl node, ClassDeclParser classOwner, VueClassParser vueOwner) : super(node, classOwner) {
      this.vueOwner = vueOwner;
      is_method     = IS.vueMethod(this);  // fixme:
      is_computed   = IS.vueComputed(this);
      is_on         = IS.vueOn(this);
      is_option     = IS.vueOption(this);
      is_once       = IS.vueOnce(this);
      is_hook       = IS.vueHook(this);
      is_provide    = IS.vueProvided(this);
      is_watch      = IS.vueWatch(this);
      annotationInit(node);
   }
}




class VueFieldsParser extends FieldsParser {
   VueClassParser vueOwner;
   VueAnnotation vueAnnotation;
   bool is_data;
   bool is_option;
   bool is_inject;
   bool is_prop;
   
   AnnotationImpl
   _getAnnotationByName(List<String> names) {
      return annotations.firstWhere((a) => names.contains(a.name.name), orElse: () => null);
   }
   
   annotationInit(FieldDeclarationImpl node) {
      AnnotationImpl annotation;
      print(
         '${node.fields.variables.first.name.name}'
         '\ndata:${IS.vueX(this, DATA_META)}, method:${IS.vueX(this, METHOD_META)}, '
         'option:${IS.vueX(this, OPTION_META)}, inject:${IS.vueX(this, INJECT_META)}, '
         'prop:${IS.vueX(this, PROP_META)}'
      );
      if (is_data) {
         annotation = _getAnnotationByName(DATA_META);
         print('_getAnnotationByName name: $annotation');
         vueAnnotation = DataAnn(annotation, node, vueOwner);
      } else if (is_option) {
         annotation = _getAnnotationByName(OPTION_META);
         vueAnnotation = Options(annotation, node, vueOwner);
      } else if (is_inject) {
         annotation = _getAnnotationByName(INJECT_META);
         vueAnnotation = Injection(annotation, node, vueOwner);
      } else if (is_prop) {
         annotation = _getAnnotationByName(PROP_META);
         vueAnnotation = PropAnn(annotation, node, vueOwner);
      } else {
         //throw Exception('Uncaught Error');
      }
      vueAnnotation?.tryWarning(vueAnnotation.host_parser, vueAnnotation.name.name);
   }
   
   VueFieldsParser(FieldDeclarationImpl node, ClassDeclParser classOwner, VueClassParser vueOwner) : super(node, classOwner) {
      this.vueOwner = vueOwner;
      is_data = IS.vueData(this);
      is_option = IS.vueOption(this);
      is_inject = IS.vueInject(this);
      is_prop = IS.vueProp(this);
      annotationInit(node);
   }
}

var pseudo_hook = VUE_HOOKS.map((s) => s.toLowerCase());


class VueDartFileParser extends DartFileParser {
   static Map<DartFileParser, VueDartFileParser> parsed_files = {};
   List<ImportParser>   vue_imports;
   List<VueClassParser> vue_classes;


   factory VueDartFileParser({CompilationUnitImpl code, Uri uri, DartFileParser file}){
      if (file == null)
         return VueDartFileParser.init(code, uri, file);
      if (VueDartFileParser.parsed_files[file] == null)
         return VueDartFileParser.fileInit(file);
      return VueDartFileParser.parsed_files[file];
   }

   VueDartFileParser.fileInit(DartFileParser file): super.fileInit(file);

   VueDartFileParser.init(CompilationUnitImpl code, Uri uri, DartFileParser file)
      :super.init(code, uri.toString(), uri);
}

class VueClassParser {
   ClassDeclParser   cls_parser;
   Component         vueAnnotation;
   VueDartFileParser vue_owner;
   
   List<VueMethodsParser> method_fields;
   List<VueMethodsParser> watch_fields;
   List<VueMethodsParser> computed_fields;
   List<VueMethodsParser> lifecycle_fields;
   
   List<VueMethodsParser> on_fields;
   List<VueMethodsParser> once_fields;
   List<VueMethodsParser> options_method_fields;
   List<VueMethodsParser> provide_method_fields;
   List<VueMethodsParser> inject_method_fields;
   List<VueMethodsParser> prop_validator_fields;
   
   List<VueFieldsParser> options_prop_fields;
   List<VueFieldsParser> provide_prop_fields;
   List<VueFieldsParser> inject_prop_fields;
   List<VueFieldsParser> data_fields;
   List<VueFieldsParser> prop_fields;
   
   bool     _isMetaMethodForced;
   bool     _isMetaDataForced;
   String   el;
   String   template;
   String   style;
   List<MapLiteralEntry> components;
   
   
   bool
   get isDataMetaForced {
      if (_isMetaDataForced != null) return _isMetaDataForced;
      return _isMetaDataForced = cls_parser.fieldsAnnotations.map((a) => a.name.name)
         .any((name) => DATA_META.contains(name));
   }
   
   void
   set isDataMetaForced(bool v) {
      _isMetaDataForced = v;
   }
   
   bool
   get isMethodMetaForced {
      if (_isMetaMethodForced != null) return _isMetaMethodForced;
      return _isMetaMethodForced = cls_parser.methodsAnnotations.map((a) => a.name.name)
         .any((name) => METHOD_META.contains(name));
   }
   
   void
   set isMethodMetaForced(bool v) {
      _isMetaMethodForced = v;
   }
   
   VueClassParser(ClassDeclParser this.cls_parser, [VueDartFileParser this.vue_owner]) {
      init();
   }

   List<VueMethodsParser>
   _filterMethodsByLifeCycleHooks(){
      return cls_parser.methods.where((method){
         return IS.vueHook(method);
      }).map((MethodsParser method) => VueMethodsParser(method.origin, cls_parser, this)).toList();
   }
   
   List<VueMethodsParser>
   _filterMethodsByOnChangedConvention(){
      return cls_parser.methods.where((MethodsParser method){
         return _isOnChangeConvention( FN.toCamelCase(method.name.name), this)
                && !watch_fields.map((VueMethodsParser p) => p.origin).contains(method.origin) ;
      }).map((MethodsParser method) => VueMethodsParser(method.origin, cls_parser, this)).toList();
   }

   List<VueMethodsParser>
   _filterMethodsByOnValidatedConvention(){
      return cls_parser.methods.where((MethodsParser method){
         return _isValidatorConvention( FN.toCamelCase(method.name.name), this)
                && !prop_validator_fields.map((VueMethodsParser p) => p.origin).contains(method.origin) ;
      }).map((MethodsParser method) => VueMethodsParser(method.origin, cls_parser, this)).toList();
   }
   
   List<VueMethodsParser>
   _filterMethodsByAnnName(String annName) {
      return cls_parser.methods.where((method) =>
         method.annotationNames.map((name) => name.toLowerCase()).contains(annName)
      ).map((MethodsParser method) => VueMethodsParser(method.origin, cls_parser, this)).toList();
   }
   
   List<VueFieldsParser>
   _filterFieldsByAnnName(String annName) {
      return cls_parser.fields.where((field) => field.annotationNames.map((name) => name.toLowerCase()).contains(annName))
         .map((FieldsParser field) {
         return VueFieldsParser(field.origin, cls_parser, this);
      }).toList();
   }
   
   init() {
      data_fields   = _filterFieldsByAnnName('data');
      method_fields = _filterMethodsByAnnName('method');
      //----------------------------------------
      prop_fields           = _filterFieldsByAnnName('prop');
      prop_validator_fields = _filterMethodsByAnnName('prop') ;
      prop_validator_fields += _filterMethodsByOnValidatedConvention();
      //----------------------------------------
      options_method_fields = _filterMethodsByAnnName('option');
      options_prop_fields   = _filterFieldsByAnnName('option');
      //----------------------------------------
      watch_fields    =  _filterMethodsByAnnName('watch');
      watch_fields    += _filterMethodsByOnChangedConvention();
      computed_fields =  _filterMethodsByAnnName('computed');
      //----------------------------------------
      on_fields   = _filterMethodsByAnnName('on');
      once_fields = _filterMethodsByAnnName('once');
      //----------------------------------------
      provide_prop_fields = _filterFieldsByAnnName('provide');
      inject_prop_fields  = _filterFieldsByAnnName('inject');
      lifecycle_fields    = _filterMethodsByLifeCycleHooks();
      //----------------------------------------
      print(cls_parser.annotationNames);
      var ann = cls_parser.annotations.where((ann) => ann.name.name.toLowerCase() == 'component').first;
      vueAnnotation = Component( ann,  cls_parser.origin,  vue_owner );
      el            = vueAnnotation.el;
      template      = vueAnnotation.template;
      style         = vueAnnotation.style;
      components    = vueAnnotation.components;
      
   }
}







*/
