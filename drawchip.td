import "math"
import "theme"

export fn(ctx, x, y, label, b_size) {
	kl := ctx.measure_text(label)
	
	var a = 2 * math.pi / 10

	for k := 0; k < 10; k++  {
		start_angle := k * a
		end_angle := start_angle + a

		ctx.move_to(x, y)
		ctx.arc(x, y, b_size/2.5, start_angle, end_angle)
		ctx.closepath()
		ctx.hex(k % 2 == 0 ? theme.white: theme.chip)
		ctx.fill()	
	}

	ctx.hex(theme.chip)
	ctx.circle(x, y, b_size/3.2)
	ctx.fill()	

	ctx.hex("#00000040")
	ctx.circle(x, y, b_size/3.2)
	ctx.fill()	

	ctx.hex("#000000bb")
	ctx.text(label, x - (kl[0]/2), y + (kl[1]/2))
	ctx.fill()	
}