<*
	Run this in a c3 project folder to generate documentation.
	c3docgen will search every .c3 file and extract all the modules,
	functions and macros and copy them to an .md file and store it in the
	/doc folder of the project if one exists, root folder otherwise.

	Usage:
		c3docgen [<options>]
			mono			creates a single file for all the modules encountered.
			verbose			output information on files and definitions found.
			-h --help 		print help

*>
module c3docgen;
import buffer;
import std::io;
import std::io::path;
import std::collections::map;
import lex;

Map(<String, Buffer>) buflist;

bool mono = false;
bool verbose = false;

const VERSION = "0.1.5";
const HELP = 
`Run this in a c3 project folder to generate documentation.
c3docgen will search every .c3 file and extract all the modules,
functions and macros and copy them to an .md file and store it in the
/doc folder of the project if one exists, root folder otherwise.

Usage:
	c3docgen [<options>]
		mono			creates a single file for all the modules encountered.
		verbose			output information on files and definitions found.
		-h --help 		print help`;

fn String Path.extract_dirname(self)
{
	String dir_path;
	if (path::is_dir(self))
	{
		dir_path = self.str_view();
	} else
	{
		dir_path = self.dirname();
	}
	usz! dir_start = dir_path.rindex_of_char(path::PREFERRED_SEPARATOR);
	if (try dir_start) dir_path = dir_path[dir_start+1:dir_path.len-dir_start-1];
	return dir_path;
}

fn void Lexer.next_line(&self)
{
	while (true)
	{
		Lexeme l = self.lex()!!;
		if (l.token == EOF) break;
		if (l.c == '\n') break;
	}
}


fn bool! walker(Path p, bool is_dir, void*)
{
	if (is_dir) return false;
	if (!p.has_extension("c3")) return false;
	if (verbose) io::printfn("Processing file :%s", p.basename());

	Buffer cur_buf = buffer::temp_file(p.path_string);
	Buffer cur_module;
	Buffer sec;
	String! module_name;
	usz start_index;
	usz! end_index;
	String! word;
	String! fn_def;
	bool found_module = false;

	cur_buf.trim();
	cur_buf.cursor_to_bof();

	//+ lex tester
	Lexer f = Lexer.init(cur_buf.str_view());
	Lexeme! l;
	while LOOP: (true)
	{
		l = f.lex();
		if (anyfault e = @catch(l))
		{
			io::printfn( "Error Line[%d] :%s", f.line, e);
			break;
		}

		Tkn t = l.token!!;
		switch (t)
		{
			case EOF: break LOOP;
			
			case ID:
				Ck token = lex::check_id (Ck, l.slice)!!;
				if (token != NOT_FOUND)
				{
					(void)io::printfn ("Found keyword [%s] %s", token, l.slice);
				}

			case COMMENT_DOC_OPEN:
				io::printn ("Found Doc open");

			case COMMENT_DOC_CLOSE:
				io::printn ("Found Doc close");

			case COMMENT:
				f.next_line();

			case COMMENT_BLOCK_OPEN:
				int nest = 1;
				while (true)
				{
					l = f.lex()!;
					t = l.token!!;

					if (t == EOF)
					{
						io::printfn("Line[%d] Unexpected EOF while parsing block comments", f.line);
					}
					else if (t == COMMENT_BLOCK_OPEN)
					{
						nest++;
					}
					else if (t == COMMENT_BLOCK_CLOSE)
					{
						nest--;
						if (!nest) break;
					}
				}

			case AT:
				Cp token = lex::check_id (Cp, l.slice)!!;
				if (token != NOT_FOUND)
				{
					(void)io::printfn ("Found doc attribute [%s] %s", token, l.slice);
				}

			default:
				continue;
		}
	}

	while (!cur_buf.is_eof())
	{
		word = cur_buf.get_word();
		if (catch error = word)
		{
			if (error = BufferError.NO_WORD)
			{
				cur_buf.cursor_next_line();
				continue;
			} else
			{
				// something else, just stop processing this and return.
				io::printfn("Encountered error :%s", error);
				return true;
			}
		} else
		{
			// we are interested in word that is
			// <*, module, fn, macro, struct, enum or union
			switch (word)
			{
				case "<*":
					start_index = cur_buf.get_cursor();
					end_index = cur_buf.find_next("*>");
					if ( catch result = end_index){
						io::printn("Error: missing '*>'");
						return true;
					}
					sec.clear();
					end_index --;
					cur_buf.sub_buffer(start_index, end_index - start_index, &sec)!;
					cur_buf.brk(); // advance to the first white space
					cur_buf.span(); // advance to the first non-white space

					// put the sections in code sections for better formatting in markdown viewers.
					sec.insert (0, "\n```");
					sec.append ("\n```");
					break;

				case "module":
					cur_buf.cursor_to_bol();
					module_name = cur_buf.get_line();
					if (try module_name)
					{
						if (verbose) io::printfn("found def :%s", module_name);
						if (try module_name.starts_with("module"))
						{
							module_name = module_name.strip_end(";");
							if (!buflist.has_key(module_name))
							{
								cur_module = buffer::new();
								cur_module.appendf ("## %s\n\n", module_name);
								//buflist.set (module_name, cur_module);
								buflist[module_name] = cur_module;
							} else
							{
								//cur_module = buflist.get(module_name)!;
								cur_module = buflist[module_name]!;
							}
							found_module = true;
							if (sec.len() > 0)
							{
								usz save_cursor = cur_module.get_cursor();
								cur_module.cursor_to_bof();
								usz inx = cur_module.cursor_right_lines(2);
								cur_module.insert(inx, "\n\n");
								cur_module.insert_buffer(inx, sec);
								cur_module.cursor_to(save_cursor);
								sec.clear();
							}
						}
					}

				case "fn":
				case "macro":
				case "extern":
					cur_buf.cursor_to_bol();
					fn_def = cur_buf.get_line();

					if (try fn_def){
						if (verbose) io::printfn("found def :%s", fn_def);
						if (!found_module)
						{
							io::printn("Error: could not find module definition in file");
							return true;
						}
						cur_module.appendf("### %s\n", fn_def);
						if (sec.len())
						{
							cur_module.append_buffer(sec);
							sec.clear();
						}
						cur_module.append("\n\n");
						
						// inserting into cur_module potentially resized it and changed the pointer,
						// set it into the map again to update the pointer.
						(void)buflist.set (module_name, cur_module);
						
					}
					break;

				case "struct":
				case "enum":
				case "union":
				case "fault":
					if (verbose) io::printfn("found :%s", word);
					uint nesting = 1;
					start_index = cur_buf.cursor_to_bol();
					cur_buf.find_next("{")!;
					while (try char c = cur_buf.get_char())
					{
						if (c=='{') nesting++;
						if (c == '}'){
							nesting--;
							if (!nesting) break;
						}
					}
					end_index = cur_buf.get_cursor();
					String cut = cur_buf.str_slice(start_index, end_index-start_index)!;
					cur_module.appendf( "```\n%s\n", cut);
					if (sec.len())
					{
						sec.delete(0, 4);
						cur_module.append_buffer(sec);
						cur_module.append("\n\n");
						sec.clear();
					} else
					{
						cur_module.append("```\n\n");
					}

				default:
					// something else, advance to the next line and continue.
					cur_buf.cursor_next_line();
					continue;
			}
		}
	}
	return false;
}

