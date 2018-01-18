
obj/user/divzero:     file format elf32-i386


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
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	zero = 0;
  800039:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 c0 0d 80 00       	push   $0x800dc0
  800056:	e8 f3 00 00 00       	call   80014e <cprintf>
}
  80005b:	83 c4 10             	add    $0x10,%esp
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	56                   	push   %esi
  800064:	53                   	push   %ebx
  800065:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800068:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
thisenv = &envs[ENVX(sys_getenvid())];
  80006b:	e8 48 0a 00 00       	call   800ab8 <sys_getenvid>
  800070:	25 ff 03 00 00       	and    $0x3ff,%eax
  800075:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800078:	c1 e0 05             	shl    $0x5,%eax
  80007b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800080:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800085:	85 db                	test   %ebx,%ebx
  800087:	7e 07                	jle    800090 <libmain+0x30>
		binaryname = argv[0];
  800089:	8b 06                	mov    (%esi),%eax
  80008b:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800090:	83 ec 08             	sub    $0x8,%esp
  800093:	56                   	push   %esi
  800094:	53                   	push   %ebx
  800095:	e8 99 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80009a:	e8 0a 00 00 00       	call   8000a9 <exit>
}
  80009f:	83 c4 10             	add    $0x10,%esp
  8000a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a5:	5b                   	pop    %ebx
  8000a6:	5e                   	pop    %esi
  8000a7:	5d                   	pop    %ebp
  8000a8:	c3                   	ret    

008000a9 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000af:	6a 00                	push   $0x0
  8000b1:	e8 c1 09 00 00       	call   800a77 <sys_env_destroy>
}
  8000b6:	83 c4 10             	add    $0x10,%esp
  8000b9:	c9                   	leave  
  8000ba:	c3                   	ret    

008000bb <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000bb:	55                   	push   %ebp
  8000bc:	89 e5                	mov    %esp,%ebp
  8000be:	53                   	push   %ebx
  8000bf:	83 ec 04             	sub    $0x4,%esp
  8000c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c5:	8b 13                	mov    (%ebx),%edx
  8000c7:	8d 42 01             	lea    0x1(%edx),%eax
  8000ca:	89 03                	mov    %eax,(%ebx)
  8000cc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cf:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d3:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d8:	75 1a                	jne    8000f4 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000da:	83 ec 08             	sub    $0x8,%esp
  8000dd:	68 ff 00 00 00       	push   $0xff
  8000e2:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e5:	50                   	push   %eax
  8000e6:	e8 4f 09 00 00       	call   800a3a <sys_cputs>
		b->idx = 0;
  8000eb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000f1:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000fb:	c9                   	leave  
  8000fc:	c3                   	ret    

008000fd <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fd:	55                   	push   %ebp
  8000fe:	89 e5                	mov    %esp,%ebp
  800100:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800106:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010d:	00 00 00 
	b.cnt = 0;
  800110:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800117:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80011a:	ff 75 0c             	pushl  0xc(%ebp)
  80011d:	ff 75 08             	pushl  0x8(%ebp)
  800120:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800126:	50                   	push   %eax
  800127:	68 bb 00 80 00       	push   $0x8000bb
  80012c:	e8 54 01 00 00       	call   800285 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800131:	83 c4 08             	add    $0x8,%esp
  800134:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80013a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800140:	50                   	push   %eax
  800141:	e8 f4 08 00 00       	call   800a3a <sys_cputs>

	return b.cnt;
}
  800146:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014c:	c9                   	leave  
  80014d:	c3                   	ret    

0080014e <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014e:	55                   	push   %ebp
  80014f:	89 e5                	mov    %esp,%ebp
  800151:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800154:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800157:	50                   	push   %eax
  800158:	ff 75 08             	pushl  0x8(%ebp)
  80015b:	e8 9d ff ff ff       	call   8000fd <vcprintf>
	va_end(ap);

	return cnt;
}
  800160:	c9                   	leave  
  800161:	c3                   	ret    

00800162 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800162:	55                   	push   %ebp
  800163:	89 e5                	mov    %esp,%ebp
  800165:	57                   	push   %edi
  800166:	56                   	push   %esi
  800167:	53                   	push   %ebx
  800168:	83 ec 1c             	sub    $0x1c,%esp
  80016b:	89 c7                	mov    %eax,%edi
  80016d:	89 d6                	mov    %edx,%esi
  80016f:	8b 45 08             	mov    0x8(%ebp),%eax
  800172:	8b 55 0c             	mov    0xc(%ebp),%edx
  800175:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800178:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80017b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800183:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800186:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800189:	39 d3                	cmp    %edx,%ebx
  80018b:	72 05                	jb     800192 <printnum+0x30>
  80018d:	39 45 10             	cmp    %eax,0x10(%ebp)
  800190:	77 45                	ja     8001d7 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800192:	83 ec 0c             	sub    $0xc,%esp
  800195:	ff 75 18             	pushl  0x18(%ebp)
  800198:	8b 45 14             	mov    0x14(%ebp),%eax
  80019b:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019e:	53                   	push   %ebx
  80019f:	ff 75 10             	pushl  0x10(%ebp)
  8001a2:	83 ec 08             	sub    $0x8,%esp
  8001a5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a8:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ab:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ae:	ff 75 d8             	pushl  -0x28(%ebp)
  8001b1:	e8 6a 09 00 00       	call   800b20 <__udivdi3>
  8001b6:	83 c4 18             	add    $0x18,%esp
  8001b9:	52                   	push   %edx
  8001ba:	50                   	push   %eax
  8001bb:	89 f2                	mov    %esi,%edx
  8001bd:	89 f8                	mov    %edi,%eax
  8001bf:	e8 9e ff ff ff       	call   800162 <printnum>
  8001c4:	83 c4 20             	add    $0x20,%esp
  8001c7:	eb 18                	jmp    8001e1 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c9:	83 ec 08             	sub    $0x8,%esp
  8001cc:	56                   	push   %esi
  8001cd:	ff 75 18             	pushl  0x18(%ebp)
  8001d0:	ff d7                	call   *%edi
  8001d2:	83 c4 10             	add    $0x10,%esp
  8001d5:	eb 03                	jmp    8001da <printnum+0x78>
  8001d7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001da:	83 eb 01             	sub    $0x1,%ebx
  8001dd:	85 db                	test   %ebx,%ebx
  8001df:	7f e8                	jg     8001c9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001e1:	83 ec 08             	sub    $0x8,%esp
  8001e4:	56                   	push   %esi
  8001e5:	83 ec 04             	sub    $0x4,%esp
  8001e8:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001eb:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ee:	ff 75 dc             	pushl  -0x24(%ebp)
  8001f1:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f4:	e8 57 0a 00 00       	call   800c50 <__umoddi3>
  8001f9:	83 c4 14             	add    $0x14,%esp
  8001fc:	0f be 80 d8 0d 80 00 	movsbl 0x800dd8(%eax),%eax
  800203:	50                   	push   %eax
  800204:	ff d7                	call   *%edi
}
  800206:	83 c4 10             	add    $0x10,%esp
  800209:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80020c:	5b                   	pop    %ebx
  80020d:	5e                   	pop    %esi
  80020e:	5f                   	pop    %edi
  80020f:	5d                   	pop    %ebp
  800210:	c3                   	ret    

