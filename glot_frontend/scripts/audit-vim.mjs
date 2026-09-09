// Compare reducer traces with an installed Vim after `gleam test`.
// This audit deliberately exits unsuccessfully while differences remain.
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, writeFileSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
const base = '../build/dev/javascript/glot_frontend/';
const option = await import('../build/dev/javascript/gleam_stdlib/gleam/option.mjs');
const driver = await import(`${base}support/code_editor_driver.mjs`);
const keys = await import(`${base}glot_frontend/public/editor/code_editor/keys.mjs`);
const bridge = await import(`${base}glot_frontend/public/editor/code_editor/settings_bridge.mjs`);

const model = await import(`${base}glot_frontend/public/editor/code_editor/model.mjs`);
const session = await import(`${base}glot_frontend/public/editor/code_editor/session.mjs`);
const message = await import(`${base}glot_frontend/public/editor/code_editor/message.mjs`);
const vim = await import(`${base}glot_frontend/public/editor/code_editor/keymap/vim.mjs`);

const cases = [
  ['counted normal join', 'one\ntwo\nthree\nfour', '3J'],
  ['counted normal join without spaces', 'one\ntwo\nthree\nfour', '3gJ'],
  ['counted normal substitute lines', 'one\ntwo\nthree\nfour', '2SX<Esc>'],
  ['counted normal delete to end', 'one\ntwo\nthree\nfour', 'l2D'],
  ['counted normal change to end', 'one\ntwo\nthree\nfour', 'l2CX<Esc>'],
  ['counted normal substitute stops at end', 'one\ntwo', 'l9sX<Esc>'],
  ['visual line yank alias', 'one\ntwo\nthree', 'VjYjp'],
  ['visual character yank line alias', 'one\ntwo\nthree', 'lvjYjp'],
  ['visual line shift count', 'one\ntwo\nthree', 'Vj2>', 'set shiftwidth=2 expandtab'],
  ['visual character shift count', 'one\ntwo\nthree', 'vj2>', 'set shiftwidth=2 expandtab'],
  ['visual join selected lines', 'one\ntwo\nthree\nfour', 'VjjJ'],
  ['visual line paste replaces selection', 'one\ntwo\nthree\nfour', 'yyjVjp'],
  ['block dollar moves through short rows', 'abcd\nx\nijklmnop', '2l<C-v>$jjd'],
  ['block dollar moves up', 'abcd\nefghijkl\nxyzxyz', 'j2l<C-v>$kd'],
  ['block dollar horizontal cancels goal', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$hjjd'],
  ['block dollar yank after vertical', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$jyjp'],
  ['block dollar replace after vertical', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$jjrX'],
  ['block dollar repeat', 'abcd\nefghijkl\nxyzxyz\n12345678', 'l<C-v>$jdj.'],
  ['block dollar repeat on longer rows', 'abcd\nefgh\nxyzxyzxyzxyz\n123456789012', 'l<C-v>$jdj.'],
  ['block dollar restore', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$j<Esc>gvd'],
  ['block dollar swap ends', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$jod'],
  ['block dollar append', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$jAX<Esc>'],
  ['block dollar change', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$jcX<Esc>'],
  ['normal dollar follows line ends', 'abcd\nefghijkl\nxyzxyz', '$jj'],
  ['counted character put before', 'one two', 'yiww3P'],
  ['counted line put before', 'one\ntwo', 'yyj2P'],
  ['counted character put undo', 'one two', 'yiww3pu'],
  ['counted line put undo', 'one\ntwo', 'yy2pu'],
  ['counted character put repeat', 'one two', 'yiww3p.'],
  ['counted put preserves register', 'one two', 'yiww3p"0P'],
  ['counted block put before', 'abcd\nefgh\nijkl', '<C-v>jlyj2P'],
  ['counted block put undo', 'abcd\nefgh\nijkl', '<C-v>jlyj2pu'],
  ['counted short block put', 'abcd\nx\nijkl', '<C-v>jlyj2p'],
  ['counted short block put at end', 'abcd\nx\nijkl', '<C-v>jlyG$2p'],
  ['block shift right at row end', 'abc\nx\nxyz', 'l<C-v>j>', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift left through tab', 'a\tb\nc\td', 'l<C-v>j<', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift left counted', 'a      b\nc      d', 'l<C-v>j2<', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift left stops at text', 'a b  c\nd e  f', 'l<C-v>j2<', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift preserves register', 'abcd\nefgh', 'yiwl<C-v>j>"0p', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift repeat', 'abcd\nefgh\nijkl\nmnop', 'l<C-v>j>jj.', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift reverse selection', 'abcd\nefgh\nijkl', 'j2l<C-v>kh>', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block left shift no whitespace', 'abcd\nefgh', 'l<C-v>j<', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift right inside lines', 'abcd\nefgh\nijkl', 'l<C-v>j>', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift left inside whitespace', 'a    b\nc    d\ne    f', 'l<C-v>j<', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift right counted', 'abcd\nefgh\nijkl', 'l<C-v>j2>', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift right skips short rows', 'abcd\n\nx\nijkl', '2l<C-v>3j>', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift starts inside tab', 'abcd\na\tb\nzzzz', '2l<C-v>j>', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block shift undo', 'abcd\nefgh', 'l<C-v>j>u', 'set shiftwidth=2 expandtab tabstop=4'],
  ['block end-of-line deletion', 'abcd\nefghijkl\nxy', 'l<C-v>j$d'],
  ['block end-of-line then down', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>$jjd'],
  ['block end-of-line yank and paste', 'abcd\nefghijkl\nxyzxyz', 'l<C-v>j$yjp'],
  ['block counted paste', 'abcd\nefgh\nijkl', '<C-v>jlyj2p'],
  ['normal counted character paste', 'one two', 'yiww3p'],
  ['normal counted line paste', 'one\ntwo', 'yy2p'],
  ['Ex semicolon relative range', 'one\ntwo\nthree\nfour', ':2;+1d<CR>'],
  ['Ex range-only cursor', 'one\n  two\nthree', ':2<CR>'],
  ['Ex substitution last matching line', 'one\none\nnone', ':%s/\\<one\\>/X/g<CR>'],
  ['Ex substitution line start', 'one\ntwo', ':%s/^/X/<CR>'],
  ['Ex substitution line end', 'one\ntwo', ':%s/$/X/<CR>'],
  ['Ex substitution newline replacement', 'one two', ':s/one/A\\rB/<CR>'],
  ['Ex substitution ignore case', 'One one ONE', ':s/one/X/gi<CR>'],
  ['Ex substitution reuses search', 'one two one', '/one<CR>:s//X/g<CR>'],
  ['Ex literal replacement dollar', 'one two', ':s/one/$1/<CR>'],
  ['Ex escaped replacement ampersand', 'one two', ':s/one/\\&/<CR>'],
  ['Ex substitute first match per line', 'one one\none one', ':%s/one/X/<CR>'],
  ['Ex substitute explicit range', 'one one\none one\none one', ':2,3s/one/X/g<CR>'],
  ['Ex substitute current to end', 'one\none\none', 'j:.,$s/one/X/<CR>'],
  ['Ex relative delete range', 'one\ntwo\nthree\nfour', 'j:.,+1d<CR>'],
  ['Ex delete updates numbered register', 'one\ntwo\nthree\nfour', ':2,3d<CR>"1p'],
  ['Ex yank range and paste', 'one\ntwo\nthree\nfour', ':2,3y<CR>p'],
  ['Ex delete current line', 'one\ntwo\nthree', 'j:d<CR>'],
  ['Ex delete last line', 'one\ntwo\nthree', ':$d<CR>'],
  ['Ex substitute undo', 'one one\none one', ':%s/one/X/g<CR>u'],
  ['Ex substitute capture replacement', 'one two', ':s/\\(one\\)/[\\1]/<CR>'],
  ['Ex substitute whole match replacement', 'one two', ':s/one/[&]/<CR>'],
  ['Ex substitute alternate delimiter', 'one two', ':s#one#X#<CR>'],
  ['Ex substitute escaped delimiter', 'one/two three', ':s/one\\/two/X/<CR>'],
  ['Ex visual substitute selected lines', 'one\none\none', 'Vj:s/one/X/<CR>'],
  ['Ex visual delete selected lines', 'one\ntwo\nthree', 'Vj:d<CR>'],
  ['Ex explicit visual marks', 'one\ntwo\nthree', 'Vj<Esc>:\'<,\'>d<CR>'],
  ['search very magic grouping', 'one abcd abd', '/\\v(ab|xy)c?d<CR>'],
  ['search very nomagic literal', 'one a+b.* end', '/\\Va+b.*<CR>'],
  ['search nomagic dot', 'one a.b acb', '/\\Ma.b<CR>'],
  ['search escaped grouping backreference', 'one abab abac', '/\\(ab\\)\\1<CR>'],
  ['search counted repetition', 'one aa aaa', '/a\\{3}<CR>'],
  ['search optional atom', 'one ac abc', '/ab\\=c<CR>'],
  ['search case override', 'one One ONE', '/\\cONE\\C<CR>'],
  ['search collection literal plus', 'one + a', '/[+]<CR>'],
  ['search repeated line end', 'abc\ndef\nghi', '/$<CR>n'],
  ['visual search line end', 'abc\ndef', 'v/$<CR>d'],
  ['operator search line end', 'abc\ndef', 'd/$<CR>'],
  ['search overlapping pattern', 'ababa', '/aba<CR>'],
  ['search repeated boundary', 'one someone one', '/\\<one\\><CR>n'],
  ['sentence without punctuation trailing spaces', 'One sentence   ', 'dis'],
  ['sentence with punctuation trailing spaces', 'One sentence.   ', 'dis'],
  ['sentence from leading spaces', '  One. Two.', 'dis'],
  ['around sentence from leading spaces', '  One. Two.', 'das'],
  ['sentence from blank line', 'One.\n\nTwo.', 'jdis'],
  ['sentence whitespace-only paragraph', 'One line\n  \nNext.', 'dis'],
  ['sentence change repeat', 'One. Two. Three.', 'cisX<Esc>w.'],
  ['sentence change undo', 'One. Two.', 'cisX<Esc>u'],
  ['visual counted sentences', 'One. Two. Three.', 'v3isd'],
  ['visual backward counted sentences', 'One. Two. Three.', '10lvh2isd'],
  ['visual backward around sentence', 'One. Two. Three.', '5lvhasd'],
  ['visual backward around sentence count', 'One. Two. Three.', '10lvh2asd'],
  ['visual sentence from internal whitespace', 'One long sentence. Two.', '4lvisd'],
  ['sentence count from whitespace', 'One.  Two. Three.', '4ld3is'],
  ['around sentence', 'One sentence. Two sentence.', 'das'],
  ['inner sentence from middle', 'One sentence. Two sentence.', '5ldis'],
  ['inner sentence from whitespace', 'One.  Two. Three.', '4ldis'],
  ['around sentence from whitespace', 'One.  Two. Three.', '4ldas'],
  ['counted inner sentences', 'One. Two. Three.', 'd2is'],
  ['counted around sentences', 'One. Two. Three.', 'd2as'],
  ['sentence punctuation closers', 'One!") Two? Three.', 'dis'],
  ['sentence punctuation without space', 'one.two end. Next.', 'dis'],
  ['sentence crosses newline', 'One line\ncontinues. Next.', 'dis'],
  ['sentence paragraph boundary', 'One line\n\nNext.', 'dis'],
  ['sentence at document end', 'One. Last sentence', '$das'],
  ['sentence count past end', 'One. Two.', 'd9is'],
  ['visual repeated sentence', 'One. Two. Three.', 'visisd'],
  ['visual repeated around sentence', 'One. Two. Three.', 'vasasd'],
  ['visual backward sentence', 'One. Two. Three.', '5lvhisd'],
  ['visual tag count from inner selection', '<p>hello <b>world</b></p>', '11lvit2itd'],
  ['visual tag selection spans siblings', '<p><b>one</b> <i>two</i></p>', '6lv12litd'],
  ['tag whitespace before closing tag', '<p>one   </p>', '6ldit'],
  ['tag with namespace', '<x:p>hello</x:p>', '5ldit'],
  ['tag change undo', '<p>hello <b>world</b></p>', '3lcitX<Esc>u'],
  ['visual empty inner tag', '<p></p>', 'vitd'],
  ['change empty inner tag', '<p></p>', 'citX<Esc>'],
  ['tag from leading whitespace', '  <p>hello</p>', 'dit'],
  ['tag from self-closing child', '<p>one<br/>two</p>', '7ldit'],
  ['tag comment inside element', '<p>one<!-- <p> -->two</p>', '3ldit'],
  ['quoted angle bracket attribute', '<p title="a>b">hello</p>', '14ldit'],
  ['tag count past outermost', '<p>hello</p>', '3ld2it'],
  ['visual backward tag expansion', '<p>hello <b>world</b></p>', '11lvitoitd'],
  ['tag object on opening tag', '<p>hello <b>world</b></p>', 'dit'],
  ['tag object on closing tag', '<p>hello <b>world</b></p>', '$dit'],
  ['inner nested tag', '<p>hello <b>world</b></p>', '11ldit'],
  ['counted nested tag', '<p>hello <b>world</b></p>', '11ld2it'],
  ['around nested tag', '<p>hello <b>world</b></p>', '11ldat'],
  ['same-name nested tags', '<p>one<p>two</p>three</p>', '8ld2it'],
  ['mixed-case tags', '<P>hello</p>', '3ldit'],
  ['self-closing tag inside element', '<p>one<br/>two</p>', '3ldit'],
  ['unclosed HTML tag inside element', '<p>one<br>two</p>', '3ldit'],
  ['stray closing tag inside element', '<p>one</bad>two</p>', '3ldit'],
  ['tag attributes', '<p title="hi">hello</p>', '14ldit'],
  ['empty inner tag', '<p></p>', 'dit'],
  ['visual repeated inner tag', '<p>hello <b>world</b></p>', '11lvititd'],
  ['visual repeated outer tag', '<p>hello <b>world</b></p>', '11lvatatd'],
  ['visual tag climbs to parent content', '<p>hello <b>world</b></p>', '11lvitititd'],
  ['visual inner tag on opening tag', '<p>hello</p>', 'vitd'],
  ['inner word counts whitespace', 'one two three four', 'd3iw'],
  ['outer and inner object counts multiply', 'one two three four', '2d2iw'],
  ['around word count', 'one two three four', 'd2aw'],
  ['inner word from whitespace', 'one  two three', '3ld2iw'],
  ['around word from whitespace', 'one  two three', '3ldaw'],
  ['around words from whitespace', 'one  two three four', '3ld2aw'],
  ['inner words across newline', 'one\ntwo three', 'd2iw'],
  ['around words across newline', 'one\ntwo three', 'd2aw'],
  ['inner WORD count', 'one.two three four', 'd3iW'],
  ['visual inner word count', 'one two three four', 'v3iwd'],
  ['visual around word count', 'one two three four', 'v2awd'],
  ['visual repeated inner word', 'one two three four', 'viwiwd'],
  ['visual backward word expansion', 'one two three four', 'wvhiwd'],
  ['word count past end', 'one two', 'd9iw'],
  ['around word count past end', 'one two', 'd9aw'],
  ['change word count past end', 'one two', 'c9iw'],
  ['visual word count past end', 'one two', 'v9iwd'],
  ['visual repeated around word', 'one two three', 'vawawd'],
  ['visual backward counted word', 'one two three four', '2wvh2iwd'],
  ["append character to block register", "abcd\nefgh\nijkl", "<C-v>j\"ayj\"Ayiwgg\"ap"],
  ["append block to character register", "abcd\nefgh\nijkl", "\"ayiwj<C-v>j\"Aygg\"ap"],
  ["append blocks with different widths", "abcd\nefgh\nijkl\nmnop", "<C-v>j\"ayjj<C-v>jl\"Aygg\"ap"],
  ["append line to block register", "abcd\nefgh\nijkl", "<C-v>j\"ayj\"Ayygg\"ap"],
  ["empty deletion preserves register", "one\n\nthree", "yiwjx\"0p"],
  ["black hole block deletion preserves register", "abcd\nefgh\nijkl", "yiw<C-v>j\"_d\"0p"],

  ["yank zero survives delete", "one two three", "yiwwdiw\"0p"],
  ["named yank preserves zero", "one two three", "yiww\"ayiw\"0p"],
  ["small delete register", "one two three", "diw\"-p"],
  ["named small delete preserves small register", "one two three", "xw\"adiw\"-p"],
  ["numbered deletes rotate", "one\ntwo\nthree\nfour", "dddd\"2p"],
  ["named line delete enters numbered history", "one\ntwo\nthree", "\"add\"1p"],
  ["black hole line delete preserves history", "one\ntwo\nthree\nfour", "dd\"_dd\"1p"],
  ["search deletion enters numbered history", "one two three", "d/two<CR>\"1p"],
  ["character register append", "one two three", "\"ayiw w\"Ayiw\"ap"],
  ["uppercase register reads lowercase", "one two", "\"ayiw w\"Ap"],
  ["append updates unnamed register", "one\ntwo\nthree", "\"ayyj\"Ayyjp"],
  ["append character to line register", "one\ntwo\nthree", "\"ayyj\"Ayiwj\"ap"],
  ["append line to character register", "one\ntwo\nthree", "\"ayiwj\"Ayyj\"ap"],
  ["append block register", "abcd\nefgh\nijkl\nmnop", "<C-v>j\"ayjj<C-v>j\"Aygg\"ap"],
  ["visual named paste preserves source", "one two three", "\"ayiwwve\"apw\"ap"],

  ["Vim search literal plus", "aaab a+b", "/a+b<CR>"],
  ["Vim search escaped repetition", "a ab aaab", "/a\\+b<CR>"],
  ["Vim search keyword boundaries", "one someone one", "/\\<one\\><CR>"],
  ["Vim search inline ignorecase", "One one ONE", "/\\cONE<CR>"],
  ["Vim search end of line", "abc\ndef", "/$<CR>"],
  ["Vim search alternation", "one two three", "/two\\|three<CR>"],

  ['search operator count', 'one two one two one', 'd2/one<CR>'],
  ['search operator change undo', 'one two three', 'c/two<CR>X<Esc>u'],
  ['search operator change repeat', 'one two one two', 'c/two<CR>X<Esc>w.'],
  ['search operator deletion repeat', 'one two one two', 'd/two<CR>w.'],
  ['search prompt cancellation clears operator', 'one two one', 'd/<Esc>/two<CR>', '', ['d/<Esc>', '/two<CR>']],
  ['search macro retains prompt text', 'one two one two one', 'qq/one<CR>q@q'],
  ['visual backward word search', 'one two one two one', '$v#d'],

  ['search reverse repeat keeps original direction', 'one two one two one', '/one<CR>Nn'],
  ['search count and wrap', 'one two one two one', '2/one<CR>2n'],
  ['search empty pattern reuse', 'one two one two one', '/one<CR>/<CR>'],
  ['search defaults case sensitive', 'One one One one', '/One<CR>'],
  ['visual search extends from anchor', 'one two one two', 'v/two<CR>d'],
  ['visual repeated search extends selection', 'one two one two one', '/one<CR>vnx'],
  ['backward search starts before cursor', 'one two one', '2l?one<CR>'],
  ['word search partial variant', 'one someone one', 'g*'],
  ['word search from whitespace', 'one two two', '3l*'],
  ['word search prefers keyword after punctuation', 'one .two two', '4l*'],
  ['operator with repeated search', 'one two one two one', '/one<CR>0dn'],
  ['operator search prompt', 'one two one', 'd/two<CR>'],

  ['search forward next', 'one two one two one', '/one<CR>n'],
  ['search backward next', 'one two one two one', '$?one<CR>n'],
  ['search does not select match', 'one two one', '/two<CR>x'],
  ['search word boundary', 'one someone one', '*'],
  ['black hole preserves unnamed register', 'one two three', 'yiww"_diwp'],
  ['uppercase register appends', 'one\ntwo\nthree', '"ayyj"Ayyj"ap'],
  ['numbered delete register', 'one\ntwo\nthree', 'dd"1p'],
  ['mark follows inserted text', 'abc def', 'wma0iX<Esc>`a'],
  ['counted inner word', 'one two three', 'd2iw'],
  ['sentence object', 'One sentence. Two sentence.', 'dis'],
  ['nested tag object', '<p>hello <b>world</b></p>', '3ldit'],
  ['Ex delete range', 'one\ntwo\nthree\nfour', ':2,3d<CR>'],
  ['Ex substitute current line', 'one one\none one', ':s/one/X/g<CR>'],
  ['Ex substitute whole document', 'one one\none one', ':%s/one/X/g<CR>'],

  ['replace identical text still repeats', 'abaa', 'Ra<Esc>l.'],
  ['counted insertion after repeated letters', 'aaaa', '3ia<Esc>'],

  ['replace identical characters', 'aaaa', 'Ra<Esc>'],
  ['replace backspace extension', 'ab', 'RXYZ<BS><BS><Esc>'],
  ['replace counted backspace', 'abcdefghij', '3RXY<BS><Esc>'],
  ['replace native macro', 'abcdefghi', 'qqlRXY<Esc>lq@q'],

  ['replace extends line', 'abc\ndef', 'lRXYZW<Esc>'],
  ['replace undo', 'abcdef', 'lRXY<Esc>u'],
  ['replace dot short line', 'abcdef\nx\nzz', 'lRXY<Esc>j0.'],
  ['replace backspace restores character', 'abcdef', 'lRXY<BS><Esc>'],
  ['replace backspace then text', 'abcdef', 'lRXY<BS>Z<Esc>'],
  ['counted replace mode', 'abcdefghij', '3RXY<Esc>'],

  ['counted insert multiple characters', 'abc', '3iXY<Esc>'],
  ['counted append', 'abc', '3aXY<Esc>'],
  ['counted insert undo', 'abc', '3iXY<Esc>u'],
  ['counted insert dot', 'abc', '3iX<Esc>l.'],
  ['counted insert backspace', 'abc', '3iXY<BS><Esc>'],
  ['counted insert macro', 'abc', 'qq3iX<Esc>lq@q'],
  ['counted insert ctrl-c', 'abc', '3iX<C-c>'],

  ['block change repeat into indentation', '// first file\nfunction greet(name) {\n  const parts = ["hello", name];\n  return parts.join(" ");\n}\n', '<C-v>jlcX<Esc>jj.'],

  ['reverse visual repeat', 'abcdefghij', '3lvhhdl.'],
  ['linewise visual repeat', 'a\nb\nc\nd\ne\nf', 'Vjdj.'],
  ['multiline visual repeat', 'abcd\nefgh\nijkl\nmnop', 'lvjdj0.'],
  ['block delete repeat', 'abcd\nefgh\nijkl\nmnop', '<C-v>jldjj.'],
  ['block insertion repeat', 'abcd\nefgh\nijkl\nmnop', '<C-v>jlIX<Esc>jj.'],
  ['visual change repeat', 'one two three', 'vlcX<Esc>w.'],
  ['counted visual repeat', 'abcdefghijkl', 'vldl2.'],

  ['block D to end', 'abcd\nefghij\nkl', 'l<C-v>jD'],
  ['block C to end', 'abcd\nefghij\nkl', 'l<C-v>jCX<Esc>'],
  ['block D partial tab', 'abcd\n\txyz', 'l<C-v>jlD', 'set ts=4'],
  ['block C partial tab', 'abcd\n\txyz', 'l<C-v>jlCX<Esc>', 'set ts=4'],

  ['visual X whole lines', 'abcd\nefgh\nijkl', 'lvjX'],
  ['visual S whole lines', 'abcd\nefgh\nijkl', 'lvjSX<Esc>'],
  ['visual R whole lines', 'abcd\nefgh\nijkl', 'lvjRX<Esc>'],
  ['visual Y whole lines', 'abcd\nefgh\nijkl', 'lvjYjp'],
  ['block X rectangle', 'abcd\nefgh', '<C-v>jlX'],
  ['block S whole lines', 'abcd\nefgh', '<C-v>jlSX<Esc>'],
  ['block R whole lines', 'abcd\nefgh', '<C-v>jlRX<Esc>'],
  ['block Y rectangle', 'abcd\nefgh\nijkl', '<C-v>jlYjp'],

  ['visual reverse uppercase delete', 'abcd\nefgh\nijkl', 'jlvlkD'],
  ['visual uppercase delete EOF', 'abcd\nefgh', 'jlvD'],
  ['visual uppercase change undo', 'abcd\nefgh\nijkl', 'lvjCX<Esc>u'],
  ['visual character uppercase corner exchange', 'abcdef', 'lvllOhd'],
  ['block reverse corner exchange', 'abcd\nefgh', 'jl<C-v>khOd'],
  ['block corner exchange twice', 'abcd\nefgh', '<C-v>jlOOd'],

  ['visual uppercase delete', 'abcd\nefgh\nijkl', 'lvjD'],
  ['visual uppercase change', 'abcd\nefgh\nijkl', 'lvjCX<Esc>'],
  ['block corner exchange', 'abcd\nefgh', '<C-v>jlOd'],
  ['block change repeat shape', 'abcd\nefgh\nijkl\nmnop', '<C-v>jlcX<Esc>jj.'],
  ['visual delete repeat shape', 'abcdef', 'vldl.'],
  ['counted insertion', 'abc', '3iX<Esc>'],
  ['replace mode native text', 'abcdef', 'lRXY<Esc>'],

  ['multiline document insert dot', 'abc\ndef', 'iXY<Esc>l.'],
  ['multiline document insert undo', 'abc\ndef', 'iXY<Esc>u'],
  ['block append no text', 'abcd\nx\nijkl', '2l<C-v>jjA<Esc>'],
  ['block reverse append no text', 'abcd\nx', '2l<C-v>jA<Esc>'],
  ['block insert backspace', 'abcd\nefgh', '<C-v>jlIXY<BS><Esc>'],
  ['block append tab', 'abcd\n\txyz', 'l<C-v>jlAX<Esc>', 'set ts=4'],
  ['block insert ctrl-c', 'abcd\nefgh', '<C-v>jlIX<C-c>'],
  ['change dot replay', 'one two three', 'cwX<Esc>w.'],
  ['insert repeat undo', 'abc', 'iX<Esc>l.u'],

  ['insert undo', 'abc', 'iXY<Esc>u'],
  ['change undo', 'one two', 'cwX<Esc>u'],
  ['block insert undo', 'abcd\nefgh', '<C-v>jlIX<Esc>u'],
  ['block change undo', 'abcd\nefgh', '<C-v>jlcX<Esc>u'],
  ['block insert skips short lines', 'abcd\nx\nijkl', '2l<C-v>jjIX<Esc>'],
  ['block append pads short lines', 'abcd\nx\nijkl', '2l<C-v>jjAX<Esc>'],
  ['block change short lines', 'abcd\nx\nijkl', '2l<C-v>jjcX<Esc>'],
  ['macro inserts native text', 'abc', 'qqiX<Esc>lq@q'],
  ['block insert into partial tab', 'abcd\n\txyz', 'l<C-v>jIX<Esc>', 'set ts=4'],

  ['native insert escape', 'abc', 'iXY<Esc>'],
  ['change word native text', 'one two', 'cwX<Esc>'],
  ['insert dot repeat', 'abc', 'iX<Esc>l.'],
  ['block insertion', 'abcd\nefgh', '<C-v>jlIX<Esc>'],
  ['block append', 'abcd\nefgh', '<C-v>jlAX<Esc>'],
  ['block change', 'abcd\nefgh', '<C-v>jlcX<Esc>'],

  ['block backwards delete', 'abcd\nefgh\nijkl', 'jl<C-v>khd'],
  ['block delete undo', 'abcd\nefgh\nijkl', '<C-v>jldu'],
  ['block yank paste', 'abcd\nefgh\nijkl', '<C-v>jlyjp'],
  ['block uppercase', 'abcd\nefgh\nijkl', '<C-v>jlU'],
  ['block replacement', 'abcd\nefgh\nijkl', '<C-v>jlrX'],
  ['block tab partial delete', 'abcd\n\txyz', 'l<C-v>jld', 'set ts=4'],
  ['block short row delete', 'abcd\nx\nijkl', '2l<C-v>jjld'],
  ['block delete EOF cursor', 'abcd\nefgh', '2l<C-v>jld'],
  ['block put past EOF', 'abcd\nefgh', '<C-v>jlyGp'],

  ['quote before punctuation', 'x = "value";', '6lda"'],

  ['quote prefers trailing spaces', 'a "bc"  d', '2lda"'],
  ['quote includes leading spaces without trailing', 'a  "bc"d', '3lda"'],
  ['inner quote preserves all whitespace', 'a  "bc"  d', '3ldi"'],

  ['delete dollar preserves next line', 'abc\ndef', 'ld$'],
  ['visual horizontal limit', 'abc\ndef', 'v9ld'],
  ['replace refuses short line', 'abc\ndef', 'l3rX'],
  ['replace at EOF refuses count', 'abc', 'l3rX'],
  ['visual line restore', 'one\ntwo\nthree', 'Vj<Esc>gggvd'],
  ['visual reverse restore', 'abcdef', '3lvhh<Esc>gvd'],
  ['visual bracket object', '(abc) xyz', 'lvi(d'],
  ['visual quote object', '"abc" xyz', 'lva"d'],
  ['backward till repeat', 'a.b.c.d', '$T.;'],
  ['counted till repeat', 'a.b.c.d', 't.2;'],
  ['visual line replace', 'abc\ndef\nghi', 'VjrX'],
  ['normal last char delete', 'abc\ndef', '$x'],
  ['normal paste character cursor', 'abc def', 'yiwwp'],

  ['visual kind switch', 'one\ntwo\nthree', 'vjVd'],
  ['visual swap ends', 'abcdef', 'lvlohd'],
  ['visual delete alias', 'abcdef', 'lvlx'],
  ['visual toggle case', 'aBcDef', 'lvl~'],
  ['delete column', 'abcdef', 'llx'],
  ['empty visual line', 'one\n\nthree', 'jVd'],
  ['cancel operator', 'abcdef', 'd<Esc>llx'],
  ['case preserves register', 'one\ntwo', 'yyjgUwp'],
  ['normal dollar', 'abc\ndef', '$'],
  ['left line boundary', 'abc\ndef', 'jh'],
  ['right line boundary', 'abc\ndef', '9l'],
  ['counted replace', 'abcdef', 'l3rX'],
  ['visual dollar delete', 'abc\ndef', 'v$d'],
  ['visual block delete', 'abcd\nefgh\nijkl', '<C-v>jld'],
  ['visual restore', 'abcdef', 'lvl<Esc>lgvd'],
  ['visual word object', 'alpha beta', 'viwd'],
  ['visual replace', 'abcdef', 'lvlrX'],
  ['visual paste', 'one two', 'yiwwvep'],
  ['word delete', 'one two three', 'dw'],
  ['counted line delete', 'one\ntwo\nthree', '2dd'],
  ['backward delete', 'abcdef', '3l2X'],
  ['explicit first line', 'one\ntwo\nthree', 'G1G'],
  ['find repeat', 'a.b.c', 'f.;'],
  ['till repeat', 'a.b.c', 't.;'],
];
const directory = mkdtempSync(join(tmpdir(), 'glot-vim-audit-'));
let failures = 0;
try {
  for (const [name, text, sequence, options = "", nativeFragments] of cases) {
    const output = join(directory, 'result.json');
    const script = join(directory, 'case.vim');
    // Separate Escape from the next search to avoid Vim's feedkeys treating
    // the concatenated bytes as a terminal key sequence.
    const fragments = nativeFragments ?? [sequence];
    const feedCommands = fragments.map(fragment => {
      const vimKeys = fragment.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replace(/<([^>]+)>/g, '\\<$1>');
      return `call feedkeys("${vimKeys}", "nxt")`;
    }).join('\n');
    writeFileSync(script, `set nocompatible\n${options}\ncall setline(1, ${JSON.stringify(text.split('\n'))})\nlet &undolevels = &undolevels\n${feedCommands}\ncall writefile([json_encode({"text": join(getline(1,"$"), "\\n"), "line": line("."), "column": col("."), "error": v:errmsg})], ${JSON.stringify(output)})\nqa!\n`);
    const result = spawnSync('vim', ['-Nu', 'NONE', '-n', '-es', '-S', script], { encoding: 'utf8' });
    if (!existsSync(output)) throw new Error(`Vim did not write a result (status ${result.status}): ${result.stderr}`);
    const expected = JSON.parse(readFileSync(output, 'utf8'));
    if (result.status !== 0) throw new Error(`Vim status ${result.status} for ${name}: ${expected.error}`);
    // ASCII fixtures: Vim byte columns equal UTF-16 columns here.
    const caret = expected.text.split('\n').slice(0, expected.line - 1).reduce((n, line) => n + line.length + 1, 0) + expected.column - 1;
    let editing = driver.with_bindings(text, bridge.BindingMode$VimLike());
    for (const token of sequence.match(/<[^>]+>|./g)) {
      if (option.Option$isSome(editing.model.prompt)) {
        const prompt = editing.model.prompt[0];
        if (token === '<CR>') editing = driver.send(editing, new message.PromptSubmitted());
        else if (token === '<Esc>') editing = driver.send(editing, new message.PromptCancelled());
        else if (token === '<BS>') editing = driver.send(editing, new message.PromptChanged(prompt.value.slice(0, -1)));
        else editing = driver.send(editing, new message.PromptChanged(prompt.value + (token === '<Space>' ? ' ' : token)));
        continue;
      }
      const named = { '<Esc>': 'Escape', '<BS>': 'Backspace', '<CR>': 'Enter', '<Tab>': 'Tab', '<Space>': ' ' };
      const key = token.startsWith('<C-') ? keys.ctrl(token.slice(3, -1)) : keys.plain(named[token] ?? token);
      const native = vim.accepts_native_input(editing.model.vim) && !token.startsWith('<');
      editing = driver.press(editing, key);
      if (native) {
        const current = model.active_session(editing.model);
        const from = Math.min(driver.anchor(editing), driver.caret(editing));
        const to = Math.max(driver.anchor(editing), driver.caret(editing));
        const before = driver.text_of(editing);
        const value = before.slice(0, from) + token + before.slice(to);
        const caret = from + token.length;
        editing = driver.send(editing, new message.InputReceived(new message.NativeInput(
          session.key_to_string(current.key), current.generation, value, caret, caret,
        )));
      }
    }
    const actual = { text: driver.text_of(editing), caret: driver.caret(editing) };
    const wanted = { text: expected.text, caret };
    const pass = JSON.stringify(actual) === JSON.stringify(wanted);
    if (!pass) failures++;
    console.log(`${pass ? 'PASS' : 'DIFF'} ${name}: ${sequence}`);
    if (!pass) console.log(`  Vim ${JSON.stringify(wanted)}\n  Glot ${JSON.stringify(actual)}`);
  }
} finally {
  rmSync(directory, { recursive: true, force: true });
}
console.log(`${cases.length - failures}/${cases.length} match Vim; ${failures} differences`);
process.exitCode = failures ? 1 : 0;
