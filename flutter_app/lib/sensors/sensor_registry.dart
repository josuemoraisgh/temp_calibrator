import '../domain/sensor_model.dart';
import 'ntc_sensor.dart';
import 'rtd_sensor.dart';
import 'thermocouple_sensor.dart';

/// Registry SOLID (DIP/OCP): adicionar novo sensor = registrar aqui.
class SensorRegistry {
  SensorRegistry._();

  static final List<SensorModel> sensors = <SensorModel>[
    NtcSensor(),
    RtdSensor(),
    ThermocoupleSensor(typeLabel: 'K'),
    ThermocoupleSensor(typeLabel: 'J'),
    ThermocoupleSensor(typeLabel: 'T'),
    ThermocoupleSensor(typeLabel: 'E'),
    ThermocoupleSensor(typeLabel: 'N'),
    ThermocoupleSensor(typeLabel: 'S'),
    ThermocoupleSensor(typeLabel: 'R'),
    ThermocoupleSensor(typeLabel: 'B'),
  ];
}
