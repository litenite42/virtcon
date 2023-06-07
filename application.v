module virtcon

import util
import models
import os
import szip
import arrays
import x.json2

pub const (
	template_dir = os.join_path(os.home_dir(), '.vtemplates')
)

pub struct App {
pub:
	cmp    util.Comparer
	config AppConfiguration
}

pub struct AppConfiguration {
pub:
	template_name string
	project_name  string
	destination   string
	help_entered  bool
	usage         string
	category      string
	subcategory   string
}

pub fn (a App) has_template_metadata(template_dir string, template_name string) bool {
	if template_dir.len == 0 {
		return false
	}
	template_path := os.join_path(template_dir, template_name)

	if os.exists(os.join_path(template_path, 'vtemplate.json')) {
		return true
	}

	mut archive := szip.open(template_path, .default_compression, .write) or {
		eprintln(err)
		return false
	}

	archive.open_entry('vtemplate.json') or {
		eprintln(err)
		return false
	}

	return true
}

fn gen_template_path(template_name string) string {
	return os.join_path(virtcon.template_dir, template_name, 'vtemplate.json')
}

pub fn (app App) parse_new_template(template string) !models.Template {
	template_path := gen_template_path(template)
	template_content := os.read_file(template_path)!

	template_json := json2.raw_decode(template_content)!

	template_map := template_json.as_map()
	mut new_template := util.new_template(template_map)
	new_template.source = template

	return new_template
}

pub fn (app App) generate_project(mut template models.Template, template_path string) !string {
	if !template.is_valid {
		msg := 'Invalid template selected. Please check logs for any reported errors.'
		eprintln(msg)

		return error(msg)
	}

	src_path := os.join_path(virtcon.template_dir, template_path)
	mut dest_name := template_path
	if !app.config.project_name.is_blank() {
		template.project.name = app.config.project_name
		dest_name = app.config.project_name
	}
	dest_path := os.join_path(app.config.destination, dest_name)
	util.scaffold_project(template, src_path, dest_path) or { eprintln(err.msg()) }

	return dest_path
}

pub fn (app App) list_templates(templates []models.Template) ![][]string {
	if templates.len == 0 {
		return error('No templates found.')
	}
	grouped_templates := arrays.group_by[string, models.Template](templates, fn (t models.Template) string {
		return '${t.category},${t.subcategory}'
	})

	mut table_rows := [][]string{}
	table_rows << ['Available templates:', '', '', '', '']
	table_rows << ['Cat.,Subcat. / Template Name', 'Scaffolded Project', 'Description', 'Author',
		'Sort Priority']
	for cat_subcat, cat_templates in grouped_templates {
		table_rows << [cat_subcat, '', '', '', '']

		mut temps := cat_templates[..]
		temps.sort_with_compare(app.cmp.compare)

		table_rows << temps.map([it.source, it.project.name, it.project.description, it.author.developer,
			it.sort_priority.str()])
	}

	return table_rows
}

pub fn (app App) extract_template_info(paths []string) ([]string, []models.Template) {
	mut usable_template_paths := paths.filter(app.has_template_metadata)

	if !app.config.template_name.is_blank() {
		usable_template_paths = usable_template_paths.filter(it.to_lower() == app.config.template_name.to_lower())
	}

	mut templates := []models.Template{}

	for template in usable_template_paths {
		templates << app.parse_new_template(template) or { continue }
	}

	if !app.config.category.is_blank() {
		templates = templates.filter(it.category.to_lower() == app.config.category.to_lower())
	}

	if !app.config.subcategory.is_blank() {
		templates = templates.filter(it.subcategory.to_lower() == app.config.subcategory.to_lower())
	}

	return usable_template_paths, templates
}