00800211 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800211:	55                   	push   %ebp
  800212:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800214:	83 fa 01             	cmp    $0x1,%edx
  800217:	7e 0e                	jle    800227 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800219:	8b 10                	mov    (%eax),%edx
  80021b:	8d 4a 08             	lea    0x8(%edx),%ecx
  80021e:	89 08                	mov    %ecx,(%eax)
  800220:	8b 02                	mov    (%edx),%eax
  800222:	8b 52 04             	mov    0x4(%edx),%edx
  800225:	eb 22                	jmp    800249 <getuint+0x38>
	else if (lflag)
  800227:	85 d2                	test   %edx,%edx
  800229:	74 10                	je     80023b <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80022b:	8b 10                	mov    (%eax),%edx
  80022d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800230:	89 08                	mov    %ecx,(%eax)
  800232:	8b 02                	mov    (%edx),%eax
  800234:	ba 00 00 00 00       	mov    $0x0,%edx
  800239:	eb 0e                	jmp    800249 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80023b:	8b 10                	mov    (%eax),%edx
  80023d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800240:	89 08                	mov    %ecx,(%eax)
  800242:	8b 02                	mov    (%edx),%eax
  800244:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800249:	5d                   	pop    %ebp
  80024a:	c3                   	ret    

0080024b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80024b:	55                   	push   %ebp
  80024c:	89 e5                	mov    %esp,%ebp
  80024e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800251:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800255:	8b 10                	mov    (%eax),%edx
  800257:	3b 50 04             	cmp    0x4(%eax),%edx
  80025a:	73 0a                	jae    800266 <sprintputch+0x1b>
		*b->buf++ = ch;
  80025c:	8d 4a 01             	lea    0x1(%edx),%ecx
  80025f:	89 08                	mov    %ecx,(%eax)
  800261:	8b 45 08             	mov    0x8(%ebp),%eax
  800264:	88 02                	mov    %al,(%edx)
}
  800266:	5d                   	pop    %ebp
  800267:	c3                   	ret    

00800268 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800268:	55                   	push   %ebp
  800269:	89 e5                	mov    %esp,%ebp
  80026b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80026e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800271:	50                   	push   %eax
  800272:	ff 75 10             	pushl  0x10(%ebp)
  800275:	ff 75 0c             	pushl  0xc(%ebp)
  800278:	ff 75 08             	pushl  0x8(%ebp)
  80027b:	e8 05 00 00 00       	call   800285 <vprintfmt>
	va_end(ap);
}
  800280:	83 c4 10             	add    $0x10,%esp
  800283:	c9                   	leave  
  800284:	c3                   	ret    

