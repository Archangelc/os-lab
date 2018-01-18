
obj/user/breakpoint:     file format elf32-i386


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
  80002c:	e8 08 00 00 00       	call   800039 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $3");
  800036:	cc                   	int3   
}
  800037:	5d                   	pop    %ebp
  800038:	c3                   	ret    

00800039 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800039:	55                   	push   %ebp
  80003a:	89 e5                	mov    %esp,%ebp
  80003c:	56                   	push   %esi
  80003d:	53                   	push   %ebx
  80003e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800041:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
thisenv = &envs[ENVX(sys_getenvid())];
  800044:	e8 c9 00 00 00       	call   800112 <sys_getenvid>
  800049:	25 ff 03 00 00       	and    $0x3ff,%eax
  80004e:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800051:	c1 e0 05             	shl    $0x5,%eax
  800054:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800059:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005e:	85 db                	test   %ebx,%ebx
  800060:	7e 07                	jle    800069 <libmain+0x30>
		binaryname = argv[0];
  800062:	8b 06                	mov    (%esi),%eax
  800064:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800069:	83 ec 08             	sub    $0x8,%esp
  80006c:	56                   	push   %esi
  80006d:	53                   	push   %ebx
  80006e:	e8 c0 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800073:	e8 0a 00 00 00       	call   800082 <exit>
}
  800078:	83 c4 10             	add    $0x10,%esp
  80007b:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80007e:	5b                   	pop    %ebx
  80007f:	5e                   	pop    %esi
  800080:	5d                   	pop    %ebp
  800081:	c3                   	ret    

00800082 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800082:	55                   	push   %ebp
  800083:	89 e5                	mov    %esp,%ebp
  800085:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800088:	6a 00                	push   $0x0
  80008a:	e8 42 00 00 00       	call   8000d1 <sys_env_destroy>
}
  80008f:	83 c4 10             	add    $0x10,%esp
  800092:	c9                   	leave  
  800093:	c3                   	ret    

00800094 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	57                   	push   %edi
  800098:	56                   	push   %esi
  800099:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009a:	b8 00 00 00 00       	mov    $0x0,%eax
  80009f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a5:	89 c3                	mov    %eax,%ebx
  8000a7:	89 c7                	mov    %eax,%edi
  8000a9:	89 c6                	mov    %eax,%esi
  8000ab:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ad:	5b                   	pop    %ebx
  8000ae:	5e                   	pop    %esi
  8000af:	5f                   	pop    %edi
  8000b0:	5d                   	pop    %ebp
  8000b1:	c3                   	ret    

008000b2 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b2:	55                   	push   %ebp
  8000b3:	89 e5                	mov    %esp,%ebp
  8000b5:	57                   	push   %edi
  8000b6:	56                   	push   %esi
  8000b7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b8:	ba 00 00 00 00       	mov    $0x0,%edx
  8000bd:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c2:	89 d1                	mov    %edx,%ecx
  8000c4:	89 d3                	mov    %edx,%ebx
  8000c6:	89 d7                	mov    %edx,%edi
  8000c8:	89 d6                	mov    %edx,%esi
  8000ca:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000cc:	5b                   	pop    %ebx
  8000cd:	5e                   	pop    %esi
  8000ce:	5f                   	pop    %edi
  8000cf:	5d                   	pop    %ebp
  8000d0:	c3                   	ret    

008000d1 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000d1:	55                   	push   %ebp
  8000d2:	89 e5                	mov    %esp,%ebp
  8000d4:	57                   	push   %edi
  8000d5:	56                   	push   %esi
  8000d6:	53                   	push   %ebx
  8000d7:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000da:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000df:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e4:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e7:	89 cb                	mov    %ecx,%ebx
  8000e9:	89 cf                	mov    %ecx,%edi
  8000eb:	89 ce                	mov    %ecx,%esi
  8000ed:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000ef:	85 c0                	test   %eax,%eax
  8000f1:	7e 17                	jle    80010a <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f3:	83 ec 0c             	sub    $0xc,%esp
  8000f6:	50                   	push   %eax
  8000f7:	6a 03                	push   $0x3
  8000f9:	68 aa 0d 80 00       	push   $0x800daa
  8000fe:	6a 23                	push   $0x23
  800100:	68 c7 0d 80 00       	push   $0x800dc7
  800105:	e8 27 00 00 00       	call   800131 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80010a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80010d:	5b                   	pop    %ebx
  80010e:	5e                   	pop    %esi
  80010f:	5f                   	pop    %edi
  800110:	5d                   	pop    %ebp
  800111:	c3                   	ret    

00800112 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800112:	55                   	push   %ebp
  800113:	89 e5                	mov    %esp,%ebp
  800115:	57                   	push   %edi
  800116:	56                   	push   %esi
  800117:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800118:	ba 00 00 00 00       	mov    $0x0,%edx
  80011d:	b8 02 00 00 00       	mov    $0x2,%eax
  800122:	89 d1                	mov    %edx,%ecx
  800124:	89 d3                	mov    %edx,%ebx
  800126:	89 d7                	mov    %edx,%edi
  800128:	89 d6                	mov    %edx,%esi
  80012a:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80012c:	5b                   	pop    %ebx
  80012d:	5e                   	pop    %esi
  80012e:	5f                   	pop    %edi
  80012f:	5d                   	pop    %ebp
  800130:	c3                   	ret    

00800131 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800131:	55                   	push   %ebp
  800132:	89 e5                	mov    %esp,%ebp
  800134:	56                   	push   %esi
  800135:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800136:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800139:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80013f:	e8 ce ff ff ff       	call   800112 <sys_getenvid>
  800144:	83 ec 0c             	sub    $0xc,%esp
  800147:	ff 75 0c             	pushl  0xc(%ebp)
  80014a:	ff 75 08             	pushl  0x8(%ebp)
  80014d:	56                   	push   %esi
  80014e:	50                   	push   %eax
  80014f:	68 d8 0d 80 00       	push   $0x800dd8
  800154:	e8 b1 00 00 00       	call   80020a <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800159:	83 c4 18             	add    $0x18,%esp
  80015c:	53                   	push   %ebx
  80015d:	ff 75 10             	pushl  0x10(%ebp)
  800160:	e8 54 00 00 00       	call   8001b9 <vcprintf>
	cprintf("\n");
  800165:	c7 04 24 fc 0d 80 00 	movl   $0x800dfc,(%esp)
  80016c:	e8 99 00 00 00       	call   80020a <cprintf>
  800171:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800174:	cc                   	int3   
  800175:	eb fd                	jmp    800174 <_panic+0x43>

00800177 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800177:	55                   	push   %ebp
  800178:	89 e5                	mov    %esp,%ebp
  80017a:	53                   	push   %ebx
  80017b:	83 ec 04             	sub    $0x4,%esp
  80017e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800181:	8b 13                	mov    (%ebx),%edx
  800183:	8d 42 01             	lea    0x1(%edx),%eax
  800186:	89 03                	mov    %eax,(%ebx)
  800188:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80018b:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80018f:	3d ff 00 00 00       	cmp    $0xff,%eax
  800194:	75 1a                	jne    8001b0 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800196:	83 ec 08             	sub    $0x8,%esp
  800199:	68 ff 00 00 00       	push   $0xff
  80019e:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a1:	50                   	push   %eax
  8001a2:	e8 ed fe ff ff       	call   800094 <sys_cputs>
		b->idx = 0;
  8001a7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001ad:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b0:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001b4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b7:	c9                   	leave  
  8001b8:	c3                   	ret    

008001b9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001b9:	55                   	push   %ebp
  8001ba:	89 e5                	mov    %esp,%ebp
  8001bc:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c2:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001c9:	00 00 00 
	b.cnt = 0;
  8001cc:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d3:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d6:	ff 75 0c             	pushl  0xc(%ebp)
  8001d9:	ff 75 08             	pushl  0x8(%ebp)
  8001dc:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e2:	50                   	push   %eax
  8001e3:	68 77 01 80 00       	push   $0x800177
  8001e8:	e8 54 01 00 00       	call   800341 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001ed:	83 c4 08             	add    $0x8,%esp
  8001f0:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f6:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001fc:	50                   	push   %eax
  8001fd:	e8 92 fe ff ff       	call   800094 <sys_cputs>

	return b.cnt;
}
  800202:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800208:	c9                   	leave  
  800209:	c3                   	ret    

