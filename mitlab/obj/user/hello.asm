
obj/user/hello:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 2d 00 00 00       	call   80005e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 c0 0d 80 00       	push   $0x800dc0
  80003e:	e8 09 01 00 00       	call   80014c <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800043:	a1 04 20 80 00       	mov    0x802004,%eax
  800048:	8b 40 48             	mov    0x48(%eax),%eax
  80004b:	83 c4 08             	add    $0x8,%esp
  80004e:	50                   	push   %eax
  80004f:	68 ce 0d 80 00       	push   $0x800dce
  800054:	e8 f3 00 00 00       	call   80014c <cprintf>
}
  800059:	83 c4 10             	add    $0x10,%esp
  80005c:	c9                   	leave  
  80005d:	c3                   	ret    

0080005e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005e:	55                   	push   %ebp
  80005f:	89 e5                	mov    %esp,%ebp
  800061:	56                   	push   %esi
  800062:	53                   	push   %ebx
  800063:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800066:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
thisenv = &envs[ENVX(sys_getenvid())];
  800069:	e8 48 0a 00 00       	call   800ab6 <sys_getenvid>
  80006e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800073:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800076:	c1 e0 05             	shl    $0x5,%eax
  800079:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80007e:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800083:	85 db                	test   %ebx,%ebx
  800085:	7e 07                	jle    80008e <libmain+0x30>
		binaryname = argv[0];
  800087:	8b 06                	mov    (%esi),%eax
  800089:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80008e:	83 ec 08             	sub    $0x8,%esp
  800091:	56                   	push   %esi
  800092:	53                   	push   %ebx
  800093:	e8 9b ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800098:	e8 0a 00 00 00       	call   8000a7 <exit>
}
  80009d:	83 c4 10             	add    $0x10,%esp
  8000a0:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a3:	5b                   	pop    %ebx
  8000a4:	5e                   	pop    %esi
  8000a5:	5d                   	pop    %ebp
  8000a6:	c3                   	ret    

008000a7 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a7:	55                   	push   %ebp
  8000a8:	89 e5                	mov    %esp,%ebp
  8000aa:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000ad:	6a 00                	push   $0x0
  8000af:	e8 c1 09 00 00       	call   800a75 <sys_env_destroy>
}
  8000b4:	83 c4 10             	add    $0x10,%esp
  8000b7:	c9                   	leave  
  8000b8:	c3                   	ret    

008000b9 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000b9:	55                   	push   %ebp
  8000ba:	89 e5                	mov    %esp,%ebp
  8000bc:	53                   	push   %ebx
  8000bd:	83 ec 04             	sub    $0x4,%esp
  8000c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c3:	8b 13                	mov    (%ebx),%edx
  8000c5:	8d 42 01             	lea    0x1(%edx),%eax
  8000c8:	89 03                	mov    %eax,(%ebx)
  8000ca:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cd:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d1:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d6:	75 1a                	jne    8000f2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000d8:	83 ec 08             	sub    $0x8,%esp
  8000db:	68 ff 00 00 00       	push   $0xff
  8000e0:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e3:	50                   	push   %eax
  8000e4:	e8 4f 09 00 00       	call   800a38 <sys_cputs>
		b->idx = 0;
  8000e9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000ef:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000f9:	c9                   	leave  
  8000fa:	c3                   	ret    

008000fb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fb:	55                   	push   %ebp
  8000fc:	89 e5                	mov    %esp,%ebp
  8000fe:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800104:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010b:	00 00 00 
	b.cnt = 0;
  80010e:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800115:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800118:	ff 75 0c             	pushl  0xc(%ebp)
  80011b:	ff 75 08             	pushl  0x8(%ebp)
  80011e:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800124:	50                   	push   %eax
  800125:	68 b9 00 80 00       	push   $0x8000b9
  80012a:	e8 54 01 00 00       	call   800283 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012f:	83 c4 08             	add    $0x8,%esp
  800132:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800138:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013e:	50                   	push   %eax
  80013f:	e8 f4 08 00 00       	call   800a38 <sys_cputs>

	return b.cnt;
}
  800144:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014a:	c9                   	leave  
  80014b:	c3                   	ret    

0080014c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014c:	55                   	push   %ebp
  80014d:	89 e5                	mov    %esp,%ebp
  80014f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800152:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800155:	50                   	push   %eax
  800156:	ff 75 08             	pushl  0x8(%ebp)
  800159:	e8 9d ff ff ff       	call   8000fb <vcprintf>
	va_end(ap);

	return cnt;
}
  80015e:	c9                   	leave  
  80015f:	c3                   	ret    

00800160 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800160:	55                   	push   %ebp
  800161:	89 e5                	mov    %esp,%ebp
  800163:	57                   	push   %edi
  800164:	56                   	push   %esi
  800165:	53                   	push   %ebx
  800166:	83 ec 1c             	sub    $0x1c,%esp
  800169:	89 c7                	mov    %eax,%edi
  80016b:	89 d6                	mov    %edx,%esi
  80016d:	8b 45 08             	mov    0x8(%ebp),%eax
  800170:	8b 55 0c             	mov    0xc(%ebp),%edx
  800173:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800176:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800179:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800181:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800184:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800187:	39 d3                	cmp    %edx,%ebx
  800189:	72 05                	jb     800190 <printnum+0x30>
  80018b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80018e:	77 45                	ja     8001d5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800190:	83 ec 0c             	sub    $0xc,%esp
  800193:	ff 75 18             	pushl  0x18(%ebp)
  800196:	8b 45 14             	mov    0x14(%ebp),%eax
  800199:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019c:	53                   	push   %ebx
  80019d:	ff 75 10             	pushl  0x10(%ebp)
  8001a0:	83 ec 08             	sub    $0x8,%esp
  8001a3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001a9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ac:	ff 75 d8             	pushl  -0x28(%ebp)
  8001af:	e8 6c 09 00 00       	call   800b20 <__udivdi3>
  8001b4:	83 c4 18             	add    $0x18,%esp
  8001b7:	52                   	push   %edx
  8001b8:	50                   	push   %eax
  8001b9:	89 f2                	mov    %esi,%edx
  8001bb:	89 f8                	mov    %edi,%eax
  8001bd:	e8 9e ff ff ff       	call   800160 <printnum>
  8001c2:	83 c4 20             	add    $0x20,%esp
  8001c5:	eb 18                	jmp    8001df <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c7:	83 ec 08             	sub    $0x8,%esp
  8001ca:	56                   	push   %esi
  8001cb:	ff 75 18             	pushl  0x18(%ebp)
  8001ce:	ff d7                	call   *%edi
  8001d0:	83 c4 10             	add    $0x10,%esp
  8001d3:	eb 03                	jmp    8001d8 <printnum+0x78>
  8001d5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001d8:	83 eb 01             	sub    $0x1,%ebx
  8001db:	85 db                	test   %ebx,%ebx
  8001dd:	7f e8                	jg     8001c7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001df:	83 ec 08             	sub    $0x8,%esp
  8001e2:	56                   	push   %esi
  8001e3:	83 ec 04             	sub    $0x4,%esp
  8001e6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001e9:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ec:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ef:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f2:	e8 59 0a 00 00       	call   800c50 <__umoddi3>
  8001f7:	83 c4 14             	add    $0x14,%esp
  8001fa:	0f be 80 ef 0d 80 00 	movsbl 0x800def(%eax),%eax
  800201:	50                   	push   %eax
  800202:	ff d7                	call   *%edi
}
  800204:	83 c4 10             	add    $0x10,%esp
  800207:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80020a:	5b                   	pop    %ebx
  80020b:	5e                   	pop    %esi
  80020c:	5f                   	pop    %edi
  80020d:	5d                   	pop    %ebp
  80020e:	c3                   	ret    

