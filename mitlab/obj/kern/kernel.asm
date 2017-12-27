
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 6f 31 00 00       	call   f01031cc <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 88 04 00 00       	call   f01004ea <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 36 10 f0       	push   $0xf0103660
f010006f:	e8 60 26 00 00       	call   f01026d4 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 62 0f 00 00       	call   f0100fdb <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 f9 06 00 00       	call   f010077f <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 7b 36 10 f0       	push   $0xf010367b
f01000b5:	e8 1a 26 00 00       	call   f01026d4 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 ea 25 00 00       	call   f01026ae <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 74 45 10 f0 	movl   $0xf0104574,(%esp)
f01000cb:	e8 04 26 00 00       	call   f01026d4 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 a2 06 00 00       	call   f010077f <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 93 36 10 f0       	push   $0xf0103693
f01000f7:	e8 d8 25 00 00       	call   f01026d4 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 a6 25 00 00       	call   f01026ae <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 74 45 10 f0 	movl   $0xf0104574,(%esp)
f010010f:	e8 c0 25 00 00       	call   f01026d4 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 00 37 10 f0 	movzbl -0xfefc900(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d e0 36 10 f0 	mov    -0xfefc920(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 ad 36 10 f0       	push   $0xf01036ad
f0100265:	e8 6a 24 00 00       	call   f01026d4 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010030c:	89 fa                	mov    %edi,%edx
f010030e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100314:	89 f8                	mov    %edi,%eax
f0100316:	80 cc 07             	or     $0x7,%ah
f0100319:	85 d2                	test   %edx,%edx
f010031b:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010031e:	89 f8                	mov    %edi,%eax
f0100320:	0f b6 c0             	movzbl %al,%eax
f0100323:	83 f8 09             	cmp    $0x9,%eax
f0100326:	74 74                	je     f010039c <cons_putc+0x113>
f0100328:	83 f8 09             	cmp    $0x9,%eax
f010032b:	7f 0a                	jg     f0100337 <cons_putc+0xae>
f010032d:	83 f8 08             	cmp    $0x8,%eax
f0100330:	74 14                	je     f0100346 <cons_putc+0xbd>
f0100332:	e9 99 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
f0100337:	83 f8 0a             	cmp    $0xa,%eax
f010033a:	74 3a                	je     f0100376 <cons_putc+0xed>
f010033c:	83 f8 0d             	cmp    $0xd,%eax
f010033f:	74 3d                	je     f010037e <cons_putc+0xf5>
f0100341:	e9 8a 00 00 00       	jmp    f01003d0 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100346:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010034d:	66 85 c0             	test   %ax,%ax
f0100350:	0f 84 e6 00 00 00    	je     f010043c <cons_putc+0x1b3>
			crt_pos--;
f0100356:	83 e8 01             	sub    $0x1,%eax
f0100359:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010035f:	0f b7 c0             	movzwl %ax,%eax
f0100362:	66 81 e7 00 ff       	and    $0xff00,%di
f0100367:	83 cf 20             	or     $0x20,%edi
f010036a:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100370:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100374:	eb 78                	jmp    f01003ee <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100376:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010037d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010037e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100385:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010038b:	c1 e8 16             	shr    $0x16,%eax
f010038e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100391:	c1 e0 04             	shl    $0x4,%eax
f0100394:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
f010039a:	eb 52                	jmp    f01003ee <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f010039c:	b8 20 00 00 00       	mov    $0x20,%eax
f01003a1:	e8 e3 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003a6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ab:	e8 d9 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b5:	e8 cf fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01003bf:	e8 c5 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c9:	e8 bb fe ff ff       	call   f0100289 <cons_putc>
f01003ce:	eb 1e                	jmp    f01003ee <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003d0:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003d7:	8d 50 01             	lea    0x1(%eax),%edx
f01003da:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f01003e1:	0f b7 c0             	movzwl %ax,%eax
f01003e4:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003ea:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003ee:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01003f5:	cf 07 
f01003f7:	76 43                	jbe    f010043c <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01003f9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01003fe:	83 ec 04             	sub    $0x4,%esp
f0100401:	68 00 0f 00 00       	push   $0xf00
f0100406:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010040c:	52                   	push   %edx
f010040d:	50                   	push   %eax
f010040e:	e8 06 2e 00 00       	call   f0103219 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100413:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100419:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010041f:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100425:	83 c4 10             	add    $0x10,%esp
f0100428:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010042d:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100430:	39 d0                	cmp    %edx,%eax
f0100432:	75 f4                	jne    f0100428 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100434:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010043b:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010043c:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100442:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100447:	89 ca                	mov    %ecx,%edx
f0100449:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010044a:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f0100451:	8d 71 01             	lea    0x1(%ecx),%esi
f0100454:	89 d8                	mov    %ebx,%eax
f0100456:	66 c1 e8 08          	shr    $0x8,%ax
f010045a:	89 f2                	mov    %esi,%edx
f010045c:	ee                   	out    %al,(%dx)
f010045d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100462:	89 ca                	mov    %ecx,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	89 f2                	mov    %esi,%edx
f0100469:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010046a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010046d:	5b                   	pop    %ebx
f010046e:	5e                   	pop    %esi
f010046f:	5f                   	pop    %edi
f0100470:	5d                   	pop    %ebp
f0100471:	c3                   	ret    

f0100472 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100472:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100479:	74 11                	je     f010048c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010047b:	55                   	push   %ebp
f010047c:	89 e5                	mov    %esp,%ebp
f010047e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100481:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100486:	e8 b0 fc ff ff       	call   f010013b <cons_intr>
}
f010048b:	c9                   	leave  
f010048c:	f3 c3                	repz ret 

f010048e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010048e:	55                   	push   %ebp
f010048f:	89 e5                	mov    %esp,%ebp
f0100491:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100494:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f0100499:	e8 9d fc ff ff       	call   f010013b <cons_intr>
}
f010049e:	c9                   	leave  
f010049f:	c3                   	ret    

f01004a0 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004a6:	e8 c7 ff ff ff       	call   f0100472 <serial_intr>
	kbd_intr();
f01004ab:	e8 de ff ff ff       	call   f010048e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004b0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004b5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004bb:	74 26                	je     f01004e3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004bd:	8d 50 01             	lea    0x1(%eax),%edx
f01004c0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004c6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004cd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004cf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004d5:	75 11                	jne    f01004e8 <cons_getc+0x48>
			cons.rpos = 0;
f01004d7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01004de:	00 00 00 
f01004e1:	eb 05                	jmp    f01004e8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004e8:	c9                   	leave  
f01004e9:	c3                   	ret    

f01004ea <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ea:	55                   	push   %ebp
f01004eb:	89 e5                	mov    %esp,%ebp
f01004ed:	57                   	push   %edi
f01004ee:	56                   	push   %esi
f01004ef:	53                   	push   %ebx
f01004f0:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004f3:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01004fa:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100501:	5a a5 
	if (*cp != 0xA55A) {
f0100503:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010050a:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010050e:	74 11                	je     f0100521 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100510:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f0100517:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010051a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010051f:	eb 16                	jmp    f0100537 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100521:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100528:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010052f:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100532:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010053d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100542:	89 fa                	mov    %edi,%edx
f0100544:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100545:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100548:	89 da                	mov    %ebx,%edx
f010054a:	ec                   	in     (%dx),%al
f010054b:	0f b6 c8             	movzbl %al,%ecx
f010054e:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100551:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100556:	89 fa                	mov    %edi,%edx
f0100558:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010055c:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100562:	0f b6 c0             	movzbl %al,%eax
f0100565:	09 c8                	or     %ecx,%eax
f0100567:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056d:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100572:	b8 00 00 00 00       	mov    $0x0,%eax
f0100577:	89 f2                	mov    %esi,%edx
f0100579:	ee                   	out    %al,(%dx)
f010057a:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010057f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100584:	ee                   	out    %al,(%dx)
f0100585:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010058a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010058f:	89 da                	mov    %ebx,%edx
f0100591:	ee                   	out    %al,(%dx)
f0100592:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100597:	b8 00 00 00 00       	mov    $0x0,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005a2:	b8 03 00 00 00       	mov    $0x3,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b2:	ee                   	out    %al,(%dx)
f01005b3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005b8:	b8 01 00 00 00       	mov    $0x1,%eax
f01005bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005be:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005c3:	ec                   	in     (%dx),%al
f01005c4:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c6:	3c ff                	cmp    $0xff,%al
f01005c8:	0f 95 05 34 65 11 f0 	setne  0xf0116534
f01005cf:	89 f2                	mov    %esi,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d5:	80 f9 ff             	cmp    $0xff,%cl
f01005d8:	75 10                	jne    f01005ea <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005da:	83 ec 0c             	sub    $0xc,%esp
f01005dd:	68 b9 36 10 f0       	push   $0xf01036b9
f01005e2:	e8 ed 20 00 00       	call   f01026d4 <cprintf>
f01005e7:	83 c4 10             	add    $0x10,%esp
}
f01005ea:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 89 fc ff ff       	call   f0100289 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 93 fe ff ff       	call   f01004a0 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    

f010061d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010061d:	55                   	push   %ebp
f010061e:	89 e5                	mov    %esp,%ebp
f0100620:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100623:	68 00 39 10 f0       	push   $0xf0103900
f0100628:	68 1e 39 10 f0       	push   $0xf010391e
f010062d:	68 23 39 10 f0       	push   $0xf0103923
f0100632:	e8 9d 20 00 00       	call   f01026d4 <cprintf>
f0100637:	83 c4 0c             	add    $0xc,%esp
f010063a:	68 b4 39 10 f0       	push   $0xf01039b4
f010063f:	68 2c 39 10 f0       	push   $0xf010392c
f0100644:	68 23 39 10 f0       	push   $0xf0103923
f0100649:	e8 86 20 00 00       	call   f01026d4 <cprintf>
	return 0;
}
f010064e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100653:	c9                   	leave  
f0100654:	c3                   	ret    

f0100655 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010065b:	68 35 39 10 f0       	push   $0xf0103935
f0100660:	e8 6f 20 00 00       	call   f01026d4 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100665:	83 c4 08             	add    $0x8,%esp
f0100668:	68 0c 00 10 00       	push   $0x10000c
f010066d:	68 dc 39 10 f0       	push   $0xf01039dc
f0100672:	e8 5d 20 00 00       	call   f01026d4 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100677:	83 c4 0c             	add    $0xc,%esp
f010067a:	68 0c 00 10 00       	push   $0x10000c
f010067f:	68 0c 00 10 f0       	push   $0xf010000c
f0100684:	68 04 3a 10 f0       	push   $0xf0103a04
f0100689:	e8 46 20 00 00       	call   f01026d4 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068e:	83 c4 0c             	add    $0xc,%esp
f0100691:	68 51 36 10 00       	push   $0x103651
f0100696:	68 51 36 10 f0       	push   $0xf0103651
f010069b:	68 28 3a 10 f0       	push   $0xf0103a28
f01006a0:	e8 2f 20 00 00       	call   f01026d4 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a5:	83 c4 0c             	add    $0xc,%esp
f01006a8:	68 00 63 11 00       	push   $0x116300
f01006ad:	68 00 63 11 f0       	push   $0xf0116300
f01006b2:	68 4c 3a 10 f0       	push   $0xf0103a4c
f01006b7:	e8 18 20 00 00       	call   f01026d4 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006bc:	83 c4 0c             	add    $0xc,%esp
f01006bf:	68 70 69 11 00       	push   $0x116970
f01006c4:	68 70 69 11 f0       	push   $0xf0116970
f01006c9:	68 70 3a 10 f0       	push   $0xf0103a70
f01006ce:	e8 01 20 00 00       	call   f01026d4 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006d3:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
f01006d8:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dd:	83 c4 08             	add    $0x8,%esp
f01006e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006e5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006eb:	85 c0                	test   %eax,%eax
f01006ed:	0f 48 c2             	cmovs  %edx,%eax
f01006f0:	c1 f8 0a             	sar    $0xa,%eax
f01006f3:	50                   	push   %eax
f01006f4:	68 94 3a 10 f0       	push   $0xf0103a94
f01006f9:	e8 d6 1f 00 00       	call   f01026d4 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100705:	55                   	push   %ebp
f0100706:	89 e5                	mov    %esp,%ebp
f0100708:	56                   	push   %esi
f0100709:	53                   	push   %ebx
f010070a:	83 ec 2c             	sub    $0x2c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010070d:	89 eb                	mov    %ebp,%ebx
	// Your code here.
        struct Eipdebuginfo info;
        uint32_t *ebp = (uint32_t *) read_ebp();
        cprintf("Stack backtrace:\n");
