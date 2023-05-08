# VIRTual CONstructor (VirtCon)
> A simple project construction tool that utilizes prebuilt templates (mostly valid V projects) 
> to speed up creation of other projects. Allowing teams to create a standard set of templates to be refereneced as a starting point. Includes Category and Subcategory metadata to allow filtering search results to find the exact match.

## Setup

By default, VirtCon references templates from `~/.vtemplates`. To build a 'valid' template, place any folder in that directory with at least a single file named `vtemplate.json`. This file will contain template, project, author, and build metadata to use while generating the new project. Currently, the project and author data must be present or the template file will be considered invalid.

At this moment, only some of the template, project, and author portions have been implemented:

``` json
{
    "project": {
        "name": "hello-world",
        "description": "Simple Hello World Template",
        "license" : "MIT",
        "version": "0.0.0.0"
    },
    "author" : {
        "developer" : "Sample Developer",
        "organization" : "Templated Organization",
        "email" : "email@server.org"
    },
    "category": "code",
    "subcategory": ""
}
```

## Installing
1. Grab the Gitly Url
    - https://gitly.org/enlite/virtcon.git
2. Use `git` to clone the repo to the location of your choosing
    - git clone https://gitly.org/enlite/virtcon.git Path-To-Destination
3. Build from the root of the project `virtcon/`.
4. Either add `virtcon/` to your PATH or move the executable somewhere in your path

## Usage
As mentioned in the Setup section, you'll need the `~/.vtemplates` directory created and to place any desired templates within it. Running the application without any parameters will list all available templates.

### Current Parameters
| Parameter | Alias | Description |
| --------- | ----- | ----------- |
| template  |   t   |  Name of which template to reference |
| project |   p  | Name to use in final project |
| destination |   d  | Where to store generated project |
| category |  c  | Category to filter results by |
| subcategory | s | Subcategory to filter results by |

### Metadata Placeholders
Metadata nested within the template can be injected into the generated project's files by referencing them with the following 
syntax:   
`#{metadata_name}{metadata_field}#`

When using the sample `vtemplate.json` from above, `author.developer`'s value could be injected using `#authordeveloper#`.  


## Example
With valid templates **welcome-world** and **hello-world** (stored at `~/.vtemplates/welcome` and `~/.vtemplates/hello` respectively) 
``` 
zsh $ virtcon

+----------------------+-------------------------------+------------------+
| Available templates: |                               |                  |
+----------------------+-------------------------------+------------------+
| web,demo             |                               |                  |
+----------------------+-------------------------------+------------------+
| welcome-world        | Simple Welcome World Template | Sample Developer |
+----------------------+-------------------------------+------------------+
| code,                |                               |                  |
+----------------------+-------------------------------+------------------+
| hello-world          | Simple Hello World Template   | Sample Developer |
+----------------------+-------------------------------+------------------+
virtcon v0.0.1
-----------------------------------------------
Usage: virtcon [options] [ARGS]

Description: Virtually Constructs projects based on a stored template.

Options:
  -t, --template <string>    Name of which template to reference.
  -p, --project <string>     Name to use in final project.
  -d, --dest-path <string>   Where to store generated project
  -h, --help                
  -c, --category <string>    Category to filter results by
  -s, --subcategory <string> Subcategory to filter results by
```

## Roadmap
> Tentative. I do plan on adding to this project, but there is no set timeline.

- [ ] Add sort priority field to place higher priority items at top of search results
- [ ] Add output generation rules (files are copied over as is by default)
    - [ ] Copy-only (list of regex paths)
    - [ ] Ignore (list of regex paths)
- [ ] Accept Compressed Templates (.zip, .7z (?), .tgz)
- [ ] Scripts to run on project generation
- [ ] VUI plugin