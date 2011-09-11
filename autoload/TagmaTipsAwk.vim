" Awk Tagma Tool Tips/Balloon Plugin
" vim:foldmethod=marker
" File:         TagmaTipsAwk.vim
" Last Changed: 2011-09-10
" Maintainer:   Lorance Stinson @ Gmail ...
" Version:      0.1
" Home:         https://github.com/LStinson/TagmaTips
" License:      Public Domain
"
" Description:
" Awk tooltips for the Tagma Tool Tips Plugin
" When the buffer is written will also scan for all function definitions.
" A tooltip will thus be displayed for all functions in the file.

" Only process the plugin once. {{{1
if exists("g:loadedTagmaTipsAwk") || &cp || !has('balloon_eval')
    finish
endif
let g:loadedTagmaTipsAwk = 1

" Function to return the tooltip text. {{{1
function! TagmaTipsAwk#Expr()
    let l:word = v:beval_text
    let l:descr = []
    if has_key(s:AwkCommands, l:word)
        let l:descr = s:AwkCommands[l:word]
    elseif has_key(b:AwkToolTipsFuncs, l:word)
        let l:descr = b:AwkToolTipsFuncs[l:word]
    elseif has_key(s:AwkVariables, l:word)
        let l:descr = s:AwkVariables[l:word]
    else
        let l:descr = spellsuggest(spellbadword(v:beval_text)[0], 5, 0 )
    endif
    return join(l:descr, has("balloon_multiline") ? "\n" : " ")
endfunction

" Scan the current buffer for prodecures. {{{1
function! TagmaTipsAwk#FuncScan()
    let b:AwkToolTipsFuncs = {}
    let l:eof = line('$')
    let l:lnum = 1
    let l:blank = 0
    " Scan for function definitions.
    while l:lnum <= l:eof
        let l:line = getline(l:lnum)
        if match(l:line, '^\s*$') >= 0
            let l:blank = l:lnum
            let l:lnum = l:lnum + 1
            continue
        endif
        let l:matches = matchlist(l:line, '^\s*func\w*\s\+\(\([^ 	(]\+\)\(\s\+\|(\).\{-}\)\(\s\+{\s*\)\?$')
        if len(l:matches) != 0
            " Save the function.
            let l:fname = l:matches[2]
            let b:AwkToolTipsFuncs[l:fname] = []
            call extend(b:AwkToolTipsFuncs[l:fname],[l:matches[1], ''])
            " Try to find the description.
            let l:def_lnum = l:blank + 1
            while l:def_lnum < l:lnum && l:def_lnum > l:lnum - 30
                call add(b:AwkToolTipsFuncs[l:fname], getline(l:def_lnum))
                let l:def_lnum = l:def_lnum + 1
            endwhile
        endif
        let l:lnum = l:lnum + 1
    endwhile
endfunction

" Setup the balloon options for the current buffer. {{{1
function! TagmaTipsAwk#Setup()
    " Set the balloonexpr for the buffer if not already set.
    if !exists("b:loadedTagmaTipsBuffer")
        let b:loadedTagmaTipsBuffer = 1

        " Balloon settings.
        setlocal bexpr=TagmaTipsAwk#Expr()
        setlocal ballooneval

        " Callback to update the function list.
        au BufWritePost <buffer> call TagmaTipsAwk#FuncScan()

        " Initialize the local function list.
        call TagmaTipsAwk#FuncScan()
    endif
endfunction