f010070f:	68 4e 39 10 f0       	push   $0xf010394e
f0100714:	e8 bb 1f 00 00       	call   f01026d4 <cprintf>
        while (ebp) {
f0100719:	83 c4 10             	add    $0x10,%esp
            cprintf(" ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
            debuginfo_eip(ebp[1], &info);
f010071c:	8d 75 e0             	lea    -0x20(%ebp),%esi
{
	// Your code here.
        struct Eipdebuginfo info;
        uint32_t *ebp = (uint32_t *) read_ebp();
        cprintf("Stack backtrace:\n");
        while (ebp) {
f010071f:	eb 4e                	jmp    f010076f <mon_backtrace+0x6a>
            cprintf(" ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
f0100721:	ff 73 18             	pushl  0x18(%ebx)
f0100724:	ff 73 14             	pushl  0x14(%ebx)
f0100727:	ff 73 10             	pushl  0x10(%ebx)
f010072a:	ff 73 0c             	pushl  0xc(%ebx)
f010072d:	ff 73 08             	pushl  0x8(%ebx)
f0100730:	ff 73 04             	pushl  0x4(%ebx)
f0100733:	53                   	push   %ebx
f0100734:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0100739:	e8 96 1f 00 00       	call   f01026d4 <cprintf>
            debuginfo_eip(ebp[1], &info);
f010073e:	83 c4 18             	add    $0x18,%esp
f0100741:	56                   	push   %esi
f0100742:	ff 73 04             	pushl  0x4(%ebx)
f0100745:	e8 94 20 00 00       	call   f01027de <debuginfo_eip>
            cprintf("\n    %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1]-info.eip_fn_addr);
f010074a:	83 c4 08             	add    $0x8,%esp
f010074d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100750:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100753:	50                   	push   %eax
f0100754:	ff 75 e8             	pushl  -0x18(%ebp)
f0100757:	ff 75 ec             	pushl  -0x14(%ebp)
f010075a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010075d:	ff 75 e0             	pushl  -0x20(%ebp)
f0100760:	68 60 39 10 f0       	push   $0xf0103960
f0100765:	e8 6a 1f 00 00       	call   f01026d4 <cprintf>
            ebp = (uint32_t *) (*ebp);
f010076a:	8b 1b                	mov    (%ebx),%ebx
f010076c:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
        struct Eipdebuginfo info;
        uint32_t *ebp = (uint32_t *) read_ebp();
        cprintf("Stack backtrace:\n");
        while (ebp) {
f010076f:	85 db                	test   %ebx,%ebx
f0100771:	75 ae                	jne    f0100721 <mon_backtrace+0x1c>
            debuginfo_eip(ebp[1], &info);
            cprintf("\n    %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1]-info.eip_fn_addr);
            ebp = (uint32_t *) (*ebp);
        }
	return 0;
}
f0100773:	b8 00 00 00 00       	mov    $0x0,%eax
f0100778:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010077b:	5b                   	pop    %ebx
f010077c:	5e                   	pop    %esi
f010077d:	5d                   	pop    %ebp
f010077e:	c3                   	ret    

f010077f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010077f:	55                   	push   %ebp
f0100780:	89 e5                	mov    %esp,%ebp
f0100782:	57                   	push   %edi
f0100783:	56                   	push   %esi
f0100784:	53                   	push   %ebx
f0100785:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100788:	68 f4 3a 10 f0       	push   $0xf0103af4
f010078d:	e8 42 1f 00 00       	call   f01026d4 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100792:	c7 04 24 18 3b 10 f0 	movl   $0xf0103b18,(%esp)
f0100799:	e8 36 1f 00 00       	call   f01026d4 <cprintf>
f010079e:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007a1:	83 ec 0c             	sub    $0xc,%esp
f01007a4:	68 75 39 10 f0       	push   $0xf0103975
f01007a9:	e8 c7 27 00 00       	call   f0102f75 <readline>
f01007ae:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007b0:	83 c4 10             	add    $0x10,%esp
f01007b3:	85 c0                	test   %eax,%eax
f01007b5:	74 ea                	je     f01007a1 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007b7:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007be:	be 00 00 00 00       	mov    $0x0,%esi
f01007c3:	eb 0a                	jmp    f01007cf <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007c5:	c6 03 00             	movb   $0x0,(%ebx)
f01007c8:	89 f7                	mov    %esi,%edi
f01007ca:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007cd:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007cf:	0f b6 03             	movzbl (%ebx),%eax
f01007d2:	84 c0                	test   %al,%al
f01007d4:	74 63                	je     f0100839 <monitor+0xba>
f01007d6:	83 ec 08             	sub    $0x8,%esp
f01007d9:	0f be c0             	movsbl %al,%eax
f01007dc:	50                   	push   %eax
f01007dd:	68 79 39 10 f0       	push   $0xf0103979
f01007e2:	e8 a8 29 00 00       	call   f010318f <strchr>
f01007e7:	83 c4 10             	add    $0x10,%esp
f01007ea:	85 c0                	test   %eax,%eax
f01007ec:	75 d7                	jne    f01007c5 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01007ee:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007f1:	74 46                	je     f0100839 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007f3:	83 fe 0f             	cmp    $0xf,%esi
f01007f6:	75 14                	jne    f010080c <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007f8:	83 ec 08             	sub    $0x8,%esp
f01007fb:	6a 10                	push   $0x10
f01007fd:	68 7e 39 10 f0       	push   $0xf010397e
f0100802:	e8 cd 1e 00 00       	call   f01026d4 <cprintf>
f0100807:	83 c4 10             	add    $0x10,%esp
f010080a:	eb 95                	jmp    f01007a1 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010080c:	8d 7e 01             	lea    0x1(%esi),%edi
f010080f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100813:	eb 03                	jmp    f0100818 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100815:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100818:	0f b6 03             	movzbl (%ebx),%eax
f010081b:	84 c0                	test   %al,%al
f010081d:	74 ae                	je     f01007cd <monitor+0x4e>
f010081f:	83 ec 08             	sub    $0x8,%esp
f0100822:	0f be c0             	movsbl %al,%eax
f0100825:	50                   	push   %eax
f0100826:	68 79 39 10 f0       	push   $0xf0103979
f010082b:	e8 5f 29 00 00       	call   f010318f <strchr>
f0100830:	83 c4 10             	add    $0x10,%esp
f0100833:	85 c0                	test   %eax,%eax
f0100835:	74 de                	je     f0100815 <monitor+0x96>
f0100837:	eb 94                	jmp    f01007cd <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100839:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100840:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100841:	85 f6                	test   %esi,%esi
f0100843:	0f 84 58 ff ff ff    	je     f01007a1 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100849:	83 ec 08             	sub    $0x8,%esp
f010084c:	68 1e 39 10 f0       	push   $0xf010391e
f0100851:	ff 75 a8             	pushl  -0x58(%ebp)
f0100854:	e8 d8 28 00 00       	call   f0103131 <strcmp>
f0100859:	83 c4 10             	add    $0x10,%esp
f010085c:	85 c0                	test   %eax,%eax
f010085e:	74 1e                	je     f010087e <monitor+0xff>
f0100860:	83 ec 08             	sub    $0x8,%esp
f0100863:	68 2c 39 10 f0       	push   $0xf010392c
f0100868:	ff 75 a8             	pushl  -0x58(%ebp)
f010086b:	e8 c1 28 00 00       	call   f0103131 <strcmp>
f0100870:	83 c4 10             	add    $0x10,%esp
f0100873:	85 c0                	test   %eax,%eax
f0100875:	75 2f                	jne    f01008a6 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100877:	b8 01 00 00 00       	mov    $0x1,%eax
f010087c:	eb 05                	jmp    f0100883 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f010087e:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100883:	83 ec 04             	sub    $0x4,%esp
f0100886:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100889:	01 d0                	add    %edx,%eax
f010088b:	ff 75 08             	pushl  0x8(%ebp)
f010088e:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100891:	51                   	push   %ecx
f0100892:	56                   	push   %esi
f0100893:	ff 14 85 48 3b 10 f0 	call   *-0xfefc4b8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010089a:	83 c4 10             	add    $0x10,%esp
f010089d:	85 c0                	test   %eax,%eax
f010089f:	78 1d                	js     f01008be <monitor+0x13f>
f01008a1:	e9 fb fe ff ff       	jmp    f01007a1 <monitor+0x22>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008a6:	83 ec 08             	sub    $0x8,%esp
f01008a9:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ac:	68 9b 39 10 f0       	push   $0xf010399b
f01008b1:	e8 1e 1e 00 00       	call   f01026d4 <cprintf>
f01008b6:	83 c4 10             	add    $0x10,%esp
f01008b9:	e9 e3 fe ff ff       	jmp    f01007a1 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008c1:	5b                   	pop    %ebx
f01008c2:	5e                   	pop    %esi
f01008c3:	5f                   	pop    %edi
f01008c4:	5d                   	pop    %ebp
f01008c5:	c3                   	ret    

f01008c6 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008c6:	55                   	push   %ebp
f01008c7:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008c9:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f01008d0:	75 11                	jne    f01008e3 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008d2:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f01008d7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008dd:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n==0)
f01008e3:	85 c0                	test   %eax,%eax
f01008e5:	75 07                	jne    f01008ee <boot_alloc+0x28>
		return nextfree;
f01008e7:	a1 38 65 11 f0       	mov    0xf0116538,%eax
f01008ec:	eb 19                	jmp    f0100907 <boot_alloc+0x41>
	result = nextfree;
f01008ee:	8b 15 38 65 11 f0    	mov    0xf0116538,%edx
	nextfree += n;
	nextfree = ROUNDUP((char *)nextfree, PGSIZE);
f01008f4:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f01008fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100900:	a3 38 65 11 f0       	mov    %eax,0xf0116538
	return result;
f0100905:	89 d0                	mov    %edx,%eax
}
f0100907:	5d                   	pop    %ebp
f0100908:	c3                   	ret    

f0100909 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100909:	89 d1                	mov    %edx,%ecx
f010090b:	c1 e9 16             	shr    $0x16,%ecx
f010090e:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100911:	a8 01                	test   $0x1,%al
f0100913:	74 52                	je     f0100967 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100915:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010091a:	89 c1                	mov    %eax,%ecx
f010091c:	c1 e9 0c             	shr    $0xc,%ecx
f010091f:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0100925:	72 1b                	jb     f0100942 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100927:	55                   	push   %ebp
f0100928:	89 e5                	mov    %esp,%ebp
f010092a:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010092d:	50                   	push   %eax
f010092e:	68 58 3b 10 f0       	push   $0xf0103b58
f0100933:	68 e1 02 00 00       	push   $0x2e1
f0100938:	68 ac 42 10 f0       	push   $0xf01042ac
f010093d:	e8 49 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100942:	c1 ea 0c             	shr    $0xc,%edx
f0100945:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010094b:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100952:	89 c2                	mov    %eax,%edx
f0100954:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100957:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010095c:	85 d2                	test   %edx,%edx
f010095e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100963:	0f 44 c2             	cmove  %edx,%eax
f0100966:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100967:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010096c:	c3                   	ret    

f010096d <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f010096d:	55                   	push   %ebp
f010096e:	89 e5                	mov    %esp,%ebp
f0100970:	57                   	push   %edi
f0100971:	56                   	push   %esi
f0100972:	53                   	push   %ebx
f0100973:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100976:	84 c0                	test   %al,%al
f0100978:	0f 85 72 02 00 00    	jne    f0100bf0 <check_page_free_list+0x283>
f010097e:	e9 7f 02 00 00       	jmp    f0100c02 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100983:	83 ec 04             	sub    $0x4,%esp
f0100986:	68 7c 3b 10 f0       	push   $0xf0103b7c
f010098b:	68 24 02 00 00       	push   $0x224
f0100990:	68 ac 42 10 f0       	push   $0xf01042ac
f0100995:	e8 f1 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010099a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010099d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009a0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009a3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009a6:	89 c2                	mov    %eax,%edx
f01009a8:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01009ae:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009b4:	0f 95 c2             	setne  %dl
f01009b7:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009ba:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009be:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009c0:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009c4:	8b 00                	mov    (%eax),%eax
f01009c6:	85 c0                	test   %eax,%eax
f01009c8:	75 dc                	jne    f01009a6 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009d9:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009db:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009de:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009e3:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009e8:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f01009ee:	eb 53                	jmp    f0100a43 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009f0:	89 d8                	mov    %ebx,%eax
f01009f2:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01009f8:	c1 f8 03             	sar    $0x3,%eax
f01009fb:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009fe:	89 c2                	mov    %eax,%edx
f0100a00:	c1 ea 16             	shr    $0x16,%edx
f0100a03:	39 f2                	cmp    %esi,%edx
f0100a05:	73 3a                	jae    f0100a41 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a07:	89 c2                	mov    %eax,%edx
f0100a09:	c1 ea 0c             	shr    $0xc,%edx
f0100a0c:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a12:	72 12                	jb     f0100a26 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a14:	50                   	push   %eax
f0100a15:	68 58 3b 10 f0       	push   $0xf0103b58
f0100a1a:	6a 52                	push   $0x52
f0100a1c:	68 b8 42 10 f0       	push   $0xf01042b8
f0100a21:	e8 65 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a26:	83 ec 04             	sub    $0x4,%esp
f0100a29:	68 80 00 00 00       	push   $0x80
f0100a2e:	68 97 00 00 00       	push   $0x97
f0100a33:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a38:	50                   	push   %eax
f0100a39:	e8 8e 27 00 00       	call   f01031cc <memset>
f0100a3e:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a41:	8b 1b                	mov    (%ebx),%ebx
f0100a43:	85 db                	test   %ebx,%ebx
f0100a45:	75 a9                	jne    f01009f0 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a47:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a4c:	e8 75 fe ff ff       	call   f01008c6 <boot_alloc>
f0100a51:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a54:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a5a:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100a60:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0100a65:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a68:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a6b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a6e:	be 00 00 00 00       	mov    $0x0,%esi
f0100a73:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a76:	e9 30 01 00 00       	jmp    f0100bab <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a7b:	39 ca                	cmp    %ecx,%edx
f0100a7d:	73 19                	jae    f0100a98 <check_page_free_list+0x12b>
f0100a7f:	68 c6 42 10 f0       	push   $0xf01042c6
f0100a84:	68 d2 42 10 f0       	push   $0xf01042d2
f0100a89:	68 3e 02 00 00       	push   $0x23e
f0100a8e:	68 ac 42 10 f0       	push   $0xf01042ac
f0100a93:	e8 f3 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100a98:	39 fa                	cmp    %edi,%edx
f0100a9a:	72 19                	jb     f0100ab5 <check_page_free_list+0x148>
f0100a9c:	68 e7 42 10 f0       	push   $0xf01042e7
f0100aa1:	68 d2 42 10 f0       	push   $0xf01042d2
f0100aa6:	68 3f 02 00 00       	push   $0x23f
f0100aab:	68 ac 42 10 f0       	push   $0xf01042ac
f0100ab0:	e8 d6 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ab5:	89 d0                	mov    %edx,%eax
f0100ab7:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aba:	a8 07                	test   $0x7,%al
f0100abc:	74 19                	je     f0100ad7 <check_page_free_list+0x16a>
f0100abe:	68 a0 3b 10 f0       	push   $0xf0103ba0
f0100ac3:	68 d2 42 10 f0       	push   $0xf01042d2
f0100ac8:	68 40 02 00 00       	push   $0x240
f0100acd:	68 ac 42 10 f0       	push   $0xf01042ac
f0100ad2:	e8 b4 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ad7:	c1 f8 03             	sar    $0x3,%eax
f0100ada:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100add:	85 c0                	test   %eax,%eax
f0100adf:	75 19                	jne    f0100afa <check_page_free_list+0x18d>
f0100ae1:	68 fb 42 10 f0       	push   $0xf01042fb
f0100ae6:	68 d2 42 10 f0       	push   $0xf01042d2
f0100aeb:	68 43 02 00 00       	push   $0x243
f0100af0:	68 ac 42 10 f0       	push   $0xf01042ac
f0100af5:	e8 91 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100afa:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100aff:	75 19                	jne    f0100b1a <check_page_free_list+0x1ad>
f0100b01:	68 0c 43 10 f0       	push   $0xf010430c
f0100b06:	68 d2 42 10 f0       	push   $0xf01042d2
f0100b0b:	68 44 02 00 00       	push   $0x244
f0100b10:	68 ac 42 10 f0       	push   $0xf01042ac
f0100b15:	e8 71 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b1a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b1f:	75 19                	jne    f0100b3a <check_page_free_list+0x1cd>
f0100b21:	68 d4 3b 10 f0       	push   $0xf0103bd4
f0100b26:	68 d2 42 10 f0       	push   $0xf01042d2
f0100b2b:	68 45 02 00 00       	push   $0x245
f0100b30:	68 ac 42 10 f0       	push   $0xf01042ac
f0100b35:	e8 51 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b3a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b3f:	75 19                	jne    f0100b5a <check_page_free_list+0x1ed>
f0100b41:	68 25 43 10 f0       	push   $0xf0104325
f0100b46:	68 d2 42 10 f0       	push   $0xf01042d2
f0100b4b:	68 46 02 00 00       	push   $0x246
f0100b50:	68 ac 42 10 f0       	push   $0xf01042ac
f0100b55:	e8 31 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b5a:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b5f:	76 3f                	jbe    f0100ba0 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b61:	89 c3                	mov    %eax,%ebx
f0100b63:	c1 eb 0c             	shr    $0xc,%ebx
f0100b66:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b69:	77 12                	ja     f0100b7d <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b6b:	50                   	push   %eax
f0100b6c:	68 58 3b 10 f0       	push   $0xf0103b58
f0100b71:	6a 52                	push   $0x52
f0100b73:	68 b8 42 10 f0       	push   $0xf01042b8
f0100b78:	e8 0e f5 ff ff       	call   f010008b <_panic>
f0100b7d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b82:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b85:	76 1e                	jbe    f0100ba5 <check_page_free_list+0x238>
f0100b87:	68 f8 3b 10 f0       	push   $0xf0103bf8
f0100b8c:	68 d2 42 10 f0       	push   $0xf01042d2
f0100b91:	68 47 02 00 00       	push   $0x247
f0100b96:	68 ac 42 10 f0       	push   $0xf01042ac
f0100b9b:	e8 eb f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100ba0:	83 c6 01             	add    $0x1,%esi
f0100ba3:	eb 04                	jmp    f0100ba9 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100ba5:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ba9:	8b 12                	mov    (%edx),%edx
f0100bab:	85 d2                	test   %edx,%edx
f0100bad:	0f 85 c8 fe ff ff    	jne    f0100a7b <check_page_free_list+0x10e>
f0100bb3:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bb6:	85 f6                	test   %esi,%esi
f0100bb8:	7f 19                	jg     f0100bd3 <check_page_free_list+0x266>
f0100bba:	68 3f 43 10 f0       	push   $0xf010433f
f0100bbf:	68 d2 42 10 f0       	push   $0xf01042d2
f0100bc4:	68 4f 02 00 00       	push   $0x24f
f0100bc9:	68 ac 42 10 f0       	push   $0xf01042ac
f0100bce:	e8 b8 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100bd3:	85 db                	test   %ebx,%ebx
f0100bd5:	7f 42                	jg     f0100c19 <check_page_free_list+0x2ac>
f0100bd7:	68 51 43 10 f0       	push   $0xf0104351
f0100bdc:	68 d2 42 10 f0       	push   $0xf01042d2
f0100be1:	68 50 02 00 00       	push   $0x250
f0100be6:	68 ac 42 10 f0       	push   $0xf01042ac
f0100beb:	e8 9b f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bf0:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100bf5:	85 c0                	test   %eax,%eax
f0100bf7:	0f 85 9d fd ff ff    	jne    f010099a <check_page_free_list+0x2d>
f0100bfd:	e9 81 fd ff ff       	jmp    f0100983 <check_page_free_list+0x16>
f0100c02:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100c09:	0f 84 74 fd ff ff    	je     f0100983 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c0f:	be 00 04 00 00       	mov    $0x400,%esi
f0100c14:	e9 cf fd ff ff       	jmp    f01009e8 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c19:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c1c:	5b                   	pop    %ebx
f0100c1d:	5e                   	pop    %esi
f0100c1e:	5f                   	pop    %edi
f0100c1f:	5d                   	pop    %ebp
f0100c20:	c3                   	ret    

f0100c21 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c21:	55                   	push   %ebp
f0100c22:	89 e5                	mov    %esp,%ebp
f0100c24:	56                   	push   %esi
f0100c25:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c26:	be 00 00 00 00       	mov    $0x0,%esi
f0100c2b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c30:	e9 c5 00 00 00       	jmp    f0100cfa <page_init+0xd9>
		if(i == 0)
f0100c35:	85 db                	test   %ebx,%ebx
f0100c37:	75 16                	jne    f0100c4f <page_init+0x2e>
		{
			pages[i].pp_ref = 1;
f0100c39:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100c3e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100c44:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100c4a:	e9 a5 00 00 00       	jmp    f0100cf4 <page_init+0xd3>
		}
		else if(i>=1 && i<npages_basemem)
f0100c4f:	3b 1d 40 65 11 f0    	cmp    0xf0116540,%ebx
f0100c55:	73 25                	jae    f0100c7c <page_init+0x5b>
		{
			pages[i].pp_ref = 0;
f0100c57:	89 f0                	mov    %esi,%eax
f0100c59:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c5f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100c65:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100c6b:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100c6d:	89 f0                	mov    %esi,%eax
f0100c6f:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c75:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
f0100c7a:	eb 78                	jmp    f0100cf4 <page_init+0xd3>
		}
		else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE)
f0100c7c:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100c82:	83 f8 5f             	cmp    $0x5f,%eax
f0100c85:	77 16                	ja     f0100c9d <page_init+0x7c>
		{
			pages[i].pp_ref = 1;
f0100c87:	89 f0                	mov    %esi,%eax
f0100c89:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c8f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100c95:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100c9b:	eb 57                	jmp    f0100cf4 <page_init+0xd3>
		}
		else if( i >= EXTPHYSMEM / PGSIZE && 
f0100c9d:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100ca3:	76 2c                	jbe    f0100cd1 <page_init+0xb0>
			i < ((int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
f0100ca5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100caa:	e8 17 fc ff ff       	call   f01008c6 <boot_alloc>
		else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE)
		{
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}
		else if( i >= EXTPHYSMEM / PGSIZE && 
f0100caf:	05 00 00 00 10       	add    $0x10000000,%eax
f0100cb4:	c1 e8 0c             	shr    $0xc,%eax
f0100cb7:	39 c3                	cmp    %eax,%ebx
f0100cb9:	73 16                	jae    f0100cd1 <page_init+0xb0>
			i < ((int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
		{
			pages[i].pp_ref = 1;
f0100cbb:	89 f0                	mov    %esi,%eax
f0100cbd:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cc3:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100cc9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100ccf:	eb 23                	jmp    f0100cf4 <page_init+0xd3>
		}
		else
		{
		pages[i].pp_ref = 0;
f0100cd1:	89 f0                	mov    %esi,%eax
f0100cd3:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cd9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100cdf:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100ce5:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100ce7:	89 f0                	mov    %esi,%eax
f0100ce9:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cef:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100cf4:	83 c3 01             	add    $0x1,%ebx
f0100cf7:	83 c6 08             	add    $0x8,%esi
f0100cfa:	3b 1d 64 69 11 f0    	cmp    0xf0116964,%ebx
f0100d00:	0f 82 2f ff ff ff    	jb     f0100c35 <page_init+0x14>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
		}
	}
}
f0100d06:	5b                   	pop    %ebx
f0100d07:	5e                   	pop    %esi
f0100d08:	5d                   	pop    %ebp
f0100d09:	c3                   	ret    

f0100d0a <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d0a:	55                   	push   %ebp
f0100d0b:	89 e5                	mov    %esp,%ebp
f0100d0d:	53                   	push   %ebx
f0100d0e:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (page_free_list == NULL)
f0100d11:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d17:	85 db                	test   %ebx,%ebx
f0100d19:	74 58                	je     f0100d73 <page_alloc+0x69>
	return NULL;
	struct PageInfo* page = page_free_list;
	page_free_list = page->pp_link;
f0100d1b:	8b 03                	mov    (%ebx),%eax
f0100d1d:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	page->pp_link = 0;
f0100d22:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100d28:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d2c:	74 45                	je     f0100d73 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d2e:	89 d8                	mov    %ebx,%eax
f0100d30:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100d36:	c1 f8 03             	sar    $0x3,%eax
f0100d39:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d3c:	89 c2                	mov    %eax,%edx
f0100d3e:	c1 ea 0c             	shr    $0xc,%edx
f0100d41:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d47:	72 12                	jb     f0100d5b <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d49:	50                   	push   %eax
f0100d4a:	68 58 3b 10 f0       	push   $0xf0103b58
f0100d4f:	6a 52                	push   $0x52
f0100d51:	68 b8 42 10 f0       	push   $0xf01042b8
f0100d56:	e8 30 f3 ff ff       	call   f010008b <_panic>
		memset(page2kva(page), 0, PGSIZE);
f0100d5b:	83 ec 04             	sub    $0x4,%esp
f0100d5e:	68 00 10 00 00       	push   $0x1000
f0100d63:	6a 00                	push   $0x0
f0100d65:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d6a:	50                   	push   %eax
f0100d6b:	e8 5c 24 00 00       	call   f01031cc <memset>
f0100d70:	83 c4 10             	add    $0x10,%esp
	return page;
}
f0100d73:	89 d8                	mov    %ebx,%eax
f0100d75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d78:	c9                   	leave  
f0100d79:	c3                   	ret    

f0100d7a <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d7a:	55                   	push   %ebp
f0100d7b:	89 e5                	mov    %esp,%ebp
f0100d7d:	83 ec 08             	sub    $0x8,%esp
f0100d80:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_link != 0 || pp->pp_ref != 0)
f0100d83:	83 38 00             	cmpl   $0x0,(%eax)
f0100d86:	75 07                	jne    f0100d8f <page_free+0x15>
f0100d88:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d8d:	74 17                	je     f0100da6 <page_free+0x2c>
		panic("page_free is not right");
f0100d8f:	83 ec 04             	sub    $0x4,%esp
f0100d92:	68 62 43 10 f0       	push   $0xf0104362
f0100d97:	68 45 01 00 00       	push   $0x145
f0100d9c:	68 ac 42 10 f0       	push   $0xf01042ac
f0100da1:	e8 e5 f2 ff ff       	call   f010008b <_panic>
	pp->pp_link = page_free_list;
f0100da6:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100dac:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100dae:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	return;
}
f0100db3:	c9                   	leave  
f0100db4:	c3                   	ret    

f0100db5 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100db5:	55                   	push   %ebp
f0100db6:	89 e5                	mov    %esp,%ebp
f0100db8:	83 ec 08             	sub    $0x8,%esp
f0100dbb:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100dbe:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100dc2:	83 e8 01             	sub    $0x1,%eax
f0100dc5:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100dc9:	66 85 c0             	test   %ax,%ax
f0100dcc:	75 0c                	jne    f0100dda <page_decref+0x25>
		page_free(pp);
f0100dce:	83 ec 0c             	sub    $0xc,%esp
f0100dd1:	52                   	push   %edx
f0100dd2:	e8 a3 ff ff ff       	call   f0100d7a <page_free>
f0100dd7:	83 c4 10             	add    $0x10,%esp
}
f0100dda:	c9                   	leave  
f0100ddb:	c3                   	ret    

f0100ddc <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ddc:	55                   	push   %ebp
f0100ddd:	89 e5                	mov    %esp,%ebp
f0100ddf:	56                   	push   %esi
f0100de0:	53                   	push   %ebx
f0100de1:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	unsigned int page_off;
	pte_t* page_base = NULL;
	struct PageInfo* new_page = NULL;
	unsigned int dic_off = PDX(va);
	pde_t* dic_entry_ptr = pgdir + dic_off;
f0100de4:	89 f3                	mov    %esi,%ebx
f0100de6:	c1 eb 16             	shr    $0x16,%ebx
f0100de9:	c1 e3 02             	shl    $0x2,%ebx
f0100dec:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*dic_entry_ptr & PTE_P))
f0100def:	f6 03 01             	testb  $0x1,(%ebx)
f0100df2:	75 2d                	jne    f0100e21 <pgdir_walk+0x45>
	{
		if(create)
f0100df4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100df8:	74 62                	je     f0100e5c <pgdir_walk+0x80>
		{
			new_page = page_alloc(1);
f0100dfa:	83 ec 0c             	sub    $0xc,%esp
f0100dfd:	6a 01                	push   $0x1
f0100dff:	e8 06 ff ff ff       	call   f0100d0a <page_alloc>
			if(new_page == NULL) return NULL;
f0100e04:	83 c4 10             	add    $0x10,%esp
f0100e07:	85 c0                	test   %eax,%eax
f0100e09:	74 58                	je     f0100e63 <pgdir_walk+0x87>
			new_page->pp_ref++;
f0100e0b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			*dic_entry_ptr = (page2pa(new_page)|PTE_P|PTE_W|PTE_U);
f0100e10:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100e16:	c1 f8 03             	sar    $0x3,%eax
f0100e19:	c1 e0 0c             	shl    $0xc,%eax
f0100e1c:	83 c8 07             	or     $0x7,%eax
f0100e1f:	89 03                	mov    %eax,(%ebx)
		}
		else
		return NULL;
	}
	page_off = PTX(va);
f0100e21:	c1 ee 0c             	shr    $0xc,%esi
f0100e24:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100e2a:	8b 03                	mov    (%ebx),%eax
f0100e2c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e31:	89 c2                	mov    %eax,%edx
f0100e33:	c1 ea 0c             	shr    $0xc,%edx
f0100e36:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100e3c:	72 15                	jb     f0100e53 <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e3e:	50                   	push   %eax
f0100e3f:	68 58 3b 10 f0       	push   $0xf0103b58
f0100e44:	68 82 01 00 00       	push   $0x182
f0100e49:	68 ac 42 10 f0       	push   $0xf01042ac
f0100e4e:	e8 38 f2 ff ff       	call   f010008b <_panic>
	return &page_base[page_off];
f0100e53:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e5a:	eb 0c                	jmp    f0100e68 <pgdir_walk+0x8c>
			if(new_page == NULL) return NULL;
			new_page->pp_ref++;
			*dic_entry_ptr = (page2pa(new_page)|PTE_P|PTE_W|PTE_U);
		}
		else
		return NULL;
f0100e5c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e61:	eb 05                	jmp    f0100e68 <pgdir_walk+0x8c>
	if(!(*dic_entry_ptr & PTE_P))
	{
		if(create)
		{
			new_page = page_alloc(1);
			if(new_page == NULL) return NULL;
f0100e63:	b8 00 00 00 00       	mov    $0x0,%eax
		return NULL;
	}
	page_off = PTX(va);
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[page_off];
}
f0100e68:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e6b:	5b                   	pop    %ebx
f0100e6c:	5e                   	pop    %esi
f0100e6d:	5d                   	pop    %ebp
f0100e6e:	c3                   	ret    

f0100e6f <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e6f:	55                   	push   %ebp
f0100e70:	89 e5                	mov    %esp,%ebp
f0100e72:	57                   	push   %edi
f0100e73:	56                   	push   %esi
f0100e74:	53                   	push   %ebx
f0100e75:	83 ec 1c             	sub    $0x1c,%esp
f0100e78:	89 c7                	mov    %eax,%edi
f0100e7a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e7d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0;nadd < size; nadd+= PGSIZE)
f0100e80:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		entry = pgdir_walk(pgdir, (void*)va,1);
		*entry = (pa|perm|PTE_P);
f0100e85:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e88:	83 c8 01             	or     $0x1,%eax
f0100e8b:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0;nadd < size; nadd+= PGSIZE)
f0100e8e:	eb 1f                	jmp    f0100eaf <boot_map_region+0x40>
	{
		entry = pgdir_walk(pgdir, (void*)va,1);
f0100e90:	83 ec 04             	sub    $0x4,%esp
f0100e93:	6a 01                	push   $0x1
f0100e95:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e98:	01 d8                	add    %ebx,%eax
f0100e9a:	50                   	push   %eax
f0100e9b:	57                   	push   %edi
f0100e9c:	e8 3b ff ff ff       	call   f0100ddc <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f0100ea1:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100ea4:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0;nadd < size; nadd+= PGSIZE)
f0100ea6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100eac:	83 c4 10             	add    $0x10,%esp
f0100eaf:	89 de                	mov    %ebx,%esi
f0100eb1:	03 75 08             	add    0x8(%ebp),%esi
f0100eb4:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100eb7:	77 d7                	ja     f0100e90 <boot_map_region+0x21>
		entry = pgdir_walk(pgdir, (void*)va,1);
		*entry = (pa|perm|PTE_P);
		pa += PGSIZE;
		va += PGSIZE;
	}
}
f0100eb9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ebc:	5b                   	pop    %ebx
f0100ebd:	5e                   	pop    %esi
f0100ebe:	5f                   	pop    %edi
f0100ebf:	5d                   	pop    %ebp
f0100ec0:	c3                   	ret    

f0100ec1 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ec1:	55                   	push   %ebp
f0100ec2:	89 e5                	mov    %esp,%ebp
f0100ec4:	53                   	push   %ebx
f0100ec5:	83 ec 08             	sub    $0x8,%esp
f0100ec8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;
	entry = pgdir_walk(pgdir,va,0);
f0100ecb:	6a 00                	push   $0x0
f0100ecd:	ff 75 0c             	pushl  0xc(%ebp)
f0100ed0:	ff 75 08             	pushl  0x8(%ebp)
f0100ed3:	e8 04 ff ff ff       	call   f0100ddc <pgdir_walk>
	if(entry == NULL)
f0100ed8:	83 c4 10             	add    $0x10,%esp
f0100edb:	85 c0                	test   %eax,%eax
f0100edd:	74 38                	je     f0100f17 <page_lookup+0x56>
f0100edf:	89 c1                	mov    %eax,%ecx
		return NULL;
	if(!(*entry &PTE_P))
f0100ee1:	8b 10                	mov    (%eax),%edx
f0100ee3:	f6 c2 01             	test   $0x1,%dl
f0100ee6:	74 36                	je     f0100f1e <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ee8:	c1 ea 0c             	shr    $0xc,%edx
f0100eeb:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100ef1:	72 14                	jb     f0100f07 <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f0100ef3:	83 ec 04             	sub    $0x4,%esp
f0100ef6:	68 40 3c 10 f0       	push   $0xf0103c40
f0100efb:	6a 4b                	push   $0x4b
f0100efd:	68 b8 42 10 f0       	push   $0xf01042b8
f0100f02:	e8 84 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f07:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0100f0c:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		return NULL;
	ret = pa2page(PTE_ADDR(*entry));
	if(pte_store != NULL)
f0100f0f:	85 db                	test   %ebx,%ebx
f0100f11:	74 10                	je     f0100f23 <page_lookup+0x62>
	{
		*pte_store = entry;
f0100f13:	89 0b                	mov    %ecx,(%ebx)
f0100f15:	eb 0c                	jmp    f0100f23 <page_lookup+0x62>
	// Fill this function in
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;
	entry = pgdir_walk(pgdir,va,0);
	if(entry == NULL)
		return NULL;
f0100f17:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f1c:	eb 05                	jmp    f0100f23 <page_lookup+0x62>
	if(!(*entry &PTE_P))
		return NULL;
f0100f1e:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		*pte_store = entry;
	}
	return ret;

}
f0100f23:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f26:	c9                   	leave  
f0100f27:	c3                   	ret    

f0100f28 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f28:	55                   	push   %ebp
f0100f29:	89 e5                	mov    %esp,%ebp
f0100f2b:	53                   	push   %ebx
f0100f2c:	83 ec 18             	sub    $0x18,%esp
f0100f2f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte_t **pte_store = &pte;
	struct PageInfo *pp = page_lookup(pgdir,va,pte_store);
f0100f32:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f35:	50                   	push   %eax
f0100f36:	53                   	push   %ebx
f0100f37:	ff 75 08             	pushl  0x8(%ebp)
f0100f3a:	e8 82 ff ff ff       	call   f0100ec1 <page_lookup>
	if(!pp)
f0100f3f:	83 c4 10             	add    $0x10,%esp
f0100f42:	85 c0                	test   %eax,%eax
f0100f44:	74 18                	je     f0100f5e <page_remove+0x36>
		return;
	page_decref(pp);
f0100f46:	83 ec 0c             	sub    $0xc,%esp
f0100f49:	50                   	push   %eax
f0100f4a:	e8 66 fe ff ff       	call   f0100db5 <page_decref>
	**pte_store = 0;
f0100f4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f58:	0f 01 3b             	invlpg (%ebx)
f0100f5b:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);
}
f0100f5e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f61:	c9                   	leave  
f0100f62:	c3                   	ret    

f0100f63 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f63:	55                   	push   %ebp
f0100f64:	89 e5                	mov    %esp,%ebp
f0100f66:	57                   	push   %edi
f0100f67:	56                   	push   %esi
f0100f68:	53                   	push   %ebx
f0100f69:	83 ec 10             	sub    $0x10,%esp
f0100f6c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f6f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t*entry = NULL;
	entry = pgdir_walk(pgdir,va,1);
f0100f72:	6a 01                	push   $0x1
f0100f74:	ff 75 10             	pushl  0x10(%ebp)
f0100f77:	56                   	push   %esi
f0100f78:	e8 5f fe ff ff       	call   f0100ddc <pgdir_walk>
	if(entry == NULL) return -E_NO_MEM;
f0100f7d:	83 c4 10             	add    $0x10,%esp
f0100f80:	85 c0                	test   %eax,%eax
f0100f82:	74 4a                	je     f0100fce <page_insert+0x6b>
f0100f84:	89 c7                	mov    %eax,%edi
	pp->pp_ref++;
f0100f86:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*entry)&PTE_P)
f0100f8b:	f6 00 01             	testb  $0x1,(%eax)
f0100f8e:	74 15                	je     f0100fa5 <page_insert+0x42>
f0100f90:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f93:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f0100f96:	83 ec 08             	sub    $0x8,%esp
f0100f99:	ff 75 10             	pushl  0x10(%ebp)
f0100f9c:	56                   	push   %esi
f0100f9d:	e8 86 ff ff ff       	call   f0100f28 <page_remove>
f0100fa2:	83 c4 10             	add    $0x10,%esp
	}
	*entry = (page2pa(pp)|perm|PTE_P);
f0100fa5:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100fab:	c1 fb 03             	sar    $0x3,%ebx
f0100fae:	c1 e3 0c             	shl    $0xc,%ebx
f0100fb1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fb4:	83 c8 01             	or     $0x1,%eax
f0100fb7:	09 c3                	or     %eax,%ebx
f0100fb9:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;
f0100fbb:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fbe:	c1 e8 16             	shr    $0x16,%eax
f0100fc1:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fc4:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f0100fc7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fcc:	eb 05                	jmp    f0100fd3 <page_insert+0x70>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t*entry = NULL;
	entry = pgdir_walk(pgdir,va,1);
	if(entry == NULL) return -E_NO_MEM;
