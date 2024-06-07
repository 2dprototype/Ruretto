import "canvas"
import "times"
import "json"
import "math"
import "os"
import "path"
import "audio"
import "fs"
import "helper/randint" // https://github.com/2dprototype/tender-free/blob/master/pkg/helper/randint.td
import "table"
import "funcs"
import "wheel"
import "rules"
import "drawchip"
import "theme"

// Comment out this code to generate logo
// ctx := canvas.new_context(500, 500)
// drawchip(ctx, 250, 250, "", 600)
// ctx.save_png("icon.png")
// os.exit(0)

audio.init()

var user_dir = path.join(os.getenv("appdata"), "Rūretto")
var user_file = path.join(user_dir, "userdata.dat")
if !fs.exists(user_dir) {
	fs.mkdir(user_dir)
}

var global = {
	points: 25000,
	betting_scale: 10,
	betting_chips: [],
	last_won: 0
}

var w = 700
var h = 400

var betting_scales = [10, 50, 100, 500, 1000, 5000, 10000, 50000, 1000000, 5000000, 10000000, 50000000]
var betting_scale_index = 0

var bounds = []
var previous_bet = null
var previous_bet_index = null
var scale = 30
var b_x = w/2 - 2.3*scale
var b_y = h/2 - 3.5*scale
var radius = 3.5*scale
var cy = b_y + 100
var cx = b_x - 150
var is_gameover = false
var font_data = embed("res/IBMPlexSans-Bold.ttf")
var comment = ""

fn save_file(){
	fs.writefile(user_file, json.encode(global))
}

fn load_file() {
	if fs.exists(user_file) {
		data := fs.readfile(user_file)
		obj := json.decode(data)
		if !is_error(obj) {
			global.points = int(obj.points) || 0
			global.betting_scale = int(obj.betting_scale) || 0
			global.last_won = int(obj.last_won) || 0
			global.betting_chips = obj.betting_chips
			if global.betting_scale == global.points {
				betting_scale_index = -1
			}
			else {
				for i := betting_scales.length - 1; i >= 0; i-- {
					if betting_scales[i] <= global.points {
						global.betting_scale = betting_scales[i]
						betting_scale_index = i
						break
					}
				}
			}
		}
		
		total_bet := 0
		for chip in global.betting_chips {
			total_bet += chip[1]
		}
		
		if global.points == 0 && total_bet == 0 {
			is_gameover = true
		}
	}
}

var last_points = global.points

fn reset(){
	global.points = 25000
	global.betting_scale = 10
	global.last_won = 0
	global.betting_chips = []
	is_gameover = false
	comment = ""
	save_file()
	last_points = global.points
}