00800285 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800285:	55                   	push   %ebp
  800286:	89 e5                	mov    %esp,%ebp
  800288:	57                   	push   %edi
  800289:	56                   	push   %esi
  80028a:	53                   	push   %ebx
  80028b:	83 ec 2c             	sub    $0x2c,%esp
  80028e:	8b 75 08             	mov    0x8(%ebp),%esi
  800291:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800294:	8b 7d 10             	mov    0x10(%ebp),%edi
  800297:	eb 12                	jmp    8002ab <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800299:	85 c0                	test   %eax,%eax
  80029b:	0f 84 a9 03 00 00    	je     80064a <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
  8002a1:	83 ec 08             	sub    $0x8,%esp
  8002a4:	53                   	push   %ebx
  8002a5:	50                   	push   %eax
  8002a6:	ff d6                	call   *%esi
  8002a8:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002ab:	83 c7 01             	add    $0x1,%edi
  8002ae:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002b2:	83 f8 25             	cmp    $0x25,%eax
  8002b5:	75 e2                	jne    800299 <vprintfmt+0x14>
  8002b7:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002bb:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002c2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002c9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002d0:	ba 00 00 00 00       	mov    $0x0,%edx
  8002d5:	eb 07                	jmp    8002de <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002da:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002de:	8d 47 01             	lea    0x1(%edi),%eax
  8002e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002e4:	0f b6 07             	movzbl (%edi),%eax
  8002e7:	0f b6 c8             	movzbl %al,%ecx
  8002ea:	83 e8 23             	sub    $0x23,%eax
  8002ed:	3c 55                	cmp    $0x55,%al
  8002ef:	0f 87 3a 03 00 00    	ja     80062f <vprintfmt+0x3aa>
  8002f5:	0f b6 c0             	movzbl %al,%eax
  8002f8:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8002ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800302:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800306:	eb d6                	jmp    8002de <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800308:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80030b:	b8 00 00 00 00       	mov    $0x0,%eax
  800310:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800313:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800316:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80031a:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80031d:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800320:	83 fa 09             	cmp    $0x9,%edx
  800323:	77 39                	ja     80035e <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800325:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800328:	eb e9                	jmp    800313 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80032a:	8b 45 14             	mov    0x14(%ebp),%eax
  80032d:	8d 48 04             	lea    0x4(%eax),%ecx
  800330:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800333:	8b 00                	mov    (%eax),%eax
  800335:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800338:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80033b:	eb 27                	jmp    800364 <vprintfmt+0xdf>
  80033d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800340:	85 c0                	test   %eax,%eax
  800342:	b9 00 00 00 00       	mov    $0x0,%ecx
  800347:	0f 49 c8             	cmovns %eax,%ecx
  80034a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800350:	eb 8c                	jmp    8002de <vprintfmt+0x59>
  800352:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800355:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80035c:	eb 80                	jmp    8002de <vprintfmt+0x59>
  80035e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800361:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800364:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800368:	0f 89 70 ff ff ff    	jns    8002de <vprintfmt+0x59>
				width = precision, precision = -1;
  80036e:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800371:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800374:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80037b:	e9 5e ff ff ff       	jmp    8002de <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800380:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800383:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800386:	e9 53 ff ff ff       	jmp    8002de <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80038b:	8b 45 14             	mov    0x14(%ebp),%eax
  80038e:	8d 50 04             	lea    0x4(%eax),%edx
  800391:	89 55 14             	mov    %edx,0x14(%ebp)
  800394:	83 ec 08             	sub    $0x8,%esp
  800397:	53                   	push   %ebx
  800398:	ff 30                	pushl  (%eax)
  80039a:	ff d6                	call   *%esi
			break;
  80039c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003a2:	e9 04 ff ff ff       	jmp    8002ab <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003aa:	8d 50 04             	lea    0x4(%eax),%edx
  8003ad:	89 55 14             	mov    %edx,0x14(%ebp)
  8003b0:	8b 00                	mov    (%eax),%eax
  8003b2:	99                   	cltd   
  8003b3:	31 d0                	xor    %edx,%eax
  8003b5:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003b7:	83 f8 07             	cmp    $0x7,%eax
  8003ba:	7f 0b                	jg     8003c7 <vprintfmt+0x142>
  8003bc:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  8003c3:	85 d2                	test   %edx,%edx
  8003c5:	75 18                	jne    8003df <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003c7:	50                   	push   %eax
  8003c8:	68 f0 0d 80 00       	push   $0x800df0
  8003cd:	53                   	push   %ebx
  8003ce:	56                   	push   %esi
  8003cf:	e8 94 fe ff ff       	call   800268 <printfmt>
  8003d4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003da:	e9 cc fe ff ff       	jmp    8002ab <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003df:	52                   	push   %edx
  8003e0:	68 f9 0d 80 00       	push   $0x800df9
  8003e5:	53                   	push   %ebx
  8003e6:	56                   	push   %esi
  8003e7:	e8 7c fe ff ff       	call   800268 <printfmt>
  8003ec:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003f2:	e9 b4 fe ff ff       	jmp    8002ab <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003fa:	8d 50 04             	lea    0x4(%eax),%edx
  8003fd:	89 55 14             	mov    %edx,0x14(%ebp)
  800400:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800402:	85 ff                	test   %edi,%edi
  800404:	b8 e9 0d 80 00       	mov    $0x800de9,%eax
  800409:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80040c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800410:	0f 8e 94 00 00 00    	jle    8004aa <vprintfmt+0x225>
  800416:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80041a:	0f 84 98 00 00 00    	je     8004b8 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800420:	83 ec 08             	sub    $0x8,%esp
  800423:	ff 75 d0             	pushl  -0x30(%ebp)
  800426:	57                   	push   %edi
  800427:	e8 a6 02 00 00       	call   8006d2 <strnlen>
  80042c:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80042f:	29 c1                	sub    %eax,%ecx
  800431:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800434:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800437:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80043b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80043e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800441:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800443:	eb 0f                	jmp    800454 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800445:	83 ec 08             	sub    $0x8,%esp
  800448:	53                   	push   %ebx
  800449:	ff 75 e0             	pushl  -0x20(%ebp)
  80044c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80044e:	83 ef 01             	sub    $0x1,%edi
  800451:	83 c4 10             	add    $0x10,%esp
  800454:	85 ff                	test   %edi,%edi
  800456:	7f ed                	jg     800445 <vprintfmt+0x1c0>
  800458:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80045b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80045e:	85 c9                	test   %ecx,%ecx
  800460:	b8 00 00 00 00       	mov    $0x0,%eax
  800465:	0f 49 c1             	cmovns %ecx,%eax
  800468:	29 c1                	sub    %eax,%ecx
  80046a:	89 75 08             	mov    %esi,0x8(%ebp)
  80046d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800470:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800473:	89 cb                	mov    %ecx,%ebx
  800475:	eb 4d                	jmp    8004c4 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800477:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80047b:	74 1b                	je     800498 <vprintfmt+0x213>
  80047d:	0f be c0             	movsbl %al,%eax
  800480:	83 e8 20             	sub    $0x20,%eax
  800483:	83 f8 5e             	cmp    $0x5e,%eax
  800486:	76 10                	jbe    800498 <vprintfmt+0x213>
					putch('?', putdat);
  800488:	83 ec 08             	sub    $0x8,%esp
  80048b:	ff 75 0c             	pushl  0xc(%ebp)
  80048e:	6a 3f                	push   $0x3f
  800490:	ff 55 08             	call   *0x8(%ebp)
  800493:	83 c4 10             	add    $0x10,%esp
  800496:	eb 0d                	jmp    8004a5 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800498:	83 ec 08             	sub    $0x8,%esp
  80049b:	ff 75 0c             	pushl  0xc(%ebp)
  80049e:	52                   	push   %edx
  80049f:	ff 55 08             	call   *0x8(%ebp)
  8004a2:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004a5:	83 eb 01             	sub    $0x1,%ebx
  8004a8:	eb 1a                	jmp    8004c4 <vprintfmt+0x23f>
  8004aa:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ad:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004b0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004b3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004b6:	eb 0c                	jmp    8004c4 <vprintfmt+0x23f>
  8004b8:	89 75 08             	mov    %esi,0x8(%ebp)
  8004bb:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004be:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004c1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004c4:	83 c7 01             	add    $0x1,%edi
  8004c7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004cb:	0f be d0             	movsbl %al,%edx
  8004ce:	85 d2                	test   %edx,%edx
  8004d0:	74 23                	je     8004f5 <vprintfmt+0x270>
  8004d2:	85 f6                	test   %esi,%esi
  8004d4:	78 a1                	js     800477 <vprintfmt+0x1f2>
  8004d6:	83 ee 01             	sub    $0x1,%esi
  8004d9:	79 9c                	jns    800477 <vprintfmt+0x1f2>
  8004db:	89 df                	mov    %ebx,%edi
  8004dd:	8b 75 08             	mov    0x8(%ebp),%esi
  8004e0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004e3:	eb 18                	jmp    8004fd <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004e5:	83 ec 08             	sub    $0x8,%esp
  8004e8:	53                   	push   %ebx
  8004e9:	6a 20                	push   $0x20
  8004eb:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004ed:	83 ef 01             	sub    $0x1,%edi
  8004f0:	83 c4 10             	add    $0x10,%esp
  8004f3:	eb 08                	jmp    8004fd <vprintfmt+0x278>
  8004f5:	89 df                	mov    %ebx,%edi
  8004f7:	8b 75 08             	mov    0x8(%ebp),%esi
  8004fa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004fd:	85 ff                	test   %edi,%edi
  8004ff:	7f e4                	jg     8004e5 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800501:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800504:	e9 a2 fd ff ff       	jmp    8002ab <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800509:	83 fa 01             	cmp    $0x1,%edx
  80050c:	7e 16                	jle    800524 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  80050e:	8b 45 14             	mov    0x14(%ebp),%eax
  800511:	8d 50 08             	lea    0x8(%eax),%edx
  800514:	89 55 14             	mov    %edx,0x14(%ebp)
  800517:	8b 50 04             	mov    0x4(%eax),%edx
  80051a:	8b 00                	mov    (%eax),%eax
  80051c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80051f:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800522:	eb 32                	jmp    800556 <vprintfmt+0x2d1>
	else if (lflag)
  800524:	85 d2                	test   %edx,%edx
  800526:	74 18                	je     800540 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800528:	8b 45 14             	mov    0x14(%ebp),%eax
  80052b:	8d 50 04             	lea    0x4(%eax),%edx
  80052e:	89 55 14             	mov    %edx,0x14(%ebp)
  800531:	8b 00                	mov    (%eax),%eax
  800533:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800536:	89 c1                	mov    %eax,%ecx
  800538:	c1 f9 1f             	sar    $0x1f,%ecx
  80053b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80053e:	eb 16                	jmp    800556 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  800540:	8b 45 14             	mov    0x14(%ebp),%eax
  800543:	8d 50 04             	lea    0x4(%eax),%edx
  800546:	89 55 14             	mov    %edx,0x14(%ebp)
  800549:	8b 00                	mov    (%eax),%eax
  80054b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80054e:	89 c1                	mov    %eax,%ecx
  800550:	c1 f9 1f             	sar    $0x1f,%ecx
  800553:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800556:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800559:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80055c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800561:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800565:	0f 89 90 00 00 00    	jns    8005fb <vprintfmt+0x376>
				putch('-', putdat);
  80056b:	83 ec 08             	sub    $0x8,%esp
  80056e:	53                   	push   %ebx
  80056f:	6a 2d                	push   $0x2d
  800571:	ff d6                	call   *%esi
				num = -(long long) num;
  800573:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800576:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800579:	f7 d8                	neg    %eax
  80057b:	83 d2 00             	adc    $0x0,%edx
  80057e:	f7 da                	neg    %edx
  800580:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800583:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800588:	eb 71                	jmp    8005fb <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80058a:	8d 45 14             	lea    0x14(%ebp),%eax
  80058d:	e8 7f fc ff ff       	call   800211 <getuint>
			base = 10;
  800592:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800597:	eb 62                	jmp    8005fb <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800599:	8d 45 14             	lea    0x14(%ebp),%eax
  80059c:	e8 70 fc ff ff       	call   800211 <getuint>
                        base = 8;
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
  8005a1:	83 ec 0c             	sub    $0xc,%esp
  8005a4:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
  8005a8:	51                   	push   %ecx
  8005a9:	ff 75 e0             	pushl  -0x20(%ebp)
  8005ac:	6a 08                	push   $0x8
  8005ae:	52                   	push   %edx
  8005af:	50                   	push   %eax
  8005b0:	89 da                	mov    %ebx,%edx
  8005b2:	89 f0                	mov    %esi,%eax
  8005b4:	e8 a9 fb ff ff       	call   800162 <printnum>
                        break;
  8005b9:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
                        break;
  8005bf:	e9 e7 fc ff ff       	jmp    8002ab <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  8005c4:	83 ec 08             	sub    $0x8,%esp
  8005c7:	53                   	push   %ebx
  8005c8:	6a 30                	push   $0x30
  8005ca:	ff d6                	call   *%esi
			putch('x', putdat);
  8005cc:	83 c4 08             	add    $0x8,%esp
  8005cf:	53                   	push   %ebx
  8005d0:	6a 78                	push   $0x78
  8005d2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005d4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d7:	8d 50 04             	lea    0x4(%eax),%edx
  8005da:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005dd:	8b 00                	mov    (%eax),%eax
  8005df:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005e4:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005e7:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005ec:	eb 0d                	jmp    8005fb <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005ee:	8d 45 14             	lea    0x14(%ebp),%eax
  8005f1:	e8 1b fc ff ff       	call   800211 <getuint>
			base = 16;
  8005f6:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005fb:	83 ec 0c             	sub    $0xc,%esp
  8005fe:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800602:	57                   	push   %edi
  800603:	ff 75 e0             	pushl  -0x20(%ebp)
  800606:	51                   	push   %ecx
  800607:	52                   	push   %edx
  800608:	50                   	push   %eax
  800609:	89 da                	mov    %ebx,%edx
  80060b:	89 f0                	mov    %esi,%eax
  80060d:	e8 50 fb ff ff       	call   800162 <printnum>
			break;
  800612:	83 c4 20             	add    $0x20,%esp
  800615:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800618:	e9 8e fc ff ff       	jmp    8002ab <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80061d:	83 ec 08             	sub    $0x8,%esp
  800620:	53                   	push   %ebx
  800621:	51                   	push   %ecx
  800622:	ff d6                	call   *%esi
			break;
  800624:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800627:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80062a:	e9 7c fc ff ff       	jmp    8002ab <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80062f:	83 ec 08             	sub    $0x8,%esp
  800632:	53                   	push   %ebx
  800633:	6a 25                	push   $0x25
  800635:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800637:	83 c4 10             	add    $0x10,%esp
  80063a:	eb 03                	jmp    80063f <vprintfmt+0x3ba>
  80063c:	83 ef 01             	sub    $0x1,%edi
  80063f:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800643:	75 f7                	jne    80063c <vprintfmt+0x3b7>
  800645:	e9 61 fc ff ff       	jmp    8002ab <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80064a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80064d:	5b                   	pop    %ebx
  80064e:	5e                   	pop    %esi
  80064f:	5f                   	pop    %edi
  800650:	5d                   	pop    %ebp
  800651:	c3                   	ret    

