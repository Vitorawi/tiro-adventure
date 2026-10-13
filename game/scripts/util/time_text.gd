class_name TimeText
extends RefCounted
## Texto curto de duração ("45s", "3 min", "2:30", "1h 05"). Usado pelo estado
## (mensagens de erro) e pela interface, por isso não fica no SheetBuilder.


static func short(seconds: int) -> String:
	seconds = maxi(0, seconds)
	if seconds >= 86400:
		return "%dd %dh" % [seconds / 86400, (seconds % 86400) / 3600]
	if seconds >= 3600:
		return "%dh %02d" % [seconds / 3600, (seconds % 3600) / 60]
	if seconds >= 60 and seconds % 60 == 0:
		return "%d min" % (seconds / 60)
	if seconds >= 60:
		return "%d:%02d" % [seconds / 60, seconds % 60]
	return "%ds" % seconds