0080020f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80020f:	55                   	push   %ebp
  800210:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800212:	83 fa 01             	cmp    $0x1,%edx
  800215:	7e 0e                	jle    800225 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800217:	8b 10                	mov    (%eax),%edx
  800219:	8d 4a 08             	lea    0x8(%edx),%ecx
  80021c:	89 08                	mov    %ecx,(%eax)
  80021e:	8b 02                	mov    (%edx),%eax
  800220:	8b 52 04             	mov    0x4(%edx),%edx
  800223:	eb 22                	jmp    800247 <getuint+0x38>
	else if (lflag)
  800225:	85 d2                	test   %edx,%edx
  800227:	74 10                	je     800239 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800229:	8b 10                	mov    (%eax),%edx
  80022b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022e:	89 08                	mov    %ecx,(%eax)
  800230:	8b 02                	mov    (%edx),%eax
  800232:	ba 00 00 00 00       	mov    $0x0,%edx
  800237:	eb 0e                	jmp    800247 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800239:	8b 10                	mov    (%eax),%edx
  80023b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80023e:	89 08                	mov    %ecx,(%eax)
  800240:	8b 02                	mov    (%edx),%eax
  800242:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800247:	5d                   	pop    %ebp
  800248:	c3                   	ret    

00800249 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800249:	55                   	push   %ebp
  80024a:	89 e5                	mov    %esp,%ebp
  80024c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80024f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800253:	8b 10                	mov    (%eax),%edx
  800255:	3b 50 04             	cmp    0x4(%eax),%edx
  800258:	73 0a                	jae    800264 <sprintputch+0x1b>
		*b->buf++ = ch;
  80025a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80025d:	89 08                	mov    %ecx,(%eax)
  80025f:	8b 45 08             	mov    0x8(%ebp),%eax
  800262:	88 02                	mov    %al,(%edx)
}
  800264:	5d                   	pop    %ebp
  800265:	c3                   	ret    

00800266 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800266:	55                   	push   %ebp
  800267:	89 e5                	mov    %esp,%ebp
  800269:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80026c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80026f:	50                   	push   %eax
  800270:	ff 75 10             	pushl  0x10(%ebp)
  800273:	ff 75 0c             	pushl  0xc(%ebp)
  800276:	ff 75 08             	pushl  0x8(%ebp)
  800279:	e8 05 00 00 00       	call   800283 <vprintfmt>
	va_end(ap);
}
  80027e:	83 c4 10             	add    $0x10,%esp
  800281:	c9                   	leave  
  800282:	c3                   	ret    

