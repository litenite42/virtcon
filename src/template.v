module main

struct Template {
mut:
	project     Project
	author      Author
	category    string
	subcategory string
	is_valid    bool
}

fn (t Template) fill_placeholders(line string) string {
	return t.author.fill_placeholders(t.project.fill_placeholders(line))
}