0080020a <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80020a:	55                   	push   %ebp
  80020b:	89 e5                	mov    %esp,%ebp
  80020d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800210:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800213:	50                   	push   %eax
  800214:	ff 75 08             	pushl  0x8(%ebp)
  800217:	e8 9d ff ff ff       	call   8001b9 <vcprintf>
	va_end(ap);

	return cnt;
}
  80021c:	c9                   	leave  
  80021d:	c3                   	ret    

0080021e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80021e:	55                   	push   %ebp
  80021f:	89 e5                	mov    %esp,%ebp
  800221:	57                   	push   %edi
  800222:	56                   	push   %esi
  800223:	53                   	push   %ebx
  800224:	83 ec 1c             	sub    $0x1c,%esp
  800227:	89 c7                	mov    %eax,%edi
  800229:	89 d6                	mov    %edx,%esi
  80022b:	8b 45 08             	mov    0x8(%ebp),%eax
  80022e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800231:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800234:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800237:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80023a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800242:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800245:	39 d3                	cmp    %edx,%ebx
  800247:	72 05                	jb     80024e <printnum+0x30>
  800249:	39 45 10             	cmp    %eax,0x10(%ebp)
  80024c:	77 45                	ja     800293 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80024e:	83 ec 0c             	sub    $0xc,%esp
  800251:	ff 75 18             	pushl  0x18(%ebp)
  800254:	8b 45 14             	mov    0x14(%ebp),%eax
  800257:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80025a:	53                   	push   %ebx
  80025b:	ff 75 10             	pushl  0x10(%ebp)
  80025e:	83 ec 08             	sub    $0x8,%esp
  800261:	ff 75 e4             	pushl  -0x1c(%ebp)
  800264:	ff 75 e0             	pushl  -0x20(%ebp)
  800267:	ff 75 dc             	pushl  -0x24(%ebp)
  80026a:	ff 75 d8             	pushl  -0x28(%ebp)
  80026d:	e8 8e 08 00 00       	call   800b00 <__udivdi3>
  800272:	83 c4 18             	add    $0x18,%esp
  800275:	52                   	push   %edx
  800276:	50                   	push   %eax
  800277:	89 f2                	mov    %esi,%edx
  800279:	89 f8                	mov    %edi,%eax
  80027b:	e8 9e ff ff ff       	call   80021e <printnum>
  800280:	83 c4 20             	add    $0x20,%esp
  800283:	eb 18                	jmp    80029d <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800285:	83 ec 08             	sub    $0x8,%esp
  800288:	56                   	push   %esi
  800289:	ff 75 18             	pushl  0x18(%ebp)
  80028c:	ff d7                	call   *%edi
  80028e:	83 c4 10             	add    $0x10,%esp
  800291:	eb 03                	jmp    800296 <printnum+0x78>
  800293:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800296:	83 eb 01             	sub    $0x1,%ebx
  800299:	85 db                	test   %ebx,%ebx
  80029b:	7f e8                	jg     800285 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80029d:	83 ec 08             	sub    $0x8,%esp
  8002a0:	56                   	push   %esi
  8002a1:	83 ec 04             	sub    $0x4,%esp
  8002a4:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a7:	ff 75 e0             	pushl  -0x20(%ebp)
  8002aa:	ff 75 dc             	pushl  -0x24(%ebp)
  8002ad:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b0:	e8 7b 09 00 00       	call   800c30 <__umoddi3>
  8002b5:	83 c4 14             	add    $0x14,%esp
  8002b8:	0f be 80 fe 0d 80 00 	movsbl 0x800dfe(%eax),%eax
  8002bf:	50                   	push   %eax
  8002c0:	ff d7                	call   *%edi
}
  8002c2:	83 c4 10             	add    $0x10,%esp
  8002c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c8:	5b                   	pop    %ebx
  8002c9:	5e                   	pop    %esi
  8002ca:	5f                   	pop    %edi
  8002cb:	5d                   	pop    %ebp
  8002cc:	c3                   	ret    

008002cd <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002cd:	55                   	push   %ebp
  8002ce:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d0:	83 fa 01             	cmp    $0x1,%edx
  8002d3:	7e 0e                	jle    8002e3 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002d5:	8b 10                	mov    (%eax),%edx
  8002d7:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002da:	89 08                	mov    %ecx,(%eax)
  8002dc:	8b 02                	mov    (%edx),%eax
  8002de:	8b 52 04             	mov    0x4(%edx),%edx
  8002e1:	eb 22                	jmp    800305 <getuint+0x38>
	else if (lflag)
  8002e3:	85 d2                	test   %edx,%edx
  8002e5:	74 10                	je     8002f7 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002e7:	8b 10                	mov    (%eax),%edx
  8002e9:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ec:	89 08                	mov    %ecx,(%eax)
  8002ee:	8b 02                	mov    (%edx),%eax
  8002f0:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f5:	eb 0e                	jmp    800305 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002f7:	8b 10                	mov    (%eax),%edx
  8002f9:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002fc:	89 08                	mov    %ecx,(%eax)
  8002fe:	8b 02                	mov    (%edx),%eax
  800300:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800305:	5d                   	pop    %ebp
  800306:	c3                   	ret    

00800307 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800307:	55                   	push   %ebp
  800308:	89 e5                	mov    %esp,%ebp
  80030a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80030d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800311:	8b 10                	mov    (%eax),%edx
  800313:	3b 50 04             	cmp    0x4(%eax),%edx
  800316:	73 0a                	jae    800322 <sprintputch+0x1b>
		*b->buf++ = ch;
  800318:	8d 4a 01             	lea    0x1(%edx),%ecx
  80031b:	89 08                	mov    %ecx,(%eax)
  80031d:	8b 45 08             	mov    0x8(%ebp),%eax
  800320:	88 02                	mov    %al,(%edx)
}
  800322:	5d                   	pop    %ebp
  800323:	c3                   	ret    

00800324 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800324:	55                   	push   %ebp
  800325:	89 e5                	mov    %esp,%ebp
  800327:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80032a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80032d:	50                   	push   %eax
  80032e:	ff 75 10             	pushl  0x10(%ebp)
  800331:	ff 75 0c             	pushl  0xc(%ebp)
  800334:	ff 75 08             	pushl  0x8(%ebp)
  800337:	e8 05 00 00 00       	call   800341 <vprintfmt>
	va_end(ap);
}
  80033c:	83 c4 10             	add    $0x10,%esp
  80033f:	c9                   	leave  
  800340:	c3                   	ret    

