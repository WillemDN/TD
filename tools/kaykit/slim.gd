extends SceneTree
# Keep only the animations the game uses and save each character as a compact .scn
const KEEP := ["Walking_A", "Walking_B", "Idle", "Death_A", "Hit_A", "Running_A"]
func _init() -> void:
	for n in ["Barbarian","Knight","Mage","Rogue","Rogue_Hooded","Skeleton_Warrior","Skeleton_Mage","Skeleton_Minion","Skeleton_Rogue"]:
		var root: Node = load("res://in/chars/%s.glb" % n).instantiate()
		var ap: AnimationPlayer = root.find_child("AnimationPlayer", true, false)
		if ap != null:
			var lib: AnimationLibrary = ap.get_animation_library("")
			for a in lib.get_animation_list():
				if not (a in KEEP):
					lib.remove_animation(a)
		_embed_textures(root)
		_own(root, root)
		var ps := PackedScene.new()
		var err := ps.pack(root)
		var path := "res://out/%s.scn" % n
		print(n, " pack ", err, " save ", ResourceSaver.save(ps, path, ResourceSaver.FLAG_COMPRESS))
		root.free()
	quit()
func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)

# imported textures are external files: embed them so the saved scene is self-contained
func _embed_textures(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(i)
			if m is BaseMaterial3D and m.albedo_texture != null and m.albedo_texture.resource_path != "":
				var img: Image = m.albedo_texture.get_image()
				m.albedo_texture = ImageTexture.create_from_image(img)
	for c in n.get_children():
		_embed_textures(c)
