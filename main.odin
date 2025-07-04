package game

import "core:fmt"
import la "core:math/linalg"
import rl "vendor:raylib"

Animation_Name :: enum {
	Idle,
	Run,
	Fire,
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
			a.current_frame = 0
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
		width  = width / f32(a.num_frames),
		height = height,
	}

	rl.DrawTexturePro(a.texture, source, dest, 0, 0, rl.WHITE)
}

main :: proc() {
	rl.InitWindow(1280, 720, "Procty")
	rl.SetWindowPosition(30, 60)
	rl.SetTargetFPS(120)

	player_pos := rl.Vector2{640, 320}
	player_vel: rl.Vector2
	player_speed: f32 = 250.0
	player_flip: bool

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
		texture = rl.LoadTexture(
			"./assets/Tiny Swords (Free Pack)/Units/Black Units/Archer/Archer_Shoot.png",
		),
	}

	current_anim := player_idle

	rl.GetScreenWidth()
	rl.GetScreenHeight()


	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({110, 184, 168, 255})

		player_vel = rl.Vector2{0, 0} // 매 프레임 초기화

		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			player_vel.x = -1
			player_flip = true
		}
		if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			player_vel.x = 1
			player_flip = false
		}
		if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
			player_vel.y = -1
		}
		if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
			player_vel.y = 1
		}

		if player_vel.x != 0 || player_vel.y != 0 {
			player_vel = la.normalize0(player_vel) * rl.GetFrameTime() * 400

			if current_anim.name != .Run {
				current_anim = player_run
			}
		} else {
			if current_anim.name != .Idle {
				current_anim = player_idle
			}
		}

		player_pos += player_vel

		update_animation(&current_anim)
		draw_animation(current_anim, player_pos, player_flip)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
