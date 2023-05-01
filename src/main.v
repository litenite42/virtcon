module main

import os
import x.json2
import toml
import flag

const (
	template_dir = os.join_path(os.home_dir(), '.vtemplates')
)

struct Project {
	name        string
	description string
	license     string
	version     string
	category    string
	subcategory string
}

struct Template {
	project Project
}

fn new_project_description(template_values map[string]json2.Any) Project {
	name := template_values['name'] or { json2.null }
	description := template_values['description'] or { json2.null }
	license := template_values['license'] or { json2.null }
	version := template_values['version'] or { json2.null }
	return Project{
		name : name.str()
		description : description.str()
		license : license.str()
		version : version.str()
	}
}

fn set_up_flag_parser(args []string) (string, string, string) {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('virtcon')
	fp.version('v0.0.1')
	fp.description('Virtually Constructs projects based on a stored template.')
	fp.skip_executable()

	template_name := fp.string('template', `t`, '', 'Name of which template to reference.')
	project_name  := fp.string('project', `p`, '', 'Name to use in final project.')
	dest_dir      := fp.string('dest-path', `d`, os.join_path(os.home_dir(), 'Documents', 'v-work'), 'Where to store generated project')

	return template_name, project_name, dest_dir
}

fn gen_template_path(template_name string) string {
	return os.join_path(template_dir, template_name, 'vtemplate.json')
}

fn main() {
	template_name, project_name, dest_dir := set_up_flag_parser(os.args)

	template_paths := os.ls(os.real_path(template_dir)) or {
		eprintln('No template directory found.')
		return
	}

	mut usable_template_paths := template_paths.filter(os.exists(os.join_path(template_dir,
		it, 'vtemplate.json')))

	if !template_name.is_blank() {
		usable_template_paths = usable_template_paths.filter(it.to_lower() == template_name.to_lower())
	}

	mut templates := []Template{}

	for template in usable_template_paths {
		template_path := gen_template_path(template)
		template_content := os.read_file(template_path) or { continue }

		template_json := json2.raw_decode(template_content) or { continue }

		template_map := template_json.as_map()
		dump(template_map)
		project_data := template_map['project'] as map[string]json2.Any

		dump(project_data)
		project_str := project_data.str()
		dump(project_str)
		project := new_project_description(project_data)
		dump(project)

		templates << Template{
			project : project
		}
	}

	dump(usable_template_paths)
	dump(templates)

	if templates.len == 1 {
		src_path := os.join_path(template_dir, usable_template_paths[0])
		dest_path := os.join_path(dest_dir, usable_template_paths[0])
		dump(src_path)
		dump(dest_path)

		if !os.exists(dest_dir) {
			os.mkdir(dest_dir) or {
				println('Could not make v-work folder for generated project')
			}
		}

		os.cp_all(src_path, dest_path, true) or {
			return
		}
		dump(os.join_path(dest_path, 'vtemplate.json'))
		os.rm(os.join_path(dest_path, 'vtemplate.json')) or {
			println('No vtemplate.json found')
		}
		os.rm(os.join_path(dest_path, 'vtemplate.toml')) or {
			println('No vtemplate.toml found')
		}
	}
}
