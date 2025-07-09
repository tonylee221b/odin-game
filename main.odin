package game

import "core:fmt"
import la "core:math/linalg"
import rl "vendor:raylib"

Animation_Name :: enum {
	Idle,
	Run,
	Fire,
}

Input_State :: struct {
	move_left:  bool,
	move_right: bool,
	move_up:    bool,
	move_down:  bool,
	fire:       bool,
}

Player_State :: enum {
	Idle,
	Moving,
	Firing,
}

Animation :: struct {
	texture:       rl.Texture2D,
	num_frames:    int,
	frame_timer:   f32,
	current_frame: int,
	frame_length:  f32,
	name:          Animation_Name,
}

update_animation :: proc(a: ^Animation) {
	a.frame_timer += rl.GetFrameTime()

	if a.frame_timer > a.frame_length {
		a.current_frame += 1
		a.frame_timer = 0

		if a.current_frame == a.num_frames {
			// Fire animation doesn't loop, others do
			if a.name != .Fire {
				a.current_frame = 0
			} else {
				a.current_frame = a.num_frames - 1
			}
		}
	}
}

draw_animation :: proc(a: Animation, pos: rl.Vector2, flip: bool) {
	width := f32(a.texture.width)
	height := f32(a.texture.height)

	source := rl.Rectangle {
		x      = f32(a.current_frame) * width / f32(a.num_frames),
		y      = 0,
		width  = width / f32(a.num_frames),
		height = height,
	}

	if flip {
		source.width = -source.width
	}

	dest := rl.Rectangle {
		x      = pos.x,
		y      = pos.y,
		width  = width * 0.6 / f32(a.num_frames),
		height = height * 0.6,
	}

	rl.DrawTexturePro(a.texture, source, dest, 0, 0, rl.WHITE)
}

get_input :: proc() -> Input_State {
	return Input_State{
		move_left  = rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A),
		move_right = rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D),
		move_up    = rl.IsKeyDown(.UP) || rl.IsKeyDown(.W),
		move_down  = rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S),
		fire       = rl.IsMouseButtonPressed(.LEFT),
	}
}

process_input :: proc(input: Input_State, player_pos: ^rl.Vector2, player_vel: ^rl.Vector2, player_flip: ^bool, player_speed: f32, state: Player_State) -> (rl.Vector2, bool) {
	if state == .Firing {
		return rl.Vector2{0, 0}, player_flip^
	}

	velocity := rl.Vector2{0, 0}
	flip := player_flip^

	if input.move_left {
		velocity.x = -1
		flip = true
	}
	if input.move_right {
		velocity.x = 1
		flip = false
	}
	if input.move_up {
		velocity.y = -1
	}
	if input.move_down {
		velocity.y = 1
	}

	if velocity.x != 0 || velocity.y != 0 {
		velocity = la.normalize0(velocity) * rl.GetFrameTime() * player_speed
	}

	return velocity, flip
}

main :: proc() {
	rl.InitWindow(1280, 720, "Procty")
	rl.SetWindowPosition(30, 60)
	rl.SetTargetFPS(120)

	player_pos := rl.Vector2{640, 320}
	player_vel: rl.Vector2
	player_speed: f32 = 400.0
	player_flip: bool
	player_state: Player_State = .Idle
	previous_anim: Animation
	fire_flip: bool

	player_run := Animation {
		texture      = rl.LoadTexture(
			"./assets/Tiny Swords (Free Pack)/Units/Black Units/Archer/Archer_Run.png",
		),
		num_frames   = 4,
		frame_length = 0.1,
		name         = .Run,
	}

	player_idle := Animation {
		texture      = rl.LoadTexture(
			"./assets/Tiny Swords (Free Pack)/Units/Black Units/Archer/Archer_Idle.png",
		),
		num_frames   = 6,
		frame_length = 0.1,
		name         = .Idle,
	}

	player_fire := Animation {
		texture      = rl.LoadTexture(
			"./assets/Tiny Swords (Free Pack)/Units/Black Units/Archer/Archer_Shoot.png",
		),
		num_frames   = 8,
		frame_length = 0.1,
		name         = .Fire,
	}

	current_anim := player_idle

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({110, 184, 168, 255})

		input := get_input()

		// Handle firing
		if input.fire && player_state != .Firing {
			player_state = .Firing
			previous_anim = current_anim
			current_anim = player_fire
			current_anim.current_frame = 0
			current_anim.frame_timer = 0
			fire_flip = player_flip
		}

		// Process movement
		player_vel, player_flip = process_input(input, &player_pos, &player_vel, &player_flip, player_speed, player_state)

		// Update animation based on state
		switch player_state {
		case .Firing:
			if current_anim.current_frame >= current_anim.num_frames - 1 {
				player_state = .Idle
				current_anim = previous_anim
			}
		case .Moving:
			if player_vel.x != 0 || player_vel.y != 0 {
				if current_anim.name != .Run {
					current_anim = player_run
				}
			} else {
				player_state = .Idle
				current_anim = player_idle
			}
		case .Idle:
			if player_vel.x != 0 || player_vel.y != 0 {
				player_state = .Moving
				current_anim = player_run
			} else {
				if current_anim.name != .Idle {
					current_anim = player_idle
				}
			}
		}

		player_pos += player_vel

		update_animation(&current_anim)

		draw_flip := player_state == .Firing ? fire_flip : player_flip
		draw_animation(current_anim, player_pos, draw_flip)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
