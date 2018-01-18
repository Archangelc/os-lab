
obj/user/testbss:     file format elf32-i386


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
  80002c:	e8 ab 00 00 00       	call   8000dc <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  800039:	68 40 0e 80 00       	push   $0x800e40
  80003e:	e8 cd 01 00 00       	call   800210 <cprintf>
  800043:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < ARRAYSIZE; i++)
  800046:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004b:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800052:	00 
  800053:	74 12                	je     800067 <umain+0x34>
			panic("bigarray[%d] isn't cleared!\n", i);
  800055:	50                   	push   %eax
  800056:	68 bb 0e 80 00       	push   $0x800ebb
  80005b:	6a 11                	push   $0x11
  80005d:	68 d8 0e 80 00       	push   $0x800ed8
  800062:	e8 d0 00 00 00       	call   800137 <_panic>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  800067:	83 c0 01             	add    $0x1,%eax
  80006a:	3d 00 00 10 00       	cmp    $0x100000,%eax
  80006f:	75 da                	jne    80004b <umain+0x18>
  800071:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  800076:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
  80007d:	83 c0 01             	add    $0x1,%eax
  800080:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800085:	75 ef                	jne    800076 <umain+0x43>
  800087:	b8 00 00 00 00       	mov    $0x0,%eax
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  80008c:	3b 04 85 20 20 80 00 	cmp    0x802020(,%eax,4),%eax
  800093:	74 12                	je     8000a7 <umain+0x74>
			panic("bigarray[%d] didn't hold its value!\n", i);
  800095:	50                   	push   %eax
  800096:	68 60 0e 80 00       	push   $0x800e60
  80009b:	6a 16                	push   $0x16
  80009d:	68 d8 0e 80 00       	push   $0x800ed8
  8000a2:	e8 90 00 00 00       	call   800137 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  8000a7:	83 c0 01             	add    $0x1,%eax
  8000aa:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000af:	75 db                	jne    80008c <umain+0x59>
		if (bigarray[i] != i)
			panic("bigarray[%d] didn't hold its value!\n", i);

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000b1:	83 ec 0c             	sub    $0xc,%esp
  8000b4:	68 88 0e 80 00       	push   $0x800e88
  8000b9:	e8 52 01 00 00       	call   800210 <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000be:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000c5:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000c8:	83 c4 0c             	add    $0xc,%esp
  8000cb:	68 e7 0e 80 00       	push   $0x800ee7
  8000d0:	6a 1a                	push   $0x1a
  8000d2:	68 d8 0e 80 00       	push   $0x800ed8
  8000d7:	e8 5b 00 00 00       	call   800137 <_panic>

008000dc <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	56                   	push   %esi
  8000e0:	53                   	push   %ebx
  8000e1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000e4:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
thisenv = &envs[ENVX(sys_getenvid())];
  8000e7:	e8 8e 0a 00 00       	call   800b7a <sys_getenvid>
  8000ec:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000f1:	8d 04 40             	lea    (%eax,%eax,2),%eax
  8000f4:	c1 e0 05             	shl    $0x5,%eax
  8000f7:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000fc:	a3 20 20 c0 00       	mov    %eax,0xc02020

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800101:	85 db                	test   %ebx,%ebx
  800103:	7e 07                	jle    80010c <libmain+0x30>
		binaryname = argv[0];
  800105:	8b 06                	mov    (%esi),%eax
  800107:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80010c:	83 ec 08             	sub    $0x8,%esp
  80010f:	56                   	push   %esi
  800110:	53                   	push   %ebx
  800111:	e8 1d ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800116:	e8 0a 00 00 00       	call   800125 <exit>
}
  80011b:	83 c4 10             	add    $0x10,%esp
  80011e:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800121:	5b                   	pop    %ebx
  800122:	5e                   	pop    %esi
  800123:	5d                   	pop    %ebp
  800124:	c3                   	ret    

00800125 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800125:	55                   	push   %ebp
  800126:	89 e5                	mov    %esp,%ebp
  800128:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80012b:	6a 00                	push   $0x0
  80012d:	e8 07 0a 00 00       	call   800b39 <sys_env_destroy>
}
  800132:	83 c4 10             	add    $0x10,%esp
  800135:	c9                   	leave  
  800136:	c3                   	ret    

00800137 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800137:	55                   	push   %ebp
  800138:	89 e5                	mov    %esp,%ebp
  80013a:	56                   	push   %esi
  80013b:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80013c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80013f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800145:	e8 30 0a 00 00       	call   800b7a <sys_getenvid>
  80014a:	83 ec 0c             	sub    $0xc,%esp
  80014d:	ff 75 0c             	pushl  0xc(%ebp)
  800150:	ff 75 08             	pushl  0x8(%ebp)
  800153:	56                   	push   %esi
  800154:	50                   	push   %eax
  800155:	68 08 0f 80 00       	push   $0x800f08
  80015a:	e8 b1 00 00 00       	call   800210 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80015f:	83 c4 18             	add    $0x18,%esp
  800162:	53                   	push   %ebx
  800163:	ff 75 10             	pushl  0x10(%ebp)
  800166:	e8 54 00 00 00       	call   8001bf <vcprintf>
	cprintf("\n");
  80016b:	c7 04 24 d6 0e 80 00 	movl   $0x800ed6,(%esp)
  800172:	e8 99 00 00 00       	call   800210 <cprintf>
  800177:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80017a:	cc                   	int3   
  80017b:	eb fd                	jmp    80017a <_panic+0x43>

0080017d <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80017d:	55                   	push   %ebp
  80017e:	89 e5                	mov    %esp,%ebp
  800180:	53                   	push   %ebx
  800181:	83 ec 04             	sub    $0x4,%esp
  800184:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800187:	8b 13                	mov    (%ebx),%edx
  800189:	8d 42 01             	lea    0x1(%edx),%eax
  80018c:	89 03                	mov    %eax,(%ebx)
  80018e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800191:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800195:	3d ff 00 00 00       	cmp    $0xff,%eax
  80019a:	75 1a                	jne    8001b6 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80019c:	83 ec 08             	sub    $0x8,%esp
  80019f:	68 ff 00 00 00       	push   $0xff
  8001a4:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a7:	50                   	push   %eax
  8001a8:	e8 4f 09 00 00       	call   800afc <sys_cputs>
		b->idx = 0;
  8001ad:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001b3:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b6:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001ba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001bd:	c9                   	leave  
  8001be:	c3                   	ret    

008001bf <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001bf:	55                   	push   %ebp
  8001c0:	89 e5                	mov    %esp,%ebp
  8001c2:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c8:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001cf:	00 00 00 
	b.cnt = 0;
  8001d2:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d9:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001dc:	ff 75 0c             	pushl  0xc(%ebp)
  8001df:	ff 75 08             	pushl  0x8(%ebp)
  8001e2:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e8:	50                   	push   %eax
  8001e9:	68 7d 01 80 00       	push   $0x80017d
  8001ee:	e8 54 01 00 00       	call   800347 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001f3:	83 c4 08             	add    $0x8,%esp
  8001f6:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001fc:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800202:	50                   	push   %eax
  800203:	e8 f4 08 00 00       	call   800afc <sys_cputs>

	return b.cnt;
}
  800208:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80020e:	c9                   	leave  
  80020f:	c3                   	ret    

00800210 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800210:	55                   	push   %ebp
  800211:	89 e5                	mov    %esp,%ebp
  800213:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800216:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800219:	50                   	push   %eax
  80021a:	ff 75 08             	pushl  0x8(%ebp)
  80021d:	e8 9d ff ff ff       	call   8001bf <vcprintf>
	va_end(ap);

	return cnt;
}
  800222:	c9                   	leave  
  800223:	c3                   	ret    

