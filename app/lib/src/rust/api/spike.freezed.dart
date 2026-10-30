// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spike.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpikeRtcEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SpikeRtcEvent()';
}


}

/// @nodoc
class $SpikeRtcEventCopyWith<$Res>  {
$SpikeRtcEventCopyWith(SpikeRtcEvent _, $Res Function(SpikeRtcEvent) __);
}


/// Adds pattern-matching-related methods to [SpikeRtcEvent].
extension SpikeRtcEventPatterns on SpikeRtcEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SpikeRtcEvent_Joined value)?  joined,TResult Function( SpikeRtcEvent_PeerJoined value)?  peerJoined,TResult Function( SpikeRtcEvent_PeerLeft value)?  peerLeft,TResult Function( SpikeRtcEvent_Connected value)?  connected,TResult Function( SpikeRtcEvent_Message value)?  message,TResult Function( SpikeRtcEvent_Closed value)?  closed,TResult Function( SpikeRtcEvent_Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SpikeRtcEvent_Joined() when joined != null:
return joined(_that);case SpikeRtcEvent_PeerJoined() when peerJoined != null:
return peerJoined(_that);case SpikeRtcEvent_PeerLeft() when peerLeft != null:
return peerLeft(_that);case SpikeRtcEvent_Connected() when connected != null:
return connected(_that);case SpikeRtcEvent_Message() when message != null:
return message(_that);case SpikeRtcEvent_Closed() when closed != null:
return closed(_that);case SpikeRtcEvent_Error() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SpikeRtcEvent_Joined value)  joined,required TResult Function( SpikeRtcEvent_PeerJoined value)  peerJoined,required TResult Function( SpikeRtcEvent_PeerLeft value)  peerLeft,required TResult Function( SpikeRtcEvent_Connected value)  connected,required TResult Function( SpikeRtcEvent_Message value)  message,required TResult Function( SpikeRtcEvent_Closed value)  closed,required TResult Function( SpikeRtcEvent_Error value)  error,}){
final _that = this;
switch (_that) {
case SpikeRtcEvent_Joined():
return joined(_that);case SpikeRtcEvent_PeerJoined():
return peerJoined(_that);case SpikeRtcEvent_PeerLeft():
return peerLeft(_that);case SpikeRtcEvent_Connected():
return connected(_that);case SpikeRtcEvent_Message():
return message(_that);case SpikeRtcEvent_Closed():
return closed(_that);case SpikeRtcEvent_Error():
return error(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SpikeRtcEvent_Joined value)?  joined,TResult? Function( SpikeRtcEvent_PeerJoined value)?  peerJoined,TResult? Function( SpikeRtcEvent_PeerLeft value)?  peerLeft,TResult? Function( SpikeRtcEvent_Connected value)?  connected,TResult? Function( SpikeRtcEvent_Message value)?  message,TResult? Function( SpikeRtcEvent_Closed value)?  closed,TResult? Function( SpikeRtcEvent_Error value)?  error,}){
final _that = this;
switch (_that) {
case SpikeRtcEvent_Joined() when joined != null:
return joined(_that);case SpikeRtcEvent_PeerJoined() when peerJoined != null:
return peerJoined(_that);case SpikeRtcEvent_PeerLeft() when peerLeft != null:
return peerLeft(_that);case SpikeRtcEvent_Connected() when connected != null:
return connected(_that);case SpikeRtcEvent_Message() when message != null:
return message(_that);case SpikeRtcEvent_Closed() when closed != null:
return closed(_that);case SpikeRtcEvent_Error() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String me)?  joined,TResult Function( String peer)?  peerJoined,TResult Function( String peer)?  peerLeft,TResult Function( String peer)?  connected,TResult Function( String text)?  message,TResult Function()?  closed,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SpikeRtcEvent_Joined() when joined != null:
return joined(_that.me);case SpikeRtcEvent_PeerJoined() when peerJoined != null:
return peerJoined(_that.peer);case SpikeRtcEvent_PeerLeft() when peerLeft != null:
return peerLeft(_that.peer);case SpikeRtcEvent_Connected() when connected != null:
return connected(_that.peer);case SpikeRtcEvent_Message() when message != null:
return message(_that.text);case SpikeRtcEvent_Closed() when closed != null:
return closed();case SpikeRtcEvent_Error() when error != null:
return error(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String me)  joined,required TResult Function( String peer)  peerJoined,required TResult Function( String peer)  peerLeft,required TResult Function( String peer)  connected,required TResult Function( String text)  message,required TResult Function()  closed,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SpikeRtcEvent_Joined():
return joined(_that.me);case SpikeRtcEvent_PeerJoined():
return peerJoined(_that.peer);case SpikeRtcEvent_PeerLeft():
return peerLeft(_that.peer);case SpikeRtcEvent_Connected():
return connected(_that.peer);case SpikeRtcEvent_Message():
return message(_that.text);case SpikeRtcEvent_Closed():
return closed();case SpikeRtcEvent_Error():
return error(_that.message);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String me)?  joined,TResult? Function( String peer)?  peerJoined,TResult? Function( String peer)?  peerLeft,TResult? Function( String peer)?  connected,TResult? Function( String text)?  message,TResult? Function()?  closed,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SpikeRtcEvent_Joined() when joined != null:
return joined(_that.me);case SpikeRtcEvent_PeerJoined() when peerJoined != null:
return peerJoined(_that.peer);case SpikeRtcEvent_PeerLeft() when peerLeft != null:
return peerLeft(_that.peer);case SpikeRtcEvent_Connected() when connected != null:
return connected(_that.peer);case SpikeRtcEvent_Message() when message != null:
return message(_that.text);case SpikeRtcEvent_Closed() when closed != null:
return closed();case SpikeRtcEvent_Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SpikeRtcEvent_Joined extends SpikeRtcEvent {
  const SpikeRtcEvent_Joined({required this.me}): super._();
  

 final  String me;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpikeRtcEvent_JoinedCopyWith<SpikeRtcEvent_Joined> get copyWith => _$SpikeRtcEvent_JoinedCopyWithImpl<SpikeRtcEvent_Joined>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent_Joined&&(identical(other.me, me) || other.me == me));
}


