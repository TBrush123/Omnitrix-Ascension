extends Node

@export var stat_upgrade_pool: Array[RewardCard] = []
@export var alien_roster: Array[AlienData] = []
@export var item_pool: Array[RewardCard] = []

func _ready() -> void:
    _load_aliens()
    _load_stat_upgrades()
    _load_items()

func _load_aliens() -> void:
    var dir = DirAccess.open("res://Player/Aliens/Data/")
    if dir == null:
        push_error("Could not open aliens directory")
        return
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".tres"):
            var resource = load("res://Player/Aliens/Data/" + file)
            if resource is AlienData:
                alien_roster.append(resource)
        file = dir.get_next()
    dir.list_dir_end()


func _load_stat_upgrades() -> void:
    var dir = DirAccess.open("res://Cards/stat/")
    if dir == null:
        push_error("Could not open stat cards directory")
        return
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".tres"):
            var resource = load("res://Cards/stat/" + file)
            if resource is RewardCard:
                stat_upgrade_pool.append(resource)
        file = dir.get_next()
    dir.list_dir_end()


func _load_items() -> void:
    var dir = DirAccess.open("res://Cards/items/")
    if dir == null:
        push_error("Could not open items directory")
        return
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".tres"):
            var resource = load("res://Cards/items/" + file)
            if resource is RewardCard:
                item_pool.append(resource)
        file = dir.get_next()
    dir.list_dir_end()