export {
format_num: fn(num) {
		num = int(num)
		if (num < 1000) {
			return string(num)
		} 
		else if (num < 1000000) {
			return string(num / 1000) + "K"
		} 
		else if (num < 1000000000) {
			return string(num / 1000000) + "M"
		}
		else if (num < 1000000000000) {
			return string(num / 1000000000) + "B"
		}
		else if (num < 1000000000000000) {
			return string(num / 1000000000000) + "T"
		}
		else if (num < 1000000000000000000) {
			return string(num / 1000000000000000) + "Q"  // Quadrillion
		}
		else if (num < 1000000000000000000000) {
			return string(num / 1000000000000000000) + "Qi"  // Quintillion
		}
		else if (num < 1000000000000000000000000) {
			return string(num / 1000000000000000000000) + "Sx"  // Sextillion
		}
		else if (num < 1000000000000000000000000000) {
			return string(num / 1000000000000000000000000) + "Sp"  // Septillion
		}
		else if (num < 1000000000000000000000000000000) {
			return string(num / 1000000000000000000000000000) + "Oc"  // Octillion
		}
		else if (num < 1000000000000000000000000000000000) {
			return string(num / 1000000000000000000000000000000) + "No"  // Nonillion
		}
		else {
			return string(num / 1000000000000000000000000000000000) + "Dc"  // Decillion
		}
	},
	format_num_comma: fn(n){
		str := string(n)
		out := ""
		commaCount := 0
		for i := str.length - 1; i >= 0; i-- {
			out += str[i]
			commaCount++
			if commaCount == 3 && i != 0 {
				out += ','
				commaCount = 0
			}
		}
		
		return reverse(out)
	}
}

