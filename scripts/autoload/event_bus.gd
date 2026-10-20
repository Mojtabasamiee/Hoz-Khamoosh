extends Node
## EventBus — global signals

signal objective_changed(text: String)
signal toast(text: String, dur: float)
signal prompt_changed(text: String)
signal item_added(id: String)
signal item_removed(id: String)
signal power_on
signal pool_drained
signal clock_solved
signal drawer_opened
signal valves_solved
signal symbols_solved
signal chapter_changed(n: int)
signal ui_open_changed(open: bool)
signal request_fade(out: bool, dur: float)
signal save_requested
signal flashlight_state(on: bool, battery: float)