00800652 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800652:	55                   	push   %ebp
  800653:	89 e5                	mov    %esp,%ebp
  800655:	83 ec 18             	sub    $0x18,%esp
  800658:	8b 45 08             	mov    0x8(%ebp),%eax
  80065b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80065e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800661:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800665:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800668:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80066f:	85 c0                	test   %eax,%eax
  800671:	74 26                	je     800699 <vsnprintf+0x47>
  800673:	85 d2                	test   %edx,%edx
  800675:	7e 22                	jle    800699 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800677:	ff 75 14             	pushl  0x14(%ebp)
  80067a:	ff 75 10             	pushl  0x10(%ebp)
  80067d:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800680:	50                   	push   %eax
  800681:	68 4b 02 80 00       	push   $0x80024b
  800686:	e8 fa fb ff ff       	call   800285 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80068b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80068e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800691:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800694:	83 c4 10             	add    $0x10,%esp
  800697:	eb 05                	jmp    80069e <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800699:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80069e:	c9                   	leave  
  80069f:	c3                   	ret    

008006a0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8006a0:	55                   	push   %ebp
  8006a1:	89 e5                	mov    %esp,%ebp
  8006a3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8006a6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8006a9:	50                   	push   %eax
  8006aa:	ff 75 10             	pushl  0x10(%ebp)
  8006ad:	ff 75 0c             	pushl  0xc(%ebp)
  8006b0:	ff 75 08             	pushl  0x8(%ebp)
  8006b3:	e8 9a ff ff ff       	call   800652 <vsnprintf>
	va_end(ap);

	return rc;
}
  8006b8:	c9                   	leave  
  8006b9:	c3                   	ret    