fn draw(ctx) {
	scale = w/23
	if scale > 45 {
		scale = 45
	}
	b_x = w/2 - 2.3*scale
	b_y = h/2 - 3.5*scale
	radius = 3.5*scale
	cy = b_y + 3.33*scale
	cx = b_x - 5*scale
	
	bounds = []
	ctx.hex(theme.bg)
	ctx.clear()
	ctx.fontface(font_data, scale/2.5)
	ctx.linewidth(1.2)
	for i, items in table {
		for j, item in items {
			ctx.hex(item.color)
			x := b_x + i*scale
			y := b_y + j*scale
			ctx.rect(x, y, scale, scale)
			ctx.fill()	
			if item.color == theme.red {
				ctx.hex(theme.black)
			}	
			else if item.color == theme.black {
				ctx.hex(theme.red)
			}
			kl := ctx.measure_text(item.number)
			ctx.text(item.number, x - (kl[0]/2) + scale/2, y + (kl[1]/2)  + scale/2)
			ctx.fill()	
			bounds.push([x, y, scale, scale, item.number])
		}
	}
	for i := 0; i < 3; i++ {
		ctx.hex(theme.white)
		x := b_x + i*scale*4
		y := b_y + 3*scale
		ctx.hex(theme.white + "09")		
		ctx.rect(x, y, scale*4, scale)
		ctx.fill()
		label := format(`%d to %d`, (i*12)+1, (i+1)*12)
		kl := ctx.measure_text(label)
		ctx.hex(theme.white + "90")		
		ctx.text(label, x - (kl[0]/2) + scale*2, y + (kl[1]/2)  + scale/2)
		ctx.fill()
		bounds.push([x, y, scale*4, scale, 40+i])		
	}
	labels := ["1-18", "EVEN", "RED", "BLACK", "ODD", "19-36"]
	for i := 0; i < 6; i++ {
		x := b_x + i*scale*2
		y := b_y + 4*scale
		ctx.hex(theme.white + "09")		
		if i == 2 {
			ctx.hex(theme.red)
		}
		else if i == 3 {
			ctx.hex(theme.black)
		}
		ctx.rect(x, y, scale*2, scale)
		ctx.fill()	
		ctx.hex(theme.white + "90")
		kl := ctx.measure_text(labels[i])
		ctx.text(labels[i], x - (kl[0]/2) + scale, y + (kl[1]/2)  + scale/2)
		ctx.fill()
		bounds.push([x, y, scale*2, scale, 43+i])
	}
	for j := 0; j < 3; j++ {
		x := b_x + 12*scale
		y := b_y + j*scale
		ctx.hex(theme.white + "09")
		ctx.rect(x, y, scale, scale)
		ctx.fill()
		ctx.hex(theme.white + "90")
		kl := ctx.measure_text("2-1")
		ctx.text("2-1", x - (kl[0]/2) + scale/2, y + (kl[1]/2)  + scale/2)
		ctx.fill()
		bounds.push([x, y, scale, scale, 49+j])		
	}
	
	
	x := b_x - scale
	y := b_y
	label := 0
	kl := ctx.measure_text(label)
	ctx.hex(theme.green)
	ctx.rect(x, y, scale, scale*3)
	ctx.fill()

	ctx.hex(theme.black)
	ctx.text(label, x - (kl[0]/2) + scale/2, y + (kl[1]/2)  + scale*1.5)
	ctx.stroke()
	bounds.push([x, y, scale, scale*3, 0])		
	
	if is_gameover {
		x := b_x 
		y := b_y + 7*scale
		label := "Play Again?"
		kl := ctx.measure_text(label)
		ctx.hex(theme.white)
		ctx.rect(x, y, scale*4, scale)
		ctx.fill()	
		ctx.hex(theme.black)
		ctx.text(label, x - kl[0]/2 + scale*2, y + kl[1]/2  + scale/2)
		ctx.fill()	
		bounds.push([x, y, scale*4, scale, 103])
	}
	else {
		labels = ["CLEAR", "DOUBLE", "ALL", "SPIN"]
		for i := 0; i < labels.length; i++ {
			x := b_x + (i*1.2)*scale*2
			y := b_y + 7*scale
			ctx.linewidth(1)
			kl := ctx.measure_text(labels[i])
			ctx.hex(theme.white + "80")
			if global.betting_scale == global.points && labels[i] == "ALL" {
				ctx.hex(theme.red)	
			}
			ctx.rect(x, y, scale*2, scale)
			ctx.stroke()	
			ctx.text(labels[i], x - (kl[0]/2) + scale, y + (kl[1]/2)  + scale/2)
			ctx.fill()	
			bounds.push([x, y, scale*2, scale, 100+i])
		}
	}
	
	var slots = wheel.length
	var a = 2 * math.pi / slots
	
	fn draw_wheel(index) {
		slot := wheel[index]
		start_angle := index * a
		end_angle := start_angle + a

		ctx.move_to(cx, cy)
		ctx.arc(cx, cy, radius, start_angle, end_angle)
		ctx.closepath()
		ctx.hex(slot.color)
		ctx.fill()	

		ctx.push()
		ctx.translate(cx, cy)
		ctx.rotate(start_angle + a / 2)
		ctx.hex(theme.black)
		if slot.color == theme.red {
			ctx.hex(theme.black)
		}	
		else if slot.color == theme.black {
			ctx.hex(theme.red)
		}
		ctx.text(slot.number, radius - 0.6*scale, 5)
		ctx.fill()
		ctx.pop()
	}

	for index, _ in wheel {
		if index == 0 {
			continue
		}
		draw_wheel(index)
	}

	ctx.hex(theme.red)
	ctx.linewidth(2)

	ctx.circle(cx, cy, radius-0.8*scale)
	ctx.stroke()
	
	draw_wheel(0)
	
	ctx.hex(theme.bg)
	ctx.circle(cx, cy, radius-1.66*scale)
	ctx.fill()
	
	ctx.hex(theme.red)
	ctx.circle(cx, cy, radius-1.66*scale)
	ctx.stroke()

	if previous_bet_index != null {
		ctx.push()
		ctx.translate(cx, cy)
		ctx.rotate((previous_bet_index * a) + a / 2)
		ctx.hex(theme.ball)
		ctx.circle(radius-2*scale, 0, scale/7.9)
		ctx.fill()
		ctx.pop()
	}
	
	
	total_bet := 0
	for chip in global.betting_chips {
		total_bet += chip[1]
	}
	
	label = format(`$%s   $%s`, funcs.format_num_comma(global.points), funcs.format_num_comma(total_bet))
	kl = ctx.measure_text(label)
	ctx.hex(theme.white)
	ctx.text(label, 10, scale/2 + kl[1]/2)
	ctx.fill()	

	label = format(`$%s`, funcs.format_num_comma(global.last_won))
	if global.last_won > 0 {
		ctx.hex(theme.green)
		label = format(`+$%s`, funcs.format_num_comma(global.last_won))
	}
	else if global.last_won < 0 {
		ctx.hex(theme.red)
		label = format(`-$%s`, funcs.format_num_comma(math.abs(global.last_won)))
	}

	lx := kl[0]
	kl = ctx.measure_text(label)
	ctx.text(label, 20 + lx, scale/2 + kl[1]/2)
	ctx.fill()		

	
	if comment != "" {
		kl2 := ctx.measure_text(comment)
		ctx.hex(theme.white)
		ctx.text(comment, b_x + scale*6 - kl2[0]/2, b_y - scale)
		ctx.fill()
		
	}
	
	if previous_bet != null {
		kl := ctx.measure_text(previous_bet.number)
		ctx.hex(previous_bet.color)
		if previous_bet.color == theme.black {
			ctx.hex(theme.white + "10")
		}
		ctx.circle(cx, cy, scale/2)
		ctx.fill()	
		ctx.hex(theme.black)
		if previous_bet.color == theme.red {
			ctx.hex(theme.black)
		}
		else if previous_bet.color == theme.black {
			ctx.hex(theme.red)
		}
		ctx.text(previous_bet.number, cx - kl[0]/2, cy + kl[1]/2)
		ctx.fill()
	}
	
	ctx.fontface(font_data, scale/3.8)
	
	for i := 0; i < betting_scales.length; i++ {
		if global.points >= betting_scales[i] {
			x := b_x + (i*1.2)*scale/1.2 + scale/3
			y := b_y + 6*scale
			label := funcs.format_num(betting_scales[i])
			if i == betting_scale_index {
				ctx.hex(theme.white + "50")
				ctx.circle(x, y, scale/2)
				ctx.fill()
			}
			drawchip(ctx, x, y, label, scale)
			bounds.push([x-scale/2.5, y-scale/2.5, scale*0.8, scale*0.8, 200+i])
		}
	}
	
	col := {}
	
	for chip in global.betting_chips {
		if col[chip[0]] == null {
			col[chip[0]] = chip[1]
		}
		else {
			col[chip[0]] += chip[1]
		}
		if bounds.length > chip[0] {
			bound := bounds[int(chip[0])]
			label := funcs.format_num(col[chip[0]])
			drawchip(ctx, bound[0] + bound[2]/2, bound[1] + bound[3]/2, label, scale)
		}
	}
}


