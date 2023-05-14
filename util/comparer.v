module util 
import models 

pub interface IComparer {
	sort_asc bool
	compare(a &models.Template, b &models.Template) int
}

fn negate_desc(asc bool, result int) int {
	return if asc {result} else {-1 * result}
}

pub struct PrioritySortComparer {
	pub mut:
	sort_asc bool
}

fn (psc PrioritySortComparer) compare(a &models.Template, b &models.Template) int {
	mut result := if a.sort_priority < b.sort_priority {
		-1
	} else if a.sort_priority > b.sort_priority {
		1
	} else {
		0
	}
	
	return negate_desc(psc.sort_asc, result)
}