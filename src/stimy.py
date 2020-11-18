#!/bin/env -S PATH=/usr/local/bin:/usr/bin python3 -I
import re,tempfile,resource,glob,io,subprocess,sys
import os,socket,getpass,random,datetime
class Stimy:
    def __init__(self,*argv):
        self.message = {'-h':' print this help message.',
        '-t': ' test','-c': ' [source file]'}
        self.argv = argv
        self.args = argv[0]
        self.argc = len(self.args)
        if self.argc == 1: self.usage()
        self.option = { '-h':self.usage ,'-t':self.test,'-c':self.default }
        self.uid = os.getuid()
        self.username = getpass.getuser()
        self.homedir = os.environ.get('HOME') + '/'
        self.tmpdir = '/var/tmp/'
        self.debugging = DEBUGGING
        self.content = ''
        self.tablesize = 256
        self.table = {}
        self.contenti = -1
        self.pattern = {}        
        self.match = ''

    def default(self):
        if self.argc < 3: self.usage(self.args[1])
        if self.argc >= 2: self.sourcefile = self.args[2]
        # Build decision table for each content char. 
        for i in range(self.tablesize):
            self.table[i] = self.fnothing
        self.table[ord(' ')] = self.fspace 
        self.table[ord('\t')] = self.ftab 
        self.table[ord('\n')] = self.fnl 
        self.table[ord('#')] = self.fsharp 
        self.table[ord('/')] = self.fbackslash 
        self.table[ord('\\')] = self.fslash 
        self.table[ord('\'')] = self.fsinglequote 
        self.table[ord('\"')] = self.fdoublequote
        self.table[ord('(')] = self.flparent 
        self.table[ord(')')] = self.frparent
        self.table[ord('{')] = self.flbrace 
        self.table[ord('}')] = self.frbrace
        self.comments()

    def fnothing(self):
        return
    def fspace(self):
        return
    def ftab(self):
        return
    def fbackslash(self):
        return
    def fnl(self):
        return
    def fsharp(self):
        return
    def fslash(self):
        return
    def fsinglequote(self):
        return
    def fdoublequote(self):
        return
    def fundef(self):
        return
    def flbrace(self):
        return
    def frbrace(self):
        return
    def flparent(self):
        return
    def frparent(self):
        return

    def ftable(number,fname):
        self.table[number] = fname

    def comments(self):
        with open(self.sourcefile,'r') as fh:
            content = fh.read()
        ## Remove multiline to one line.
        content = re.sub(r'\\\n','',content)
        pattern = r"""
                            ##  --------- COMMENT ---------
           /\*              ##  Start of /* ... */ comment
           [^*]*\*+         ##  Non-* followed by 1-or-more *'s
           (                ##
             [^/*][^*]*\*+  ##
           )*               ##  0-or-more things which don't start with /
                            ##    but do end with '*'
           /                ##  End of /* ... */ comment
         |
            //[^\n\r]*      ##  // ... comment
         |                  ##  -OR-  various things which aren't comments:
           (                ## 
                            ##  ------ " ... " STRING ------
             "              ##  Start of " ... " string
             (              ##
               \\.          ##  Escaped char
             |              ##  -OR-
               [^"\\]       ##  Non "\ characters
             )*             ##
             "              ##  End of " ... " string
           |                ##  -OR-
                            ##
                            ##  ------ ' ... ' STRING ------
             '              ##  Start of ' ... ' string
             (              ##
               \\.          ##  Escaped char
             |              ##  -OR-
               [^'\\]       ##  Non '\ characters
             )*             ##
             '              ##  End of ' ... ' string
           |                ##  -OR-
                            ##  ------ ANYTHING ELSE -------
             .              ##  Anything other char
             [^/"'\\]*      ##  Chars which doesn't start a comment, string
           )                ##    or escape
        """
        regex = re.compile(pattern,re.VERBOSE|re.MULTILINE|re.DOTALL)
        for m in regex.finditer(content):
            if not m.group(2):continue
            self.content += m.group(2)
        self.content = re.sub(r'\s+\n','\n',self.content)
        self.content = re.sub(r'^\s*\n\s*','',self.content)
        print(self.content)

    def space(char):
        return ord(char)

    def test(self):
        with tempfile.NamedTemporaryFile(mode='w+',
        dir=self.tmpdir,delete=False) as self.testfh:
            self.testfh.write('big')
        proc = self.run(cmd='cat',stdout=subprocess.PIPE,infile=self.testfh.name)
        if proc != None:print(proc.stdout)
        proc = self.run(cmd='cat',stdout=subprocess.PIPE,infile='/etc/hostname')
        if proc != None:print(proc.stdout)
        self.run(cmd='date -u')

    def run(self, cmd='',infile='',outfile='',stdin=None,stdout=None,
        text=True,pass_fds=[],exit_errorcode='',shell=False):
        try:
            proc = None
            emit = __file__ + ':' + sys._getframe(1).f_code.co_name + ':' \
            + str(sys._getframe(1).f_lineno)
            if infile != '': stdin = open(infile,'r')
            if outfile != '': stdout = open(outfile,'w')
            proc = subprocess.run(cmd.split(),
            stdin=stdin,stdout=stdout,text=text,check=True,
            pass_fds=pass_fds,shell=shell)
            if infile != '': stdin.close() 
            if outfile != '': stdout.close()
            if not isinstance(proc,subprocess.CompletedProcess):
                self.debug(info='end 1',emit=emit)
                return None
            if isinstance(proc.stdout,str):
                proc.stdout = proc.stdout.rstrip('\n')
                self.debug(info='end 2',emit=emit)
                return proc
        except subprocess.CalledProcessError as e:
            emit += ':' + str(e.returncode)
            if exit_errorcode == '':
                if e.returncode != 0:
                    self.debug(info='end 3: ',emit=emit)
                    exit(1)
            elif e.returncode == exit_errorcode:
                self.debug(info='end 4',emit=emit)
                exit(1)
            return None

    def usage(self,option=1):
        if option in self.message:
            print(self.message[option].replace("@","\n    "))
        else:
            for key in self.message:
                print(key,self.message[key].replace("@","\n    "))
        exit(1)
    def debug(self,info='',outfile='',emit=''):
        if not self.debugging: return
        emit = sys._getframe(1).f_code.co_name + ':' \
        + str(sys._getframe(1).f_lineno) + ':' + info + ':' + emit
        print(emit)

if __name__ == '__main__':
    stimy = Stimy(sys.argv)
    if stimy.args[1] not in stimy.option: stimy.usage()
    try:
        stimy.option[stimy.args[1]]()
    except KeyboardInterrupt:
        stimy.debug(info='user ctrl-C')
    finally:
        stimy.debug(info='session finally end')
        for key,value in stimy.__dict__.items():
            if isinstance(value,io.TextIOWrapper):
                value.close()
                continue
            if isinstance(value,tempfile._TemporaryFileWrapper):
                value.close() 
                if os.access(value.name,os.R_OK): os.unlink(value.name)
        if stimy.debugging:
            with open('/tmp/stimylog','w') as stimy.logfh:
                print(stimy.__dict__,file=stimy.logfh)
