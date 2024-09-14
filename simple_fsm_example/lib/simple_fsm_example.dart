import 'package:logging/logging.dart';
import 'package:simple_fsm/simple_fsm.dart';

final logger = Logger('fsm');

enum State { water, ice, steam }

enum Event { heat, cool }

int currentTemp = 0;

final fsm = StateMachine(
  initialState: State.water,
  logger: logger,
  transitions: {
    State.water: [
      Transition(State.ice, Event.cool),
      Transition(State.steam, Event.heat),
    ],
    State.ice: [
      Transition(State.steam, Event.heat, guard: () => currentTemp >= 100),
      Transition(State.water, Event.heat),
    ],
    State.steam: [
      Transition(State.water, Event.cool,
          onTransition: () => logger.info('Liquefied')),
    ],
  },
  onEnter: {
    State.steam: () => logger.info('The water is boiling'),
  },
  onExit: {
    State.steam: () => logger.info('The water has stopped boiling'),
  },
);

void run() {
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  fsm.fire(Event.cool);
  fsm.fire(Event.heat);
  fsm.fire(Event.heat);
  fsm.fire(Event.cool);
  currentTemp = 100;
  fsm.fire(Event.heat);
}