fn int main(String[] args)
{
	foreach (i, value: args)
	{
		switch (value)
		{
			case "mono":
				mono = true;
			case "verbose":
				verbose = true;
			case "-h": case "--help":
				io::printfn("\nc3docgen v.%s\n", VERSION);
				io::printn(HELP);
		}
	}

	Path! path = path::temp_cwd();
	if (verbose) io::printfn("Working on project folder :%s", path.path_string)!!;
	(void)path.walk(&walker, null);

	// save the files to /doc folder if one exists, current folder otherwise.
	Buffer monobuf;
	String dir_name = path.extract_dirname()!!;
	monobuf.appendf ("# %s\n", dir_name);
	
	DString work = dstring::temp_new();
	work.append(path.path_string)!!;
	work.append(path::PREFERRED_SEPARATOR);
	work.append("docs");
	if (os::native_file_or_dir_exists(work.str_view()))
	{
		work.append(path::PREFERRED_SEPARATOR);
	} else
	{
		work.chop (work.len()-4);
	}
	String doc_folder = work.tcopy_str();
	buflist.@each(;String key, Buffer value)
	{
		// for multi-files, extract module name
		// for monofiles, extract the current folder name and create a <name>.md file containing all
		// the modules in one file. in such case, we want to keep the full module name for all the modules.
		String fix_key = key;
		fix_key = fix_key.trim();
		if (mono) {
			monobuf.append ("\n");
			monobuf.append (value);
			monobuf.append ("\n");
		} else
		{
			
			// order of these is important
			fix_key = fix_key[7:fix_key.len-7]; // eat "module"
			// also possible to have multiple '@' in the module line, strip that too
			usz! index = fix_key.index_of_char('@');
			if (try index)
			{
				fix_key = fix_key[:index-1];
				fix_key = fix_key.trim();
			}
			index = fix_key.rindex_of_char(':'); // cut off at last '::' before module name
			if (try index)
			{
				fix_key = fix_key[index+1:fix_key.len-index-1];
			}
			index = fix_key.rindex_of_char('('); // snip any possible (<type>) from module name
			if (try index)
			{
				fix_key = fix_key[:index];
			}
			

			work.clear();
			work.append (fix_key);
			work.insert_at (0, doc_folder);
			work.append (".md");
			if (verbose) io::printfn("saving as :%s", work.str_view());
			value.save_as (work.str_view())!!;
		}
	};

	if (mono)
	{
		work.clear();
		work.append (doc_folder);
		work.append (dir_name);
		work.append (".md");
		if (verbose) io::printfn("saving as monofile:%s", work.str_view());
		monobuf.save_as (work.str_view())!!;
	}
	return 0;
}
