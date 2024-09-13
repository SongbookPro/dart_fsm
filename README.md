A finite state machine implementation using enums for states and events. This simple approach allows for a highly readable state machine, while still supporting features including guards, transition callbacks and logging.

## Features

Supported state machine features:

- States and events represented by enums
- Optional callbacks on state entry, exit and transitions
- Optional guard functions on state transitions
- Fires events on transitions between states

## Usage

To get started create an instance of `StateMachine` with the initial state and a map of transitions between states. The map of transitions should be a map of state enums to a list of valid `Transition` from that state.

Then call `fire` on the `StateMachine` instance to transition to the next state.

```dart
import 'package:simple_fsm/simple_fsm.dart';

enum State { water, ice, steam }
enum Event { heat, cool }

final fsm = StateMachine(
  initialState: State.water,
  transitions: const {
    State.water: [
      Transition(State.ice, Event.cool),
      Transition(State.steam, Event.heat),
    ],
    State.ice: [
      Transition(State.steam, Event.heat, guard: () => temp > 100),
      Transition(State.water, Event.heat),
    ],
    State.steam: [
      Transition(State.water, Event.cool),
    ],
  },
  onEnter: {
    State.steam: () => print('The water is boiling'),
  },
  onExit: {
    State.steam: () => print('The water has stopped boiling'),
  },
);

fsm.fire(Event.cool);
```

State transition events can also be listened to using the `onTransition` stream.

```dart
fsm.onTransition.listen((event) {
  print('State transitioned from ${event.previousState} to ${event.newState} on ${event.event}');
});
```

## Logging

To add logging to your state machine, simply pass a `Logger` instance to the `StateMachine` constructor.

## Type aliasing

To reduce the verbosity of the code, the following type aliases are provided:

```dart
typedef FSM = StateMachine;
typedef Tx = Transition;
```

This will allow you to write the following:

```dart
final fsm = FSM(
  initialState: State.water,
  transitions: const {
    State.water: [
      Tx(State.ice, Event.freeze),
      Tx(State.steam, Event.boil),
    ],
    State.ice: [
      Tx(State.water, Event.melt),
    ],
  },
);
```
