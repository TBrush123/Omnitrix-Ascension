class_name StatModifier
extends Resource

enum Type {
    FLAT,
    PERCENT
}

@export var stat: String
@export var type: Type
@export var value: float
@export var source: String = ""