00800341 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800341:	55                   	push   %ebp
  800342:	89 e5                	mov    %esp,%ebp
  800344:	57                   	push   %edi
  800345:	56                   	push   %esi
  800346:	53                   	push   %ebx
  800347:	83 ec 2c             	sub    $0x2c,%esp
  80034a:	8b 75 08             	mov    0x8(%ebp),%esi
  80034d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800350:	8b 7d 10             	mov    0x10(%ebp),%edi
  800353:	eb 12                	jmp    800367 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800355:	85 c0                	test   %eax,%eax
  800357:	0f 84 a9 03 00 00    	je     800706 <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
  80035d:	83 ec 08             	sub    $0x8,%esp
  800360:	53                   	push   %ebx
  800361:	50                   	push   %eax
  800362:	ff d6                	call   *%esi
  800364:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800367:	83 c7 01             	add    $0x1,%edi
  80036a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80036e:	83 f8 25             	cmp    $0x25,%eax
  800371:	75 e2                	jne    800355 <vprintfmt+0x14>
  800373:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800377:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80037e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800385:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80038c:	ba 00 00 00 00       	mov    $0x0,%edx
  800391:	eb 07                	jmp    80039a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800393:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800396:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039a:	8d 47 01             	lea    0x1(%edi),%eax
  80039d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003a0:	0f b6 07             	movzbl (%edi),%eax
  8003a3:	0f b6 c8             	movzbl %al,%ecx
  8003a6:	83 e8 23             	sub    $0x23,%eax
  8003a9:	3c 55                	cmp    $0x55,%al
  8003ab:	0f 87 3a 03 00 00    	ja     8006eb <vprintfmt+0x3aa>
  8003b1:	0f b6 c0             	movzbl %al,%eax
  8003b4:	ff 24 85 a0 0e 80 00 	jmp    *0x800ea0(,%eax,4)
  8003bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003be:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003c2:	eb d6                	jmp    80039a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c7:	b8 00 00 00 00       	mov    $0x0,%eax
  8003cc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003cf:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003d2:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003d6:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003d9:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003dc:	83 fa 09             	cmp    $0x9,%edx
  8003df:	77 39                	ja     80041a <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003e1:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003e4:	eb e9                	jmp    8003cf <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e9:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ec:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003ef:	8b 00                	mov    (%eax),%eax
  8003f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003f7:	eb 27                	jmp    800420 <vprintfmt+0xdf>
  8003f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003fc:	85 c0                	test   %eax,%eax
  8003fe:	b9 00 00 00 00       	mov    $0x0,%ecx
  800403:	0f 49 c8             	cmovns %eax,%ecx
  800406:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80040c:	eb 8c                	jmp    80039a <vprintfmt+0x59>
  80040e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800411:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800418:	eb 80                	jmp    80039a <vprintfmt+0x59>
  80041a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80041d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800420:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800424:	0f 89 70 ff ff ff    	jns    80039a <vprintfmt+0x59>
				width = precision, precision = -1;
  80042a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80042d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800430:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800437:	e9 5e ff ff ff       	jmp    80039a <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80043c:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800442:	e9 53 ff ff ff       	jmp    80039a <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800447:	8b 45 14             	mov    0x14(%ebp),%eax
  80044a:	8d 50 04             	lea    0x4(%eax),%edx
  80044d:	89 55 14             	mov    %edx,0x14(%ebp)
  800450:	83 ec 08             	sub    $0x8,%esp
  800453:	53                   	push   %ebx
  800454:	ff 30                	pushl  (%eax)
  800456:	ff d6                	call   *%esi
			break;
  800458:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80045e:	e9 04 ff ff ff       	jmp    800367 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800463:	8b 45 14             	mov    0x14(%ebp),%eax
  800466:	8d 50 04             	lea    0x4(%eax),%edx
  800469:	89 55 14             	mov    %edx,0x14(%ebp)
  80046c:	8b 00                	mov    (%eax),%eax
  80046e:	99                   	cltd   
  80046f:	31 d0                	xor    %edx,%eax
  800471:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800473:	83 f8 07             	cmp    $0x7,%eax
  800476:	7f 0b                	jg     800483 <vprintfmt+0x142>
  800478:	8b 14 85 00 10 80 00 	mov    0x801000(,%eax,4),%edx
  80047f:	85 d2                	test   %edx,%edx
  800481:	75 18                	jne    80049b <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800483:	50                   	push   %eax
  800484:	68 16 0e 80 00       	push   $0x800e16
  800489:	53                   	push   %ebx
  80048a:	56                   	push   %esi
  80048b:	e8 94 fe ff ff       	call   800324 <printfmt>
  800490:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800493:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800496:	e9 cc fe ff ff       	jmp    800367 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80049b:	52                   	push   %edx
  80049c:	68 1f 0e 80 00       	push   $0x800e1f
  8004a1:	53                   	push   %ebx
  8004a2:	56                   	push   %esi
  8004a3:	e8 7c fe ff ff       	call   800324 <printfmt>
  8004a8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004ae:	e9 b4 fe ff ff       	jmp    800367 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b3:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b6:	8d 50 04             	lea    0x4(%eax),%edx
  8004b9:	89 55 14             	mov    %edx,0x14(%ebp)
  8004bc:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004be:	85 ff                	test   %edi,%edi
  8004c0:	b8 0f 0e 80 00       	mov    $0x800e0f,%eax
  8004c5:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004c8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004cc:	0f 8e 94 00 00 00    	jle    800566 <vprintfmt+0x225>
  8004d2:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004d6:	0f 84 98 00 00 00    	je     800574 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004dc:	83 ec 08             	sub    $0x8,%esp
  8004df:	ff 75 d0             	pushl  -0x30(%ebp)
  8004e2:	57                   	push   %edi
  8004e3:	e8 a6 02 00 00       	call   80078e <strnlen>
  8004e8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004eb:	29 c1                	sub    %eax,%ecx
  8004ed:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004f0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004f3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004fa:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004fd:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ff:	eb 0f                	jmp    800510 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800501:	83 ec 08             	sub    $0x8,%esp
  800504:	53                   	push   %ebx
  800505:	ff 75 e0             	pushl  -0x20(%ebp)
  800508:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80050a:	83 ef 01             	sub    $0x1,%edi
  80050d:	83 c4 10             	add    $0x10,%esp
  800510:	85 ff                	test   %edi,%edi
  800512:	7f ed                	jg     800501 <vprintfmt+0x1c0>
  800514:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800517:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80051a:	85 c9                	test   %ecx,%ecx
  80051c:	b8 00 00 00 00       	mov    $0x0,%eax
  800521:	0f 49 c1             	cmovns %ecx,%eax
  800524:	29 c1                	sub    %eax,%ecx
  800526:	89 75 08             	mov    %esi,0x8(%ebp)
  800529:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052f:	89 cb                	mov    %ecx,%ebx
  800531:	eb 4d                	jmp    800580 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800533:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800537:	74 1b                	je     800554 <vprintfmt+0x213>
  800539:	0f be c0             	movsbl %al,%eax
  80053c:	83 e8 20             	sub    $0x20,%eax
  80053f:	83 f8 5e             	cmp    $0x5e,%eax
  800542:	76 10                	jbe    800554 <vprintfmt+0x213>
					putch('?', putdat);
  800544:	83 ec 08             	sub    $0x8,%esp
  800547:	ff 75 0c             	pushl  0xc(%ebp)
  80054a:	6a 3f                	push   $0x3f
  80054c:	ff 55 08             	call   *0x8(%ebp)
  80054f:	83 c4 10             	add    $0x10,%esp
  800552:	eb 0d                	jmp    800561 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800554:	83 ec 08             	sub    $0x8,%esp
  800557:	ff 75 0c             	pushl  0xc(%ebp)
  80055a:	52                   	push   %edx
  80055b:	ff 55 08             	call   *0x8(%ebp)
  80055e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800561:	83 eb 01             	sub    $0x1,%ebx
  800564:	eb 1a                	jmp    800580 <vprintfmt+0x23f>
  800566:	89 75 08             	mov    %esi,0x8(%ebp)
  800569:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80056c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80056f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800572:	eb 0c                	jmp    800580 <vprintfmt+0x23f>
  800574:	89 75 08             	mov    %esi,0x8(%ebp)
  800577:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80057a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80057d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800580:	83 c7 01             	add    $0x1,%edi
  800583:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800587:	0f be d0             	movsbl %al,%edx
  80058a:	85 d2                	test   %edx,%edx
  80058c:	74 23                	je     8005b1 <vprintfmt+0x270>
  80058e:	85 f6                	test   %esi,%esi
  800590:	78 a1                	js     800533 <vprintfmt+0x1f2>
  800592:	83 ee 01             	sub    $0x1,%esi
  800595:	79 9c                	jns    800533 <vprintfmt+0x1f2>
  800597:	89 df                	mov    %ebx,%edi
  800599:	8b 75 08             	mov    0x8(%ebp),%esi
  80059c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80059f:	eb 18                	jmp    8005b9 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005a1:	83 ec 08             	sub    $0x8,%esp
  8005a4:	53                   	push   %ebx
  8005a5:	6a 20                	push   $0x20
  8005a7:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005a9:	83 ef 01             	sub    $0x1,%edi
  8005ac:	83 c4 10             	add    $0x10,%esp
  8005af:	eb 08                	jmp    8005b9 <vprintfmt+0x278>
  8005b1:	89 df                	mov    %ebx,%edi
  8005b3:	8b 75 08             	mov    0x8(%ebp),%esi
  8005b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005b9:	85 ff                	test   %edi,%edi
  8005bb:	7f e4                	jg     8005a1 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005bd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c0:	e9 a2 fd ff ff       	jmp    800367 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005c5:	83 fa 01             	cmp    $0x1,%edx
  8005c8:	7e 16                	jle    8005e0 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cd:	8d 50 08             	lea    0x8(%eax),%edx
  8005d0:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d3:	8b 50 04             	mov    0x4(%eax),%edx
  8005d6:	8b 00                	mov    (%eax),%eax
  8005d8:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005db:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005de:	eb 32                	jmp    800612 <vprintfmt+0x2d1>
	else if (lflag)
  8005e0:	85 d2                	test   %edx,%edx
  8005e2:	74 18                	je     8005fc <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e7:	8d 50 04             	lea    0x4(%eax),%edx
  8005ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ed:	8b 00                	mov    (%eax),%eax
  8005ef:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f2:	89 c1                	mov    %eax,%ecx
  8005f4:	c1 f9 1f             	sar    $0x1f,%ecx
  8005f7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005fa:	eb 16                	jmp    800612 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  8005fc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ff:	8d 50 04             	lea    0x4(%eax),%edx
  800602:	89 55 14             	mov    %edx,0x14(%ebp)
  800605:	8b 00                	mov    (%eax),%eax
  800607:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80060a:	89 c1                	mov    %eax,%ecx
  80060c:	c1 f9 1f             	sar    $0x1f,%ecx
  80060f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800612:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800615:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800618:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80061d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800621:	0f 89 90 00 00 00    	jns    8006b7 <vprintfmt+0x376>
				putch('-', putdat);
  800627:	83 ec 08             	sub    $0x8,%esp
  80062a:	53                   	push   %ebx
  80062b:	6a 2d                	push   $0x2d
  80062d:	ff d6                	call   *%esi
				num = -(long long) num;
  80062f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800632:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800635:	f7 d8                	neg    %eax
  800637:	83 d2 00             	adc    $0x0,%edx
  80063a:	f7 da                	neg    %edx
  80063c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80063f:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800644:	eb 71                	jmp    8006b7 <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800646:	8d 45 14             	lea    0x14(%ebp),%eax
  800649:	e8 7f fc ff ff       	call   8002cd <getuint>
			base = 10;
  80064e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800653:	eb 62                	jmp    8006b7 <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800655:	8d 45 14             	lea    0x14(%ebp),%eax
  800658:	e8 70 fc ff ff       	call   8002cd <getuint>
                        base = 8;
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
  80065d:	83 ec 0c             	sub    $0xc,%esp
  800660:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
  800664:	51                   	push   %ecx
  800665:	ff 75 e0             	pushl  -0x20(%ebp)
  800668:	6a 08                	push   $0x8
  80066a:	52                   	push   %edx
  80066b:	50                   	push   %eax
  80066c:	89 da                	mov    %ebx,%edx
  80066e:	89 f0                	mov    %esi,%eax
  800670:	e8 a9 fb ff ff       	call   80021e <printnum>
                        break;
  800675:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800678:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
                        break;
  80067b:	e9 e7 fc ff ff       	jmp    800367 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
  800680:	83 ec 08             	sub    $0x8,%esp
  800683:	53                   	push   %ebx
  800684:	6a 30                	push   $0x30
  800686:	ff d6                	call   *%esi
			putch('x', putdat);
  800688:	83 c4 08             	add    $0x8,%esp
  80068b:	53                   	push   %ebx
  80068c:	6a 78                	push   $0x78
  80068e:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800690:	8b 45 14             	mov    0x14(%ebp),%eax
  800693:	8d 50 04             	lea    0x4(%eax),%edx
  800696:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800699:	8b 00                	mov    (%eax),%eax
  80069b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8006a0:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006a3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006a8:	eb 0d                	jmp    8006b7 <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006aa:	8d 45 14             	lea    0x14(%ebp),%eax
  8006ad:	e8 1b fc ff ff       	call   8002cd <getuint>
			base = 16;
  8006b2:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006b7:	83 ec 0c             	sub    $0xc,%esp
  8006ba:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006be:	57                   	push   %edi
  8006bf:	ff 75 e0             	pushl  -0x20(%ebp)
  8006c2:	51                   	push   %ecx
  8006c3:	52                   	push   %edx
  8006c4:	50                   	push   %eax
  8006c5:	89 da                	mov    %ebx,%edx
  8006c7:	89 f0                	mov    %esi,%eax
  8006c9:	e8 50 fb ff ff       	call   80021e <printnum>
			break;
  8006ce:	83 c4 20             	add    $0x20,%esp
  8006d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006d4:	e9 8e fc ff ff       	jmp    800367 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006d9:	83 ec 08             	sub    $0x8,%esp
  8006dc:	53                   	push   %ebx
  8006dd:	51                   	push   %ecx
  8006de:	ff d6                	call   *%esi
			break;
  8006e0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006e6:	e9 7c fc ff ff       	jmp    800367 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006eb:	83 ec 08             	sub    $0x8,%esp
  8006ee:	53                   	push   %ebx
  8006ef:	6a 25                	push   $0x25
  8006f1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006f3:	83 c4 10             	add    $0x10,%esp
  8006f6:	eb 03                	jmp    8006fb <vprintfmt+0x3ba>
  8006f8:	83 ef 01             	sub    $0x1,%edi
  8006fb:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006ff:	75 f7                	jne    8006f8 <vprintfmt+0x3b7>
  800701:	e9 61 fc ff ff       	jmp    800367 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800706:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800709:	5b                   	pop    %ebx
  80070a:	5e                   	pop    %esi
  80070b:	5f                   	pop    %edi
  80070c:	5d                   	pop    %ebp
  80070d:	c3                   	ret    

