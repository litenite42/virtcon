I'm sorry for the inconvenience. I can generate the whole thing in markdown, but I have to split it into multiple responses because I can only give one reply for each conversation turn. Here is the first part:

# VIRTual CONstructor (VirtCon)
> A simple project construction tool that utilizes prebuilt templates (mostly valid V projects) 
> to speed up creation of other projects. Allowing teams to create a standard set of templates to be refereneced as a starting point. Includes Category and Subcategory metadata to allow filtering search results to find the exact match.

VirtCon is a tool that helps you create new projects based on existing templates. You can use VirtCon to:

- Scaffold projects from a variety of templates stored in `~/.vtemplates`.
- Customize your project metadata such as name, description, license, version, author, etc.
- Inject metadata placeholders into your project files using a simple syntax.
- Manipulate the scaffolded output by ignoring or copying files without placeholder replacement.
- Debug the project generation process by compiling with `-cg` flag.

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
    "subcategory": "",
    "sort_priority": 100,
    "ignore" : [".git"],
    "copyonly" : []
}
```


## Installing
1. Grab the GitHub Mirror Url
    - `https://github.com/litenite42/virtcon.git`
2. Use `git` to clone the repo to the location of your choosing
    - `git clone https://github.com/litenite42/virtcon.git Path-To-Destination`
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
| order | o | Sort Descdending if present |
| field | f | Which field to sort by |

### Metadata Placeholders
Metadata nested within the template can be injected into the generated project's files by referencing them with the following 
syntax:   
`#{metadata_name}{metadata_field}#`

When using the sample `vtemplate.json` from above, `author.developer`'s value could be injected using `#authordeveloper#`.  
### Manipulate Scaffolded Output
> By default, all files in a project will be copied to the destination and have the placeholder replacement logic ran on their contents.

You can add the following keys to your `vtemplate.json` with 
an array of PCRE-compliant regexes to change this behavior:
- `ignore` - Skips this file entirely. No matching file should appear in the destination
- `copyonly` - Skips the placeholder filler step after the file is copied to the destination

### Debug Printout
Compile with `-cg` to get debug information to print out while the project is scaffolded.

## Roadmap

- [x] Add sort priority field to place higher priority items at top of search results
- [x] Add output generation rules (files are copied over and placeholder fields are updated as appropriate by default)
    - [x] Copy-only (list of regex paths)
    - [x] Ignore (list of regex paths)
- [ ] Accept Compressed Templates (.zip, .7z (?), .tgz)
- [ ] Scripts to run on project generation
- [ ] VUI plugin

## Contributing
VirtCon is an open source project and welcomes contributions from anyone. If you want to contribute to VirtCon, you can:

- Fork this repository and submit pull requests with your changes.
- Report any issues or bugs on the [issue tracker](https://github.com/litenite42/virtcon/issues).
- Suggest new features or improvements on the [issue tracker](https://github.com/litenite42/virtcon/issues).
- Create new templates and share them with others.

## License
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

VirtCon is licensed under the MIT license. See [LICENSE](LICENSE) for more details.
