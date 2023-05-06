module main

struct Author {
	developer    string
	organization string
	email        string
}

fn (a Author) fill_placeholders(line string) string {
	return line.replace_each(['#authordeveloper#', a.developer, '#authororganization#', a.organization,
		'#authoremail#', a.email])
}