00800283 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800283:	55                   	push   %ebp
  800284:	89 e5                	mov    %esp,%ebp
  800286:	57                   	push   %edi
  800287:	56                   	push   %esi
  800288:	53                   	push   %ebx
  800289:	83 ec 2c             	sub    $0x2c,%esp
  80028c:	8b 75 08             	mov    0x8(%ebp),%esi
  80028f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800292:	8b 7d 10             	mov    0x10(%ebp),%edi
  800295:	eb 12                	jmp    8002a9 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800297:	85 c0                	test   %eax,%eax
  800299:	0f 84 a9 03 00 00    	je     800648 <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
  80029f:	83 ec 08             	sub    $0x8,%esp
  8002a2:	53                   	push   %ebx
  8002a3:	50                   	push   %eax
  8002a4:	ff d6                	call   *%esi
  8002a6:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002a9:	83 c7 01             	add    $0x1,%edi
  8002ac:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002b0:	83 f8 25             	cmp    $0x25,%eax
  8002b3:	75 e2                	jne    800297 <vprintfmt+0x14>
  8002b5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002b9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002c0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002c7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002ce:	ba 00 00 00 00       	mov    $0x0,%edx
  8002d3:	eb 07                	jmp    8002dc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002d8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002dc:	8d 47 01             	lea    0x1(%edi),%eax
  8002df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002e2:	0f b6 07             	movzbl (%edi),%eax
  8002e5:	0f b6 c8             	movzbl %al,%ecx
  8002e8:	83 e8 23             	sub    $0x23,%eax
  8002eb:	3c 55                	cmp    $0x55,%al
  8002ed:	0f 87 3a 03 00 00    	ja     80062d <vprintfmt+0x3aa>
  8002f3:	0f b6 c0             	movzbl %al,%eax
  8002f6:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8002fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800300:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800304:	eb d6                	jmp    8002dc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800306:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800309:	b8 00 00 00 00       	mov    $0x0,%eax
  80030e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800311:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800314:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800318:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80031b:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80031e:	83 fa 09             	cmp    $0x9,%edx
  800321:	77 39                	ja     80035c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800323:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800326:	eb e9                	jmp    800311 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800328:	8b 45 14             	mov    0x14(%ebp),%eax
  80032b:	8d 48 04             	lea    0x4(%eax),%ecx
  80032e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800331:	8b 00                	mov    (%eax),%eax
  800333:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800336:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800339:	eb 27                	jmp    800362 <vprintfmt+0xdf>
  80033b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80033e:	85 c0                	test   %eax,%eax
  800340:	b9 00 00 00 00       	mov    $0x0,%ecx
  800345:	0f 49 c8             	cmovns %eax,%ecx
  800348:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80034e:	eb 8c                	jmp    8002dc <vprintfmt+0x59>
  800350:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800353:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80035a:	eb 80                	jmp    8002dc <vprintfmt+0x59>
  80035c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80035f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800362:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800366:	0f 89 70 ff ff ff    	jns    8002dc <vprintfmt+0x59>
				width = precision, precision = -1;
  80036c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80036f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800372:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800379:	e9 5e ff ff ff       	jmp    8002dc <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80037e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800384:	e9 53 ff ff ff       	jmp    8002dc <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800389:	8b 45 14             	mov    0x14(%ebp),%eax
  80038c:	8d 50 04             	lea    0x4(%eax),%edx
  80038f:	89 55 14             	mov    %edx,0x14(%ebp)
  800392:	83 ec 08             	sub    $0x8,%esp
  800395:	53                   	push   %ebx
  800396:	ff 30                	pushl  (%eax)
  800398:	ff d6                	call   *%esi
			break;
  80039a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003a0:	e9 04 ff ff ff       	jmp    8002a9 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003a5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003a8:	8d 50 04             	lea    0x4(%eax),%edx
  8003ab:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ae:	8b 00                	mov    (%eax),%eax
  8003b0:	99                   	cltd   
  8003b1:	31 d0                	xor    %edx,%eax
  8003b3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003b5:	83 f8 07             	cmp    $0x7,%eax
  8003b8:	7f 0b                	jg     8003c5 <vprintfmt+0x142>
  8003ba:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  8003c1:	85 d2                	test   %edx,%edx
  8003c3:	75 18                	jne    8003dd <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003c5:	50                   	push   %eax
  8003c6:	68 07 0e 80 00       	push   $0x800e07
  8003cb:	53                   	push   %ebx
  8003cc:	56                   	push   %esi
  8003cd:	e8 94 fe ff ff       	call   800266 <printfmt>
  8003d2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003d8:	e9 cc fe ff ff       	jmp    8002a9 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003dd:	52                   	push   %edx
  8003de:	68 10 0e 80 00       	push   $0x800e10
  8003e3:	53                   	push   %ebx
  8003e4:	56                   	push   %esi
  8003e5:	e8 7c fe ff ff       	call   800266 <printfmt>
  8003ea:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003f0:	e9 b4 fe ff ff       	jmp    8002a9 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f8:	8d 50 04             	lea    0x4(%eax),%edx
  8003fb:	89 55 14             	mov    %edx,0x14(%ebp)
  8003fe:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800400:	85 ff                	test   %edi,%edi
  800402:	b8 00 0e 80 00       	mov    $0x800e00,%eax
  800407:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80040a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80040e:	0f 8e 94 00 00 00    	jle    8004a8 <vprintfmt+0x225>
  800414:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800418:	0f 84 98 00 00 00    	je     8004b6 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80041e:	83 ec 08             	sub    $0x8,%esp
  800421:	ff 75 d0             	pushl  -0x30(%ebp)
  800424:	57                   	push   %edi
  800425:	e8 a6 02 00 00       	call   8006d0 <strnlen>
  80042a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80042d:	29 c1                	sub    %eax,%ecx
  80042f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800432:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800435:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800439:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80043c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80043f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800441:	eb 0f                	jmp    800452 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800443:	83 ec 08             	sub    $0x8,%esp
  800446:	53                   	push   %ebx
  800447:	ff 75 e0             	pushl  -0x20(%ebp)
  80044a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80044c:	83 ef 01             	sub    $0x1,%edi
  80044f:	83 c4 10             	add    $0x10,%esp
  800452:	85 ff                	test   %edi,%edi
  800454:	7f ed                	jg     800443 <vprintfmt+0x1c0>
  800456:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800459:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80045c:	85 c9                	test   %ecx,%ecx
  80045e:	b8 00 00 00 00       	mov    $0x0,%eax
  800463:	0f 49 c1             	cmovns %ecx,%eax
  800466:	29 c1                	sub    %eax,%ecx
  800468:	89 75 08             	mov    %esi,0x8(%ebp)
  80046b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80046e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800471:	89 cb                	mov    %ecx,%ebx
  800473:	eb 4d                	jmp    8004c2 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800475:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800479:	74 1b                	je     800496 <vprintfmt+0x213>
  80047b:	0f be c0             	movsbl %al,%eax
  80047e:	83 e8 20             	sub    $0x20,%eax
  800481:	83 f8 5e             	cmp    $0x5e,%eax
  800484:	76 10                	jbe    800496 <vprintfmt+0x213>
					putch('?', putdat);
  800486:	83 ec 08             	sub    $0x8,%esp
  800489:	ff 75 0c             	pushl  0xc(%ebp)
  80048c:	6a 3f                	push   $0x3f
  80048e:	ff 55 08             	call   *0x8(%ebp)
  800491:	83 c4 10             	add    $0x10,%esp
  800494:	eb 0d                	jmp    8004a3 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800496:	83 ec 08             	sub    $0x8,%esp
  800499:	ff 75 0c             	pushl  0xc(%ebp)
  80049c:	52                   	push   %edx
  80049d:	ff 55 08             	call   *0x8(%ebp)
  8004a0:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004a3:	83 eb 01             	sub    $0x1,%ebx
  8004a6:	eb 1a                	jmp    8004c2 <vprintfmt+0x23f>
  8004a8:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ab:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ae:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004b1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004b4:	eb 0c                	jmp    8004c2 <vprintfmt+0x23f>
  8004b6:	89 75 08             	mov    %esi,0x8(%ebp)
  8004b9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004bc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004bf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004c2:	83 c7 01             	add    $0x1,%edi
  8004c5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004c9:	0f be d0             	movsbl %al,%edx
  8004cc:	85 d2                	test   %edx,%edx
  8004ce:	74 23                	je     8004f3 <vprintfmt+0x270>
  8004d0:	85 f6                	test   %esi,%esi
  8004d2:	78 a1                	js     800475 <vprintfmt+0x1f2>
  8004d4:	83 ee 01             	sub    $0x1,%esi
  8004d7:	79 9c                	jns    800475 <vprintfmt+0x1f2>
  8004d9:	89 df                	mov    %ebx,%edi
  8004db:	8b 75 08             	mov    0x8(%ebp),%esi
  8004de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004e1:	eb 18                	jmp    8004fb <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004e3:	83 ec 08             	sub    $0x8,%esp
  8004e6:	53                   	push   %ebx
  8004e7:	6a 20                	push   $0x20
  8004e9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004eb:	83 ef 01             	sub    $0x1,%edi
  8004ee:	83 c4 10             	add    $0x10,%esp
  8004f1:	eb 08                	jmp    8004fb <vprintfmt+0x278>
  8004f3:	89 df                	mov    %ebx,%edi
  8004f5:	8b 75 08             	mov    0x8(%ebp),%esi
  8004f8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004fb:	85 ff                	test   %edi,%edi
  8004fd:	7f e4                	jg     8004e3 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800502:	e9 a2 fd ff ff       	jmp    8002a9 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800507:	83 fa 01             	cmp    $0x1,%edx
  80050a:	7e 16                	jle    800522 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  80050c:	8b 45 14             	mov    0x14(%ebp),%eax
  80050f:	8d 50 08             	lea    0x8(%eax),%edx
  800512:	89 55 14             	mov    %edx,0x14(%ebp)
  800515:	8b 50 04             	mov    0x4(%eax),%edx
  800518:	8b 00                	mov    (%eax),%eax
  80051a:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80051d:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800520:	eb 32                	jmp    800554 <vprintfmt+0x2d1>
	else if (lflag)
  800522:	85 d2                	test   %edx,%edx
  800524:	74 18                	je     80053e <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800526:	8b 45 14             	mov    0x14(%ebp),%eax
  800529:	8d 50 04             	lea    0x4(%eax),%edx
  80052c:	89 55 14             	mov    %edx,0x14(%ebp)
  80052f:	8b 00                	mov    (%eax),%eax
  800531:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800534:	89 c1                	mov    %eax,%ecx
  800536:	c1 f9 1f             	sar    $0x1f,%ecx
  800539:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80053c:	eb 16                	jmp    800554 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80053e:	8b 45 14             	mov    0x14(%ebp),%eax
  800541:	8d 50 04             	lea    0x4(%eax),%edx
  800544:	89 55 14             	mov    %edx,0x14(%ebp)
  800547:	8b 00                	mov    (%eax),%eax
  800549:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80054c:	89 c1                	mov    %eax,%ecx
  80054e:	c1 f9 1f             	sar    $0x1f,%ecx
  800551:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800554:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800557:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80055a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80055f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800563:	0f 89 90 00 00 00    	jns    8005f9 <vprintfmt+0x376>
				putch('-', putdat);
  800569:	83 ec 08             	sub    $0x8,%esp
  80056c:	53                   	push   %ebx
  80056d:	6a 2d                	push   $0x2d
  80056f:	ff d6                	call   *%esi
				num = -(long long) num;
  800571:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800574:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800577:	f7 d8                	neg    %eax
  800579:	83 d2 00             	adc    $0x0,%edx
  80057c:	f7 da                	neg    %edx
  80057e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800581:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800586:	eb 71                	jmp    8005f9 <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800588:	8d 45 14             	lea    0x14(%ebp),%eax
  80058b:	e8 7f fc ff ff       	call   80020f <getuint>
			base = 10;
  800590:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800595:	eb 62                	jmp    8005f9 <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800597:	8d 45 14             	lea    0x14(%ebp),%eax
  80059a:	e8 70 fc ff ff       	call   80020f <getuint>
                        base = 8;
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
  80059f:	83 ec 0c             	sub    $0xc,%esp
  8005a2:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
  8005a6:	51                   	push   %ecx
  8005a7:	ff 75 e0             	pushl  -0x20(%ebp)
  8005aa:	6a 08                	push   $0x8
  8005ac:	52                   	push   %edx
  8005ad:	50                   	push   %eax
  8005ae:	89 da                	mov    %ebx,%edx
  8005b0:	89 f0                	mov    %esi,%eax
  8005b2:	e8 a9 fb ff ff       	call   800160 <printnum>
                        break;
  8005b7:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
                        break;
  8005bd:	e9 e7 fc ff ff       	jmp    8002a9 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005c2:	83 ec 08             	sub    $0x8,%esp
  8005c5:	53                   	push   %ebx
  8005c6:	6a 30                	push   $0x30
  8005c8:	ff d6                	call   *%esi
			putch('x', putdat);
  8005ca:	83 c4 08             	add    $0x8,%esp
  8005cd:	53                   	push   %ebx
  8005ce:	6a 78                	push   $0x78
  8005d0:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005d2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d5:	8d 50 04             	lea    0x4(%eax),%edx
  8005d8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005db:	8b 00                	mov    (%eax),%eax
  8005dd:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005e2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005e5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005ea:	eb 0d                	jmp    8005f9 <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005ec:	8d 45 14             	lea    0x14(%ebp),%eax
  8005ef:	e8 1b fc ff ff       	call   80020f <getuint>
			base = 16;
  8005f4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005f9:	83 ec 0c             	sub    $0xc,%esp
  8005fc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800600:	57                   	push   %edi
  800601:	ff 75 e0             	pushl  -0x20(%ebp)
  800604:	51                   	push   %ecx
  800605:	52                   	push   %edx
  800606:	50                   	push   %eax
  800607:	89 da                	mov    %ebx,%edx
  800609:	89 f0                	mov    %esi,%eax
  80060b:	e8 50 fb ff ff       	call   800160 <printnum>
			break;
  800610:	83 c4 20             	add    $0x20,%esp
  800613:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800616:	e9 8e fc ff ff       	jmp    8002a9 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80061b:	83 ec 08             	sub    $0x8,%esp
  80061e:	53                   	push   %ebx
  80061f:	51                   	push   %ecx
  800620:	ff d6                	call   *%esi
			break;
  800622:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800625:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800628:	e9 7c fc ff ff       	jmp    8002a9 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80062d:	83 ec 08             	sub    $0x8,%esp
  800630:	53                   	push   %ebx
  800631:	6a 25                	push   $0x25
  800633:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800635:	83 c4 10             	add    $0x10,%esp
  800638:	eb 03                	jmp    80063d <vprintfmt+0x3ba>
  80063a:	83 ef 01             	sub    $0x1,%edi
  80063d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800641:	75 f7                	jne    80063a <vprintfmt+0x3b7>
  800643:	e9 61 fc ff ff       	jmp    8002a9 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800648:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80064b:	5b                   	pop    %ebx
  80064c:	5e                   	pop    %esi
  80064d:	5f                   	pop    %edi
  80064e:	5d                   	pop    %ebp
  80064f:	c3                   	ret    

