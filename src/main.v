module main

import os
import x.json2
import flag
import arrays
import serkonda7.termtable as tt

const (
	template_dir = os.join_path(os.home_dir(), '.vtemplates')
)

fn set_up_flag_parser(args []string) (string, string, string, bool, string) {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('virtcon')
	fp.version('v0.0.1')
	fp.description('Virtually Constructs projects based on a stored template.')
	fp.skip_executable()

	template_name := fp.string('template', `t`, '', 'Name of which template to reference.')
	project_name := fp.string('project', `p`, '', 'Name to use in final project.')
	dest_dir := fp.string('dest-path', `d`, os.join_path(os.home_dir(), 'Documents', 'v-work'),
		'Where to store generated project')
	help_entered := fp.bool('help', `h`, false, '')

	return template_name, project_name, dest_dir, help_entered, fp.usage()
}

fn gen_template_path(template_name string) string {
	return os.join_path(template_dir, template_name, 'vtemplate.json')
}

fn new_project_description(doc map[string]json2.Any) ?Project {
	project_doc := doc['project'] or { return none }
	template_values := project_doc as map[string]json2.Any

	name := template_values['name'] or { json2.null }
	description := template_values['description'] or { json2.null }
	license := template_values['license'] or { json2.null }
	version := template_values['version'] or { json2.null }

	return Project{
		name: name.str()
		description: description.str()
		license: license.str()
		version: version.str()
	}
}

fn new_author_description(doc map[string]json2.Any) ?Author {
	author_doc := doc['author'] or { return none }
	template_values := author_doc as map[string]json2.Any

	developer := template_values['developer'] or { json2.null }
	organization := template_values['organization'] or { json2.null }
	email := template_values['email'] or { json2.null }

	return Author{
		developer: developer.str()
		organization: organization.str()
		email: email.str()
	}
}

fn new_template_description(doc map[string]json2.Any) Template {
	mut is_valid := true

	// dump(template_map)
	project := new_project_description(doc) or {
		eprintln('Could not find project information.')
		is_valid = false
		Project{}
	}

	// dump(project)
	author := new_author_description(doc) or {
		eprintln('Could not find author information.')
		is_valid = false
		Author{}
	}

	js_category := doc['category']  or { json2.null }
	js_subcategory := doc['subcategory']  or { json2.null }

	return Template{
		project: project
		author: author
		category: js_category.str()
		subcategory: js_subcategory.str()
		is_valid: is_valid
	}
}

fn copy_project_files(src_path string, dest_path string) {
	// dump(src_path)
	// dump(dest_path)
	if !os.exists(dest_path) {
		os.mkdir(dest_path) or { println('Could not make v-work folder for generated project') }
	}

	os.cp_all(src_path, dest_path, true) or { return }
	os.rm(os.join_path(dest_path, 'vtemplate.json')) or { println('No vtemplate.json found') }
}

fn fill_placeholders(dest_path string, t Template) {
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
	template_name, project_name, dest_dir, help_entered, usage := set_up_flag_parser(os.args)
	if help_entered {
		println(usage)
		return
	}

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
		templates << new_template_description(template_map)
	}
	
	if templates.len == 1 {
		mut template := templates[0]
		
		if template.is_valid {
			src_path := os.join_path(template_dir, usable_template_paths[0])
			mut dest_name := usable_template_paths[0]
			if !project_name.is_blank() {
				template.project.name = project_name
				dest_name = project_name
			}
			dest_path := os.join_path(dest_dir, dest_name)
			copy_project_files(src_path, dest_path)
			fill_placeholders(dest_path, template)
		} else {
			eprintln('Invalid template selected. Please check logs for any reported errors.')
		}
	} else if templates.len > 1 {
		grouped_templates := arrays.group_by<string,Template>(templates, fn(t Template) string {
			return '${t.category},${t.subcategory}'
		})

		mut table_rows := [][]string{}
		table_rows << ['Available templates:', '', '']
		for cat_subcat, cat_templates in grouped_templates {
			table_rows << [cat_subcat, '', '']
			table_rows << cat_templates.map([it.project.name, it.project.description, it.author.developer])
		}

		t := tt.Table{
			data: table_rows
			// The following settings are optional and have these defaults:
			style: .grid
			header_style: .bold
			align: .left
			orientation: .row
			padding: 1
			tabsize: 4
		}
		println(t)
	}
}