0080070e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80070e:	55                   	push   %ebp
  80070f:	89 e5                	mov    %esp,%ebp
  800711:	83 ec 18             	sub    $0x18,%esp
  800714:	8b 45 08             	mov    0x8(%ebp),%eax
  800717:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80071a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80071d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800721:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800724:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80072b:	85 c0                	test   %eax,%eax
  80072d:	74 26                	je     800755 <vsnprintf+0x47>
  80072f:	85 d2                	test   %edx,%edx
  800731:	7e 22                	jle    800755 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800733:	ff 75 14             	pushl  0x14(%ebp)
  800736:	ff 75 10             	pushl  0x10(%ebp)
  800739:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80073c:	50                   	push   %eax
  80073d:	68 07 03 80 00       	push   $0x800307
  800742:	e8 fa fb ff ff       	call   800341 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800747:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80074a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80074d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800750:	83 c4 10             	add    $0x10,%esp
  800753:	eb 05                	jmp    80075a <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800755:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80075a:	c9                   	leave  
  80075b:	c3                   	ret    

0080075c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80075c:	55                   	push   %ebp
  80075d:	89 e5                	mov    %esp,%ebp
  80075f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800762:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800765:	50                   	push   %eax
  800766:	ff 75 10             	pushl  0x10(%ebp)
  800769:	ff 75 0c             	pushl  0xc(%ebp)
  80076c:	ff 75 08             	pushl  0x8(%ebp)
  80076f:	e8 9a ff ff ff       	call   80070e <vsnprintf>
	va_end(ap);

	return rc;
}
  800774:	c9                   	leave  
  800775:	c3                   	ret    

00800776 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800776:	55                   	push   %ebp
  800777:	89 e5                	mov    %esp,%ebp
  800779:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80077c:	b8 00 00 00 00       	mov    $0x0,%eax
  800781:	eb 03                	jmp    800786 <strlen+0x10>
		n++;
  800783:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800786:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80078a:	75 f7                	jne    800783 <strlen+0xd>
		n++;
	return n;
}
  80078c:	5d                   	pop    %ebp
  80078d:	c3                   	ret    

0080078e <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80078e:	55                   	push   %ebp
  80078f:	89 e5                	mov    %esp,%ebp
  800791:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800794:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800797:	ba 00 00 00 00       	mov    $0x0,%edx
  80079c:	eb 03                	jmp    8007a1 <strnlen+0x13>
		n++;
  80079e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007a1:	39 c2                	cmp    %eax,%edx
  8007a3:	74 08                	je     8007ad <strnlen+0x1f>
  8007a5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8007a9:	75 f3                	jne    80079e <strnlen+0x10>
  8007ab:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007ad:	5d                   	pop    %ebp
  8007ae:	c3                   	ret    