00800650 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800650:	55                   	push   %ebp
  800651:	89 e5                	mov    %esp,%ebp
  800653:	83 ec 18             	sub    $0x18,%esp
  800656:	8b 45 08             	mov    0x8(%ebp),%eax
  800659:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80065c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80065f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800663:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800666:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80066d:	85 c0                	test   %eax,%eax
  80066f:	74 26                	je     800697 <vsnprintf+0x47>
  800671:	85 d2                	test   %edx,%edx
  800673:	7e 22                	jle    800697 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800675:	ff 75 14             	pushl  0x14(%ebp)
  800678:	ff 75 10             	pushl  0x10(%ebp)
  80067b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80067e:	50                   	push   %eax
  80067f:	68 49 02 80 00       	push   $0x800249
  800684:	e8 fa fb ff ff       	call   800283 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800689:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80068c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80068f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800692:	83 c4 10             	add    $0x10,%esp
  800695:	eb 05                	jmp    80069c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800697:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80069c:	c9                   	leave  
  80069d:	c3                   	ret    

0080069e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80069e:	55                   	push   %ebp
  80069f:	89 e5                	mov    %esp,%ebp
  8006a1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006a4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006a7:	50                   	push   %eax
  8006a8:	ff 75 10             	pushl  0x10(%ebp)
  8006ab:	ff 75 0c             	pushl  0xc(%ebp)
  8006ae:	ff 75 08             	pushl  0x8(%ebp)
  8006b1:	e8 9a ff ff ff       	call   800650 <vsnprintf>
	va_end(ap);

	return rc;
}
  8006b6:	c9                   	leave  
  8006b7:	c3                   	ret    

008006b8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8006b8:	55                   	push   %ebp
  8006b9:	89 e5                	mov    %esp,%ebp
  8006bb:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8006be:	b8 00 00 00 00       	mov    $0x0,%eax
  8006c3:	eb 03                	jmp    8006c8 <strlen+0x10>
		n++;
  8006c5:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8006c8:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8006cc:	75 f7                	jne    8006c5 <strlen+0xd>
		n++;
	return n;
}
  8006ce:	5d                   	pop    %ebp
  8006cf:	c3                   	ret    

008006d0 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8006d0:	55                   	push   %ebp
  8006d1:	89 e5                	mov    %esp,%ebp
  8006d3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006d6:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006d9:	ba 00 00 00 00       	mov    $0x0,%edx
  8006de:	eb 03                	jmp    8006e3 <strnlen+0x13>
		n++;
  8006e0:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006e3:	39 c2                	cmp    %eax,%edx
  8006e5:	74 08                	je     8006ef <strnlen+0x1f>
  8006e7:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006eb:	75 f3                	jne    8006e0 <strnlen+0x10>
  8006ed:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006ef:	5d                   	pop    %ebp
  8006f0:	c3                   	ret    

008006f1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006f1:	55                   	push   %ebp
  8006f2:	89 e5                	mov    %esp,%ebp
  8006f4:	53                   	push   %ebx
  8006f5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006fb:	89 c2                	mov    %eax,%edx
  8006fd:	83 c2 01             	add    $0x1,%edx
  800700:	83 c1 01             	add    $0x1,%ecx
  800703:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800707:	88 5a ff             	mov    %bl,-0x1(%edx)
  80070a:	84 db                	test   %bl,%bl
  80070c:	75 ef                	jne    8006fd <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80070e:	5b                   	pop    %ebx
  80070f:	5d                   	pop    %ebp
  800710:	c3                   	ret    

00800711 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800711:	55                   	push   %ebp
  800712:	89 e5                	mov    %esp,%ebp
  800714:	53                   	push   %ebx
  800715:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800718:	53                   	push   %ebx
  800719:	e8 9a ff ff ff       	call   8006b8 <strlen>
  80071e:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800721:	ff 75 0c             	pushl  0xc(%ebp)
  800724:	01 d8                	add    %ebx,%eax
  800726:	50                   	push   %eax
  800727:	e8 c5 ff ff ff       	call   8006f1 <strcpy>
	return dst;
}
  80072c:	89 d8                	mov    %ebx,%eax
  80072e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800731:	c9                   	leave  
  800732:	c3                   	ret    

00800733 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800733:	55                   	push   %ebp
  800734:	89 e5                	mov    %esp,%ebp
  800736:	56                   	push   %esi
  800737:	53                   	push   %ebx
  800738:	8b 75 08             	mov    0x8(%ebp),%esi
  80073b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80073e:	89 f3                	mov    %esi,%ebx
  800740:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800743:	89 f2                	mov    %esi,%edx
  800745:	eb 0f                	jmp    800756 <strncpy+0x23>
		*dst++ = *src;
  800747:	83 c2 01             	add    $0x1,%edx
  80074a:	0f b6 01             	movzbl (%ecx),%eax
  80074d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800750:	80 39 01             	cmpb   $0x1,(%ecx)
  800753:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800756:	39 da                	cmp    %ebx,%edx
  800758:	75 ed                	jne    800747 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80075a:	89 f0                	mov    %esi,%eax
  80075c:	5b                   	pop    %ebx
  80075d:	5e                   	pop    %esi
  80075e:	5d                   	pop    %ebp
  80075f:	c3                   	ret    

00800760 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800760:	55                   	push   %ebp
  800761:	89 e5                	mov    %esp,%ebp
  800763:	56                   	push   %esi
  800764:	53                   	push   %ebx
  800765:	8b 75 08             	mov    0x8(%ebp),%esi
  800768:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80076b:	8b 55 10             	mov    0x10(%ebp),%edx
  80076e:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800770:	85 d2                	test   %edx,%edx
  800772:	74 21                	je     800795 <strlcpy+0x35>
  800774:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800778:	89 f2                	mov    %esi,%edx
  80077a:	eb 09                	jmp    800785 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80077c:	83 c2 01             	add    $0x1,%edx
  80077f:	83 c1 01             	add    $0x1,%ecx
  800782:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800785:	39 c2                	cmp    %eax,%edx
  800787:	74 09                	je     800792 <strlcpy+0x32>
  800789:	0f b6 19             	movzbl (%ecx),%ebx
  80078c:	84 db                	test   %bl,%bl
  80078e:	75 ec                	jne    80077c <strlcpy+0x1c>
  800790:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800792:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800795:	29 f0                	sub    %esi,%eax
}
  800797:	5b                   	pop    %ebx
  800798:	5e                   	pop    %esi
  800799:	5d                   	pop    %ebp
  80079a:	c3                   	ret    

0080079b <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80079b:	55                   	push   %ebp
  80079c:	89 e5                	mov    %esp,%ebp
  80079e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007a1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8007a4:	eb 06                	jmp    8007ac <strcmp+0x11>
		p++, q++;
  8007a6:	83 c1 01             	add    $0x1,%ecx
  8007a9:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8007ac:	0f b6 01             	movzbl (%ecx),%eax
  8007af:	84 c0                	test   %al,%al
  8007b1:	74 04                	je     8007b7 <strcmp+0x1c>
  8007b3:	3a 02                	cmp    (%edx),%al
  8007b5:	74 ef                	je     8007a6 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8007b7:	0f b6 c0             	movzbl %al,%eax
  8007ba:	0f b6 12             	movzbl (%edx),%edx
  8007bd:	29 d0                	sub    %edx,%eax
}
  8007bf:	5d                   	pop    %ebp
  8007c0:	c3                   	ret    

