module util

import models

fn negate_desc(asc bool, result int) int {
	return if asc { result } else { -1 * result }
}

type CompareFn = fn (&models.Template, &models.Template) int

pub struct Comparer {
pub mut:
	sort_asc   bool
	sort_field string
	fn_map     map[string]CompareFn
}

pub struct ComparerConfig {
	sort_asc   bool   = true
	sort_field string = 'sort-priority'
}

pub fn init_comparer(config ComparerConfig) Comparer {
	mut comparer := init_comparer_inner(config)

	comparer.fn_map = {
		'sort-priority': comparer.sort_priority
		'project-name':  comparer.project_name
	}

	return comparer
}

fn init_comparer_inner(config ComparerConfig) Comparer {
	return Comparer{
		sort_asc: config.sort_asc
		sort_field: config.sort_field
		fn_map: map[string]CompareFn{}
	}
}

fn cmp[T](sort_asc bool, a &T, b &T) int {
	mut result := if a < b {
		-1
	} else if a > b {
		1
	} else {
		0
	}

	return negate_desc(sort_asc, result)
}

pub fn (c Comparer) compare(a &models.Template, b &models.Template) int {
	func := c.fn_map[c.sort_field] or {
		eprintln('Invalid sort field entered! ${c.sort_field}.\nAvailable Field Names: ${c.fn_map.keys().join(', ')}')
		c.sort_priority
	}
	return func(a, b)
}

pub fn (c Comparer) sort_priority(a &models.Template, b &models.Template) int {
	return cmp[int](c.sort_asc, a.sort_priority, b.sort_priority)
}

pub fn (c Comparer) project_name(a &models.Template, b &models.Template) int {
	return cmp[string](c.sort_asc, a.project.name, b.project.name)
}
