systolic_bp=120
diastolic_bp=80
pulse_pressure= systolic_bp - diastolic_bp
print("Pulse pressure is ",pulse_pressure)
map=diastolic_bp + (0.412 * pulse_pressure)
print("Mean arterial pressure is ",map)
fractional_pulse_pressure = pulse_pressure/map
print("Fractional pulse pressure is ",fractional_pulse_pressure)
