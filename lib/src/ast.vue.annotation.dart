
//@fmt:off
import 'package:meta/meta.dart';

const VUE_BEFORE_CREATED = ['beforeCreate'];
const VUE_CREATED        = ['created'];
const VUE_BEFORE_MOUNTED = ['beforeMounte'];
const VUE_MOUNTED        = ['mounted'];
const VUE_BEFORE_UPDATED = ['beforeUpdate'];
const VUE_UPDATED        = ['updated'];
const VUE_BEFORE_DESTROY = ['beforeDestroy'];
const VUE_DESTROYED      = ['destroyed'];

const DATA_META     = ['Data', 'data'];
const METHOD_META   = ['Method', 'method'];
const COMPUTED_META = ['Computed', 'computed'];
const OPTION_META   = ['Option', 'options'];
const PROP_META     = ['Prop', 'prop'];
const WATCH_META    = ['Watch', 'watch'];
const PROVIDE_META  = ['Provide', 'provide'];
const INJECT_META   = ['Inject', 'inject'];
const ON_META       = ['On', 'on'];
const ONCE_META     = ['Once', 'once'];
const COMP_META     = ['Component', 'component'];

final CLASS_ANNOTATIONS  = COMP_META;
final FIELD_ANNOTATIONS  = DATA_META + OPTION_META  + INJECT_META ;
final METHOD_ANNOTATIONS = METHOD_META + COMPUTED_META + WATCH_META + PROVIDE_META
                           + ON_META + ONCE_META + PROP_META + OPTION_META;
final VUE_ANNOTATIONS    = CLASS_ANNOTATIONS + FIELD_ANNOTATIONS + METHOD_ANNOTATIONS;
final VUE_HOOKS          = VUE_BEFORE_CREATED + VUE_CREATED + VUE_BEFORE_MOUNTED
                           + VUE_MOUNTED + VUE_BEFORE_UPDATED + VUE_UPDATED
                           + VUE_BEFORE_DESTROY + VUE_DESTROYED;
//@fmt:on


/*class Option {
   const Option();
}*/

class Prop {
   final bool required;
   
   const Prop({this.required});
}

/*class Provide {
   const Provide();
}*/

/*class Inject {
   const Inject();
}*/

class On {
   final String event_name;
   final bool life_hook;
   
   const On(this.event_name, [this.life_hook = false]);
}

class Once {
   final String event_name;
   final bool life_hook;
   
   const Once(this.event_name, [this.life_hook = false]);
}

class Watch {
   final String var_name;
   final bool immediate;
   final bool deep;
   
   const Watch({this.var_name, this.immediate, this.deep});
}


class Model{
   final String prop;
   final String event;
   const Model(this.prop, this.event);
}

class Component {
   final List<String>      delimiters;
   final Map<String, Type> components;
   final List<Type>        mixins;
   final String   template;
   final String   el;
   final String   name;
   final bool     activated;
   final Model    model;
   const Component({@required this.template,@required this.el, this.components,
          this.name, this.model, this.activated, this.delimiters, this.mixins});
}


class Mixin {
   final Type data;
   final Type computed;
   final Type prop;
   final Type watch;
   final Type option;
   final Type method;
   final Type on;
   final Type once;
   final Type filters;
   const Mixin ({
       this.data, this.computed, this.prop, this.watch, this.option,
       this.method, this.on, this.once, this.filters});
}



class _VueProp {
   const _VueProp();
}

class _VueComputed {
   const _VueComputed();
}

class _VueMethod {
   const _VueMethod();
}

class _VueRef {
   const _VueRef();
}

class _VueOption {
   const _VueOption();
}

class _VueInject {
   const _VueInject();
}

class _VueProvide {
   const _VueProvide();
}

class _VueData {
   const _VueData();
}


const option   = const _VueOption();
const inject   = const _VueInject();
const provide  = const _VueProvide();
const data     = const _VueData();
const prop     = const _VueProp();
const computed = const _VueComputed();
const method   = const _VueMethod();
const ref      = const _VueRef();


class ONImplementation {
   String   propname;
   List     args;
   Function body;
   Function wrapper;
   
   ONImplementation({this.propname, this.args, this.body, this.wrapper});
   
   String output(){
      return wrapper(
         body
      );
   }
}


class ON_ENUMS {
   static const CLICK      = 'ON.CLICK';
   static const LOAD       = 'ON.LOAD';
   static const TOUCH      = 'ON.TOUCH';
   static const TOUCH_UP   = 'ON.TOUCH_UP';
   static const TOUCH_MOVE = 'ON.TOUCH_MOVE';
   static const MOUSE_MOVE = 'ON.MOUSE_MOVE';
   static const MOUSE_DOWN = 'ON.MOUSE_DOWN';
   static const MOUSE_UP   = 'ON.MOUSE_UP';
   static const DOUBLE_TAP = 'ON.DOUBLE_TAP';
}

class ON {
   static const Enums      = ON_ENUMS;
   static const CLICK      = ON_ENUMS.CLICK;
   static const LOAD       = ON_ENUMS.LOAD;
   static const TOUCH      = ON_ENUMS.TOUCH;
   static const MOUSE_DOWN = ON_ENUMS.MOUSE_DOWN;
   static const MOUSE_MOVE = ON_ENUMS.MOUSE_MOVE;
   static const MOUSE_UP   = ON_ENUMS.MOUSE_UP;
   static const TOUCH_MOVE = ON_ENUMS.TOUCH_MOVE;
   static const DOUBLE_TAP = ON_ENUMS.DOUBLE_TAP;
   
   const ON.DOM_CHANGED(String dom);
   const ON.VUE_HOOK(String hook);
}