f0100fce:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);
	}
	*entry = (page2pa(pp)|perm|PTE_P);
	pgdir[PDX(va)] |= perm;
	return 0;
}
f0100fd3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fd6:	5b                   	pop    %ebx
f0100fd7:	5e                   	pop    %esi
f0100fd8:	5f                   	pop    %edi
f0100fd9:	5d                   	pop    %ebp
f0100fda:	c3                   	ret    

f0100fdb <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100fdb:	55                   	push   %ebp
f0100fdc:	89 e5                	mov    %esp,%ebp
f0100fde:	57                   	push   %edi
f0100fdf:	56                   	push   %esi
f0100fe0:	53                   	push   %ebx
f0100fe1:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100fe4:	6a 15                	push   $0x15
f0100fe6:	e8 82 16 00 00       	call   f010266d <mc146818_read>
f0100feb:	89 c3                	mov    %eax,%ebx
f0100fed:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100ff4:	e8 74 16 00 00       	call   f010266d <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100ff9:	c1 e0 08             	shl    $0x8,%eax
f0100ffc:	09 d8                	or     %ebx,%eax
f0100ffe:	c1 e0 0a             	shl    $0xa,%eax
f0101001:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101007:	85 c0                	test   %eax,%eax
f0101009:	0f 48 c2             	cmovs  %edx,%eax
f010100c:	c1 f8 0c             	sar    $0xc,%eax
f010100f:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101014:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010101b:	e8 4d 16 00 00       	call   f010266d <mc146818_read>
f0101020:	89 c3                	mov    %eax,%ebx
f0101022:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101029:	e8 3f 16 00 00       	call   f010266d <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010102e:	c1 e0 08             	shl    $0x8,%eax
f0101031:	09 d8                	or     %ebx,%eax
f0101033:	c1 e0 0a             	shl    $0xa,%eax
f0101036:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010103c:	83 c4 10             	add    $0x10,%esp
f010103f:	85 c0                	test   %eax,%eax
f0101041:	0f 48 c2             	cmovs  %edx,%eax
f0101044:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101047:	85 c0                	test   %eax,%eax
f0101049:	74 0e                	je     f0101059 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010104b:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101051:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f0101057:	eb 0c                	jmp    f0101065 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101059:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f010105f:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101065:	c1 e0 0c             	shl    $0xc,%eax
f0101068:	c1 e8 0a             	shr    $0xa,%eax
f010106b:	50                   	push   %eax
f010106c:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f0101071:	c1 e0 0c             	shl    $0xc,%eax
f0101074:	c1 e8 0a             	shr    $0xa,%eax
f0101077:	50                   	push   %eax
f0101078:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010107d:	c1 e0 0c             	shl    $0xc,%eax
f0101080:	c1 e8 0a             	shr    $0xa,%eax
f0101083:	50                   	push   %eax
f0101084:	68 60 3c 10 f0       	push   $0xf0103c60
f0101089:	e8 46 16 00 00       	call   f01026d4 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010108e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101093:	e8 2e f8 ff ff       	call   f01008c6 <boot_alloc>
f0101098:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f010109d:	83 c4 0c             	add    $0xc,%esp
f01010a0:	68 00 10 00 00       	push   $0x1000
f01010a5:	6a 00                	push   $0x0
f01010a7:	50                   	push   %eax
f01010a8:	e8 1f 21 00 00       	call   f01031cc <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010ad:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010b2:	83 c4 10             	add    $0x10,%esp
f01010b5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010ba:	77 15                	ja     f01010d1 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010bc:	50                   	push   %eax
f01010bd:	68 9c 3c 10 f0       	push   $0xf0103c9c
f01010c2:	68 8e 00 00 00       	push   $0x8e
f01010c7:	68 ac 42 10 f0       	push   $0xf01042ac
f01010cc:	e8 ba ef ff ff       	call   f010008b <_panic>
f01010d1:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010d7:	83 ca 05             	or     $0x5,%edx
f01010da:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = boot_alloc(npages * sizeof (struct PageInfo));
f01010e0:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01010e5:	c1 e0 03             	shl    $0x3,%eax
f01010e8:	e8 d9 f7 ff ff       	call   f01008c6 <boot_alloc>
f01010ed:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages, 0, npages* sizeof(struct PageInfo));
f01010f2:	83 ec 04             	sub    $0x4,%esp
f01010f5:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f01010fb:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101102:	52                   	push   %edx
f0101103:	6a 00                	push   $0x0
f0101105:	50                   	push   %eax
f0101106:	e8 c1 20 00 00       	call   f01031cc <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010110b:	e8 11 fb ff ff       	call   f0100c21 <page_init>

	check_page_free_list(1);
f0101110:	b8 01 00 00 00       	mov    $0x1,%eax
f0101115:	e8 53 f8 ff ff       	call   f010096d <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010111a:	83 c4 10             	add    $0x10,%esp
f010111d:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f0101124:	75 17                	jne    f010113d <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0101126:	83 ec 04             	sub    $0x4,%esp
f0101129:	68 79 43 10 f0       	push   $0xf0104379
f010112e:	68 61 02 00 00       	push   $0x261
f0101133:	68 ac 42 10 f0       	push   $0xf01042ac
f0101138:	e8 4e ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010113d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101142:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101147:	eb 05                	jmp    f010114e <mem_init+0x173>
		++nfree;
f0101149:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010114c:	8b 00                	mov    (%eax),%eax
f010114e:	85 c0                	test   %eax,%eax
f0101150:	75 f7                	jne    f0101149 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101152:	83 ec 0c             	sub    $0xc,%esp
f0101155:	6a 00                	push   $0x0
f0101157:	e8 ae fb ff ff       	call   f0100d0a <page_alloc>
f010115c:	89 c7                	mov    %eax,%edi
f010115e:	83 c4 10             	add    $0x10,%esp
f0101161:	85 c0                	test   %eax,%eax
f0101163:	75 19                	jne    f010117e <mem_init+0x1a3>
f0101165:	68 94 43 10 f0       	push   $0xf0104394
f010116a:	68 d2 42 10 f0       	push   $0xf01042d2
f010116f:	68 69 02 00 00       	push   $0x269
f0101174:	68 ac 42 10 f0       	push   $0xf01042ac
f0101179:	e8 0d ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010117e:	83 ec 0c             	sub    $0xc,%esp
f0101181:	6a 00                	push   $0x0
f0101183:	e8 82 fb ff ff       	call   f0100d0a <page_alloc>
f0101188:	89 c6                	mov    %eax,%esi
f010118a:	83 c4 10             	add    $0x10,%esp
f010118d:	85 c0                	test   %eax,%eax
f010118f:	75 19                	jne    f01011aa <mem_init+0x1cf>
f0101191:	68 aa 43 10 f0       	push   $0xf01043aa
f0101196:	68 d2 42 10 f0       	push   $0xf01042d2
f010119b:	68 6a 02 00 00       	push   $0x26a
f01011a0:	68 ac 42 10 f0       	push   $0xf01042ac
f01011a5:	e8 e1 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011aa:	83 ec 0c             	sub    $0xc,%esp
f01011ad:	6a 00                	push   $0x0
f01011af:	e8 56 fb ff ff       	call   f0100d0a <page_alloc>
f01011b4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011b7:	83 c4 10             	add    $0x10,%esp
f01011ba:	85 c0                	test   %eax,%eax
f01011bc:	75 19                	jne    f01011d7 <mem_init+0x1fc>
f01011be:	68 c0 43 10 f0       	push   $0xf01043c0
f01011c3:	68 d2 42 10 f0       	push   $0xf01042d2
f01011c8:	68 6b 02 00 00       	push   $0x26b
f01011cd:	68 ac 42 10 f0       	push   $0xf01042ac
f01011d2:	e8 b4 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011d7:	39 f7                	cmp    %esi,%edi
f01011d9:	75 19                	jne    f01011f4 <mem_init+0x219>
f01011db:	68 d6 43 10 f0       	push   $0xf01043d6
f01011e0:	68 d2 42 10 f0       	push   $0xf01042d2
f01011e5:	68 6e 02 00 00       	push   $0x26e
f01011ea:	68 ac 42 10 f0       	push   $0xf01042ac
f01011ef:	e8 97 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011f7:	39 c6                	cmp    %eax,%esi
f01011f9:	74 04                	je     f01011ff <mem_init+0x224>
f01011fb:	39 c7                	cmp    %eax,%edi
f01011fd:	75 19                	jne    f0101218 <mem_init+0x23d>
f01011ff:	68 c0 3c 10 f0       	push   $0xf0103cc0
f0101204:	68 d2 42 10 f0       	push   $0xf01042d2
f0101209:	68 6f 02 00 00       	push   $0x26f
f010120e:	68 ac 42 10 f0       	push   $0xf01042ac
f0101213:	e8 73 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101218:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010121e:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0101224:	c1 e2 0c             	shl    $0xc,%edx
f0101227:	89 f8                	mov    %edi,%eax
f0101229:	29 c8                	sub    %ecx,%eax
f010122b:	c1 f8 03             	sar    $0x3,%eax
f010122e:	c1 e0 0c             	shl    $0xc,%eax
f0101231:	39 d0                	cmp    %edx,%eax
f0101233:	72 19                	jb     f010124e <mem_init+0x273>
f0101235:	68 e8 43 10 f0       	push   $0xf01043e8
f010123a:	68 d2 42 10 f0       	push   $0xf01042d2
f010123f:	68 70 02 00 00       	push   $0x270
f0101244:	68 ac 42 10 f0       	push   $0xf01042ac
f0101249:	e8 3d ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010124e:	89 f0                	mov    %esi,%eax
f0101250:	29 c8                	sub    %ecx,%eax
f0101252:	c1 f8 03             	sar    $0x3,%eax
f0101255:	c1 e0 0c             	shl    $0xc,%eax
f0101258:	39 c2                	cmp    %eax,%edx
f010125a:	77 19                	ja     f0101275 <mem_init+0x29a>
f010125c:	68 05 44 10 f0       	push   $0xf0104405
f0101261:	68 d2 42 10 f0       	push   $0xf01042d2
f0101266:	68 71 02 00 00       	push   $0x271
f010126b:	68 ac 42 10 f0       	push   $0xf01042ac
f0101270:	e8 16 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101275:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101278:	29 c8                	sub    %ecx,%eax
f010127a:	c1 f8 03             	sar    $0x3,%eax
f010127d:	c1 e0 0c             	shl    $0xc,%eax
f0101280:	39 c2                	cmp    %eax,%edx
f0101282:	77 19                	ja     f010129d <mem_init+0x2c2>
f0101284:	68 22 44 10 f0       	push   $0xf0104422
f0101289:	68 d2 42 10 f0       	push   $0xf01042d2
f010128e:	68 72 02 00 00       	push   $0x272
f0101293:	68 ac 42 10 f0       	push   $0xf01042ac
f0101298:	e8 ee ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010129d:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012a2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012a5:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012ac:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012af:	83 ec 0c             	sub    $0xc,%esp
f01012b2:	6a 00                	push   $0x0
f01012b4:	e8 51 fa ff ff       	call   f0100d0a <page_alloc>
f01012b9:	83 c4 10             	add    $0x10,%esp
f01012bc:	85 c0                	test   %eax,%eax
f01012be:	74 19                	je     f01012d9 <mem_init+0x2fe>
f01012c0:	68 3f 44 10 f0       	push   $0xf010443f
f01012c5:	68 d2 42 10 f0       	push   $0xf01042d2
f01012ca:	68 79 02 00 00       	push   $0x279
f01012cf:	68 ac 42 10 f0       	push   $0xf01042ac
f01012d4:	e8 b2 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012d9:	83 ec 0c             	sub    $0xc,%esp
f01012dc:	57                   	push   %edi
f01012dd:	e8 98 fa ff ff       	call   f0100d7a <page_free>
	page_free(pp1);
f01012e2:	89 34 24             	mov    %esi,(%esp)
f01012e5:	e8 90 fa ff ff       	call   f0100d7a <page_free>
	page_free(pp2);
f01012ea:	83 c4 04             	add    $0x4,%esp
f01012ed:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012f0:	e8 85 fa ff ff       	call   f0100d7a <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012f5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012fc:	e8 09 fa ff ff       	call   f0100d0a <page_alloc>
f0101301:	89 c6                	mov    %eax,%esi
f0101303:	83 c4 10             	add    $0x10,%esp
f0101306:	85 c0                	test   %eax,%eax
f0101308:	75 19                	jne    f0101323 <mem_init+0x348>
f010130a:	68 94 43 10 f0       	push   $0xf0104394
f010130f:	68 d2 42 10 f0       	push   $0xf01042d2
f0101314:	68 80 02 00 00       	push   $0x280
f0101319:	68 ac 42 10 f0       	push   $0xf01042ac
f010131e:	e8 68 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101323:	83 ec 0c             	sub    $0xc,%esp
f0101326:	6a 00                	push   $0x0
f0101328:	e8 dd f9 ff ff       	call   f0100d0a <page_alloc>
f010132d:	89 c7                	mov    %eax,%edi
f010132f:	83 c4 10             	add    $0x10,%esp
f0101332:	85 c0                	test   %eax,%eax
f0101334:	75 19                	jne    f010134f <mem_init+0x374>
f0101336:	68 aa 43 10 f0       	push   $0xf01043aa
f010133b:	68 d2 42 10 f0       	push   $0xf01042d2
f0101340:	68 81 02 00 00       	push   $0x281
f0101345:	68 ac 42 10 f0       	push   $0xf01042ac
f010134a:	e8 3c ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010134f:	83 ec 0c             	sub    $0xc,%esp
f0101352:	6a 00                	push   $0x0
f0101354:	e8 b1 f9 ff ff       	call   f0100d0a <page_alloc>
f0101359:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010135c:	83 c4 10             	add    $0x10,%esp
f010135f:	85 c0                	test   %eax,%eax
f0101361:	75 19                	jne    f010137c <mem_init+0x3a1>
f0101363:	68 c0 43 10 f0       	push   $0xf01043c0
f0101368:	68 d2 42 10 f0       	push   $0xf01042d2
f010136d:	68 82 02 00 00       	push   $0x282
f0101372:	68 ac 42 10 f0       	push   $0xf01042ac
f0101377:	e8 0f ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010137c:	39 fe                	cmp    %edi,%esi
f010137e:	75 19                	jne    f0101399 <mem_init+0x3be>
f0101380:	68 d6 43 10 f0       	push   $0xf01043d6
f0101385:	68 d2 42 10 f0       	push   $0xf01042d2
f010138a:	68 84 02 00 00       	push   $0x284
f010138f:	68 ac 42 10 f0       	push   $0xf01042ac
f0101394:	e8 f2 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101399:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010139c:	39 c7                	cmp    %eax,%edi
f010139e:	74 04                	je     f01013a4 <mem_init+0x3c9>
f01013a0:	39 c6                	cmp    %eax,%esi
f01013a2:	75 19                	jne    f01013bd <mem_init+0x3e2>
f01013a4:	68 c0 3c 10 f0       	push   $0xf0103cc0
f01013a9:	68 d2 42 10 f0       	push   $0xf01042d2
f01013ae:	68 85 02 00 00       	push   $0x285
f01013b3:	68 ac 42 10 f0       	push   $0xf01042ac
f01013b8:	e8 ce ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013bd:	83 ec 0c             	sub    $0xc,%esp
f01013c0:	6a 00                	push   $0x0
f01013c2:	e8 43 f9 ff ff       	call   f0100d0a <page_alloc>
f01013c7:	83 c4 10             	add    $0x10,%esp
f01013ca:	85 c0                	test   %eax,%eax
f01013cc:	74 19                	je     f01013e7 <mem_init+0x40c>
f01013ce:	68 3f 44 10 f0       	push   $0xf010443f
f01013d3:	68 d2 42 10 f0       	push   $0xf01042d2
f01013d8:	68 86 02 00 00       	push   $0x286
f01013dd:	68 ac 42 10 f0       	push   $0xf01042ac
f01013e2:	e8 a4 ec ff ff       	call   f010008b <_panic>
f01013e7:	89 f0                	mov    %esi,%eax
f01013e9:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01013ef:	c1 f8 03             	sar    $0x3,%eax
f01013f2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013f5:	89 c2                	mov    %eax,%edx
f01013f7:	c1 ea 0c             	shr    $0xc,%edx
f01013fa:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101400:	72 12                	jb     f0101414 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101402:	50                   	push   %eax
f0101403:	68 58 3b 10 f0       	push   $0xf0103b58
f0101408:	6a 52                	push   $0x52
f010140a:	68 b8 42 10 f0       	push   $0xf01042b8
f010140f:	e8 77 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101414:	83 ec 04             	sub    $0x4,%esp
f0101417:	68 00 10 00 00       	push   $0x1000
f010141c:	6a 01                	push   $0x1
f010141e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101423:	50                   	push   %eax
f0101424:	e8 a3 1d 00 00       	call   f01031cc <memset>
	page_free(pp0);
f0101429:	89 34 24             	mov    %esi,(%esp)
f010142c:	e8 49 f9 ff ff       	call   f0100d7a <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101431:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101438:	e8 cd f8 ff ff       	call   f0100d0a <page_alloc>
f010143d:	83 c4 10             	add    $0x10,%esp
f0101440:	85 c0                	test   %eax,%eax
f0101442:	75 19                	jne    f010145d <mem_init+0x482>
f0101444:	68 4e 44 10 f0       	push   $0xf010444e
f0101449:	68 d2 42 10 f0       	push   $0xf01042d2
f010144e:	68 8b 02 00 00       	push   $0x28b
f0101453:	68 ac 42 10 f0       	push   $0xf01042ac
f0101458:	e8 2e ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010145d:	39 c6                	cmp    %eax,%esi
f010145f:	74 19                	je     f010147a <mem_init+0x49f>
f0101461:	68 6c 44 10 f0       	push   $0xf010446c
f0101466:	68 d2 42 10 f0       	push   $0xf01042d2
f010146b:	68 8c 02 00 00       	push   $0x28c
f0101470:	68 ac 42 10 f0       	push   $0xf01042ac
f0101475:	e8 11 ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010147a:	89 f0                	mov    %esi,%eax
f010147c:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101482:	c1 f8 03             	sar    $0x3,%eax
f0101485:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101488:	89 c2                	mov    %eax,%edx
f010148a:	c1 ea 0c             	shr    $0xc,%edx
f010148d:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101493:	72 12                	jb     f01014a7 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101495:	50                   	push   %eax
f0101496:	68 58 3b 10 f0       	push   $0xf0103b58
f010149b:	6a 52                	push   $0x52
f010149d:	68 b8 42 10 f0       	push   $0xf01042b8
f01014a2:	e8 e4 eb ff ff       	call   f010008b <_panic>
f01014a7:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014ad:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014b3:	80 38 00             	cmpb   $0x0,(%eax)
f01014b6:	74 19                	je     f01014d1 <mem_init+0x4f6>
f01014b8:	68 7c 44 10 f0       	push   $0xf010447c
f01014bd:	68 d2 42 10 f0       	push   $0xf01042d2
f01014c2:	68 8f 02 00 00       	push   $0x28f
f01014c7:	68 ac 42 10 f0       	push   $0xf01042ac
f01014cc:	e8 ba eb ff ff       	call   f010008b <_panic>
f01014d1:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014d4:	39 d0                	cmp    %edx,%eax
f01014d6:	75 db                	jne    f01014b3 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014d8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014db:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f01014e0:	83 ec 0c             	sub    $0xc,%esp
f01014e3:	56                   	push   %esi
f01014e4:	e8 91 f8 ff ff       	call   f0100d7a <page_free>
	page_free(pp1);
f01014e9:	89 3c 24             	mov    %edi,(%esp)
f01014ec:	e8 89 f8 ff ff       	call   f0100d7a <page_free>
	page_free(pp2);
f01014f1:	83 c4 04             	add    $0x4,%esp
f01014f4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014f7:	e8 7e f8 ff ff       	call   f0100d7a <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014fc:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101501:	83 c4 10             	add    $0x10,%esp
f0101504:	eb 05                	jmp    f010150b <mem_init+0x530>
		--nfree;