00800224 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800224:	55                   	push   %ebp
  800225:	89 e5                	mov    %esp,%ebp
  800227:	57                   	push   %edi
  800228:	56                   	push   %esi
  800229:	53                   	push   %ebx
  80022a:	83 ec 1c             	sub    $0x1c,%esp
  80022d:	89 c7                	mov    %eax,%edi
  80022f:	89 d6                	mov    %edx,%esi
  800231:	8b 45 08             	mov    0x8(%ebp),%eax
  800234:	8b 55 0c             	mov    0xc(%ebp),%edx
  800237:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80023a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80023d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800240:	bb 00 00 00 00       	mov    $0x0,%ebx
  800245:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800248:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80024b:	39 d3                	cmp    %edx,%ebx
  80024d:	72 05                	jb     800254 <printnum+0x30>
  80024f:	39 45 10             	cmp    %eax,0x10(%ebp)
  800252:	77 45                	ja     800299 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800254:	83 ec 0c             	sub    $0xc,%esp
  800257:	ff 75 18             	pushl  0x18(%ebp)
  80025a:	8b 45 14             	mov    0x14(%ebp),%eax
  80025d:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800260:	53                   	push   %ebx
  800261:	ff 75 10             	pushl  0x10(%ebp)
  800264:	83 ec 08             	sub    $0x8,%esp
  800267:	ff 75 e4             	pushl  -0x1c(%ebp)
  80026a:	ff 75 e0             	pushl  -0x20(%ebp)
  80026d:	ff 75 dc             	pushl  -0x24(%ebp)
  800270:	ff 75 d8             	pushl  -0x28(%ebp)
  800273:	e8 28 09 00 00       	call   800ba0 <__udivdi3>
  800278:	83 c4 18             	add    $0x18,%esp
  80027b:	52                   	push   %edx
  80027c:	50                   	push   %eax
  80027d:	89 f2                	mov    %esi,%edx
  80027f:	89 f8                	mov    %edi,%eax
  800281:	e8 9e ff ff ff       	call   800224 <printnum>
  800286:	83 c4 20             	add    $0x20,%esp
  800289:	eb 18                	jmp    8002a3 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80028b:	83 ec 08             	sub    $0x8,%esp
  80028e:	56                   	push   %esi
  80028f:	ff 75 18             	pushl  0x18(%ebp)
  800292:	ff d7                	call   *%edi
  800294:	83 c4 10             	add    $0x10,%esp
  800297:	eb 03                	jmp    80029c <printnum+0x78>
  800299:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80029c:	83 eb 01             	sub    $0x1,%ebx
  80029f:	85 db                	test   %ebx,%ebx
  8002a1:	7f e8                	jg     80028b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002a3:	83 ec 08             	sub    $0x8,%esp
  8002a6:	56                   	push   %esi
  8002a7:	83 ec 04             	sub    $0x4,%esp
  8002aa:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002ad:	ff 75 e0             	pushl  -0x20(%ebp)
  8002b0:	ff 75 dc             	pushl  -0x24(%ebp)
  8002b3:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b6:	e8 15 0a 00 00       	call   800cd0 <__umoddi3>
  8002bb:	83 c4 14             	add    $0x14,%esp
  8002be:	0f be 80 2c 0f 80 00 	movsbl 0x800f2c(%eax),%eax
  8002c5:	50                   	push   %eax
  8002c6:	ff d7                	call   *%edi
}
  8002c8:	83 c4 10             	add    $0x10,%esp
  8002cb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ce:	5b                   	pop    %ebx
  8002cf:	5e                   	pop    %esi
  8002d0:	5f                   	pop    %edi
  8002d1:	5d                   	pop    %ebp
  8002d2:	c3                   	ret    

008002d3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002d3:	55                   	push   %ebp
  8002d4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d6:	83 fa 01             	cmp    $0x1,%edx
  8002d9:	7e 0e                	jle    8002e9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002db:	8b 10                	mov    (%eax),%edx
  8002dd:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002e0:	89 08                	mov    %ecx,(%eax)
  8002e2:	8b 02                	mov    (%edx),%eax
  8002e4:	8b 52 04             	mov    0x4(%edx),%edx
  8002e7:	eb 22                	jmp    80030b <getuint+0x38>
	else if (lflag)
  8002e9:	85 d2                	test   %edx,%edx
  8002eb:	74 10                	je     8002fd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002ed:	8b 10                	mov    (%eax),%edx
  8002ef:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002f2:	89 08                	mov    %ecx,(%eax)
  8002f4:	8b 02                	mov    (%edx),%eax
  8002f6:	ba 00 00 00 00       	mov    $0x0,%edx
  8002fb:	eb 0e                	jmp    80030b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002fd:	8b 10                	mov    (%eax),%edx
  8002ff:	8d 4a 04             	lea    0x4(%edx),%ecx
  800302:	89 08                	mov    %ecx,(%eax)
  800304:	8b 02                	mov    (%edx),%eax
  800306:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80030b:	5d                   	pop    %ebp
  80030c:	c3                   	ret    

0080030d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80030d:	55                   	push   %ebp
  80030e:	89 e5                	mov    %esp,%ebp
  800310:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800313:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800317:	8b 10                	mov    (%eax),%edx
  800319:	3b 50 04             	cmp    0x4(%eax),%edx
  80031c:	73 0a                	jae    800328 <sprintputch+0x1b>
		*b->buf++ = ch;
  80031e:	8d 4a 01             	lea    0x1(%edx),%ecx
  800321:	89 08                	mov    %ecx,(%eax)
  800323:	8b 45 08             	mov    0x8(%ebp),%eax
  800326:	88 02                	mov    %al,(%edx)
}
  800328:	5d                   	pop    %ebp
  800329:	c3                   	ret    

0080032a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80032a:	55                   	push   %ebp
  80032b:	89 e5                	mov    %esp,%ebp
  80032d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800330:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800333:	50                   	push   %eax
  800334:	ff 75 10             	pushl  0x10(%ebp)
  800337:	ff 75 0c             	pushl  0xc(%ebp)
  80033a:	ff 75 08             	pushl  0x8(%ebp)
  80033d:	e8 05 00 00 00       	call   800347 <vprintfmt>
	va_end(ap);
}
  800342:	83 c4 10             	add    $0x10,%esp
  800345:	c9                   	leave  
  800346:	c3                   	ret    

