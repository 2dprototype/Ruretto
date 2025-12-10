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
import "console"

// console.hide()

// Comment out this code to generate logo
// ctx := canvas.new_context(500, 500)
// drawchip(ctx, 250, 250, "", 600)
// ctx.save_png("icon.png")
// os.exit(0)

audio.init()

var user_dir = path.join(os.getenv("appdata"), "Rūretto")
var user_file = path.join(user_dir, "userdata.dat")
var history_file = path.join(user_dir, "history.dat")
if !fs.exists(user_dir) {
	fs.mkdir(user_dir)
}

var global = {
	points: bigint(25000),
	betting_scale: bigint(10),
	betting_chips: [],
	last_won: bigint(0)
}

var game_history = []

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
var show_history = false
var font_data = embed("res/IBMPlexSans-Bold.ttf")
var comment = ""

fn save_file(){
	fs.writefile(user_file, json.encode(global))
	if game_history.length > 0 {
		fs.writefile(history_file, json.encode(game_history))
	}
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
	
	// Load game history
	if fs.exists(history_file) {
		data := fs.readfile(history_file)
		history_data := json.decode(data)
		if !is_error(history_data) {
			game_history = history_data
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

fn add_to_history(bet_amount, result, won_amount, balance_change) {
	history_entry := {
		timestamp: times.time_format(times.now(), "02 Jan 06 15:04"),
		bet: bet_amount,
		result_number: result.number,
		result_color: result.color,
		won: won_amount,
		balance_change: balance_change,
		final_balance: global.points
	}
	
	// game_history.unshift(history_entry) // Add to beginning
	game_history.push(history_entry) // Add to beginning
	
	// Keep only last 100 games
	if game_history.length > 100 {
		game_history = game_history.slice(0, 100)
	}
	
	save_file()
}

fn draw_history_panel(ctx, x, y, width, height) {
	// Draw background
	// ctx.hex(theme.bg + "F0")
	ctx.hex("121212")
	ctx.rect(x, y, width, height)
	ctx.fill()
	
	// ctx.hex(theme.white + "40")
	// ctx.rect(x, y, width, height)
	// ctx.stroke()
	
	// Draw title
	ctx.fontface(font_data, scale/3)
	ctx.hex(theme.white)
	title := "Game History"
	title_kl := ctx.measure_text(title)
	ctx.text(title, x + width/2 - title_kl[0]/2, y + scale/2 + title_kl[1]/2)
	ctx.fill()
	
	ctx.linewidth(1)
	// Draw close button
	close_btn_size := scale/3
	ctx.hex(theme.red)
	cx := x + width - close_btn_size - 5
	cy := y + close_btn_size + 5
	ctx.circle(cx, cy, close_btn_size)
	ctx.stroke()
	
	// ctx.fontface(font_data, scale/2)
	// kl := ctx.measure_text("x")
	// ctx.text("x", cx - close_btn_size/2 + kl[0]/2, cy + kl[1]/2)
	
	// ctx.fontface(font_data, scale/3)
	
	bounds.push([x + width - close_btn_size*2 - 5, y + 5, close_btn_size*2, close_btn_size*2, 150]) // Close button ID
	
	// Calculate area for history items
	var start_y = y + scale
	var item_height = scale/1.5
	var max_items = math.floor((height - scale*2) / item_height)
	
	// Draw column headers
	ctx.hex(theme.white + "80")
	headers := ["Time", "Bet", "Result", "Won", "Balance"]
	col_width := width / headers.length
	
	for i, header in headers {
		header_x := x + i * col_width + 5
		kl := ctx.measure_text(header)
		ctx.text(header, header_x, start_y + item_height/2 + kl[1]/2)
		ctx.fill()
	}
	
	// Draw separator line
	ctx.linewidth(1)
	ctx.hex(theme.white + "40")
	ctx.move_to(x, start_y + item_height)
	ctx.line_to(x + width, start_y + item_height)
	ctx.stroke()
	
	// Draw history items
	start_y += item_height + 5
	

	for i, entry in reverse(game_history) {
		if i >= max_items-1 {
			break
		}
		
		item_y := start_y + i * item_height
		
		// Alternate row colors
		if i % 2 == 0 {
			ctx.hex(theme.white + "10")
			ctx.rect(x, item_y, width, item_height)
			ctx.fill()
		}
		
		// Format time
		time_str := entry.timestamp
		
		// Format bet
		bet_str := funcs.format_num(entry.bet)
		
		// Format result
		result_str := format(`%s %s`, string(entry.result_number), entry.result_color == theme.red ? "R" : "B")
		
		var won_str
		var won_color
		
		// Format winnings
		if entry.won > 0 {
			won_str = format(`+$%s`, funcs.format_num(entry.won))
			won_color = theme.green
		}
		
		else if entry.won < 0 {
			won_str = format(`-$%s`, funcs.format_num(math.abs(entry.won)))
			won_color = theme.red
		}
		else {
			won_str = "$0"
			won_color = theme.white + "80"
		}
		
		var balance_str
		var balance_color
		
		// Format balance change
		if entry.balance_change > 0 {
			balance_str = format(`+$%s`, funcs.format_num(entry.balance_change))
			balance_color = theme.green
		}
		else if entry.balance_change < 0 {
			balance_str = format(`-$%s`, funcs.format_num(math.abs(entry.balance_change)))
			balance_color = theme.red
		}
		else {
			balance_str = "$0"
			balance_color = theme.white + "80"
		}
		
		// Draw columns
		columns := [time_str, "$" + bet_str, result_str, won_str, balance_str]
		colors := [theme.white + "80", theme.white + "80", theme.white + "80", won_color, balance_color]
		
		for j, col_text in columns {
			col_x := x + j * col_width + 5
			kl := ctx.measure_text(col_text)
			ctx.hex(colors[j])
			ctx.text(col_text, col_x, item_y + item_height/2 + kl[1]/2)
			ctx.fill()
		}
	}
	
	// Draw "No games played yet" message if history is empty
	if game_history.length == 0 {
		ctx.hex(theme.white + "60")
		msg := "No games played yet"
		kl := ctx.measure_text(msg)
		ctx.text(msg, x + width/2 - kl[0]/2, start_y + height/3)
		ctx.fill()
	}
	
	// Draw summary at bottom
	if game_history.length > 0 {
		total_won := 0
		total_lost := 0
		wins := 0
		losses := 0
		
		for entry in game_history {
			if entry.won > 0 {
				total_won += entry.won
				wins += 1
			}
			else if entry.won < 0 {
				total_lost += math.abs(entry.won)
				losses += 1
			}
		}
		
		summary_y := y + height - scale/4
		
		// Win rate
		total_games := wins + losses
		win_rate := total_games > 0 ? ((float(wins) / total_games) * 100) : 0
		
		summary_text := format(`Games: %d | Wins: %d (%.0f%%) | Profit: $%s`, 
			total_games, wins, win_rate, funcs.format_num_comma(total_won - total_lost))
		
		ctx.hex(theme.white + "80")
		ctx.fontface(font_data, scale/3.5)
		kl := ctx.measure_text(summary_text)
		ctx.text(summary_text, x + width/2 - kl[0]/2, summary_y)
		ctx.fill()
	}
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
	
	// Draw history button
	history_btn_x := w - scale/2 - 10
	history_btn_y := scale/2 + 10
	ctx.linewidth(1)
	// ctx.hex(theme.white + "20")
	// ctx.circle(history_btn_x, history_btn_y, scale/3)
	// ctx.fill()
	ctx.hex(theme.white)
	ctx.circle(history_btn_x, history_btn_y, scale/3)
	ctx.stroke()
	
	bounds.push([history_btn_x - scale/3, history_btn_y - scale/3, scale, scale, 151]) // History button ID
	
	// Draw history panel if shown
	if show_history {
		panel_width := w * 0.8
		panel_height := h * 0.7
		panel_x := (w - panel_width) / 2
		panel_y := (h - panel_height) / 2
		draw_history_panel(ctx, panel_x, panel_y, panel_width, panel_height)
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


var options = {
    width: w,
    height: h,
    title: "Rūretto",
    x: 150,
    y: 80
}

canvas.new_window(options, fn(window){
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
					
					// Handle history panel close button
					if show_history && id == 150 {
						show_history = false
						draw(ctx)
						window.update(w, h)
						continue
					}
					
					// Handle history button
					if id == 151 {
						show_history = !show_history
						draw(ctx)
						window.update(w, h)
						continue
					}
					
					// If history panel is open, only allow clicking on close button
					if show_history {
						continue
					}
					
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
						// Calculate total bet before spin
						total_bet_before := 0
						for chip in global.betting_chips {
							total_bet_before += chip[1]
						}
						
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
						
						points_before := global.points
						rules(global, luck)
						global.last_won = global.points - last_points
						
						// Calculate winnings/losses
						won_amount := 0
						balance_change := global.points - points_before
						
						if balance_change > 0 {
							won_amount = balance_change
						} else {
							won_amount = -total_bet_before
						}
						
						// Add to history
						add_to_history(total_bet_before, luck, won_amount, balance_change)
						
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
				}
			}
		}
	}
})