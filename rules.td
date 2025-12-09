import "theme"

var columns = [
	[3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36],
	[2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35],
	[1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34]
]

export fn(global, luck){
	var straight_up = {}
	var column_bet = {"49":0,"50":0,"51":0}
	var dozen_bet = {"40":0,"41":0,"42":0}
	var bottom_bet = {"43":0,"44":0,"45":0,"46":0,"47":0,"48":0}
	var zeros = {"0":0}
	
	for chip in global.betting_chips {
		k := chip[2]
		if chip[2] > 0 && chip[2] <= 36 {
			if straight_up[k] == null {
				straight_up[k] = chip[1]
			}
			else {
				straight_up[k] += chip[1]
			}
		}	
		else if chip[2] >= 49 && chip[2] <= 51 {
			column_bet[k] += chip[1]
		}
		else if chip[2] >= 40 && chip[2] <= 42 {
			dozen_bet[k] += chip[1]
		}
		else if chip[2] >= 43 && chip[2] <= 48 {
			bottom_bet[k] += chip[1]
		}
		else if chip[2] == 0 {
			zeros["0"] += chip[1]
		}
	}
	k := string(luck.number)
	global.points += 36 * (includes(straight_up, k) ? straight_up[k] : 0)
	for i, v in columns {
		if includes(v, luck.number) {
			global.points += 3 * column_bet[string(49+i)]
		}
	}
	if luck.number >= 1 && luck.number <= 12 {
		global.points += 3 * dozen_bet["40"]
	}
	else if luck.number >= 13 && luck.number <= 24 {
		global.points += 3 * dozen_bet["41"]
	}	
	else if luck.number >= 25 && luck.number <= 36 {
		global.points += 3 * dozen_bet["42"]
	}
	
	if luck.number >= 1 && luck.number <= 18 {
		global.points += 2 * bottom_bet["43"]
	}
	else if luck.number >= 19 && luck.number <= 36 {
		global.points += 2 * bottom_bet["48"]
	}
	
	if luck.number % 2 == 0 {
		global.points += 2 * bottom_bet["44"]
	}
	else {
		global.points += 2 * bottom_bet["47"]
	}

	if luck.color == theme.black {
		global.points += 2 * bottom_bet["46"]
	}
	else if luck.color == theme.red {
		global.points += 2 * bottom_bet["45"]
	}
	
	if luck.number == 0 {
		global.points += 36 * zeros["0"]
	}
}