00800347 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800347:	55                   	push   %ebp
  800348:	89 e5                	mov    %esp,%ebp
  80034a:	57                   	push   %edi
  80034b:	56                   	push   %esi
  80034c:	53                   	push   %ebx
  80034d:	83 ec 2c             	sub    $0x2c,%esp
  800350:	8b 75 08             	mov    0x8(%ebp),%esi
  800353:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800356:	8b 7d 10             	mov    0x10(%ebp),%edi
  800359:	eb 12                	jmp    80036d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80035b:	85 c0                	test   %eax,%eax
  80035d:	0f 84 a9 03 00 00    	je     80070c <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
  800363:	83 ec 08             	sub    $0x8,%esp
  800366:	53                   	push   %ebx
  800367:	50                   	push   %eax
  800368:	ff d6                	call   *%esi
  80036a:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80036d:	83 c7 01             	add    $0x1,%edi
  800370:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800374:	83 f8 25             	cmp    $0x25,%eax
  800377:	75 e2                	jne    80035b <vprintfmt+0x14>
  800379:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80037d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800384:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80038b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800392:	ba 00 00 00 00       	mov    $0x0,%edx
  800397:	eb 07                	jmp    8003a0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800399:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80039c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a0:	8d 47 01             	lea    0x1(%edi),%eax
  8003a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003a6:	0f b6 07             	movzbl (%edi),%eax
  8003a9:	0f b6 c8             	movzbl %al,%ecx
  8003ac:	83 e8 23             	sub    $0x23,%eax
  8003af:	3c 55                	cmp    $0x55,%al
  8003b1:	0f 87 3a 03 00 00    	ja     8006f1 <vprintfmt+0x3aa>
  8003b7:	0f b6 c0             	movzbl %al,%eax
  8003ba:	ff 24 85 c0 0f 80 00 	jmp    *0x800fc0(,%eax,4)
  8003c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003c4:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003c8:	eb d6                	jmp    8003a0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003cd:	b8 00 00 00 00       	mov    $0x0,%eax
  8003d2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003d5:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003d8:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003dc:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003df:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003e2:	83 fa 09             	cmp    $0x9,%edx
  8003e5:	77 39                	ja     800420 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003e7:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003ea:	eb e9                	jmp    8003d5 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003ec:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ef:	8d 48 04             	lea    0x4(%eax),%ecx
  8003f2:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003f5:	8b 00                	mov    (%eax),%eax
  8003f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003fd:	eb 27                	jmp    800426 <vprintfmt+0xdf>
  8003ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800402:	85 c0                	test   %eax,%eax
  800404:	b9 00 00 00 00       	mov    $0x0,%ecx
  800409:	0f 49 c8             	cmovns %eax,%ecx
  80040c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800412:	eb 8c                	jmp    8003a0 <vprintfmt+0x59>
  800414:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800417:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80041e:	eb 80                	jmp    8003a0 <vprintfmt+0x59>
  800420:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800423:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800426:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80042a:	0f 89 70 ff ff ff    	jns    8003a0 <vprintfmt+0x59>
				width = precision, precision = -1;
  800430:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800433:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800436:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80043d:	e9 5e ff ff ff       	jmp    8003a0 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800442:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800445:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800448:	e9 53 ff ff ff       	jmp    8003a0 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80044d:	8b 45 14             	mov    0x14(%ebp),%eax
  800450:	8d 50 04             	lea    0x4(%eax),%edx
  800453:	89 55 14             	mov    %edx,0x14(%ebp)
  800456:	83 ec 08             	sub    $0x8,%esp
  800459:	53                   	push   %ebx
  80045a:	ff 30                	pushl  (%eax)
  80045c:	ff d6                	call   *%esi
			break;
  80045e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800461:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800464:	e9 04 ff ff ff       	jmp    80036d <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800469:	8b 45 14             	mov    0x14(%ebp),%eax
  80046c:	8d 50 04             	lea    0x4(%eax),%edx
  80046f:	89 55 14             	mov    %edx,0x14(%ebp)
  800472:	8b 00                	mov    (%eax),%eax
  800474:	99                   	cltd   
  800475:	31 d0                	xor    %edx,%eax
  800477:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800479:	83 f8 07             	cmp    $0x7,%eax
  80047c:	7f 0b                	jg     800489 <vprintfmt+0x142>
  80047e:	8b 14 85 20 11 80 00 	mov    0x801120(,%eax,4),%edx
  800485:	85 d2                	test   %edx,%edx
  800487:	75 18                	jne    8004a1 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800489:	50                   	push   %eax
  80048a:	68 44 0f 80 00       	push   $0x800f44
  80048f:	53                   	push   %ebx
  800490:	56                   	push   %esi
  800491:	e8 94 fe ff ff       	call   80032a <printfmt>
  800496:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800499:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80049c:	e9 cc fe ff ff       	jmp    80036d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004a1:	52                   	push   %edx
  8004a2:	68 4d 0f 80 00       	push   $0x800f4d
  8004a7:	53                   	push   %ebx
  8004a8:	56                   	push   %esi
  8004a9:	e8 7c fe ff ff       	call   80032a <printfmt>
  8004ae:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004b4:	e9 b4 fe ff ff       	jmp    80036d <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004bc:	8d 50 04             	lea    0x4(%eax),%edx
  8004bf:	89 55 14             	mov    %edx,0x14(%ebp)
  8004c2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004c4:	85 ff                	test   %edi,%edi
  8004c6:	b8 3d 0f 80 00       	mov    $0x800f3d,%eax
  8004cb:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004ce:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004d2:	0f 8e 94 00 00 00    	jle    80056c <vprintfmt+0x225>
  8004d8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004dc:	0f 84 98 00 00 00    	je     80057a <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e2:	83 ec 08             	sub    $0x8,%esp
  8004e5:	ff 75 d0             	pushl  -0x30(%ebp)
  8004e8:	57                   	push   %edi
  8004e9:	e8 a6 02 00 00       	call   800794 <strnlen>
  8004ee:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004f1:	29 c1                	sub    %eax,%ecx
  8004f3:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004f6:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004f9:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004fd:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800500:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800503:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800505:	eb 0f                	jmp    800516 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800507:	83 ec 08             	sub    $0x8,%esp
  80050a:	53                   	push   %ebx
  80050b:	ff 75 e0             	pushl  -0x20(%ebp)
  80050e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800510:	83 ef 01             	sub    $0x1,%edi
  800513:	83 c4 10             	add    $0x10,%esp
  800516:	85 ff                	test   %edi,%edi
  800518:	7f ed                	jg     800507 <vprintfmt+0x1c0>
  80051a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80051d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800520:	85 c9                	test   %ecx,%ecx
  800522:	b8 00 00 00 00       	mov    $0x0,%eax
  800527:	0f 49 c1             	cmovns %ecx,%eax
  80052a:	29 c1                	sub    %eax,%ecx
  80052c:	89 75 08             	mov    %esi,0x8(%ebp)
  80052f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800532:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800535:	89 cb                	mov    %ecx,%ebx
  800537:	eb 4d                	jmp    800586 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800539:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80053d:	74 1b                	je     80055a <vprintfmt+0x213>
  80053f:	0f be c0             	movsbl %al,%eax
  800542:	83 e8 20             	sub    $0x20,%eax
  800545:	83 f8 5e             	cmp    $0x5e,%eax
  800548:	76 10                	jbe    80055a <vprintfmt+0x213>
					putch('?', putdat);
  80054a:	83 ec 08             	sub    $0x8,%esp
  80054d:	ff 75 0c             	pushl  0xc(%ebp)
  800550:	6a 3f                	push   $0x3f
  800552:	ff 55 08             	call   *0x8(%ebp)
  800555:	83 c4 10             	add    $0x10,%esp
  800558:	eb 0d                	jmp    800567 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  80055a:	83 ec 08             	sub    $0x8,%esp
  80055d:	ff 75 0c             	pushl  0xc(%ebp)
  800560:	52                   	push   %edx
  800561:	ff 55 08             	call   *0x8(%ebp)
  800564:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800567:	83 eb 01             	sub    $0x1,%ebx
  80056a:	eb 1a                	jmp    800586 <vprintfmt+0x23f>
  80056c:	89 75 08             	mov    %esi,0x8(%ebp)
  80056f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800572:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800575:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800578:	eb 0c                	jmp    800586 <vprintfmt+0x23f>
  80057a:	89 75 08             	mov    %esi,0x8(%ebp)
  80057d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800580:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800583:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800586:	83 c7 01             	add    $0x1,%edi
  800589:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80058d:	0f be d0             	movsbl %al,%edx
  800590:	85 d2                	test   %edx,%edx
  800592:	74 23                	je     8005b7 <vprintfmt+0x270>
  800594:	85 f6                	test   %esi,%esi
  800596:	78 a1                	js     800539 <vprintfmt+0x1f2>
  800598:	83 ee 01             	sub    $0x1,%esi
  80059b:	79 9c                	jns    800539 <vprintfmt+0x1f2>
  80059d:	89 df                	mov    %ebx,%edi
  80059f:	8b 75 08             	mov    0x8(%ebp),%esi
  8005a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a5:	eb 18                	jmp    8005bf <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005a7:	83 ec 08             	sub    $0x8,%esp
  8005aa:	53                   	push   %ebx
  8005ab:	6a 20                	push   $0x20
  8005ad:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005af:	83 ef 01             	sub    $0x1,%edi
  8005b2:	83 c4 10             	add    $0x10,%esp
  8005b5:	eb 08                	jmp    8005bf <vprintfmt+0x278>
  8005b7:	89 df                	mov    %ebx,%edi
  8005b9:	8b 75 08             	mov    0x8(%ebp),%esi
  8005bc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005bf:	85 ff                	test   %edi,%edi
  8005c1:	7f e4                	jg     8005a7 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c6:	e9 a2 fd ff ff       	jmp    80036d <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005cb:	83 fa 01             	cmp    $0x1,%edx
  8005ce:	7e 16                	jle    8005e6 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005d0:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d3:	8d 50 08             	lea    0x8(%eax),%edx
  8005d6:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d9:	8b 50 04             	mov    0x4(%eax),%edx
  8005dc:	8b 00                	mov    (%eax),%eax
  8005de:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e1:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005e4:	eb 32                	jmp    800618 <vprintfmt+0x2d1>
	else if (lflag)
  8005e6:	85 d2                	test   %edx,%edx
  8005e8:	74 18                	je     800602 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005ea:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ed:	8d 50 04             	lea    0x4(%eax),%edx
  8005f0:	89 55 14             	mov    %edx,0x14(%ebp)
  8005f3:	8b 00                	mov    (%eax),%eax
  8005f5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f8:	89 c1                	mov    %eax,%ecx
  8005fa:	c1 f9 1f             	sar    $0x1f,%ecx
  8005fd:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800600:	eb 16                	jmp    800618 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  800602:	8b 45 14             	mov    0x14(%ebp),%eax
  800605:	8d 50 04             	lea    0x4(%eax),%edx
  800608:	89 55 14             	mov    %edx,0x14(%ebp)
  80060b:	8b 00                	mov    (%eax),%eax
  80060d:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800610:	89 c1                	mov    %eax,%ecx
  800612:	c1 f9 1f             	sar    $0x1f,%ecx
  800615:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800618:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80061b:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80061e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800623:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800627:	0f 89 90 00 00 00    	jns    8006bd <vprintfmt+0x376>
				putch('-', putdat);
  80062d:	83 ec 08             	sub    $0x8,%esp
  800630:	53                   	push   %ebx
  800631:	6a 2d                	push   $0x2d
  800633:	ff d6                	call   *%esi
				num = -(long long) num;
  800635:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800638:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80063b:	f7 d8                	neg    %eax
  80063d:	83 d2 00             	adc    $0x0,%edx
  800640:	f7 da                	neg    %edx
  800642:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800645:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80064a:	eb 71                	jmp    8006bd <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80064c:	8d 45 14             	lea    0x14(%ebp),%eax
  80064f:	e8 7f fc ff ff       	call   8002d3 <getuint>
			base = 10;
  800654:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800659:	eb 62                	jmp    8006bd <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80065b:	8d 45 14             	lea    0x14(%ebp),%eax
  80065e:	e8 70 fc ff ff       	call   8002d3 <getuint>
                        base = 8;
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
  800663:	83 ec 0c             	sub    $0xc,%esp
  800666:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
  80066a:	51                   	push   %ecx
  80066b:	ff 75 e0             	pushl  -0x20(%ebp)
  80066e:	6a 08                	push   $0x8
  800670:	52                   	push   %edx
  800671:	50                   	push   %eax
  800672:	89 da                	mov    %ebx,%edx
  800674:	89 f0                	mov    %esi,%eax
  800676:	e8 a9 fb ff ff       	call   800224 <printnum>
                        break;
  80067b:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80067e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
                        break;
  800681:	e9 e7 fc ff ff       	jmp    80036d <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800686:	83 ec 08             	sub    $0x8,%esp
  800689:	53                   	push   %ebx
  80068a:	6a 30                	push   $0x30
  80068c:	ff d6                	call   *%esi
			putch('x', putdat);
  80068e:	83 c4 08             	add    $0x8,%esp
  800691:	53                   	push   %ebx
  800692:	6a 78                	push   $0x78
  800694:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800696:	8b 45 14             	mov    0x14(%ebp),%eax
  800699:	8d 50 04             	lea    0x4(%eax),%edx
  80069c:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80069f:	8b 00                	mov    (%eax),%eax
  8006a1:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006a6:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006a9:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006ae:	eb 0d                	jmp    8006bd <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006b0:	8d 45 14             	lea    0x14(%ebp),%eax
  8006b3:	e8 1b fc ff ff       	call   8002d3 <getuint>
			base = 16;
  8006b8:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006bd:	83 ec 0c             	sub    $0xc,%esp
  8006c0:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006c4:	57                   	push   %edi
  8006c5:	ff 75 e0             	pushl  -0x20(%ebp)
  8006c8:	51                   	push   %ecx
  8006c9:	52                   	push   %edx
  8006ca:	50                   	push   %eax
  8006cb:	89 da                	mov    %ebx,%edx
  8006cd:	89 f0                	mov    %esi,%eax
  8006cf:	e8 50 fb ff ff       	call   800224 <printnum>
			break;
  8006d4:	83 c4 20             	add    $0x20,%esp
  8006d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006da:	e9 8e fc ff ff       	jmp    80036d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006df:	83 ec 08             	sub    $0x8,%esp
  8006e2:	53                   	push   %ebx
  8006e3:	51                   	push   %ecx
  8006e4:	ff d6                	call   *%esi
			break;
  8006e6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006e9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006ec:	e9 7c fc ff ff       	jmp    80036d <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006f1:	83 ec 08             	sub    $0x8,%esp
  8006f4:	53                   	push   %ebx
  8006f5:	6a 25                	push   $0x25
  8006f7:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006f9:	83 c4 10             	add    $0x10,%esp
  8006fc:	eb 03                	jmp    800701 <vprintfmt+0x3ba>
  8006fe:	83 ef 01             	sub    $0x1,%edi
  800701:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800705:	75 f7                	jne    8006fe <vprintfmt+0x3b7>
  800707:	e9 61 fc ff ff       	jmp    80036d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80070c:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80070f:	5b                   	pop    %ebx
  800710:	5e                   	pop    %esi
  800711:	5f                   	pop    %edi
  800712:	5d                   	pop    %ebp
  800713:	c3                   	ret    

