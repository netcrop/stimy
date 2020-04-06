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

Build install and run the application as usual.
> cd [project]
> make
> make install
> ./application
> stimy.restore.target [project~]
> cat /tmp/stimy0.txt
```
## Examples
```
# Here is a example run-time call-graph from the [dmenu] application.
# The entire call-graph is located inside github.com/netcrop/stimy/misc/dmenu.txt.

1     6        !setlocale (LC_CTYPE, "") || !XSupportsLocale ()
2     6        !(dpy = XOpenDisplay (NULL))
3     6        !embed || !(parentwin = strtol (embed, NULL, 0))
4     6        !XGetWindowAttributes (dpy, parentwin, &wa)
5     8          drw_create 0
6    10            ecalloc 0
7    10            !(p = calloc (nmemb, size))
8    10            ecalloc 1
12    8          drw_fontset_create 0
13    8          !drw || !fonts
14    8          (cur = xfont_create (drw, fonts[fontcount - i], NULL))
15   10            xfont_create 0
16   10            fontname
17   10            !(xfont = XftFontOpenName (drw->dpy, drw->screen,
```
## Releases

## Reporting a bug and security issues

github.com/netcrop/stimy/pulls

## License

[GNU General Public License version 2 (GPLv2)](https://raw.githubusercontent.com/netcrop/lwrap/beta/LICENSE)