008007c1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8007c1:	55                   	push   %ebp
  8007c2:	89 e5                	mov    %esp,%ebp
  8007c4:	53                   	push   %ebx
  8007c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007cb:	89 c3                	mov    %eax,%ebx
  8007cd:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8007d0:	eb 06                	jmp    8007d8 <strncmp+0x17>
		n--, p++, q++;
  8007d2:	83 c0 01             	add    $0x1,%eax
  8007d5:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007d8:	39 d8                	cmp    %ebx,%eax
  8007da:	74 15                	je     8007f1 <strncmp+0x30>
  8007dc:	0f b6 08             	movzbl (%eax),%ecx
  8007df:	84 c9                	test   %cl,%cl
  8007e1:	74 04                	je     8007e7 <strncmp+0x26>
  8007e3:	3a 0a                	cmp    (%edx),%cl
  8007e5:	74 eb                	je     8007d2 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007e7:	0f b6 00             	movzbl (%eax),%eax
  8007ea:	0f b6 12             	movzbl (%edx),%edx
  8007ed:	29 d0                	sub    %edx,%eax
  8007ef:	eb 05                	jmp    8007f6 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007f1:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007f6:	5b                   	pop    %ebx
  8007f7:	5d                   	pop    %ebp
  8007f8:	c3                   	ret    

008007f9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007f9:	55                   	push   %ebp
  8007fa:	89 e5                	mov    %esp,%ebp
  8007fc:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ff:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800803:	eb 07                	jmp    80080c <strchr+0x13>
		if (*s == c)
  800805:	38 ca                	cmp    %cl,%dl
  800807:	74 0f                	je     800818 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800809:	83 c0 01             	add    $0x1,%eax
  80080c:	0f b6 10             	movzbl (%eax),%edx
  80080f:	84 d2                	test   %dl,%dl
  800811:	75 f2                	jne    800805 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800813:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800818:	5d                   	pop    %ebp
  800819:	c3                   	ret    

0080081a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80081a:	55                   	push   %ebp
  80081b:	89 e5                	mov    %esp,%ebp
  80081d:	8b 45 08             	mov    0x8(%ebp),%eax
  800820:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800824:	eb 03                	jmp    800829 <strfind+0xf>
  800826:	83 c0 01             	add    $0x1,%eax
  800829:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80082c:	38 ca                	cmp    %cl,%dl
  80082e:	74 04                	je     800834 <strfind+0x1a>
  800830:	84 d2                	test   %dl,%dl
  800832:	75 f2                	jne    800826 <strfind+0xc>
			break;
	return (char *) s;
}
  800834:	5d                   	pop    %ebp
  800835:	c3                   	ret    

00800836 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800836:	55                   	push   %ebp
  800837:	89 e5                	mov    %esp,%ebp
  800839:	57                   	push   %edi
  80083a:	56                   	push   %esi
  80083b:	53                   	push   %ebx
  80083c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80083f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800842:	85 c9                	test   %ecx,%ecx
  800844:	74 36                	je     80087c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800846:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80084c:	75 28                	jne    800876 <memset+0x40>
  80084e:	f6 c1 03             	test   $0x3,%cl
  800851:	75 23                	jne    800876 <memset+0x40>
		c &= 0xFF;
  800853:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800857:	89 d3                	mov    %edx,%ebx
  800859:	c1 e3 08             	shl    $0x8,%ebx
  80085c:	89 d6                	mov    %edx,%esi
  80085e:	c1 e6 18             	shl    $0x18,%esi
  800861:	89 d0                	mov    %edx,%eax
  800863:	c1 e0 10             	shl    $0x10,%eax
  800866:	09 f0                	or     %esi,%eax
  800868:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80086a:	89 d8                	mov    %ebx,%eax
  80086c:	09 d0                	or     %edx,%eax
  80086e:	c1 e9 02             	shr    $0x2,%ecx
  800871:	fc                   	cld    
  800872:	f3 ab                	rep stos %eax,%es:(%edi)
  800874:	eb 06                	jmp    80087c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800876:	8b 45 0c             	mov    0xc(%ebp),%eax
  800879:	fc                   	cld    
  80087a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80087c:	89 f8                	mov    %edi,%eax
  80087e:	5b                   	pop    %ebx
  80087f:	5e                   	pop    %esi
  800880:	5f                   	pop    %edi
  800881:	5d                   	pop    %ebp
  800882:	c3                   	ret    

00800883 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800883:	55                   	push   %ebp
  800884:	89 e5                	mov    %esp,%ebp
  800886:	57                   	push   %edi
  800887:	56                   	push   %esi
  800888:	8b 45 08             	mov    0x8(%ebp),%eax
  80088b:	8b 75 0c             	mov    0xc(%ebp),%esi
  80088e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800891:	39 c6                	cmp    %eax,%esi
  800893:	73 35                	jae    8008ca <memmove+0x47>
  800895:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800898:	39 d0                	cmp    %edx,%eax
  80089a:	73 2e                	jae    8008ca <memmove+0x47>
		s += n;
		d += n;
  80089c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80089f:	89 d6                	mov    %edx,%esi
  8008a1:	09 fe                	or     %edi,%esi
  8008a3:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8008a9:	75 13                	jne    8008be <memmove+0x3b>
  8008ab:	f6 c1 03             	test   $0x3,%cl
  8008ae:	75 0e                	jne    8008be <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8008b0:	83 ef 04             	sub    $0x4,%edi
  8008b3:	8d 72 fc             	lea    -0x4(%edx),%esi
  8008b6:	c1 e9 02             	shr    $0x2,%ecx
  8008b9:	fd                   	std    
  8008ba:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008bc:	eb 09                	jmp    8008c7 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8008be:	83 ef 01             	sub    $0x1,%edi
  8008c1:	8d 72 ff             	lea    -0x1(%edx),%esi
  8008c4:	fd                   	std    
  8008c5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8008c7:	fc                   	cld    
  8008c8:	eb 1d                	jmp    8008e7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008ca:	89 f2                	mov    %esi,%edx
  8008cc:	09 c2                	or     %eax,%edx
  8008ce:	f6 c2 03             	test   $0x3,%dl
  8008d1:	75 0f                	jne    8008e2 <memmove+0x5f>
  8008d3:	f6 c1 03             	test   $0x3,%cl
  8008d6:	75 0a                	jne    8008e2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008d8:	c1 e9 02             	shr    $0x2,%ecx
  8008db:	89 c7                	mov    %eax,%edi
  8008dd:	fc                   	cld    
  8008de:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008e0:	eb 05                	jmp    8008e7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008e2:	89 c7                	mov    %eax,%edi
  8008e4:	fc                   	cld    
  8008e5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008e7:	5e                   	pop    %esi
  8008e8:	5f                   	pop    %edi
  8008e9:	5d                   	pop    %ebp
  8008ea:	c3                   	ret    

008008eb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008eb:	55                   	push   %ebp
  8008ec:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008ee:	ff 75 10             	pushl  0x10(%ebp)
  8008f1:	ff 75 0c             	pushl  0xc(%ebp)
  8008f4:	ff 75 08             	pushl  0x8(%ebp)
  8008f7:	e8 87 ff ff ff       	call   800883 <memmove>
}
  8008fc:	c9                   	leave  
  8008fd:	c3                   	ret    

008008fe <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008fe:	55                   	push   %ebp
  8008ff:	89 e5                	mov    %esp,%ebp
  800901:	56                   	push   %esi
  800902:	53                   	push   %ebx
  800903:	8b 45 08             	mov    0x8(%ebp),%eax
  800906:	8b 55 0c             	mov    0xc(%ebp),%edx
  800909:	89 c6                	mov    %eax,%esi
  80090b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80090e:	eb 1a                	jmp    80092a <memcmp+0x2c>
		if (*s1 != *s2)
  800910:	0f b6 08             	movzbl (%eax),%ecx
  800913:	0f b6 1a             	movzbl (%edx),%ebx
  800916:	38 d9                	cmp    %bl,%cl
  800918:	74 0a                	je     800924 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80091a:	0f b6 c1             	movzbl %cl,%eax
  80091d:	0f b6 db             	movzbl %bl,%ebx
  800920:	29 d8                	sub    %ebx,%eax
  800922:	eb 0f                	jmp    800933 <memcmp+0x35>
		s1++, s2++;
  800924:	83 c0 01             	add    $0x1,%eax
  800927:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80092a:	39 f0                	cmp    %esi,%eax
  80092c:	75 e2                	jne    800910 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80092e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800933:	5b                   	pop    %ebx
  800934:	5e                   	pop    %esi
  800935:	5d                   	pop    %ebp
  800936:	c3                   	ret    

