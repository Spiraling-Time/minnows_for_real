extends Node2D

const DISTANCE = 100
var target
var direction
var speed = 30
var bodySize
var approaching:bool = false
var mode = "fill"
var shape
var anchor
@onready var sprite = $sprite