008006ba <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8006ba:	55                   	push   %ebp
  8006bb:	89 e5                	mov    %esp,%ebp
  8006bd:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8006c0:	b8 00 00 00 00       	mov    $0x0,%eax
  8006c5:	eb 03                	jmp    8006ca <strlen+0x10>
		n++;
  8006c7:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8006ca:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8006ce:	75 f7                	jne    8006c7 <strlen+0xd>
		n++;
	return n;
}
  8006d0:	5d                   	pop    %ebp
  8006d1:	c3                   	ret    

008006d2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8006d2:	55                   	push   %ebp
  8006d3:	89 e5                	mov    %esp,%ebp
  8006d5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006d8:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006db:	ba 00 00 00 00       	mov    $0x0,%edx
  8006e0:	eb 03                	jmp    8006e5 <strnlen+0x13>
		n++;
  8006e2:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006e5:	39 c2                	cmp    %eax,%edx
  8006e7:	74 08                	je     8006f1 <strnlen+0x1f>
  8006e9:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006ed:	75 f3                	jne    8006e2 <strnlen+0x10>
  8006ef:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006f1:	5d                   	pop    %ebp
  8006f2:	c3                   	ret    

008006f3 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006f3:	55                   	push   %ebp
  8006f4:	89 e5                	mov    %esp,%ebp
  8006f6:	53                   	push   %ebx
  8006f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8006fa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006fd:	89 c2                	mov    %eax,%edx
  8006ff:	83 c2 01             	add    $0x1,%edx
  800702:	83 c1 01             	add    $0x1,%ecx
  800705:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800709:	88 5a ff             	mov    %bl,-0x1(%edx)
  80070c:	84 db                	test   %bl,%bl
  80070e:	75 ef                	jne    8006ff <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800710:	5b                   	pop    %ebx
  800711:	5d                   	pop    %ebp
  800712:	c3                   	ret    

00800713 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800713:	55                   	push   %ebp
  800714:	89 e5                	mov    %esp,%ebp
  800716:	53                   	push   %ebx
  800717:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  80071a:	53                   	push   %ebx
  80071b:	e8 9a ff ff ff       	call   8006ba <strlen>
  800720:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800723:	ff 75 0c             	pushl  0xc(%ebp)
  800726:	01 d8                	add    %ebx,%eax
  800728:	50                   	push   %eax
  800729:	e8 c5 ff ff ff       	call   8006f3 <strcpy>
	return dst;
}
  80072e:	89 d8                	mov    %ebx,%eax
  800730:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800733:	c9                   	leave  
  800734:	c3                   	ret    

00800735 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800735:	55                   	push   %ebp
  800736:	89 e5                	mov    %esp,%ebp
  800738:	56                   	push   %esi
  800739:	53                   	push   %ebx
  80073a:	8b 75 08             	mov    0x8(%ebp),%esi
  80073d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800740:	89 f3                	mov    %esi,%ebx
  800742:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800745:	89 f2                	mov    %esi,%edx
  800747:	eb 0f                	jmp    800758 <strncpy+0x23>
		*dst++ = *src;
  800749:	83 c2 01             	add    $0x1,%edx
  80074c:	0f b6 01             	movzbl (%ecx),%eax
  80074f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800752:	80 39 01             	cmpb   $0x1,(%ecx)
  800755:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800758:	39 da                	cmp    %ebx,%edx
  80075a:	75 ed                	jne    800749 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80075c:	89 f0                	mov    %esi,%eax
  80075e:	5b                   	pop    %ebx
  80075f:	5e                   	pop    %esi
  800760:	5d                   	pop    %ebp
  800761:	c3                   	ret    

00800762 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800762:	55                   	push   %ebp
  800763:	89 e5                	mov    %esp,%ebp
  800765:	56                   	push   %esi
  800766:	53                   	push   %ebx
  800767:	8b 75 08             	mov    0x8(%ebp),%esi
  80076a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80076d:	8b 55 10             	mov    0x10(%ebp),%edx
  800770:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800772:	85 d2                	test   %edx,%edx
  800774:	74 21                	je     800797 <strlcpy+0x35>
  800776:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80077a:	89 f2                	mov    %esi,%edx
  80077c:	eb 09                	jmp    800787 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80077e:	83 c2 01             	add    $0x1,%edx
  800781:	83 c1 01             	add    $0x1,%ecx
  800784:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800787:	39 c2                	cmp    %eax,%edx
  800789:	74 09                	je     800794 <strlcpy+0x32>
  80078b:	0f b6 19             	movzbl (%ecx),%ebx
  80078e:	84 db                	test   %bl,%bl
  800790:	75 ec                	jne    80077e <strlcpy+0x1c>
  800792:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800794:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800797:	29 f0                	sub    %esi,%eax
}
  800799:	5b                   	pop    %ebx
  80079a:	5e                   	pop    %esi
  80079b:	5d                   	pop    %ebp
  80079c:	c3                   	ret    

0080079d <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80079d:	55                   	push   %ebp
  80079e:	89 e5                	mov    %esp,%ebp
  8007a0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007a3:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8007a6:	eb 06                	jmp    8007ae <strcmp+0x11>
		p++, q++;
  8007a8:	83 c1 01             	add    $0x1,%ecx
  8007ab:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8007ae:	0f b6 01             	movzbl (%ecx),%eax
  8007b1:	84 c0                	test   %al,%al
  8007b3:	74 04                	je     8007b9 <strcmp+0x1c>
  8007b5:	3a 02                	cmp    (%edx),%al
  8007b7:	74 ef                	je     8007a8 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8007b9:	0f b6 c0             	movzbl %al,%eax
  8007bc:	0f b6 12             	movzbl (%edx),%edx
  8007bf:	29 d0                	sub    %edx,%eax
}
  8007c1:	5d                   	pop    %ebp
  8007c2:	c3                   	ret    