@override
int get hashCode {
    return Object.hash(runtimeType,me);
}

@override
String toString() {
    return 'SpikeRtcEvent.joined(me: $me)';
}


}

/// @nodoc
abstract mixin class $SpikeRtcEvent_JoinedCopyWith<$Res> implements $SpikeRtcEventCopyWith<$Res> {
  factory $SpikeRtcEvent_JoinedCopyWith(SpikeRtcEvent_Joined value, $Res Function(SpikeRtcEvent_Joined) _then) = _$SpikeRtcEvent_JoinedCopyWithImpl;
@useResult
$Res call({
 String me
});




}
/// @nodoc
class _$SpikeRtcEvent_JoinedCopyWithImpl<$Res>
    implements $SpikeRtcEvent_JoinedCopyWith<$Res> {
  _$SpikeRtcEvent_JoinedCopyWithImpl(this._self, this._then);

  final SpikeRtcEvent_Joined _self;
  final $Res Function(SpikeRtcEvent_Joined) _then;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? me = null,}) {
  return _then(SpikeRtcEvent_Joined(
me: null == me ? _self.me : me // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SpikeRtcEvent_PeerJoined extends SpikeRtcEvent {
  const SpikeRtcEvent_PeerJoined({required this.peer}): super._();
  

 final  String peer;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpikeRtcEvent_PeerJoinedCopyWith<SpikeRtcEvent_PeerJoined> get copyWith => _$SpikeRtcEvent_PeerJoinedCopyWithImpl<SpikeRtcEvent_PeerJoined>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent_PeerJoined&&(identical(other.peer, peer) || other.peer == peer));
}


@override
int get hashCode {
    return Object.hash(runtimeType,peer);
}

@override
String toString() {
    return 'SpikeRtcEvent.peerJoined(peer: $peer)';
}


}