00800937 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800937:	55                   	push   %ebp
  800938:	89 e5                	mov    %esp,%ebp
  80093a:	53                   	push   %ebx
  80093b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80093e:	89 c1                	mov    %eax,%ecx
  800940:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800943:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800947:	eb 0a                	jmp    800953 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800949:	0f b6 10             	movzbl (%eax),%edx
  80094c:	39 da                	cmp    %ebx,%edx
  80094e:	74 07                	je     800957 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800950:	83 c0 01             	add    $0x1,%eax
  800953:	39 c8                	cmp    %ecx,%eax
  800955:	72 f2                	jb     800949 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800957:	5b                   	pop    %ebx
  800958:	5d                   	pop    %ebp
  800959:	c3                   	ret    

0080095a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  80095a:	55                   	push   %ebp
  80095b:	89 e5                	mov    %esp,%ebp
  80095d:	57                   	push   %edi
  80095e:	56                   	push   %esi
  80095f:	53                   	push   %ebx
  800960:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800963:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800966:	eb 03                	jmp    80096b <strtol+0x11>
		s++;
  800968:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80096b:	0f b6 01             	movzbl (%ecx),%eax
  80096e:	3c 20                	cmp    $0x20,%al
  800970:	74 f6                	je     800968 <strtol+0xe>
  800972:	3c 09                	cmp    $0x9,%al
  800974:	74 f2                	je     800968 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800976:	3c 2b                	cmp    $0x2b,%al
  800978:	75 0a                	jne    800984 <strtol+0x2a>
		s++;
  80097a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80097d:	bf 00 00 00 00       	mov    $0x0,%edi
  800982:	eb 11                	jmp    800995 <strtol+0x3b>
  800984:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800989:	3c 2d                	cmp    $0x2d,%al
  80098b:	75 08                	jne    800995 <strtol+0x3b>
		s++, neg = 1;
  80098d:	83 c1 01             	add    $0x1,%ecx
  800990:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800995:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  80099b:	75 15                	jne    8009b2 <strtol+0x58>
  80099d:	80 39 30             	cmpb   $0x30,(%ecx)
  8009a0:	75 10                	jne    8009b2 <strtol+0x58>
  8009a2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  8009a6:	75 7c                	jne    800a24 <strtol+0xca>
		s += 2, base = 16;
  8009a8:	83 c1 02             	add    $0x2,%ecx
  8009ab:	bb 10 00 00 00       	mov    $0x10,%ebx
  8009b0:	eb 16                	jmp    8009c8 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  8009b2:	85 db                	test   %ebx,%ebx
  8009b4:	75 12                	jne    8009c8 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  8009b6:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009bb:	80 39 30             	cmpb   $0x30,(%ecx)
  8009be:	75 08                	jne    8009c8 <strtol+0x6e>
		s++, base = 8;
  8009c0:	83 c1 01             	add    $0x1,%ecx
  8009c3:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  8009c8:	b8 00 00 00 00       	mov    $0x0,%eax
  8009cd:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  8009d0:	0f b6 11             	movzbl (%ecx),%edx
  8009d3:	8d 72 d0             	lea    -0x30(%edx),%esi
  8009d6:	89 f3                	mov    %esi,%ebx
  8009d8:	80 fb 09             	cmp    $0x9,%bl
  8009db:	77 08                	ja     8009e5 <strtol+0x8b>
			dig = *s - '0';
  8009dd:	0f be d2             	movsbl %dl,%edx
  8009e0:	83 ea 30             	sub    $0x30,%edx
  8009e3:	eb 22                	jmp    800a07 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009e5:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009e8:	89 f3                	mov    %esi,%ebx
  8009ea:	80 fb 19             	cmp    $0x19,%bl
  8009ed:	77 08                	ja     8009f7 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009ef:	0f be d2             	movsbl %dl,%edx
  8009f2:	83 ea 57             	sub    $0x57,%edx
  8009f5:	eb 10                	jmp    800a07 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009f7:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009fa:	89 f3                	mov    %esi,%ebx
  8009fc:	80 fb 19             	cmp    $0x19,%bl
  8009ff:	77 16                	ja     800a17 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a01:	0f be d2             	movsbl %dl,%edx
  800a04:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a07:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a0a:	7d 0b                	jge    800a17 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a0c:	83 c1 01             	add    $0x1,%ecx
  800a0f:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a13:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a15:	eb b9                	jmp    8009d0 <strtol+0x76>

	if (endptr)
  800a17:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a1b:	74 0d                	je     800a2a <strtol+0xd0>
		*endptr = (char *) s;
  800a1d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a20:	89 0e                	mov    %ecx,(%esi)
  800a22:	eb 06                	jmp    800a2a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a24:	85 db                	test   %ebx,%ebx
  800a26:	74 98                	je     8009c0 <strtol+0x66>
  800a28:	eb 9e                	jmp    8009c8 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a2a:	89 c2                	mov    %eax,%edx
  800a2c:	f7 da                	neg    %edx
  800a2e:	85 ff                	test   %edi,%edi
  800a30:	0f 45 c2             	cmovne %edx,%eax
}
  800a33:	5b                   	pop    %ebx
  800a34:	5e                   	pop    %esi
  800a35:	5f                   	pop    %edi
  800a36:	5d                   	pop    %ebp
  800a37:	c3                   	ret    

00800a38 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a38:	55                   	push   %ebp
  800a39:	89 e5                	mov    %esp,%ebp
  800a3b:	57                   	push   %edi
  800a3c:	56                   	push   %esi
  800a3d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a3e:	b8 00 00 00 00       	mov    $0x0,%eax
  800a43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a46:	8b 55 08             	mov    0x8(%ebp),%edx
  800a49:	89 c3                	mov    %eax,%ebx
  800a4b:	89 c7                	mov    %eax,%edi
  800a4d:	89 c6                	mov    %eax,%esi
  800a4f:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a51:	5b                   	pop    %ebx
  800a52:	5e                   	pop    %esi
  800a53:	5f                   	pop    %edi
  800a54:	5d                   	pop    %ebp
  800a55:	c3                   	ret    

00800a56 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a56:	55                   	push   %ebp
  800a57:	89 e5                	mov    %esp,%ebp
  800a59:	57                   	push   %edi
  800a5a:	56                   	push   %esi
  800a5b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a5c:	ba 00 00 00 00       	mov    $0x0,%edx
  800a61:	b8 01 00 00 00       	mov    $0x1,%eax
  800a66:	89 d1                	mov    %edx,%ecx
  800a68:	89 d3                	mov    %edx,%ebx
  800a6a:	89 d7                	mov    %edx,%edi
  800a6c:	89 d6                	mov    %edx,%esi
  800a6e:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800a70:	5b                   	pop    %ebx
  800a71:	5e                   	pop    %esi
  800a72:	5f                   	pop    %edi
  800a73:	5d                   	pop    %ebp
  800a74:	c3                   	ret    

00800a75 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a75:	55                   	push   %ebp
  800a76:	89 e5                	mov    %esp,%ebp
  800a78:	57                   	push   %edi
  800a79:	56                   	push   %esi
  800a7a:	53                   	push   %ebx
  800a7b:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a7e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a83:	b8 03 00 00 00       	mov    $0x3,%eax
  800a88:	8b 55 08             	mov    0x8(%ebp),%edx
  800a8b:	89 cb                	mov    %ecx,%ebx
  800a8d:	89 cf                	mov    %ecx,%edi
  800a8f:	89 ce                	mov    %ecx,%esi
  800a91:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800a93:	85 c0                	test   %eax,%eax
  800a95:	7e 17                	jle    800aae <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800a97:	83 ec 0c             	sub    $0xc,%esp
  800a9a:	50                   	push   %eax
  800a9b:	6a 03                	push   $0x3
  800a9d:	68 00 10 80 00       	push   $0x801000
  800aa2:	6a 23                	push   $0x23
  800aa4:	68 1d 10 80 00       	push   $0x80101d
  800aa9:	e8 27 00 00 00       	call   800ad5 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800aae:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800ab1:	5b                   	pop    %ebx
  800ab2:	5e                   	pop    %esi
  800ab3:	5f                   	pop    %edi
  800ab4:	5d                   	pop    %ebp
  800ab5:	c3                   	ret    