008007c3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8007c3:	55                   	push   %ebp
  8007c4:	89 e5                	mov    %esp,%ebp
  8007c6:	53                   	push   %ebx
  8007c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ca:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007cd:	89 c3                	mov    %eax,%ebx
  8007cf:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8007d2:	eb 06                	jmp    8007da <strncmp+0x17>
		n--, p++, q++;
  8007d4:	83 c0 01             	add    $0x1,%eax
  8007d7:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007da:	39 d8                	cmp    %ebx,%eax
  8007dc:	74 15                	je     8007f3 <strncmp+0x30>
  8007de:	0f b6 08             	movzbl (%eax),%ecx
  8007e1:	84 c9                	test   %cl,%cl
  8007e3:	74 04                	je     8007e9 <strncmp+0x26>
  8007e5:	3a 0a                	cmp    (%edx),%cl
  8007e7:	74 eb                	je     8007d4 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007e9:	0f b6 00             	movzbl (%eax),%eax
  8007ec:	0f b6 12             	movzbl (%edx),%edx
  8007ef:	29 d0                	sub    %edx,%eax
  8007f1:	eb 05                	jmp    8007f8 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007f3:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007f8:	5b                   	pop    %ebx
  8007f9:	5d                   	pop    %ebp
  8007fa:	c3                   	ret    

008007fb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007fb:	55                   	push   %ebp
  8007fc:	89 e5                	mov    %esp,%ebp
  8007fe:	8b 45 08             	mov    0x8(%ebp),%eax
  800801:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800805:	eb 07                	jmp    80080e <strchr+0x13>
		if (*s == c)
  800807:	38 ca                	cmp    %cl,%dl
  800809:	74 0f                	je     80081a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80080b:	83 c0 01             	add    $0x1,%eax
  80080e:	0f b6 10             	movzbl (%eax),%edx
  800811:	84 d2                	test   %dl,%dl
  800813:	75 f2                	jne    800807 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800815:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80081a:	5d                   	pop    %ebp
  80081b:	c3                   	ret    

0080081c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80081c:	55                   	push   %ebp
  80081d:	89 e5                	mov    %esp,%ebp
  80081f:	8b 45 08             	mov    0x8(%ebp),%eax
  800822:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800826:	eb 03                	jmp    80082b <strfind+0xf>
  800828:	83 c0 01             	add    $0x1,%eax
  80082b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80082e:	38 ca                	cmp    %cl,%dl
  800830:	74 04                	je     800836 <strfind+0x1a>
  800832:	84 d2                	test   %dl,%dl
  800834:	75 f2                	jne    800828 <strfind+0xc>
			break;
	return (char *) s;
}
  800836:	5d                   	pop    %ebp
  800837:	c3                   	ret    

00800838 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800838:	55                   	push   %ebp
  800839:	89 e5                	mov    %esp,%ebp
  80083b:	57                   	push   %edi
  80083c:	56                   	push   %esi
  80083d:	53                   	push   %ebx
  80083e:	8b 7d 08             	mov    0x8(%ebp),%edi
  800841:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800844:	85 c9                	test   %ecx,%ecx
  800846:	74 36                	je     80087e <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800848:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80084e:	75 28                	jne    800878 <memset+0x40>
  800850:	f6 c1 03             	test   $0x3,%cl
  800853:	75 23                	jne    800878 <memset+0x40>
		c &= 0xFF;
  800855:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800859:	89 d3                	mov    %edx,%ebx
  80085b:	c1 e3 08             	shl    $0x8,%ebx
  80085e:	89 d6                	mov    %edx,%esi
  800860:	c1 e6 18             	shl    $0x18,%esi
  800863:	89 d0                	mov    %edx,%eax
  800865:	c1 e0 10             	shl    $0x10,%eax
  800868:	09 f0                	or     %esi,%eax
  80086a:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80086c:	89 d8                	mov    %ebx,%eax
  80086e:	09 d0                	or     %edx,%eax
  800870:	c1 e9 02             	shr    $0x2,%ecx
  800873:	fc                   	cld    
  800874:	f3 ab                	rep stos %eax,%es:(%edi)
  800876:	eb 06                	jmp    80087e <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800878:	8b 45 0c             	mov    0xc(%ebp),%eax
  80087b:	fc                   	cld    
  80087c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80087e:	89 f8                	mov    %edi,%eax
  800880:	5b                   	pop    %ebx
  800881:	5e                   	pop    %esi
  800882:	5f                   	pop    %edi
  800883:	5d                   	pop    %ebp
  800884:	c3                   	ret    

00800885 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800885:	55                   	push   %ebp
  800886:	89 e5                	mov    %esp,%ebp
  800888:	57                   	push   %edi
  800889:	56                   	push   %esi
  80088a:	8b 45 08             	mov    0x8(%ebp),%eax
  80088d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800890:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800893:	39 c6                	cmp    %eax,%esi
  800895:	73 35                	jae    8008cc <memmove+0x47>
  800897:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80089a:	39 d0                	cmp    %edx,%eax
  80089c:	73 2e                	jae    8008cc <memmove+0x47>
		s += n;
		d += n;
  80089e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008a1:	89 d6                	mov    %edx,%esi
  8008a3:	09 fe                	or     %edi,%esi
  8008a5:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8008ab:	75 13                	jne    8008c0 <memmove+0x3b>
  8008ad:	f6 c1 03             	test   $0x3,%cl
  8008b0:	75 0e                	jne    8008c0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  8008b2:	83 ef 04             	sub    $0x4,%edi
  8008b5:	8d 72 fc             	lea    -0x4(%edx),%esi
  8008b8:	c1 e9 02             	shr    $0x2,%ecx
  8008bb:	fd                   	std    
  8008bc:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008be:	eb 09                	jmp    8008c9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8008c0:	83 ef 01             	sub    $0x1,%edi
  8008c3:	8d 72 ff             	lea    -0x1(%edx),%esi
  8008c6:	fd                   	std    
  8008c7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8008c9:	fc                   	cld    
  8008ca:	eb 1d                	jmp    8008e9 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008cc:	89 f2                	mov    %esi,%edx
  8008ce:	09 c2                	or     %eax,%edx
  8008d0:	f6 c2 03             	test   $0x3,%dl
  8008d3:	75 0f                	jne    8008e4 <memmove+0x5f>
  8008d5:	f6 c1 03             	test   $0x3,%cl
  8008d8:	75 0a                	jne    8008e4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008da:	c1 e9 02             	shr    $0x2,%ecx
  8008dd:	89 c7                	mov    %eax,%edi
  8008df:	fc                   	cld    
  8008e0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008e2:	eb 05                	jmp    8008e9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008e4:	89 c7                	mov    %eax,%edi
  8008e6:	fc                   	cld    
  8008e7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008e9:	5e                   	pop    %esi
  8008ea:	5f                   	pop    %edi
  8008eb:	5d                   	pop    %ebp
  8008ec:	c3                   	ret    