f0101506:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101509:	8b 00                	mov    (%eax),%eax
f010150b:	85 c0                	test   %eax,%eax
f010150d:	75 f7                	jne    f0101506 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f010150f:	85 db                	test   %ebx,%ebx
f0101511:	74 19                	je     f010152c <mem_init+0x551>
f0101513:	68 86 44 10 f0       	push   $0xf0104486
f0101518:	68 d2 42 10 f0       	push   $0xf01042d2
f010151d:	68 9c 02 00 00       	push   $0x29c
f0101522:	68 ac 42 10 f0       	push   $0xf01042ac
f0101527:	e8 5f eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010152c:	83 ec 0c             	sub    $0xc,%esp
f010152f:	68 e0 3c 10 f0       	push   $0xf0103ce0
f0101534:	e8 9b 11 00 00       	call   f01026d4 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101539:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101540:	e8 c5 f7 ff ff       	call   f0100d0a <page_alloc>
f0101545:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101548:	83 c4 10             	add    $0x10,%esp
f010154b:	85 c0                	test   %eax,%eax
f010154d:	75 19                	jne    f0101568 <mem_init+0x58d>
f010154f:	68 94 43 10 f0       	push   $0xf0104394
f0101554:	68 d2 42 10 f0       	push   $0xf01042d2
f0101559:	68 f5 02 00 00       	push   $0x2f5
f010155e:	68 ac 42 10 f0       	push   $0xf01042ac
f0101563:	e8 23 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101568:	83 ec 0c             	sub    $0xc,%esp
f010156b:	6a 00                	push   $0x0
f010156d:	e8 98 f7 ff ff       	call   f0100d0a <page_alloc>
f0101572:	89 c3                	mov    %eax,%ebx
f0101574:	83 c4 10             	add    $0x10,%esp
f0101577:	85 c0                	test   %eax,%eax
f0101579:	75 19                	jne    f0101594 <mem_init+0x5b9>
f010157b:	68 aa 43 10 f0       	push   $0xf01043aa
f0101580:	68 d2 42 10 f0       	push   $0xf01042d2
f0101585:	68 f6 02 00 00       	push   $0x2f6
f010158a:	68 ac 42 10 f0       	push   $0xf01042ac
f010158f:	e8 f7 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101594:	83 ec 0c             	sub    $0xc,%esp
f0101597:	6a 00                	push   $0x0
f0101599:	e8 6c f7 ff ff       	call   f0100d0a <page_alloc>
f010159e:	89 c6                	mov    %eax,%esi
f01015a0:	83 c4 10             	add    $0x10,%esp
f01015a3:	85 c0                	test   %eax,%eax
f01015a5:	75 19                	jne    f01015c0 <mem_init+0x5e5>
f01015a7:	68 c0 43 10 f0       	push   $0xf01043c0
f01015ac:	68 d2 42 10 f0       	push   $0xf01042d2
f01015b1:	68 f7 02 00 00       	push   $0x2f7
f01015b6:	68 ac 42 10 f0       	push   $0xf01042ac
f01015bb:	e8 cb ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015c0:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015c3:	75 19                	jne    f01015de <mem_init+0x603>
f01015c5:	68 d6 43 10 f0       	push   $0xf01043d6
f01015ca:	68 d2 42 10 f0       	push   $0xf01042d2
f01015cf:	68 fa 02 00 00       	push   $0x2fa
f01015d4:	68 ac 42 10 f0       	push   $0xf01042ac
f01015d9:	e8 ad ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015de:	39 c3                	cmp    %eax,%ebx
f01015e0:	74 05                	je     f01015e7 <mem_init+0x60c>
f01015e2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015e5:	75 19                	jne    f0101600 <mem_init+0x625>
f01015e7:	68 c0 3c 10 f0       	push   $0xf0103cc0
f01015ec:	68 d2 42 10 f0       	push   $0xf01042d2
f01015f1:	68 fb 02 00 00       	push   $0x2fb
f01015f6:	68 ac 42 10 f0       	push   $0xf01042ac
f01015fb:	e8 8b ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101600:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101605:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101608:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010160f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101612:	83 ec 0c             	sub    $0xc,%esp
f0101615:	6a 00                	push   $0x0
f0101617:	e8 ee f6 ff ff       	call   f0100d0a <page_alloc>
f010161c:	83 c4 10             	add    $0x10,%esp
f010161f:	85 c0                	test   %eax,%eax
f0101621:	74 19                	je     f010163c <mem_init+0x661>
f0101623:	68 3f 44 10 f0       	push   $0xf010443f
f0101628:	68 d2 42 10 f0       	push   $0xf01042d2
f010162d:	68 02 03 00 00       	push   $0x302
f0101632:	68 ac 42 10 f0       	push   $0xf01042ac
f0101637:	e8 4f ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010163c:	83 ec 04             	sub    $0x4,%esp
f010163f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101642:	50                   	push   %eax
f0101643:	6a 00                	push   $0x0
f0101645:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010164b:	e8 71 f8 ff ff       	call   f0100ec1 <page_lookup>
f0101650:	83 c4 10             	add    $0x10,%esp
f0101653:	85 c0                	test   %eax,%eax
f0101655:	74 19                	je     f0101670 <mem_init+0x695>
f0101657:	68 00 3d 10 f0       	push   $0xf0103d00
f010165c:	68 d2 42 10 f0       	push   $0xf01042d2
f0101661:	68 05 03 00 00       	push   $0x305
f0101666:	68 ac 42 10 f0       	push   $0xf01042ac
f010166b:	e8 1b ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101670:	6a 02                	push   $0x2
f0101672:	6a 00                	push   $0x0
f0101674:	53                   	push   %ebx
f0101675:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010167b:	e8 e3 f8 ff ff       	call   f0100f63 <page_insert>
f0101680:	83 c4 10             	add    $0x10,%esp
f0101683:	85 c0                	test   %eax,%eax
f0101685:	78 19                	js     f01016a0 <mem_init+0x6c5>
f0101687:	68 38 3d 10 f0       	push   $0xf0103d38
f010168c:	68 d2 42 10 f0       	push   $0xf01042d2
f0101691:	68 08 03 00 00       	push   $0x308
f0101696:	68 ac 42 10 f0       	push   $0xf01042ac
f010169b:	e8 eb e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016a0:	83 ec 0c             	sub    $0xc,%esp
f01016a3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016a6:	e8 cf f6 ff ff       	call   f0100d7a <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016ab:	6a 02                	push   $0x2
f01016ad:	6a 00                	push   $0x0
f01016af:	53                   	push   %ebx
f01016b0:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016b6:	e8 a8 f8 ff ff       	call   f0100f63 <page_insert>
f01016bb:	83 c4 20             	add    $0x20,%esp
f01016be:	85 c0                	test   %eax,%eax
f01016c0:	74 19                	je     f01016db <mem_init+0x700>
f01016c2:	68 68 3d 10 f0       	push   $0xf0103d68
f01016c7:	68 d2 42 10 f0       	push   $0xf01042d2
f01016cc:	68 0c 03 00 00       	push   $0x30c
f01016d1:	68 ac 42 10 f0       	push   $0xf01042ac
f01016d6:	e8 b0 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016db:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016e1:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f01016e6:	89 c1                	mov    %eax,%ecx
f01016e8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016eb:	8b 17                	mov    (%edi),%edx
f01016ed:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016f6:	29 c8                	sub    %ecx,%eax
f01016f8:	c1 f8 03             	sar    $0x3,%eax
f01016fb:	c1 e0 0c             	shl    $0xc,%eax
f01016fe:	39 c2                	cmp    %eax,%edx
f0101700:	74 19                	je     f010171b <mem_init+0x740>
f0101702:	68 98 3d 10 f0       	push   $0xf0103d98
f0101707:	68 d2 42 10 f0       	push   $0xf01042d2
f010170c:	68 0d 03 00 00       	push   $0x30d
f0101711:	68 ac 42 10 f0       	push   $0xf01042ac
f0101716:	e8 70 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010171b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101720:	89 f8                	mov    %edi,%eax
f0101722:	e8 e2 f1 ff ff       	call   f0100909 <check_va2pa>
f0101727:	89 da                	mov    %ebx,%edx
f0101729:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010172c:	c1 fa 03             	sar    $0x3,%edx
f010172f:	c1 e2 0c             	shl    $0xc,%edx
f0101732:	39 d0                	cmp    %edx,%eax
f0101734:	74 19                	je     f010174f <mem_init+0x774>
f0101736:	68 c0 3d 10 f0       	push   $0xf0103dc0
f010173b:	68 d2 42 10 f0       	push   $0xf01042d2
f0101740:	68 0e 03 00 00       	push   $0x30e
f0101745:	68 ac 42 10 f0       	push   $0xf01042ac
f010174a:	e8 3c e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010174f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101754:	74 19                	je     f010176f <mem_init+0x794>
f0101756:	68 91 44 10 f0       	push   $0xf0104491
f010175b:	68 d2 42 10 f0       	push   $0xf01042d2
f0101760:	68 0f 03 00 00       	push   $0x30f
f0101765:	68 ac 42 10 f0       	push   $0xf01042ac
f010176a:	e8 1c e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010176f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101772:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101777:	74 19                	je     f0101792 <mem_init+0x7b7>
f0101779:	68 a2 44 10 f0       	push   $0xf01044a2
f010177e:	68 d2 42 10 f0       	push   $0xf01042d2
f0101783:	68 10 03 00 00       	push   $0x310
f0101788:	68 ac 42 10 f0       	push   $0xf01042ac
f010178d:	e8 f9 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101792:	6a 02                	push   $0x2
f0101794:	68 00 10 00 00       	push   $0x1000
f0101799:	56                   	push   %esi
f010179a:	57                   	push   %edi
f010179b:	e8 c3 f7 ff ff       	call   f0100f63 <page_insert>
f01017a0:	83 c4 10             	add    $0x10,%esp
f01017a3:	85 c0                	test   %eax,%eax
f01017a5:	74 19                	je     f01017c0 <mem_init+0x7e5>
f01017a7:	68 f0 3d 10 f0       	push   $0xf0103df0
f01017ac:	68 d2 42 10 f0       	push   $0xf01042d2
f01017b1:	68 13 03 00 00       	push   $0x313
f01017b6:	68 ac 42 10 f0       	push   $0xf01042ac
f01017bb:	e8 cb e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017c0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017c5:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01017ca:	e8 3a f1 ff ff       	call   f0100909 <check_va2pa>
f01017cf:	89 f2                	mov    %esi,%edx
f01017d1:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01017d7:	c1 fa 03             	sar    $0x3,%edx
f01017da:	c1 e2 0c             	shl    $0xc,%edx
f01017dd:	39 d0                	cmp    %edx,%eax
f01017df:	74 19                	je     f01017fa <mem_init+0x81f>
f01017e1:	68 2c 3e 10 f0       	push   $0xf0103e2c
f01017e6:	68 d2 42 10 f0       	push   $0xf01042d2
f01017eb:	68 14 03 00 00       	push   $0x314
f01017f0:	68 ac 42 10 f0       	push   $0xf01042ac
f01017f5:	e8 91 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017fa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017ff:	74 19                	je     f010181a <mem_init+0x83f>
f0101801:	68 b3 44 10 f0       	push   $0xf01044b3
f0101806:	68 d2 42 10 f0       	push   $0xf01042d2
f010180b:	68 15 03 00 00       	push   $0x315
f0101810:	68 ac 42 10 f0       	push   $0xf01042ac
f0101815:	e8 71 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010181a:	83 ec 0c             	sub    $0xc,%esp
f010181d:	6a 00                	push   $0x0
f010181f:	e8 e6 f4 ff ff       	call   f0100d0a <page_alloc>
f0101824:	83 c4 10             	add    $0x10,%esp
f0101827:	85 c0                	test   %eax,%eax
f0101829:	74 19                	je     f0101844 <mem_init+0x869>
f010182b:	68 3f 44 10 f0       	push   $0xf010443f
f0101830:	68 d2 42 10 f0       	push   $0xf01042d2
f0101835:	68 18 03 00 00       	push   $0x318
f010183a:	68 ac 42 10 f0       	push   $0xf01042ac
f010183f:	e8 47 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101844:	6a 02                	push   $0x2
f0101846:	68 00 10 00 00       	push   $0x1000
f010184b:	56                   	push   %esi
f010184c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101852:	e8 0c f7 ff ff       	call   f0100f63 <page_insert>
f0101857:	83 c4 10             	add    $0x10,%esp
f010185a:	85 c0                	test   %eax,%eax
f010185c:	74 19                	je     f0101877 <mem_init+0x89c>
f010185e:	68 f0 3d 10 f0       	push   $0xf0103df0
f0101863:	68 d2 42 10 f0       	push   $0xf01042d2
f0101868:	68 1b 03 00 00       	push   $0x31b
f010186d:	68 ac 42 10 f0       	push   $0xf01042ac
f0101872:	e8 14 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101877:	ba 00 10 00 00       	mov    $0x1000,%edx
f010187c:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101881:	e8 83 f0 ff ff       	call   f0100909 <check_va2pa>
f0101886:	89 f2                	mov    %esi,%edx
f0101888:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010188e:	c1 fa 03             	sar    $0x3,%edx
f0101891:	c1 e2 0c             	shl    $0xc,%edx
f0101894:	39 d0                	cmp    %edx,%eax
f0101896:	74 19                	je     f01018b1 <mem_init+0x8d6>
f0101898:	68 2c 3e 10 f0       	push   $0xf0103e2c
f010189d:	68 d2 42 10 f0       	push   $0xf01042d2
f01018a2:	68 1c 03 00 00       	push   $0x31c
f01018a7:	68 ac 42 10 f0       	push   $0xf01042ac
f01018ac:	e8 da e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018b1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018b6:	74 19                	je     f01018d1 <mem_init+0x8f6>
f01018b8:	68 b3 44 10 f0       	push   $0xf01044b3
f01018bd:	68 d2 42 10 f0       	push   $0xf01042d2
f01018c2:	68 1d 03 00 00       	push   $0x31d
f01018c7:	68 ac 42 10 f0       	push   $0xf01042ac
f01018cc:	e8 ba e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018d1:	83 ec 0c             	sub    $0xc,%esp
f01018d4:	6a 00                	push   $0x0
f01018d6:	e8 2f f4 ff ff       	call   f0100d0a <page_alloc>
f01018db:	83 c4 10             	add    $0x10,%esp
f01018de:	85 c0                	test   %eax,%eax
f01018e0:	74 19                	je     f01018fb <mem_init+0x920>
f01018e2:	68 3f 44 10 f0       	push   $0xf010443f
f01018e7:	68 d2 42 10 f0       	push   $0xf01042d2
f01018ec:	68 21 03 00 00       	push   $0x321
f01018f1:	68 ac 42 10 f0       	push   $0xf01042ac
f01018f6:	e8 90 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01018fb:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f0101901:	8b 02                	mov    (%edx),%eax
f0101903:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101908:	89 c1                	mov    %eax,%ecx
f010190a:	c1 e9 0c             	shr    $0xc,%ecx
f010190d:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0101913:	72 15                	jb     f010192a <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101915:	50                   	push   %eax
f0101916:	68 58 3b 10 f0       	push   $0xf0103b58
f010191b:	68 24 03 00 00       	push   $0x324
f0101920:	68 ac 42 10 f0       	push   $0xf01042ac
f0101925:	e8 61 e7 ff ff       	call   f010008b <_panic>
f010192a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010192f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101932:	83 ec 04             	sub    $0x4,%esp
f0101935:	6a 00                	push   $0x0
f0101937:	68 00 10 00 00       	push   $0x1000
f010193c:	52                   	push   %edx
f010193d:	e8 9a f4 ff ff       	call   f0100ddc <pgdir_walk>
f0101942:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101945:	8d 51 04             	lea    0x4(%ecx),%edx
f0101948:	83 c4 10             	add    $0x10,%esp
f010194b:	39 d0                	cmp    %edx,%eax
f010194d:	74 19                	je     f0101968 <mem_init+0x98d>
f010194f:	68 5c 3e 10 f0       	push   $0xf0103e5c
f0101954:	68 d2 42 10 f0       	push   $0xf01042d2
f0101959:	68 25 03 00 00       	push   $0x325
f010195e:	68 ac 42 10 f0       	push   $0xf01042ac
f0101963:	e8 23 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101968:	6a 06                	push   $0x6
f010196a:	68 00 10 00 00       	push   $0x1000
f010196f:	56                   	push   %esi
f0101970:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101976:	e8 e8 f5 ff ff       	call   f0100f63 <page_insert>
f010197b:	83 c4 10             	add    $0x10,%esp
f010197e:	85 c0                	test   %eax,%eax
f0101980:	74 19                	je     f010199b <mem_init+0x9c0>
f0101982:	68 9c 3e 10 f0       	push   $0xf0103e9c
f0101987:	68 d2 42 10 f0       	push   $0xf01042d2
f010198c:	68 28 03 00 00       	push   $0x328
f0101991:	68 ac 42 10 f0       	push   $0xf01042ac
f0101996:	e8 f0 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010199b:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019a1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019a6:	89 f8                	mov    %edi,%eax
f01019a8:	e8 5c ef ff ff       	call   f0100909 <check_va2pa>
f01019ad:	89 f2                	mov    %esi,%edx
f01019af:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019b5:	c1 fa 03             	sar    $0x3,%edx
f01019b8:	c1 e2 0c             	shl    $0xc,%edx
f01019bb:	39 d0                	cmp    %edx,%eax
f01019bd:	74 19                	je     f01019d8 <mem_init+0x9fd>
f01019bf:	68 2c 3e 10 f0       	push   $0xf0103e2c
f01019c4:	68 d2 42 10 f0       	push   $0xf01042d2
f01019c9:	68 29 03 00 00       	push   $0x329
f01019ce:	68 ac 42 10 f0       	push   $0xf01042ac
f01019d3:	e8 b3 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019d8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019dd:	74 19                	je     f01019f8 <mem_init+0xa1d>
f01019df:	68 b3 44 10 f0       	push   $0xf01044b3
f01019e4:	68 d2 42 10 f0       	push   $0xf01042d2
f01019e9:	68 2a 03 00 00       	push   $0x32a
f01019ee:	68 ac 42 10 f0       	push   $0xf01042ac
f01019f3:	e8 93 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01019f8:	83 ec 04             	sub    $0x4,%esp
f01019fb:	6a 00                	push   $0x0
f01019fd:	68 00 10 00 00       	push   $0x1000
f0101a02:	57                   	push   %edi
f0101a03:	e8 d4 f3 ff ff       	call   f0100ddc <pgdir_walk>
f0101a08:	83 c4 10             	add    $0x10,%esp
f0101a0b:	f6 00 04             	testb  $0x4,(%eax)
f0101a0e:	75 19                	jne    f0101a29 <mem_init+0xa4e>
f0101a10:	68 dc 3e 10 f0       	push   $0xf0103edc
f0101a15:	68 d2 42 10 f0       	push   $0xf01042d2
f0101a1a:	68 2b 03 00 00       	push   $0x32b
f0101a1f:	68 ac 42 10 f0       	push   $0xf01042ac
f0101a24:	e8 62 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a29:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a2e:	f6 00 04             	testb  $0x4,(%eax)
f0101a31:	75 19                	jne    f0101a4c <mem_init+0xa71>
f0101a33:	68 c4 44 10 f0       	push   $0xf01044c4
f0101a38:	68 d2 42 10 f0       	push   $0xf01042d2
f0101a3d:	68 2c 03 00 00       	push   $0x32c
f0101a42:	68 ac 42 10 f0       	push   $0xf01042ac
f0101a47:	e8 3f e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a4c:	6a 02                	push   $0x2
f0101a4e:	68 00 10 00 00       	push   $0x1000
f0101a53:	56                   	push   %esi
f0101a54:	50                   	push   %eax
f0101a55:	e8 09 f5 ff ff       	call   f0100f63 <page_insert>
f0101a5a:	83 c4 10             	add    $0x10,%esp
f0101a5d:	85 c0                	test   %eax,%eax
f0101a5f:	74 19                	je     f0101a7a <mem_init+0xa9f>
f0101a61:	68 f0 3d 10 f0       	push   $0xf0103df0
f0101a66:	68 d2 42 10 f0       	push   $0xf01042d2
f0101a6b:	68 2f 03 00 00       	push   $0x32f
f0101a70:	68 ac 42 10 f0       	push   $0xf01042ac
f0101a75:	e8 11 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a7a:	83 ec 04             	sub    $0x4,%esp
f0101a7d:	6a 00                	push   $0x0
f0101a7f:	68 00 10 00 00       	push   $0x1000
f0101a84:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a8a:	e8 4d f3 ff ff       	call   f0100ddc <pgdir_walk>
f0101a8f:	83 c4 10             	add    $0x10,%esp
f0101a92:	f6 00 02             	testb  $0x2,(%eax)
f0101a95:	75 19                	jne    f0101ab0 <mem_init+0xad5>
f0101a97:	68 10 3f 10 f0       	push   $0xf0103f10
f0101a9c:	68 d2 42 10 f0       	push   $0xf01042d2
f0101aa1:	68 30 03 00 00       	push   $0x330
f0101aa6:	68 ac 42 10 f0       	push   $0xf01042ac
f0101aab:	e8 db e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ab0:	83 ec 04             	sub    $0x4,%esp
f0101ab3:	6a 00                	push   $0x0
f0101ab5:	68 00 10 00 00       	push   $0x1000
f0101aba:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ac0:	e8 17 f3 ff ff       	call   f0100ddc <pgdir_walk>
f0101ac5:	83 c4 10             	add    $0x10,%esp
f0101ac8:	f6 00 04             	testb  $0x4,(%eax)
f0101acb:	74 19                	je     f0101ae6 <mem_init+0xb0b>
f0101acd:	68 44 3f 10 f0       	push   $0xf0103f44
f0101ad2:	68 d2 42 10 f0       	push   $0xf01042d2
f0101ad7:	68 31 03 00 00       	push   $0x331
f0101adc:	68 ac 42 10 f0       	push   $0xf01042ac
f0101ae1:	e8 a5 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ae6:	6a 02                	push   $0x2
f0101ae8:	68 00 00 40 00       	push   $0x400000
f0101aed:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101af0:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101af6:	e8 68 f4 ff ff       	call   f0100f63 <page_insert>
f0101afb:	83 c4 10             	add    $0x10,%esp
f0101afe:	85 c0                	test   %eax,%eax
f0101b00:	78 19                	js     f0101b1b <mem_init+0xb40>
f0101b02:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101b07:	68 d2 42 10 f0       	push   $0xf01042d2
f0101b0c:	68 34 03 00 00       	push   $0x334
f0101b11:	68 ac 42 10 f0       	push   $0xf01042ac
f0101b16:	e8 70 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b1b:	6a 02                	push   $0x2
f0101b1d:	68 00 10 00 00       	push   $0x1000
f0101b22:	53                   	push   %ebx
f0101b23:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b29:	e8 35 f4 ff ff       	call   f0100f63 <page_insert>
f0101b2e:	83 c4 10             	add    $0x10,%esp
f0101b31:	85 c0                	test   %eax,%eax
f0101b33:	74 19                	je     f0101b4e <mem_init+0xb73>
f0101b35:	68 b4 3f 10 f0       	push   $0xf0103fb4
f0101b3a:	68 d2 42 10 f0       	push   $0xf01042d2
f0101b3f:	68 37 03 00 00       	push   $0x337
f0101b44:	68 ac 42 10 f0       	push   $0xf01042ac
f0101b49:	e8 3d e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b4e:	83 ec 04             	sub    $0x4,%esp
f0101b51:	6a 00                	push   $0x0
f0101b53:	68 00 10 00 00       	push   $0x1000
f0101b58:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b5e:	e8 79 f2 ff ff       	call   f0100ddc <pgdir_walk>
f0101b63:	83 c4 10             	add    $0x10,%esp
f0101b66:	f6 00 04             	testb  $0x4,(%eax)
f0101b69:	74 19                	je     f0101b84 <mem_init+0xba9>
f0101b6b:	68 44 3f 10 f0       	push   $0xf0103f44
f0101b70:	68 d2 42 10 f0       	push   $0xf01042d2
f0101b75:	68 38 03 00 00       	push   $0x338
f0101b7a:	68 ac 42 10 f0       	push   $0xf01042ac
f0101b7f:	e8 07 e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b84:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101b8a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b8f:	89 f8                	mov    %edi,%eax
f0101b91:	e8 73 ed ff ff       	call   f0100909 <check_va2pa>
f0101b96:	89 c1                	mov    %eax,%ecx
f0101b98:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b9b:	89 d8                	mov    %ebx,%eax
f0101b9d:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101ba3:	c1 f8 03             	sar    $0x3,%eax
f0101ba6:	c1 e0 0c             	shl    $0xc,%eax
f0101ba9:	39 c1                	cmp    %eax,%ecx
f0101bab:	74 19                	je     f0101bc6 <mem_init+0xbeb>
f0101bad:	68 f0 3f 10 f0       	push   $0xf0103ff0
f0101bb2:	68 d2 42 10 f0       	push   $0xf01042d2
f0101bb7:	68 3b 03 00 00       	push   $0x33b
f0101bbc:	68 ac 42 10 f0       	push   $0xf01042ac
f0101bc1:	e8 c5 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bc6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bcb:	89 f8                	mov    %edi,%eax
f0101bcd:	e8 37 ed ff ff       	call   f0100909 <check_va2pa>
f0101bd2:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bd5:	74 19                	je     f0101bf0 <mem_init+0xc15>
f0101bd7:	68 1c 40 10 f0       	push   $0xf010401c
f0101bdc:	68 d2 42 10 f0       	push   $0xf01042d2
f0101be1:	68 3c 03 00 00       	push   $0x33c
f0101be6:	68 ac 42 10 f0       	push   $0xf01042ac
f0101beb:	e8 9b e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101bf0:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101bf5:	74 19                	je     f0101c10 <mem_init+0xc35>
f0101bf7:	68 da 44 10 f0       	push   $0xf01044da
f0101bfc:	68 d2 42 10 f0       	push   $0xf01042d2
f0101c01:	68 3e 03 00 00       	push   $0x33e
f0101c06:	68 ac 42 10 f0       	push   $0xf01042ac
f0101c0b:	e8 7b e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c10:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c15:	74 19                	je     f0101c30 <mem_init+0xc55>
f0101c17:	68 eb 44 10 f0       	push   $0xf01044eb
f0101c1c:	68 d2 42 10 f0       	push   $0xf01042d2
f0101c21:	68 3f 03 00 00       	push   $0x33f
f0101c26:	68 ac 42 10 f0       	push   $0xf01042ac
f0101c2b:	e8 5b e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c30:	83 ec 0c             	sub    $0xc,%esp
f0101c33:	6a 00                	push   $0x0
f0101c35:	e8 d0 f0 ff ff       	call   f0100d0a <page_alloc>
f0101c3a:	83 c4 10             	add    $0x10,%esp
f0101c3d:	85 c0                	test   %eax,%eax
f0101c3f:	74 04                	je     f0101c45 <mem_init+0xc6a>
f0101c41:	39 c6                	cmp    %eax,%esi
f0101c43:	74 19                	je     f0101c5e <mem_init+0xc83>
f0101c45:	68 4c 40 10 f0       	push   $0xf010404c
f0101c4a:	68 d2 42 10 f0       	push   $0xf01042d2
f0101c4f:	68 42 03 00 00       	push   $0x342
f0101c54:	68 ac 42 10 f0       	push   $0xf01042ac
f0101c59:	e8 2d e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c5e:	83 ec 08             	sub    $0x8,%esp
f0101c61:	6a 00                	push   $0x0
f0101c63:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c69:	e8 ba f2 ff ff       	call   f0100f28 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c6e:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c74:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c79:	89 f8                	mov    %edi,%eax
f0101c7b:	e8 89 ec ff ff       	call   f0100909 <check_va2pa>
f0101c80:	83 c4 10             	add    $0x10,%esp
f0101c83:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c86:	74 19                	je     f0101ca1 <mem_init+0xcc6>
f0101c88:	68 70 40 10 f0       	push   $0xf0104070
f0101c8d:	68 d2 42 10 f0       	push   $0xf01042d2
f0101c92:	68 46 03 00 00       	push   $0x346
f0101c97:	68 ac 42 10 f0       	push   $0xf01042ac
f0101c9c:	e8 ea e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ca1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca6:	89 f8                	mov    %edi,%eax
f0101ca8:	e8 5c ec ff ff       	call   f0100909 <check_va2pa>
f0101cad:	89 da                	mov    %ebx,%edx
f0101caf:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cb5:	c1 fa 03             	sar    $0x3,%edx
f0101cb8:	c1 e2 0c             	shl    $0xc,%edx
f0101cbb:	39 d0                	cmp    %edx,%eax
f0101cbd:	74 19                	je     f0101cd8 <mem_init+0xcfd>
f0101cbf:	68 1c 40 10 f0       	push   $0xf010401c
f0101cc4:	68 d2 42 10 f0       	push   $0xf01042d2
f0101cc9:	68 47 03 00 00       	push   $0x347
f0101cce:	68 ac 42 10 f0       	push   $0xf01042ac
f0101cd3:	e8 b3 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101cd8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cdd:	74 19                	je     f0101cf8 <mem_init+0xd1d>
f0101cdf:	68 91 44 10 f0       	push   $0xf0104491
f0101ce4:	68 d2 42 10 f0       	push   $0xf01042d2
f0101ce9:	68 48 03 00 00       	push   $0x348
f0101cee:	68 ac 42 10 f0       	push   $0xf01042ac
f0101cf3:	e8 93 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101cf8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101cfd:	74 19                	je     f0101d18 <mem_init+0xd3d>
f0101cff:	68 eb 44 10 f0       	push   $0xf01044eb
f0101d04:	68 d2 42 10 f0       	push   $0xf01042d2
f0101d09:	68 49 03 00 00       	push   $0x349
f0101d0e:	68 ac 42 10 f0       	push   $0xf01042ac
f0101d13:	e8 73 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d18:	6a 00                	push   $0x0
f0101d1a:	68 00 10 00 00       	push   $0x1000
f0101d1f:	53                   	push   %ebx
f0101d20:	57                   	push   %edi
f0101d21:	e8 3d f2 ff ff       	call   f0100f63 <page_insert>
f0101d26:	83 c4 10             	add    $0x10,%esp
f0101d29:	85 c0                	test   %eax,%eax
f0101d2b:	74 19                	je     f0101d46 <mem_init+0xd6b>
f0101d2d:	68 94 40 10 f0       	push   $0xf0104094
f0101d32:	68 d2 42 10 f0       	push   $0xf01042d2
f0101d37:	68 4c 03 00 00       	push   $0x34c
f0101d3c:	68 ac 42 10 f0       	push   $0xf01042ac
f0101d41:	e8 45 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d46:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d4b:	75 19                	jne    f0101d66 <mem_init+0xd8b>
f0101d4d:	68 fc 44 10 f0       	push   $0xf01044fc
f0101d52:	68 d2 42 10 f0       	push   $0xf01042d2
f0101d57:	68 4d 03 00 00       	push   $0x34d
f0101d5c:	68 ac 42 10 f0       	push   $0xf01042ac
f0101d61:	e8 25 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d66:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d69:	74 19                	je     f0101d84 <mem_init+0xda9>
f0101d6b:	68 08 45 10 f0       	push   $0xf0104508
f0101d70:	68 d2 42 10 f0       	push   $0xf01042d2
f0101d75:	68 4e 03 00 00       	push   $0x34e
f0101d7a:	68 ac 42 10 f0       	push   $0xf01042ac
f0101d7f:	e8 07 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d84:	83 ec 08             	sub    $0x8,%esp
f0101d87:	68 00 10 00 00       	push   $0x1000
f0101d8c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101d92:	e8 91 f1 ff ff       	call   f0100f28 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d97:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101d9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101da2:	89 f8                	mov    %edi,%eax
f0101da4:	e8 60 eb ff ff       	call   f0100909 <check_va2pa>
f0101da9:	83 c4 10             	add    $0x10,%esp
f0101dac:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101daf:	74 19                	je     f0101dca <mem_init+0xdef>
f0101db1:	68 70 40 10 f0       	push   $0xf0104070
f0101db6:	68 d2 42 10 f0       	push   $0xf01042d2
f0101dbb:	68 52 03 00 00       	push   $0x352
f0101dc0:	68 ac 42 10 f0       	push   $0xf01042ac
f0101dc5:	e8 c1 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101dca:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dcf:	89 f8                	mov    %edi,%eax
f0101dd1:	e8 33 eb ff ff       	call   f0100909 <check_va2pa>
f0101dd6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dd9:	74 19                	je     f0101df4 <mem_init+0xe19>
f0101ddb:	68 cc 40 10 f0       	push   $0xf01040cc
f0101de0:	68 d2 42 10 f0       	push   $0xf01042d2
f0101de5:	68 53 03 00 00       	push   $0x353
f0101dea:	68 ac 42 10 f0       	push   $0xf01042ac
f0101def:	e8 97 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101df4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101df9:	74 19                	je     f0101e14 <mem_init+0xe39>
f0101dfb:	68 1d 45 10 f0       	push   $0xf010451d
f0101e00:	68 d2 42 10 f0       	push   $0xf01042d2
f0101e05:	68 54 03 00 00       	push   $0x354
f0101e0a:	68 ac 42 10 f0       	push   $0xf01042ac
f0101e0f:	e8 77 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e14:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e19:	74 19                	je     f0101e34 <mem_init+0xe59>
f0101e1b:	68 eb 44 10 f0       	push   $0xf01044eb
f0101e20:	68 d2 42 10 f0       	push   $0xf01042d2
f0101e25:	68 55 03 00 00       	push   $0x355
f0101e2a:	68 ac 42 10 f0       	push   $0xf01042ac
f0101e2f:	e8 57 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e34:	83 ec 0c             	sub    $0xc,%esp
f0101e37:	6a 00                	push   $0x0
f0101e39:	e8 cc ee ff ff       	call   f0100d0a <page_alloc>
f0101e3e:	83 c4 10             	add    $0x10,%esp
f0101e41:	39 c3                	cmp    %eax,%ebx
f0101e43:	75 04                	jne    f0101e49 <mem_init+0xe6e>
f0101e45:	85 c0                	test   %eax,%eax
f0101e47:	75 19                	jne    f0101e62 <mem_init+0xe87>
f0101e49:	68 f4 40 10 f0       	push   $0xf01040f4
f0101e4e:	68 d2 42 10 f0       	push   $0xf01042d2
f0101e53:	68 58 03 00 00       	push   $0x358
f0101e58:	68 ac 42 10 f0       	push   $0xf01042ac
f0101e5d:	e8 29 e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e62:	83 ec 0c             	sub    $0xc,%esp
f0101e65:	6a 00                	push   $0x0
f0101e67:	e8 9e ee ff ff       	call   f0100d0a <page_alloc>
f0101e6c:	83 c4 10             	add    $0x10,%esp
f0101e6f:	85 c0                	test   %eax,%eax
f0101e71:	74 19                	je     f0101e8c <mem_init+0xeb1>
f0101e73:	68 3f 44 10 f0       	push   $0xf010443f
f0101e78:	68 d2 42 10 f0       	push   $0xf01042d2
f0101e7d:	68 5b 03 00 00       	push   $0x35b
f0101e82:	68 ac 42 10 f0       	push   $0xf01042ac
f0101e87:	e8 ff e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e8c:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101e92:	8b 11                	mov    (%ecx),%edx
f0101e94:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e9a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e9d:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101ea3:	c1 f8 03             	sar    $0x3,%eax
f0101ea6:	c1 e0 0c             	shl    $0xc,%eax
f0101ea9:	39 c2                	cmp    %eax,%edx
f0101eab:	74 19                	je     f0101ec6 <mem_init+0xeeb>
f0101ead:	68 98 3d 10 f0       	push   $0xf0103d98
f0101eb2:	68 d2 42 10 f0       	push   $0xf01042d2
f0101eb7:	68 5e 03 00 00       	push   $0x35e
f0101ebc:	68 ac 42 10 f0       	push   $0xf01042ac
f0101ec1:	e8 c5 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101ec6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101ecc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ecf:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ed4:	74 19                	je     f0101eef <mem_init+0xf14>
f0101ed6:	68 a2 44 10 f0       	push   $0xf01044a2
f0101edb:	68 d2 42 10 f0       	push   $0xf01042d2
f0101ee0:	68 60 03 00 00       	push   $0x360
f0101ee5:	68 ac 42 10 f0       	push   $0xf01042ac
f0101eea:	e8 9c e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101eef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ef8:	83 ec 0c             	sub    $0xc,%esp
f0101efb:	50                   	push   %eax
f0101efc:	e8 79 ee ff ff       	call   f0100d7a <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f01:	83 c4 0c             	add    $0xc,%esp
f0101f04:	6a 01                	push   $0x1
f0101f06:	68 00 10 40 00       	push   $0x401000
f0101f0b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f11:	e8 c6 ee ff ff       	call   f0100ddc <pgdir_walk>
f0101f16:	89 c7                	mov    %eax,%edi
f0101f18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f1b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f20:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f23:	8b 40 04             	mov    0x4(%eax),%eax
f0101f26:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f2b:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f31:	89 c2                	mov    %eax,%edx
f0101f33:	c1 ea 0c             	shr    $0xc,%edx
f0101f36:	83 c4 10             	add    $0x10,%esp
f0101f39:	39 ca                	cmp    %ecx,%edx
f0101f3b:	72 15                	jb     f0101f52 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f3d:	50                   	push   %eax
f0101f3e:	68 58 3b 10 f0       	push   $0xf0103b58
f0101f43:	68 67 03 00 00       	push   $0x367
f0101f48:	68 ac 42 10 f0       	push   $0xf01042ac
f0101f4d:	e8 39 e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f52:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f57:	39 c7                	cmp    %eax,%edi
f0101f59:	74 19                	je     f0101f74 <mem_init+0xf99>
f0101f5b:	68 2e 45 10 f0       	push   $0xf010452e
f0101f60:	68 d2 42 10 f0       	push   $0xf01042d2
f0101f65:	68 68 03 00 00       	push   $0x368
f0101f6a:	68 ac 42 10 f0       	push   $0xf01042ac
f0101f6f:	e8 17 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f74:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f77:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f7e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f81:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f87:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101f8d:	c1 f8 03             	sar    $0x3,%eax
f0101f90:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f93:	89 c2                	mov    %eax,%edx
f0101f95:	c1 ea 0c             	shr    $0xc,%edx
f0101f98:	39 d1                	cmp    %edx,%ecx
f0101f9a:	77 12                	ja     f0101fae <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f9c:	50                   	push   %eax
f0101f9d:	68 58 3b 10 f0       	push   $0xf0103b58
f0101fa2:	6a 52                	push   $0x52
f0101fa4:	68 b8 42 10 f0       	push   $0xf01042b8
f0101fa9:	e8 dd e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fae:	83 ec 04             	sub    $0x4,%esp
f0101fb1:	68 00 10 00 00       	push   $0x1000
f0101fb6:	68 ff 00 00 00       	push   $0xff
f0101fbb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fc0:	50                   	push   %eax
f0101fc1:	e8 06 12 00 00       	call   f01031cc <memset>
	page_free(pp0);