00800ab6 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800ab6:	55                   	push   %ebp
  800ab7:	89 e5                	mov    %esp,%ebp
  800ab9:	57                   	push   %edi
  800aba:	56                   	push   %esi
  800abb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800abc:	ba 00 00 00 00       	mov    $0x0,%edx
  800ac1:	b8 02 00 00 00       	mov    $0x2,%eax
  800ac6:	89 d1                	mov    %edx,%ecx
  800ac8:	89 d3                	mov    %edx,%ebx
  800aca:	89 d7                	mov    %edx,%edi
  800acc:	89 d6                	mov    %edx,%esi
  800ace:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800ad0:	5b                   	pop    %ebx
  800ad1:	5e                   	pop    %esi
  800ad2:	5f                   	pop    %edi
  800ad3:	5d                   	pop    %ebp
  800ad4:	c3                   	ret    

00800ad5 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ad5:	55                   	push   %ebp
  800ad6:	89 e5                	mov    %esp,%ebp
  800ad8:	56                   	push   %esi
  800ad9:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800ada:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800add:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ae3:	e8 ce ff ff ff       	call   800ab6 <sys_getenvid>
  800ae8:	83 ec 0c             	sub    $0xc,%esp
  800aeb:	ff 75 0c             	pushl  0xc(%ebp)
  800aee:	ff 75 08             	pushl  0x8(%ebp)
  800af1:	56                   	push   %esi
  800af2:	50                   	push   %eax
  800af3:	68 2c 10 80 00       	push   $0x80102c
  800af8:	e8 4f f6 ff ff       	call   80014c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800afd:	83 c4 18             	add    $0x18,%esp
  800b00:	53                   	push   %ebx
  800b01:	ff 75 10             	pushl  0x10(%ebp)
  800b04:	e8 f2 f5 ff ff       	call   8000fb <vcprintf>
	cprintf("\n");
  800b09:	c7 04 24 cc 0d 80 00 	movl   $0x800dcc,(%esp)
  800b10:	e8 37 f6 ff ff       	call   80014c <cprintf>
  800b15:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b18:	cc                   	int3   
  800b19:	eb fd                	jmp    800b18 <_panic+0x43>
  800b1b:	66 90                	xchg   %ax,%ax
  800b1d:	66 90                	xchg   %ax,%ax
  800b1f:	90                   	nop

00800b20 <__udivdi3>:
  800b20:	55                   	push   %ebp
  800b21:	57                   	push   %edi
  800b22:	56                   	push   %esi
  800b23:	53                   	push   %ebx
  800b24:	83 ec 1c             	sub    $0x1c,%esp
  800b27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b33:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b37:	85 f6                	test   %esi,%esi
  800b39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b3d:	89 ca                	mov    %ecx,%edx
  800b3f:	89 f8                	mov    %edi,%eax
  800b41:	75 3d                	jne    800b80 <__udivdi3+0x60>
  800b43:	39 cf                	cmp    %ecx,%edi
  800b45:	0f 87 c5 00 00 00    	ja     800c10 <__udivdi3+0xf0>
  800b4b:	85 ff                	test   %edi,%edi
  800b4d:	89 fd                	mov    %edi,%ebp
  800b4f:	75 0b                	jne    800b5c <__udivdi3+0x3c>
  800b51:	b8 01 00 00 00       	mov    $0x1,%eax
  800b56:	31 d2                	xor    %edx,%edx
  800b58:	f7 f7                	div    %edi
  800b5a:	89 c5                	mov    %eax,%ebp
  800b5c:	89 c8                	mov    %ecx,%eax
  800b5e:	31 d2                	xor    %edx,%edx
  800b60:	f7 f5                	div    %ebp
  800b62:	89 c1                	mov    %eax,%ecx
  800b64:	89 d8                	mov    %ebx,%eax
  800b66:	89 cf                	mov    %ecx,%edi
  800b68:	f7 f5                	div    %ebp
  800b6a:	89 c3                	mov    %eax,%ebx
  800b6c:	89 d8                	mov    %ebx,%eax
  800b6e:	89 fa                	mov    %edi,%edx
  800b70:	83 c4 1c             	add    $0x1c,%esp
  800b73:	5b                   	pop    %ebx
  800b74:	5e                   	pop    %esi
  800b75:	5f                   	pop    %edi
  800b76:	5d                   	pop    %ebp
  800b77:	c3                   	ret    
  800b78:	90                   	nop
  800b79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b80:	39 ce                	cmp    %ecx,%esi
  800b82:	77 74                	ja     800bf8 <__udivdi3+0xd8>
  800b84:	0f bd fe             	bsr    %esi,%edi
  800b87:	83 f7 1f             	xor    $0x1f,%edi
  800b8a:	0f 84 98 00 00 00    	je     800c28 <__udivdi3+0x108>
  800b90:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b95:	89 f9                	mov    %edi,%ecx
  800b97:	89 c5                	mov    %eax,%ebp
  800b99:	29 fb                	sub    %edi,%ebx
  800b9b:	d3 e6                	shl    %cl,%esi
  800b9d:	89 d9                	mov    %ebx,%ecx
  800b9f:	d3 ed                	shr    %cl,%ebp
  800ba1:	89 f9                	mov    %edi,%ecx
  800ba3:	d3 e0                	shl    %cl,%eax
  800ba5:	09 ee                	or     %ebp,%esi
  800ba7:	89 d9                	mov    %ebx,%ecx
  800ba9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bad:	89 d5                	mov    %edx,%ebp
  800baf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800bb3:	d3 ed                	shr    %cl,%ebp
  800bb5:	89 f9                	mov    %edi,%ecx
  800bb7:	d3 e2                	shl    %cl,%edx
  800bb9:	89 d9                	mov    %ebx,%ecx
  800bbb:	d3 e8                	shr    %cl,%eax
  800bbd:	09 c2                	or     %eax,%edx
  800bbf:	89 d0                	mov    %edx,%eax
  800bc1:	89 ea                	mov    %ebp,%edx
  800bc3:	f7 f6                	div    %esi
  800bc5:	89 d5                	mov    %edx,%ebp
  800bc7:	89 c3                	mov    %eax,%ebx
  800bc9:	f7 64 24 0c          	mull   0xc(%esp)
  800bcd:	39 d5                	cmp    %edx,%ebp
  800bcf:	72 10                	jb     800be1 <__udivdi3+0xc1>
  800bd1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800bd5:	89 f9                	mov    %edi,%ecx
  800bd7:	d3 e6                	shl    %cl,%esi
  800bd9:	39 c6                	cmp    %eax,%esi
  800bdb:	73 07                	jae    800be4 <__udivdi3+0xc4>
  800bdd:	39 d5                	cmp    %edx,%ebp
  800bdf:	75 03                	jne    800be4 <__udivdi3+0xc4>
  800be1:	83 eb 01             	sub    $0x1,%ebx
  800be4:	31 ff                	xor    %edi,%edi
  800be6:	89 d8                	mov    %ebx,%eax
  800be8:	89 fa                	mov    %edi,%edx
  800bea:	83 c4 1c             	add    $0x1c,%esp
  800bed:	5b                   	pop    %ebx
  800bee:	5e                   	pop    %esi
  800bef:	5f                   	pop    %edi
  800bf0:	5d                   	pop    %ebp
  800bf1:	c3                   	ret    
  800bf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bf8:	31 ff                	xor    %edi,%edi
  800bfa:	31 db                	xor    %ebx,%ebx
  800bfc:	89 d8                	mov    %ebx,%eax
  800bfe:	89 fa                	mov    %edi,%edx
  800c00:	83 c4 1c             	add    $0x1c,%esp
  800c03:	5b                   	pop    %ebx
  800c04:	5e                   	pop    %esi
  800c05:	5f                   	pop    %edi
  800c06:	5d                   	pop    %ebp
  800c07:	c3                   	ret    
  800c08:	90                   	nop
  800c09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c10:	89 d8                	mov    %ebx,%eax
  800c12:	f7 f7                	div    %edi
  800c14:	31 ff                	xor    %edi,%edi
  800c16:	89 c3                	mov    %eax,%ebx
  800c18:	89 d8                	mov    %ebx,%eax
  800c1a:	89 fa                	mov    %edi,%edx
  800c1c:	83 c4 1c             	add    $0x1c,%esp
  800c1f:	5b                   	pop    %ebx
  800c20:	5e                   	pop    %esi
  800c21:	5f                   	pop    %edi
  800c22:	5d                   	pop    %ebp
  800c23:	c3                   	ret    
  800c24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c28:	39 ce                	cmp    %ecx,%esi
  800c2a:	72 0c                	jb     800c38 <__udivdi3+0x118>
  800c2c:	31 db                	xor    %ebx,%ebx
  800c2e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c32:	0f 87 34 ff ff ff    	ja     800b6c <__udivdi3+0x4c>
  800c38:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c3d:	e9 2a ff ff ff       	jmp    800b6c <__udivdi3+0x4c>
  800c42:	66 90                	xchg   %ax,%ax
  800c44:	66 90                	xchg   %ax,%ax
  800c46:	66 90                	xchg   %ax,%ax
  800c48:	66 90                	xchg   %ax,%ax
  800c4a:	66 90                	xchg   %ax,%ax
  800c4c:	66 90                	xchg   %ax,%ax
  800c4e:	66 90                	xchg   %ax,%ax

