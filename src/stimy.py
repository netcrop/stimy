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
        self.indent = '    '
        self.semicol = ';'
        self.lower = 'abcdefghijklmnopqrstuvwxyz'
        self.upper = 'abcdefghijklmnopqrstuvwxyz'.upper()
        self.digits = '0123456789'
        self.underscore = '_'
        self.identifier = list(self.lower + self.upper + self.digits + self.underscore)
        self.nl ='\n'
        self.insert = {}
        self.insertstr = {}
        self.insertstr[0] = self.nl + self.indent + 'stimy_pre()' + self.semicol 
        self.insertstr[1] = self.indent + 'stimy_post()' + self.semicol + self.nl  
        self.insertstr[2] = 'stimy_post('
        self.insertstr[3] = ');'
        self.parent = ()

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


    def default(self):
        if self.argc < 3: self.usage(self.args[1])
        if self.argc >= 2: self.sourcefile = self.args[2]
        self.fh = open(self.log,'a')
        # Build decision table for each content char. 
        for c in self.identifier:
            self.table[ord(c)] = self.fidentifier
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
        print('=======================')
        print(''.join(self.content))

    def finsert(self):
        insertlen = 0
        offset = 0
        for key,value in self.insert.items():
            insertlen = len(self.insertstr[value])
            for i in range(insertlen):
                self.content.insert(key+offset+i,self.insertstr[value][i:i+1])
            offset += insertlen

    # First condition to handle 
    def fsinglequote(self):
        if self.dquote or self.preprocessor:return
        if self.backslash: 
            self.backslash = 0
            return
        if self.squote:
            print('fsinglequote:end',file=self.fh)
            self.squote = 0
            return
        print('fsinglequote:start',file=self.fh)
        self.squote = 1

    def fdoublequote(self):
        if self.squote or self.preprocessor:return
        if self.backslash: 
            self.backslash = 0
            return
        if self.dquote:
           print('fdoublequote:end',file=self.fh)
           self.dquote = 0  
           return
        print('fdoublequote:start',file=self.fh)
        self.dquote = 1

    def fsharp(self):
        if self.dquote or self.squote or self.preprocessor:return
        print('fsharp:start preprocessor',file=self.fh)
        self.preprocessor = 1

    def fnl(self):
        if self.dquote or self.squote:return
        if self.preprocessor:
            print('fnl:end preprocessor',file=self.fh)
            self.preprocessor = 0
            return
        print('fnl:',file=self.fh)

    def fbackslash(self):
        if self.backslash: 
            print('fbackslash:end',file=self.fh)
            self.backslash = 0
            return
        # Next char
        match = re.search('[\'\"]',self.content[self.contenti+1])
        if match:
            print('fbackslash:start',file=self.fh)
            self.backslash = 1

    def flbrace(self):
        if self.dquote or self.squote or self.preprocessor:return
        # Increment Brace only inside function def
        if self.fdef:
            print('flbrace:start',file=self.fh)
            self.num_brace += 1
            return
        # Decremental check
        for i in range(self.contenti-1,0,-1): 
            match = re.search('\s',self.content[i])
            if match:continue
            if self.content[i].find(')') < 0:return
            break
        # Found function def
        print('flbrace:fdef start',file=self.fh)
        self.fdef = 1
        self.insert[self.contenti+1] = 0

    def frbrace(self):
        # Increment Brace only inside function def
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        if self.num_brace > 0:
            print('frbrace:end',file=self.fh)
            self.num_brace -= 1
            return
        print('frbrace:fdef end',file=self.fh)
        self.fdef = 0
        self.insert[self.contenti] = 1

    def fidentifier(self):
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        # Lookforward one char
        match = re.search('[a-zA-Z_0-9]',self.content[self.contenti + 1])
        if match:
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
            print(identifier,file=self.fh)
            return
        # One Char Identifier
        if self.content[self.contenti].isdigit():return
        self.idstarti = self.contenti
        self.idendi = self.contenti + 1
        print(''.join(self.content[self.idstarti:self.idendi]),file=self.fh)

    # Insert
    def freturn(self):
        for i in range(self.idendi,self.content_len):
            if self.content[i].find(';') < 0:continue
            insertposti = i + 1
            break
        self.insert[self.idstarti] = 2
        self.insert[insertposti] = 3
 
    def flparent(self):
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        print('flparent:start',file=self.fh)
        # Function def
        if self.num_brace < 1: return
        self.parent.append(self.contenti)

    def frparent(self):
        if self.dquote or self.squote or self.preprocessor or not self.fdef:return
        print('frparent:end',file=self.fh)
        return

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
