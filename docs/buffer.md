# module buffer

 this is a general purpose prototyping module used for parsing and creating files.
 contains methods for adding and deleting data into the buffer, tokenizing, cursor movements,
 file i/o, varisous search, replace methods.
 Buffer uses dynamic memory, all insertion methods will resize the buffer as needed.

## fn Buffer Buffer.new_init(&self, usz capacity = DEFAULT_CAPACITY, Allocator allocator = allocator::heap())

 Allocate memory for a new Buffer object. Panics if allocation fails
 @require !self.data() "Buffer already initialized"
 @param capacity `desired capacity for buffer, default = DEFAULT_CAPACITY`
 @param allocator `the allocator to use`

## fn Buffer Buffer.temp_init(&self, usz capacity = DEFAULT_CAPACITY)

 calls new_init with temp allocator.
 @require !self.data() "Buffer already initialized"

## fn Buffer new(usz capacity = DEFAULT_CAPACITY, Allocator allocator = allocator::heap())

 function call for new object

## fn Buffer temp_new(usz capacity = DEFAULT_CAPACITY) => new(capacity, allocator::temp()) @inline;

 function call for new temp object

## fn Buffer new_file(String filepath, Allocator allocator = allocator::heap())

 will attempt to create a new buffer object and load the contents of filepath.
 if the file does not exits, an empty buffer is created with the filepath and default capacity.

## fn Buffer temp_file(String filepath) => new_file (filepath, allocator::temp() ) @inline;

 same as new_file, using the temp allocator

## fn void Buffer.set_filepath(&self, String filepath)

 sets a new internal filepath for this object.
 this is the file created with the save() method.

## fn void Buffer.open_file(&self, String filepath)

 tries to open the file filepath and load it into the buffer.
 filepath is set as the internal filename for the buffer.
 this will replace existing content in the buffer.
 use append_file() to keep the contents of the buffer.

## macro void Buffer.append_file(&self, String filepath)

 will try to open filepath and append it at the end of the buffer.
 this macro is a wrapper around insert_file method.

## fn void Buffer.insert_file(&self, usz index, String filepath)

 tries to insert a file at the given index.
 if tere is no filepath specified for the buffer, sets filepath as the buffer's filepath.

## fn void Buffer.free(&self)

 free memory of buffer

## fn void Buffer.reserve(&self, usz addition) @private

 private method to reserve addition amount of bytes in the buffer memory.

## fn void Buffer.adjust_for_insert(&self, usz index, usz len) @private

 private helper metod for creating a len amount of space at index for
 inserting new data.

## fn void! Buffer.save(&self)

 saves te contents of the buffer to a file using the internal buffer filepath.
 returns error if there is no internal filepath set.
 returns NULL_BUFFER, SAVE_FAILED and NO_FILENAME errors.

## fn void! Buffer.save_as(&self, String filepath)

 saves te contents of the buffer to a file using filepath.
 the internal buffer filepath name is set to filepath.
 returns error if there is no internal filepath set.
 returns NULL_BUFFER, SAVE_FAILED and NO_FILENAM errors.

## fn BufferData* Buffer.data(self) @inline @private

 private method
 @return `a pointer to the buffer data`

## fn usz Buffer.capacity(self)

 @return `the capacity of buffer`

## fn String Buffer.get_filepath(self)

 @return `the filepath that is set for this buffer`

## fn usz Buffer.len(&self) @dynamic

 @return `the length of buffer`

## fn String Buffer.str_view(self)

 @return `a string slice of buffer contents`

## fn ZString Buffer.zstr_view(&self)

 @return `a zstring pointer of buffer contents. buffer is modified with a 0 at the end`

## fn void Buffer.clear(self)

 clears the contents of the buffer, does not reallocate memory.

## fn void Buffer.chop(self, usz new_size)

 @require new_size <= self.len()

## macro usz Buffer.get_cursor(self)

 @return `index of cursor`

## macro usz Buffer.cursor_to_eof(&self)

 move cursor to end of buffer
 @return `index of cursor`

## macro usz Buffer.cursor_to_bof(&self)

 move cursor to beginning of buffer
 @return `index of cursor`

## fn usz Buffer.cursor_to(&self, usz index)

 @param index `position to try moving cursor`
 @return `index of cursor`

## fn usz Buffer.cursor_right(&self, usz n)

 try to move cursor right (towards end of buffer)
 @param n `number of characters to move`
 @return `index of cursor`

