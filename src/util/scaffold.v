module util

import os
import pcre
import models

struct RegexConfig {
	regex_list    []string
	check_against string
	label         string = 'ignore'
}

fn dprintln(s string) {
	$if debug {
		println(s)
	}
}

fn ddump[T](t T) {
	$if debug {
		dump(t)
	}
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

		re.match_str(config.check_against, 0, 0) or {
			dprintln('No ${config.label} match.')
			continue
		}

		dprintln('${config.label} match')
		return true
	}

	return false
}

fn ignore_template_file(t &models.Template, f string) bool {
	return check_list_regex(regex_list: t.ignore_list, check_against: f, label: 'ignore')
}

fn copy_only_file(t &models.Template, f string) bool {
	return check_list_regex(regex_list: t.copy_only_list, check_against: f, label: '')
}

fn fill_placeholders(t models.Template, dest_path string) ! {
	mut file_lines := os.read_lines(dest_path) or {
		eprintln('Unable to open ${dest_path}.')
		return
	}

	for ndx := 0; ndx < file_lines.len; ndx++ {
		file_lines[ndx] = t.fill_placeholders(file_lines[ndx])
	}

	os.write_file(dest_path, file_lines.join('\n')) or {
		eprintln('Error writing to file ${dest_path}')
	}
}

pub fn scaffold_project(t models.Template, src_path string, dest_path string) ! {
	os.walk(src_path, fn [t, src_path, dest_path] (f string) {
		dprintln(f)

		if f.contains('vtemplate.json') {
			return
		}

		if ignore_template_file(t, f) {
			dprintln('Skipped')
			return
		}

		dest_file := f.replace(src_path, dest_path)

		if !os.exists(os.dir(dest_file)) {
			os.mkdir(os.dir(dest_file)) or { eprintln(err) }
		}

		os.cp(f, dest_file) or {
			eprintln(err)
			return
		}

		if copy_only_file(t, f) {
			dprintln('copy-only. end of processing')
			return
		}

		fill_placeholders(t, dest_file) or {
			eprintln(err)
			return
		}
	})
}