00800714 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800714:	55                   	push   %ebp
  800715:	89 e5                	mov    %esp,%ebp
  800717:	83 ec 18             	sub    $0x18,%esp
  80071a:	8b 45 08             	mov    0x8(%ebp),%eax
  80071d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800720:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800723:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800727:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80072a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800731:	85 c0                	test   %eax,%eax
  800733:	74 26                	je     80075b <vsnprintf+0x47>
  800735:	85 d2                	test   %edx,%edx
  800737:	7e 22                	jle    80075b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800739:	ff 75 14             	pushl  0x14(%ebp)
  80073c:	ff 75 10             	pushl  0x10(%ebp)
  80073f:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800742:	50                   	push   %eax
  800743:	68 0d 03 80 00       	push   $0x80030d
  800748:	e8 fa fb ff ff       	call   800347 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80074d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800750:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800753:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800756:	83 c4 10             	add    $0x10,%esp
  800759:	eb 05                	jmp    800760 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80075b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800760:	c9                   	leave  
  800761:	c3                   	ret    

00800762 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800762:	55                   	push   %ebp
  800763:	89 e5                	mov    %esp,%ebp
  800765:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800768:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80076b:	50                   	push   %eax
  80076c:	ff 75 10             	pushl  0x10(%ebp)
  80076f:	ff 75 0c             	pushl  0xc(%ebp)
  800772:	ff 75 08             	pushl  0x8(%ebp)
  800775:	e8 9a ff ff ff       	call   800714 <vsnprintf>
	va_end(ap);

	return rc;
}
  80077a:	c9                   	leave  
  80077b:	c3                   	ret    

0080077c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80077c:	55                   	push   %ebp
  80077d:	89 e5                	mov    %esp,%ebp
  80077f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800782:	b8 00 00 00 00       	mov    $0x0,%eax
  800787:	eb 03                	jmp    80078c <strlen+0x10>
		n++;
  800789:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80078c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800790:	75 f7                	jne    800789 <strlen+0xd>
		n++;
	return n;
}
  800792:	5d                   	pop    %ebp
  800793:	c3                   	ret    

00800794 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800794:	55                   	push   %ebp
  800795:	89 e5                	mov    %esp,%ebp
  800797:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80079a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80079d:	ba 00 00 00 00       	mov    $0x0,%edx
  8007a2:	eb 03                	jmp    8007a7 <strnlen+0x13>
		n++;
  8007a4:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007a7:	39 c2                	cmp    %eax,%edx
  8007a9:	74 08                	je     8007b3 <strnlen+0x1f>
  8007ab:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007af:	75 f3                	jne    8007a4 <strnlen+0x10>
  8007b1:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007b3:	5d                   	pop    %ebp
  8007b4:	c3                   	ret    

008007b5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007b5:	55                   	push   %ebp
  8007b6:	89 e5                	mov    %esp,%ebp
  8007b8:	53                   	push   %ebx
  8007b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8007bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007bf:	89 c2                	mov    %eax,%edx
  8007c1:	83 c2 01             	add    $0x1,%edx
  8007c4:	83 c1 01             	add    $0x1,%ecx
  8007c7:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007cb:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007ce:	84 db                	test   %bl,%bl
  8007d0:	75 ef                	jne    8007c1 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007d2:	5b                   	pop    %ebx
  8007d3:	5d                   	pop    %ebp
  8007d4:	c3                   	ret    

008007d5 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007d5:	55                   	push   %ebp
  8007d6:	89 e5                	mov    %esp,%ebp
  8007d8:	53                   	push   %ebx
  8007d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007dc:	53                   	push   %ebx
  8007dd:	e8 9a ff ff ff       	call   80077c <strlen>
  8007e2:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007e5:	ff 75 0c             	pushl  0xc(%ebp)
  8007e8:	01 d8                	add    %ebx,%eax
  8007ea:	50                   	push   %eax
  8007eb:	e8 c5 ff ff ff       	call   8007b5 <strcpy>
	return dst;
}
  8007f0:	89 d8                	mov    %ebx,%eax
  8007f2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007f5:	c9                   	leave  
  8007f6:	c3                   	ret    

008007f7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007f7:	55                   	push   %ebp
  8007f8:	89 e5                	mov    %esp,%ebp
  8007fa:	56                   	push   %esi
  8007fb:	53                   	push   %ebx
  8007fc:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800802:	89 f3                	mov    %esi,%ebx
  800804:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800807:	89 f2                	mov    %esi,%edx
  800809:	eb 0f                	jmp    80081a <strncpy+0x23>
		*dst++ = *src;
  80080b:	83 c2 01             	add    $0x1,%edx
  80080e:	0f b6 01             	movzbl (%ecx),%eax
  800811:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800814:	80 39 01             	cmpb   $0x1,(%ecx)
  800817:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  80081a:	39 da                	cmp    %ebx,%edx
  80081c:	75 ed                	jne    80080b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80081e:	89 f0                	mov    %esi,%eax
  800820:	5b                   	pop    %ebx
  800821:	5e                   	pop    %esi
  800822:	5d                   	pop    %ebp
  800823:	c3                   	ret    