008007af <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007af:	55                   	push   %ebp
  8007b0:	89 e5                	mov    %esp,%ebp
  8007b2:	53                   	push   %ebx
  8007b3:	8b 45 08             	mov    0x8(%ebp),%eax
  8007b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007b9:	89 c2                	mov    %eax,%edx
  8007bb:	83 c2 01             	add    $0x1,%edx
  8007be:	83 c1 01             	add    $0x1,%ecx
  8007c1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007c5:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007c8:	84 db                	test   %bl,%bl
  8007ca:	75 ef                	jne    8007bb <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007cc:	5b                   	pop    %ebx
  8007cd:	5d                   	pop    %ebp
  8007ce:	c3                   	ret    

008007cf <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007cf:	55                   	push   %ebp
  8007d0:	89 e5                	mov    %esp,%ebp
  8007d2:	53                   	push   %ebx
  8007d3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007d6:	53                   	push   %ebx
  8007d7:	e8 9a ff ff ff       	call   800776 <strlen>
  8007dc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007df:	ff 75 0c             	pushl  0xc(%ebp)
  8007e2:	01 d8                	add    %ebx,%eax
  8007e4:	50                   	push   %eax
  8007e5:	e8 c5 ff ff ff       	call   8007af <strcpy>
	return dst;
}
  8007ea:	89 d8                	mov    %ebx,%eax
  8007ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007ef:	c9                   	leave  
  8007f0:	c3                   	ret    

008007f1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007f1:	55                   	push   %ebp
  8007f2:	89 e5                	mov    %esp,%ebp
  8007f4:	56                   	push   %esi
  8007f5:	53                   	push   %ebx
  8007f6:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007fc:	89 f3                	mov    %esi,%ebx
  8007fe:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800801:	89 f2                	mov    %esi,%edx
  800803:	eb 0f                	jmp    800814 <strncpy+0x23>
		*dst++ = *src;
  800805:	83 c2 01             	add    $0x1,%edx
  800808:	0f b6 01             	movzbl (%ecx),%eax
  80080b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80080e:	80 39 01             	cmpb   $0x1,(%ecx)
  800811:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800814:	39 da                	cmp    %ebx,%edx
  800816:	75 ed                	jne    800805 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800818:	89 f0                	mov    %esi,%eax
  80081a:	5b                   	pop    %ebx
  80081b:	5e                   	pop    %esi
  80081c:	5d                   	pop    %ebp
  80081d:	c3                   	ret    

0080081e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80081e:	55                   	push   %ebp
  80081f:	89 e5                	mov    %esp,%ebp
  800821:	56                   	push   %esi
  800822:	53                   	push   %ebx
  800823:	8b 75 08             	mov    0x8(%ebp),%esi
  800826:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800829:	8b 55 10             	mov    0x10(%ebp),%edx
  80082c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80082e:	85 d2                	test   %edx,%edx
  800830:	74 21                	je     800853 <strlcpy+0x35>
  800832:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800836:	89 f2                	mov    %esi,%edx
  800838:	eb 09                	jmp    800843 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80083a:	83 c2 01             	add    $0x1,%edx
  80083d:	83 c1 01             	add    $0x1,%ecx
  800840:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800843:	39 c2                	cmp    %eax,%edx
  800845:	74 09                	je     800850 <strlcpy+0x32>
  800847:	0f b6 19             	movzbl (%ecx),%ebx
  80084a:	84 db                	test   %bl,%bl
  80084c:	75 ec                	jne    80083a <strlcpy+0x1c>
  80084e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800850:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800853:	29 f0                	sub    %esi,%eax
}
  800855:	5b                   	pop    %ebx
  800856:	5e                   	pop    %esi
  800857:	5d                   	pop    %ebp
  800858:	c3                   	ret    

00800859 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800859:	55                   	push   %ebp
  80085a:	89 e5                	mov    %esp,%ebp
  80085c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80085f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800862:	eb 06                	jmp    80086a <strcmp+0x11>
		p++, q++;
  800864:	83 c1 01             	add    $0x1,%ecx
  800867:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80086a:	0f b6 01             	movzbl (%ecx),%eax
  80086d:	84 c0                	test   %al,%al
  80086f:	74 04                	je     800875 <strcmp+0x1c>
  800871:	3a 02                	cmp    (%edx),%al
  800873:	74 ef                	je     800864 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800875:	0f b6 c0             	movzbl %al,%eax
  800878:	0f b6 12             	movzbl (%edx),%edx
  80087b:	29 d0                	sub    %edx,%eax
}
  80087d:	5d                   	pop    %ebp
  80087e:	c3                   	ret    

0080087f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80087f:	55                   	push   %ebp
  800880:	89 e5                	mov    %esp,%ebp
  800882:	53                   	push   %ebx
  800883:	8b 45 08             	mov    0x8(%ebp),%eax
  800886:	8b 55 0c             	mov    0xc(%ebp),%edx
  800889:	89 c3                	mov    %eax,%ebx
  80088b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80088e:	eb 06                	jmp    800896 <strncmp+0x17>
		n--, p++, q++;
  800890:	83 c0 01             	add    $0x1,%eax
  800893:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800896:	39 d8                	cmp    %ebx,%eax
  800898:	74 15                	je     8008af <strncmp+0x30>
  80089a:	0f b6 08             	movzbl (%eax),%ecx
  80089d:	84 c9                	test   %cl,%cl
  80089f:	74 04                	je     8008a5 <strncmp+0x26>
  8008a1:	3a 0a                	cmp    (%edx),%cl
  8008a3:	74 eb                	je     800890 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008a5:	0f b6 00             	movzbl (%eax),%eax
  8008a8:	0f b6 12             	movzbl (%edx),%edx
  8008ab:	29 d0                	sub    %edx,%eax
  8008ad:	eb 05                	jmp    8008b4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008af:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008b4:	5b                   	pop    %ebx
  8008b5:	5d                   	pop    %ebp
  8008b6:	c3                   	ret    

008008b7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008b7:	55                   	push   %ebp
  8008b8:	89 e5                	mov    %esp,%ebp
  8008ba:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c1:	eb 07                	jmp    8008ca <strchr+0x13>
		if (*s == c)
  8008c3:	38 ca                	cmp    %cl,%dl
  8008c5:	74 0f                	je     8008d6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008c7:	83 c0 01             	add    $0x1,%eax
  8008ca:	0f b6 10             	movzbl (%eax),%edx
  8008cd:	84 d2                	test   %dl,%dl
  8008cf:	75 f2                	jne    8008c3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008d6:	5d                   	pop    %ebp
  8008d7:	c3                   	ret    

008008d8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008d8:	55                   	push   %ebp
  8008d9:	89 e5                	mov    %esp,%ebp
  8008db:	8b 45 08             	mov    0x8(%ebp),%eax
  8008de:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008e2:	eb 03                	jmp    8008e7 <strfind+0xf>
  8008e4:	83 c0 01             	add    $0x1,%eax
  8008e7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008ea:	38 ca                	cmp    %cl,%dl
  8008ec:	74 04                	je     8008f2 <strfind+0x1a>
  8008ee:	84 d2                	test   %dl,%dl
  8008f0:	75 f2                	jne    8008e4 <strfind+0xc>
			break;
	return (char *) s;
}
  8008f2:	5d                   	pop    %ebp
  8008f3:	c3                   	ret    

008008f4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008f4:	55                   	push   %ebp
  8008f5:	89 e5                	mov    %esp,%ebp
  8008f7:	57                   	push   %edi
  8008f8:	56                   	push   %esi
  8008f9:	53                   	push   %ebx
  8008fa:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008fd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800900:	85 c9                	test   %ecx,%ecx
  800902:	74 36                	je     80093a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800904:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80090a:	75 28                	jne    800934 <memset+0x40>
  80090c:	f6 c1 03             	test   $0x3,%cl
  80090f:	75 23                	jne    800934 <memset+0x40>
		c &= 0xFF;
  800911:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800915:	89 d3                	mov    %edx,%ebx
  800917:	c1 e3 08             	shl    $0x8,%ebx
  80091a:	89 d6                	mov    %edx,%esi
  80091c:	c1 e6 18             	shl    $0x18,%esi
  80091f:	89 d0                	mov    %edx,%eax
  800921:	c1 e0 10             	shl    $0x10,%eax
  800924:	09 f0                	or     %esi,%eax
  800926:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800928:	89 d8                	mov    %ebx,%eax
  80092a:	09 d0                	or     %edx,%eax
  80092c:	c1 e9 02             	shr    $0x2,%ecx
  80092f:	fc                   	cld    
  800930:	f3 ab                	rep stos %eax,%es:(%edi)
  800932:	eb 06                	jmp    80093a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800934:	8b 45 0c             	mov    0xc(%ebp),%eax
  800937:	fc                   	cld    
  800938:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80093a:	89 f8                	mov    %edi,%eax
  80093c:	5b                   	pop    %ebx
  80093d:	5e                   	pop    %esi
  80093e:	5f                   	pop    %edi
  80093f:	5d                   	pop    %ebp
  800940:	c3                   	ret    