00800c50 <__umoddi3>:
  800c50:	55                   	push   %ebp
  800c51:	57                   	push   %edi
  800c52:	56                   	push   %esi
  800c53:	53                   	push   %ebx
  800c54:	83 ec 1c             	sub    $0x1c,%esp
  800c57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c5b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c5f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c67:	85 d2                	test   %edx,%edx
  800c69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c6d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c71:	89 f3                	mov    %esi,%ebx
  800c73:	89 3c 24             	mov    %edi,(%esp)
  800c76:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c7a:	75 1c                	jne    800c98 <__umoddi3+0x48>
  800c7c:	39 f7                	cmp    %esi,%edi
  800c7e:	76 50                	jbe    800cd0 <__umoddi3+0x80>
  800c80:	89 c8                	mov    %ecx,%eax
  800c82:	89 f2                	mov    %esi,%edx
  800c84:	f7 f7                	div    %edi
  800c86:	89 d0                	mov    %edx,%eax
  800c88:	31 d2                	xor    %edx,%edx
  800c8a:	83 c4 1c             	add    $0x1c,%esp
  800c8d:	5b                   	pop    %ebx
  800c8e:	5e                   	pop    %esi
  800c8f:	5f                   	pop    %edi
  800c90:	5d                   	pop    %ebp
  800c91:	c3                   	ret    
  800c92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c98:	39 f2                	cmp    %esi,%edx
  800c9a:	89 d0                	mov    %edx,%eax
  800c9c:	77 52                	ja     800cf0 <__umoddi3+0xa0>
  800c9e:	0f bd ea             	bsr    %edx,%ebp
  800ca1:	83 f5 1f             	xor    $0x1f,%ebp
  800ca4:	75 5a                	jne    800d00 <__umoddi3+0xb0>
  800ca6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800caa:	0f 82 e0 00 00 00    	jb     800d90 <__umoddi3+0x140>
  800cb0:	39 0c 24             	cmp    %ecx,(%esp)
  800cb3:	0f 86 d7 00 00 00    	jbe    800d90 <__umoddi3+0x140>
  800cb9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cbd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cc1:	83 c4 1c             	add    $0x1c,%esp
  800cc4:	5b                   	pop    %ebx
  800cc5:	5e                   	pop    %esi
  800cc6:	5f                   	pop    %edi
  800cc7:	5d                   	pop    %ebp
  800cc8:	c3                   	ret    
  800cc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cd0:	85 ff                	test   %edi,%edi
  800cd2:	89 fd                	mov    %edi,%ebp
  800cd4:	75 0b                	jne    800ce1 <__umoddi3+0x91>
  800cd6:	b8 01 00 00 00       	mov    $0x1,%eax
  800cdb:	31 d2                	xor    %edx,%edx
  800cdd:	f7 f7                	div    %edi
  800cdf:	89 c5                	mov    %eax,%ebp
  800ce1:	89 f0                	mov    %esi,%eax
  800ce3:	31 d2                	xor    %edx,%edx
  800ce5:	f7 f5                	div    %ebp
  800ce7:	89 c8                	mov    %ecx,%eax
  800ce9:	f7 f5                	div    %ebp
  800ceb:	89 d0                	mov    %edx,%eax
  800ced:	eb 99                	jmp    800c88 <__umoddi3+0x38>
  800cef:	90                   	nop
  800cf0:	89 c8                	mov    %ecx,%eax
  800cf2:	89 f2                	mov    %esi,%edx
  800cf4:	83 c4 1c             	add    $0x1c,%esp
  800cf7:	5b                   	pop    %ebx
  800cf8:	5e                   	pop    %esi
  800cf9:	5f                   	pop    %edi
  800cfa:	5d                   	pop    %ebp
  800cfb:	c3                   	ret    
  800cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d00:	8b 34 24             	mov    (%esp),%esi
  800d03:	bf 20 00 00 00       	mov    $0x20,%edi
  800d08:	89 e9                	mov    %ebp,%ecx
  800d0a:	29 ef                	sub    %ebp,%edi
  800d0c:	d3 e0                	shl    %cl,%eax
  800d0e:	89 f9                	mov    %edi,%ecx
  800d10:	89 f2                	mov    %esi,%edx
  800d12:	d3 ea                	shr    %cl,%edx
  800d14:	89 e9                	mov    %ebp,%ecx
  800d16:	09 c2                	or     %eax,%edx
  800d18:	89 d8                	mov    %ebx,%eax
  800d1a:	89 14 24             	mov    %edx,(%esp)
  800d1d:	89 f2                	mov    %esi,%edx
  800d1f:	d3 e2                	shl    %cl,%edx
  800d21:	89 f9                	mov    %edi,%ecx
  800d23:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d27:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d2b:	d3 e8                	shr    %cl,%eax
  800d2d:	89 e9                	mov    %ebp,%ecx
  800d2f:	89 c6                	mov    %eax,%esi
  800d31:	d3 e3                	shl    %cl,%ebx
  800d33:	89 f9                	mov    %edi,%ecx
  800d35:	89 d0                	mov    %edx,%eax
  800d37:	d3 e8                	shr    %cl,%eax
  800d39:	89 e9                	mov    %ebp,%ecx
  800d3b:	09 d8                	or     %ebx,%eax
  800d3d:	89 d3                	mov    %edx,%ebx
  800d3f:	89 f2                	mov    %esi,%edx
  800d41:	f7 34 24             	divl   (%esp)
  800d44:	89 d6                	mov    %edx,%esi
  800d46:	d3 e3                	shl    %cl,%ebx
  800d48:	f7 64 24 04          	mull   0x4(%esp)
  800d4c:	39 d6                	cmp    %edx,%esi
  800d4e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d52:	89 d1                	mov    %edx,%ecx
  800d54:	89 c3                	mov    %eax,%ebx
  800d56:	72 08                	jb     800d60 <__umoddi3+0x110>
  800d58:	75 11                	jne    800d6b <__umoddi3+0x11b>
  800d5a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d5e:	73 0b                	jae    800d6b <__umoddi3+0x11b>
  800d60:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d64:	1b 14 24             	sbb    (%esp),%edx
  800d67:	89 d1                	mov    %edx,%ecx
  800d69:	89 c3                	mov    %eax,%ebx
  800d6b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d6f:	29 da                	sub    %ebx,%edx
  800d71:	19 ce                	sbb    %ecx,%esi
  800d73:	89 f9                	mov    %edi,%ecx
  800d75:	89 f0                	mov    %esi,%eax
  800d77:	d3 e0                	shl    %cl,%eax
  800d79:	89 e9                	mov    %ebp,%ecx
  800d7b:	d3 ea                	shr    %cl,%edx
  800d7d:	89 e9                	mov    %ebp,%ecx
  800d7f:	d3 ee                	shr    %cl,%esi
  800d81:	09 d0                	or     %edx,%eax
  800d83:	89 f2                	mov    %esi,%edx
  800d85:	83 c4 1c             	add    $0x1c,%esp
  800d88:	5b                   	pop    %ebx
  800d89:	5e                   	pop    %esi
  800d8a:	5f                   	pop    %edi
  800d8b:	5d                   	pop    %ebp
  800d8c:	c3                   	ret    
  800d8d:	8d 76 00             	lea    0x0(%esi),%esi
  800d90:	29 f9                	sub    %edi,%ecx
  800d92:	19 d6                	sbb    %edx,%esi
  800d94:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d98:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d9c:	e9 18 ff ff ff       	jmp    800cb9 <__umoddi3+0x69>
