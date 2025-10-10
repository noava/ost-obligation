extends Node

var candle_lit: bool = true

func secondary_activation():
	candle_lit = !candle_lit

	$Flame.visible = candle_lit
	$OmniLight3D.visible = candle_lit