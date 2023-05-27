module models

pub struct Template {
pub mut:
	project       Project
	author        Author
	category      string
	subcategory   string
	is_valid      bool
	sort_priority int
	ignore_list []string
	copy_only_list []string
	source string
}

pub fn (t Template) fill_placeholders(line string) string {
	return t.author.fill_placeholders(t.project.fill_placeholders(line))
}
