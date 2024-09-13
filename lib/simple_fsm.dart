/// A finite state machine implementation which uses enums for states and events.
library simple_fsm;

import 'dart:async';

import 'package:logging/logging.dart';

/// A shorthand version of [Transition].
typedef Tx<State extends Enum, Event extends Enum> = Transition;

/// A shorthand version of [StateMachine].
typedef FSM<State extends Enum, Event extends Enum> = StateMachine;

/// Represents a transition to a new state.
class Transition<State extends Enum, Event extends Enum> {
  /// Represents the state to transition to.
  final State state;

  /// Represents the event that triggers the transition.
  final Event event;

  /// An optional guard that must return true to trigger the transition.
  final bool Function()? guard;

  /// An optional callback that is called after the transition has been performed.
  final void Function()? onTransition;

  /// Represents a transition to [state] on [event] with optional [guard] and [onTransition] callback.
  const Transition(this.state, this.event, {this.guard, this.onTransition});
}

/// Details a transition that occurred.
class TransitionEvent<State extends Enum, Event extends Enum> {
  /// The previous state.
  final State previousState;

  /// The state that was transitioned to.
  final State newState;

  /// The event that triggered the transition.
  final Event event;

  const TransitionEvent._(this.previousState, this.newState, this.event);
}

/// A finite state machine implementation which uses enums for states and events.
class StateMachine<State extends Enum, Event extends Enum> {
  final Map<State, List<Transition<State, Event>>> _transitions;
  final Map<State, void Function()>? _onEnter;
  final Map<State, void Function()>? _onExit;
  final Logger? _logger;

  final _transitionStream = StreamController<TransitionEvent>.broadcast();

  State _state;

  /// Creates a new [StateMachine] with the given [initialState] and [transitions].
  ///
  /// Example:
  ///
  /// ```dart
  /// enum State { water, ice }
  /// enum Event { freeze, melt }
  ///
  /// final fsm = StateMachine(
  ///   initialState: State.water,
  ///   transitions: const {
  ///     State.water: [
  ///       Transition(State.ice, Event.freeze),
  ///     ],
  ///     State.ice: [
  ///       Transition(State.water, Event.melt),
  ///     ],
  ///   },
  /// );
  /// ```
  StateMachine({
    required State initialState,
    required Map<State, List<Transition<State, Event>>> transitions,
    Map<State, void Function()>? onEnter,
    Map<State, void Function()>? onExit,
    Logger? logger,
  })  : _state = initialState,
        _transitions = transitions,
        _onEnter = onEnter,
        _onExit = onExit,
        _logger = logger;

  /// The current state of the [StateMachine].
  State get state => _state;

  /// A stream of [TransitionEvent] that are emitted when a transition occurs.
  Stream<TransitionEvent> get onTransition => _transitionStream.stream;

  /// Fires the given [event] and transitions to the next state if applicable.
  void fire(Event event) {
    final transitions = _transitions[_state];
    if (transitions == null) {
      return;
    }

    for (final transition in transitions) {
      if (transition.event == event) {
        // Check guard if present
        if (transition.guard?.call() == false) {
          continue;
        }

        final oldState = _state;

        // Log transition if required
        if (_logger != null) {
          _logger!.info('[${[
            event.toString().split('.').last
          ]}] ${oldState.toString().split('.').last} -> ${transition.state.toString().split('.').last}');
        }

        _onExit?[_state]?.call();

        // Perform transition
        _state = transition.state;

        _onEnter?[_state]?.call();

        transition.onTransition?.call();

        _transitionStream.add(TransitionEvent._(oldState, transition.state, event));
        return;
      }
    }
  }
}
