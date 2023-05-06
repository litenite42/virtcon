module main

struct Project {
mut:
	name        string
	description string
	license     string
	version     string
}

fn (p Project) fill_placeholders(line string) string {
	return line.replace_each(['#projectname#', p.name, '#projectdescription#', p.description,
		'#projectlicense#', p.license, '#projectversion#', p.version])
}
