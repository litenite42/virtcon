module main

import os
import x.json2
import flag
import arrays
import termtable as tt
import models
import util

const (
	template_dir = os.join_path(os.home_dir(), '.vtemplates')
)

struct AppConfiguration {
	template_name string
	project_name string
	destination string
	help_entered bool
	usage string
	category string
	subcategory string
}

fn init_app_config(args []string) AppConfiguration {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('virtcon')
	fp.version('v0.0.1')
	fp.description('Virtually Constructs projects based on a stored template.')
	fp.skip_executable()

	template_name := fp.string('template', `t`, '', 'Name of which template to reference.')
	project_name := fp.string('project', `p`, '', 'Name to use in final project.')
	dest_dir := fp.string('destination', `d`, os.join_path(os.home_dir(), 'Documents', 'v-work'),
		'Where to store generated project')
	help_entered := fp.bool('help', `h`, false, '')
	category := fp.string('category', `c`, '', 'Category to filter results by')
	subcategory := fp.string('subcategory', `s`, '', 'Subcategory to filter results by')

	config := AppConfiguration{
		template_name : template_name
		project_name : project_name
		destination : dest_dir
		help_entered : help_entered
		usage : fp.usage()
		category : category
		subcategory : subcategory
	}

	return config
}

fn gen_template_path(template_name string) string {
	return os.join_path(template_dir, template_name, 'vtemplate.json')
}

fn copy_project_files(src_path string, dest_path string) ! {
	if !os.exists(dest_path) {
		os.mkdir(dest_path) or { return error('Could not make v-work folder for generated project') }
	}

	os.cp_all(src_path, dest_path, true) !
	os.rm(os.join_path(dest_path, 'vtemplate.json')) or { return error('No vtemplate.json found') }
}

fn fill_placeholders(dest_path string, t models.Template) ! {
	os.walk(dest_path, fn [t] (f string) {
		mut file_lines := os.read_lines(f) or {
			eprintln('Unable to open ${f}.')
			return
		}

		for ndx := 0; ndx < file_lines.len; ndx++ {
			file_lines[ndx] = t.fill_placeholders(file_lines[ndx])
		}

		os.write_file(f, file_lines.join('\n')) or { eprintln('Error writing to file ${f}') }
	})
}

fn main() {
	app_config := init_app_config(os.args)

	template_paths := os.ls(os.real_path(template_dir)) or {
		eprintln('No template directory found.')
		return
	}

	mut usable_template_paths := template_paths.filter(os.exists(os.join_path(template_dir,
		it, 'vtemplate.json')))

	if !app_config.template_name.is_blank() {
		usable_template_paths = usable_template_paths.filter(it.to_lower() == app_config.template_name.to_lower())
	}

	mut templates := []models.Template{}

	for template in usable_template_paths {
		template_path := gen_template_path(template)
		template_content := os.read_file(template_path) or { continue }

		template_json := json2.raw_decode(template_content) or { continue }

		template_map := template_json.as_map()
		templates << util.new_template(template_map)
	}

	if !app_config.category.is_blank() {
		templates = templates.filter(it.category.to_lower() == app_config.category.to_lower())
	}

	if !app_config.subcategory.is_blank() {
		templates = templates.filter(it.subcategory.to_lower() == app_config.subcategory.to_lower())
	}
	
	if templates.len == 1 && !app_config.template_name.is_blank() {
		mut template := templates[0]
		
		if template.is_valid {
			src_path := os.join_path(template_dir, usable_template_paths[0])
			mut dest_name := usable_template_paths[0]
			if !app_config.project_name.is_blank() {
				template.project.name = app_config.project_name
				dest_name = app_config.project_name
			}
			dest_path := os.join_path(app_config.destination, dest_name)
			copy_project_files(src_path, dest_path) or { eprintln(err.msg()) }
			fill_placeholders(dest_path, template) or { eprintln(err.msg()) }
		} else {
			eprintln('Invalid template selected. Please check logs for any reported errors.')
		}
	} else if templates.len > 0 {
		grouped_templates := arrays.group_by<string,models.Template>(templates, fn(t models.Template) string {
			return '${t.category},${t.subcategory}'
		})

		mut table_rows := [][]string{}
		table_rows << ['Available templates:', '', '']
		for cat_subcat, cat_templates in grouped_templates {
			table_rows << [cat_subcat, '', '']

			mut temps := cat_templates[..]
			temps.sort(a.sort_priority < b.sort_priority)
			
			table_rows << temps.map([it.project.name, it.project.description, it.author.developer])
		}

		t := tt.Table{
			data: table_rows
		}
		println(t)
	}
	
	if app_config.help_entered {
		println(app_config.usage)
	}
}
