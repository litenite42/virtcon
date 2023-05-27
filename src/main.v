module main

import os
import x.json2
import flag
import arrays
import termtable as tt
import models
import util
import pcre

const (
	template_dir = os.join_path(os.home_dir(), '.vtemplates')
)

struct App {
	cmp    util.Comparer
	config AppConfiguration
}

struct AppConfiguration {
	template_name string
	project_name  string
	destination   string
	help_entered  bool
	usage         string
	category      string
	subcategory   string
}

fn configure_app(args []string) App {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('virtcon')
	fp.version('v0.0.2')
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

	config := AppConfiguration{
		template_name: template_name
		project_name: project_name
		destination: dest_dir
		help_entered: help_entered
		usage: fp.usage()
		category: category
		subcategory: subcategory
	}

	return App{
		cmp: util.init_comparer(sort_asc: !sort_desc, sort_field: sort_field)
		config: config
	}
}

fn gen_template_path(template_name string) string {
	return os.join_path(template_dir, template_name, 'vtemplate.json')
}

fn fill_placeholders(t models.Template, dest_path string) ! {
		mut file_lines := os.read_lines(dest_path) or {
			eprintln('Unable to open ${dest_path}.')
			return
		}

		for ndx := 0; ndx < file_lines.len; ndx++ {
			file_lines[ndx] = t.fill_placeholders(file_lines[ndx])
		}

		os.write_file(dest_path, file_lines.join('\n')) or { eprintln('Error writing to file ${dest_path}') }
}

struct RegexConfig {
	regex_list []string
	check_against string
	label string = 'ignore'
}

fn check_list_regex(config RegexConfig) bool {
	if config.regex_list.len == 0 {
		return false
	}
	
	for ignore_regex in config.regex_list {
		mut re := pcre.new_regex(ignore_regex, 0) or { 
			eprintln(err) 
			return false	
		}

		m := re.match_str(config.check_against, 0, 0) or {
			println('No ${config.label} match!')
			continue 
		}
		println('${config.label} match')
		return true
	}

	return false
}

fn ignore_template_file(t &models.Template, f string) bool {
	return check_list_regex(regex_list: t.ignore_list check_against: f label: 'ignore' )
}

fn copy_only_file(t &models.Template, f string) bool {
	return check_list_regex(regex_list: t.copy_only_list check_against: f label: '')
}

fn scaffold_project(t models.Template, src_path string, dest_path string) ! {
	os.walk(src_path, fn [t, src_path, dest_path] (f string) {
		println(f)
		if f.contains('vtemplate.json') {
			return
		}
		
		if ignore_template_file(t, f) {
			println('Skipped')
			return
		}


		dest_file := f.replace(src_path, dest_path)

		if !os.exists(os.dir(dest_file)) {
			os.mkdir(os.dir(dest_file)) or {
				eprintln(err)
			}
		}

		os.cp(f, dest_file) or {
			eprintln(err)
			return
		}

		if copy_only_file(t, f) {		
			println('copy-only. end of processing')	
			return
		}

		fill_placeholders(t, dest_file) or {
			eprintln(err)
			return
		}
	})
}

fn main() {
	app := configure_app(os.args)

	template_paths := os.ls(os.real_path(template_dir)) or {
		eprintln('No template directory found.')
		return
	}

	mut usable_template_paths := template_paths.filter(os.exists(os.join_path(template_dir,
		it, 'vtemplate.json')))

	if !app.config.template_name.is_blank() {
		usable_template_paths = usable_template_paths.filter(it.to_lower() == app.config.template_name.to_lower())
	}

	mut templates := []models.Template{}

	for template in usable_template_paths {
		template_path := gen_template_path(template)
		template_content := os.read_file(template_path) or { continue }

		template_json := json2.raw_decode(template_content) or { continue }

		template_map := template_json.as_map()
		mut new_template := util.new_template(template_map)
		new_template.source = template
		templates << new_template
	}

	if !app.config.category.is_blank() {
		templates = templates.filter(it.category.to_lower() == app.config.category.to_lower())
	}

	if !app.config.subcategory.is_blank() {
		templates = templates.filter(it.subcategory.to_lower() == app.config.subcategory.to_lower())
	}

	if templates.len == 1 && !app.config.template_name.is_blank() {
		if !templates[0].is_valid {
			eprintln('Invalid template selected. Please check logs for any reported errors.')
			unsafe { goto after_loop }
		}

		mut template := templates[0]

		src_path := os.join_path(template_dir, usable_template_paths[0])
		mut dest_name := usable_template_paths[0]
		if !app.config.project_name.is_blank() {
			template.project.name = app.config.project_name
			dest_name = app.config.project_name
		}
		dest_path := os.join_path(app.config.destination, dest_name)
		scaffold_project(template, src_path, dest_path) or { eprintln(err.msg()) }
	} else if templates.len > 0 {
		grouped_templates := arrays.group_by[string, models.Template](templates, fn (t models.Template) string {
			return '${t.category},${t.subcategory}'
		})

		mut table_rows := [][]string{}
		table_rows << ['Available templates:', '', '', '', '']
		table_rows << ['Cat.,Subcat. / Template Name', 'Scaffolded Project', 'Description', 'Author', 'Sort Priority']
		for cat_subcat, cat_templates in grouped_templates {
			table_rows << [cat_subcat, '', '', '', '']

			mut temps := cat_templates[..]
			cmp := app.cmp
			temps.sort_with_compare(fn [cmp] (a &models.Template, b &models.Template) int {
				return cmp.compare(a, b)
			})

			table_rows << temps.map([it.source, it.project.name, it.project.description, it.author.developer,
				it.sort_priority.str()])
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