00800941 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800941:	55                   	push   %ebp
  800942:	89 e5                	mov    %esp,%ebp
  800944:	57                   	push   %edi
  800945:	56                   	push   %esi
  800946:	8b 45 08             	mov    0x8(%ebp),%eax
  800949:	8b 75 0c             	mov    0xc(%ebp),%esi
  80094c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80094f:	39 c6                	cmp    %eax,%esi
  800951:	73 35                	jae    800988 <memmove+0x47>
  800953:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800956:	39 d0                	cmp    %edx,%eax
  800958:	73 2e                	jae    800988 <memmove+0x47>
		s += n;
		d += n;
  80095a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80095d:	89 d6                	mov    %edx,%esi
  80095f:	09 fe                	or     %edi,%esi
  800961:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800967:	75 13                	jne    80097c <memmove+0x3b>
  800969:	f6 c1 03             	test   $0x3,%cl
  80096c:	75 0e                	jne    80097c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80096e:	83 ef 04             	sub    $0x4,%edi
  800971:	8d 72 fc             	lea    -0x4(%edx),%esi
  800974:	c1 e9 02             	shr    $0x2,%ecx
  800977:	fd                   	std    
  800978:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80097a:	eb 09                	jmp    800985 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80097c:	83 ef 01             	sub    $0x1,%edi
  80097f:	8d 72 ff             	lea    -0x1(%edx),%esi
  800982:	fd                   	std    
  800983:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800985:	fc                   	cld    
  800986:	eb 1d                	jmp    8009a5 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800988:	89 f2                	mov    %esi,%edx
  80098a:	09 c2                	or     %eax,%edx
  80098c:	f6 c2 03             	test   $0x3,%dl
  80098f:	75 0f                	jne    8009a0 <memmove+0x5f>
  800991:	f6 c1 03             	test   $0x3,%cl
  800994:	75 0a                	jne    8009a0 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800996:	c1 e9 02             	shr    $0x2,%ecx
  800999:	89 c7                	mov    %eax,%edi
  80099b:	fc                   	cld    
  80099c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80099e:	eb 05                	jmp    8009a5 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009a0:	89 c7                	mov    %eax,%edi
  8009a2:	fc                   	cld    
  8009a3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009a5:	5e                   	pop    %esi
  8009a6:	5f                   	pop    %edi
  8009a7:	5d                   	pop    %ebp
  8009a8:	c3                   	ret    

008009a9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009a9:	55                   	push   %ebp
  8009aa:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009ac:	ff 75 10             	pushl  0x10(%ebp)
  8009af:	ff 75 0c             	pushl  0xc(%ebp)
  8009b2:	ff 75 08             	pushl  0x8(%ebp)
  8009b5:	e8 87 ff ff ff       	call   800941 <memmove>
}
  8009ba:	c9                   	leave  
  8009bb:	c3                   	ret    

008009bc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009bc:	55                   	push   %ebp
  8009bd:	89 e5                	mov    %esp,%ebp
  8009bf:	56                   	push   %esi
  8009c0:	53                   	push   %ebx
  8009c1:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c4:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009c7:	89 c6                	mov    %eax,%esi
  8009c9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009cc:	eb 1a                	jmp    8009e8 <memcmp+0x2c>
		if (*s1 != *s2)
  8009ce:	0f b6 08             	movzbl (%eax),%ecx
  8009d1:	0f b6 1a             	movzbl (%edx),%ebx
  8009d4:	38 d9                	cmp    %bl,%cl
  8009d6:	74 0a                	je     8009e2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009d8:	0f b6 c1             	movzbl %cl,%eax
  8009db:	0f b6 db             	movzbl %bl,%ebx
  8009de:	29 d8                	sub    %ebx,%eax
  8009e0:	eb 0f                	jmp    8009f1 <memcmp+0x35>
		s1++, s2++;
  8009e2:	83 c0 01             	add    $0x1,%eax
  8009e5:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009e8:	39 f0                	cmp    %esi,%eax
  8009ea:	75 e2                	jne    8009ce <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009f1:	5b                   	pop    %ebx
  8009f2:	5e                   	pop    %esi
  8009f3:	5d                   	pop    %ebp
  8009f4:	c3                   	ret    

008009f5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009f5:	55                   	push   %ebp
  8009f6:	89 e5                	mov    %esp,%ebp
  8009f8:	53                   	push   %ebx
  8009f9:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009fc:	89 c1                	mov    %eax,%ecx
  8009fe:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800a01:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a05:	eb 0a                	jmp    800a11 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a07:	0f b6 10             	movzbl (%eax),%edx
  800a0a:	39 da                	cmp    %ebx,%edx
  800a0c:	74 07                	je     800a15 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a0e:	83 c0 01             	add    $0x1,%eax
  800a11:	39 c8                	cmp    %ecx,%eax
  800a13:	72 f2                	jb     800a07 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a15:	5b                   	pop    %ebx
  800a16:	5d                   	pop    %ebp
  800a17:	c3                   	ret    

00800a18 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a18:	55                   	push   %ebp
  800a19:	89 e5                	mov    %esp,%ebp
  800a1b:	57                   	push   %edi
  800a1c:	56                   	push   %esi
  800a1d:	53                   	push   %ebx
  800a1e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a21:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a24:	eb 03                	jmp    800a29 <strtol+0x11>
		s++;
  800a26:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a29:	0f b6 01             	movzbl (%ecx),%eax
  800a2c:	3c 20                	cmp    $0x20,%al
  800a2e:	74 f6                	je     800a26 <strtol+0xe>
  800a30:	3c 09                	cmp    $0x9,%al
  800a32:	74 f2                	je     800a26 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a34:	3c 2b                	cmp    $0x2b,%al
  800a36:	75 0a                	jne    800a42 <strtol+0x2a>
		s++;
  800a38:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a3b:	bf 00 00 00 00       	mov    $0x0,%edi
  800a40:	eb 11                	jmp    800a53 <strtol+0x3b>
  800a42:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a47:	3c 2d                	cmp    $0x2d,%al
  800a49:	75 08                	jne    800a53 <strtol+0x3b>
		s++, neg = 1;
  800a4b:	83 c1 01             	add    $0x1,%ecx
  800a4e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a53:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a59:	75 15                	jne    800a70 <strtol+0x58>
  800a5b:	80 39 30             	cmpb   $0x30,(%ecx)
  800a5e:	75 10                	jne    800a70 <strtol+0x58>
  800a60:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a64:	75 7c                	jne    800ae2 <strtol+0xca>
		s += 2, base = 16;
  800a66:	83 c1 02             	add    $0x2,%ecx
  800a69:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a6e:	eb 16                	jmp    800a86 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a70:	85 db                	test   %ebx,%ebx
  800a72:	75 12                	jne    800a86 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a74:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a79:	80 39 30             	cmpb   $0x30,(%ecx)
  800a7c:	75 08                	jne    800a86 <strtol+0x6e>
		s++, base = 8;
  800a7e:	83 c1 01             	add    $0x1,%ecx
  800a81:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a86:	b8 00 00 00 00       	mov    $0x0,%eax
  800a8b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a8e:	0f b6 11             	movzbl (%ecx),%edx
  800a91:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a94:	89 f3                	mov    %esi,%ebx
  800a96:	80 fb 09             	cmp    $0x9,%bl
  800a99:	77 08                	ja     800aa3 <strtol+0x8b>
			dig = *s - '0';
  800a9b:	0f be d2             	movsbl %dl,%edx
  800a9e:	83 ea 30             	sub    $0x30,%edx
  800aa1:	eb 22                	jmp    800ac5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800aa3:	8d 72 9f             	lea    -0x61(%edx),%esi
  800aa6:	89 f3                	mov    %esi,%ebx
  800aa8:	80 fb 19             	cmp    $0x19,%bl
  800aab:	77 08                	ja     800ab5 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800aad:	0f be d2             	movsbl %dl,%edx
  800ab0:	83 ea 57             	sub    $0x57,%edx
  800ab3:	eb 10                	jmp    800ac5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800ab5:	8d 72 bf             	lea    -0x41(%edx),%esi
  800ab8:	89 f3                	mov    %esi,%ebx
  800aba:	80 fb 19             	cmp    $0x19,%bl
  800abd:	77 16                	ja     800ad5 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800abf:	0f be d2             	movsbl %dl,%edx
  800ac2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ac5:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ac8:	7d 0b                	jge    800ad5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800aca:	83 c1 01             	add    $0x1,%ecx
  800acd:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ad1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ad3:	eb b9                	jmp    800a8e <strtol+0x76>

	if (endptr)
  800ad5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ad9:	74 0d                	je     800ae8 <strtol+0xd0>
		*endptr = (char *) s;
  800adb:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ade:	89 0e                	mov    %ecx,(%esi)
  800ae0:	eb 06                	jmp    800ae8 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ae2:	85 db                	test   %ebx,%ebx
  800ae4:	74 98                	je     800a7e <strtol+0x66>
  800ae6:	eb 9e                	jmp    800a86 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ae8:	89 c2                	mov    %eax,%edx
  800aea:	f7 da                	neg    %edx
  800aec:	85 ff                	test   %edi,%edi
  800aee:	0f 45 c2             	cmovne %edx,%eax
}
  800af1:	5b                   	pop    %ebx
  800af2:	5e                   	pop    %esi
  800af3:	5f                   	pop    %edi
  800af4:	5d                   	pop    %ebp
  800af5:	c3                   	ret    
  800af6:	66 90                	xchg   %ax,%ax
  800af8:	66 90                	xchg   %ax,%ax
  800afa:	66 90                	xchg   %ax,%ax
  800afc:	66 90                	xchg   %ax,%ax
  800afe:	66 90                	xchg   %ax,%ax

