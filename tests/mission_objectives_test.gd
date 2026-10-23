extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)


func run() -> void:
	var config: MissionConfig = load("res://resources/missions/asset_recovery.tres")
	check(config.validation_error().is_empty(), "S configuration validates against both finite layouts")
	var invalid := config.duplicate(true) as MissionConfig
	invalid.objective_definitions[0].target = 15
	check(not invalid.validation_error().is_empty(), "Impossible material targets rejected")
	invalid = config.duplicate(true)
	invalid.objective_definitions[1].objective_id = invalid.objective_definitions[0].objective_id
	check(not invalid.validation_error().is_empty(), "Duplicate objective IDs rejected")
	invalid = config.duplicate(true)
	invalid.objective_definitions[0].target = 0
	check(not invalid.validation_error().is_empty(), "Invalid target rejected")
	invalid = config.duplicate(true)
	invalid.objective_definitions[1].required = false
	check(not invalid.validation_error().is_empty(), "Required extraction cannot be omitted")
	invalid = config.duplicate(true)
	invalid.player_extraction = false
	check(not invalid.validation_error().is_empty(), "Banking requires recall support")
	var ledger := MaterialLedger.new({&"site": 6}, [1, 2])
	var equipment := EquipmentLedger.new()
	equipment.assign_loadout(1, false)
	var model := MissionObjectives.new(config, ledger, equipment, 123, "deployment")
	check(model.snapshot().size() == 4 and not model.required_satisfied(false), "Deterministic empty objective initialization")
	ledger.collect(1, &"site", 3)
	var drop := ledger.defeat(1)
	ledger.recover(drop)
	equipment.resolve(1)
	equipment.recover(1)
	check(model.snapshot()[0].progress == 0 and model.snapshot()[0].carried == 3 and model.snapshot()[0].status == "pending", "Possession shows readiness without banked completion")
	var event := {"deployment_id": "deployment", "victim": 1, "instigator": 123, "eligible": true}
	model.accepted_defeat(event)
	model.accepted_defeat(event)
	model.accepted_defeat({"deployment_id": "older", "victim": 2, "instigator": 123, "eligible": true})
	model.accepted_defeat({"deployment_id": "deployment", "victim": 2, "instigator": 99, "eligible": true})
	check(model.snapshot()[3].progress == 1, "Kill credit rejects duplicates, old deployments and other instigators")
	var copy := model.snapshot()
	copy[0].progress = 999
	check(model.snapshot()[0].progress == 0, "Objective inspection is detached")
	ledger.settle_player(true)
	check(not model.required_satisfied(false), "Banked loot cannot substitute for extraction")
	equipment.settle_player(true)
	check(model.required_satisfied(true), "Explicit terminal reconciliation reads both settled owners")
	var mission := MissionRules.new()
	mission.requires_extraction = true
	mission.complete_extraction(model.required_satisfied(true))
	model.close(mission, 42)
	var result := model.result()
	check(result.success and result.materials_banked == 3 and result.equipment_banked == 2 and result.materials_picked_up == 3, "Settled result is truthful without counting pickup and bank twice")
	result.objectives.clear()
	model.accepted_defeat({"deployment_id": "deployment", "victim": 2, "instigator": 123, "eligible": true})
	model.close(mission, 999)
	check(model.result().duration == 42 and model.result().objectives.size() == 4 and model.snapshot()[3].progress == 1, "Frozen results and completion are idempotent")
	model.dispose()
	var fresh_ledger := MaterialLedger.new({&"site": 3}, [1])
	var fresh_equipment := EquipmentLedger.new()
	var fresh := MissionObjectives.new(config, fresh_ledger, fresh_equipment, 123, "fresh")
	check(fresh.snapshot()[3].progress == 0 and fresh.snapshot()[0].carried == 0 and not fresh.is_closed(), "New deployment resets objectives and credit identities")
	fresh_ledger.settle_player(true)
	fresh_equipment.settle_player(true)
	var early := MissionRules.new()
	early.requires_extraction = true
	early.complete_extraction(fresh.required_satisfied(true))
	fresh.close(early, 5)
	check(early.player_extracted and early.phase == MissionRules.Phase.FAILED and fresh.snapshot()[0].status == "incomplete" and fresh.snapshot()[1].status == "completed", "Early extraction is terminal and distinct from mission success")
	fresh.dispose()
	check(ledger.is_conserved() and equipment.is_valid(), "Objective queries preserve accounting invariants")
	print("Stage S objective failures: ", failures)
	quit(0 if failures == 0 else 1)
