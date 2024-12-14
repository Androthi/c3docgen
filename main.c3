module c3docgen;
import buffer;
import std::io;
import std::io::path;
import std::collections::map;

Map(<String, Buffer>) buflist;

fn String Path.extract_dirname(self)
{
	String dir_path = self.dirname();
	usz! dir_start = dir_path.rindex_of_char(path::PREFERRED_SEPARATOR);
	if (try dir_start) dir_path = dir_path[dir_start+1:dir_path.len-dir_start-1];
	return dir_path;
}

fn bool! walker(Path p, bool is_dir, void*)
{
	String dir_name = p.extract_dirname();
	if (!is_dir)
	{
		if (p.has_extension("c3"))
		{
			io::printfn("Processing file :%s", p.basename());

			// extract the module name, check in buflist map to see if we already
			// have this object in the map.
			Buffer cur_buf = buffer::temp_file(p.path_string);
			while (true)
			{
				// we need to find module definition, make sure it is flush with line, so we know it's the correct one
				usz! index = cur_buf.find_next("module");
				if ( catch error = index)
				{
					io::printn("Error, .c3 file missing module identifier");
					return true;
				}
				usz cursor_pos = cur_buf.get_cursor();
				if (--cursor_pos > 0 ) cursor_pos--;
				if (cursor_pos > 0 && cur_buf.peek_char_at(cursor_pos)! != '\n') continue;
				break;
			}
			cur_buf.brk();
			cur_buf.span();
			String! module_name = cur_buf.get_line();
			if (catch error = module_name)
			{
				io::printn("Error, couldn't get the line from module");
				return true;
			}
			module_name = module_name.strip_end(";");

			// see if it's already in list
			Buffer cur_module;
			if (!buflist.has_key(module_name))
			{
				cur_module = buffer::new();
				cur_module.appendf ("## %s\n", module_name);
				Buffer tbuf = buflist.set_value_return( module_name, cur_module );
				buflist.set(module_name, cur_module);
			} else
			{
				cur_module = buflist.get(module_name)!;
			}
			//=============================================================================


			// here, cur_module is the doc file we are building for the module being parsed.
			// cur_buf is the module being parsed.
			cur_buf.trim();
			cur_buf.cursor_to_bof();
			Buffer sec;
			usz start_index;
			usz! end_index;
			String! word;
			String! fn_def;

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
					// <*, module, fn, macro
					switch (word)
					{
						case "<*":
							start_index = cur_buf.get_cursor();
							end_index = cur_buf.find_next("*>");
							if ( catch result = end_index){
								io::printn("Error: missing '*>'");
								return true;
							}
							end_index --;
							cur_buf.sub_buffer(start_index, end_index - start_index, &sec)!;
							cur_buf.brk(); // advance to the first white space
							cur_buf.span(); // advance to the first non-white space
							break;

						case "module":
							// the module name
						case "fn":
							// fn declaration that does not have docs, but add it anyway.
						case "macro":
							// macro declaration that does not have docs, but add it anyway.
							cur_buf.cursor_to_bol();
							fn_def = cur_buf.get_line();

							if (try fn_def){
								io::printfn("found def :%s", fn_def);
								if (fn_def.starts_with("module"))
								{
									if (sec.len() > 0)
									{
										usz save_cursor = cur_module.get_cursor();
										cur_module.cursor_to_bof();
										usz inx = cur_module.cursor_right_lines(2);
										cur_module.insert(inx, "\n\n");
										cur_module.insert_buffer(inx, sec);
										cur_module.cursor_to(save_cursor);
									}
								} else
								{
									cur_module.appendf("### %s\n", fn_def);
									cur_module.append_buffer(sec);
									cur_module.append("\n\n");
								}

								// inserting into cur_module potentially resized it and changed the pointer,
								// set it into the map again to update the pointer.
								buflist.set (module_name, cur_module);
								sec.clear();

							}

							break;
						default:
							// something else, advance to the next line and continue.
							cur_buf.cursor_next_line();
							continue;
					}
				}
			}
		}
	} else
	{
		// for debug
		//io::printfn("Processing directory :%s", dir_name);
	}
	return false;
}

fn int main(String[] args)
{

	// a doc gen test program

	Path! path = path::temp_cwd();
	io::printfn("Working on project folder :%s", path.path_string)!!;
	(void)path.walk(&walker, null);

	// save the files to /doc folder
	DString work = dstring::temp_new();
	work.append(path.path_string)!!;
	work.append(path::PREFERRED_SEPARATOR);
	work.append("docs");
	work.append(path::PREFERRED_SEPARATOR);
	String doc_folder = work.tcopy_str();
	buflist.@each(;String key, Buffer value)
	{
		// for multi-files, extract module name
		//+ TODO for monofiles, extract the current folder name and create a <name>.md file containing all
		// the modules in one file. in such case, we want to keep the full module name for all the modules.
		String fix_key = key;
		fix_key = fix_key.trim();
		fix_key = fix_key[7:fix_key.len-7];
		usz! colon_index = fix_key.rindex_of_char(':');
		if (try colon_index)
		{
			fix_key = fix_key[colon_index+1:fix_key.len-colon_index-1];
		}

		work.clear();
		work.append (fix_key);
		work.insert_at (0, doc_folder);
		work.append (".md");
		io::printfn("saving as :%s", work.str_view());
		value.save_as (work.str_view())!!;
	};
	return 0;
}