008008ed <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008ed:	55                   	push   %ebp
  8008ee:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008f0:	ff 75 10             	pushl  0x10(%ebp)
  8008f3:	ff 75 0c             	pushl  0xc(%ebp)
  8008f6:	ff 75 08             	pushl  0x8(%ebp)
  8008f9:	e8 87 ff ff ff       	call   800885 <memmove>
}
  8008fe:	c9                   	leave  
  8008ff:	c3                   	ret    

00800900 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800900:	55                   	push   %ebp
  800901:	89 e5                	mov    %esp,%ebp
  800903:	56                   	push   %esi
  800904:	53                   	push   %ebx
  800905:	8b 45 08             	mov    0x8(%ebp),%eax
  800908:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090b:	89 c6                	mov    %eax,%esi
  80090d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800910:	eb 1a                	jmp    80092c <memcmp+0x2c>
		if (*s1 != *s2)
  800912:	0f b6 08             	movzbl (%eax),%ecx
  800915:	0f b6 1a             	movzbl (%edx),%ebx
  800918:	38 d9                	cmp    %bl,%cl
  80091a:	74 0a                	je     800926 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  80091c:	0f b6 c1             	movzbl %cl,%eax
  80091f:	0f b6 db             	movzbl %bl,%ebx
  800922:	29 d8                	sub    %ebx,%eax
  800924:	eb 0f                	jmp    800935 <memcmp+0x35>
		s1++, s2++;
  800926:	83 c0 01             	add    $0x1,%eax
  800929:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80092c:	39 f0                	cmp    %esi,%eax
  80092e:	75 e2                	jne    800912 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800930:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800935:	5b                   	pop    %ebx
  800936:	5e                   	pop    %esi
  800937:	5d                   	pop    %ebp
  800938:	c3                   	ret    

00800939 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800939:	55                   	push   %ebp
  80093a:	89 e5                	mov    %esp,%ebp
  80093c:	53                   	push   %ebx
  80093d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800940:	89 c1                	mov    %eax,%ecx
  800942:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800945:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800949:	eb 0a                	jmp    800955 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  80094b:	0f b6 10             	movzbl (%eax),%edx
  80094e:	39 da                	cmp    %ebx,%edx
  800950:	74 07                	je     800959 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800952:	83 c0 01             	add    $0x1,%eax
  800955:	39 c8                	cmp    %ecx,%eax
  800957:	72 f2                	jb     80094b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800959:	5b                   	pop    %ebx
  80095a:	5d                   	pop    %ebp
  80095b:	c3                   	ret    

0080095c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  80095c:	55                   	push   %ebp
  80095d:	89 e5                	mov    %esp,%ebp
  80095f:	57                   	push   %edi
  800960:	56                   	push   %esi
  800961:	53                   	push   %ebx
  800962:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800965:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800968:	eb 03                	jmp    80096d <strtol+0x11>
		s++;
  80096a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80096d:	0f b6 01             	movzbl (%ecx),%eax
  800970:	3c 20                	cmp    $0x20,%al
  800972:	74 f6                	je     80096a <strtol+0xe>
  800974:	3c 09                	cmp    $0x9,%al
  800976:	74 f2                	je     80096a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800978:	3c 2b                	cmp    $0x2b,%al
  80097a:	75 0a                	jne    800986 <strtol+0x2a>
		s++;
  80097c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80097f:	bf 00 00 00 00       	mov    $0x0,%edi
  800984:	eb 11                	jmp    800997 <strtol+0x3b>
  800986:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  80098b:	3c 2d                	cmp    $0x2d,%al
  80098d:	75 08                	jne    800997 <strtol+0x3b>
		s++, neg = 1;
  80098f:	83 c1 01             	add    $0x1,%ecx
  800992:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800997:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  80099d:	75 15                	jne    8009b4 <strtol+0x58>
  80099f:	80 39 30             	cmpb   $0x30,(%ecx)
  8009a2:	75 10                	jne    8009b4 <strtol+0x58>
  8009a4:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  8009a8:	75 7c                	jne    800a26 <strtol+0xca>
		s += 2, base = 16;
  8009aa:	83 c1 02             	add    $0x2,%ecx
  8009ad:	bb 10 00 00 00       	mov    $0x10,%ebx
  8009b2:	eb 16                	jmp    8009ca <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  8009b4:	85 db                	test   %ebx,%ebx
  8009b6:	75 12                	jne    8009ca <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  8009b8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009bd:	80 39 30             	cmpb   $0x30,(%ecx)
  8009c0:	75 08                	jne    8009ca <strtol+0x6e>
		s++, base = 8;
  8009c2:	83 c1 01             	add    $0x1,%ecx
  8009c5:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  8009ca:	b8 00 00 00 00       	mov    $0x0,%eax
  8009cf:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  8009d2:	0f b6 11             	movzbl (%ecx),%edx
  8009d5:	8d 72 d0             	lea    -0x30(%edx),%esi
  8009d8:	89 f3                	mov    %esi,%ebx
  8009da:	80 fb 09             	cmp    $0x9,%bl
  8009dd:	77 08                	ja     8009e7 <strtol+0x8b>
			dig = *s - '0';
  8009df:	0f be d2             	movsbl %dl,%edx
  8009e2:	83 ea 30             	sub    $0x30,%edx
  8009e5:	eb 22                	jmp    800a09 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009e7:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009ea:	89 f3                	mov    %esi,%ebx
  8009ec:	80 fb 19             	cmp    $0x19,%bl
  8009ef:	77 08                	ja     8009f9 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009f1:	0f be d2             	movsbl %dl,%edx
  8009f4:	83 ea 57             	sub    $0x57,%edx
  8009f7:	eb 10                	jmp    800a09 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009f9:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009fc:	89 f3                	mov    %esi,%ebx
  8009fe:	80 fb 19             	cmp    $0x19,%bl
  800a01:	77 16                	ja     800a19 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a03:	0f be d2             	movsbl %dl,%edx
  800a06:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a09:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a0c:	7d 0b                	jge    800a19 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a0e:	83 c1 01             	add    $0x1,%ecx
  800a11:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a15:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a17:	eb b9                	jmp    8009d2 <strtol+0x76>

	if (endptr)
  800a19:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a1d:	74 0d                	je     800a2c <strtol+0xd0>
		*endptr = (char *) s;
  800a1f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a22:	89 0e                	mov    %ecx,(%esi)
  800a24:	eb 06                	jmp    800a2c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a26:	85 db                	test   %ebx,%ebx
  800a28:	74 98                	je     8009c2 <strtol+0x66>
  800a2a:	eb 9e                	jmp    8009ca <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a2c:	89 c2                	mov    %eax,%edx
  800a2e:	f7 da                	neg    %edx
  800a30:	85 ff                	test   %edi,%edi
  800a32:	0f 45 c2             	cmovne %edx,%eax
}
  800a35:	5b                   	pop    %ebx
  800a36:	5e                   	pop    %esi
  800a37:	5f                   	pop    %edi
  800a38:	5d                   	pop    %ebp
  800a39:	c3                   	ret    

