## stimy
Stimy is a run-time call-graph generator library. It can be used as a white-box (source code) testing tool to inspect the run time behaviour of any application build using C programming language.
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
# and insert C preprocessor macros inside each .[c,h] source file in the newly copied [project].
> stimy.target [project]

# Build install and run the application as usual.
> cd [project]
> make
> make install
> ./application
# Restore the original [project].
> stimy.restore.target [project~]
# Showing call-graph with squeezed consecutive and repetitive function call.
> stimy.squeeze /tmp/stimy0.txt
```
## Examples
```
# Here is a partial run-time call-graph from the [dmenu] application.
 0    6        main 0
 1    6        strcmp
27    6        setlocale
28    6        XSupportsLocale
29    6        XOpenDisplay
30    6        DefaultScreen
31    6        RootWindow
32    6        XGetWindowAttributes
33    6        drw_create
34    8          drw_create 0
35    8          ecalloc
36    8          sizeof
37   10            ecalloc 0
38   10            calloc
39   10            ecalloc 1
40    8          XCreatePixmap
41    8          DefaultDepth
42    8          XCreateGC
43    8          XSetLineAttributes
44    8          drw_create 1
```
## Releases

## Reporting a bug and security issues

github.com/netcrop/stimy/pulls

## License

[GNU General Public License version 2 (GPLv2)](https://raw.githubusercontent.com/netcrop/lwrap/beta/LICENSE)