00800824 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800824:	55                   	push   %ebp
  800825:	89 e5                	mov    %esp,%ebp
  800827:	56                   	push   %esi
  800828:	53                   	push   %ebx
  800829:	8b 75 08             	mov    0x8(%ebp),%esi
  80082c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80082f:	8b 55 10             	mov    0x10(%ebp),%edx
  800832:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800834:	85 d2                	test   %edx,%edx
  800836:	74 21                	je     800859 <strlcpy+0x35>
  800838:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80083c:	89 f2                	mov    %esi,%edx
  80083e:	eb 09                	jmp    800849 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800840:	83 c2 01             	add    $0x1,%edx
  800843:	83 c1 01             	add    $0x1,%ecx
  800846:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800849:	39 c2                	cmp    %eax,%edx
  80084b:	74 09                	je     800856 <strlcpy+0x32>
  80084d:	0f b6 19             	movzbl (%ecx),%ebx
  800850:	84 db                	test   %bl,%bl
  800852:	75 ec                	jne    800840 <strlcpy+0x1c>
  800854:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800856:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800859:	29 f0                	sub    %esi,%eax
}
  80085b:	5b                   	pop    %ebx
  80085c:	5e                   	pop    %esi
  80085d:	5d                   	pop    %ebp
  80085e:	c3                   	ret    

0080085f <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80085f:	55                   	push   %ebp
  800860:	89 e5                	mov    %esp,%ebp
  800862:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800865:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800868:	eb 06                	jmp    800870 <strcmp+0x11>
		p++, q++;
  80086a:	83 c1 01             	add    $0x1,%ecx
  80086d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800870:	0f b6 01             	movzbl (%ecx),%eax
  800873:	84 c0                	test   %al,%al
  800875:	74 04                	je     80087b <strcmp+0x1c>
  800877:	3a 02                	cmp    (%edx),%al
  800879:	74 ef                	je     80086a <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80087b:	0f b6 c0             	movzbl %al,%eax
  80087e:	0f b6 12             	movzbl (%edx),%edx
  800881:	29 d0                	sub    %edx,%eax
}
  800883:	5d                   	pop    %ebp
  800884:	c3                   	ret    

00800885 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800885:	55                   	push   %ebp
  800886:	89 e5                	mov    %esp,%ebp
  800888:	53                   	push   %ebx
  800889:	8b 45 08             	mov    0x8(%ebp),%eax
  80088c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80088f:	89 c3                	mov    %eax,%ebx
  800891:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800894:	eb 06                	jmp    80089c <strncmp+0x17>
		n--, p++, q++;
  800896:	83 c0 01             	add    $0x1,%eax
  800899:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80089c:	39 d8                	cmp    %ebx,%eax
  80089e:	74 15                	je     8008b5 <strncmp+0x30>
  8008a0:	0f b6 08             	movzbl (%eax),%ecx
  8008a3:	84 c9                	test   %cl,%cl
  8008a5:	74 04                	je     8008ab <strncmp+0x26>
  8008a7:	3a 0a                	cmp    (%edx),%cl
  8008a9:	74 eb                	je     800896 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008ab:	0f b6 00             	movzbl (%eax),%eax
  8008ae:	0f b6 12             	movzbl (%edx),%edx
  8008b1:	29 d0                	sub    %edx,%eax
  8008b3:	eb 05                	jmp    8008ba <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008b5:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008ba:	5b                   	pop    %ebx
  8008bb:	5d                   	pop    %ebp
  8008bc:	c3                   	ret    

008008bd <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008bd:	55                   	push   %ebp
  8008be:	89 e5                	mov    %esp,%ebp
  8008c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c7:	eb 07                	jmp    8008d0 <strchr+0x13>
		if (*s == c)
  8008c9:	38 ca                	cmp    %cl,%dl
  8008cb:	74 0f                	je     8008dc <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008cd:	83 c0 01             	add    $0x1,%eax
  8008d0:	0f b6 10             	movzbl (%eax),%edx
  8008d3:	84 d2                	test   %dl,%dl
  8008d5:	75 f2                	jne    8008c9 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008dc:	5d                   	pop    %ebp
  8008dd:	c3                   	ret    

008008de <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008de:	55                   	push   %ebp
  8008df:	89 e5                	mov    %esp,%ebp
  8008e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008e8:	eb 03                	jmp    8008ed <strfind+0xf>
  8008ea:	83 c0 01             	add    $0x1,%eax
  8008ed:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008f0:	38 ca                	cmp    %cl,%dl
  8008f2:	74 04                	je     8008f8 <strfind+0x1a>
  8008f4:	84 d2                	test   %dl,%dl
  8008f6:	75 f2                	jne    8008ea <strfind+0xc>
			break;
	return (char *) s;
}
  8008f8:	5d                   	pop    %ebp
  8008f9:	c3                   	ret    

008008fa <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008fa:	55                   	push   %ebp
  8008fb:	89 e5                	mov    %esp,%ebp
  8008fd:	57                   	push   %edi
  8008fe:	56                   	push   %esi
  8008ff:	53                   	push   %ebx
  800900:	8b 7d 08             	mov    0x8(%ebp),%edi
  800903:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800906:	85 c9                	test   %ecx,%ecx
  800908:	74 36                	je     800940 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  80090a:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800910:	75 28                	jne    80093a <memset+0x40>
  800912:	f6 c1 03             	test   $0x3,%cl
  800915:	75 23                	jne    80093a <memset+0x40>
		c &= 0xFF;
  800917:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80091b:	89 d3                	mov    %edx,%ebx
  80091d:	c1 e3 08             	shl    $0x8,%ebx
  800920:	89 d6                	mov    %edx,%esi
  800922:	c1 e6 18             	shl    $0x18,%esi
  800925:	89 d0                	mov    %edx,%eax
  800927:	c1 e0 10             	shl    $0x10,%eax
  80092a:	09 f0                	or     %esi,%eax
  80092c:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80092e:	89 d8                	mov    %ebx,%eax
  800930:	09 d0                	or     %edx,%eax
  800932:	c1 e9 02             	shr    $0x2,%ecx
  800935:	fc                   	cld    
  800936:	f3 ab                	rep stos %eax,%es:(%edi)
  800938:	eb 06                	jmp    800940 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80093a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80093d:	fc                   	cld    
  80093e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800940:	89 f8                	mov    %edi,%eax
  800942:	5b                   	pop    %ebx
  800943:	5e                   	pop    %esi
  800944:	5f                   	pop    %edi
  800945:	5d                   	pop    %ebp
  800946:	c3                   	ret    

00800947 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800947:	55                   	push   %ebp
  800948:	89 e5                	mov    %esp,%ebp
  80094a:	57                   	push   %edi
  80094b:	56                   	push   %esi
  80094c:	8b 45 08             	mov    0x8(%ebp),%eax
  80094f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800952:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800955:	39 c6                	cmp    %eax,%esi
  800957:	73 35                	jae    80098e <memmove+0x47>
  800959:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80095c:	39 d0                	cmp    %edx,%eax
  80095e:	73 2e                	jae    80098e <memmove+0x47>
		s += n;
		d += n;
  800960:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800963:	89 d6                	mov    %edx,%esi
  800965:	09 fe                	or     %edi,%esi
  800967:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80096d:	75 13                	jne    800982 <memmove+0x3b>
  80096f:	f6 c1 03             	test   $0x3,%cl
  800972:	75 0e                	jne    800982 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800974:	83 ef 04             	sub    $0x4,%edi
  800977:	8d 72 fc             	lea    -0x4(%edx),%esi
  80097a:	c1 e9 02             	shr    $0x2,%ecx
  80097d:	fd                   	std    
  80097e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800980:	eb 09                	jmp    80098b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800982:	83 ef 01             	sub    $0x1,%edi
  800985:	8d 72 ff             	lea    -0x1(%edx),%esi
  800988:	fd                   	std    
  800989:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80098b:	fc                   	cld    
  80098c:	eb 1d                	jmp    8009ab <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80098e:	89 f2                	mov    %esi,%edx
  800990:	09 c2                	or     %eax,%edx
  800992:	f6 c2 03             	test   $0x3,%dl
  800995:	75 0f                	jne    8009a6 <memmove+0x5f>
  800997:	f6 c1 03             	test   $0x3,%cl
  80099a:	75 0a                	jne    8009a6 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80099c:	c1 e9 02             	shr    $0x2,%ecx
  80099f:	89 c7                	mov    %eax,%edi
  8009a1:	fc                   	cld    
  8009a2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009a4:	eb 05                	jmp    8009ab <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009a6:	89 c7                	mov    %eax,%edi
  8009a8:	fc                   	cld    
  8009a9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009ab:	5e                   	pop    %esi
  8009ac:	5f                   	pop    %edi
  8009ad:	5d                   	pop    %ebp
  8009ae:	c3                   	ret    

