module models

pub struct Author {
pub mut:
	developer    string
	organization string
	email        string
}

pub fn (a Author) fill_placeholders(line string) string {
	return line.replace_each(['#authordeveloper#', a.developer, '#authororganization#', a.organization,
		'#authoremail#', a.email])
}