f0101fc6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fc9:	89 3c 24             	mov    %edi,(%esp)
f0101fcc:	e8 a9 ed ff ff       	call   f0100d7a <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fd1:	83 c4 0c             	add    $0xc,%esp
f0101fd4:	6a 01                	push   $0x1
f0101fd6:	6a 00                	push   $0x0
f0101fd8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101fde:	e8 f9 ed ff ff       	call   f0100ddc <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fe3:	89 fa                	mov    %edi,%edx
f0101fe5:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101feb:	c1 fa 03             	sar    $0x3,%edx
f0101fee:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ff1:	89 d0                	mov    %edx,%eax
f0101ff3:	c1 e8 0c             	shr    $0xc,%eax
f0101ff6:	83 c4 10             	add    $0x10,%esp
f0101ff9:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0101fff:	72 12                	jb     f0102013 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102001:	52                   	push   %edx
f0102002:	68 58 3b 10 f0       	push   $0xf0103b58
f0102007:	6a 52                	push   $0x52
f0102009:	68 b8 42 10 f0       	push   $0xf01042b8
f010200e:	e8 78 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102013:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102019:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010201c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102022:	f6 00 01             	testb  $0x1,(%eax)
f0102025:	74 19                	je     f0102040 <mem_init+0x1065>
f0102027:	68 46 45 10 f0       	push   $0xf0104546
f010202c:	68 d2 42 10 f0       	push   $0xf01042d2
f0102031:	68 72 03 00 00       	push   $0x372
f0102036:	68 ac 42 10 f0       	push   $0xf01042ac
f010203b:	e8 4b e0 ff ff       	call   f010008b <_panic>
f0102040:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102043:	39 d0                	cmp    %edx,%eax
f0102045:	75 db                	jne    f0102022 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102047:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010204c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102052:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102055:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010205b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010205e:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102064:	83 ec 0c             	sub    $0xc,%esp
f0102067:	50                   	push   %eax
f0102068:	e8 0d ed ff ff       	call   f0100d7a <page_free>
	page_free(pp1);
f010206d:	89 1c 24             	mov    %ebx,(%esp)
f0102070:	e8 05 ed ff ff       	call   f0100d7a <page_free>
	page_free(pp2);
f0102075:	89 34 24             	mov    %esi,(%esp)
f0102078:	e8 fd ec ff ff       	call   f0100d7a <page_free>

	cprintf("check_page() succeeded!\n");
f010207d:	c7 04 24 5d 45 10 f0 	movl   $0xf010455d,(%esp)
f0102084:	e8 4b 06 00 00       	call   f01026d4 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f0102089:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010208e:	83 c4 10             	add    $0x10,%esp
f0102091:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102096:	77 15                	ja     f01020ad <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102098:	50                   	push   %eax
f0102099:	68 9c 3c 10 f0       	push   $0xf0103c9c
f010209e:	68 b0 00 00 00       	push   $0xb0
f01020a3:	68 ac 42 10 f0       	push   $0xf01042ac
f01020a8:	e8 de df ff ff       	call   f010008b <_panic>
f01020ad:	83 ec 08             	sub    $0x8,%esp
f01020b0:	6a 04                	push   $0x4
f01020b2:	05 00 00 00 10       	add    $0x10000000,%eax
f01020b7:	50                   	push   %eax
f01020b8:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020bd:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020c2:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01020c7:	e8 a3 ed ff ff       	call   f0100e6f <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020cc:	83 c4 10             	add    $0x10,%esp
f01020cf:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f01020d4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020d9:	77 15                	ja     f01020f0 <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020db:	50                   	push   %eax
f01020dc:	68 9c 3c 10 f0       	push   $0xf0103c9c
f01020e1:	68 bc 00 00 00       	push   $0xbc
f01020e6:	68 ac 42 10 f0       	push   $0xf01042ac
f01020eb:	e8 9b df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01020f0:	83 ec 08             	sub    $0x8,%esp
f01020f3:	6a 02                	push   $0x2
f01020f5:	68 00 c0 10 00       	push   $0x10c000
f01020fa:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020ff:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102104:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102109:	e8 61 ed ff ff       	call   f0100e6f <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f010210e:	83 c4 08             	add    $0x8,%esp
f0102111:	6a 02                	push   $0x2
f0102113:	6a 00                	push   $0x0
f0102115:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010211a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010211f:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102124:	e8 46 ed ff ff       	call   f0100e6f <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102129:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010212f:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0102134:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102137:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010213e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102143:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102146:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010214c:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010214f:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102152:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102157:	eb 55                	jmp    f01021ae <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102159:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010215f:	89 f0                	mov    %esi,%eax
f0102161:	e8 a3 e7 ff ff       	call   f0100909 <check_va2pa>
f0102166:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010216d:	77 15                	ja     f0102184 <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010216f:	57                   	push   %edi
f0102170:	68 9c 3c 10 f0       	push   $0xf0103c9c
f0102175:	68 b4 02 00 00       	push   $0x2b4
f010217a:	68 ac 42 10 f0       	push   $0xf01042ac
f010217f:	e8 07 df ff ff       	call   f010008b <_panic>
f0102184:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010218b:	39 c2                	cmp    %eax,%edx
f010218d:	74 19                	je     f01021a8 <mem_init+0x11cd>
f010218f:	68 18 41 10 f0       	push   $0xf0104118
f0102194:	68 d2 42 10 f0       	push   $0xf01042d2
f0102199:	68 b4 02 00 00       	push   $0x2b4
f010219e:	68 ac 42 10 f0       	push   $0xf01042ac
f01021a3:	e8 e3 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021a8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021ae:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021b1:	77 a6                	ja     f0102159 <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021b3:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021b6:	c1 e7 0c             	shl    $0xc,%edi
f01021b9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021be:	eb 30                	jmp    f01021f0 <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021c0:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01021c6:	89 f0                	mov    %esi,%eax
f01021c8:	e8 3c e7 ff ff       	call   f0100909 <check_va2pa>
f01021cd:	39 c3                	cmp    %eax,%ebx
f01021cf:	74 19                	je     f01021ea <mem_init+0x120f>
f01021d1:	68 4c 41 10 f0       	push   $0xf010414c
f01021d6:	68 d2 42 10 f0       	push   $0xf01042d2
f01021db:	68 b9 02 00 00       	push   $0x2b9
f01021e0:	68 ac 42 10 f0       	push   $0xf01042ac
f01021e5:	e8 a1 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021ea:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021f0:	39 fb                	cmp    %edi,%ebx
f01021f2:	72 cc                	jb     f01021c0 <mem_init+0x11e5>
f01021f4:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01021f9:	89 da                	mov    %ebx,%edx
f01021fb:	89 f0                	mov    %esi,%eax
f01021fd:	e8 07 e7 ff ff       	call   f0100909 <check_va2pa>
f0102202:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102208:	39 c2                	cmp    %eax,%edx
f010220a:	74 19                	je     f0102225 <mem_init+0x124a>
f010220c:	68 74 41 10 f0       	push   $0xf0104174
f0102211:	68 d2 42 10 f0       	push   $0xf01042d2
f0102216:	68 bd 02 00 00       	push   $0x2bd
f010221b:	68 ac 42 10 f0       	push   $0xf01042ac
f0102220:	e8 66 de ff ff       	call   f010008b <_panic>
f0102225:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010222b:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102231:	75 c6                	jne    f01021f9 <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102233:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102238:	89 f0                	mov    %esi,%eax
f010223a:	e8 ca e6 ff ff       	call   f0100909 <check_va2pa>
f010223f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102242:	74 51                	je     f0102295 <mem_init+0x12ba>
f0102244:	68 bc 41 10 f0       	push   $0xf01041bc
f0102249:	68 d2 42 10 f0       	push   $0xf01042d2
f010224e:	68 be 02 00 00       	push   $0x2be
f0102253:	68 ac 42 10 f0       	push   $0xf01042ac
f0102258:	e8 2e de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010225d:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102262:	72 36                	jb     f010229a <mem_init+0x12bf>
f0102264:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102269:	76 07                	jbe    f0102272 <mem_init+0x1297>
f010226b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102270:	75 28                	jne    f010229a <mem_init+0x12bf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102272:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102276:	0f 85 83 00 00 00    	jne    f01022ff <mem_init+0x1324>
f010227c:	68 76 45 10 f0       	push   $0xf0104576
f0102281:	68 d2 42 10 f0       	push   $0xf01042d2
f0102286:	68 c6 02 00 00       	push   $0x2c6
f010228b:	68 ac 42 10 f0       	push   $0xf01042ac
f0102290:	e8 f6 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102295:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010229a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010229f:	76 3f                	jbe    f01022e0 <mem_init+0x1305>
				assert(pgdir[i] & PTE_P);
f01022a1:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022a4:	f6 c2 01             	test   $0x1,%dl
f01022a7:	75 19                	jne    f01022c2 <mem_init+0x12e7>
f01022a9:	68 76 45 10 f0       	push   $0xf0104576
f01022ae:	68 d2 42 10 f0       	push   $0xf01042d2
f01022b3:	68 ca 02 00 00       	push   $0x2ca
f01022b8:	68 ac 42 10 f0       	push   $0xf01042ac
f01022bd:	e8 c9 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01022c2:	f6 c2 02             	test   $0x2,%dl
f01022c5:	75 38                	jne    f01022ff <mem_init+0x1324>
f01022c7:	68 87 45 10 f0       	push   $0xf0104587
f01022cc:	68 d2 42 10 f0       	push   $0xf01042d2
f01022d1:	68 cb 02 00 00       	push   $0x2cb
f01022d6:	68 ac 42 10 f0       	push   $0xf01042ac
f01022db:	e8 ab dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f01022e0:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01022e4:	74 19                	je     f01022ff <mem_init+0x1324>
f01022e6:	68 98 45 10 f0       	push   $0xf0104598
f01022eb:	68 d2 42 10 f0       	push   $0xf01042d2
f01022f0:	68 cd 02 00 00       	push   $0x2cd
f01022f5:	68 ac 42 10 f0       	push   $0xf01042ac
f01022fa:	e8 8c dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01022ff:	83 c0 01             	add    $0x1,%eax
f0102302:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102307:	0f 86 50 ff ff ff    	jbe    f010225d <mem_init+0x1282>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010230d:	83 ec 0c             	sub    $0xc,%esp
f0102310:	68 ec 41 10 f0       	push   $0xf01041ec
f0102315:	e8 ba 03 00 00       	call   f01026d4 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010231a:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010231f:	83 c4 10             	add    $0x10,%esp
f0102322:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102327:	77 15                	ja     f010233e <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102329:	50                   	push   %eax
f010232a:	68 9c 3c 10 f0       	push   $0xf0103c9c
f010232f:	68 d0 00 00 00       	push   $0xd0
f0102334:	68 ac 42 10 f0       	push   $0xf01042ac
f0102339:	e8 4d dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010233e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102343:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102346:	b8 00 00 00 00       	mov    $0x0,%eax
f010234b:	e8 1d e6 ff ff       	call   f010096d <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102350:	0f 20 c0             	mov    %cr0,%eax
f0102353:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102356:	0d 23 00 05 80       	or     $0x80050023,%eax
f010235b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010235e:	83 ec 0c             	sub    $0xc,%esp
f0102361:	6a 00                	push   $0x0
f0102363:	e8 a2 e9 ff ff       	call   f0100d0a <page_alloc>
f0102368:	89 c3                	mov    %eax,%ebx
f010236a:	83 c4 10             	add    $0x10,%esp
f010236d:	85 c0                	test   %eax,%eax
f010236f:	75 19                	jne    f010238a <mem_init+0x13af>
f0102371:	68 94 43 10 f0       	push   $0xf0104394
f0102376:	68 d2 42 10 f0       	push   $0xf01042d2
f010237b:	68 8d 03 00 00       	push   $0x38d
f0102380:	68 ac 42 10 f0       	push   $0xf01042ac
f0102385:	e8 01 dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010238a:	83 ec 0c             	sub    $0xc,%esp
f010238d:	6a 00                	push   $0x0
f010238f:	e8 76 e9 ff ff       	call   f0100d0a <page_alloc>
f0102394:	89 c7                	mov    %eax,%edi
f0102396:	83 c4 10             	add    $0x10,%esp
f0102399:	85 c0                	test   %eax,%eax
f010239b:	75 19                	jne    f01023b6 <mem_init+0x13db>
f010239d:	68 aa 43 10 f0       	push   $0xf01043aa
f01023a2:	68 d2 42 10 f0       	push   $0xf01042d2
f01023a7:	68 8e 03 00 00       	push   $0x38e
f01023ac:	68 ac 42 10 f0       	push   $0xf01042ac
f01023b1:	e8 d5 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023b6:	83 ec 0c             	sub    $0xc,%esp
f01023b9:	6a 00                	push   $0x0
f01023bb:	e8 4a e9 ff ff       	call   f0100d0a <page_alloc>
f01023c0:	89 c6                	mov    %eax,%esi
f01023c2:	83 c4 10             	add    $0x10,%esp
f01023c5:	85 c0                	test   %eax,%eax
f01023c7:	75 19                	jne    f01023e2 <mem_init+0x1407>
f01023c9:	68 c0 43 10 f0       	push   $0xf01043c0
f01023ce:	68 d2 42 10 f0       	push   $0xf01042d2
f01023d3:	68 8f 03 00 00       	push   $0x38f
f01023d8:	68 ac 42 10 f0       	push   $0xf01042ac
f01023dd:	e8 a9 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01023e2:	83 ec 0c             	sub    $0xc,%esp
f01023e5:	53                   	push   %ebx
f01023e6:	e8 8f e9 ff ff       	call   f0100d7a <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023eb:	89 f8                	mov    %edi,%eax
f01023ed:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01023f3:	c1 f8 03             	sar    $0x3,%eax
f01023f6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023f9:	89 c2                	mov    %eax,%edx
f01023fb:	c1 ea 0c             	shr    $0xc,%edx
f01023fe:	83 c4 10             	add    $0x10,%esp
f0102401:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102407:	72 12                	jb     f010241b <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102409:	50                   	push   %eax
f010240a:	68 58 3b 10 f0       	push   $0xf0103b58
f010240f:	6a 52                	push   $0x52
f0102411:	68 b8 42 10 f0       	push   $0xf01042b8
f0102416:	e8 70 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010241b:	83 ec 04             	sub    $0x4,%esp
f010241e:	68 00 10 00 00       	push   $0x1000
f0102423:	6a 01                	push   $0x1
f0102425:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010242a:	50                   	push   %eax
f010242b:	e8 9c 0d 00 00       	call   f01031cc <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102430:	89 f0                	mov    %esi,%eax
f0102432:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102438:	c1 f8 03             	sar    $0x3,%eax
f010243b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010243e:	89 c2                	mov    %eax,%edx
f0102440:	c1 ea 0c             	shr    $0xc,%edx
f0102443:	83 c4 10             	add    $0x10,%esp
f0102446:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010244c:	72 12                	jb     f0102460 <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010244e:	50                   	push   %eax
f010244f:	68 58 3b 10 f0       	push   $0xf0103b58
f0102454:	6a 52                	push   $0x52
f0102456:	68 b8 42 10 f0       	push   $0xf01042b8
f010245b:	e8 2b dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102460:	83 ec 04             	sub    $0x4,%esp
f0102463:	68 00 10 00 00       	push   $0x1000
f0102468:	6a 02                	push   $0x2
f010246a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010246f:	50                   	push   %eax
f0102470:	e8 57 0d 00 00       	call   f01031cc <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102475:	6a 02                	push   $0x2
f0102477:	68 00 10 00 00       	push   $0x1000
f010247c:	57                   	push   %edi
f010247d:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102483:	e8 db ea ff ff       	call   f0100f63 <page_insert>
	assert(pp1->pp_ref == 1);
f0102488:	83 c4 20             	add    $0x20,%esp
f010248b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102490:	74 19                	je     f01024ab <mem_init+0x14d0>
f0102492:	68 91 44 10 f0       	push   $0xf0104491
f0102497:	68 d2 42 10 f0       	push   $0xf01042d2
f010249c:	68 94 03 00 00       	push   $0x394
f01024a1:	68 ac 42 10 f0       	push   $0xf01042ac
f01024a6:	e8 e0 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024ab:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024b2:	01 01 01 
f01024b5:	74 19                	je     f01024d0 <mem_init+0x14f5>
f01024b7:	68 0c 42 10 f0       	push   $0xf010420c
f01024bc:	68 d2 42 10 f0       	push   $0xf01042d2
f01024c1:	68 95 03 00 00       	push   $0x395
f01024c6:	68 ac 42 10 f0       	push   $0xf01042ac
f01024cb:	e8 bb db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01024d0:	6a 02                	push   $0x2
f01024d2:	68 00 10 00 00       	push   $0x1000
f01024d7:	56                   	push   %esi
f01024d8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024de:	e8 80 ea ff ff       	call   f0100f63 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01024e3:	83 c4 10             	add    $0x10,%esp
f01024e6:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01024ed:	02 02 02 
f01024f0:	74 19                	je     f010250b <mem_init+0x1530>
f01024f2:	68 30 42 10 f0       	push   $0xf0104230
f01024f7:	68 d2 42 10 f0       	push   $0xf01042d2
f01024fc:	68 97 03 00 00       	push   $0x397
f0102501:	68 ac 42 10 f0       	push   $0xf01042ac
f0102506:	e8 80 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010250b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102510:	74 19                	je     f010252b <mem_init+0x1550>
f0102512:	68 b3 44 10 f0       	push   $0xf01044b3
f0102517:	68 d2 42 10 f0       	push   $0xf01042d2
f010251c:	68 98 03 00 00       	push   $0x398
f0102521:	68 ac 42 10 f0       	push   $0xf01042ac
f0102526:	e8 60 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010252b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102530:	74 19                	je     f010254b <mem_init+0x1570>
f0102532:	68 1d 45 10 f0       	push   $0xf010451d
f0102537:	68 d2 42 10 f0       	push   $0xf01042d2
f010253c:	68 99 03 00 00       	push   $0x399
f0102541:	68 ac 42 10 f0       	push   $0xf01042ac
f0102546:	e8 40 db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010254b:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102552:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102555:	89 f0                	mov    %esi,%eax
f0102557:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010255d:	c1 f8 03             	sar    $0x3,%eax
f0102560:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102563:	89 c2                	mov    %eax,%edx
f0102565:	c1 ea 0c             	shr    $0xc,%edx
f0102568:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010256e:	72 12                	jb     f0102582 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102570:	50                   	push   %eax
f0102571:	68 58 3b 10 f0       	push   $0xf0103b58
f0102576:	6a 52                	push   $0x52
f0102578:	68 b8 42 10 f0       	push   $0xf01042b8
f010257d:	e8 09 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102582:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102589:	03 03 03 
f010258c:	74 19                	je     f01025a7 <mem_init+0x15cc>
f010258e:	68 54 42 10 f0       	push   $0xf0104254
f0102593:	68 d2 42 10 f0       	push   $0xf01042d2
f0102598:	68 9b 03 00 00       	push   $0x39b
f010259d:	68 ac 42 10 f0       	push   $0xf01042ac
f01025a2:	e8 e4 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025a7:	83 ec 08             	sub    $0x8,%esp
f01025aa:	68 00 10 00 00       	push   $0x1000
f01025af:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01025b5:	e8 6e e9 ff ff       	call   f0100f28 <page_remove>
	assert(pp2->pp_ref == 0);
