class_name StatModifier
extends Resource

enum ModifierType {
    FLAT,
    PERCENT
}

@export var stat: String
@export var type: ModifierType
@export var value: float