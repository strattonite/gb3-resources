const SAMPLE_DELAY = 1;
const MAX_SAMPLES = 100_000;

clear();
if (!("Wavegen1" in this) || !("Scope1" in this))
  throw "Please open a Scope and a Wavegen instrument";

Scope1.Trigger.Trigger.text = "Repeated";
Scope1.run();

let measurement_started = false;
let total_power = 0;
let start_idx = null;
let end_idx = null;

for (let i = 0; wait(SAMPLE_DELAY) && i < MAX_SAMPLES; i++) {}