f01025ba:	83 c4 10             	add    $0x10,%esp
f01025bd:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025c2:	74 19                	je     f01025dd <mem_init+0x1602>
f01025c4:	68 eb 44 10 f0       	push   $0xf01044eb
f01025c9:	68 d2 42 10 f0       	push   $0xf01042d2
f01025ce:	68 9d 03 00 00       	push   $0x39d
f01025d3:	68 ac 42 10 f0       	push   $0xf01042ac
f01025d8:	e8 ae da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025dd:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f01025e3:	8b 11                	mov    (%ecx),%edx
f01025e5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01025eb:	89 d8                	mov    %ebx,%eax
f01025ed:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01025f3:	c1 f8 03             	sar    $0x3,%eax
f01025f6:	c1 e0 0c             	shl    $0xc,%eax
f01025f9:	39 c2                	cmp    %eax,%edx
f01025fb:	74 19                	je     f0102616 <mem_init+0x163b>
f01025fd:	68 98 3d 10 f0       	push   $0xf0103d98
f0102602:	68 d2 42 10 f0       	push   $0xf01042d2
f0102607:	68 a0 03 00 00       	push   $0x3a0
f010260c:	68 ac 42 10 f0       	push   $0xf01042ac
f0102611:	e8 75 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102616:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010261c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102621:	74 19                	je     f010263c <mem_init+0x1661>
f0102623:	68 a2 44 10 f0       	push   $0xf01044a2
f0102628:	68 d2 42 10 f0       	push   $0xf01042d2
f010262d:	68 a2 03 00 00       	push   $0x3a2
f0102632:	68 ac 42 10 f0       	push   $0xf01042ac
f0102637:	e8 4f da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010263c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102642:	83 ec 0c             	sub    $0xc,%esp
f0102645:	53                   	push   %ebx
f0102646:	e8 2f e7 ff ff       	call   f0100d7a <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010264b:	c7 04 24 80 42 10 f0 	movl   $0xf0104280,(%esp)
f0102652:	e8 7d 00 00 00       	call   f01026d4 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102657:	83 c4 10             	add    $0x10,%esp
f010265a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010265d:	5b                   	pop    %ebx
f010265e:	5e                   	pop    %esi
f010265f:	5f                   	pop    %edi
f0102660:	5d                   	pop    %ebp
f0102661:	c3                   	ret    

f0102662 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102662:	55                   	push   %ebp
f0102663:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102665:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102668:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010266b:	5d                   	pop    %ebp
f010266c:	c3                   	ret    

f010266d <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010266d:	55                   	push   %ebp
f010266e:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102670:	ba 70 00 00 00       	mov    $0x70,%edx
f0102675:	8b 45 08             	mov    0x8(%ebp),%eax
f0102678:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102679:	ba 71 00 00 00       	mov    $0x71,%edx
f010267e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010267f:	0f b6 c0             	movzbl %al,%eax
}
f0102682:	5d                   	pop    %ebp
f0102683:	c3                   	ret    

f0102684 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102684:	55                   	push   %ebp
f0102685:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102687:	ba 70 00 00 00       	mov    $0x70,%edx
f010268c:	8b 45 08             	mov    0x8(%ebp),%eax
f010268f:	ee                   	out    %al,(%dx)
f0102690:	ba 71 00 00 00       	mov    $0x71,%edx
f0102695:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102698:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102699:	5d                   	pop    %ebp
f010269a:	c3                   	ret    

f010269b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010269b:	55                   	push   %ebp
f010269c:	89 e5                	mov    %esp,%ebp
f010269e:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026a1:	ff 75 08             	pushl  0x8(%ebp)
f01026a4:	e8 49 df ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f01026a9:	83 c4 10             	add    $0x10,%esp
f01026ac:	c9                   	leave  
f01026ad:	c3                   	ret    

f01026ae <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026ae:	55                   	push   %ebp
f01026af:	89 e5                	mov    %esp,%ebp
f01026b1:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026bb:	ff 75 0c             	pushl  0xc(%ebp)
f01026be:	ff 75 08             	pushl  0x8(%ebp)
f01026c1:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026c4:	50                   	push   %eax
f01026c5:	68 9b 26 10 f0       	push   $0xf010269b
f01026ca:	e8 71 04 00 00       	call   f0102b40 <vprintfmt>
	return cnt;
}
f01026cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026d2:	c9                   	leave  
f01026d3:	c3                   	ret    

f01026d4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026d4:	55                   	push   %ebp
f01026d5:	89 e5                	mov    %esp,%ebp
f01026d7:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01026da:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01026dd:	50                   	push   %eax
f01026de:	ff 75 08             	pushl  0x8(%ebp)
f01026e1:	e8 c8 ff ff ff       	call   f01026ae <vcprintf>
	va_end(ap);

	return cnt;
}
f01026e6:	c9                   	leave  
f01026e7:	c3                   	ret    

f01026e8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01026e8:	55                   	push   %ebp
f01026e9:	89 e5                	mov    %esp,%ebp
f01026eb:	57                   	push   %edi
f01026ec:	56                   	push   %esi
f01026ed:	53                   	push   %ebx
f01026ee:	83 ec 14             	sub    $0x14,%esp
f01026f1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01026f4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01026f7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01026fa:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01026fd:	8b 1a                	mov    (%edx),%ebx
f01026ff:	8b 01                	mov    (%ecx),%eax
f0102701:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102704:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010270b:	eb 7f                	jmp    f010278c <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010270d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102710:	01 d8                	add    %ebx,%eax
f0102712:	89 c6                	mov    %eax,%esi
f0102714:	c1 ee 1f             	shr    $0x1f,%esi
f0102717:	01 c6                	add    %eax,%esi
f0102719:	d1 fe                	sar    %esi
f010271b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010271e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102721:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102724:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102726:	eb 03                	jmp    f010272b <stab_binsearch+0x43>
			m--;
f0102728:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010272b:	39 c3                	cmp    %eax,%ebx
f010272d:	7f 0d                	jg     f010273c <stab_binsearch+0x54>
f010272f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102733:	83 ea 0c             	sub    $0xc,%edx
f0102736:	39 f9                	cmp    %edi,%ecx
f0102738:	75 ee                	jne    f0102728 <stab_binsearch+0x40>
f010273a:	eb 05                	jmp    f0102741 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010273c:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010273f:	eb 4b                	jmp    f010278c <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102741:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102744:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102747:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010274b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010274e:	76 11                	jbe    f0102761 <stab_binsearch+0x79>
			*region_left = m;
f0102750:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102753:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102755:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102758:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010275f:	eb 2b                	jmp    f010278c <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102761:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102764:	73 14                	jae    f010277a <stab_binsearch+0x92>
			*region_right = m - 1;
f0102766:	83 e8 01             	sub    $0x1,%eax
f0102769:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010276c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010276f:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102771:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102778:	eb 12                	jmp    f010278c <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010277a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010277d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010277f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102783:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102785:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010278c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010278f:	0f 8e 78 ff ff ff    	jle    f010270d <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102795:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102799:	75 0f                	jne    f01027aa <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010279b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010279e:	8b 00                	mov    (%eax),%eax
f01027a0:	83 e8 01             	sub    $0x1,%eax
f01027a3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027a6:	89 06                	mov    %eax,(%esi)
f01027a8:	eb 2c                	jmp    f01027d6 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027ad:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027af:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027b2:	8b 0e                	mov    (%esi),%ecx
f01027b4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027b7:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027ba:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027bd:	eb 03                	jmp    f01027c2 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027bf:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027c2:	39 c8                	cmp    %ecx,%eax
f01027c4:	7e 0b                	jle    f01027d1 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027c6:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027ca:	83 ea 0c             	sub    $0xc,%edx
f01027cd:	39 df                	cmp    %ebx,%edi
f01027cf:	75 ee                	jne    f01027bf <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027d1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027d4:	89 06                	mov    %eax,(%esi)
	}
}
f01027d6:	83 c4 14             	add    $0x14,%esp
f01027d9:	5b                   	pop    %ebx
f01027da:	5e                   	pop    %esi
f01027db:	5f                   	pop    %edi
f01027dc:	5d                   	pop    %ebp
f01027dd:	c3                   	ret    

f01027de <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.

int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01027de:	55                   	push   %ebp
f01027df:	89 e5                	mov    %esp,%ebp
f01027e1:	57                   	push   %edi
f01027e2:	56                   	push   %esi
f01027e3:	53                   	push   %ebx
f01027e4:	83 ec 3c             	sub    $0x3c,%esp
f01027e7:	8b 75 08             	mov    0x8(%ebp),%esi
f01027ea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01027ed:	c7 03 a6 45 10 f0    	movl   $0xf01045a6,(%ebx)
	info->eip_line = 0;
f01027f3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01027fa:	c7 43 08 a6 45 10 f0 	movl   $0xf01045a6,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102801:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102808:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010280b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102812:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102818:	76 11                	jbe    f010282b <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010281a:	b8 26 be 10 f0       	mov    $0xf010be26,%eax
f010281f:	3d 59 a0 10 f0       	cmp    $0xf010a059,%eax
f0102824:	77 19                	ja     f010283f <debuginfo_eip+0x61>
f0102826:	e9 c9 01 00 00       	jmp    f01029f4 <debuginfo_eip+0x216>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010282b:	83 ec 04             	sub    $0x4,%esp
f010282e:	68 b0 45 10 f0       	push   $0xf01045b0
f0102833:	6a 7e                	push   $0x7e
f0102835:	68 bd 45 10 f0       	push   $0xf01045bd
f010283a:	e8 4c d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010283f:	80 3d 25 be 10 f0 00 	cmpb   $0x0,0xf010be25
f0102846:	0f 85 af 01 00 00    	jne    f01029fb <debuginfo_eip+0x21d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010284c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102853:	b8 58 a0 10 f0       	mov    $0xf010a058,%eax
f0102858:	2d f0 47 10 f0       	sub    $0xf01047f0,%eax
f010285d:	c1 f8 02             	sar    $0x2,%eax
f0102860:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102866:	83 e8 01             	sub    $0x1,%eax
f0102869:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010286c:	83 ec 08             	sub    $0x8,%esp
f010286f:	56                   	push   %esi
f0102870:	6a 64                	push   $0x64
f0102872:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102875:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102878:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f010287d:	e8 66 fe ff ff       	call   f01026e8 <stab_binsearch>
	if (lfile == 0)
f0102882:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102885:	83 c4 10             	add    $0x10,%esp
f0102888:	85 c0                	test   %eax,%eax
f010288a:	0f 84 72 01 00 00    	je     f0102a02 <debuginfo_eip+0x224>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102890:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102893:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102896:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102899:	83 ec 08             	sub    $0x8,%esp
f010289c:	56                   	push   %esi
f010289d:	6a 24                	push   $0x24
f010289f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028a2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028a5:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f01028aa:	e8 39 fe ff ff       	call   f01026e8 <stab_binsearch>

	if (lfun <= rfun) {
f01028af:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028b2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028b5:	83 c4 10             	add    $0x10,%esp
f01028b8:	39 d0                	cmp    %edx,%eax
f01028ba:	7f 40                	jg     f01028fc <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028bc:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01028bf:	c1 e1 02             	shl    $0x2,%ecx
f01028c2:	8d b9 f0 47 10 f0    	lea    -0xfefb810(%ecx),%edi
f01028c8:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028cb:	8b b9 f0 47 10 f0    	mov    -0xfefb810(%ecx),%edi
f01028d1:	b9 26 be 10 f0       	mov    $0xf010be26,%ecx
f01028d6:	81 e9 59 a0 10 f0    	sub    $0xf010a059,%ecx
f01028dc:	39 cf                	cmp    %ecx,%edi
f01028de:	73 09                	jae    f01028e9 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01028e0:	81 c7 59 a0 10 f0    	add    $0xf010a059,%edi
f01028e6:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01028e9:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01028ec:	8b 4f 08             	mov    0x8(%edi),%ecx
f01028ef:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01028f2:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01028f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01028f7:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01028fa:	eb 0f                	jmp    f010290b <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01028fc:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01028ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102902:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102905:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102908:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010290b:	83 ec 08             	sub    $0x8,%esp
f010290e:	6a 3a                	push   $0x3a
f0102910:	ff 73 08             	pushl  0x8(%ebx)
f0102913:	e8 98 08 00 00       	call   f01031b0 <strfind>
f0102918:	2b 43 08             	sub    0x8(%ebx),%eax
f010291b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
        info->eip_file = stabstr + stabs[lfile].n_strx;
f010291e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102921:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102924:	8b 04 85 f0 47 10 f0 	mov    -0xfefb810(,%eax,4),%eax
f010292b:	05 59 a0 10 f0       	add    $0xf010a059,%eax
f0102930:	89 03                	mov    %eax,(%ebx)
        stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102932:	83 c4 08             	add    $0x8,%esp
f0102935:	56                   	push   %esi
f0102936:	6a 44                	push   $0x44
f0102938:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010293b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010293e:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f0102943:	e8 a0 fd ff ff       	call   f01026e8 <stab_binsearch>
        if (lline > rline) {
f0102948:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010294b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010294e:	83 c4 10             	add    $0x10,%esp
f0102951:	39 d0                	cmp    %edx,%eax
f0102953:	0f 8f b0 00 00 00    	jg     f0102a09 <debuginfo_eip+0x22b>
            return -1;
        } else {
            info->eip_line = stabs[rline].n_desc;
f0102959:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010295c:	0f b7 14 95 f6 47 10 	movzwl -0xfefb80a(,%edx,4),%edx
f0102963:	f0 
f0102964:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102967:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010296a:	89 c2                	mov    %eax,%edx
f010296c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010296f:	8d 04 85 f0 47 10 f0 	lea    -0xfefb810(,%eax,4),%eax
f0102976:	eb 06                	jmp    f010297e <debuginfo_eip+0x1a0>
f0102978:	83 ea 01             	sub    $0x1,%edx
f010297b:	83 e8 0c             	sub    $0xc,%eax
f010297e:	39 d7                	cmp    %edx,%edi
f0102980:	7f 34                	jg     f01029b6 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0102982:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102986:	80 f9 84             	cmp    $0x84,%cl
f0102989:	74 0b                	je     f0102996 <debuginfo_eip+0x1b8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010298b:	80 f9 64             	cmp    $0x64,%cl
f010298e:	75 e8                	jne    f0102978 <debuginfo_eip+0x19a>
f0102990:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102994:	74 e2                	je     f0102978 <debuginfo_eip+0x19a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102996:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102999:	8b 14 85 f0 47 10 f0 	mov    -0xfefb810(,%eax,4),%edx
f01029a0:	b8 26 be 10 f0       	mov    $0xf010be26,%eax
f01029a5:	2d 59 a0 10 f0       	sub    $0xf010a059,%eax
f01029aa:	39 c2                	cmp    %eax,%edx
f01029ac:	73 08                	jae    f01029b6 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029ae:	81 c2 59 a0 10 f0    	add    $0xf010a059,%edx
f01029b4:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029b6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01029b9:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029bc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029c1:	39 f2                	cmp    %esi,%edx
f01029c3:	7d 50                	jge    f0102a15 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
f01029c5:	83 c2 01             	add    $0x1,%edx
f01029c8:	89 d0                	mov    %edx,%eax
f01029ca:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029cd:	8d 14 95 f0 47 10 f0 	lea    -0xfefb810(,%edx,4),%edx
f01029d4:	eb 04                	jmp    f01029da <debuginfo_eip+0x1fc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029d6:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029da:	39 c6                	cmp    %eax,%esi
f01029dc:	7e 32                	jle    f0102a10 <debuginfo_eip+0x232>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029de:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01029e2:	83 c0 01             	add    $0x1,%eax
f01029e5:	83 c2 0c             	add    $0xc,%edx
f01029e8:	80 f9 a0             	cmp    $0xa0,%cl
f01029eb:	74 e9                	je     f01029d6 <debuginfo_eip+0x1f8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01029f2:	eb 21                	jmp    f0102a15 <debuginfo_eip+0x237>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029f9:	eb 1a                	jmp    f0102a15 <debuginfo_eip+0x237>
f01029fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a00:	eb 13                	jmp    f0102a15 <debuginfo_eip+0x237>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a07:	eb 0c                	jmp    f0102a15 <debuginfo_eip+0x237>
	//	which one.
	// Your code here.
        info->eip_file = stabstr + stabs[lfile].n_strx;
        stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
        if (lline > rline) {
            return -1;
f0102a09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a0e:	eb 05                	jmp    f0102a15 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a10:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a15:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a18:	5b                   	pop    %ebx
f0102a19:	5e                   	pop    %esi
f0102a1a:	5f                   	pop    %edi
f0102a1b:	5d                   	pop    %ebp
f0102a1c:	c3                   	ret    

f0102a1d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a1d:	55                   	push   %ebp
f0102a1e:	89 e5                	mov    %esp,%ebp
f0102a20:	57                   	push   %edi
f0102a21:	56                   	push   %esi
f0102a22:	53                   	push   %ebx
f0102a23:	83 ec 1c             	sub    $0x1c,%esp
f0102a26:	89 c7                	mov    %eax,%edi
f0102a28:	89 d6                	mov    %edx,%esi
f0102a2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a2d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a30:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a33:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a36:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a39:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a3e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a41:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a44:	39 d3                	cmp    %edx,%ebx
f0102a46:	72 05                	jb     f0102a4d <printnum+0x30>
f0102a48:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a4b:	77 45                	ja     f0102a92 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a4d:	83 ec 0c             	sub    $0xc,%esp
f0102a50:	ff 75 18             	pushl  0x18(%ebp)
f0102a53:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a56:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a59:	53                   	push   %ebx
f0102a5a:	ff 75 10             	pushl  0x10(%ebp)
f0102a5d:	83 ec 08             	sub    $0x8,%esp
f0102a60:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a63:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a66:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a69:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a6c:	e8 5f 09 00 00       	call   f01033d0 <__udivdi3>
f0102a71:	83 c4 18             	add    $0x18,%esp
f0102a74:	52                   	push   %edx
f0102a75:	50                   	push   %eax
f0102a76:	89 f2                	mov    %esi,%edx
f0102a78:	89 f8                	mov    %edi,%eax
f0102a7a:	e8 9e ff ff ff       	call   f0102a1d <printnum>
f0102a7f:	83 c4 20             	add    $0x20,%esp
f0102a82:	eb 18                	jmp    f0102a9c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a84:	83 ec 08             	sub    $0x8,%esp
f0102a87:	56                   	push   %esi
f0102a88:	ff 75 18             	pushl  0x18(%ebp)
f0102a8b:	ff d7                	call   *%edi
f0102a8d:	83 c4 10             	add    $0x10,%esp
f0102a90:	eb 03                	jmp    f0102a95 <printnum+0x78>
f0102a92:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a95:	83 eb 01             	sub    $0x1,%ebx
f0102a98:	85 db                	test   %ebx,%ebx
f0102a9a:	7f e8                	jg     f0102a84 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a9c:	83 ec 08             	sub    $0x8,%esp
f0102a9f:	56                   	push   %esi
f0102aa0:	83 ec 04             	sub    $0x4,%esp
f0102aa3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aa6:	ff 75 e0             	pushl  -0x20(%ebp)
f0102aa9:	ff 75 dc             	pushl  -0x24(%ebp)
f0102aac:	ff 75 d8             	pushl  -0x28(%ebp)
f0102aaf:	e8 4c 0a 00 00       	call   f0103500 <__umoddi3>
f0102ab4:	83 c4 14             	add    $0x14,%esp
f0102ab7:	0f be 80 cb 45 10 f0 	movsbl -0xfefba35(%eax),%eax
f0102abe:	50                   	push   %eax
f0102abf:	ff d7                	call   *%edi
}
f0102ac1:	83 c4 10             	add    $0x10,%esp
f0102ac4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ac7:	5b                   	pop    %ebx
f0102ac8:	5e                   	pop    %esi
f0102ac9:	5f                   	pop    %edi
f0102aca:	5d                   	pop    %ebp
f0102acb:	c3                   	ret    

f0102acc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102acc:	55                   	push   %ebp
f0102acd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102acf:	83 fa 01             	cmp    $0x1,%edx
f0102ad2:	7e 0e                	jle    f0102ae2 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102ad4:	8b 10                	mov    (%eax),%edx
f0102ad6:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102ad9:	89 08                	mov    %ecx,(%eax)
f0102adb:	8b 02                	mov    (%edx),%eax
f0102add:	8b 52 04             	mov    0x4(%edx),%edx
f0102ae0:	eb 22                	jmp    f0102b04 <getuint+0x38>
	else if (lflag)
f0102ae2:	85 d2                	test   %edx,%edx
f0102ae4:	74 10                	je     f0102af6 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102ae6:	8b 10                	mov    (%eax),%edx
f0102ae8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102aeb:	89 08                	mov    %ecx,(%eax)
f0102aed:	8b 02                	mov    (%edx),%eax
f0102aef:	ba 00 00 00 00       	mov    $0x0,%edx
f0102af4:	eb 0e                	jmp    f0102b04 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102af6:	8b 10                	mov    (%eax),%edx
f0102af8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102afb:	89 08                	mov    %ecx,(%eax)
f0102afd:	8b 02                	mov    (%edx),%eax
f0102aff:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b04:	5d                   	pop    %ebp
f0102b05:	c3                   	ret    

f0102b06 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b06:	55                   	push   %ebp
f0102b07:	89 e5                	mov    %esp,%ebp
f0102b09:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b0c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b10:	8b 10                	mov    (%eax),%edx
f0102b12:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b15:	73 0a                	jae    f0102b21 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b17:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b1a:	89 08                	mov    %ecx,(%eax)
f0102b1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b1f:	88 02                	mov    %al,(%edx)
}
f0102b21:	5d                   	pop    %ebp
f0102b22:	c3                   	ret    

f0102b23 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b23:	55                   	push   %ebp
f0102b24:	89 e5                	mov    %esp,%ebp
f0102b26:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b29:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b2c:	50                   	push   %eax
f0102b2d:	ff 75 10             	pushl  0x10(%ebp)
f0102b30:	ff 75 0c             	pushl  0xc(%ebp)
f0102b33:	ff 75 08             	pushl  0x8(%ebp)
f0102b36:	e8 05 00 00 00       	call   f0102b40 <vprintfmt>
	va_end(ap);
}
f0102b3b:	83 c4 10             	add    $0x10,%esp
f0102b3e:	c9                   	leave  
f0102b3f:	c3                   	ret    

f0102b40 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b40:	55                   	push   %ebp
f0102b41:	89 e5                	mov    %esp,%ebp
f0102b43:	57                   	push   %edi
f0102b44:	56                   	push   %esi
f0102b45:	53                   	push   %ebx
f0102b46:	83 ec 2c             	sub    $0x2c,%esp
f0102b49:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b4c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b4f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b52:	eb 12                	jmp    f0102b66 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b54:	85 c0                	test   %eax,%eax
f0102b56:	0f 84 a9 03 00 00    	je     f0102f05 <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
f0102b5c:	83 ec 08             	sub    $0x8,%esp
f0102b5f:	53                   	push   %ebx
f0102b60:	50                   	push   %eax
f0102b61:	ff d6                	call   *%esi
f0102b63:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b66:	83 c7 01             	add    $0x1,%edi
f0102b69:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b6d:	83 f8 25             	cmp    $0x25,%eax
f0102b70:	75 e2                	jne    f0102b54 <vprintfmt+0x14>
f0102b72:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b76:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b7d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b84:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b8b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b90:	eb 07                	jmp    f0102b99 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b92:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b95:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b99:	8d 47 01             	lea    0x1(%edi),%eax
f0102b9c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b9f:	0f b6 07             	movzbl (%edi),%eax
f0102ba2:	0f b6 c8             	movzbl %al,%ecx
f0102ba5:	83 e8 23             	sub    $0x23,%eax
f0102ba8:	3c 55                	cmp    $0x55,%al
f0102baa:	0f 87 3a 03 00 00    	ja     f0102eea <vprintfmt+0x3aa>
f0102bb0:	0f b6 c0             	movzbl %al,%eax
f0102bb3:	ff 24 85 60 46 10 f0 	jmp    *-0xfefb9a0(,%eax,4)
f0102bba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bbd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bc1:	eb d6                	jmp    f0102b99 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bcb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bce:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bd1:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102bd5:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102bd8:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102bdb:	83 fa 09             	cmp    $0x9,%edx
f0102bde:	77 39                	ja     f0102c19 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102be0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102be3:	eb e9                	jmp    f0102bce <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102be5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be8:	8d 48 04             	lea    0x4(%eax),%ecx
f0102beb:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102bee:	8b 00                	mov    (%eax),%eax
f0102bf0:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102bf6:	eb 27                	jmp    f0102c1f <vprintfmt+0xdf>
f0102bf8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bfb:	85 c0                	test   %eax,%eax
f0102bfd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c02:	0f 49 c8             	cmovns %eax,%ecx
f0102c05:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c0b:	eb 8c                	jmp    f0102b99 <vprintfmt+0x59>
f0102c0d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c10:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c17:	eb 80                	jmp    f0102b99 <vprintfmt+0x59>
f0102c19:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c1c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c1f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c23:	0f 89 70 ff ff ff    	jns    f0102b99 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c29:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c2c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c2f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c36:	e9 5e ff ff ff       	jmp    f0102b99 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c3b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c41:	e9 53 ff ff ff       	jmp    f0102b99 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c46:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c49:	8d 50 04             	lea    0x4(%eax),%edx
f0102c4c:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c4f:	83 ec 08             	sub    $0x8,%esp
f0102c52:	53                   	push   %ebx
f0102c53:	ff 30                	pushl  (%eax)
f0102c55:	ff d6                	call   *%esi
			break;