/// @nodoc
abstract mixin class $SpikeRtcEvent_PeerJoinedCopyWith<$Res> implements $SpikeRtcEventCopyWith<$Res> {
  factory $SpikeRtcEvent_PeerJoinedCopyWith(SpikeRtcEvent_PeerJoined value, $Res Function(SpikeRtcEvent_PeerJoined) _then) = _$SpikeRtcEvent_PeerJoinedCopyWithImpl;
@useResult
$Res call({
 String peer
});




}
/// @nodoc
class _$SpikeRtcEvent_PeerJoinedCopyWithImpl<$Res>
    implements $SpikeRtcEvent_PeerJoinedCopyWith<$Res> {
  _$SpikeRtcEvent_PeerJoinedCopyWithImpl(this._self, this._then);

  final SpikeRtcEvent_PeerJoined _self;
  final $Res Function(SpikeRtcEvent_PeerJoined) _then;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? peer = null,}) {
  return _then(SpikeRtcEvent_PeerJoined(
peer: null == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SpikeRtcEvent_PeerLeft extends SpikeRtcEvent {
  const SpikeRtcEvent_PeerLeft({required this.peer}): super._();
  

 final  String peer;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpikeRtcEvent_PeerLeftCopyWith<SpikeRtcEvent_PeerLeft> get copyWith => _$SpikeRtcEvent_PeerLeftCopyWithImpl<SpikeRtcEvent_PeerLeft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent_PeerLeft&&(identical(other.peer, peer) || other.peer == peer));
}


@override
int get hashCode {
    return Object.hash(runtimeType,peer);
}

@override
String toString() {
    return 'SpikeRtcEvent.peerLeft(peer: $peer)';
}


}

/// @nodoc
abstract mixin class $SpikeRtcEvent_PeerLeftCopyWith<$Res> implements $SpikeRtcEventCopyWith<$Res> {
  factory $SpikeRtcEvent_PeerLeftCopyWith(SpikeRtcEvent_PeerLeft value, $Res Function(SpikeRtcEvent_PeerLeft) _then) = _$SpikeRtcEvent_PeerLeftCopyWithImpl;
@useResult
$Res call({
 String peer
});




}
/// @nodoc
class _$SpikeRtcEvent_PeerLeftCopyWithImpl<$Res>
    implements $SpikeRtcEvent_PeerLeftCopyWith<$Res> {
  _$SpikeRtcEvent_PeerLeftCopyWithImpl(this._self, this._then);

  final SpikeRtcEvent_PeerLeft _self;
  final $Res Function(SpikeRtcEvent_PeerLeft) _then;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? peer = null,}) {
  return _then(SpikeRtcEvent_PeerLeft(
peer: null == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SpikeRtcEvent_Connected extends SpikeRtcEvent {
  const SpikeRtcEvent_Connected({required this.peer}): super._();
  

 final  String peer;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpikeRtcEvent_ConnectedCopyWith<SpikeRtcEvent_Connected> get copyWith => _$SpikeRtcEvent_ConnectedCopyWithImpl<SpikeRtcEvent_Connected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent_Connected&&(identical(other.peer, peer) || other.peer == peer));
}


@override
int get hashCode {
    return Object.hash(runtimeType,peer);
}

@override
String toString() {
    return 'SpikeRtcEvent.connected(peer: $peer)';
}


}

/// @nodoc
abstract mixin class $SpikeRtcEvent_ConnectedCopyWith<$Res> implements $SpikeRtcEventCopyWith<$Res> {
  factory $SpikeRtcEvent_ConnectedCopyWith(SpikeRtcEvent_Connected value, $Res Function(SpikeRtcEvent_Connected) _then) = _$SpikeRtcEvent_ConnectedCopyWithImpl;
@useResult
$Res call({
 String peer
});




}
/// @nodoc
class _$SpikeRtcEvent_ConnectedCopyWithImpl<$Res>
    implements $SpikeRtcEvent_ConnectedCopyWith<$Res> {
  _$SpikeRtcEvent_ConnectedCopyWithImpl(this._self, this._then);

  final SpikeRtcEvent_Connected _self;
  final $Res Function(SpikeRtcEvent_Connected) _then;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? peer = null,}) {
  return _then(SpikeRtcEvent_Connected(
peer: null == peer ? _self.peer : peer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SpikeRtcEvent_Message extends SpikeRtcEvent {
  const SpikeRtcEvent_Message({required this.text}): super._();
  

 final  String text;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpikeRtcEvent_MessageCopyWith<SpikeRtcEvent_Message> get copyWith => _$SpikeRtcEvent_MessageCopyWithImpl<SpikeRtcEvent_Message>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent_Message&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text);
}

@override
String toString() {
    return 'SpikeRtcEvent.message(text: $text)';
}


}

/// @nodoc
abstract mixin class $SpikeRtcEvent_MessageCopyWith<$Res> implements $SpikeRtcEventCopyWith<$Res> {
  factory $SpikeRtcEvent_MessageCopyWith(SpikeRtcEvent_Message value, $Res Function(SpikeRtcEvent_Message) _then) = _$SpikeRtcEvent_MessageCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$SpikeRtcEvent_MessageCopyWithImpl<$Res>
    implements $SpikeRtcEvent_MessageCopyWith<$Res> {
  _$SpikeRtcEvent_MessageCopyWithImpl(this._self, this._then);

  final SpikeRtcEvent_Message _self;
  final $Res Function(SpikeRtcEvent_Message) _then;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(SpikeRtcEvent_Message(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SpikeRtcEvent_Closed extends SpikeRtcEvent {
  const SpikeRtcEvent_Closed(): super._();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent_Closed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SpikeRtcEvent.closed()';
}


}




/// @nodoc


class SpikeRtcEvent_Error extends SpikeRtcEvent {
  const SpikeRtcEvent_Error({required this.message}): super._();
  

 final  String message;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpikeRtcEvent_ErrorCopyWith<SpikeRtcEvent_Error> get copyWith => _$SpikeRtcEvent_ErrorCopyWithImpl<SpikeRtcEvent_Error>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpikeRtcEvent_Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'SpikeRtcEvent.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SpikeRtcEvent_ErrorCopyWith<$Res> implements $SpikeRtcEventCopyWith<$Res> {
  factory $SpikeRtcEvent_ErrorCopyWith(SpikeRtcEvent_Error value, $Res Function(SpikeRtcEvent_Error) _then) = _$SpikeRtcEvent_ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SpikeRtcEvent_ErrorCopyWithImpl<$Res>
    implements $SpikeRtcEvent_ErrorCopyWith<$Res> {
  _$SpikeRtcEvent_ErrorCopyWithImpl(this._self, this._then);

  final SpikeRtcEvent_Error _self;
  final $Res Function(SpikeRtcEvent_Error) _then;

/// Create a copy of SpikeRtcEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SpikeRtcEvent_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
