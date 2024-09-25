import 'package:test/test.dart';

import 'package:simple_fsm/simple_fsm.dart';

enum State { steam, water, ice }

enum Event { freeze, melt, evaporate, condense }

void main() {
  test('Simple transitions work', () {
    final fsm = FSM(
      initialState: State.water,
      transitions: const {
        State.steam: [
          Transition(State.water, Event.freeze),
        ],
        State.water: [
          Transition(State.steam, Event.evaporate),
          Transition(State.ice, Event.freeze),
        ],
        State.ice: [
          Transition(State.water, Event.melt),
        ],
      },
    );

    expect(fsm.state, State.water);

    fsm.fire(Event.freeze);
    expect(fsm.state, State.ice);

    fsm.fire(Event.evaporate);
    expect(fsm.state, State.ice);

    fsm.fire(Event.melt);
    expect(fsm.state, State.water);
  });

  test('Test guard function', () {
    final fsm = FSM(
      initialState: State.ice,
      transitions: {
        State.ice: [
          Tx(State.water, Event.evaporate, guard: () => false),
          Tx(State.steam, Event.evaporate, guard: () => true),
        ],
      },
    );

    expect(fsm.state, State.ice);

    fsm.fire(Event.evaporate);
    expect(fsm.state, State.steam);
  });

  test('Test callback function', () {
    var triggered = false;

    final fsm = FSM(
      initialState: State.ice,
      transitions: {
        State.ice: [
          Tx(State.water, Event.evaporate, onTransition: () {
            triggered = true;
          }),
        ],
      },
    );

    expect(fsm.state, State.ice);
    expect(triggered, false);

    fsm.fire(Event.evaporate);
    expect(fsm.state, State.water);
    expect(triggered, true);
  });

  test('Test transition stream', () async {
    var triggered = false;

    final fsm = FSM(
      initialState: State.ice,
      transitions: const {
        State.ice: [
          Tx(State.water, Event.evaporate),
        ],
      },
    );

    fsm.onTransition.listen((event) {
      expect(event.previousState, State.ice);
      expect(event.newState, State.water);
      expect(event.event, Event.evaporate);
      triggered = true;
    });

    expect(fsm.state, State.ice);
    expect(triggered, false);

    fsm.fire(Event.evaporate);
    expect(fsm.state, State.water);

    await Future.delayed(const Duration(milliseconds: 100));
    expect(triggered, true);
  });
}