00800a3a <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a3a:	55                   	push   %ebp
  800a3b:	89 e5                	mov    %esp,%ebp
  800a3d:	57                   	push   %edi
  800a3e:	56                   	push   %esi
  800a3f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a40:	b8 00 00 00 00       	mov    $0x0,%eax
  800a45:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a48:	8b 55 08             	mov    0x8(%ebp),%edx
  800a4b:	89 c3                	mov    %eax,%ebx
  800a4d:	89 c7                	mov    %eax,%edi
  800a4f:	89 c6                	mov    %eax,%esi
  800a51:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a53:	5b                   	pop    %ebx
  800a54:	5e                   	pop    %esi
  800a55:	5f                   	pop    %edi
  800a56:	5d                   	pop    %ebp
  800a57:	c3                   	ret    

00800a58 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a58:	55                   	push   %ebp
  800a59:	89 e5                	mov    %esp,%ebp
  800a5b:	57                   	push   %edi
  800a5c:	56                   	push   %esi
  800a5d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a5e:	ba 00 00 00 00       	mov    $0x0,%edx
  800a63:	b8 01 00 00 00       	mov    $0x1,%eax
  800a68:	89 d1                	mov    %edx,%ecx
  800a6a:	89 d3                	mov    %edx,%ebx
  800a6c:	89 d7                	mov    %edx,%edi
  800a6e:	89 d6                	mov    %edx,%esi
  800a70:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800a72:	5b                   	pop    %ebx
  800a73:	5e                   	pop    %esi
  800a74:	5f                   	pop    %edi
  800a75:	5d                   	pop    %ebp
  800a76:	c3                   	ret    

00800a77 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a77:	55                   	push   %ebp
  800a78:	89 e5                	mov    %esp,%ebp
  800a7a:	57                   	push   %edi
  800a7b:	56                   	push   %esi
  800a7c:	53                   	push   %ebx
  800a7d:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a80:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a85:	b8 03 00 00 00       	mov    $0x3,%eax
  800a8a:	8b 55 08             	mov    0x8(%ebp),%edx
  800a8d:	89 cb                	mov    %ecx,%ebx
  800a8f:	89 cf                	mov    %ecx,%edi
  800a91:	89 ce                	mov    %ecx,%esi
  800a93:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800a95:	85 c0                	test   %eax,%eax
  800a97:	7e 17                	jle    800ab0 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800a99:	83 ec 0c             	sub    $0xc,%esp
  800a9c:	50                   	push   %eax
  800a9d:	6a 03                	push   $0x3
  800a9f:	68 00 10 80 00       	push   $0x801000
  800aa4:	6a 23                	push   $0x23
  800aa6:	68 1d 10 80 00       	push   $0x80101d
  800aab:	e8 27 00 00 00       	call   800ad7 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800ab0:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800ab3:	5b                   	pop    %ebx
  800ab4:	5e                   	pop    %esi
  800ab5:	5f                   	pop    %edi
  800ab6:	5d                   	pop    %ebp
  800ab7:	c3                   	ret    

00800ab8 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800ab8:	55                   	push   %ebp
  800ab9:	89 e5                	mov    %esp,%ebp
  800abb:	57                   	push   %edi
  800abc:	56                   	push   %esi
  800abd:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800abe:	ba 00 00 00 00       	mov    $0x0,%edx
  800ac3:	b8 02 00 00 00       	mov    $0x2,%eax
  800ac8:	89 d1                	mov    %edx,%ecx
  800aca:	89 d3                	mov    %edx,%ebx
  800acc:	89 d7                	mov    %edx,%edi
  800ace:	89 d6                	mov    %edx,%esi
  800ad0:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800ad2:	5b                   	pop    %ebx
  800ad3:	5e                   	pop    %esi
  800ad4:	5f                   	pop    %edi
  800ad5:	5d                   	pop    %ebp
  800ad6:	c3                   	ret    

00800ad7 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ad7:	55                   	push   %ebp
  800ad8:	89 e5                	mov    %esp,%ebp
  800ada:	56                   	push   %esi
  800adb:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800adc:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800adf:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ae5:	e8 ce ff ff ff       	call   800ab8 <sys_getenvid>
  800aea:	83 ec 0c             	sub    $0xc,%esp
  800aed:	ff 75 0c             	pushl  0xc(%ebp)
  800af0:	ff 75 08             	pushl  0x8(%ebp)
  800af3:	56                   	push   %esi
  800af4:	50                   	push   %eax
  800af5:	68 2c 10 80 00       	push   $0x80102c
  800afa:	e8 4f f6 ff ff       	call   80014e <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800aff:	83 c4 18             	add    $0x18,%esp
  800b02:	53                   	push   %ebx
  800b03:	ff 75 10             	pushl  0x10(%ebp)
  800b06:	e8 f2 f5 ff ff       	call   8000fd <vcprintf>
	cprintf("\n");
  800b0b:	c7 04 24 cc 0d 80 00 	movl   $0x800dcc,(%esp)
  800b12:	e8 37 f6 ff ff       	call   80014e <cprintf>
  800b17:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b1a:	cc                   	int3   
  800b1b:	eb fd                	jmp    800b1a <_panic+0x43>
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
