module main

import os
import flag
import virtcon
import virtcon.util
import virtcon.termtable as tt

fn configure_app(args []string) virtcon.App {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('virtcon')
	fp.version('v0.0.3')
	fp.description('Virtually Constructs projects based on a stored template.')
	fp.skip_executable()

	template_name := fp.string('template', `t`, '', 'Name of which template to reference.')
	project_name := fp.string('project', `p`, '', 'Name to use in final project.')
	dest_dir := fp.string('destination', `d`, os.join_path(os.home_dir(), 'Documents',
		'v-work'), 'Where to store generated project')
	help_entered := fp.bool('help', `h`, false, '')
	category := fp.string('cat', `c`, '', 'Category to filter results by')
	subcategory := fp.string('subcat', `s`, '', 'Subcategory to filter results by')
	sort_desc := fp.bool('order', `o`, false, 'Sort Descending if present')
	sort_field := fp.string('field', `f`, 'sort-priority', 'Which field to sort by ')

	config := virtcon.AppConfiguration{
		template_name: template_name
		project_name: project_name
		destination: dest_dir
		help_entered: help_entered
		usage: fp.usage()
		category: category
		subcategory: subcategory
	}

	return virtcon.App{
		cmp: util.init_comparer(sort_asc: !sort_desc, sort_field: sort_field)
		config: config
	}
}

fn main() {
	app := configure_app(os.args)

	template_paths := os.ls(os.real_path(virtcon.template_dir)) or {
		eprintln('No template directory found.')
		return
	}

	mut usable_template_paths, mut templates := app.extract_template_info(template_paths)

	if templates.len == 1 && !app.config.template_name.is_blank() {
		generated_project_path := app.generate_project(mut templates[0], usable_template_paths[0]) or {
			''
		}

		if generated_project_path.is_blank() {
			unsafe {
				goto after_loop
			}
		}
	} else if templates.len > 0 {
		table_rows := app.list_templates(templates) or {
			eprintln('An error occurred trying to list installed templates.')
			[][]string{}
		}

		if table_rows.len == 0 {
			unsafe {
				goto after_loop
			}
		}

		t := tt.Table{
			data: table_rows
		}

		println(t)
	}

	after_loop:
	if app.config.help_entered {
		println(app.config.usage)
	}
}