00800b00 <__udivdi3>:
  800b00:	55                   	push   %ebp
  800b01:	57                   	push   %edi
  800b02:	56                   	push   %esi
  800b03:	53                   	push   %ebx
  800b04:	83 ec 1c             	sub    $0x1c,%esp
  800b07:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b0b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b0f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b13:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b17:	85 f6                	test   %esi,%esi
  800b19:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b1d:	89 ca                	mov    %ecx,%edx
  800b1f:	89 f8                	mov    %edi,%eax
  800b21:	75 3d                	jne    800b60 <__udivdi3+0x60>
  800b23:	39 cf                	cmp    %ecx,%edi
  800b25:	0f 87 c5 00 00 00    	ja     800bf0 <__udivdi3+0xf0>
  800b2b:	85 ff                	test   %edi,%edi
  800b2d:	89 fd                	mov    %edi,%ebp
  800b2f:	75 0b                	jne    800b3c <__udivdi3+0x3c>
  800b31:	b8 01 00 00 00       	mov    $0x1,%eax
  800b36:	31 d2                	xor    %edx,%edx
  800b38:	f7 f7                	div    %edi
  800b3a:	89 c5                	mov    %eax,%ebp
  800b3c:	89 c8                	mov    %ecx,%eax
  800b3e:	31 d2                	xor    %edx,%edx
  800b40:	f7 f5                	div    %ebp
  800b42:	89 c1                	mov    %eax,%ecx
  800b44:	89 d8                	mov    %ebx,%eax
  800b46:	89 cf                	mov    %ecx,%edi
  800b48:	f7 f5                	div    %ebp
  800b4a:	89 c3                	mov    %eax,%ebx
  800b4c:	89 d8                	mov    %ebx,%eax
  800b4e:	89 fa                	mov    %edi,%edx
  800b50:	83 c4 1c             	add    $0x1c,%esp
  800b53:	5b                   	pop    %ebx
  800b54:	5e                   	pop    %esi
  800b55:	5f                   	pop    %edi
  800b56:	5d                   	pop    %ebp
  800b57:	c3                   	ret    
  800b58:	90                   	nop
  800b59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b60:	39 ce                	cmp    %ecx,%esi
  800b62:	77 74                	ja     800bd8 <__udivdi3+0xd8>
  800b64:	0f bd fe             	bsr    %esi,%edi
  800b67:	83 f7 1f             	xor    $0x1f,%edi
  800b6a:	0f 84 98 00 00 00    	je     800c08 <__udivdi3+0x108>
  800b70:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b75:	89 f9                	mov    %edi,%ecx
  800b77:	89 c5                	mov    %eax,%ebp
  800b79:	29 fb                	sub    %edi,%ebx
  800b7b:	d3 e6                	shl    %cl,%esi
  800b7d:	89 d9                	mov    %ebx,%ecx
  800b7f:	d3 ed                	shr    %cl,%ebp
  800b81:	89 f9                	mov    %edi,%ecx
  800b83:	d3 e0                	shl    %cl,%eax
  800b85:	09 ee                	or     %ebp,%esi
  800b87:	89 d9                	mov    %ebx,%ecx
  800b89:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b8d:	89 d5                	mov    %edx,%ebp
  800b8f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800b93:	d3 ed                	shr    %cl,%ebp
  800b95:	89 f9                	mov    %edi,%ecx
  800b97:	d3 e2                	shl    %cl,%edx
  800b99:	89 d9                	mov    %ebx,%ecx
  800b9b:	d3 e8                	shr    %cl,%eax
  800b9d:	09 c2                	or     %eax,%edx
  800b9f:	89 d0                	mov    %edx,%eax
  800ba1:	89 ea                	mov    %ebp,%edx
  800ba3:	f7 f6                	div    %esi
  800ba5:	89 d5                	mov    %edx,%ebp
  800ba7:	89 c3                	mov    %eax,%ebx
  800ba9:	f7 64 24 0c          	mull   0xc(%esp)
  800bad:	39 d5                	cmp    %edx,%ebp
  800baf:	72 10                	jb     800bc1 <__udivdi3+0xc1>
  800bb1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800bb5:	89 f9                	mov    %edi,%ecx
  800bb7:	d3 e6                	shl    %cl,%esi
  800bb9:	39 c6                	cmp    %eax,%esi
  800bbb:	73 07                	jae    800bc4 <__udivdi3+0xc4>
  800bbd:	39 d5                	cmp    %edx,%ebp
  800bbf:	75 03                	jne    800bc4 <__udivdi3+0xc4>
  800bc1:	83 eb 01             	sub    $0x1,%ebx
  800bc4:	31 ff                	xor    %edi,%edi
  800bc6:	89 d8                	mov    %ebx,%eax
  800bc8:	89 fa                	mov    %edi,%edx
  800bca:	83 c4 1c             	add    $0x1c,%esp
  800bcd:	5b                   	pop    %ebx
  800bce:	5e                   	pop    %esi
  800bcf:	5f                   	pop    %edi
  800bd0:	5d                   	pop    %ebp
  800bd1:	c3                   	ret    
  800bd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bd8:	31 ff                	xor    %edi,%edi
  800bda:	31 db                	xor    %ebx,%ebx
  800bdc:	89 d8                	mov    %ebx,%eax
  800bde:	89 fa                	mov    %edi,%edx
  800be0:	83 c4 1c             	add    $0x1c,%esp
  800be3:	5b                   	pop    %ebx
  800be4:	5e                   	pop    %esi
  800be5:	5f                   	pop    %edi
  800be6:	5d                   	pop    %ebp
  800be7:	c3                   	ret    
  800be8:	90                   	nop
  800be9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bf0:	89 d8                	mov    %ebx,%eax
  800bf2:	f7 f7                	div    %edi
  800bf4:	31 ff                	xor    %edi,%edi
  800bf6:	89 c3                	mov    %eax,%ebx
  800bf8:	89 d8                	mov    %ebx,%eax
  800bfa:	89 fa                	mov    %edi,%edx
  800bfc:	83 c4 1c             	add    $0x1c,%esp
  800bff:	5b                   	pop    %ebx
  800c00:	5e                   	pop    %esi
  800c01:	5f                   	pop    %edi
  800c02:	5d                   	pop    %ebp
  800c03:	c3                   	ret    
  800c04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c08:	39 ce                	cmp    %ecx,%esi
  800c0a:	72 0c                	jb     800c18 <__udivdi3+0x118>
  800c0c:	31 db                	xor    %ebx,%ebx
  800c0e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c12:	0f 87 34 ff ff ff    	ja     800b4c <__udivdi3+0x4c>
  800c18:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c1d:	e9 2a ff ff ff       	jmp    800b4c <__udivdi3+0x4c>
  800c22:	66 90                	xchg   %ax,%ax
  800c24:	66 90                	xchg   %ax,%ax
  800c26:	66 90                	xchg   %ax,%ax
  800c28:	66 90                	xchg   %ax,%ax
  800c2a:	66 90                	xchg   %ax,%ax
  800c2c:	66 90                	xchg   %ax,%ax
  800c2e:	66 90                	xchg   %ax,%ax

