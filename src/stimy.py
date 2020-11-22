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
        self.option = { '-h':self.usage ,'-t':self.test,'-c':self.fdefault }
        self.uid = os.getuid()
        self.username = getpass.getuser()
        self.homedir = os.environ.get('HOME') + '/'
        self.tmpdir = '/var/tmp/'
        self.debugging = DEBUGGING
        self.content = ''
        self.tablesize = 256
        self.table = {}
        self.contenti = -1
        self.content_len = 0
        self.dquote = 0
        self.squote = 0
        self.preprocessor = 0
        self.backslash = 0
        self.log = '/tmp/stimy.log'
        self.fh = ''
        self.num_brace = 0
        self.fdef = 0
        self.idprocess = False
        self.idstarti = 0
        self.idendi = 0
        self.whitespace = {' ':1,'\t':1,'\n':1,'\r':1,'\f':1,'\v':1}
        self.indent = '    '
        self.semicol = ';'
        self.lower = 'abcdefghijklmnopqrstuvwxyz'
        self.upper = 'abcdefghijklmnopqrstuvwxyz'.upper()
        self.digits = '0123456789'
        self.underscore = '_'
        self.nl ='\n'
        self.insert = {}
        self.insertstr = {}
        self.insertstr[0] = self.nl + self.indent + 'stimy_pre()' + self.semicol 
        self.insertstr[1] = self.indent + 'stimy_post()' + self.semicol + self.nl  
        self.insertstr[2] = 'stimy_post('
        self.insertstr[3] = ');'
        self.insertstr[4] = ' stimy_echo('
        self.insertstr[5] = '#ifndef STIMY_H\n#include <stimy.h>\n#endif\n' 
        self.insertstr[6] = ')'
        self.parent = []
        self.identifier = { 'a':1,'b':1,'c':1,'d':1,'e':1,'f':1,'g':1,'h':1,'i':1,'j':1,'k':1,'l':1,'m':1,'n':1,'o':1,'p':1,'q':1,'r':1,'s':1,'t':1,'u':1,'v':1,'w':1,'x':1,'y':1,'z':1,'A':1,'B':1,'C':1,'D':1,'E':1,'F':1,'G':1,'H':1,'I':1,'J':1,'K':1,'L':1,'M':1,'N':1,'O':1,'P':1,'Q':1,'R':1,'S':1,'T':1,'U':1,'V':1,'W':1,'X':1,'Y':1,'Z':1,'0':1,'1':1,'2':1,'3':1,'4':1,'5':1,'6':1,'7':1,'8':1,'9':1,'_':1}
        self.keyword = { 'error':1,'pragma':1,'operator':1,'elif':1,'line':1,'endif':1,'ifdef':1,'include':1,'undef':1,'defined':1,'auto':1,'char':1,'default':1,'else':1,'for':1,'inline':1,'return':1,'static':1,'union':1,'while':1,'_Bool':1,'_Complex':1,'restrict':1,'enum':1,'goto':1,'int':1,'short':1,'struct':1,'unsigned':1,'break':1,'const':1,'do':1,'extern':1,'if':1,'long':1,'signed':1,'switch':1,'void':1,'case':1,'continue':1,'double':1,'float':1,'_Imaginary':1,'register':1,'sizeof':1,'typeof':1,'typedef':1,'volatile':1}
    def comments(self):
        with open(self.sourcefile,'r') as fh:
            content = fh.read()
        ## Remove multiline to one line.
        content = re.sub(r"\\\n",'',content)
        pattern = r"""
          //[^\n\r]*     ##  // ... comment on the same line
         |
                            ##  --------- COMMENT ---------
           /\*              ##  Start of /* ... */ comment
           [^*]*\*+         ##  Non-* followed by 1-or-more *'s
           (?:              ##
             [^/*][^*]*\*+  ##
           )*               ##  0-or-more things which don't start with /
                            ##    but do end with '*'
           /                ##  End of /* ... */ comment
         |                  ##  -OR-  various things which aren't comments:
           (                ##  Group 1 start
                            ##  ------ " ... " STRING ------
             "              ##  Start of " ... " string
             (?:            ##
               \\.          ##  Escaped char
             |              ##  -OR-
               [^"\\]       ##  Non "\ characters
             )*             ##
             "              ##  End of " ... " string
           |                ##  -OR-
                            ##
                            ##  ------ ' ... ' STRING ------
             '              ##  Start of ' ... ' string
             (?:            ##
               \\.          ##  Escaped char
             |              ##  -OR-
               [^'\\]       ##  Non '\ characters
             )*             ##
             '              ##  End of ' ... ' string
           |                ##  -OR-
                            ##  ------ ANYTHING ELSE -------
             .              ##  Anything other char
             [^/"'\\]*      ##  Chars which doesn't start a comment, string or escape
           )                ##  Group 1 end  
        """
        regex = re.compile(pattern,re.VERBOSE|re.MULTILINE|re.DOTALL)
        for m in regex.finditer(content):
            if m.group(1):self.content += m.group(1)
        self.content = re.sub(r'\s*\n','\n',self.content)
        self.content = re.sub(r'^\s*\n\s*','',self.content,1)
        self.content = re.sub(r'\s*\n\s*$','',self.content,1)
        self.content = list(self.content)
        self.content_len = len(self.content)

    def fdefault(self):
        if self.argc < 3: self.usage(self.args[1])
        if self.argc >= 2: self.sourcefile = self.args[2]
        self.fh = open(self.log,'a')
        # Build decision table for each content char. 
        for i in self.identifier:
            self.table[ord(i)] = self.fidentifier
        self.table[ord(' ')] = self.fspace 
        self.table[ord('\t')] = self.ftab 
        self.table[ord('\n')] = self.fnl 
        self.table[ord('#')] = self.fsharp 
        self.table[ord('/')] = self.fslash 
        self.table[ord('\\')] = self.fbackslash 
        self.table[ord('\'')] = self.fsinglequote 
        self.table[ord('\"')] = self.fdoublequote
        self.table[ord('(')] = self.flparent 
        self.table[ord(')')] = self.frparent
        self.table[ord('{')] = self.flbrace 
        self.table[ord('}')] = self.frbrace
        for i in range(self.tablesize):
            if i not in self.table: self.table[i] = self.fnothing
        self.comments()
        while self.contenti < self.content_len: 
            self.table[ord(self.content[self.contenti])]()
            self.contenti += 1
        self.finsert()
        self.flog('=======================')
        print(self.insertstr[5] + ''.join(self.content))

       # First condition to handle 
    def fsinglequote(self):
        if self.dquote or self.preprocessor:return
        if self.backslash: 
            self.backslash = 0
            return
        if self.squote:
            self.flog('fsinglequote:end')
            self.squote = 0
            return
        self.flog('fsinglequote:start')
        self.squote = 1

    def fdoublequote(self):
        if self.squote or self.preprocessor:return
        if self.backslash: 
            self.backslash = 0
            return
        if self.dquote:
           self.flog('fdoublequote:end')
           self.dquote = 0  
           return
        self.flog('fdoublequote:start')
        self.dquote = 1

    def fsharp(self):
        if self.dquote or self.squote or self.preprocessor:return
        self.flog('fsharp:start preprocessor')
        self.preprocessor = 1

    def fnl(self):
        if self.dquote or self.squote:return
        if self.preprocessor:
            self.flog('fnl:end preprocessor')
            self.preprocessor = 0
            return
        self.flog('fnl:')

    def fbackslash(self):
        if self.backslash: 
            self.flog('fbackslash:end')
            self.backslash = 0
            return
        # Next char
        if '\'\"'.find(self.content[self.contenti+1]) < 0:return
        self.flog('fbackslash:start')
        self.backslash = 1

    def flbrace(self):
        if self.dquote or self.squote or self.preprocessor:return
        # Increment Brace only inside function def
        if self.fdef:
            self.flog('flbrace:start')
            self.num_brace += 1
            return
        # Decremental check
        for i in range(self.contenti-1,0,-1): 
            if self.content[i] in self.whitespace:continue
            if self.content[i].find(')') < 0:return
            break
        # Found function def
        self.flog('flbrace:fdef start')
        self.fdef = 1
        self.insert[self.contenti+1] = [0]

    def frbrace(self):
        # Increment Brace only inside function def
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        if self.num_brace > 0:
            self.flog('frbrace:end')
            self.num_brace -= 1
            return
        self.flog('frbrace:fdef end')
        self.fdef = 0
        self.insert[self.contenti] = [1]

    def fidentifier(self):
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        # Lookforward one char
        if self.content[self.contenti + 1] in self.identifier:
            if self.idprocess:return
            self.idstarti = self.contenti
            self.idprocess = True
            return
        if self.idprocess:
            self.idprocess = False
            # Multi char Identifier
            if self.content[self.idstarti].isdigit():return
            self.idendi = self.contenti + 1
            identifier = ''.join(self.content[self.idstarti:self.idendi])
            if identifier.find('return') >= 0:self.freturn()
            self.flog(identifier)
            return
        # One Char Identifier
        if self.content[self.contenti].isdigit():return
        self.idstarti = self.contenti
        self.idendi = self.contenti + 1
        self.flog(''.join(self.content[self.idstarti:self.idendi]))

    # Insert
    def freturn(self):
        for i in range(self.idendi,self.content_len):
            if self.content[i].find(';') < 0:continue
            insertposti = i + 1
            break
        self.insert[self.idstarti] = [2]
        self.insert[insertposti] = [3]
 
    def flparent(self):
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        self.flog('flparent:start')
        self.parent.append(self.contenti)

    def frparent(self):
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        self.flog('frparent:end1')
        lparenti = self.parent.pop()
        self.idprocess = False
        for i in range(lparenti-1,0,-1):
            if self.content[i] in self.whitespace:
                if not self.idprocess:continue
                self.idstarti = i
                self.idprocess = False
                break
            if self.content[i] not in self.identifier:return 
            if self.idprocess:continue
            self.idendi = i + 1
            self.idprocess = True

        word = ''.join(self.content[self.idstarti:self.idendi]).strip()
        if word in self.keyword:return
        # Insert Stimy_echo(X,Y) argument X
        self.insert[self.idstarti] = [4, word + ',']
        self.insert[self.contenti] = [6]
        self.flog('frparent:end2 ' + self.insertstr[4])

    def finsert(self):
        insertlen = 0
        offset = 0
        for key,value in self.insert.items():
            insertlen = len(self.insertstr[value[0]])
            for i in range(insertlen):
                self.content.insert(key+offset+i,self.insertstr[value[0]][i:i+1])
            offset += insertlen
            if len(value) < 2:continue
            # Insert Stimy_echo(X,Y) argument X
            insertlen = len(value[1])
            for i in range(insertlen):
                self.content.insert(key+offset+i,value[1][i:i+1])
            offset += insertlen

    def flog(self,info=''):
        if self.debugging:print(info,file=self.fh)

    def fnothing(self):
        return
    def fspace(self):
        return
    def ftab(self):
        return
    def fslash(self):
        return
    def fundef(self):
        return

    def ftable(number,fname):
        self.table[number] = fname
        
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
