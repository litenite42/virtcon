module util

import x.json2
import models

pub fn new_project(doc map[string]json2.Any) ?models.Project {
	project_doc := doc['project'] or { return none }
	template_values := project_doc as map[string]json2.Any

	name := template_values['name'] or { json2.null }
	description := template_values['description'] or { json2.null }
	license := template_values['license'] or { json2.null }
	version := template_values['version'] or { json2.null }

	return models.Project{
		name: name.str()
		description: description.str()
		license: license.str()
		version: version.str()
	}
}

pub fn new_author(doc map[string]json2.Any) ?models.Author {
	author_doc := doc['author'] or { return none }
	template_values := author_doc as map[string]json2.Any

	developer := template_values['developer'] or { json2.null }
	organization := template_values['organization'] or { json2.null }
	email := template_values['email'] or { json2.null }

	return models.Author{
		developer: developer.str()
		organization: organization.str()
		email: email.str()
	}
}

pub fn new_template(doc map[string]json2.Any) models.Template {
	mut is_valid := true

	project := new_project(doc) or {
		eprintln('Could not find project information.')
		is_valid = false
		models.Project{}
	}

	author := new_author(doc) or {
		eprintln('Could not find author information.')
		is_valid = false
		models.Author{}
	}

	js_category := doc['category'] or { json2.null }
	js_subcategory := doc['subcategory'] or { json2.null }
	js_sortpriority := doc['sort_priority'] or { json2.null }
	js_ignorelist := doc['ignore'] or { json2.null }
	js_copyonlylist := doc['copyonly'] or { json2.null }

	ignore_list := js_ignorelist.arr().map(it.str())
	copy_only_list := js_copyonlylist.arr().map(it.str())

	return models.Template{
		project: project
		author: author
		category: js_category.str()
		subcategory: js_subcategory.str()
		sort_priority: js_sortpriority.int()
		is_valid: is_valid
		ignore_list: ignore_list
		copy_only_list: copy_only_list
	}
}