008009af <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009af:	55                   	push   %ebp
  8009b0:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009b2:	ff 75 10             	pushl  0x10(%ebp)
  8009b5:	ff 75 0c             	pushl  0xc(%ebp)
  8009b8:	ff 75 08             	pushl  0x8(%ebp)
  8009bb:	e8 87 ff ff ff       	call   800947 <memmove>
}
  8009c0:	c9                   	leave  
  8009c1:	c3                   	ret    

008009c2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009c2:	55                   	push   %ebp
  8009c3:	89 e5                	mov    %esp,%ebp
  8009c5:	56                   	push   %esi
  8009c6:	53                   	push   %ebx
  8009c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ca:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009cd:	89 c6                	mov    %eax,%esi
  8009cf:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d2:	eb 1a                	jmp    8009ee <memcmp+0x2c>
		if (*s1 != *s2)
  8009d4:	0f b6 08             	movzbl (%eax),%ecx
  8009d7:	0f b6 1a             	movzbl (%edx),%ebx
  8009da:	38 d9                	cmp    %bl,%cl
  8009dc:	74 0a                	je     8009e8 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009de:	0f b6 c1             	movzbl %cl,%eax
  8009e1:	0f b6 db             	movzbl %bl,%ebx
  8009e4:	29 d8                	sub    %ebx,%eax
  8009e6:	eb 0f                	jmp    8009f7 <memcmp+0x35>
		s1++, s2++;
  8009e8:	83 c0 01             	add    $0x1,%eax
  8009eb:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ee:	39 f0                	cmp    %esi,%eax
  8009f0:	75 e2                	jne    8009d4 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009f7:	5b                   	pop    %ebx
  8009f8:	5e                   	pop    %esi
  8009f9:	5d                   	pop    %ebp
  8009fa:	c3                   	ret    

008009fb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009fb:	55                   	push   %ebp
  8009fc:	89 e5                	mov    %esp,%ebp
  8009fe:	53                   	push   %ebx
  8009ff:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800a02:	89 c1                	mov    %eax,%ecx
  800a04:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a07:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a0b:	eb 0a                	jmp    800a17 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a0d:	0f b6 10             	movzbl (%eax),%edx
  800a10:	39 da                	cmp    %ebx,%edx
  800a12:	74 07                	je     800a1b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a14:	83 c0 01             	add    $0x1,%eax
  800a17:	39 c8                	cmp    %ecx,%eax
  800a19:	72 f2                	jb     800a0d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a1b:	5b                   	pop    %ebx
  800a1c:	5d                   	pop    %ebp
  800a1d:	c3                   	ret    

00800a1e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a1e:	55                   	push   %ebp
  800a1f:	89 e5                	mov    %esp,%ebp
  800a21:	57                   	push   %edi
  800a22:	56                   	push   %esi
  800a23:	53                   	push   %ebx
  800a24:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a27:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a2a:	eb 03                	jmp    800a2f <strtol+0x11>
		s++;
  800a2c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a2f:	0f b6 01             	movzbl (%ecx),%eax
  800a32:	3c 20                	cmp    $0x20,%al
  800a34:	74 f6                	je     800a2c <strtol+0xe>
  800a36:	3c 09                	cmp    $0x9,%al
  800a38:	74 f2                	je     800a2c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a3a:	3c 2b                	cmp    $0x2b,%al
  800a3c:	75 0a                	jne    800a48 <strtol+0x2a>
		s++;
  800a3e:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a41:	bf 00 00 00 00       	mov    $0x0,%edi
  800a46:	eb 11                	jmp    800a59 <strtol+0x3b>
  800a48:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a4d:	3c 2d                	cmp    $0x2d,%al
  800a4f:	75 08                	jne    800a59 <strtol+0x3b>
		s++, neg = 1;
  800a51:	83 c1 01             	add    $0x1,%ecx
  800a54:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a59:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a5f:	75 15                	jne    800a76 <strtol+0x58>
  800a61:	80 39 30             	cmpb   $0x30,(%ecx)
  800a64:	75 10                	jne    800a76 <strtol+0x58>
  800a66:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a6a:	75 7c                	jne    800ae8 <strtol+0xca>
		s += 2, base = 16;
  800a6c:	83 c1 02             	add    $0x2,%ecx
  800a6f:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a74:	eb 16                	jmp    800a8c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a76:	85 db                	test   %ebx,%ebx
  800a78:	75 12                	jne    800a8c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a7a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a7f:	80 39 30             	cmpb   $0x30,(%ecx)
  800a82:	75 08                	jne    800a8c <strtol+0x6e>
		s++, base = 8;
  800a84:	83 c1 01             	add    $0x1,%ecx
  800a87:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a8c:	b8 00 00 00 00       	mov    $0x0,%eax
  800a91:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a94:	0f b6 11             	movzbl (%ecx),%edx
  800a97:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a9a:	89 f3                	mov    %esi,%ebx
  800a9c:	80 fb 09             	cmp    $0x9,%bl
  800a9f:	77 08                	ja     800aa9 <strtol+0x8b>
			dig = *s - '0';
  800aa1:	0f be d2             	movsbl %dl,%edx
  800aa4:	83 ea 30             	sub    $0x30,%edx
  800aa7:	eb 22                	jmp    800acb <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aa9:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aac:	89 f3                	mov    %esi,%ebx
  800aae:	80 fb 19             	cmp    $0x19,%bl
  800ab1:	77 08                	ja     800abb <strtol+0x9d>
			dig = *s - 'a' + 10;
  800ab3:	0f be d2             	movsbl %dl,%edx
  800ab6:	83 ea 57             	sub    $0x57,%edx
  800ab9:	eb 10                	jmp    800acb <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800abb:	8d 72 bf             	lea    -0x41(%edx),%esi
  800abe:	89 f3                	mov    %esi,%ebx
  800ac0:	80 fb 19             	cmp    $0x19,%bl
  800ac3:	77 16                	ja     800adb <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ac5:	0f be d2             	movsbl %dl,%edx
  800ac8:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800acb:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ace:	7d 0b                	jge    800adb <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ad0:	83 c1 01             	add    $0x1,%ecx
  800ad3:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ad7:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ad9:	eb b9                	jmp    800a94 <strtol+0x76>

	if (endptr)
  800adb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800adf:	74 0d                	je     800aee <strtol+0xd0>
		*endptr = (char *) s;
  800ae1:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ae4:	89 0e                	mov    %ecx,(%esi)
  800ae6:	eb 06                	jmp    800aee <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ae8:	85 db                	test   %ebx,%ebx
  800aea:	74 98                	je     800a84 <strtol+0x66>
  800aec:	eb 9e                	jmp    800a8c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800aee:	89 c2                	mov    %eax,%edx
  800af0:	f7 da                	neg    %edx
  800af2:	85 ff                	test   %edi,%edi
  800af4:	0f 45 c2             	cmovne %edx,%eax
}
  800af7:	5b                   	pop    %ebx
  800af8:	5e                   	pop    %esi
  800af9:	5f                   	pop    %edi
  800afa:	5d                   	pop    %ebp
  800afb:	c3                   	ret    

00800afc <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800afc:	55                   	push   %ebp
  800afd:	89 e5                	mov    %esp,%ebp
  800aff:	57                   	push   %edi
  800b00:	56                   	push   %esi
  800b01:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b02:	b8 00 00 00 00       	mov    $0x0,%eax
  800b07:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b0a:	8b 55 08             	mov    0x8(%ebp),%edx
  800b0d:	89 c3                	mov    %eax,%ebx
  800b0f:	89 c7                	mov    %eax,%edi
  800b11:	89 c6                	mov    %eax,%esi
  800b13:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b15:	5b                   	pop    %ebx
  800b16:	5e                   	pop    %esi
  800b17:	5f                   	pop    %edi
  800b18:	5d                   	pop    %ebp
  800b19:	c3                   	ret    

00800b1a <sys_cgetc>:

int
sys_cgetc(void)
{
  800b1a:	55                   	push   %ebp
  800b1b:	89 e5                	mov    %esp,%ebp
  800b1d:	57                   	push   %edi
  800b1e:	56                   	push   %esi
  800b1f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b20:	ba 00 00 00 00       	mov    $0x0,%edx
  800b25:	b8 01 00 00 00       	mov    $0x1,%eax
  800b2a:	89 d1                	mov    %edx,%ecx
  800b2c:	89 d3                	mov    %edx,%ebx
  800b2e:	89 d7                	mov    %edx,%edi
  800b30:	89 d6                	mov    %edx,%esi
  800b32:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b34:	5b                   	pop    %ebx
  800b35:	5e                   	pop    %esi
  800b36:	5f                   	pop    %edi
  800b37:	5d                   	pop    %ebp
  800b38:	c3                   	ret    

00800b39 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b39:	55                   	push   %ebp
  800b3a:	89 e5                	mov    %esp,%ebp
  800b3c:	57                   	push   %edi
  800b3d:	56                   	push   %esi
  800b3e:	53                   	push   %ebx
  800b3f:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b42:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b47:	b8 03 00 00 00       	mov    $0x3,%eax
  800b4c:	8b 55 08             	mov    0x8(%ebp),%edx
  800b4f:	89 cb                	mov    %ecx,%ebx
  800b51:	89 cf                	mov    %ecx,%edi
  800b53:	89 ce                	mov    %ecx,%esi
  800b55:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b57:	85 c0                	test   %eax,%eax
  800b59:	7e 17                	jle    800b72 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b5b:	83 ec 0c             	sub    $0xc,%esp
  800b5e:	50                   	push   %eax
  800b5f:	6a 03                	push   $0x3
  800b61:	68 40 11 80 00       	push   $0x801140
  800b66:	6a 23                	push   $0x23
  800b68:	68 5d 11 80 00       	push   $0x80115d
  800b6d:	e8 c5 f5 ff ff       	call   800137 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b72:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b75:	5b                   	pop    %ebx
  800b76:	5e                   	pop    %esi
  800b77:	5f                   	pop    %edi
  800b78:	5d                   	pop    %ebp
  800b79:	c3                   	ret    

00800b7a <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b7a:	55                   	push   %ebp
  800b7b:	89 e5                	mov    %esp,%ebp
  800b7d:	57                   	push   %edi
  800b7e:	56                   	push   %esi
  800b7f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b80:	ba 00 00 00 00       	mov    $0x0,%edx
  800b85:	b8 02 00 00 00       	mov    $0x2,%eax
  800b8a:	89 d1                	mov    %edx,%ecx
  800b8c:	89 d3                	mov    %edx,%ebx
  800b8e:	89 d7                	mov    %edx,%edi
  800b90:	89 d6                	mov    %edx,%esi
  800b92:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b94:	5b                   	pop    %ebx
  800b95:	5e                   	pop    %esi
  800b96:	5f                   	pop    %edi
  800b97:	5d                   	pop    %ebp
  800b98:	c3                   	ret    
  800b99:	66 90                	xchg   %ax,%ax
  800b9b:	66 90                	xchg   %ax,%ax
  800b9d:	66 90                	xchg   %ax,%ax
  800b9f:	90                   	nop

00800ba0 <__udivdi3>:
  800ba0:	55                   	push   %ebp
  800ba1:	57                   	push   %edi
  800ba2:	56                   	push   %esi
  800ba3:	53                   	push   %ebx
  800ba4:	83 ec 1c             	sub    $0x1c,%esp
  800ba7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800bab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800baf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800bb3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800bb7:	85 f6                	test   %esi,%esi
  800bb9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800bbd:	89 ca                	mov    %ecx,%edx
  800bbf:	89 f8                	mov    %edi,%eax
  800bc1:	75 3d                	jne    800c00 <__udivdi3+0x60>
  800bc3:	39 cf                	cmp    %ecx,%edi
  800bc5:	0f 87 c5 00 00 00    	ja     800c90 <__udivdi3+0xf0>
  800bcb:	85 ff                	test   %edi,%edi
  800bcd:	89 fd                	mov    %edi,%ebp
  800bcf:	75 0b                	jne    800bdc <__udivdi3+0x3c>
  800bd1:	b8 01 00 00 00       	mov    $0x1,%eax
  800bd6:	31 d2                	xor    %edx,%edx
  800bd8:	f7 f7                	div    %edi
  800bda:	89 c5                	mov    %eax,%ebp
  800bdc:	89 c8                	mov    %ecx,%eax
  800bde:	31 d2                	xor    %edx,%edx
  800be0:	f7 f5                	div    %ebp
  800be2:	89 c1                	mov    %eax,%ecx
  800be4:	89 d8                	mov    %ebx,%eax
  800be6:	89 cf                	mov    %ecx,%edi
  800be8:	f7 f5                	div    %ebp
  800bea:	89 c3                	mov    %eax,%ebx
  800bec:	89 d8                	mov    %ebx,%eax
  800bee:	89 fa                	mov    %edi,%edx
  800bf0:	83 c4 1c             	add    $0x1c,%esp
  800bf3:	5b                   	pop    %ebx
  800bf4:	5e                   	pop    %esi
  800bf5:	5f                   	pop    %edi
  800bf6:	5d                   	pop    %ebp
  800bf7:	c3                   	ret    
  800bf8:	90                   	nop
  800bf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c00:	39 ce                	cmp    %ecx,%esi
  800c02:	77 74                	ja     800c78 <__udivdi3+0xd8>
  800c04:	0f bd fe             	bsr    %esi,%edi
  800c07:	83 f7 1f             	xor    $0x1f,%edi
  800c0a:	0f 84 98 00 00 00    	je     800ca8 <__udivdi3+0x108>
  800c10:	bb 20 00 00 00       	mov    $0x20,%ebx
  800c15:	89 f9                	mov    %edi,%ecx
  800c17:	89 c5                	mov    %eax,%ebp
  800c19:	29 fb                	sub    %edi,%ebx
  800c1b:	d3 e6                	shl    %cl,%esi
  800c1d:	89 d9                	mov    %ebx,%ecx
  800c1f:	d3 ed                	shr    %cl,%ebp
  800c21:	89 f9                	mov    %edi,%ecx
  800c23:	d3 e0                	shl    %cl,%eax
  800c25:	09 ee                	or     %ebp,%esi
  800c27:	89 d9                	mov    %ebx,%ecx
  800c29:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c2d:	89 d5                	mov    %edx,%ebp
  800c2f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c33:	d3 ed                	shr    %cl,%ebp
  800c35:	89 f9                	mov    %edi,%ecx
  800c37:	d3 e2                	shl    %cl,%edx
  800c39:	89 d9                	mov    %ebx,%ecx
  800c3b:	d3 e8                	shr    %cl,%eax
  800c3d:	09 c2                	or     %eax,%edx
  800c3f:	89 d0                	mov    %edx,%eax
  800c41:	89 ea                	mov    %ebp,%edx
  800c43:	f7 f6                	div    %esi
  800c45:	89 d5                	mov    %edx,%ebp
  800c47:	89 c3                	mov    %eax,%ebx
  800c49:	f7 64 24 0c          	mull   0xc(%esp)
  800c4d:	39 d5                	cmp    %edx,%ebp
  800c4f:	72 10                	jb     800c61 <__udivdi3+0xc1>
  800c51:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c55:	89 f9                	mov    %edi,%ecx
  800c57:	d3 e6                	shl    %cl,%esi
  800c59:	39 c6                	cmp    %eax,%esi
  800c5b:	73 07                	jae    800c64 <__udivdi3+0xc4>
  800c5d:	39 d5                	cmp    %edx,%ebp
  800c5f:	75 03                	jne    800c64 <__udivdi3+0xc4>
  800c61:	83 eb 01             	sub    $0x1,%ebx
  800c64:	31 ff                	xor    %edi,%edi
  800c66:	89 d8                	mov    %ebx,%eax
  800c68:	89 fa                	mov    %edi,%edx
  800c6a:	83 c4 1c             	add    $0x1c,%esp
  800c6d:	5b                   	pop    %ebx
  800c6e:	5e                   	pop    %esi
  800c6f:	5f                   	pop    %edi
  800c70:	5d                   	pop    %ebp
  800c71:	c3                   	ret    
  800c72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c78:	31 ff                	xor    %edi,%edi
  800c7a:	31 db                	xor    %ebx,%ebx
  800c7c:	89 d8                	mov    %ebx,%eax
  800c7e:	89 fa                	mov    %edi,%edx
  800c80:	83 c4 1c             	add    $0x1c,%esp
  800c83:	5b                   	pop    %ebx
  800c84:	5e                   	pop    %esi
  800c85:	5f                   	pop    %edi
  800c86:	5d                   	pop    %ebp
  800c87:	c3                   	ret    
  800c88:	90                   	nop
  800c89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c90:	89 d8                	mov    %ebx,%eax
  800c92:	f7 f7                	div    %edi
  800c94:	31 ff                	xor    %edi,%edi
  800c96:	89 c3                	mov    %eax,%ebx
  800c98:	89 d8                	mov    %ebx,%eax
  800c9a:	89 fa                	mov    %edi,%edx
  800c9c:	83 c4 1c             	add    $0x1c,%esp
  800c9f:	5b                   	pop    %ebx
  800ca0:	5e                   	pop    %esi
  800ca1:	5f                   	pop    %edi
  800ca2:	5d                   	pop    %ebp
  800ca3:	c3                   	ret    
  800ca4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ca8:	39 ce                	cmp    %ecx,%esi
  800caa:	72 0c                	jb     800cb8 <__udivdi3+0x118>
  800cac:	31 db                	xor    %ebx,%ebx
  800cae:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800cb2:	0f 87 34 ff ff ff    	ja     800bec <__udivdi3+0x4c>
  800cb8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800cbd:	e9 2a ff ff ff       	jmp    800bec <__udivdi3+0x4c>
  800cc2:	66 90                	xchg   %ax,%ax
  800cc4:	66 90                	xchg   %ax,%ax
  800cc6:	66 90                	xchg   %ax,%ax
  800cc8:	66 90                	xchg   %ax,%ax
  800cca:	66 90                	xchg   %ax,%ax
  800ccc:	66 90                	xchg   %ax,%ax
  800cce:	66 90                	xchg   %ax,%ax

00800cd0 <__umoddi3>:
  800cd0:	55                   	push   %ebp
  800cd1:	57                   	push   %edi
  800cd2:	56                   	push   %esi
  800cd3:	53                   	push   %ebx
  800cd4:	83 ec 1c             	sub    $0x1c,%esp
  800cd7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800cdb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800cdf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800ce3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ce7:	85 d2                	test   %edx,%edx
  800ce9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800ced:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800cf1:	89 f3                	mov    %esi,%ebx
  800cf3:	89 3c 24             	mov    %edi,(%esp)
  800cf6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cfa:	75 1c                	jne    800d18 <__umoddi3+0x48>
  800cfc:	39 f7                	cmp    %esi,%edi
  800cfe:	76 50                	jbe    800d50 <__umoddi3+0x80>
  800d00:	89 c8                	mov    %ecx,%eax
  800d02:	89 f2                	mov    %esi,%edx
  800d04:	f7 f7                	div    %edi
  800d06:	89 d0                	mov    %edx,%eax
  800d08:	31 d2                	xor    %edx,%edx
  800d0a:	83 c4 1c             	add    $0x1c,%esp
  800d0d:	5b                   	pop    %ebx
  800d0e:	5e                   	pop    %esi
  800d0f:	5f                   	pop    %edi
  800d10:	5d                   	pop    %ebp
  800d11:	c3                   	ret    
  800d12:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d18:	39 f2                	cmp    %esi,%edx
  800d1a:	89 d0                	mov    %edx,%eax
  800d1c:	77 52                	ja     800d70 <__umoddi3+0xa0>
  800d1e:	0f bd ea             	bsr    %edx,%ebp
  800d21:	83 f5 1f             	xor    $0x1f,%ebp
  800d24:	75 5a                	jne    800d80 <__umoddi3+0xb0>
  800d26:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d2a:	0f 82 e0 00 00 00    	jb     800e10 <__umoddi3+0x140>
  800d30:	39 0c 24             	cmp    %ecx,(%esp)
  800d33:	0f 86 d7 00 00 00    	jbe    800e10 <__umoddi3+0x140>
  800d39:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d3d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d41:	83 c4 1c             	add    $0x1c,%esp
  800d44:	5b                   	pop    %ebx
  800d45:	5e                   	pop    %esi
  800d46:	5f                   	pop    %edi
  800d47:	5d                   	pop    %ebp
  800d48:	c3                   	ret    
  800d49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d50:	85 ff                	test   %edi,%edi
  800d52:	89 fd                	mov    %edi,%ebp
  800d54:	75 0b                	jne    800d61 <__umoddi3+0x91>
  800d56:	b8 01 00 00 00       	mov    $0x1,%eax
  800d5b:	31 d2                	xor    %edx,%edx
  800d5d:	f7 f7                	div    %edi
  800d5f:	89 c5                	mov    %eax,%ebp
  800d61:	89 f0                	mov    %esi,%eax
  800d63:	31 d2                	xor    %edx,%edx
  800d65:	f7 f5                	div    %ebp
  800d67:	89 c8                	mov    %ecx,%eax
  800d69:	f7 f5                	div    %ebp
  800d6b:	89 d0                	mov    %edx,%eax
  800d6d:	eb 99                	jmp    800d08 <__umoddi3+0x38>
  800d6f:	90                   	nop
  800d70:	89 c8                	mov    %ecx,%eax
  800d72:	89 f2                	mov    %esi,%edx
  800d74:	83 c4 1c             	add    $0x1c,%esp
  800d77:	5b                   	pop    %ebx
  800d78:	5e                   	pop    %esi
  800d79:	5f                   	pop    %edi
  800d7a:	5d                   	pop    %ebp
  800d7b:	c3                   	ret    
  800d7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d80:	8b 34 24             	mov    (%esp),%esi
  800d83:	bf 20 00 00 00       	mov    $0x20,%edi
  800d88:	89 e9                	mov    %ebp,%ecx
  800d8a:	29 ef                	sub    %ebp,%edi
  800d8c:	d3 e0                	shl    %cl,%eax
  800d8e:	89 f9                	mov    %edi,%ecx
  800d90:	89 f2                	mov    %esi,%edx
  800d92:	d3 ea                	shr    %cl,%edx
  800d94:	89 e9                	mov    %ebp,%ecx
  800d96:	09 c2                	or     %eax,%edx
  800d98:	89 d8                	mov    %ebx,%eax
  800d9a:	89 14 24             	mov    %edx,(%esp)
  800d9d:	89 f2                	mov    %esi,%edx
  800d9f:	d3 e2                	shl    %cl,%edx
  800da1:	89 f9                	mov    %edi,%ecx
  800da3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800da7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800dab:	d3 e8                	shr    %cl,%eax
  800dad:	89 e9                	mov    %ebp,%ecx
  800daf:	89 c6                	mov    %eax,%esi
  800db1:	d3 e3                	shl    %cl,%ebx
  800db3:	89 f9                	mov    %edi,%ecx
  800db5:	89 d0                	mov    %edx,%eax
  800db7:	d3 e8                	shr    %cl,%eax
  800db9:	89 e9                	mov    %ebp,%ecx
  800dbb:	09 d8                	or     %ebx,%eax
  800dbd:	89 d3                	mov    %edx,%ebx
  800dbf:	89 f2                	mov    %esi,%edx
  800dc1:	f7 34 24             	divl   (%esp)
  800dc4:	89 d6                	mov    %edx,%esi
  800dc6:	d3 e3                	shl    %cl,%ebx
  800dc8:	f7 64 24 04          	mull   0x4(%esp)
  800dcc:	39 d6                	cmp    %edx,%esi
  800dce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800dd2:	89 d1                	mov    %edx,%ecx
  800dd4:	89 c3                	mov    %eax,%ebx
  800dd6:	72 08                	jb     800de0 <__umoddi3+0x110>
  800dd8:	75 11                	jne    800deb <__umoddi3+0x11b>
  800dda:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dde:	73 0b                	jae    800deb <__umoddi3+0x11b>
  800de0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800de4:	1b 14 24             	sbb    (%esp),%edx
  800de7:	89 d1                	mov    %edx,%ecx
  800de9:	89 c3                	mov    %eax,%ebx
  800deb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800def:	29 da                	sub    %ebx,%edx
  800df1:	19 ce                	sbb    %ecx,%esi
  800df3:	89 f9                	mov    %edi,%ecx
  800df5:	89 f0                	mov    %esi,%eax
  800df7:	d3 e0                	shl    %cl,%eax
  800df9:	89 e9                	mov    %ebp,%ecx
  800dfb:	d3 ea                	shr    %cl,%edx
  800dfd:	89 e9                	mov    %ebp,%ecx
  800dff:	d3 ee                	shr    %cl,%esi
  800e01:	09 d0                	or     %edx,%eax
  800e03:	89 f2                	mov    %esi,%edx
  800e05:	83 c4 1c             	add    $0x1c,%esp
  800e08:	5b                   	pop    %ebx
  800e09:	5e                   	pop    %esi
  800e0a:	5f                   	pop    %edi
  800e0b:	5d                   	pop    %ebp
  800e0c:	c3                   	ret    
  800e0d:	8d 76 00             	lea    0x0(%esi),%esi
  800e10:	29 f9                	sub    %edi,%ecx
  800e12:	19 d6                	sbb    %edx,%esi
  800e14:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e18:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e1c:	e9 18 ff ff ff       	jmp    800d39 <__umoddi3+0x69>