## fn usz Buffer.cursor_left(&self, usz n)

 try to move cursor left (towards beginning of buffer)
 @param n `number of characters to move`
 @return `index of cursor`

## fn usz Buffer.cursor_right_lines(&self, usz num_lines)

 tries to move cursor right (towards end of buffer) num_lines number of lines.
 @param num_lines `number of lines to move`
 @return `index of cursor`

## fn usz Buffer.cursor_to_bol(&self)

 move cursor to beginning of current line
 @return `index of cursor`

## fn usz Buffer.cursor_to_eol(&self)

 moves the internal cursor to the the end of the current line
 @return `index of cursor`

## fn usz Buffer.span(&self, Cset set = WHITE_SPACES)

 moves the internal cursor to the next character that is not a member of set.
 @return `index of cursor`

## fn usz Buffer.r_span(&self, Cset set = WHITE_SPACES)

 moves the internal cursor to the previous character that is not a member of set.
 @return `index of cursor`

## fn usz Buffer.brk(&self, Cset set = WHITE_SPACES)

 moves the internal cursor to the next character that is a member of set.
 @return `index of cursor`

## fn usz Buffer.r_brk(&self, Cset set = WHITE_SPACES)

 moves the internal cursor to the previous character that is a member of set.
 @return `index of cursor`

## fn char! Buffer.get_char(&self)

 @return! BufferError.NULL_BUFFER, BufferError.EOF
 @return `character at cursor index in buffer. cursor is advanced by 1`

## fn char! Buffer.peek_char_at(&self, usz index)

 @return! BufferError.NULL_BUFFER, BufferError.INDEX_OUT_OF_RANGE
 @return `character at cursor index in buffer.`

## fn String! Buffer.get_line(&self, bool entire_line = true)

 @param entire_line `if true, finds the beginning and end of line at cursor, if false, beginning of line is starting cursor index`
 @return! BufferError.NULL_BUFFER, BufferError.EOF
 @return `string slice of entire line at cursor index, cursor is advanced to end of current line`

## macro String! Buffer.get_cursor_line(&self)

 wrapper for get_line with parameter for entire_line set to false.

## fn String! Buffer.get_line_from(&self, usz start)

 cursor independent method to get the string slice of a line
 @param start `index that determines beginning of line to retreive`
 @return! BufferError.NULL_BUFFER, BufferError.EOF
 @return `string slice of line starting at start`

## fn usz! Buffer.find_next(&self, String needle, bool case_sensitive = true)

 @param needle `string to search`
 @param case_sensitive `search is case_sensitive if true`
 @return! BufferError.NULL_BUFFER, BufferError.EOF
 @return `index in buffer where needle is found, cursor is advanced to end of found data`

## macro usz! Buffer.ifind_next(&self, String needle)

 wrapper around find_next with case_sensitive set to false

## fn usz! Buffer.find(&self, String needle, usz start_from = 0, bool case_sensitive = true)

 @param needle `the string to search for in the buffer`
 @param start_from `the index in buffer from which to begin searching`
 @param case_sensitive `if true, search is case sensitive, default true`
 @return! BufferError.NULL_BUFFER, BufferError.EOF
 @return `index if needle is found in buffer`

## macro usz! Buffer.ifind(&self, String needle, usz start_from = 0)

 wrapper around find method with case sensitive set to false

## macro usz Buffer.append_char32(&self, Char32 c)

 @require c <= 0x10ffff

## fn void Buffer.set(self, usz index, char c)

 @require index < self.len()

## fn void Buffer.insert_chars(&self, usz index, String s)

 @require index <= self.len()

## fn void Buffer.insert_string(&self, usz index, DString str)

 @require index <= self.len()

## fn void Buffer.insert_char(&self, usz index, char c)

 @require index <= self.len()

## fn usz Buffer.insert_char32(&self, usz index, Char32 c)

 @require index <= self.len()

## fn usz Buffer.insert_utf32(&self, usz index, Char32[] chars)

 @require index <= self.len()

## fn void Buffer.delete(&self, usz start, usz len = 1)

 @require start < self.len()
 @require start + len <= self.len()

## fn void Buffer.delete_range(&self, usz start, usz end)

 @require start < self.len()
 @require end < self.len()
 @require end >= start "End must be same or equal to the start"

## fn bool Buffer.is_eof(self)

 @return `true if cursor is at EOF`