f0102c57:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c5d:	e9 04 ff ff ff       	jmp    f0102b66 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c62:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c65:	8d 50 04             	lea    0x4(%eax),%edx
f0102c68:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c6b:	8b 00                	mov    (%eax),%eax
f0102c6d:	99                   	cltd   
f0102c6e:	31 d0                	xor    %edx,%eax
f0102c70:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c72:	83 f8 07             	cmp    $0x7,%eax
f0102c75:	7f 0b                	jg     f0102c82 <vprintfmt+0x142>
f0102c77:	8b 14 85 c0 47 10 f0 	mov    -0xfefb840(,%eax,4),%edx
f0102c7e:	85 d2                	test   %edx,%edx
f0102c80:	75 18                	jne    f0102c9a <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c82:	50                   	push   %eax
f0102c83:	68 e3 45 10 f0       	push   $0xf01045e3
f0102c88:	53                   	push   %ebx
f0102c89:	56                   	push   %esi
f0102c8a:	e8 94 fe ff ff       	call   f0102b23 <printfmt>
f0102c8f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c95:	e9 cc fe ff ff       	jmp    f0102b66 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c9a:	52                   	push   %edx
f0102c9b:	68 e4 42 10 f0       	push   $0xf01042e4
f0102ca0:	53                   	push   %ebx
f0102ca1:	56                   	push   %esi
f0102ca2:	e8 7c fe ff ff       	call   f0102b23 <printfmt>
f0102ca7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102caa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cad:	e9 b4 fe ff ff       	jmp    f0102b66 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cb2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cb5:	8d 50 04             	lea    0x4(%eax),%edx
f0102cb8:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cbb:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cbd:	85 ff                	test   %edi,%edi
f0102cbf:	b8 dc 45 10 f0       	mov    $0xf01045dc,%eax
f0102cc4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cc7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ccb:	0f 8e 94 00 00 00    	jle    f0102d65 <vprintfmt+0x225>
f0102cd1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cd5:	0f 84 98 00 00 00    	je     f0102d73 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cdb:	83 ec 08             	sub    $0x8,%esp
f0102cde:	ff 75 d0             	pushl  -0x30(%ebp)
f0102ce1:	57                   	push   %edi
f0102ce2:	e8 7f 03 00 00       	call   f0103066 <strnlen>
f0102ce7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cea:	29 c1                	sub    %eax,%ecx
f0102cec:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102cef:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102cf2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102cf6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cf9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102cfc:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cfe:	eb 0f                	jmp    f0102d0f <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d00:	83 ec 08             	sub    $0x8,%esp
f0102d03:	53                   	push   %ebx
f0102d04:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d07:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d09:	83 ef 01             	sub    $0x1,%edi
f0102d0c:	83 c4 10             	add    $0x10,%esp
f0102d0f:	85 ff                	test   %edi,%edi
f0102d11:	7f ed                	jg     f0102d00 <vprintfmt+0x1c0>
f0102d13:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d16:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d19:	85 c9                	test   %ecx,%ecx
f0102d1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d20:	0f 49 c1             	cmovns %ecx,%eax
f0102d23:	29 c1                	sub    %eax,%ecx
f0102d25:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d28:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d2b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d2e:	89 cb                	mov    %ecx,%ebx
f0102d30:	eb 4d                	jmp    f0102d7f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d32:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d36:	74 1b                	je     f0102d53 <vprintfmt+0x213>
f0102d38:	0f be c0             	movsbl %al,%eax
f0102d3b:	83 e8 20             	sub    $0x20,%eax
f0102d3e:	83 f8 5e             	cmp    $0x5e,%eax
f0102d41:	76 10                	jbe    f0102d53 <vprintfmt+0x213>
					putch('?', putdat);
f0102d43:	83 ec 08             	sub    $0x8,%esp
f0102d46:	ff 75 0c             	pushl  0xc(%ebp)
f0102d49:	6a 3f                	push   $0x3f
f0102d4b:	ff 55 08             	call   *0x8(%ebp)
f0102d4e:	83 c4 10             	add    $0x10,%esp
f0102d51:	eb 0d                	jmp    f0102d60 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d53:	83 ec 08             	sub    $0x8,%esp
f0102d56:	ff 75 0c             	pushl  0xc(%ebp)
f0102d59:	52                   	push   %edx
f0102d5a:	ff 55 08             	call   *0x8(%ebp)
f0102d5d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d60:	83 eb 01             	sub    $0x1,%ebx
f0102d63:	eb 1a                	jmp    f0102d7f <vprintfmt+0x23f>
f0102d65:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d68:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d6b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d6e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d71:	eb 0c                	jmp    f0102d7f <vprintfmt+0x23f>
f0102d73:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d76:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d79:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d7c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d7f:	83 c7 01             	add    $0x1,%edi
f0102d82:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d86:	0f be d0             	movsbl %al,%edx
f0102d89:	85 d2                	test   %edx,%edx
f0102d8b:	74 23                	je     f0102db0 <vprintfmt+0x270>
f0102d8d:	85 f6                	test   %esi,%esi
f0102d8f:	78 a1                	js     f0102d32 <vprintfmt+0x1f2>
f0102d91:	83 ee 01             	sub    $0x1,%esi
f0102d94:	79 9c                	jns    f0102d32 <vprintfmt+0x1f2>
f0102d96:	89 df                	mov    %ebx,%edi
f0102d98:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d9b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d9e:	eb 18                	jmp    f0102db8 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102da0:	83 ec 08             	sub    $0x8,%esp
f0102da3:	53                   	push   %ebx
f0102da4:	6a 20                	push   $0x20
f0102da6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102da8:	83 ef 01             	sub    $0x1,%edi
f0102dab:	83 c4 10             	add    $0x10,%esp
f0102dae:	eb 08                	jmp    f0102db8 <vprintfmt+0x278>
f0102db0:	89 df                	mov    %ebx,%edi
f0102db2:	8b 75 08             	mov    0x8(%ebp),%esi
f0102db5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102db8:	85 ff                	test   %edi,%edi
f0102dba:	7f e4                	jg     f0102da0 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dbc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dbf:	e9 a2 fd ff ff       	jmp    f0102b66 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dc4:	83 fa 01             	cmp    $0x1,%edx
f0102dc7:	7e 16                	jle    f0102ddf <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102dc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dcc:	8d 50 08             	lea    0x8(%eax),%edx
f0102dcf:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dd2:	8b 50 04             	mov    0x4(%eax),%edx
f0102dd5:	8b 00                	mov    (%eax),%eax
f0102dd7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dda:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102ddd:	eb 32                	jmp    f0102e11 <vprintfmt+0x2d1>
	else if (lflag)
f0102ddf:	85 d2                	test   %edx,%edx
f0102de1:	74 18                	je     f0102dfb <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102de3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de6:	8d 50 04             	lea    0x4(%eax),%edx
f0102de9:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dec:	8b 00                	mov    (%eax),%eax
f0102dee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102df1:	89 c1                	mov    %eax,%ecx
f0102df3:	c1 f9 1f             	sar    $0x1f,%ecx
f0102df6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102df9:	eb 16                	jmp    f0102e11 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102dfb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dfe:	8d 50 04             	lea    0x4(%eax),%edx
f0102e01:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e04:	8b 00                	mov    (%eax),%eax
f0102e06:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e09:	89 c1                	mov    %eax,%ecx
f0102e0b:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e0e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e11:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e14:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e17:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e1c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e20:	0f 89 90 00 00 00    	jns    f0102eb6 <vprintfmt+0x376>
				putch('-', putdat);
f0102e26:	83 ec 08             	sub    $0x8,%esp
f0102e29:	53                   	push   %ebx
f0102e2a:	6a 2d                	push   $0x2d
f0102e2c:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e2e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e31:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e34:	f7 d8                	neg    %eax
f0102e36:	83 d2 00             	adc    $0x0,%edx
f0102e39:	f7 da                	neg    %edx
f0102e3b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e3e:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e43:	eb 71                	jmp    f0102eb6 <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e45:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e48:	e8 7f fc ff ff       	call   f0102acc <getuint>
			base = 10;
f0102e4d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e52:	eb 62                	jmp    f0102eb6 <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102e54:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e57:	e8 70 fc ff ff       	call   f0102acc <getuint>
                        base = 8;
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
f0102e5c:	83 ec 0c             	sub    $0xc,%esp
f0102e5f:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f0102e63:	51                   	push   %ecx
f0102e64:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e67:	6a 08                	push   $0x8
f0102e69:	52                   	push   %edx
f0102e6a:	50                   	push   %eax
f0102e6b:	89 da                	mov    %ebx,%edx
f0102e6d:	89 f0                	mov    %esi,%eax
f0102e6f:	e8 a9 fb ff ff       	call   f0102a1d <printnum>
                        break;
f0102e74:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
                        break;
f0102e7a:	e9 e7 fc ff ff       	jmp    f0102b66 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e7f:	83 ec 08             	sub    $0x8,%esp
f0102e82:	53                   	push   %ebx
f0102e83:	6a 30                	push   $0x30
f0102e85:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e87:	83 c4 08             	add    $0x8,%esp
f0102e8a:	53                   	push   %ebx
f0102e8b:	6a 78                	push   $0x78
f0102e8d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e8f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e92:	8d 50 04             	lea    0x4(%eax),%edx
f0102e95:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e98:	8b 00                	mov    (%eax),%eax
f0102e9a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e9f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102ea2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102ea7:	eb 0d                	jmp    f0102eb6 <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102ea9:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eac:	e8 1b fc ff ff       	call   f0102acc <getuint>
			base = 16;
f0102eb1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102eb6:	83 ec 0c             	sub    $0xc,%esp
f0102eb9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102ebd:	57                   	push   %edi
f0102ebe:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ec1:	51                   	push   %ecx
f0102ec2:	52                   	push   %edx
f0102ec3:	50                   	push   %eax
f0102ec4:	89 da                	mov    %ebx,%edx
f0102ec6:	89 f0                	mov    %esi,%eax
f0102ec8:	e8 50 fb ff ff       	call   f0102a1d <printnum>
			break;
f0102ecd:	83 c4 20             	add    $0x20,%esp
f0102ed0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ed3:	e9 8e fc ff ff       	jmp    f0102b66 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102ed8:	83 ec 08             	sub    $0x8,%esp
f0102edb:	53                   	push   %ebx
f0102edc:	51                   	push   %ecx
f0102edd:	ff d6                	call   *%esi
			break;
f0102edf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ee2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ee5:	e9 7c fc ff ff       	jmp    f0102b66 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102eea:	83 ec 08             	sub    $0x8,%esp
f0102eed:	53                   	push   %ebx
f0102eee:	6a 25                	push   $0x25
f0102ef0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102ef2:	83 c4 10             	add    $0x10,%esp
f0102ef5:	eb 03                	jmp    f0102efa <vprintfmt+0x3ba>
f0102ef7:	83 ef 01             	sub    $0x1,%edi
f0102efa:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102efe:	75 f7                	jne    f0102ef7 <vprintfmt+0x3b7>
f0102f00:	e9 61 fc ff ff       	jmp    f0102b66 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f05:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f08:	5b                   	pop    %ebx
f0102f09:	5e                   	pop    %esi
f0102f0a:	5f                   	pop    %edi
f0102f0b:	5d                   	pop    %ebp
f0102f0c:	c3                   	ret    

f0102f0d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f0d:	55                   	push   %ebp
f0102f0e:	89 e5                	mov    %esp,%ebp
f0102f10:	83 ec 18             	sub    $0x18,%esp
f0102f13:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f16:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f19:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f1c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f20:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f2a:	85 c0                	test   %eax,%eax
f0102f2c:	74 26                	je     f0102f54 <vsnprintf+0x47>
f0102f2e:	85 d2                	test   %edx,%edx
f0102f30:	7e 22                	jle    f0102f54 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f32:	ff 75 14             	pushl  0x14(%ebp)
f0102f35:	ff 75 10             	pushl  0x10(%ebp)
f0102f38:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f3b:	50                   	push   %eax
f0102f3c:	68 06 2b 10 f0       	push   $0xf0102b06
f0102f41:	e8 fa fb ff ff       	call   f0102b40 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f46:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f49:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f4f:	83 c4 10             	add    $0x10,%esp
f0102f52:	eb 05                	jmp    f0102f59 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f54:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f59:	c9                   	leave  
f0102f5a:	c3                   	ret    

f0102f5b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f5b:	55                   	push   %ebp
f0102f5c:	89 e5                	mov    %esp,%ebp
f0102f5e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f61:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f64:	50                   	push   %eax
f0102f65:	ff 75 10             	pushl  0x10(%ebp)
f0102f68:	ff 75 0c             	pushl  0xc(%ebp)
f0102f6b:	ff 75 08             	pushl  0x8(%ebp)
f0102f6e:	e8 9a ff ff ff       	call   f0102f0d <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f73:	c9                   	leave  
f0102f74:	c3                   	ret    

f0102f75 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f75:	55                   	push   %ebp
f0102f76:	89 e5                	mov    %esp,%ebp
f0102f78:	57                   	push   %edi
f0102f79:	56                   	push   %esi
f0102f7a:	53                   	push   %ebx
f0102f7b:	83 ec 0c             	sub    $0xc,%esp
f0102f7e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f81:	85 c0                	test   %eax,%eax
f0102f83:	74 11                	je     f0102f96 <readline+0x21>
		cprintf("%s", prompt);
f0102f85:	83 ec 08             	sub    $0x8,%esp
f0102f88:	50                   	push   %eax
f0102f89:	68 e4 42 10 f0       	push   $0xf01042e4
f0102f8e:	e8 41 f7 ff ff       	call   f01026d4 <cprintf>
f0102f93:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f96:	83 ec 0c             	sub    $0xc,%esp
f0102f99:	6a 00                	push   $0x0
f0102f9b:	e8 73 d6 ff ff       	call   f0100613 <iscons>
f0102fa0:	89 c7                	mov    %eax,%edi
f0102fa2:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102fa5:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102faa:	e8 53 d6 ff ff       	call   f0100602 <getchar>
f0102faf:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102fb1:	85 c0                	test   %eax,%eax
f0102fb3:	79 18                	jns    f0102fcd <readline+0x58>
			cprintf("read error: %e\n", c);
f0102fb5:	83 ec 08             	sub    $0x8,%esp
f0102fb8:	50                   	push   %eax
f0102fb9:	68 e0 47 10 f0       	push   $0xf01047e0
f0102fbe:	e8 11 f7 ff ff       	call   f01026d4 <cprintf>
			return NULL;
f0102fc3:	83 c4 10             	add    $0x10,%esp
f0102fc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fcb:	eb 79                	jmp    f0103046 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fcd:	83 f8 08             	cmp    $0x8,%eax
f0102fd0:	0f 94 c2             	sete   %dl
f0102fd3:	83 f8 7f             	cmp    $0x7f,%eax
f0102fd6:	0f 94 c0             	sete   %al
f0102fd9:	08 c2                	or     %al,%dl
f0102fdb:	74 1a                	je     f0102ff7 <readline+0x82>
f0102fdd:	85 f6                	test   %esi,%esi
f0102fdf:	7e 16                	jle    f0102ff7 <readline+0x82>
			if (echoing)
f0102fe1:	85 ff                	test   %edi,%edi
f0102fe3:	74 0d                	je     f0102ff2 <readline+0x7d>
				cputchar('\b');
f0102fe5:	83 ec 0c             	sub    $0xc,%esp
f0102fe8:	6a 08                	push   $0x8
f0102fea:	e8 03 d6 ff ff       	call   f01005f2 <cputchar>
f0102fef:	83 c4 10             	add    $0x10,%esp
			i--;
f0102ff2:	83 ee 01             	sub    $0x1,%esi
f0102ff5:	eb b3                	jmp    f0102faa <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102ff7:	83 fb 1f             	cmp    $0x1f,%ebx
f0102ffa:	7e 23                	jle    f010301f <readline+0xaa>
f0102ffc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103002:	7f 1b                	jg     f010301f <readline+0xaa>
			if (echoing)
f0103004:	85 ff                	test   %edi,%edi
f0103006:	74 0c                	je     f0103014 <readline+0x9f>
				cputchar(c);
f0103008:	83 ec 0c             	sub    $0xc,%esp
f010300b:	53                   	push   %ebx
f010300c:	e8 e1 d5 ff ff       	call   f01005f2 <cputchar>
f0103011:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103014:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f010301a:	8d 76 01             	lea    0x1(%esi),%esi
f010301d:	eb 8b                	jmp    f0102faa <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010301f:	83 fb 0a             	cmp    $0xa,%ebx
f0103022:	74 05                	je     f0103029 <readline+0xb4>
f0103024:	83 fb 0d             	cmp    $0xd,%ebx
f0103027:	75 81                	jne    f0102faa <readline+0x35>
			if (echoing)
f0103029:	85 ff                	test   %edi,%edi
f010302b:	74 0d                	je     f010303a <readline+0xc5>
				cputchar('\n');
f010302d:	83 ec 0c             	sub    $0xc,%esp
f0103030:	6a 0a                	push   $0xa
f0103032:	e8 bb d5 ff ff       	call   f01005f2 <cputchar>
f0103037:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010303a:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0103041:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0103046:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103049:	5b                   	pop    %ebx
f010304a:	5e                   	pop    %esi
f010304b:	5f                   	pop    %edi
f010304c:	5d                   	pop    %ebp
f010304d:	c3                   	ret    

f010304e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010304e:	55                   	push   %ebp
f010304f:	89 e5                	mov    %esp,%ebp
f0103051:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103054:	b8 00 00 00 00       	mov    $0x0,%eax
f0103059:	eb 03                	jmp    f010305e <strlen+0x10>
		n++;
f010305b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010305e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103062:	75 f7                	jne    f010305b <strlen+0xd>
		n++;
	return n;
}
f0103064:	5d                   	pop    %ebp
f0103065:	c3                   	ret    

f0103066 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103066:	55                   	push   %ebp
f0103067:	89 e5                	mov    %esp,%ebp
f0103069:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010306c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010306f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103074:	eb 03                	jmp    f0103079 <strnlen+0x13>
		n++;
f0103076:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103079:	39 c2                	cmp    %eax,%edx
f010307b:	74 08                	je     f0103085 <strnlen+0x1f>
f010307d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103081:	75 f3                	jne    f0103076 <strnlen+0x10>
f0103083:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103085:	5d                   	pop    %ebp
f0103086:	c3                   	ret    

f0103087 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103087:	55                   	push   %ebp
f0103088:	89 e5                	mov    %esp,%ebp
f010308a:	53                   	push   %ebx
f010308b:	8b 45 08             	mov    0x8(%ebp),%eax
f010308e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103091:	89 c2                	mov    %eax,%edx
f0103093:	83 c2 01             	add    $0x1,%edx
f0103096:	83 c1 01             	add    $0x1,%ecx
f0103099:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010309d:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030a0:	84 db                	test   %bl,%bl
f01030a2:	75 ef                	jne    f0103093 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01030a4:	5b                   	pop    %ebx
f01030a5:	5d                   	pop    %ebp
f01030a6:	c3                   	ret    

f01030a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030a7:	55                   	push   %ebp
f01030a8:	89 e5                	mov    %esp,%ebp
f01030aa:	53                   	push   %ebx
f01030ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01030ae:	53                   	push   %ebx
f01030af:	e8 9a ff ff ff       	call   f010304e <strlen>
f01030b4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030b7:	ff 75 0c             	pushl  0xc(%ebp)
f01030ba:	01 d8                	add    %ebx,%eax
f01030bc:	50                   	push   %eax
f01030bd:	e8 c5 ff ff ff       	call   f0103087 <strcpy>
	return dst;
}
f01030c2:	89 d8                	mov    %ebx,%eax
f01030c4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030c7:	c9                   	leave  
f01030c8:	c3                   	ret    

f01030c9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030c9:	55                   	push   %ebp
f01030ca:	89 e5                	mov    %esp,%ebp
f01030cc:	56                   	push   %esi
f01030cd:	53                   	push   %ebx
f01030ce:	8b 75 08             	mov    0x8(%ebp),%esi
f01030d1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030d4:	89 f3                	mov    %esi,%ebx
f01030d6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030d9:	89 f2                	mov    %esi,%edx
f01030db:	eb 0f                	jmp    f01030ec <strncpy+0x23>
		*dst++ = *src;
f01030dd:	83 c2 01             	add    $0x1,%edx
f01030e0:	0f b6 01             	movzbl (%ecx),%eax
f01030e3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030e6:	80 39 01             	cmpb   $0x1,(%ecx)
f01030e9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030ec:	39 da                	cmp    %ebx,%edx
f01030ee:	75 ed                	jne    f01030dd <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030f0:	89 f0                	mov    %esi,%eax
f01030f2:	5b                   	pop    %ebx
f01030f3:	5e                   	pop    %esi
f01030f4:	5d                   	pop    %ebp
f01030f5:	c3                   	ret    

f01030f6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030f6:	55                   	push   %ebp
f01030f7:	89 e5                	mov    %esp,%ebp
f01030f9:	56                   	push   %esi
f01030fa:	53                   	push   %ebx
f01030fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01030fe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103101:	8b 55 10             	mov    0x10(%ebp),%edx
f0103104:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103106:	85 d2                	test   %edx,%edx
f0103108:	74 21                	je     f010312b <strlcpy+0x35>
f010310a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010310e:	89 f2                	mov    %esi,%edx
f0103110:	eb 09                	jmp    f010311b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103112:	83 c2 01             	add    $0x1,%edx
f0103115:	83 c1 01             	add    $0x1,%ecx
f0103118:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010311b:	39 c2                	cmp    %eax,%edx
f010311d:	74 09                	je     f0103128 <strlcpy+0x32>
f010311f:	0f b6 19             	movzbl (%ecx),%ebx
f0103122:	84 db                	test   %bl,%bl
f0103124:	75 ec                	jne    f0103112 <strlcpy+0x1c>
f0103126:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103128:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010312b:	29 f0                	sub    %esi,%eax
}
f010312d:	5b                   	pop    %ebx
f010312e:	5e                   	pop    %esi
f010312f:	5d                   	pop    %ebp
f0103130:	c3                   	ret    

f0103131 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103131:	55                   	push   %ebp
f0103132:	89 e5                	mov    %esp,%ebp
f0103134:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103137:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010313a:	eb 06                	jmp    f0103142 <strcmp+0x11>
		p++, q++;
f010313c:	83 c1 01             	add    $0x1,%ecx
f010313f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103142:	0f b6 01             	movzbl (%ecx),%eax
f0103145:	84 c0                	test   %al,%al
f0103147:	74 04                	je     f010314d <strcmp+0x1c>
f0103149:	3a 02                	cmp    (%edx),%al
f010314b:	74 ef                	je     f010313c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010314d:	0f b6 c0             	movzbl %al,%eax
f0103150:	0f b6 12             	movzbl (%edx),%edx
f0103153:	29 d0                	sub    %edx,%eax
}
f0103155:	5d                   	pop    %ebp
f0103156:	c3                   	ret    

f0103157 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103157:	55                   	push   %ebp
f0103158:	89 e5                	mov    %esp,%ebp
f010315a:	53                   	push   %ebx
f010315b:	8b 45 08             	mov    0x8(%ebp),%eax
f010315e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103161:	89 c3                	mov    %eax,%ebx
f0103163:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103166:	eb 06                	jmp    f010316e <strncmp+0x17>
		n--, p++, q++;
f0103168:	83 c0 01             	add    $0x1,%eax
f010316b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010316e:	39 d8                	cmp    %ebx,%eax
f0103170:	74 15                	je     f0103187 <strncmp+0x30>
f0103172:	0f b6 08             	movzbl (%eax),%ecx
f0103175:	84 c9                	test   %cl,%cl
f0103177:	74 04                	je     f010317d <strncmp+0x26>
f0103179:	3a 0a                	cmp    (%edx),%cl
f010317b:	74 eb                	je     f0103168 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010317d:	0f b6 00             	movzbl (%eax),%eax
f0103180:	0f b6 12             	movzbl (%edx),%edx
f0103183:	29 d0                	sub    %edx,%eax
f0103185:	eb 05                	jmp    f010318c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103187:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010318c:	5b                   	pop    %ebx
f010318d:	5d                   	pop    %ebp
f010318e:	c3                   	ret    

f010318f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010318f:	55                   	push   %ebp
f0103190:	89 e5                	mov    %esp,%ebp
f0103192:	8b 45 08             	mov    0x8(%ebp),%eax
f0103195:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103199:	eb 07                	jmp    f01031a2 <strchr+0x13>
		if (*s == c)
f010319b:	38 ca                	cmp    %cl,%dl
f010319d:	74 0f                	je     f01031ae <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010319f:	83 c0 01             	add    $0x1,%eax
f01031a2:	0f b6 10             	movzbl (%eax),%edx
f01031a5:	84 d2                	test   %dl,%dl
f01031a7:	75 f2                	jne    f010319b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031a9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031ae:	5d                   	pop    %ebp
f01031af:	c3                   	ret    

