## stimy
Stimy is a run-time call-graph generator library for applications written in C programming language.
Stimy itself is written in C, Bash and Perl.
## Compile install and uninstall
* For linux/unix system:  
required header files:  
threads.h  
stdatomic.h  
stdio.h  
stdarg.h
stdlib.h
sys/stat.h
```
Some of the following commands use sudo for install/uninstall.
The install script will pick the latest Perl version from your system.
> cd stimy/
> source stimy.sh
> stimy.lib
> stimy.install
```
## Using stimy
```
# This command will backup the original [project] as [project~]
# and insert C preprocessor macros inside each C source file in the newly copied [project].
> stimy.target [project source dir]

# Build install and run the application as usual.
> cd [project]
> make
> make install
> ./application
# Restore the original [project].
> stimy.restore.target [project~]
# Show call-graph without consequtive repeatitive function call.
> stimy.fold /tmp/stimy0.txt
```
## Examples
```
# Here is a example run-time call-graph from the [dmenu] application.
# The entire call-graph is located inside github.com/netcrop/stimy/misc/dmenu.txt.
0    6        main 0
1    8          drw_create 0
2   10            ecalloc 0
3   10            ecalloc 1
4    8          drw_create 1
5    8          drw_fontset_create 0
6   10            xfont_create 0
7   12              ecalloc 0
8   12              ecalloc 1
9   10            xfont_create 1
10    8          drw_fontset_create 1
11    8          readstdin 0
12   10            drw_font_getexts 0
13   10            drw_font_getexts 1
62   10            drw_fontset_getwidth 0
63   10            drw_fontset_getwidth 1
64   10            drw_text 0
65   12              utf8decode 0
66   14                utf8decodebyte 0
67   14                utf8decodebyte 1
```
## Releases

## Reporting a bug and security issues

github.com/netcrop/stimy/pulls

## License

[GNU General Public License version 2 (GPLv2)](https://raw.githubusercontent.com/netcrop/lwrap/beta/LICENSE)
      