fn intro(ctx, window){
	ctx.hex(theme.bg)
	ctx.clear()
	ctx.hex(theme.white)
	ctx.fontface(font_data, scale)
	
	kw := ctx.measure_text("2DPROTOTYPE")
	ctx.text("2DPROTOTYPE", w/2 - kw[0]/2, h/2 - kw[1]/2)
	ctx.rect(w/2 - kw[0]/2, h/2, kw[0], 10)
	ctx.stroke()
	window.update(w, h)
	
	for i := 0; i < 1; i += 0.05 {
		ctx.rect(w/2 - kw[0]/2, h/2, kw[0] * i, 10)
		ctx.fill()
		window.update(w, h)
		times.sleep(times.second/40)
	}
}

canvas.new_window(w, h, "Rūretto", fn(window){
	ctx := window.new_context(w, h)
	intro(ctx, window)
	load_file()
	last_points = global.points
	draw(ctx)
	window.update(w, h)
	for {
		e := window.next_event()
		if e.type == "size" {
			w = e.width_px 
			h = e.height_px
			ctx = window.new_context(e.width_px, e.height_px)
			draw(ctx)
			window.update(w, h)
		}
		else if e.type == "lifecycle" && e.from == 3 && e.to == 0 {
			break
		}
		else if e.type == "mouse" && e.direction == 1 {
			for b_index, b in bounds {
				ax := b[0]
				ay := b[1]
				aw := b[2]
				ah := b[3]
				if ax < e.x && ay < e.y && ax + aw > e.x && ay + ah > e.y {
					var id = b[4]
					if is_gameover {
						if id == 103 {
							reset()
							draw(ctx)
							window.update(w, h)
						}
						continue
					}
					if id < 200 {
						ctx.hex(theme.white + "25")
						ctx.rect(b[0], b[1], b[2], b[3])
						ctx.fill()
						window.update(w, h)
					}
				
					if id >= 200 {
						if id-200 < betting_scales.length {
							global.betting_scale = betting_scales[id-200]
							betting_scale_index = id-200
						}
					}
					else if id < 100 {
						if global.points == 0 {
						}
						else if global.points > global.betting_scale  {
							global.points -= global.betting_scale
							global.betting_chips.push([b_index, global.betting_scale, b[4]])
						}
						else {
							global.betting_chips.push([b_index, global.points, b[4]])
							global.points = 0
						}
						if betting_scale_index >= 0 {
							if betting_scales[betting_scale_index] > global.points {
								for i := betting_scales.length - 1; i >= 0; i-- {
									if betting_scales[i] <= global.points {
										global.betting_scale = betting_scales[i]
										betting_scale_index = i
										break
									}
								}
							}
						}
					}
					else if id == 100 {
						for chip in global.betting_chips {
							global.points += chip[1]
						} 
						global.betting_chips = []
					}	
					else if id == 101 {
						for chip in global.betting_chips {
							r := chip[1] * 2
							if global.points > r  {
								global.points -= r
								chip[1] = r
							}
							else {
								break
							}
						}
					}
					else if id == 102 {
						global.betting_scale = global.points
						betting_scale_index = -1
					}
 					else if id == 103 {
						index := randint(0, wheel.length - 1)
						luck := wheel[index]
						fn(){
							var slots = wheel.length
							var a = 2 * math.pi / slots
							ii := index
							if ii < 10 {
								ii = index+36
							}
							for i := 0; i < ii; i++ {
								start_angle := i * a
								end_angle := start_angle + a

								ctx.hex(theme.bg)
								ctx.circle(cx, cy, radius-1.66*scale)
								ctx.fill()
								ctx.hex(theme.red)
								ctx.circle(cx, cy, radius-1.66*scale)
								ctx.stroke()
								
								ctx.push()
								ctx.translate(cx, cy)
								ctx.rotate(start_angle + a / 2)
								ctx.hex(theme.ball)
								ctx.circle(radius-2*scale, 0, scale/7.9)
								ctx.fill()
								ctx.pop()
								
								window.update(w, h)
								times.sleep(times.second/20)
							}
						}()
						rules(global, luck)
						global.last_won = global.points - last_points
						if global.last_won < 0 {
							go(fn(){
								a := audio.player(embed("res/wooh.mp3"))
								a.play()
								for a.is_playing() {}
							})
						}
						last_points = global.points
						global.betting_chips = []
						previous_bet = luck
						previous_bet_index = index
						if global.points == 0 {
							comment = "Woooh! You lost all of your chips, didn't you?"
							is_gameover = true
						}
						else if global.points >= 1000000000 {
							comment = "Damn! You've become a billionaire!"
						}
						else if global.points < 1000000000 {
							comment = ""
						}
					} 
					draw(ctx)
					window.update(w, h)
					save_file()
					// sysout format("0x%05x %d\n", id, id).yellow
				}
			}
		}
	}
})