" Dictionary of Awk commands. {{{1
let s:AwkCommands = {
    \ 'close':       ['close(file [, how])',
    \                 '',
    \                 'Close file, pipe or co-process.  The optional how should only be used when',
    \                 'closing  one  end  of  a two-way  pipe  to  a  co-process.   It  must be a',
    \                 'string value, either "to" or "from".'],
    \ 'getline':     ['getline',
    \                 '',
    \                 'The getline command returns 1 on success, 0 on end of file, and  -1  on an',
    \                 'error.  Upon an error, ERRNO contains a string describing the problem.',
    \                 '',
    \                 'getline			Set $0 from next input record; set NF, NR, FNR.',
    \                 'getline <file		Set $0 from next record of file; set NF.',
    \                 'getline var		Set var from next input record; set NR, FNR.',
    \                 'getline var <file		Set var from next record of file.',
    \                 'command | getline [var]	Run command piping the output either into  $0  or var,',
    \                 '			as above.',
    \                 'command |& getline [var]	Run  command  as  a  co-process piping the',
    \                 '			output either into $0 or var,  as  above.   Co-processes are  a  gawk',
    \                 '			extension.   (command can also be a socket.  See the subsection Special  File',
    \                 '			Names, below.)'],
    \ 'next':        ['next',
    \                 '',
    \                 'Stop  processing  the  current input record.  The next input record is read and',
    \                 'processing  starts over  with  the first pattern in the AWK program.  If the',
    \                 'end of the input data is reached, the  END block(s), if any, are executed.'],
    \ 'nextfile':    ['nextfile',
    \                 '',
    \                 'Stop processing the current input file.  The next input record read comes from',
    \                 'the next input file.  FILENAME  and ARGIND are updated, FNR is reset to 1, and',
    \                 'processing starts over with the first pattern  in the AWK program. If the end',
    \                 'of the input data is reached, the END block(s),  if  any,  are executed.'],
    \ 'print':       ['print',
    \                 '',
    \                 'print			Print  the  current record.  The output record is',
    \                 '			terminated with the value of the ORS variable.',
    \                 '			print expr-list Print expressions.  Each',
    \                 '			expression is  separated by',
    \                 '			the  value  of  the OFS variable.  The output record is',
    \                 '			terminated with the value  of  the  ORS variable.',
    \                 'print expr-list >file	Print  expressions  on  file.  Each expression is',
    \                 '			separated by the value of the OFS variable.   The',
    \                 '			output record is terminated with the value of the ORS',
    \                 '			variable.',
    \                 'print ... >> file		Appends output to the file.',
    \                 'print ... | command	Writes on a pipe.',
    \                 'print ... |& command	Sends  data to a co-process or socket.  (See also the',
    \                 '			subsection Special File Names, below.)'],
    \ 'printf':      ['printf',
    \                 '',
    \                 'printf fmt, expr-list	Format and  print.   See  The  printf  Statement, below.',
    \                 'printf fmt, expr-list >file	Format and print on file.'],
    \ 'system':      ['system(cmd-line)',
    \                 '',
    \                 'Execute the command cmd-line, and return the exit status.  (This may not be',
    \                 'available on  non-POSIX systems.)'],
    \ 'fflush':      ['fflush([file])',
    \                 '',
    \                 'Flush any buffers associated with the open output file or pipe file.   If  file',
    \                 'is  missing,  then flush  standard  output.   If  file  is  the null string,',
    \                 'then flush  all  open  output  files  and pipes.'],
    \ 'atan2':       ['atan2(y, x)',
    \                 '',
    \                 'Return the arctangent of y/x in radians.'],
    \ 'cos':         ['cos(expr)',
    \                 '',
    \                 'Return the cosine of expr, which is in radians.'],
    \ 'exp':         ['exp(expr)',
    \                 '',
    \                 'The exponential function.'],
    \ 'int':         ['int(expr)',
    \                 '',
    \                 'Truncate to integer.'],
    \ 'log':         ['log(expr)',
    \                 '',
    \                 'The natural logarithm function.'],
    \ 'rand':        ['rand()',
    \                 '',
    \                 'Return a random number N, between 0 and 1, such that 0 <= N < 1.'],
    \ 'sin':         ['sin(expr)',
    \                 '',
    \                 'Return the sine of expr, which is in radians.'],
    \ 'sqrt':        ['sqrt(expr)',
    \                 '',
    \                 'The square root function.'],
    \ 'srand':       ['srand([expr])',
    \                 '',
    \                 'Use expr as the new seed for the random number generator.  If no expr is',
    \                 'provided, use the time of day.  The  return value  is the previous seed for the',
    \                 'random number generator.'],
    \ 'asort':       ['asort(s [, d [, how] ])',
    \                 '',
    \                 'Return the number of  elements  in  the  source array  s.   Sort the contents',
    \                 "of s using gawk's normal rules for comparing values, and  replace the indices",
    \                 'of the sorted values s with sequential integers starting with 1. If the',
    \                 'optional destination  array  d  is specified, then first duplicate s into d,',
    \                 'and then  sort  d,  leaving the  indices  of  the source array s unchanged.',
    \                 'The optional string how controls the  direction and  the comparsion mode.',
    \                 'Valid values for how are   any   of   the    strings    valid    for',
    \                 'PROCINFO["sorted_in"].  It can also be the name of  a  user-defined  comparison',
    \                 'function   as described in PROCINFO["sorted_in"].'],
    \ 'asorti':      ['asorti(s [, d [, how] ])',
    \                 '',
    \                 'Return  the  number  of  elements in the source array s.  The behavior is the',
    \                 'same as  that  of asort(), except that the array indices are used for sorting,',
    \                 'not the array values.  When  done, the  array is indexed numerically, and the',
    \                 'values are those of  the  original  indices.   The original values are lost;',
    \                 'thus provide a second array if you wish  to  preserve  the  original.  The',
    \                 'purpose  of the optional string how is the same as described in asort() above.'],
    \ 'gensub':      ['gensub(r, s, h [, t])',
    \                 '',
    \                 'Search the target string t for matches  of  the regular  expression r.  If h is',
    \                 'a string beginning with g or G, then replace all matches of r with  s.',
    \                 'Otherwise,  h is a number indicating which match of r to replace.  If t is not',
    \                 'supplied,  use $0 instead.  Within the replacement text s, the sequence \n,',
    \                 'where  n  is  a  digit from  1  to 9, may be used to indicate just the text',
    \                 "that matched the n'th parenthesized subexpression.    The  sequence  \\0",
    \                 'represents  the entire matched text, as does the  character  &.  Unlike sub()',
    \                 'and gsub(), the modified string is returned as the result of the function, and',
    \                 'the original target string is not changed.'],
    \ 'gsub':        ['gsub(r, s [, t])',
    \                 '',
    \                 'For each substring matching the regular expression r in the string t,',
    \                 'substitute  the  string s,  and return the number of substitutions.  If t is',
    \                 'not  supplied,  use  $0.   An  &  in  the replacement text is replaced with the',
    \                 'text that was actually matched.  Use \& to get a  literal &.   (This  must  be',
    \                 'typed as "\\&"; see GAWK: Effective AWK Programming for a fuller  discussion',
    \                 "of  the  rules for &'s and backslashes in the replacement text of sub(),",
    \                 'gsub(), and gensub().)'],
    \ 'index':       ['index(s, t)',
    \                 '',
    \                 'Return  the index of the string t in the string s, or 0 if t is  not  present.',
    \                 '(This  implies that character indices start at one.)'],
    \ 'length':      ['length([s])',
    \                 '',
    \                 'Return  the  length  of  the  string  s, or the length of $0 if s is not',
    \                 'supplied.  As  a  nonstandard  extension,  with  an  array argument, length()',
    \                 'returns the number of elements in  the array.'],
    \ 'match':       ['match(s, r [, a])',
    \                 '',
    \                 'Return  the  position  in  s  where the regular expression r occurs, or 0 if r',
    \                 'is not  present, and set the values of RSTART and RLENGTH.  Note that the',
    \                 'argument order is the same as for  the ~  operator: str ~ re.  If array a is',
    \                 'provided, a is cleared and then elements 1 through n  are filled  with  the',
    \                 'portions of s that match the corresponding parenthesized subexpression in r.',
    \                 "The 0'th element of a contains the portion of s matched by the  entire  regular",
    \                 'expression  r.  Subscripts  a[n,  "start"],  and a[n, "length"] provide the',
    \                 'starting index in  the  string  and length  respectively,  of  each  matching',
    \                 'substring.'],
    \ 'patsplit':    ['patsplit(s, a [, r [, seps] ])',
    \                 '',
    \                 'Split the string s into the  array  a  and  the separators array seps on the',
    \                 'regular expression r, and return the number  of  fields.   Element values  are',
    \                 'the  portions of s that matched r.  The value of  seps[i]  is  the  separator',
    \                 'that appeared  in front of a[i+1].  If r is omitted, FPAT is used instead.  The',
    \                 'arrays  a  and  seps are  cleared  first.  Splitting behaves identically to',
    \                 'field splitting with  FPAT,  described above.'],
    \ 'split':       ['split(s, a [, r [, seps] ])',
    \                 '',
    \                 'Split  the  string  s  into the array a and the separators array seps on the',
    \                 'regular expression r,  and  return  the number of fields.  If r is omitted, FS',
    \                 'is used instead.  The arrays a  and seps  are  cleared first.  seps[i] is the',
    \                 'field separator matched by r between a[i] and a[i+1].  If r is a single space,',
    \                 'then leading whitespace in s goes into the extra array element  seps[0] and',
    \                 'trailing  whitespace  goes  into the extra array element seps[n], where n  is',
    \                 'the  return value  of  split(s,  a,  r,  seps).   Splitting behaves',
    \                 'identically   to   field   splitting, described above.'],
    \ 'sprintf':     ['sprintf(fmt, expr-list)',
    \                 '',
    \                 'Prints  expr-list according to fmt, and returns the resulting string.'],
    \ 'strtonum':    ['strtonum(str)',
    \                 '',
    \                 'Examine str, and return its numeric value.   If str begins with a leading 0,',
    \                 'strtonum() assumes that str is an octal  number.   If  str  begins with  a',
    \                 'leading  0x  or 0X, strtonum() assumes that str is a hexadecimal  number.',
    \                 'Otherwise, decimal is assumed.'],
    \ 'sub':         ['sub(r, s [, t])',
    \                 '',
    \                 'Just  like  gsub(),  but replace only the first matching substring.'],
    \ 'substr':      ['substr(s, i [, n])',
    \                 '',
    \                 'Return the at most n-character substring  of  s starting  at  i.  If n is omitted, use the rest of s.'],
    \ 'tolower':     ['tolower(str)',
    \                 '',
    \                 'Return a copy of the string str, with  all  the uppercase characters in str',
    \                 'translated to their corresponding  lowercase  counterparts.    Nonalphabetic',
    \                 'characters are left unchanged.'],
    \ 'toupper':     ['toupper(str)',
    \                 '',
    \                 'Return  a  copy of the string str, with all the'],
    \ 'lowercase':   ['lowercase',
    \                 '',
    \                 'characters in str translated to their'],
    \ 'corresponding': ['corresponding',
    \                 '',
    \                 'uppercase  counterparts.   Nonalphabetic characters are left unchanged.'],
    \ 'mktime':      ['mktime(datespec)',
    \                 '',
    \                 'Turn  datespec into a time stamp of the same form as returned by systime(), and',
    \                 'return  the  result.   The  datespec  is  a string  of  the form YYYY MM DD HH',
    \                 'MM SS[ DST].  The contents of the string are six or seven numbers  representing',
    \                 'respectively  the  full year including century, the month from 1 to 12, the day',
    \                 'of the month from 1 to 31, the hour  of  the  day from  0  to 23, the minute',
    \                 'from 0 to 59, the second from 0 to 60, and an optional daylight  saving  flag.',
    \                 'The  values  of these  numbers  need  not be within the ranges specified; for',
    \                 'example, an hour of -1 means 1  hour  before  midnight.   The origin-zero',
    \                 'Gregorian  calendar is assumed, with year 0 preceding year 1 and year -1',
    \                 'preceding  year  0.   The  time  is assumed  to be in the local timezone.  If',
    \                 'the daylight saving flag is positive, the time is assumed to be  daylight',
    \                 'saving time;  if  zero, the time is assumed to be standard time; and if',
    \                 'negative (the default),  mktime()  attempts  to  determine whether  daylight',
    \                 'saving time is in effect for the specified time.  If datespec does not contain',
    \                 'enough elements or if the resulting time is out of range, mktime() returns -1.'],
    \ 'strftime':    ['strftime([format [, timestamp[, utc-flag]]])',
    \                 '',
    \                 'Format  timestamp  according  to the specification in format.  If utc-flag is',
    \                 'present  and  is  non-zero  or  non-null,  the result is in UTC, otherwise the',
    \                 'result is in local time.  The timestamp should be of the same  form  as',
    \                 'returned  by  systime().   If timestamp is missing, the current time of day is',
    \                 'used.  If format is missing, a default format  equivalent  to the  output of',
    \                 'date(1) is used.  The default format is available in PROCINFO["strftime"].  See',
    \                 'the specification for  the strftime() function in ANSI C for the format',
    \                 'conversions that are guaranteed to be available.'],
    \ 'systime':     ['systime()',
    \                 '',
    \                 'Return the current time of day as the number of seconds since the Epoch',
    \                 '(1970-01-01 00:00:00 UTC on POSIX systems).'],
    \ 'and':         ['and(v1, v2)',
    \                 '',
    \                 'Return the bitwise AND of the values provided by v1 and v2.'],
    \ 'compl':       ['compl(val)',
    \                 '',
    \                 'Return the bitwise complement of val.'],
    \ 'lshift':      ['lshift(val, count)',
    \                 '',
    \                 'Return  the  value  of  val,  shifted left by count bits.'],
    \ 'or':          ['or(v1, v2)',
    \                 '',
    \                 'Return the bitwise OR of the values provided by  v1 and v2.'],
    \ 'rshift':      ['rshift(val, count)',
    \                 '',
    \                 'Return  the  value  of  val, shifted right by count bits.'],
    \ 'xor':         ['xor(v1, v2)',
    \                 '',
    \                 'Return the bitwise XOR of the values provided by v1 and v2.'],
    \ 'isarray':     ['isarray(x)',
    \                 '',
    \                 'Return true if x is an array, false otherwise.'],
    \ 'bindtextdomain': ['bindtextdomain(directory [, domain])',
    \                 '',
    \                 'Specify  the  directory  where  gawk looks for the .mo files, in case they will',
    \                 'not or cannot be placed in the ``standard'' locations  (e.g.,  during',
    \                 'testing).  It returns the directory where domain is ``bound.'' The default',
    \                 'domain is the value of TEXTDOMAIN.  If directory  is the  null string (""),',
    \                 'then bindtextdomain() returns the current binding for the given domain.'],
    \ 'dcgettext':   ['dcgettext(string [, domain [, category]])',
    \                 '',
    \                 'Return the translation of  string  in  text  domain  domain  for locale',
    \                 'category  category.  The default value for domain is the current value of',
    \                 'TEXTDOMAIN.  The default value for category  is "LC_MESSAGES".  If you supply a',
    \                 'value for category, it must be a string equal to one of the known locale',
    \                 'categories described in GAWK:  Effective AWK  Programming.   You  must  also',
    \                 'supply  a text domain.  Use TEXTDOMAIN if you want to use the current domain.'],
    \ 'dcngettext':  ['dcngettext(string1 , string2 , number [, domain [, category]])',
    \                 '',
    \                 'Return the plural form used for number  of  the  translation  of string1  and',
    \                 'string2  in text domain domain for locale category category.  The default value',
    \                 'for domain is the current value  of TEXTDOMAIN.  The default value for category',
    \                 'is "LC_MESSAGES".  If you supply a value for category, it must be a string',
    \                 'equal to one of the known locale categories described in GAWK:  Effective AWK',
    \                 'Programming.   You  must  also  supply  a text domain.  Use TEXTDOMAIN if you',
    \                 'want to use the current domain.'],
    \ }