f01031b0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01031b0:	55                   	push   %ebp
f01031b1:	89 e5                	mov    %esp,%ebp
f01031b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031ba:	eb 03                	jmp    f01031bf <strfind+0xf>
f01031bc:	83 c0 01             	add    $0x1,%eax
f01031bf:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031c2:	38 ca                	cmp    %cl,%dl
f01031c4:	74 04                	je     f01031ca <strfind+0x1a>
f01031c6:	84 d2                	test   %dl,%dl
f01031c8:	75 f2                	jne    f01031bc <strfind+0xc>
			break;
	return (char *) s;
}
f01031ca:	5d                   	pop    %ebp
f01031cb:	c3                   	ret    

f01031cc <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031cc:	55                   	push   %ebp
f01031cd:	89 e5                	mov    %esp,%ebp
f01031cf:	57                   	push   %edi
f01031d0:	56                   	push   %esi
f01031d1:	53                   	push   %ebx
f01031d2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031d8:	85 c9                	test   %ecx,%ecx
f01031da:	74 36                	je     f0103212 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031dc:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031e2:	75 28                	jne    f010320c <memset+0x40>
f01031e4:	f6 c1 03             	test   $0x3,%cl
f01031e7:	75 23                	jne    f010320c <memset+0x40>
		c &= 0xFF;
f01031e9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031ed:	89 d3                	mov    %edx,%ebx
f01031ef:	c1 e3 08             	shl    $0x8,%ebx
f01031f2:	89 d6                	mov    %edx,%esi
f01031f4:	c1 e6 18             	shl    $0x18,%esi
f01031f7:	89 d0                	mov    %edx,%eax
f01031f9:	c1 e0 10             	shl    $0x10,%eax
f01031fc:	09 f0                	or     %esi,%eax
f01031fe:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103200:	89 d8                	mov    %ebx,%eax
f0103202:	09 d0                	or     %edx,%eax
f0103204:	c1 e9 02             	shr    $0x2,%ecx
f0103207:	fc                   	cld    
f0103208:	f3 ab                	rep stos %eax,%es:(%edi)
f010320a:	eb 06                	jmp    f0103212 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010320c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010320f:	fc                   	cld    
f0103210:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103212:	89 f8                	mov    %edi,%eax
f0103214:	5b                   	pop    %ebx
f0103215:	5e                   	pop    %esi
f0103216:	5f                   	pop    %edi
f0103217:	5d                   	pop    %ebp
f0103218:	c3                   	ret    

f0103219 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103219:	55                   	push   %ebp
f010321a:	89 e5                	mov    %esp,%ebp
f010321c:	57                   	push   %edi
f010321d:	56                   	push   %esi
f010321e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103221:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103224:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103227:	39 c6                	cmp    %eax,%esi
f0103229:	73 35                	jae    f0103260 <memmove+0x47>
f010322b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010322e:	39 d0                	cmp    %edx,%eax
f0103230:	73 2e                	jae    f0103260 <memmove+0x47>
		s += n;
		d += n;
f0103232:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103235:	89 d6                	mov    %edx,%esi
f0103237:	09 fe                	or     %edi,%esi
f0103239:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010323f:	75 13                	jne    f0103254 <memmove+0x3b>
f0103241:	f6 c1 03             	test   $0x3,%cl
f0103244:	75 0e                	jne    f0103254 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103246:	83 ef 04             	sub    $0x4,%edi
f0103249:	8d 72 fc             	lea    -0x4(%edx),%esi
f010324c:	c1 e9 02             	shr    $0x2,%ecx
f010324f:	fd                   	std    
f0103250:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103252:	eb 09                	jmp    f010325d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103254:	83 ef 01             	sub    $0x1,%edi
f0103257:	8d 72 ff             	lea    -0x1(%edx),%esi
f010325a:	fd                   	std    
f010325b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010325d:	fc                   	cld    
f010325e:	eb 1d                	jmp    f010327d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103260:	89 f2                	mov    %esi,%edx
f0103262:	09 c2                	or     %eax,%edx
f0103264:	f6 c2 03             	test   $0x3,%dl
f0103267:	75 0f                	jne    f0103278 <memmove+0x5f>
f0103269:	f6 c1 03             	test   $0x3,%cl
f010326c:	75 0a                	jne    f0103278 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010326e:	c1 e9 02             	shr    $0x2,%ecx
f0103271:	89 c7                	mov    %eax,%edi
f0103273:	fc                   	cld    
f0103274:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103276:	eb 05                	jmp    f010327d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103278:	89 c7                	mov    %eax,%edi
f010327a:	fc                   	cld    
f010327b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010327d:	5e                   	pop    %esi
f010327e:	5f                   	pop    %edi
f010327f:	5d                   	pop    %ebp
f0103280:	c3                   	ret    

f0103281 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103281:	55                   	push   %ebp
f0103282:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103284:	ff 75 10             	pushl  0x10(%ebp)
f0103287:	ff 75 0c             	pushl  0xc(%ebp)
f010328a:	ff 75 08             	pushl  0x8(%ebp)
f010328d:	e8 87 ff ff ff       	call   f0103219 <memmove>
}
f0103292:	c9                   	leave  
f0103293:	c3                   	ret    

f0103294 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103294:	55                   	push   %ebp
f0103295:	89 e5                	mov    %esp,%ebp
f0103297:	56                   	push   %esi
f0103298:	53                   	push   %ebx
f0103299:	8b 45 08             	mov    0x8(%ebp),%eax
f010329c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010329f:	89 c6                	mov    %eax,%esi
f01032a1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032a4:	eb 1a                	jmp    f01032c0 <memcmp+0x2c>
		if (*s1 != *s2)
f01032a6:	0f b6 08             	movzbl (%eax),%ecx
f01032a9:	0f b6 1a             	movzbl (%edx),%ebx
f01032ac:	38 d9                	cmp    %bl,%cl
f01032ae:	74 0a                	je     f01032ba <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01032b0:	0f b6 c1             	movzbl %cl,%eax
f01032b3:	0f b6 db             	movzbl %bl,%ebx
f01032b6:	29 d8                	sub    %ebx,%eax
f01032b8:	eb 0f                	jmp    f01032c9 <memcmp+0x35>
		s1++, s2++;
f01032ba:	83 c0 01             	add    $0x1,%eax
f01032bd:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032c0:	39 f0                	cmp    %esi,%eax
f01032c2:	75 e2                	jne    f01032a6 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032c9:	5b                   	pop    %ebx
f01032ca:	5e                   	pop    %esi
f01032cb:	5d                   	pop    %ebp
f01032cc:	c3                   	ret    

f01032cd <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032cd:	55                   	push   %ebp
f01032ce:	89 e5                	mov    %esp,%ebp
f01032d0:	53                   	push   %ebx
f01032d1:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032d4:	89 c1                	mov    %eax,%ecx
f01032d6:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032d9:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032dd:	eb 0a                	jmp    f01032e9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032df:	0f b6 10             	movzbl (%eax),%edx
f01032e2:	39 da                	cmp    %ebx,%edx
f01032e4:	74 07                	je     f01032ed <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032e6:	83 c0 01             	add    $0x1,%eax
f01032e9:	39 c8                	cmp    %ecx,%eax
f01032eb:	72 f2                	jb     f01032df <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032ed:	5b                   	pop    %ebx
f01032ee:	5d                   	pop    %ebp
f01032ef:	c3                   	ret    

f01032f0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032f0:	55                   	push   %ebp
f01032f1:	89 e5                	mov    %esp,%ebp
f01032f3:	57                   	push   %edi
f01032f4:	56                   	push   %esi
f01032f5:	53                   	push   %ebx
f01032f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032f9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032fc:	eb 03                	jmp    f0103301 <strtol+0x11>
		s++;
f01032fe:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103301:	0f b6 01             	movzbl (%ecx),%eax
f0103304:	3c 20                	cmp    $0x20,%al
f0103306:	74 f6                	je     f01032fe <strtol+0xe>
f0103308:	3c 09                	cmp    $0x9,%al
f010330a:	74 f2                	je     f01032fe <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010330c:	3c 2b                	cmp    $0x2b,%al
f010330e:	75 0a                	jne    f010331a <strtol+0x2a>
		s++;
f0103310:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103313:	bf 00 00 00 00       	mov    $0x0,%edi
f0103318:	eb 11                	jmp    f010332b <strtol+0x3b>
f010331a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010331f:	3c 2d                	cmp    $0x2d,%al
f0103321:	75 08                	jne    f010332b <strtol+0x3b>
		s++, neg = 1;
f0103323:	83 c1 01             	add    $0x1,%ecx
f0103326:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010332b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103331:	75 15                	jne    f0103348 <strtol+0x58>
f0103333:	80 39 30             	cmpb   $0x30,(%ecx)
f0103336:	75 10                	jne    f0103348 <strtol+0x58>
f0103338:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010333c:	75 7c                	jne    f01033ba <strtol+0xca>
		s += 2, base = 16;
f010333e:	83 c1 02             	add    $0x2,%ecx
f0103341:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103346:	eb 16                	jmp    f010335e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103348:	85 db                	test   %ebx,%ebx
f010334a:	75 12                	jne    f010335e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010334c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103351:	80 39 30             	cmpb   $0x30,(%ecx)
f0103354:	75 08                	jne    f010335e <strtol+0x6e>
		s++, base = 8;
f0103356:	83 c1 01             	add    $0x1,%ecx
f0103359:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010335e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103363:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103366:	0f b6 11             	movzbl (%ecx),%edx
f0103369:	8d 72 d0             	lea    -0x30(%edx),%esi
f010336c:	89 f3                	mov    %esi,%ebx
f010336e:	80 fb 09             	cmp    $0x9,%bl
f0103371:	77 08                	ja     f010337b <strtol+0x8b>
			dig = *s - '0';
f0103373:	0f be d2             	movsbl %dl,%edx
f0103376:	83 ea 30             	sub    $0x30,%edx
f0103379:	eb 22                	jmp    f010339d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010337b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010337e:	89 f3                	mov    %esi,%ebx
f0103380:	80 fb 19             	cmp    $0x19,%bl
f0103383:	77 08                	ja     f010338d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103385:	0f be d2             	movsbl %dl,%edx
f0103388:	83 ea 57             	sub    $0x57,%edx
f010338b:	eb 10                	jmp    f010339d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010338d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103390:	89 f3                	mov    %esi,%ebx
f0103392:	80 fb 19             	cmp    $0x19,%bl
f0103395:	77 16                	ja     f01033ad <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103397:	0f be d2             	movsbl %dl,%edx
f010339a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010339d:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033a0:	7d 0b                	jge    f01033ad <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01033a2:	83 c1 01             	add    $0x1,%ecx
f01033a5:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033a9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01033ab:	eb b9                	jmp    f0103366 <strtol+0x76>

	if (endptr)
f01033ad:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033b1:	74 0d                	je     f01033c0 <strtol+0xd0>
		*endptr = (char *) s;
f01033b3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033b6:	89 0e                	mov    %ecx,(%esi)
f01033b8:	eb 06                	jmp    f01033c0 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033ba:	85 db                	test   %ebx,%ebx
f01033bc:	74 98                	je     f0103356 <strtol+0x66>
f01033be:	eb 9e                	jmp    f010335e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033c0:	89 c2                	mov    %eax,%edx
f01033c2:	f7 da                	neg    %edx
f01033c4:	85 ff                	test   %edi,%edi
f01033c6:	0f 45 c2             	cmovne %edx,%eax
}
f01033c9:	5b                   	pop    %ebx
f01033ca:	5e                   	pop    %esi
f01033cb:	5f                   	pop    %edi
f01033cc:	5d                   	pop    %ebp
f01033cd:	c3                   	ret    
f01033ce:	66 90                	xchg   %ax,%ax

f01033d0 <__udivdi3>:
f01033d0:	55                   	push   %ebp
f01033d1:	57                   	push   %edi
f01033d2:	56                   	push   %esi
f01033d3:	53                   	push   %ebx
f01033d4:	83 ec 1c             	sub    $0x1c,%esp
f01033d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033e7:	85 f6                	test   %esi,%esi
f01033e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033ed:	89 ca                	mov    %ecx,%edx
f01033ef:	89 f8                	mov    %edi,%eax
f01033f1:	75 3d                	jne    f0103430 <__udivdi3+0x60>
f01033f3:	39 cf                	cmp    %ecx,%edi
f01033f5:	0f 87 c5 00 00 00    	ja     f01034c0 <__udivdi3+0xf0>
f01033fb:	85 ff                	test   %edi,%edi
f01033fd:	89 fd                	mov    %edi,%ebp
f01033ff:	75 0b                	jne    f010340c <__udivdi3+0x3c>
f0103401:	b8 01 00 00 00       	mov    $0x1,%eax
f0103406:	31 d2                	xor    %edx,%edx
f0103408:	f7 f7                	div    %edi
f010340a:	89 c5                	mov    %eax,%ebp
f010340c:	89 c8                	mov    %ecx,%eax
f010340e:	31 d2                	xor    %edx,%edx
f0103410:	f7 f5                	div    %ebp
f0103412:	89 c1                	mov    %eax,%ecx
f0103414:	89 d8                	mov    %ebx,%eax
f0103416:	89 cf                	mov    %ecx,%edi
f0103418:	f7 f5                	div    %ebp
f010341a:	89 c3                	mov    %eax,%ebx
f010341c:	89 d8                	mov    %ebx,%eax
f010341e:	89 fa                	mov    %edi,%edx
f0103420:	83 c4 1c             	add    $0x1c,%esp
f0103423:	5b                   	pop    %ebx
f0103424:	5e                   	pop    %esi
f0103425:	5f                   	pop    %edi
f0103426:	5d                   	pop    %ebp
f0103427:	c3                   	ret    
f0103428:	90                   	nop
f0103429:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103430:	39 ce                	cmp    %ecx,%esi
f0103432:	77 74                	ja     f01034a8 <__udivdi3+0xd8>
f0103434:	0f bd fe             	bsr    %esi,%edi
f0103437:	83 f7 1f             	xor    $0x1f,%edi
f010343a:	0f 84 98 00 00 00    	je     f01034d8 <__udivdi3+0x108>
f0103440:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103445:	89 f9                	mov    %edi,%ecx
f0103447:	89 c5                	mov    %eax,%ebp
f0103449:	29 fb                	sub    %edi,%ebx
f010344b:	d3 e6                	shl    %cl,%esi
f010344d:	89 d9                	mov    %ebx,%ecx
f010344f:	d3 ed                	shr    %cl,%ebp
f0103451:	89 f9                	mov    %edi,%ecx
f0103453:	d3 e0                	shl    %cl,%eax
f0103455:	09 ee                	or     %ebp,%esi
f0103457:	89 d9                	mov    %ebx,%ecx
f0103459:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010345d:	89 d5                	mov    %edx,%ebp
f010345f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103463:	d3 ed                	shr    %cl,%ebp
f0103465:	89 f9                	mov    %edi,%ecx
f0103467:	d3 e2                	shl    %cl,%edx
f0103469:	89 d9                	mov    %ebx,%ecx
f010346b:	d3 e8                	shr    %cl,%eax
f010346d:	09 c2                	or     %eax,%edx
f010346f:	89 d0                	mov    %edx,%eax
f0103471:	89 ea                	mov    %ebp,%edx
f0103473:	f7 f6                	div    %esi
f0103475:	89 d5                	mov    %edx,%ebp
f0103477:	89 c3                	mov    %eax,%ebx
f0103479:	f7 64 24 0c          	mull   0xc(%esp)
f010347d:	39 d5                	cmp    %edx,%ebp
f010347f:	72 10                	jb     f0103491 <__udivdi3+0xc1>
f0103481:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103485:	89 f9                	mov    %edi,%ecx
f0103487:	d3 e6                	shl    %cl,%esi
f0103489:	39 c6                	cmp    %eax,%esi
f010348b:	73 07                	jae    f0103494 <__udivdi3+0xc4>
f010348d:	39 d5                	cmp    %edx,%ebp
f010348f:	75 03                	jne    f0103494 <__udivdi3+0xc4>
f0103491:	83 eb 01             	sub    $0x1,%ebx
f0103494:	31 ff                	xor    %edi,%edi
f0103496:	89 d8                	mov    %ebx,%eax
f0103498:	89 fa                	mov    %edi,%edx
f010349a:	83 c4 1c             	add    $0x1c,%esp
f010349d:	5b                   	pop    %ebx
f010349e:	5e                   	pop    %esi
f010349f:	5f                   	pop    %edi
f01034a0:	5d                   	pop    %ebp
f01034a1:	c3                   	ret    
f01034a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034a8:	31 ff                	xor    %edi,%edi
f01034aa:	31 db                	xor    %ebx,%ebx
f01034ac:	89 d8                	mov    %ebx,%eax
f01034ae:	89 fa                	mov    %edi,%edx
f01034b0:	83 c4 1c             	add    $0x1c,%esp
f01034b3:	5b                   	pop    %ebx
f01034b4:	5e                   	pop    %esi
f01034b5:	5f                   	pop    %edi
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    
f01034b8:	90                   	nop
f01034b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034c0:	89 d8                	mov    %ebx,%eax
f01034c2:	f7 f7                	div    %edi
f01034c4:	31 ff                	xor    %edi,%edi
f01034c6:	89 c3                	mov    %eax,%ebx
f01034c8:	89 d8                	mov    %ebx,%eax
f01034ca:	89 fa                	mov    %edi,%edx
f01034cc:	83 c4 1c             	add    $0x1c,%esp
f01034cf:	5b                   	pop    %ebx
f01034d0:	5e                   	pop    %esi
f01034d1:	5f                   	pop    %edi
f01034d2:	5d                   	pop    %ebp
f01034d3:	c3                   	ret    
f01034d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034d8:	39 ce                	cmp    %ecx,%esi
f01034da:	72 0c                	jb     f01034e8 <__udivdi3+0x118>
f01034dc:	31 db                	xor    %ebx,%ebx
f01034de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034e2:	0f 87 34 ff ff ff    	ja     f010341c <__udivdi3+0x4c>
f01034e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034ed:	e9 2a ff ff ff       	jmp    f010341c <__udivdi3+0x4c>
f01034f2:	66 90                	xchg   %ax,%ax
f01034f4:	66 90                	xchg   %ax,%ax
f01034f6:	66 90                	xchg   %ax,%ax
f01034f8:	66 90                	xchg   %ax,%ax
f01034fa:	66 90                	xchg   %ax,%ax
f01034fc:	66 90                	xchg   %ax,%ax
f01034fe:	66 90                	xchg   %ax,%ax

f0103500 <__umoddi3>:
f0103500:	55                   	push   %ebp
f0103501:	57                   	push   %edi
f0103502:	56                   	push   %esi
f0103503:	53                   	push   %ebx
f0103504:	83 ec 1c             	sub    $0x1c,%esp
f0103507:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010350b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010350f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103513:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103517:	85 d2                	test   %edx,%edx
f0103519:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010351d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103521:	89 f3                	mov    %esi,%ebx
f0103523:	89 3c 24             	mov    %edi,(%esp)
f0103526:	89 74 24 04          	mov    %esi,0x4(%esp)
f010352a:	75 1c                	jne    f0103548 <__umoddi3+0x48>
f010352c:	39 f7                	cmp    %esi,%edi
f010352e:	76 50                	jbe    f0103580 <__umoddi3+0x80>
f0103530:	89 c8                	mov    %ecx,%eax
f0103532:	89 f2                	mov    %esi,%edx
f0103534:	f7 f7                	div    %edi
f0103536:	89 d0                	mov    %edx,%eax
f0103538:	31 d2                	xor    %edx,%edx
f010353a:	83 c4 1c             	add    $0x1c,%esp
f010353d:	5b                   	pop    %ebx
f010353e:	5e                   	pop    %esi
f010353f:	5f                   	pop    %edi
f0103540:	5d                   	pop    %ebp
f0103541:	c3                   	ret    
f0103542:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103548:	39 f2                	cmp    %esi,%edx
f010354a:	89 d0                	mov    %edx,%eax
f010354c:	77 52                	ja     f01035a0 <__umoddi3+0xa0>
f010354e:	0f bd ea             	bsr    %edx,%ebp
f0103551:	83 f5 1f             	xor    $0x1f,%ebp
f0103554:	75 5a                	jne    f01035b0 <__umoddi3+0xb0>
f0103556:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010355a:	0f 82 e0 00 00 00    	jb     f0103640 <__umoddi3+0x140>
f0103560:	39 0c 24             	cmp    %ecx,(%esp)
f0103563:	0f 86 d7 00 00 00    	jbe    f0103640 <__umoddi3+0x140>
f0103569:	8b 44 24 08          	mov    0x8(%esp),%eax
f010356d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103571:	83 c4 1c             	add    $0x1c,%esp
f0103574:	5b                   	pop    %ebx
f0103575:	5e                   	pop    %esi
f0103576:	5f                   	pop    %edi
f0103577:	5d                   	pop    %ebp
f0103578:	c3                   	ret    
f0103579:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103580:	85 ff                	test   %edi,%edi
f0103582:	89 fd                	mov    %edi,%ebp
f0103584:	75 0b                	jne    f0103591 <__umoddi3+0x91>
f0103586:	b8 01 00 00 00       	mov    $0x1,%eax
f010358b:	31 d2                	xor    %edx,%edx
f010358d:	f7 f7                	div    %edi
f010358f:	89 c5                	mov    %eax,%ebp
f0103591:	89 f0                	mov    %esi,%eax
f0103593:	31 d2                	xor    %edx,%edx
f0103595:	f7 f5                	div    %ebp
f0103597:	89 c8                	mov    %ecx,%eax
f0103599:	f7 f5                	div    %ebp
f010359b:	89 d0                	mov    %edx,%eax
f010359d:	eb 99                	jmp    f0103538 <__umoddi3+0x38>
f010359f:	90                   	nop
f01035a0:	89 c8                	mov    %ecx,%eax
f01035a2:	89 f2                	mov    %esi,%edx
f01035a4:	83 c4 1c             	add    $0x1c,%esp
f01035a7:	5b                   	pop    %ebx
f01035a8:	5e                   	pop    %esi
f01035a9:	5f                   	pop    %edi
f01035aa:	5d                   	pop    %ebp
f01035ab:	c3                   	ret    
f01035ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035b0:	8b 34 24             	mov    (%esp),%esi
f01035b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035b8:	89 e9                	mov    %ebp,%ecx
f01035ba:	29 ef                	sub    %ebp,%edi
f01035bc:	d3 e0                	shl    %cl,%eax
f01035be:	89 f9                	mov    %edi,%ecx
f01035c0:	89 f2                	mov    %esi,%edx
f01035c2:	d3 ea                	shr    %cl,%edx
f01035c4:	89 e9                	mov    %ebp,%ecx
f01035c6:	09 c2                	or     %eax,%edx
f01035c8:	89 d8                	mov    %ebx,%eax
f01035ca:	89 14 24             	mov    %edx,(%esp)
f01035cd:	89 f2                	mov    %esi,%edx
f01035cf:	d3 e2                	shl    %cl,%edx
f01035d1:	89 f9                	mov    %edi,%ecx
f01035d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035db:	d3 e8                	shr    %cl,%eax
f01035dd:	89 e9                	mov    %ebp,%ecx
f01035df:	89 c6                	mov    %eax,%esi
f01035e1:	d3 e3                	shl    %cl,%ebx
f01035e3:	89 f9                	mov    %edi,%ecx
f01035e5:	89 d0                	mov    %edx,%eax
f01035e7:	d3 e8                	shr    %cl,%eax
f01035e9:	89 e9                	mov    %ebp,%ecx
f01035eb:	09 d8                	or     %ebx,%eax
f01035ed:	89 d3                	mov    %edx,%ebx
f01035ef:	89 f2                	mov    %esi,%edx
f01035f1:	f7 34 24             	divl   (%esp)
f01035f4:	89 d6                	mov    %edx,%esi
f01035f6:	d3 e3                	shl    %cl,%ebx
f01035f8:	f7 64 24 04          	mull   0x4(%esp)
f01035fc:	39 d6                	cmp    %edx,%esi
f01035fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103602:	89 d1                	mov    %edx,%ecx
f0103604:	89 c3                	mov    %eax,%ebx
f0103606:	72 08                	jb     f0103610 <__umoddi3+0x110>
f0103608:	75 11                	jne    f010361b <__umoddi3+0x11b>
f010360a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010360e:	73 0b                	jae    f010361b <__umoddi3+0x11b>
f0103610:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103614:	1b 14 24             	sbb    (%esp),%edx
f0103617:	89 d1                	mov    %edx,%ecx
f0103619:	89 c3                	mov    %eax,%ebx
f010361b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010361f:	29 da                	sub    %ebx,%edx
f0103621:	19 ce                	sbb    %ecx,%esi
f0103623:	89 f9                	mov    %edi,%ecx
f0103625:	89 f0                	mov    %esi,%eax
f0103627:	d3 e0                	shl    %cl,%eax
f0103629:	89 e9                	mov    %ebp,%ecx
f010362b:	d3 ea                	shr    %cl,%edx
f010362d:	89 e9                	mov    %ebp,%ecx
f010362f:	d3 ee                	shr    %cl,%esi
f0103631:	09 d0                	or     %edx,%eax
f0103633:	89 f2                	mov    %esi,%edx
f0103635:	83 c4 1c             	add    $0x1c,%esp
f0103638:	5b                   	pop    %ebx
f0103639:	5e                   	pop    %esi
f010363a:	5f                   	pop    %edi
f010363b:	5d                   	pop    %ebp
f010363c:	c3                   	ret    
f010363d:	8d 76 00             	lea    0x0(%esi),%esi
f0103640:	29 f9                	sub    %edi,%ecx
f0103642:	19 d6                	sbb    %edx,%esi
f0103644:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103648:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010364c:	e9 18 ff ff ff       	jmp    f0103569 <__umoddi3+0x69>
