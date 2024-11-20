
obj = ClassKeySightSupply.getInstance() % Creates an instance of the class Keysight supply
obj.connect('SinglePowerSupply') % Select one from two power supplies: SinglePowerSupply with one output and TriplePowerSupply with three outputs

obj.ReadVoltage([]) % Command to Read the voltage
obj.ReadCurrent([])  % Command to Read the current

obj.powerOn([])  % Command to activate the port

obj. setVoltage(5, []) % To set the voltage to 5V
obj.powerOff([])  % Command to deactivate the port