" Dictionary of Awk variables. {{{1
let s:AwkVariables = {
    \ 'ARGC':        ['ARGC',
    \                 '',
    \                 'The  number  of  command  line  arguments (does not include options to gawk,',
    \                 'or the program source).'],
    \ 'ARGIND':      ['ARGIND',
    \                 '',
    \                 'The index in ARGV of the current file being processed.'],
    \ 'ARGV':        ['ARGV',
    \                 '',
    \                 'Array of command line arguments.  The array is indexed from 0  to  ARGC - 1.',
    \                 'Dynamically changing the contents of ARGV can control the files used for data.'],
    \ 'BINMODE':     ['BINMODE',
    \                 '',
    \                 'On non-POSIX systems, specifies use of  "binary"  mode  for all  file  I/O.',
    \                 'Numeric values of 1, 2, or 3, specify that input files, output  files,  or',
    \                 'all  files,  respectively, should  use binary I/O.  String values of "r", or',
    \                 '"w" specify that input files, or output files, respectively, should use binary',
    \                 'I/O.  String values of "rw" or "wr" specify that all files should use binary',
    \                 'I/O.  Any other string value is treated as "rw", but generates a warning',
    \                 'message.'],
    \ 'CONVFMT':     ['CONVFMT',
    \                 '',
    \                 'The conversion format for numbers, "%.6g", by default.'],
    \ 'ENVIRON':     ['ENVIRON',
    \                 '',
    \                 'An  array containing the values of the current environment.  The array is',
    \                 'indexed by  the  environment  variables,  each element  being  the  value  of',
    \                 'that  variable (e.g., ENVIRON["HOME"] might be /home/arnold).   Changing  this',
    \                 'array does not affect the environment seen by programs which gawk spawns via',
    \                 'redirection or the system() function.'],
    \ 'ERRNO':       ['ERRNO',
    \                 '',
    \                 'If a system error occurs either  doing  a  redirection  for getline,  during',
    \                 'a  read for getline, or during a close(), then ERRNO will contain a string',
    \                 'describing the error.  The value is subject to translation in non-English',
    \                 'locales.'],
    \ 'FIELDWIDTHS': ['FIELDWIDTHS',
    \                 '',
    \                 'A  whitespace  separated  list  of field widths.  When set, gawk parses the',
    \                 'input into fields of fixed  width,  instead of  using the value of the FS',
    \                 'variable as the field separator.  See Fields, above.'],
    \ 'FILENAME':    ['FILENAME',
    \                 '',
    \                 'The name of the current input file.  If no files are specified  on  the',
    \                 'command  line, the value of FILENAME is "-".  However, FILENAME  is  undefined',
    \                 'inside  the  BEGIN  block (unless set by getline).'],
    \ 'FNR':         ['FNR',
    \                 '',
    \                 'The input record number in the current input file.'],
    \ 'FPAT':        ['FPAT',
    \                 '',
    \                 'A  regular expression describing the contents of the fields in a record.  When',
    \                 'set, gawk parses the input into  fields, where  the  fields match the regular',
    \                 'expression, instead of using the value of the FS variable as the field',
    \                 'separator.  See Fields, above.'],
    \ 'FS':          ['FS',
    \                 '',
    \                 'The input field separator, a space by default.  See Fields, above.'],
    \ 'IGNORECASE':  ['IGNORECASE',
    \                 '',
    \                 'Controls the case-sensitivity of all regular expression and string',
    \                 'operations.   If  IGNORECASE  has a non-zero value, then string comparisons',
    \                 'and  pattern  matching  in  rules, field  splitting  with  FS and FPAT, record',
    \                 'separating with RS, regular expression matching with ~ and !~, and the',
    \                 'gensub(),  gsub(),  index(), match(), patsplit(), split(), and sub() built-in',
    \                 'functions all ignore case when doing regular expression  operations.   NOTE:',
    \                 'Array  subscripting is not affected.  However, the asort() and asorti()',
    \                 'functions  are affected.'],
    \ 'LINT':        ['LINT',
    \                 '',
    \                 'Provides  dynamic  control of the --lint option from within an AWK program.',
    \                 'When true, gawk prints lint warnings. When false,  it  does  not.   When',
    \                 'assigned  the  string  value "fatal", lint warnings become fatal  errors,',
    \                 'exactly  like --lint=fatal.  Any other true value just prints warnings.'],
    \ 'NF':          ['NF',
    \                 '',
    \                 'The number of fields in the current input record.'],
    \ 'NR':          ['NR',
    \                 '',
    \                 'The total number of input records seen so far.'],
    \ 'OFMT':        ['OFMT',
    \                 '',
    \                 'The output format for numbers, "%.6g", by default.'],
    \ 'OFS':         ['OFS',
    \                 '',
    \                 'The output field separator, a space by default.'],
    \ 'ORS':         ['ORS',
    \                 '',
    \                 'The output record separator, by default a newline.'],
    \ 'PROCINFO':    ['PROCINFO',
    \                 '',
    \                 'The  elements  of  this array provide access to information about the running',
    \                 'AWK program.  On some systems, there  may be  elements  in  the  array,',
    \                 '"group1" through "groupn" for some n, which is the number of  supplementary',
    \                 'groups  that the  process  has.   Use  the in operator to test for these',
    \                 'elements.  The following  elements  are  guaranteed  to  be available:',
    \                 '',
    \                 'PROCINFO["egid"]	the  value  of  the  getegid(2)  system call.',
    \                 'PROCINFO["strftime"]	The  default  time  format  string  for strftime().',
    \                 'PROCINFO["euid"]	the  value  of  the  geteuid(2)  system call.',
    \                 'PROCINFO["FS"]		"FS" if field splitting with FS  is  in effect,  "FPAT" if',
    \                 '			field splitting with FPAT is in effect, or "FIELDWIDTHS"',
    \                 '			if field  splitting with FIELDWIDTHS is in effect.',
    \                 'PROCINFO["gid"]		the value of the getgid(2) system call.',
    \                 'PROCINFO["pgrpid"]	the process group  ID  of  the  current process.',
    \                 'PROCINFO["pid"]		the process ID of the current process.',
    \                 'PROCINFO["ppid"]	the  parent  process  ID of the current process.',
    \                 'PROCINFO["uid"]		the value of the getuid(2) system call.',
    \                 'PROCINFO["sorted_in"]	If this  element  exists  in  PROCINFO, then  its  value',
    \                 '			controls the order in which array elements are',
    \                 '			traversed  in for   loops.  PROCINFO["version"] the',
    \                 '			version of gawk.'],
    \ 'RS':          ['RS',
    \                 '',
    \                 'The input record separator, by default a newline.'],
    \ 'RT':          ['RT',
    \                 '',
    \                 'The record terminator.  Gawk sets RT to the input text that matched the',
    \                 'character or regular  expression  specified  by RS.'],
    \ 'RSTART':      ['RSTART',
    \                 '',
    \                 'The  index  of the first character matched by match(); 0 if no match.  (This',
    \                 'implies that character  indices  start  at one.)'],
    \ 'RLENGTH':     ['RLENGTH',
    \                 '',
    \                 'The  length  of  the  string  matched  by match(); -1 if no match.'],
    \ 'SUBSEP':      ['SUBSEP',
    \                 '',
    \                 'The character used to separate multiple subscripts in array elements, by',
    \                 'default "\\034".'],
    \ 'TEXTDOMAIN':  ['TEXTDOMAIN',
    \                 '',
    \                 'The text domain of the AWK program; used to find the localized translations',
    \                 "for the program's strings."],
    \ }