00800c30 <__umoddi3>:
  800c30:	55                   	push   %ebp
  800c31:	57                   	push   %edi
  800c32:	56                   	push   %esi
  800c33:	53                   	push   %ebx
  800c34:	83 ec 1c             	sub    $0x1c,%esp
  800c37:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c3b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c3f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c43:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c47:	85 d2                	test   %edx,%edx
  800c49:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c4d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c51:	89 f3                	mov    %esi,%ebx
  800c53:	89 3c 24             	mov    %edi,(%esp)
  800c56:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c5a:	75 1c                	jne    800c78 <__umoddi3+0x48>
  800c5c:	39 f7                	cmp    %esi,%edi
  800c5e:	76 50                	jbe    800cb0 <__umoddi3+0x80>
  800c60:	89 c8                	mov    %ecx,%eax
  800c62:	89 f2                	mov    %esi,%edx
  800c64:	f7 f7                	div    %edi
  800c66:	89 d0                	mov    %edx,%eax
  800c68:	31 d2                	xor    %edx,%edx
  800c6a:	83 c4 1c             	add    $0x1c,%esp
  800c6d:	5b                   	pop    %ebx
  800c6e:	5e                   	pop    %esi
  800c6f:	5f                   	pop    %edi
  800c70:	5d                   	pop    %ebp
  800c71:	c3                   	ret    
  800c72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c78:	39 f2                	cmp    %esi,%edx
  800c7a:	89 d0                	mov    %edx,%eax
  800c7c:	77 52                	ja     800cd0 <__umoddi3+0xa0>
  800c7e:	0f bd ea             	bsr    %edx,%ebp
  800c81:	83 f5 1f             	xor    $0x1f,%ebp
  800c84:	75 5a                	jne    800ce0 <__umoddi3+0xb0>
  800c86:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c8a:	0f 82 e0 00 00 00    	jb     800d70 <__umoddi3+0x140>
  800c90:	39 0c 24             	cmp    %ecx,(%esp)
  800c93:	0f 86 d7 00 00 00    	jbe    800d70 <__umoddi3+0x140>
  800c99:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c9d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ca1:	83 c4 1c             	add    $0x1c,%esp
  800ca4:	5b                   	pop    %ebx
  800ca5:	5e                   	pop    %esi
  800ca6:	5f                   	pop    %edi
  800ca7:	5d                   	pop    %ebp
  800ca8:	c3                   	ret    
  800ca9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cb0:	85 ff                	test   %edi,%edi
  800cb2:	89 fd                	mov    %edi,%ebp
  800cb4:	75 0b                	jne    800cc1 <__umoddi3+0x91>
  800cb6:	b8 01 00 00 00       	mov    $0x1,%eax
  800cbb:	31 d2                	xor    %edx,%edx
  800cbd:	f7 f7                	div    %edi
  800cbf:	89 c5                	mov    %eax,%ebp
  800cc1:	89 f0                	mov    %esi,%eax
  800cc3:	31 d2                	xor    %edx,%edx
  800cc5:	f7 f5                	div    %ebp
  800cc7:	89 c8                	mov    %ecx,%eax
  800cc9:	f7 f5                	div    %ebp
  800ccb:	89 d0                	mov    %edx,%eax
  800ccd:	eb 99                	jmp    800c68 <__umoddi3+0x38>
  800ccf:	90                   	nop
  800cd0:	89 c8                	mov    %ecx,%eax
  800cd2:	89 f2                	mov    %esi,%edx
  800cd4:	83 c4 1c             	add    $0x1c,%esp
  800cd7:	5b                   	pop    %ebx
  800cd8:	5e                   	pop    %esi
  800cd9:	5f                   	pop    %edi
  800cda:	5d                   	pop    %ebp
  800cdb:	c3                   	ret    
  800cdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ce0:	8b 34 24             	mov    (%esp),%esi
  800ce3:	bf 20 00 00 00       	mov    $0x20,%edi
  800ce8:	89 e9                	mov    %ebp,%ecx
  800cea:	29 ef                	sub    %ebp,%edi
  800cec:	d3 e0                	shl    %cl,%eax
  800cee:	89 f9                	mov    %edi,%ecx
  800cf0:	89 f2                	mov    %esi,%edx
  800cf2:	d3 ea                	shr    %cl,%edx
  800cf4:	89 e9                	mov    %ebp,%ecx
  800cf6:	09 c2                	or     %eax,%edx
  800cf8:	89 d8                	mov    %ebx,%eax
  800cfa:	89 14 24             	mov    %edx,(%esp)
  800cfd:	89 f2                	mov    %esi,%edx
  800cff:	d3 e2                	shl    %cl,%edx
  800d01:	89 f9                	mov    %edi,%ecx
  800d03:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d07:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d0b:	d3 e8                	shr    %cl,%eax
  800d0d:	89 e9                	mov    %ebp,%ecx
  800d0f:	89 c6                	mov    %eax,%esi
  800d11:	d3 e3                	shl    %cl,%ebx
  800d13:	89 f9                	mov    %edi,%ecx
  800d15:	89 d0                	mov    %edx,%eax
  800d17:	d3 e8                	shr    %cl,%eax
  800d19:	89 e9                	mov    %ebp,%ecx
  800d1b:	09 d8                	or     %ebx,%eax
  800d1d:	89 d3                	mov    %edx,%ebx
  800d1f:	89 f2                	mov    %esi,%edx
  800d21:	f7 34 24             	divl   (%esp)
  800d24:	89 d6                	mov    %edx,%esi
  800d26:	d3 e3                	shl    %cl,%ebx
  800d28:	f7 64 24 04          	mull   0x4(%esp)
  800d2c:	39 d6                	cmp    %edx,%esi
  800d2e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d32:	89 d1                	mov    %edx,%ecx
  800d34:	89 c3                	mov    %eax,%ebx
  800d36:	72 08                	jb     800d40 <__umoddi3+0x110>
  800d38:	75 11                	jne    800d4b <__umoddi3+0x11b>
  800d3a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d3e:	73 0b                	jae    800d4b <__umoddi3+0x11b>
  800d40:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d44:	1b 14 24             	sbb    (%esp),%edx
  800d47:	89 d1                	mov    %edx,%ecx
  800d49:	89 c3                	mov    %eax,%ebx
  800d4b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d4f:	29 da                	sub    %ebx,%edx
  800d51:	19 ce                	sbb    %ecx,%esi
  800d53:	89 f9                	mov    %edi,%ecx
  800d55:	89 f0                	mov    %esi,%eax
  800d57:	d3 e0                	shl    %cl,%eax
  800d59:	89 e9                	mov    %ebp,%ecx
  800d5b:	d3 ea                	shr    %cl,%edx
  800d5d:	89 e9                	mov    %ebp,%ecx
  800d5f:	d3 ee                	shr    %cl,%esi
  800d61:	09 d0                	or     %edx,%eax
  800d63:	89 f2                	mov    %esi,%edx
  800d65:	83 c4 1c             	add    $0x1c,%esp
  800d68:	5b                   	pop    %ebx
  800d69:	5e                   	pop    %esi
  800d6a:	5f                   	pop    %edi
  800d6b:	5d                   	pop    %ebp
  800d6c:	c3                   	ret    
  800d6d:	8d 76 00             	lea    0x0(%esi),%esi
  800d70:	29 f9                	sub    %edi,%ecx
  800d72:	19 d6                	sbb    %edx,%esi
  800d74:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d78:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d7c:	e9 18 ff ff ff       	jmp    800c99 <__umoddi3+0x69>
