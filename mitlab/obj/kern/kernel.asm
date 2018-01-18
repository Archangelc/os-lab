
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 50 dc 17 f0       	mov    $0xf017dc50,%eax
f010004b:	2d 26 cd 17 f0       	sub    $0xf017cd26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 cd 17 f0       	push   $0xf017cd26
f0100058:	e8 62 42 00 00       	call   f01042bf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 9d 04 00 00       	call   f01004ff <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 47 10 f0       	push   $0xf0104760
f010006f:	e8 ba 2e 00 00       	call   f0102f2e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 8b 0f 00 00       	call   f0101004 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 f0 28 00 00       	call   f010296e <env_init>
	trap_init();
f010007e:	e8 1c 2f 00 00       	call   f0102f9f <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 56 b3 11 f0       	push   $0xf011b356
f010008d:	e8 a7 2a 00 00       	call   f0102b39 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 8c cf 17 f0    	pushl  0xf017cf8c
f010009b:	e8 c5 2d 00 00       	call   f0102e65 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 dc 17 f0 00 	cmpl   $0x0,0xf017dc40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 dc 17 f0    	mov    %esi,0xf017dc40

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 7b 47 10 f0       	push   $0xf010477b
f01000ca:	e8 5f 2e 00 00       	call   f0102f2e <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 2f 2e 00 00       	call   f0102f08 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 dd 56 10 f0 	movl   $0xf01056dd,(%esp)
f01000e0:	e8 49 2e 00 00       	call   f0102f2e <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 a2 06 00 00       	call   f0100794 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 93 47 10 f0       	push   $0xf0104793
f010010c:	e8 1d 2e 00 00       	call   f0102f2e <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 eb 2d 00 00       	call   f0102f08 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 dd 56 10 f0 	movl   $0xf01056dd,(%esp)
f0100124:	e8 05 2e 00 00       	call   f0102f2e <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 cf 17 f0    	mov    0xf017cf64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 cf 17 f0    	mov    %edx,0xf017cf64
f010016e:	88 81 60 cd 17 f0    	mov    %al,-0xfe832a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 cf 17 f0 00 	movl   $0x0,0xf017cf64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 40 cd 17 f0 40 	orl    $0x40,0xf017cd40
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 40 cd 17 f0    	mov    0xf017cd40,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 00 49 10 f0 	movzbl -0xfefb700(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 40 cd 17 f0       	mov    %eax,0xf017cd40
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 40 cd 17 f0    	mov    0xf017cd40,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 40 cd 17 f0    	mov    %ecx,0xf017cd40
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 00 49 10 f0 	movzbl -0xfefb700(%edx),%eax
f010021e:	0b 05 40 cd 17 f0    	or     0xf017cd40,%eax
f0100224:	0f b6 8a 00 48 10 f0 	movzbl -0xfefb800(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 40 cd 17 f0       	mov    %eax,0xf017cd40

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d e0 47 10 f0 	mov    -0xfefb820(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 ad 47 10 f0       	push   $0xf01047ad
f010027a:	e8 af 2c 00 00       	call   f0102f2e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100321:	89 fa                	mov    %edi,%edx
f0100323:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100329:	89 f8                	mov    %edi,%eax
f010032b:	80 cc 07             	or     $0x7,%ah
f010032e:	85 d2                	test   %edx,%edx
f0100330:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100333:	89 f8                	mov    %edi,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	83 f8 09             	cmp    $0x9,%eax
f010033b:	74 74                	je     f01003b1 <cons_putc+0x113>
f010033d:	83 f8 09             	cmp    $0x9,%eax
f0100340:	7f 0a                	jg     f010034c <cons_putc+0xae>
f0100342:	83 f8 08             	cmp    $0x8,%eax
f0100345:	74 14                	je     f010035b <cons_putc+0xbd>
f0100347:	e9 99 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
f010034c:	83 f8 0a             	cmp    $0xa,%eax
f010034f:	74 3a                	je     f010038b <cons_putc+0xed>
f0100351:	83 f8 0d             	cmp    $0xd,%eax
f0100354:	74 3d                	je     f0100393 <cons_putc+0xf5>
f0100356:	e9 8a 00 00 00       	jmp    f01003e5 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010035b:	0f b7 05 68 cf 17 f0 	movzwl 0xf017cf68,%eax
f0100362:	66 85 c0             	test   %ax,%ax
f0100365:	0f 84 e6 00 00 00    	je     f0100451 <cons_putc+0x1b3>
			crt_pos--;
f010036b:	83 e8 01             	sub    $0x1,%eax
f010036e:	66 a3 68 cf 17 f0    	mov    %ax,0xf017cf68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100374:	0f b7 c0             	movzwl %ax,%eax
f0100377:	66 81 e7 00 ff       	and    $0xff00,%di
f010037c:	83 cf 20             	or     $0x20,%edi
f010037f:	8b 15 6c cf 17 f0    	mov    0xf017cf6c,%edx
f0100385:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100389:	eb 78                	jmp    f0100403 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010038b:	66 83 05 68 cf 17 f0 	addw   $0x50,0xf017cf68
f0100392:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100393:	0f b7 05 68 cf 17 f0 	movzwl 0xf017cf68,%eax
f010039a:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a0:	c1 e8 16             	shr    $0x16,%eax
f01003a3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003a6:	c1 e0 04             	shl    $0x4,%eax
f01003a9:	66 a3 68 cf 17 f0    	mov    %ax,0xf017cf68
f01003af:	eb 52                	jmp    f0100403 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b6:	e8 e3 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003bb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c0:	e8 d9 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003c5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ca:	e8 cf fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 c5 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 bb fe ff ff       	call   f010029e <cons_putc>
f01003e3:	eb 1e                	jmp    f0100403 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003e5:	0f b7 05 68 cf 17 f0 	movzwl 0xf017cf68,%eax
f01003ec:	8d 50 01             	lea    0x1(%eax),%edx
f01003ef:	66 89 15 68 cf 17 f0 	mov    %dx,0xf017cf68
f01003f6:	0f b7 c0             	movzwl %ax,%eax
f01003f9:	8b 15 6c cf 17 f0    	mov    0xf017cf6c,%edx
f01003ff:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100403:	66 81 3d 68 cf 17 f0 	cmpw   $0x7cf,0xf017cf68
f010040a:	cf 07 
f010040c:	76 43                	jbe    f0100451 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 6c cf 17 f0       	mov    0xf017cf6c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 e4 3e 00 00       	call   f010430c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 6c cf 17 f0    	mov    0xf017cf6c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 68 cf 17 f0 	subw   $0x50,0xf017cf68
f0100450:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100451:	8b 0d 70 cf 17 f0    	mov    0xf017cf70,%ecx
f0100457:	b8 0e 00 00 00       	mov    $0xe,%eax
f010045c:	89 ca                	mov    %ecx,%edx
f010045e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010045f:	0f b7 1d 68 cf 17 f0 	movzwl 0xf017cf68,%ebx
f0100466:	8d 71 01             	lea    0x1(%ecx),%esi
f0100469:	89 d8                	mov    %ebx,%eax
f010046b:	66 c1 e8 08          	shr    $0x8,%ax
f010046f:	89 f2                	mov    %esi,%edx
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100477:	89 ca                	mov    %ecx,%edx
f0100479:	ee                   	out    %al,(%dx)
f010047a:	89 d8                	mov    %ebx,%eax
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010047f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100482:	5b                   	pop    %ebx
f0100483:	5e                   	pop    %esi
f0100484:	5f                   	pop    %edi
f0100485:	5d                   	pop    %ebp
f0100486:	c3                   	ret    

f0100487 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100487:	80 3d 74 cf 17 f0 00 	cmpb   $0x0,0xf017cf74
f010048e:	74 11                	je     f01004a1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100490:	55                   	push   %ebp
f0100491:	89 e5                	mov    %esp,%ebp
f0100493:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100496:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f010049b:	e8 b0 fc ff ff       	call   f0100150 <cons_intr>
}
f01004a0:	c9                   	leave  
f01004a1:	f3 c3                	repz ret 

f01004a3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a3:	55                   	push   %ebp
f01004a4:	89 e5                	mov    %esp,%ebp
f01004a6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a9:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004ae:	e8 9d fc ff ff       	call   f0100150 <cons_intr>
}
f01004b3:	c9                   	leave  
f01004b4:	c3                   	ret    

f01004b5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b5:	55                   	push   %ebp
f01004b6:	89 e5                	mov    %esp,%ebp
f01004b8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bb:	e8 c7 ff ff ff       	call   f0100487 <serial_intr>
	kbd_intr();
f01004c0:	e8 de ff ff ff       	call   f01004a3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c5:	a1 60 cf 17 f0       	mov    0xf017cf60,%eax
f01004ca:	3b 05 64 cf 17 f0    	cmp    0xf017cf64,%eax
f01004d0:	74 26                	je     f01004f8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004d2:	8d 50 01             	lea    0x1(%eax),%edx
f01004d5:	89 15 60 cf 17 f0    	mov    %edx,0xf017cf60
f01004db:	0f b6 88 60 cd 17 f0 	movzbl -0xfe832a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004e2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004e4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ea:	75 11                	jne    f01004fd <cons_getc+0x48>
			cons.rpos = 0;
f01004ec:	c7 05 60 cf 17 f0 00 	movl   $0x0,0xf017cf60
f01004f3:	00 00 00 
f01004f6:	eb 05                	jmp    f01004fd <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	57                   	push   %edi
f0100503:	56                   	push   %esi
f0100504:	53                   	push   %ebx
f0100505:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100508:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100516:	5a a5 
	if (*cp != 0xA55A) {
f0100518:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100523:	74 11                	je     f0100536 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100525:	c7 05 70 cf 17 f0 b4 	movl   $0x3b4,0xf017cf70
f010052c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100534:	eb 16                	jmp    f010054c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100536:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053d:	c7 05 70 cf 17 f0 d4 	movl   $0x3d4,0xf017cf70
f0100544:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100547:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010054c:	8b 3d 70 cf 17 f0    	mov    0xf017cf70,%edi
f0100552:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100557:	89 fa                	mov    %edi,%edx
f0100559:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055a:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055d:	89 da                	mov    %ebx,%edx
f010055f:	ec                   	in     (%dx),%al
f0100560:	0f b6 c8             	movzbl %al,%ecx
f0100563:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100566:	b8 0f 00 00 00       	mov    $0xf,%eax
f010056b:	89 fa                	mov    %edi,%edx
f010056d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056e:	89 da                	mov    %ebx,%edx
f0100570:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100571:	89 35 6c cf 17 f0    	mov    %esi,0xf017cf6c
	crt_pos = pos;
f0100577:	0f b6 c0             	movzbl %al,%eax
f010057a:	09 c8                	or     %ecx,%eax
f010057c:	66 a3 68 cf 17 f0    	mov    %ax,0xf017cf68
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100582:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100587:	b8 00 00 00 00       	mov    $0x0,%eax
f010058c:	89 f2                	mov    %esi,%edx
f010058e:	ee                   	out    %al,(%dx)
f010058f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100594:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100599:	ee                   	out    %al,(%dx)
f010059a:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010059f:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a4:	89 da                	mov    %ebx,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005db:	3c ff                	cmp    $0xff,%al
f01005dd:	0f 95 05 74 cf 17 f0 	setne  0xf017cf74
f01005e4:	89 f2                	mov    %esi,%edx
f01005e6:	ec                   	in     (%dx),%al
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005ea:	80 f9 ff             	cmp    $0xff,%cl
f01005ed:	75 10                	jne    f01005ff <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005ef:	83 ec 0c             	sub    $0xc,%esp
f01005f2:	68 b9 47 10 f0       	push   $0xf01047b9
f01005f7:	e8 32 29 00 00       	call   f0102f2e <cprintf>
f01005fc:	83 c4 10             	add    $0x10,%esp
}
f01005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100607:	55                   	push   %ebp
f0100608:	89 e5                	mov    %esp,%ebp
f010060a:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010060d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100610:	e8 89 fc ff ff       	call   f010029e <cons_putc>
}
f0100615:	c9                   	leave  
f0100616:	c3                   	ret    

f0100617 <getchar>:

int
getchar(void)
{
f0100617:	55                   	push   %ebp
f0100618:	89 e5                	mov    %esp,%ebp
f010061a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010061d:	e8 93 fe ff ff       	call   f01004b5 <cons_getc>
f0100622:	85 c0                	test   %eax,%eax
f0100624:	74 f7                	je     f010061d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100626:	c9                   	leave  
f0100627:	c3                   	ret    

f0100628 <iscons>:

int
iscons(int fdnum)
{
f0100628:	55                   	push   %ebp
f0100629:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010062b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100630:	5d                   	pop    %ebp
f0100631:	c3                   	ret    

f0100632 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100638:	68 00 4a 10 f0       	push   $0xf0104a00
f010063d:	68 1e 4a 10 f0       	push   $0xf0104a1e
f0100642:	68 23 4a 10 f0       	push   $0xf0104a23
f0100647:	e8 e2 28 00 00       	call   f0102f2e <cprintf>
f010064c:	83 c4 0c             	add    $0xc,%esp
f010064f:	68 b4 4a 10 f0       	push   $0xf0104ab4
f0100654:	68 2c 4a 10 f0       	push   $0xf0104a2c
f0100659:	68 23 4a 10 f0       	push   $0xf0104a23
f010065e:	e8 cb 28 00 00       	call   f0102f2e <cprintf>
	return 0;
}
f0100663:	b8 00 00 00 00       	mov    $0x0,%eax
f0100668:	c9                   	leave  
f0100669:	c3                   	ret    

f010066a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010066a:	55                   	push   %ebp
f010066b:	89 e5                	mov    %esp,%ebp
f010066d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100670:	68 35 4a 10 f0       	push   $0xf0104a35
f0100675:	e8 b4 28 00 00       	call   f0102f2e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010067a:	83 c4 08             	add    $0x8,%esp
f010067d:	68 0c 00 10 00       	push   $0x10000c
f0100682:	68 dc 4a 10 f0       	push   $0xf0104adc
f0100687:	e8 a2 28 00 00       	call   f0102f2e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010068c:	83 c4 0c             	add    $0xc,%esp
f010068f:	68 0c 00 10 00       	push   $0x10000c
f0100694:	68 0c 00 10 f0       	push   $0xf010000c
f0100699:	68 04 4b 10 f0       	push   $0xf0104b04
f010069e:	e8 8b 28 00 00       	call   f0102f2e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 51 47 10 00       	push   $0x104751
f01006ab:	68 51 47 10 f0       	push   $0xf0104751
f01006b0:	68 28 4b 10 f0       	push   $0xf0104b28
f01006b5:	e8 74 28 00 00       	call   f0102f2e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 26 cd 17 00       	push   $0x17cd26
f01006c2:	68 26 cd 17 f0       	push   $0xf017cd26
f01006c7:	68 4c 4b 10 f0       	push   $0xf0104b4c
f01006cc:	e8 5d 28 00 00       	call   f0102f2e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006d1:	83 c4 0c             	add    $0xc,%esp
f01006d4:	68 50 dc 17 00       	push   $0x17dc50
f01006d9:	68 50 dc 17 f0       	push   $0xf017dc50
f01006de:	68 70 4b 10 f0       	push   $0xf0104b70
f01006e3:	e8 46 28 00 00       	call   f0102f2e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006e8:	b8 4f e0 17 f0       	mov    $0xf017e04f,%eax
f01006ed:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006f2:	83 c4 08             	add    $0x8,%esp
f01006f5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01006fa:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100700:	85 c0                	test   %eax,%eax
f0100702:	0f 48 c2             	cmovs  %edx,%eax
f0100705:	c1 f8 0a             	sar    $0xa,%eax
f0100708:	50                   	push   %eax
f0100709:	68 94 4b 10 f0       	push   $0xf0104b94
f010070e:	e8 1b 28 00 00       	call   f0102f2e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100713:	b8 00 00 00 00       	mov    $0x0,%eax
f0100718:	c9                   	leave  
f0100719:	c3                   	ret    

f010071a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010071a:	55                   	push   %ebp
f010071b:	89 e5                	mov    %esp,%ebp
f010071d:	56                   	push   %esi
f010071e:	53                   	push   %ebx
f010071f:	83 ec 2c             	sub    $0x2c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100722:	89 eb                	mov    %ebp,%ebx
	// Your code here.
        struct Eipdebuginfo info;
        uint32_t *ebp = (uint32_t *) read_ebp();
        cprintf("Stack backtrace:\n");
f0100724:	68 4e 4a 10 f0       	push   $0xf0104a4e
f0100729:	e8 00 28 00 00       	call   f0102f2e <cprintf>
        while (ebp) {
f010072e:	83 c4 10             	add    $0x10,%esp
            cprintf(" ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
            debuginfo_eip(ebp[1], &info);
f0100731:	8d 75 e0             	lea    -0x20(%ebp),%esi
{
	// Your code here.
        struct Eipdebuginfo info;
        uint32_t *ebp = (uint32_t *) read_ebp();
        cprintf("Stack backtrace:\n");
        while (ebp) {
f0100734:	eb 4e                	jmp    f0100784 <mon_backtrace+0x6a>
            cprintf(" ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
f0100736:	ff 73 18             	pushl  0x18(%ebx)
f0100739:	ff 73 14             	pushl  0x14(%ebx)
f010073c:	ff 73 10             	pushl  0x10(%ebx)
f010073f:	ff 73 0c             	pushl  0xc(%ebx)
f0100742:	ff 73 08             	pushl  0x8(%ebx)
f0100745:	ff 73 04             	pushl  0x4(%ebx)
f0100748:	53                   	push   %ebx
f0100749:	68 c0 4b 10 f0       	push   $0xf0104bc0
f010074e:	e8 db 27 00 00       	call   f0102f2e <cprintf>
            debuginfo_eip(ebp[1], &info);
f0100753:	83 c4 18             	add    $0x18,%esp
f0100756:	56                   	push   %esi
f0100757:	ff 73 04             	pushl  0x4(%ebx)
f010075a:	e8 58 31 00 00       	call   f01038b7 <debuginfo_eip>
            cprintf("\n    %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1]-info.eip_fn_addr);
f010075f:	83 c4 08             	add    $0x8,%esp
f0100762:	8b 43 04             	mov    0x4(%ebx),%eax
f0100765:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100768:	50                   	push   %eax
f0100769:	ff 75 e8             	pushl  -0x18(%ebp)
f010076c:	ff 75 ec             	pushl  -0x14(%ebp)
f010076f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100772:	ff 75 e0             	pushl  -0x20(%ebp)
f0100775:	68 60 4a 10 f0       	push   $0xf0104a60
f010077a:	e8 af 27 00 00       	call   f0102f2e <cprintf>
            ebp = (uint32_t *) (*ebp);
f010077f:	8b 1b                	mov    (%ebx),%ebx
f0100781:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
        struct Eipdebuginfo info;
        uint32_t *ebp = (uint32_t *) read_ebp();
        cprintf("Stack backtrace:\n");
        while (ebp) {
f0100784:	85 db                	test   %ebx,%ebx
f0100786:	75 ae                	jne    f0100736 <mon_backtrace+0x1c>
            debuginfo_eip(ebp[1], &info);
            cprintf("\n    %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1]-info.eip_fn_addr);
            ebp = (uint32_t *) (*ebp);
        }
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100790:	5b                   	pop    %ebx
f0100791:	5e                   	pop    %esi
f0100792:	5d                   	pop    %ebp
f0100793:	c3                   	ret    

f0100794 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100794:	55                   	push   %ebp
f0100795:	89 e5                	mov    %esp,%ebp
f0100797:	57                   	push   %edi
f0100798:	56                   	push   %esi
f0100799:	53                   	push   %ebx
f010079a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010079d:	68 f4 4b 10 f0       	push   $0xf0104bf4
f01007a2:	e8 87 27 00 00       	call   f0102f2e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007a7:	c7 04 24 18 4c 10 f0 	movl   $0xf0104c18,(%esp)
f01007ae:	e8 7b 27 00 00       	call   f0102f2e <cprintf>

	if (tf != NULL)
f01007b3:	83 c4 10             	add    $0x10,%esp
f01007b6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007ba:	74 0e                	je     f01007ca <monitor+0x36>
		print_trapframe(tf);
f01007bc:	83 ec 0c             	sub    $0xc,%esp
f01007bf:	ff 75 08             	pushl  0x8(%ebp)
f01007c2:	e8 a1 2b 00 00       	call   f0103368 <print_trapframe>
f01007c7:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01007ca:	83 ec 0c             	sub    $0xc,%esp
f01007cd:	68 75 4a 10 f0       	push   $0xf0104a75
f01007d2:	e8 91 38 00 00       	call   f0104068 <readline>
f01007d7:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007d9:	83 c4 10             	add    $0x10,%esp
f01007dc:	85 c0                	test   %eax,%eax
f01007de:	74 ea                	je     f01007ca <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007e0:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e7:	be 00 00 00 00       	mov    $0x0,%esi
f01007ec:	eb 0a                	jmp    f01007f8 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007ee:	c6 03 00             	movb   $0x0,(%ebx)
f01007f1:	89 f7                	mov    %esi,%edi
f01007f3:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007f6:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f8:	0f b6 03             	movzbl (%ebx),%eax
f01007fb:	84 c0                	test   %al,%al
f01007fd:	74 63                	je     f0100862 <monitor+0xce>
f01007ff:	83 ec 08             	sub    $0x8,%esp
f0100802:	0f be c0             	movsbl %al,%eax
f0100805:	50                   	push   %eax
f0100806:	68 79 4a 10 f0       	push   $0xf0104a79
f010080b:	e8 72 3a 00 00       	call   f0104282 <strchr>
f0100810:	83 c4 10             	add    $0x10,%esp
f0100813:	85 c0                	test   %eax,%eax
f0100815:	75 d7                	jne    f01007ee <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100817:	80 3b 00             	cmpb   $0x0,(%ebx)
f010081a:	74 46                	je     f0100862 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010081c:	83 fe 0f             	cmp    $0xf,%esi
f010081f:	75 14                	jne    f0100835 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100821:	83 ec 08             	sub    $0x8,%esp
f0100824:	6a 10                	push   $0x10
f0100826:	68 7e 4a 10 f0       	push   $0xf0104a7e
f010082b:	e8 fe 26 00 00       	call   f0102f2e <cprintf>
f0100830:	83 c4 10             	add    $0x10,%esp
f0100833:	eb 95                	jmp    f01007ca <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100835:	8d 7e 01             	lea    0x1(%esi),%edi
f0100838:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010083c:	eb 03                	jmp    f0100841 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010083e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100841:	0f b6 03             	movzbl (%ebx),%eax
f0100844:	84 c0                	test   %al,%al
f0100846:	74 ae                	je     f01007f6 <monitor+0x62>
f0100848:	83 ec 08             	sub    $0x8,%esp
f010084b:	0f be c0             	movsbl %al,%eax
f010084e:	50                   	push   %eax
f010084f:	68 79 4a 10 f0       	push   $0xf0104a79
f0100854:	e8 29 3a 00 00       	call   f0104282 <strchr>
f0100859:	83 c4 10             	add    $0x10,%esp
f010085c:	85 c0                	test   %eax,%eax
f010085e:	74 de                	je     f010083e <monitor+0xaa>
f0100860:	eb 94                	jmp    f01007f6 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f0100862:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100869:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010086a:	85 f6                	test   %esi,%esi
f010086c:	0f 84 58 ff ff ff    	je     f01007ca <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100872:	83 ec 08             	sub    $0x8,%esp
f0100875:	68 1e 4a 10 f0       	push   $0xf0104a1e
f010087a:	ff 75 a8             	pushl  -0x58(%ebp)
f010087d:	e8 a2 39 00 00       	call   f0104224 <strcmp>
f0100882:	83 c4 10             	add    $0x10,%esp
f0100885:	85 c0                	test   %eax,%eax
f0100887:	74 1e                	je     f01008a7 <monitor+0x113>
f0100889:	83 ec 08             	sub    $0x8,%esp
f010088c:	68 2c 4a 10 f0       	push   $0xf0104a2c
f0100891:	ff 75 a8             	pushl  -0x58(%ebp)
f0100894:	e8 8b 39 00 00       	call   f0104224 <strcmp>
f0100899:	83 c4 10             	add    $0x10,%esp
f010089c:	85 c0                	test   %eax,%eax
f010089e:	75 2f                	jne    f01008cf <monitor+0x13b>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008a0:	b8 01 00 00 00       	mov    $0x1,%eax
f01008a5:	eb 05                	jmp    f01008ac <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a7:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008ac:	83 ec 04             	sub    $0x4,%esp
f01008af:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008b2:	01 d0                	add    %edx,%eax
f01008b4:	ff 75 08             	pushl  0x8(%ebp)
f01008b7:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008ba:	51                   	push   %ecx
f01008bb:	56                   	push   %esi
f01008bc:	ff 14 85 48 4c 10 f0 	call   *-0xfefb3b8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c3:	83 c4 10             	add    $0x10,%esp
f01008c6:	85 c0                	test   %eax,%eax
f01008c8:	78 1d                	js     f01008e7 <monitor+0x153>
f01008ca:	e9 fb fe ff ff       	jmp    f01007ca <monitor+0x36>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008cf:	83 ec 08             	sub    $0x8,%esp
f01008d2:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d5:	68 9b 4a 10 f0       	push   $0xf0104a9b
f01008da:	e8 4f 26 00 00       	call   f0102f2e <cprintf>
f01008df:	83 c4 10             	add    $0x10,%esp
f01008e2:	e9 e3 fe ff ff       	jmp    f01007ca <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ea:	5b                   	pop    %ebx
f01008eb:	5e                   	pop    %esi
f01008ec:	5f                   	pop    %edi
f01008ed:	5d                   	pop    %ebp
f01008ee:	c3                   	ret    

f01008ef <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008ef:	55                   	push   %ebp
f01008f0:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008f2:	83 3d 78 cf 17 f0 00 	cmpl   $0x0,0xf017cf78
f01008f9:	75 11                	jne    f010090c <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008fb:	ba 4f ec 17 f0       	mov    $0xf017ec4f,%edx
f0100900:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100906:	89 15 78 cf 17 f0    	mov    %edx,0xf017cf78
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n==0)
f010090c:	85 c0                	test   %eax,%eax
f010090e:	75 07                	jne    f0100917 <boot_alloc+0x28>
		return nextfree;
f0100910:	a1 78 cf 17 f0       	mov    0xf017cf78,%eax
f0100915:	eb 19                	jmp    f0100930 <boot_alloc+0x41>
	result = nextfree;
f0100917:	8b 15 78 cf 17 f0    	mov    0xf017cf78,%edx
	nextfree += n;
	nextfree = ROUNDUP((char *)nextfree, PGSIZE);
f010091d:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100924:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100929:	a3 78 cf 17 f0       	mov    %eax,0xf017cf78
	return result;
f010092e:	89 d0                	mov    %edx,%eax
}
f0100930:	5d                   	pop    %ebp
f0100931:	c3                   	ret    

f0100932 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100932:	89 d1                	mov    %edx,%ecx
f0100934:	c1 e9 16             	shr    $0x16,%ecx
f0100937:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010093a:	a8 01                	test   $0x1,%al
f010093c:	74 52                	je     f0100990 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010093e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100943:	89 c1                	mov    %eax,%ecx
f0100945:	c1 e9 0c             	shr    $0xc,%ecx
f0100948:	3b 0d 44 dc 17 f0    	cmp    0xf017dc44,%ecx
f010094e:	72 1b                	jb     f010096b <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100956:	50                   	push   %eax
f0100957:	68 58 4c 10 f0       	push   $0xf0104c58
f010095c:	68 33 03 00 00       	push   $0x333
f0100961:	68 15 54 10 f0       	push   $0xf0105415
f0100966:	e8 35 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f010096b:	c1 ea 0c             	shr    $0xc,%edx
f010096e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100974:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010097b:	89 c2                	mov    %eax,%edx
f010097d:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100980:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100985:	85 d2                	test   %edx,%edx
f0100987:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010098c:	0f 44 c2             	cmove  %edx,%eax
f010098f:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100990:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100995:	c3                   	ret    

f0100996 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100996:	55                   	push   %ebp
f0100997:	89 e5                	mov    %esp,%ebp
f0100999:	57                   	push   %edi
f010099a:	56                   	push   %esi
f010099b:	53                   	push   %ebx
f010099c:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010099f:	84 c0                	test   %al,%al
f01009a1:	0f 85 72 02 00 00    	jne    f0100c19 <check_page_free_list+0x283>
f01009a7:	e9 7f 02 00 00       	jmp    f0100c2b <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009ac:	83 ec 04             	sub    $0x4,%esp
f01009af:	68 7c 4c 10 f0       	push   $0xf0104c7c
f01009b4:	68 71 02 00 00       	push   $0x271
f01009b9:	68 15 54 10 f0       	push   $0xf0105415
f01009be:	e8 dd f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009c3:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009c6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009c9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009cc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009cf:	89 c2                	mov    %eax,%edx
f01009d1:	2b 15 4c dc 17 f0    	sub    0xf017dc4c,%edx
f01009d7:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009dd:	0f 95 c2             	setne  %dl
f01009e0:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009e3:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009e7:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009e9:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009ed:	8b 00                	mov    (%eax),%eax
f01009ef:	85 c0                	test   %eax,%eax
f01009f1:	75 dc                	jne    f01009cf <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009ff:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a02:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a04:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a07:	a3 80 cf 17 f0       	mov    %eax,0xf017cf80
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a0c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a11:	8b 1d 80 cf 17 f0    	mov    0xf017cf80,%ebx
f0100a17:	eb 53                	jmp    f0100a6c <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a19:	89 d8                	mov    %ebx,%eax
f0100a1b:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f0100a21:	c1 f8 03             	sar    $0x3,%eax
f0100a24:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a27:	89 c2                	mov    %eax,%edx
f0100a29:	c1 ea 16             	shr    $0x16,%edx
f0100a2c:	39 f2                	cmp    %esi,%edx
f0100a2e:	73 3a                	jae    f0100a6a <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a30:	89 c2                	mov    %eax,%edx
f0100a32:	c1 ea 0c             	shr    $0xc,%edx
f0100a35:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f0100a3b:	72 12                	jb     f0100a4f <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a3d:	50                   	push   %eax
f0100a3e:	68 58 4c 10 f0       	push   $0xf0104c58
f0100a43:	6a 56                	push   $0x56
f0100a45:	68 21 54 10 f0       	push   $0xf0105421
f0100a4a:	e8 51 f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a4f:	83 ec 04             	sub    $0x4,%esp
f0100a52:	68 80 00 00 00       	push   $0x80
f0100a57:	68 97 00 00 00       	push   $0x97
f0100a5c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a61:	50                   	push   %eax
f0100a62:	e8 58 38 00 00       	call   f01042bf <memset>
f0100a67:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a6a:	8b 1b                	mov    (%ebx),%ebx
f0100a6c:	85 db                	test   %ebx,%ebx
f0100a6e:	75 a9                	jne    f0100a19 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a70:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a75:	e8 75 fe ff ff       	call   f01008ef <boot_alloc>
f0100a7a:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a7d:	8b 15 80 cf 17 f0    	mov    0xf017cf80,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a83:	8b 0d 4c dc 17 f0    	mov    0xf017dc4c,%ecx
		assert(pp < pages + npages);
f0100a89:	a1 44 dc 17 f0       	mov    0xf017dc44,%eax
f0100a8e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a91:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a94:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a97:	be 00 00 00 00       	mov    $0x0,%esi
f0100a9c:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a9f:	e9 30 01 00 00       	jmp    f0100bd4 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aa4:	39 ca                	cmp    %ecx,%edx
f0100aa6:	73 19                	jae    f0100ac1 <check_page_free_list+0x12b>
f0100aa8:	68 2f 54 10 f0       	push   $0xf010542f
f0100aad:	68 3b 54 10 f0       	push   $0xf010543b
f0100ab2:	68 8b 02 00 00       	push   $0x28b
f0100ab7:	68 15 54 10 f0       	push   $0xf0105415
f0100abc:	e8 df f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100ac1:	39 fa                	cmp    %edi,%edx
f0100ac3:	72 19                	jb     f0100ade <check_page_free_list+0x148>
f0100ac5:	68 50 54 10 f0       	push   $0xf0105450
f0100aca:	68 3b 54 10 f0       	push   $0xf010543b
f0100acf:	68 8c 02 00 00       	push   $0x28c
f0100ad4:	68 15 54 10 f0       	push   $0xf0105415
f0100ad9:	e8 c2 f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ade:	89 d0                	mov    %edx,%eax
f0100ae0:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100ae3:	a8 07                	test   $0x7,%al
f0100ae5:	74 19                	je     f0100b00 <check_page_free_list+0x16a>
f0100ae7:	68 a0 4c 10 f0       	push   $0xf0104ca0
f0100aec:	68 3b 54 10 f0       	push   $0xf010543b
f0100af1:	68 8d 02 00 00       	push   $0x28d
f0100af6:	68 15 54 10 f0       	push   $0xf0105415
f0100afb:	e8 a0 f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b00:	c1 f8 03             	sar    $0x3,%eax
f0100b03:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b06:	85 c0                	test   %eax,%eax
f0100b08:	75 19                	jne    f0100b23 <check_page_free_list+0x18d>
f0100b0a:	68 64 54 10 f0       	push   $0xf0105464
f0100b0f:	68 3b 54 10 f0       	push   $0xf010543b
f0100b14:	68 90 02 00 00       	push   $0x290
f0100b19:	68 15 54 10 f0       	push   $0xf0105415
f0100b1e:	e8 7d f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b23:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b28:	75 19                	jne    f0100b43 <check_page_free_list+0x1ad>
f0100b2a:	68 75 54 10 f0       	push   $0xf0105475
f0100b2f:	68 3b 54 10 f0       	push   $0xf010543b
f0100b34:	68 91 02 00 00       	push   $0x291
f0100b39:	68 15 54 10 f0       	push   $0xf0105415
f0100b3e:	e8 5d f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b43:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b48:	75 19                	jne    f0100b63 <check_page_free_list+0x1cd>
f0100b4a:	68 d4 4c 10 f0       	push   $0xf0104cd4
f0100b4f:	68 3b 54 10 f0       	push   $0xf010543b
f0100b54:	68 92 02 00 00       	push   $0x292
f0100b59:	68 15 54 10 f0       	push   $0xf0105415
f0100b5e:	e8 3d f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b63:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b68:	75 19                	jne    f0100b83 <check_page_free_list+0x1ed>
f0100b6a:	68 8e 54 10 f0       	push   $0xf010548e
f0100b6f:	68 3b 54 10 f0       	push   $0xf010543b
f0100b74:	68 93 02 00 00       	push   $0x293
f0100b79:	68 15 54 10 f0       	push   $0xf0105415
f0100b7e:	e8 1d f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b83:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b88:	76 3f                	jbe    f0100bc9 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b8a:	89 c3                	mov    %eax,%ebx
f0100b8c:	c1 eb 0c             	shr    $0xc,%ebx
f0100b8f:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b92:	77 12                	ja     f0100ba6 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b94:	50                   	push   %eax
f0100b95:	68 58 4c 10 f0       	push   $0xf0104c58
f0100b9a:	6a 56                	push   $0x56
f0100b9c:	68 21 54 10 f0       	push   $0xf0105421
f0100ba1:	e8 fa f4 ff ff       	call   f01000a0 <_panic>
f0100ba6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bab:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bae:	76 1e                	jbe    f0100bce <check_page_free_list+0x238>
f0100bb0:	68 f8 4c 10 f0       	push   $0xf0104cf8
f0100bb5:	68 3b 54 10 f0       	push   $0xf010543b
f0100bba:	68 94 02 00 00       	push   $0x294
f0100bbf:	68 15 54 10 f0       	push   $0xf0105415
f0100bc4:	e8 d7 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bc9:	83 c6 01             	add    $0x1,%esi
f0100bcc:	eb 04                	jmp    f0100bd2 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bce:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bd2:	8b 12                	mov    (%edx),%edx
f0100bd4:	85 d2                	test   %edx,%edx
f0100bd6:	0f 85 c8 fe ff ff    	jne    f0100aa4 <check_page_free_list+0x10e>
f0100bdc:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bdf:	85 f6                	test   %esi,%esi
f0100be1:	7f 19                	jg     f0100bfc <check_page_free_list+0x266>
f0100be3:	68 a8 54 10 f0       	push   $0xf01054a8
f0100be8:	68 3b 54 10 f0       	push   $0xf010543b
f0100bed:	68 9c 02 00 00       	push   $0x29c
f0100bf2:	68 15 54 10 f0       	push   $0xf0105415
f0100bf7:	e8 a4 f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100bfc:	85 db                	test   %ebx,%ebx
f0100bfe:	7f 42                	jg     f0100c42 <check_page_free_list+0x2ac>
f0100c00:	68 ba 54 10 f0       	push   $0xf01054ba
f0100c05:	68 3b 54 10 f0       	push   $0xf010543b
f0100c0a:	68 9d 02 00 00       	push   $0x29d
f0100c0f:	68 15 54 10 f0       	push   $0xf0105415
f0100c14:	e8 87 f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c19:	a1 80 cf 17 f0       	mov    0xf017cf80,%eax
f0100c1e:	85 c0                	test   %eax,%eax
f0100c20:	0f 85 9d fd ff ff    	jne    f01009c3 <check_page_free_list+0x2d>
f0100c26:	e9 81 fd ff ff       	jmp    f01009ac <check_page_free_list+0x16>
f0100c2b:	83 3d 80 cf 17 f0 00 	cmpl   $0x0,0xf017cf80
f0100c32:	0f 84 74 fd ff ff    	je     f01009ac <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c38:	be 00 04 00 00       	mov    $0x400,%esi
f0100c3d:	e9 cf fd ff ff       	jmp    f0100a11 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c42:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c45:	5b                   	pop    %ebx
f0100c46:	5e                   	pop    %esi
f0100c47:	5f                   	pop    %edi
f0100c48:	5d                   	pop    %ebp
f0100c49:	c3                   	ret    

f0100c4a <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c4a:	55                   	push   %ebp
f0100c4b:	89 e5                	mov    %esp,%ebp
f0100c4d:	56                   	push   %esi
f0100c4e:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100c4f:	be 00 00 00 00       	mov    $0x0,%esi
f0100c54:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c59:	e9 c5 00 00 00       	jmp    f0100d23 <page_init+0xd9>
		if(i == 0)
f0100c5e:	85 db                	test   %ebx,%ebx
f0100c60:	75 16                	jne    f0100c78 <page_init+0x2e>
		{
			pages[i].pp_ref = 1;
f0100c62:	a1 4c dc 17 f0       	mov    0xf017dc4c,%eax
f0100c67:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100c6d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100c73:	e9 a5 00 00 00       	jmp    f0100d1d <page_init+0xd3>
		}
		else if(i>=1 && i<npages_basemem)
f0100c78:	3b 1d 84 cf 17 f0    	cmp    0xf017cf84,%ebx
f0100c7e:	73 25                	jae    f0100ca5 <page_init+0x5b>
		{
			pages[i].pp_ref = 0;
f0100c80:	89 f0                	mov    %esi,%eax
f0100c82:	03 05 4c dc 17 f0    	add    0xf017dc4c,%eax
f0100c88:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100c8e:	8b 15 80 cf 17 f0    	mov    0xf017cf80,%edx
f0100c94:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100c96:	89 f0                	mov    %esi,%eax
f0100c98:	03 05 4c dc 17 f0    	add    0xf017dc4c,%eax
f0100c9e:	a3 80 cf 17 f0       	mov    %eax,0xf017cf80
f0100ca3:	eb 78                	jmp    f0100d1d <page_init+0xd3>
		}
		else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE)
f0100ca5:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100cab:	83 f8 5f             	cmp    $0x5f,%eax
f0100cae:	77 16                	ja     f0100cc6 <page_init+0x7c>
		{
			pages[i].pp_ref = 1;
f0100cb0:	89 f0                	mov    %esi,%eax
f0100cb2:	03 05 4c dc 17 f0    	add    0xf017dc4c,%eax
f0100cb8:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100cbe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100cc4:	eb 57                	jmp    f0100d1d <page_init+0xd3>
		}
		else if( i >= EXTPHYSMEM / PGSIZE && 
f0100cc6:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100ccc:	76 2c                	jbe    f0100cfa <page_init+0xb0>
			i < ((int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
f0100cce:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd3:	e8 17 fc ff ff       	call   f01008ef <boot_alloc>
		else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE)
		{
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
		}
		else if( i >= EXTPHYSMEM / PGSIZE && 
f0100cd8:	05 00 00 00 10       	add    $0x10000000,%eax
f0100cdd:	c1 e8 0c             	shr    $0xc,%eax
f0100ce0:	39 c3                	cmp    %eax,%ebx
f0100ce2:	73 16                	jae    f0100cfa <page_init+0xb0>
			i < ((int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
		{
			pages[i].pp_ref = 1;
f0100ce4:	89 f0                	mov    %esi,%eax
f0100ce6:	03 05 4c dc 17 f0    	add    0xf017dc4c,%eax
f0100cec:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100cf2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100cf8:	eb 23                	jmp    f0100d1d <page_init+0xd3>
		}
		else
		{
		pages[i].pp_ref = 0;
f0100cfa:	89 f0                	mov    %esi,%eax
f0100cfc:	03 05 4c dc 17 f0    	add    0xf017dc4c,%eax
f0100d02:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d08:	8b 15 80 cf 17 f0    	mov    0xf017cf80,%edx
f0100d0e:	89 10                	mov    %edx,(%eax)
		page_free_list = &pages[i];
f0100d10:	89 f0                	mov    %esi,%eax
f0100d12:	03 05 4c dc 17 f0    	add    0xf017dc4c,%eax
f0100d18:	a3 80 cf 17 f0       	mov    %eax,0xf017cf80
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100d1d:	83 c3 01             	add    $0x1,%ebx
f0100d20:	83 c6 08             	add    $0x8,%esi
f0100d23:	3b 1d 44 dc 17 f0    	cmp    0xf017dc44,%ebx
f0100d29:	0f 82 2f ff ff ff    	jb     f0100c5e <page_init+0x14>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
		}
	}
}
f0100d2f:	5b                   	pop    %ebx
f0100d30:	5e                   	pop    %esi
f0100d31:	5d                   	pop    %ebp
f0100d32:	c3                   	ret    

f0100d33 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d33:	55                   	push   %ebp
f0100d34:	89 e5                	mov    %esp,%ebp
f0100d36:	53                   	push   %ebx
f0100d37:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (page_free_list == NULL)
f0100d3a:	8b 1d 80 cf 17 f0    	mov    0xf017cf80,%ebx
f0100d40:	85 db                	test   %ebx,%ebx
f0100d42:	74 58                	je     f0100d9c <page_alloc+0x69>
	return NULL;
	struct PageInfo* page = page_free_list;
	page_free_list = page->pp_link;
f0100d44:	8b 03                	mov    (%ebx),%eax
f0100d46:	a3 80 cf 17 f0       	mov    %eax,0xf017cf80
	page->pp_link = 0;
f0100d4b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
f0100d51:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d55:	74 45                	je     f0100d9c <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d57:	89 d8                	mov    %ebx,%eax
f0100d59:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f0100d5f:	c1 f8 03             	sar    $0x3,%eax
f0100d62:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d65:	89 c2                	mov    %eax,%edx
f0100d67:	c1 ea 0c             	shr    $0xc,%edx
f0100d6a:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f0100d70:	72 12                	jb     f0100d84 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d72:	50                   	push   %eax
f0100d73:	68 58 4c 10 f0       	push   $0xf0104c58
f0100d78:	6a 56                	push   $0x56
f0100d7a:	68 21 54 10 f0       	push   $0xf0105421
f0100d7f:	e8 1c f3 ff ff       	call   f01000a0 <_panic>
		memset(page2kva(page), 0, PGSIZE);
f0100d84:	83 ec 04             	sub    $0x4,%esp
f0100d87:	68 00 10 00 00       	push   $0x1000
f0100d8c:	6a 00                	push   $0x0
f0100d8e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d93:	50                   	push   %eax
f0100d94:	e8 26 35 00 00       	call   f01042bf <memset>
f0100d99:	83 c4 10             	add    $0x10,%esp
	return page;
}
f0100d9c:	89 d8                	mov    %ebx,%eax
f0100d9e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100da1:	c9                   	leave  
f0100da2:	c3                   	ret    

f0100da3 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100da3:	55                   	push   %ebp
f0100da4:	89 e5                	mov    %esp,%ebp
f0100da6:	83 ec 08             	sub    $0x8,%esp
f0100da9:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_link != 0 || pp->pp_ref != 0)
f0100dac:	83 38 00             	cmpl   $0x0,(%eax)
f0100daf:	75 07                	jne    f0100db8 <page_free+0x15>
f0100db1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100db6:	74 17                	je     f0100dcf <page_free+0x2c>
		panic("page_free is not right");
f0100db8:	83 ec 04             	sub    $0x4,%esp
f0100dbb:	68 cb 54 10 f0       	push   $0xf01054cb
f0100dc0:	68 53 01 00 00       	push   $0x153
f0100dc5:	68 15 54 10 f0       	push   $0xf0105415
f0100dca:	e8 d1 f2 ff ff       	call   f01000a0 <_panic>
	pp->pp_link = page_free_list;
f0100dcf:	8b 15 80 cf 17 f0    	mov    0xf017cf80,%edx
f0100dd5:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100dd7:	a3 80 cf 17 f0       	mov    %eax,0xf017cf80
	return;
}
f0100ddc:	c9                   	leave  
f0100ddd:	c3                   	ret    

f0100dde <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100dde:	55                   	push   %ebp
f0100ddf:	89 e5                	mov    %esp,%ebp
f0100de1:	83 ec 08             	sub    $0x8,%esp
f0100de4:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100de7:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100deb:	83 e8 01             	sub    $0x1,%eax
f0100dee:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100df2:	66 85 c0             	test   %ax,%ax
f0100df5:	75 0c                	jne    f0100e03 <page_decref+0x25>
		page_free(pp);
f0100df7:	83 ec 0c             	sub    $0xc,%esp
f0100dfa:	52                   	push   %edx
f0100dfb:	e8 a3 ff ff ff       	call   f0100da3 <page_free>
f0100e00:	83 c4 10             	add    $0x10,%esp
}
f0100e03:	c9                   	leave  
f0100e04:	c3                   	ret    

f0100e05 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e05:	55                   	push   %ebp
f0100e06:	89 e5                	mov    %esp,%ebp
f0100e08:	56                   	push   %esi
f0100e09:	53                   	push   %ebx
f0100e0a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	unsigned int page_off;
	pte_t* page_base = NULL;
	struct PageInfo* new_page = NULL;
	unsigned int dic_off = PDX(va);
	pde_t* dic_entry_ptr = pgdir + dic_off;
f0100e0d:	89 f3                	mov    %esi,%ebx
f0100e0f:	c1 eb 16             	shr    $0x16,%ebx
f0100e12:	c1 e3 02             	shl    $0x2,%ebx
f0100e15:	03 5d 08             	add    0x8(%ebp),%ebx
	if(!(*dic_entry_ptr & PTE_P))
f0100e18:	f6 03 01             	testb  $0x1,(%ebx)
f0100e1b:	75 2d                	jne    f0100e4a <pgdir_walk+0x45>
	{
		if(create)
f0100e1d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e21:	74 62                	je     f0100e85 <pgdir_walk+0x80>
		{
			new_page = page_alloc(1);
f0100e23:	83 ec 0c             	sub    $0xc,%esp
f0100e26:	6a 01                	push   $0x1
f0100e28:	e8 06 ff ff ff       	call   f0100d33 <page_alloc>
			if(new_page == NULL) return NULL;
f0100e2d:	83 c4 10             	add    $0x10,%esp
f0100e30:	85 c0                	test   %eax,%eax
f0100e32:	74 58                	je     f0100e8c <pgdir_walk+0x87>
			new_page->pp_ref++;
f0100e34:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
			*dic_entry_ptr = (page2pa(new_page)|PTE_P|PTE_W|PTE_U);
f0100e39:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f0100e3f:	c1 f8 03             	sar    $0x3,%eax
f0100e42:	c1 e0 0c             	shl    $0xc,%eax
f0100e45:	83 c8 07             	or     $0x7,%eax
f0100e48:	89 03                	mov    %eax,(%ebx)
		}
		else
		return NULL;
	}
	page_off = PTX(va);
f0100e4a:	c1 ee 0c             	shr    $0xc,%esi
f0100e4d:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100e53:	8b 03                	mov    (%ebx),%eax
f0100e55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e5a:	89 c2                	mov    %eax,%edx
f0100e5c:	c1 ea 0c             	shr    $0xc,%edx
f0100e5f:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f0100e65:	72 15                	jb     f0100e7c <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e67:	50                   	push   %eax
f0100e68:	68 58 4c 10 f0       	push   $0xf0104c58
f0100e6d:	68 90 01 00 00       	push   $0x190
f0100e72:	68 15 54 10 f0       	push   $0xf0105415
f0100e77:	e8 24 f2 ff ff       	call   f01000a0 <_panic>
	return &page_base[page_off];
f0100e7c:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e83:	eb 0c                	jmp    f0100e91 <pgdir_walk+0x8c>
			if(new_page == NULL) return NULL;
			new_page->pp_ref++;
			*dic_entry_ptr = (page2pa(new_page)|PTE_P|PTE_W|PTE_U);
		}
		else
		return NULL;
f0100e85:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e8a:	eb 05                	jmp    f0100e91 <pgdir_walk+0x8c>
	if(!(*dic_entry_ptr & PTE_P))
	{
		if(create)
		{
			new_page = page_alloc(1);
			if(new_page == NULL) return NULL;
f0100e8c:	b8 00 00 00 00       	mov    $0x0,%eax
		return NULL;
	}
	page_off = PTX(va);
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[page_off];
}
f0100e91:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e94:	5b                   	pop    %ebx
f0100e95:	5e                   	pop    %esi
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	57                   	push   %edi
f0100e9c:	56                   	push   %esi
f0100e9d:	53                   	push   %ebx
f0100e9e:	83 ec 1c             	sub    $0x1c,%esp
f0100ea1:	89 c7                	mov    %eax,%edi
f0100ea3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ea6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0;nadd < size; nadd+= PGSIZE)
f0100ea9:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		entry = pgdir_walk(pgdir, (void*)va,1);
		*entry = (pa|perm|PTE_P);
f0100eae:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eb1:	83 c8 01             	or     $0x1,%eax
f0100eb4:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0;nadd < size; nadd+= PGSIZE)
f0100eb7:	eb 1f                	jmp    f0100ed8 <boot_map_region+0x40>
	{
		entry = pgdir_walk(pgdir, (void*)va,1);
f0100eb9:	83 ec 04             	sub    $0x4,%esp
f0100ebc:	6a 01                	push   $0x1
f0100ebe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ec1:	01 d8                	add    %ebx,%eax
f0100ec3:	50                   	push   %eax
f0100ec4:	57                   	push   %edi
f0100ec5:	e8 3b ff ff ff       	call   f0100e05 <pgdir_walk>
		*entry = (pa|perm|PTE_P);
f0100eca:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100ecd:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0;nadd < size; nadd+= PGSIZE)
f0100ecf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100ed5:	83 c4 10             	add    $0x10,%esp
f0100ed8:	89 de                	mov    %ebx,%esi
f0100eda:	03 75 08             	add    0x8(%ebp),%esi
f0100edd:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100ee0:	77 d7                	ja     f0100eb9 <boot_map_region+0x21>
		entry = pgdir_walk(pgdir, (void*)va,1);
		*entry = (pa|perm|PTE_P);
		pa += PGSIZE;
		va += PGSIZE;
	}
}
f0100ee2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ee5:	5b                   	pop    %ebx
f0100ee6:	5e                   	pop    %esi
f0100ee7:	5f                   	pop    %edi
f0100ee8:	5d                   	pop    %ebp
f0100ee9:	c3                   	ret    

f0100eea <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100eea:	55                   	push   %ebp
f0100eeb:	89 e5                	mov    %esp,%ebp
f0100eed:	53                   	push   %ebx
f0100eee:	83 ec 08             	sub    $0x8,%esp
f0100ef1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;
	entry = pgdir_walk(pgdir,va,0);
f0100ef4:	6a 00                	push   $0x0
f0100ef6:	ff 75 0c             	pushl  0xc(%ebp)
f0100ef9:	ff 75 08             	pushl  0x8(%ebp)
f0100efc:	e8 04 ff ff ff       	call   f0100e05 <pgdir_walk>
	if(entry == NULL)
f0100f01:	83 c4 10             	add    $0x10,%esp
f0100f04:	85 c0                	test   %eax,%eax
f0100f06:	74 38                	je     f0100f40 <page_lookup+0x56>
f0100f08:	89 c1                	mov    %eax,%ecx
		return NULL;
	if(!(*entry &PTE_P))
f0100f0a:	8b 10                	mov    (%eax),%edx
f0100f0c:	f6 c2 01             	test   $0x1,%dl
f0100f0f:	74 36                	je     f0100f47 <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f11:	c1 ea 0c             	shr    $0xc,%edx
f0100f14:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f0100f1a:	72 14                	jb     f0100f30 <page_lookup+0x46>
		panic("pa2page called with invalid pa");
f0100f1c:	83 ec 04             	sub    $0x4,%esp
f0100f1f:	68 40 4d 10 f0       	push   $0xf0104d40
f0100f24:	6a 4f                	push   $0x4f
f0100f26:	68 21 54 10 f0       	push   $0xf0105421
f0100f2b:	e8 70 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f30:	a1 4c dc 17 f0       	mov    0xf017dc4c,%eax
f0100f35:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		return NULL;
	ret = pa2page(PTE_ADDR(*entry));
	if(pte_store != NULL)
f0100f38:	85 db                	test   %ebx,%ebx
f0100f3a:	74 10                	je     f0100f4c <page_lookup+0x62>
	{
		*pte_store = entry;
f0100f3c:	89 0b                	mov    %ecx,(%ebx)
f0100f3e:	eb 0c                	jmp    f0100f4c <page_lookup+0x62>
	// Fill this function in
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;
	entry = pgdir_walk(pgdir,va,0);
	if(entry == NULL)
		return NULL;
f0100f40:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f45:	eb 05                	jmp    f0100f4c <page_lookup+0x62>
	if(!(*entry &PTE_P))
		return NULL;
f0100f47:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		*pte_store = entry;
	}
	return ret;

}
f0100f4c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f4f:	c9                   	leave  
f0100f50:	c3                   	ret    

f0100f51 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f51:	55                   	push   %ebp
f0100f52:	89 e5                	mov    %esp,%ebp
f0100f54:	53                   	push   %ebx
f0100f55:	83 ec 18             	sub    $0x18,%esp
f0100f58:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte_t **pte_store = &pte;
	struct PageInfo *pp = page_lookup(pgdir,va,pte_store);
f0100f5b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f5e:	50                   	push   %eax
f0100f5f:	53                   	push   %ebx
f0100f60:	ff 75 08             	pushl  0x8(%ebp)
f0100f63:	e8 82 ff ff ff       	call   f0100eea <page_lookup>
	if(!pp)
f0100f68:	83 c4 10             	add    $0x10,%esp
f0100f6b:	85 c0                	test   %eax,%eax
f0100f6d:	74 18                	je     f0100f87 <page_remove+0x36>
		return;
	page_decref(pp);
f0100f6f:	83 ec 0c             	sub    $0xc,%esp
f0100f72:	50                   	push   %eax
f0100f73:	e8 66 fe ff ff       	call   f0100dde <page_decref>
	**pte_store = 0;
f0100f78:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f7b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f81:	0f 01 3b             	invlpg (%ebx)
f0100f84:	83 c4 10             	add    $0x10,%esp
	tlb_invalidate(pgdir,va);
}
f0100f87:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f8a:	c9                   	leave  
f0100f8b:	c3                   	ret    

f0100f8c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f8c:	55                   	push   %ebp
f0100f8d:	89 e5                	mov    %esp,%ebp
f0100f8f:	57                   	push   %edi
f0100f90:	56                   	push   %esi
f0100f91:	53                   	push   %ebx
f0100f92:	83 ec 10             	sub    $0x10,%esp
f0100f95:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f98:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t*entry = NULL;
	entry = pgdir_walk(pgdir,va,1);
f0100f9b:	6a 01                	push   $0x1
f0100f9d:	ff 75 10             	pushl  0x10(%ebp)
f0100fa0:	56                   	push   %esi
f0100fa1:	e8 5f fe ff ff       	call   f0100e05 <pgdir_walk>
	if(entry == NULL) return -E_NO_MEM;
f0100fa6:	83 c4 10             	add    $0x10,%esp
f0100fa9:	85 c0                	test   %eax,%eax
f0100fab:	74 4a                	je     f0100ff7 <page_insert+0x6b>
f0100fad:	89 c7                	mov    %eax,%edi
	pp->pp_ref++;
f0100faf:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*entry)&PTE_P)
f0100fb4:	f6 00 01             	testb  $0x1,(%eax)
f0100fb7:	74 15                	je     f0100fce <page_insert+0x42>
f0100fb9:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fbc:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f0100fbf:	83 ec 08             	sub    $0x8,%esp
f0100fc2:	ff 75 10             	pushl  0x10(%ebp)
f0100fc5:	56                   	push   %esi
f0100fc6:	e8 86 ff ff ff       	call   f0100f51 <page_remove>
f0100fcb:	83 c4 10             	add    $0x10,%esp
	}
	*entry = (page2pa(pp)|perm|PTE_P);
f0100fce:	2b 1d 4c dc 17 f0    	sub    0xf017dc4c,%ebx
f0100fd4:	c1 fb 03             	sar    $0x3,%ebx
f0100fd7:	c1 e3 0c             	shl    $0xc,%ebx
f0100fda:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fdd:	83 c8 01             	or     $0x1,%eax
f0100fe0:	09 c3                	or     %eax,%ebx
f0100fe2:	89 1f                	mov    %ebx,(%edi)
	pgdir[PDX(va)] |= perm;
f0100fe4:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fe7:	c1 e8 16             	shr    $0x16,%eax
f0100fea:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fed:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f0100ff0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ff5:	eb 05                	jmp    f0100ffc <page_insert+0x70>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t*entry = NULL;
	entry = pgdir_walk(pgdir,va,1);
	if(entry == NULL) return -E_NO_MEM;
f0100ff7:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);
	}
	*entry = (page2pa(pp)|perm|PTE_P);
	pgdir[PDX(va)] |= perm;
	return 0;
}
f0100ffc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fff:	5b                   	pop    %ebx
f0101000:	5e                   	pop    %esi
f0101001:	5f                   	pop    %edi
f0101002:	5d                   	pop    %ebp
f0101003:	c3                   	ret    

f0101004 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101004:	55                   	push   %ebp
f0101005:	89 e5                	mov    %esp,%ebp
f0101007:	57                   	push   %edi
f0101008:	56                   	push   %esi
f0101009:	53                   	push   %ebx
f010100a:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010100d:	6a 15                	push   $0x15
f010100f:	e8 b3 1e 00 00       	call   f0102ec7 <mc146818_read>
f0101014:	89 c3                	mov    %eax,%ebx
f0101016:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010101d:	e8 a5 1e 00 00       	call   f0102ec7 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101022:	c1 e0 08             	shl    $0x8,%eax
f0101025:	09 d8                	or     %ebx,%eax
f0101027:	c1 e0 0a             	shl    $0xa,%eax
f010102a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101030:	85 c0                	test   %eax,%eax
f0101032:	0f 48 c2             	cmovs  %edx,%eax
f0101035:	c1 f8 0c             	sar    $0xc,%eax
f0101038:	a3 84 cf 17 f0       	mov    %eax,0xf017cf84
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010103d:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101044:	e8 7e 1e 00 00       	call   f0102ec7 <mc146818_read>
f0101049:	89 c3                	mov    %eax,%ebx
f010104b:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101052:	e8 70 1e 00 00       	call   f0102ec7 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101057:	c1 e0 08             	shl    $0x8,%eax
f010105a:	09 d8                	or     %ebx,%eax
f010105c:	c1 e0 0a             	shl    $0xa,%eax
f010105f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101065:	83 c4 10             	add    $0x10,%esp
f0101068:	85 c0                	test   %eax,%eax
f010106a:	0f 48 c2             	cmovs  %edx,%eax
f010106d:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101070:	85 c0                	test   %eax,%eax
f0101072:	74 0e                	je     f0101082 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101074:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010107a:	89 15 44 dc 17 f0    	mov    %edx,0xf017dc44
f0101080:	eb 0c                	jmp    f010108e <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101082:	8b 15 84 cf 17 f0    	mov    0xf017cf84,%edx
f0101088:	89 15 44 dc 17 f0    	mov    %edx,0xf017dc44

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010108e:	c1 e0 0c             	shl    $0xc,%eax
f0101091:	c1 e8 0a             	shr    $0xa,%eax
f0101094:	50                   	push   %eax
f0101095:	a1 84 cf 17 f0       	mov    0xf017cf84,%eax
f010109a:	c1 e0 0c             	shl    $0xc,%eax
f010109d:	c1 e8 0a             	shr    $0xa,%eax
f01010a0:	50                   	push   %eax
f01010a1:	a1 44 dc 17 f0       	mov    0xf017dc44,%eax
f01010a6:	c1 e0 0c             	shl    $0xc,%eax
f01010a9:	c1 e8 0a             	shr    $0xa,%eax
f01010ac:	50                   	push   %eax
f01010ad:	68 60 4d 10 f0       	push   $0xf0104d60
f01010b2:	e8 77 1e 00 00       	call   f0102f2e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010b7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010bc:	e8 2e f8 ff ff       	call   f01008ef <boot_alloc>
f01010c1:	a3 48 dc 17 f0       	mov    %eax,0xf017dc48
	memset(kern_pgdir, 0, PGSIZE);
f01010c6:	83 c4 0c             	add    $0xc,%esp
f01010c9:	68 00 10 00 00       	push   $0x1000
f01010ce:	6a 00                	push   $0x0
f01010d0:	50                   	push   %eax
f01010d1:	e8 e9 31 00 00       	call   f01042bf <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010d6:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010db:	83 c4 10             	add    $0x10,%esp
f01010de:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010e3:	77 15                	ja     f01010fa <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010e5:	50                   	push   %eax
f01010e6:	68 9c 4d 10 f0       	push   $0xf0104d9c
f01010eb:	68 8f 00 00 00       	push   $0x8f
f01010f0:	68 15 54 10 f0       	push   $0xf0105415
f01010f5:	e8 a6 ef ff ff       	call   f01000a0 <_panic>
f01010fa:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101100:	83 ca 05             	or     $0x5,%edx
f0101103:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = boot_alloc(npages * sizeof (struct PageInfo));
f0101109:	a1 44 dc 17 f0       	mov    0xf017dc44,%eax
f010110e:	c1 e0 03             	shl    $0x3,%eax
f0101111:	e8 d9 f7 ff ff       	call   f01008ef <boot_alloc>
f0101116:	a3 4c dc 17 f0       	mov    %eax,0xf017dc4c
	memset(pages, 0, npages* sizeof(struct PageInfo));
f010111b:	83 ec 04             	sub    $0x4,%esp
f010111e:	8b 3d 44 dc 17 f0    	mov    0xf017dc44,%edi
f0101124:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f010112b:	52                   	push   %edx
f010112c:	6a 00                	push   $0x0
f010112e:	50                   	push   %eax
f010112f:	e8 8b 31 00 00       	call   f01042bf <memset>
	
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f0101134:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101139:	e8 b1 f7 ff ff       	call   f01008ef <boot_alloc>
f010113e:	a3 8c cf 17 f0       	mov    %eax,0xf017cf8c
	memset(envs, 0, NENV * sizeof(struct Env));
f0101143:	83 c4 0c             	add    $0xc,%esp
f0101146:	68 00 80 01 00       	push   $0x18000
f010114b:	6a 00                	push   $0x0
f010114d:	50                   	push   %eax
f010114e:	e8 6c 31 00 00       	call   f01042bf <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101153:	e8 f2 fa ff ff       	call   f0100c4a <page_init>

	check_page_free_list(1);
f0101158:	b8 01 00 00 00       	mov    $0x1,%eax
f010115d:	e8 34 f8 ff ff       	call   f0100996 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101162:	83 c4 10             	add    $0x10,%esp
f0101165:	83 3d 4c dc 17 f0 00 	cmpl   $0x0,0xf017dc4c
f010116c:	75 17                	jne    f0101185 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010116e:	83 ec 04             	sub    $0x4,%esp
f0101171:	68 e2 54 10 f0       	push   $0xf01054e2
f0101176:	68 ae 02 00 00       	push   $0x2ae
f010117b:	68 15 54 10 f0       	push   $0xf0105415
f0101180:	e8 1b ef ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101185:	a1 80 cf 17 f0       	mov    0xf017cf80,%eax
f010118a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010118f:	eb 05                	jmp    f0101196 <mem_init+0x192>
		++nfree;
f0101191:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101194:	8b 00                	mov    (%eax),%eax
f0101196:	85 c0                	test   %eax,%eax
f0101198:	75 f7                	jne    f0101191 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010119a:	83 ec 0c             	sub    $0xc,%esp
f010119d:	6a 00                	push   $0x0
f010119f:	e8 8f fb ff ff       	call   f0100d33 <page_alloc>
f01011a4:	89 c7                	mov    %eax,%edi
f01011a6:	83 c4 10             	add    $0x10,%esp
f01011a9:	85 c0                	test   %eax,%eax
f01011ab:	75 19                	jne    f01011c6 <mem_init+0x1c2>
f01011ad:	68 fd 54 10 f0       	push   $0xf01054fd
f01011b2:	68 3b 54 10 f0       	push   $0xf010543b
f01011b7:	68 b6 02 00 00       	push   $0x2b6
f01011bc:	68 15 54 10 f0       	push   $0xf0105415
f01011c1:	e8 da ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01011c6:	83 ec 0c             	sub    $0xc,%esp
f01011c9:	6a 00                	push   $0x0
f01011cb:	e8 63 fb ff ff       	call   f0100d33 <page_alloc>
f01011d0:	89 c6                	mov    %eax,%esi
f01011d2:	83 c4 10             	add    $0x10,%esp
f01011d5:	85 c0                	test   %eax,%eax
f01011d7:	75 19                	jne    f01011f2 <mem_init+0x1ee>
f01011d9:	68 13 55 10 f0       	push   $0xf0105513
f01011de:	68 3b 54 10 f0       	push   $0xf010543b
f01011e3:	68 b7 02 00 00       	push   $0x2b7
f01011e8:	68 15 54 10 f0       	push   $0xf0105415
f01011ed:	e8 ae ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01011f2:	83 ec 0c             	sub    $0xc,%esp
f01011f5:	6a 00                	push   $0x0
f01011f7:	e8 37 fb ff ff       	call   f0100d33 <page_alloc>
f01011fc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011ff:	83 c4 10             	add    $0x10,%esp
f0101202:	85 c0                	test   %eax,%eax
f0101204:	75 19                	jne    f010121f <mem_init+0x21b>
f0101206:	68 29 55 10 f0       	push   $0xf0105529
f010120b:	68 3b 54 10 f0       	push   $0xf010543b
f0101210:	68 b8 02 00 00       	push   $0x2b8
f0101215:	68 15 54 10 f0       	push   $0xf0105415
f010121a:	e8 81 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010121f:	39 f7                	cmp    %esi,%edi
f0101221:	75 19                	jne    f010123c <mem_init+0x238>
f0101223:	68 3f 55 10 f0       	push   $0xf010553f
f0101228:	68 3b 54 10 f0       	push   $0xf010543b
f010122d:	68 bb 02 00 00       	push   $0x2bb
f0101232:	68 15 54 10 f0       	push   $0xf0105415
f0101237:	e8 64 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010123c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010123f:	39 c6                	cmp    %eax,%esi
f0101241:	74 04                	je     f0101247 <mem_init+0x243>
f0101243:	39 c7                	cmp    %eax,%edi
f0101245:	75 19                	jne    f0101260 <mem_init+0x25c>
f0101247:	68 c0 4d 10 f0       	push   $0xf0104dc0
f010124c:	68 3b 54 10 f0       	push   $0xf010543b
f0101251:	68 bc 02 00 00       	push   $0x2bc
f0101256:	68 15 54 10 f0       	push   $0xf0105415
f010125b:	e8 40 ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101260:	8b 0d 4c dc 17 f0    	mov    0xf017dc4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101266:	8b 15 44 dc 17 f0    	mov    0xf017dc44,%edx
f010126c:	c1 e2 0c             	shl    $0xc,%edx
f010126f:	89 f8                	mov    %edi,%eax
f0101271:	29 c8                	sub    %ecx,%eax
f0101273:	c1 f8 03             	sar    $0x3,%eax
f0101276:	c1 e0 0c             	shl    $0xc,%eax
f0101279:	39 d0                	cmp    %edx,%eax
f010127b:	72 19                	jb     f0101296 <mem_init+0x292>
f010127d:	68 51 55 10 f0       	push   $0xf0105551
f0101282:	68 3b 54 10 f0       	push   $0xf010543b
f0101287:	68 bd 02 00 00       	push   $0x2bd
f010128c:	68 15 54 10 f0       	push   $0xf0105415
f0101291:	e8 0a ee ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101296:	89 f0                	mov    %esi,%eax
f0101298:	29 c8                	sub    %ecx,%eax
f010129a:	c1 f8 03             	sar    $0x3,%eax
f010129d:	c1 e0 0c             	shl    $0xc,%eax
f01012a0:	39 c2                	cmp    %eax,%edx
f01012a2:	77 19                	ja     f01012bd <mem_init+0x2b9>
f01012a4:	68 6e 55 10 f0       	push   $0xf010556e
f01012a9:	68 3b 54 10 f0       	push   $0xf010543b
f01012ae:	68 be 02 00 00       	push   $0x2be
f01012b3:	68 15 54 10 f0       	push   $0xf0105415
f01012b8:	e8 e3 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012c0:	29 c8                	sub    %ecx,%eax
f01012c2:	c1 f8 03             	sar    $0x3,%eax
f01012c5:	c1 e0 0c             	shl    $0xc,%eax
f01012c8:	39 c2                	cmp    %eax,%edx
f01012ca:	77 19                	ja     f01012e5 <mem_init+0x2e1>
f01012cc:	68 8b 55 10 f0       	push   $0xf010558b
f01012d1:	68 3b 54 10 f0       	push   $0xf010543b
f01012d6:	68 bf 02 00 00       	push   $0x2bf
f01012db:	68 15 54 10 f0       	push   $0xf0105415
f01012e0:	e8 bb ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012e5:	a1 80 cf 17 f0       	mov    0xf017cf80,%eax
f01012ea:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012ed:	c7 05 80 cf 17 f0 00 	movl   $0x0,0xf017cf80
f01012f4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012f7:	83 ec 0c             	sub    $0xc,%esp
f01012fa:	6a 00                	push   $0x0
f01012fc:	e8 32 fa ff ff       	call   f0100d33 <page_alloc>
f0101301:	83 c4 10             	add    $0x10,%esp
f0101304:	85 c0                	test   %eax,%eax
f0101306:	74 19                	je     f0101321 <mem_init+0x31d>
f0101308:	68 a8 55 10 f0       	push   $0xf01055a8
f010130d:	68 3b 54 10 f0       	push   $0xf010543b
f0101312:	68 c6 02 00 00       	push   $0x2c6
f0101317:	68 15 54 10 f0       	push   $0xf0105415
f010131c:	e8 7f ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101321:	83 ec 0c             	sub    $0xc,%esp
f0101324:	57                   	push   %edi
f0101325:	e8 79 fa ff ff       	call   f0100da3 <page_free>
	page_free(pp1);
f010132a:	89 34 24             	mov    %esi,(%esp)
f010132d:	e8 71 fa ff ff       	call   f0100da3 <page_free>
	page_free(pp2);
f0101332:	83 c4 04             	add    $0x4,%esp
f0101335:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101338:	e8 66 fa ff ff       	call   f0100da3 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010133d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101344:	e8 ea f9 ff ff       	call   f0100d33 <page_alloc>
f0101349:	89 c6                	mov    %eax,%esi
f010134b:	83 c4 10             	add    $0x10,%esp
f010134e:	85 c0                	test   %eax,%eax
f0101350:	75 19                	jne    f010136b <mem_init+0x367>
f0101352:	68 fd 54 10 f0       	push   $0xf01054fd
f0101357:	68 3b 54 10 f0       	push   $0xf010543b
f010135c:	68 cd 02 00 00       	push   $0x2cd
f0101361:	68 15 54 10 f0       	push   $0xf0105415
f0101366:	e8 35 ed ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010136b:	83 ec 0c             	sub    $0xc,%esp
f010136e:	6a 00                	push   $0x0
f0101370:	e8 be f9 ff ff       	call   f0100d33 <page_alloc>
f0101375:	89 c7                	mov    %eax,%edi
f0101377:	83 c4 10             	add    $0x10,%esp
f010137a:	85 c0                	test   %eax,%eax
f010137c:	75 19                	jne    f0101397 <mem_init+0x393>
f010137e:	68 13 55 10 f0       	push   $0xf0105513
f0101383:	68 3b 54 10 f0       	push   $0xf010543b
f0101388:	68 ce 02 00 00       	push   $0x2ce
f010138d:	68 15 54 10 f0       	push   $0xf0105415
f0101392:	e8 09 ed ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101397:	83 ec 0c             	sub    $0xc,%esp
f010139a:	6a 00                	push   $0x0
f010139c:	e8 92 f9 ff ff       	call   f0100d33 <page_alloc>
f01013a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013a4:	83 c4 10             	add    $0x10,%esp
f01013a7:	85 c0                	test   %eax,%eax
f01013a9:	75 19                	jne    f01013c4 <mem_init+0x3c0>
f01013ab:	68 29 55 10 f0       	push   $0xf0105529
f01013b0:	68 3b 54 10 f0       	push   $0xf010543b
f01013b5:	68 cf 02 00 00       	push   $0x2cf
f01013ba:	68 15 54 10 f0       	push   $0xf0105415
f01013bf:	e8 dc ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013c4:	39 fe                	cmp    %edi,%esi
f01013c6:	75 19                	jne    f01013e1 <mem_init+0x3dd>
f01013c8:	68 3f 55 10 f0       	push   $0xf010553f
f01013cd:	68 3b 54 10 f0       	push   $0xf010543b
f01013d2:	68 d1 02 00 00       	push   $0x2d1
f01013d7:	68 15 54 10 f0       	push   $0xf0105415
f01013dc:	e8 bf ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013e4:	39 c7                	cmp    %eax,%edi
f01013e6:	74 04                	je     f01013ec <mem_init+0x3e8>
f01013e8:	39 c6                	cmp    %eax,%esi
f01013ea:	75 19                	jne    f0101405 <mem_init+0x401>
f01013ec:	68 c0 4d 10 f0       	push   $0xf0104dc0
f01013f1:	68 3b 54 10 f0       	push   $0xf010543b
f01013f6:	68 d2 02 00 00       	push   $0x2d2
f01013fb:	68 15 54 10 f0       	push   $0xf0105415
f0101400:	e8 9b ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101405:	83 ec 0c             	sub    $0xc,%esp
f0101408:	6a 00                	push   $0x0
f010140a:	e8 24 f9 ff ff       	call   f0100d33 <page_alloc>
f010140f:	83 c4 10             	add    $0x10,%esp
f0101412:	85 c0                	test   %eax,%eax
f0101414:	74 19                	je     f010142f <mem_init+0x42b>
f0101416:	68 a8 55 10 f0       	push   $0xf01055a8
f010141b:	68 3b 54 10 f0       	push   $0xf010543b
f0101420:	68 d3 02 00 00       	push   $0x2d3
f0101425:	68 15 54 10 f0       	push   $0xf0105415
f010142a:	e8 71 ec ff ff       	call   f01000a0 <_panic>
f010142f:	89 f0                	mov    %esi,%eax
f0101431:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f0101437:	c1 f8 03             	sar    $0x3,%eax
f010143a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010143d:	89 c2                	mov    %eax,%edx
f010143f:	c1 ea 0c             	shr    $0xc,%edx
f0101442:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f0101448:	72 12                	jb     f010145c <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010144a:	50                   	push   %eax
f010144b:	68 58 4c 10 f0       	push   $0xf0104c58
f0101450:	6a 56                	push   $0x56
f0101452:	68 21 54 10 f0       	push   $0xf0105421
f0101457:	e8 44 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010145c:	83 ec 04             	sub    $0x4,%esp
f010145f:	68 00 10 00 00       	push   $0x1000
f0101464:	6a 01                	push   $0x1
f0101466:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010146b:	50                   	push   %eax
f010146c:	e8 4e 2e 00 00       	call   f01042bf <memset>
	page_free(pp0);
f0101471:	89 34 24             	mov    %esi,(%esp)
f0101474:	e8 2a f9 ff ff       	call   f0100da3 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101479:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101480:	e8 ae f8 ff ff       	call   f0100d33 <page_alloc>
f0101485:	83 c4 10             	add    $0x10,%esp
f0101488:	85 c0                	test   %eax,%eax
f010148a:	75 19                	jne    f01014a5 <mem_init+0x4a1>
f010148c:	68 b7 55 10 f0       	push   $0xf01055b7
f0101491:	68 3b 54 10 f0       	push   $0xf010543b
f0101496:	68 d8 02 00 00       	push   $0x2d8
f010149b:	68 15 54 10 f0       	push   $0xf0105415
f01014a0:	e8 fb eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014a5:	39 c6                	cmp    %eax,%esi
f01014a7:	74 19                	je     f01014c2 <mem_init+0x4be>
f01014a9:	68 d5 55 10 f0       	push   $0xf01055d5
f01014ae:	68 3b 54 10 f0       	push   $0xf010543b
f01014b3:	68 d9 02 00 00       	push   $0x2d9
f01014b8:	68 15 54 10 f0       	push   $0xf0105415
f01014bd:	e8 de eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014c2:	89 f0                	mov    %esi,%eax
f01014c4:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f01014ca:	c1 f8 03             	sar    $0x3,%eax
f01014cd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014d0:	89 c2                	mov    %eax,%edx
f01014d2:	c1 ea 0c             	shr    $0xc,%edx
f01014d5:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f01014db:	72 12                	jb     f01014ef <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014dd:	50                   	push   %eax
f01014de:	68 58 4c 10 f0       	push   $0xf0104c58
f01014e3:	6a 56                	push   $0x56
f01014e5:	68 21 54 10 f0       	push   $0xf0105421
f01014ea:	e8 b1 eb ff ff       	call   f01000a0 <_panic>
f01014ef:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014f5:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014fb:	80 38 00             	cmpb   $0x0,(%eax)
f01014fe:	74 19                	je     f0101519 <mem_init+0x515>
f0101500:	68 e5 55 10 f0       	push   $0xf01055e5
f0101505:	68 3b 54 10 f0       	push   $0xf010543b
f010150a:	68 dc 02 00 00       	push   $0x2dc
f010150f:	68 15 54 10 f0       	push   $0xf0105415
f0101514:	e8 87 eb ff ff       	call   f01000a0 <_panic>
f0101519:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010151c:	39 d0                	cmp    %edx,%eax
f010151e:	75 db                	jne    f01014fb <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101520:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101523:	a3 80 cf 17 f0       	mov    %eax,0xf017cf80

	// free the pages we took
	page_free(pp0);
f0101528:	83 ec 0c             	sub    $0xc,%esp
f010152b:	56                   	push   %esi
f010152c:	e8 72 f8 ff ff       	call   f0100da3 <page_free>
	page_free(pp1);
f0101531:	89 3c 24             	mov    %edi,(%esp)
f0101534:	e8 6a f8 ff ff       	call   f0100da3 <page_free>
	page_free(pp2);
f0101539:	83 c4 04             	add    $0x4,%esp
f010153c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010153f:	e8 5f f8 ff ff       	call   f0100da3 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101544:	a1 80 cf 17 f0       	mov    0xf017cf80,%eax
f0101549:	83 c4 10             	add    $0x10,%esp
f010154c:	eb 05                	jmp    f0101553 <mem_init+0x54f>
		--nfree;
f010154e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101551:	8b 00                	mov    (%eax),%eax
f0101553:	85 c0                	test   %eax,%eax
f0101555:	75 f7                	jne    f010154e <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101557:	85 db                	test   %ebx,%ebx
f0101559:	74 19                	je     f0101574 <mem_init+0x570>
f010155b:	68 ef 55 10 f0       	push   $0xf01055ef
f0101560:	68 3b 54 10 f0       	push   $0xf010543b
f0101565:	68 e9 02 00 00       	push   $0x2e9
f010156a:	68 15 54 10 f0       	push   $0xf0105415
f010156f:	e8 2c eb ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101574:	83 ec 0c             	sub    $0xc,%esp
f0101577:	68 e0 4d 10 f0       	push   $0xf0104de0
f010157c:	e8 ad 19 00 00       	call   f0102f2e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101581:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101588:	e8 a6 f7 ff ff       	call   f0100d33 <page_alloc>
f010158d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101590:	83 c4 10             	add    $0x10,%esp
f0101593:	85 c0                	test   %eax,%eax
f0101595:	75 19                	jne    f01015b0 <mem_init+0x5ac>
f0101597:	68 fd 54 10 f0       	push   $0xf01054fd
f010159c:	68 3b 54 10 f0       	push   $0xf010543b
f01015a1:	68 47 03 00 00       	push   $0x347
f01015a6:	68 15 54 10 f0       	push   $0xf0105415
f01015ab:	e8 f0 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015b0:	83 ec 0c             	sub    $0xc,%esp
f01015b3:	6a 00                	push   $0x0
f01015b5:	e8 79 f7 ff ff       	call   f0100d33 <page_alloc>
f01015ba:	89 c3                	mov    %eax,%ebx
f01015bc:	83 c4 10             	add    $0x10,%esp
f01015bf:	85 c0                	test   %eax,%eax
f01015c1:	75 19                	jne    f01015dc <mem_init+0x5d8>
f01015c3:	68 13 55 10 f0       	push   $0xf0105513
f01015c8:	68 3b 54 10 f0       	push   $0xf010543b
f01015cd:	68 48 03 00 00       	push   $0x348
f01015d2:	68 15 54 10 f0       	push   $0xf0105415
f01015d7:	e8 c4 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01015dc:	83 ec 0c             	sub    $0xc,%esp
f01015df:	6a 00                	push   $0x0
f01015e1:	e8 4d f7 ff ff       	call   f0100d33 <page_alloc>
f01015e6:	89 c6                	mov    %eax,%esi
f01015e8:	83 c4 10             	add    $0x10,%esp
f01015eb:	85 c0                	test   %eax,%eax
f01015ed:	75 19                	jne    f0101608 <mem_init+0x604>
f01015ef:	68 29 55 10 f0       	push   $0xf0105529
f01015f4:	68 3b 54 10 f0       	push   $0xf010543b
f01015f9:	68 49 03 00 00       	push   $0x349
f01015fe:	68 15 54 10 f0       	push   $0xf0105415
f0101603:	e8 98 ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101608:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010160b:	75 19                	jne    f0101626 <mem_init+0x622>
f010160d:	68 3f 55 10 f0       	push   $0xf010553f
f0101612:	68 3b 54 10 f0       	push   $0xf010543b
f0101617:	68 4c 03 00 00       	push   $0x34c
f010161c:	68 15 54 10 f0       	push   $0xf0105415
f0101621:	e8 7a ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101626:	39 c3                	cmp    %eax,%ebx
f0101628:	74 05                	je     f010162f <mem_init+0x62b>
f010162a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010162d:	75 19                	jne    f0101648 <mem_init+0x644>
f010162f:	68 c0 4d 10 f0       	push   $0xf0104dc0
f0101634:	68 3b 54 10 f0       	push   $0xf010543b
f0101639:	68 4d 03 00 00       	push   $0x34d
f010163e:	68 15 54 10 f0       	push   $0xf0105415
f0101643:	e8 58 ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101648:	a1 80 cf 17 f0       	mov    0xf017cf80,%eax
f010164d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101650:	c7 05 80 cf 17 f0 00 	movl   $0x0,0xf017cf80
f0101657:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010165a:	83 ec 0c             	sub    $0xc,%esp
f010165d:	6a 00                	push   $0x0
f010165f:	e8 cf f6 ff ff       	call   f0100d33 <page_alloc>
f0101664:	83 c4 10             	add    $0x10,%esp
f0101667:	85 c0                	test   %eax,%eax
f0101669:	74 19                	je     f0101684 <mem_init+0x680>
f010166b:	68 a8 55 10 f0       	push   $0xf01055a8
f0101670:	68 3b 54 10 f0       	push   $0xf010543b
f0101675:	68 54 03 00 00       	push   $0x354
f010167a:	68 15 54 10 f0       	push   $0xf0105415
f010167f:	e8 1c ea ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101684:	83 ec 04             	sub    $0x4,%esp
f0101687:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010168a:	50                   	push   %eax
f010168b:	6a 00                	push   $0x0
f010168d:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101693:	e8 52 f8 ff ff       	call   f0100eea <page_lookup>
f0101698:	83 c4 10             	add    $0x10,%esp
f010169b:	85 c0                	test   %eax,%eax
f010169d:	74 19                	je     f01016b8 <mem_init+0x6b4>
f010169f:	68 00 4e 10 f0       	push   $0xf0104e00
f01016a4:	68 3b 54 10 f0       	push   $0xf010543b
f01016a9:	68 57 03 00 00       	push   $0x357
f01016ae:	68 15 54 10 f0       	push   $0xf0105415
f01016b3:	e8 e8 e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016b8:	6a 02                	push   $0x2
f01016ba:	6a 00                	push   $0x0
f01016bc:	53                   	push   %ebx
f01016bd:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f01016c3:	e8 c4 f8 ff ff       	call   f0100f8c <page_insert>
f01016c8:	83 c4 10             	add    $0x10,%esp
f01016cb:	85 c0                	test   %eax,%eax
f01016cd:	78 19                	js     f01016e8 <mem_init+0x6e4>
f01016cf:	68 38 4e 10 f0       	push   $0xf0104e38
f01016d4:	68 3b 54 10 f0       	push   $0xf010543b
f01016d9:	68 5a 03 00 00       	push   $0x35a
f01016de:	68 15 54 10 f0       	push   $0xf0105415
f01016e3:	e8 b8 e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016e8:	83 ec 0c             	sub    $0xc,%esp
f01016eb:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016ee:	e8 b0 f6 ff ff       	call   f0100da3 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016f3:	6a 02                	push   $0x2
f01016f5:	6a 00                	push   $0x0
f01016f7:	53                   	push   %ebx
f01016f8:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f01016fe:	e8 89 f8 ff ff       	call   f0100f8c <page_insert>
f0101703:	83 c4 20             	add    $0x20,%esp
f0101706:	85 c0                	test   %eax,%eax
f0101708:	74 19                	je     f0101723 <mem_init+0x71f>
f010170a:	68 68 4e 10 f0       	push   $0xf0104e68
f010170f:	68 3b 54 10 f0       	push   $0xf010543b
f0101714:	68 5e 03 00 00       	push   $0x35e
f0101719:	68 15 54 10 f0       	push   $0xf0105415
f010171e:	e8 7d e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101723:	8b 3d 48 dc 17 f0    	mov    0xf017dc48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101729:	a1 4c dc 17 f0       	mov    0xf017dc4c,%eax
f010172e:	89 c1                	mov    %eax,%ecx
f0101730:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101733:	8b 17                	mov    (%edi),%edx
f0101735:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010173b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010173e:	29 c8                	sub    %ecx,%eax
f0101740:	c1 f8 03             	sar    $0x3,%eax
f0101743:	c1 e0 0c             	shl    $0xc,%eax
f0101746:	39 c2                	cmp    %eax,%edx
f0101748:	74 19                	je     f0101763 <mem_init+0x75f>
f010174a:	68 98 4e 10 f0       	push   $0xf0104e98
f010174f:	68 3b 54 10 f0       	push   $0xf010543b
f0101754:	68 5f 03 00 00       	push   $0x35f
f0101759:	68 15 54 10 f0       	push   $0xf0105415
f010175e:	e8 3d e9 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101763:	ba 00 00 00 00       	mov    $0x0,%edx
f0101768:	89 f8                	mov    %edi,%eax
f010176a:	e8 c3 f1 ff ff       	call   f0100932 <check_va2pa>
f010176f:	89 da                	mov    %ebx,%edx
f0101771:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101774:	c1 fa 03             	sar    $0x3,%edx
f0101777:	c1 e2 0c             	shl    $0xc,%edx
f010177a:	39 d0                	cmp    %edx,%eax
f010177c:	74 19                	je     f0101797 <mem_init+0x793>
f010177e:	68 c0 4e 10 f0       	push   $0xf0104ec0
f0101783:	68 3b 54 10 f0       	push   $0xf010543b
f0101788:	68 60 03 00 00       	push   $0x360
f010178d:	68 15 54 10 f0       	push   $0xf0105415
f0101792:	e8 09 e9 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101797:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010179c:	74 19                	je     f01017b7 <mem_init+0x7b3>
f010179e:	68 fa 55 10 f0       	push   $0xf01055fa
f01017a3:	68 3b 54 10 f0       	push   $0xf010543b
f01017a8:	68 61 03 00 00       	push   $0x361
f01017ad:	68 15 54 10 f0       	push   $0xf0105415
f01017b2:	e8 e9 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017b7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017ba:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017bf:	74 19                	je     f01017da <mem_init+0x7d6>
f01017c1:	68 0b 56 10 f0       	push   $0xf010560b
f01017c6:	68 3b 54 10 f0       	push   $0xf010543b
f01017cb:	68 62 03 00 00       	push   $0x362
f01017d0:	68 15 54 10 f0       	push   $0xf0105415
f01017d5:	e8 c6 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017da:	6a 02                	push   $0x2
f01017dc:	68 00 10 00 00       	push   $0x1000
f01017e1:	56                   	push   %esi
f01017e2:	57                   	push   %edi
f01017e3:	e8 a4 f7 ff ff       	call   f0100f8c <page_insert>
f01017e8:	83 c4 10             	add    $0x10,%esp
f01017eb:	85 c0                	test   %eax,%eax
f01017ed:	74 19                	je     f0101808 <mem_init+0x804>
f01017ef:	68 f0 4e 10 f0       	push   $0xf0104ef0
f01017f4:	68 3b 54 10 f0       	push   $0xf010543b
f01017f9:	68 65 03 00 00       	push   $0x365
f01017fe:	68 15 54 10 f0       	push   $0xf0105415
f0101803:	e8 98 e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101808:	ba 00 10 00 00       	mov    $0x1000,%edx
f010180d:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f0101812:	e8 1b f1 ff ff       	call   f0100932 <check_va2pa>
f0101817:	89 f2                	mov    %esi,%edx
f0101819:	2b 15 4c dc 17 f0    	sub    0xf017dc4c,%edx
f010181f:	c1 fa 03             	sar    $0x3,%edx
f0101822:	c1 e2 0c             	shl    $0xc,%edx
f0101825:	39 d0                	cmp    %edx,%eax
f0101827:	74 19                	je     f0101842 <mem_init+0x83e>
f0101829:	68 2c 4f 10 f0       	push   $0xf0104f2c
f010182e:	68 3b 54 10 f0       	push   $0xf010543b
f0101833:	68 66 03 00 00       	push   $0x366
f0101838:	68 15 54 10 f0       	push   $0xf0105415
f010183d:	e8 5e e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101842:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101847:	74 19                	je     f0101862 <mem_init+0x85e>
f0101849:	68 1c 56 10 f0       	push   $0xf010561c
f010184e:	68 3b 54 10 f0       	push   $0xf010543b
f0101853:	68 67 03 00 00       	push   $0x367
f0101858:	68 15 54 10 f0       	push   $0xf0105415
f010185d:	e8 3e e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101862:	83 ec 0c             	sub    $0xc,%esp
f0101865:	6a 00                	push   $0x0
f0101867:	e8 c7 f4 ff ff       	call   f0100d33 <page_alloc>
f010186c:	83 c4 10             	add    $0x10,%esp
f010186f:	85 c0                	test   %eax,%eax
f0101871:	74 19                	je     f010188c <mem_init+0x888>
f0101873:	68 a8 55 10 f0       	push   $0xf01055a8
f0101878:	68 3b 54 10 f0       	push   $0xf010543b
f010187d:	68 6a 03 00 00       	push   $0x36a
f0101882:	68 15 54 10 f0       	push   $0xf0105415
f0101887:	e8 14 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010188c:	6a 02                	push   $0x2
f010188e:	68 00 10 00 00       	push   $0x1000
f0101893:	56                   	push   %esi
f0101894:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f010189a:	e8 ed f6 ff ff       	call   f0100f8c <page_insert>
f010189f:	83 c4 10             	add    $0x10,%esp
f01018a2:	85 c0                	test   %eax,%eax
f01018a4:	74 19                	je     f01018bf <mem_init+0x8bb>
f01018a6:	68 f0 4e 10 f0       	push   $0xf0104ef0
f01018ab:	68 3b 54 10 f0       	push   $0xf010543b
f01018b0:	68 6d 03 00 00       	push   $0x36d
f01018b5:	68 15 54 10 f0       	push   $0xf0105415
f01018ba:	e8 e1 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018c4:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f01018c9:	e8 64 f0 ff ff       	call   f0100932 <check_va2pa>
f01018ce:	89 f2                	mov    %esi,%edx
f01018d0:	2b 15 4c dc 17 f0    	sub    0xf017dc4c,%edx
f01018d6:	c1 fa 03             	sar    $0x3,%edx
f01018d9:	c1 e2 0c             	shl    $0xc,%edx
f01018dc:	39 d0                	cmp    %edx,%eax
f01018de:	74 19                	je     f01018f9 <mem_init+0x8f5>
f01018e0:	68 2c 4f 10 f0       	push   $0xf0104f2c
f01018e5:	68 3b 54 10 f0       	push   $0xf010543b
f01018ea:	68 6e 03 00 00       	push   $0x36e
f01018ef:	68 15 54 10 f0       	push   $0xf0105415
f01018f4:	e8 a7 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01018f9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018fe:	74 19                	je     f0101919 <mem_init+0x915>
f0101900:	68 1c 56 10 f0       	push   $0xf010561c
f0101905:	68 3b 54 10 f0       	push   $0xf010543b
f010190a:	68 6f 03 00 00       	push   $0x36f
f010190f:	68 15 54 10 f0       	push   $0xf0105415
f0101914:	e8 87 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101919:	83 ec 0c             	sub    $0xc,%esp
f010191c:	6a 00                	push   $0x0
f010191e:	e8 10 f4 ff ff       	call   f0100d33 <page_alloc>
f0101923:	83 c4 10             	add    $0x10,%esp
f0101926:	85 c0                	test   %eax,%eax
f0101928:	74 19                	je     f0101943 <mem_init+0x93f>
f010192a:	68 a8 55 10 f0       	push   $0xf01055a8
f010192f:	68 3b 54 10 f0       	push   $0xf010543b
f0101934:	68 73 03 00 00       	push   $0x373
f0101939:	68 15 54 10 f0       	push   $0xf0105415
f010193e:	e8 5d e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101943:	8b 15 48 dc 17 f0    	mov    0xf017dc48,%edx
f0101949:	8b 02                	mov    (%edx),%eax
f010194b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101950:	89 c1                	mov    %eax,%ecx
f0101952:	c1 e9 0c             	shr    $0xc,%ecx
f0101955:	3b 0d 44 dc 17 f0    	cmp    0xf017dc44,%ecx
f010195b:	72 15                	jb     f0101972 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010195d:	50                   	push   %eax
f010195e:	68 58 4c 10 f0       	push   $0xf0104c58
f0101963:	68 76 03 00 00       	push   $0x376
f0101968:	68 15 54 10 f0       	push   $0xf0105415
f010196d:	e8 2e e7 ff ff       	call   f01000a0 <_panic>
f0101972:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101977:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010197a:	83 ec 04             	sub    $0x4,%esp
f010197d:	6a 00                	push   $0x0
f010197f:	68 00 10 00 00       	push   $0x1000
f0101984:	52                   	push   %edx
f0101985:	e8 7b f4 ff ff       	call   f0100e05 <pgdir_walk>
f010198a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010198d:	8d 57 04             	lea    0x4(%edi),%edx
f0101990:	83 c4 10             	add    $0x10,%esp
f0101993:	39 d0                	cmp    %edx,%eax
f0101995:	74 19                	je     f01019b0 <mem_init+0x9ac>
f0101997:	68 5c 4f 10 f0       	push   $0xf0104f5c
f010199c:	68 3b 54 10 f0       	push   $0xf010543b
f01019a1:	68 77 03 00 00       	push   $0x377
f01019a6:	68 15 54 10 f0       	push   $0xf0105415
f01019ab:	e8 f0 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019b0:	6a 06                	push   $0x6
f01019b2:	68 00 10 00 00       	push   $0x1000
f01019b7:	56                   	push   %esi
f01019b8:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f01019be:	e8 c9 f5 ff ff       	call   f0100f8c <page_insert>
f01019c3:	83 c4 10             	add    $0x10,%esp
f01019c6:	85 c0                	test   %eax,%eax
f01019c8:	74 19                	je     f01019e3 <mem_init+0x9df>
f01019ca:	68 9c 4f 10 f0       	push   $0xf0104f9c
f01019cf:	68 3b 54 10 f0       	push   $0xf010543b
f01019d4:	68 7a 03 00 00       	push   $0x37a
f01019d9:	68 15 54 10 f0       	push   $0xf0105415
f01019de:	e8 bd e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019e3:	8b 3d 48 dc 17 f0    	mov    0xf017dc48,%edi
f01019e9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019ee:	89 f8                	mov    %edi,%eax
f01019f0:	e8 3d ef ff ff       	call   f0100932 <check_va2pa>
f01019f5:	89 f2                	mov    %esi,%edx
f01019f7:	2b 15 4c dc 17 f0    	sub    0xf017dc4c,%edx
f01019fd:	c1 fa 03             	sar    $0x3,%edx
f0101a00:	c1 e2 0c             	shl    $0xc,%edx
f0101a03:	39 d0                	cmp    %edx,%eax
f0101a05:	74 19                	je     f0101a20 <mem_init+0xa1c>
f0101a07:	68 2c 4f 10 f0       	push   $0xf0104f2c
f0101a0c:	68 3b 54 10 f0       	push   $0xf010543b
f0101a11:	68 7b 03 00 00       	push   $0x37b
f0101a16:	68 15 54 10 f0       	push   $0xf0105415
f0101a1b:	e8 80 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a20:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a25:	74 19                	je     f0101a40 <mem_init+0xa3c>
f0101a27:	68 1c 56 10 f0       	push   $0xf010561c
f0101a2c:	68 3b 54 10 f0       	push   $0xf010543b
f0101a31:	68 7c 03 00 00       	push   $0x37c
f0101a36:	68 15 54 10 f0       	push   $0xf0105415
f0101a3b:	e8 60 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a40:	83 ec 04             	sub    $0x4,%esp
f0101a43:	6a 00                	push   $0x0
f0101a45:	68 00 10 00 00       	push   $0x1000
f0101a4a:	57                   	push   %edi
f0101a4b:	e8 b5 f3 ff ff       	call   f0100e05 <pgdir_walk>
f0101a50:	83 c4 10             	add    $0x10,%esp
f0101a53:	f6 00 04             	testb  $0x4,(%eax)
f0101a56:	75 19                	jne    f0101a71 <mem_init+0xa6d>
f0101a58:	68 dc 4f 10 f0       	push   $0xf0104fdc
f0101a5d:	68 3b 54 10 f0       	push   $0xf010543b
f0101a62:	68 7d 03 00 00       	push   $0x37d
f0101a67:	68 15 54 10 f0       	push   $0xf0105415
f0101a6c:	e8 2f e6 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a71:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f0101a76:	f6 00 04             	testb  $0x4,(%eax)
f0101a79:	75 19                	jne    f0101a94 <mem_init+0xa90>
f0101a7b:	68 2d 56 10 f0       	push   $0xf010562d
f0101a80:	68 3b 54 10 f0       	push   $0xf010543b
f0101a85:	68 7e 03 00 00       	push   $0x37e
f0101a8a:	68 15 54 10 f0       	push   $0xf0105415
f0101a8f:	e8 0c e6 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a94:	6a 02                	push   $0x2
f0101a96:	68 00 10 00 00       	push   $0x1000
f0101a9b:	56                   	push   %esi
f0101a9c:	50                   	push   %eax
f0101a9d:	e8 ea f4 ff ff       	call   f0100f8c <page_insert>
f0101aa2:	83 c4 10             	add    $0x10,%esp
f0101aa5:	85 c0                	test   %eax,%eax
f0101aa7:	74 19                	je     f0101ac2 <mem_init+0xabe>
f0101aa9:	68 f0 4e 10 f0       	push   $0xf0104ef0
f0101aae:	68 3b 54 10 f0       	push   $0xf010543b
f0101ab3:	68 81 03 00 00       	push   $0x381
f0101ab8:	68 15 54 10 f0       	push   $0xf0105415
f0101abd:	e8 de e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ac2:	83 ec 04             	sub    $0x4,%esp
f0101ac5:	6a 00                	push   $0x0
f0101ac7:	68 00 10 00 00       	push   $0x1000
f0101acc:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101ad2:	e8 2e f3 ff ff       	call   f0100e05 <pgdir_walk>
f0101ad7:	83 c4 10             	add    $0x10,%esp
f0101ada:	f6 00 02             	testb  $0x2,(%eax)
f0101add:	75 19                	jne    f0101af8 <mem_init+0xaf4>
f0101adf:	68 10 50 10 f0       	push   $0xf0105010
f0101ae4:	68 3b 54 10 f0       	push   $0xf010543b
f0101ae9:	68 82 03 00 00       	push   $0x382
f0101aee:	68 15 54 10 f0       	push   $0xf0105415
f0101af3:	e8 a8 e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101af8:	83 ec 04             	sub    $0x4,%esp
f0101afb:	6a 00                	push   $0x0
f0101afd:	68 00 10 00 00       	push   $0x1000
f0101b02:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101b08:	e8 f8 f2 ff ff       	call   f0100e05 <pgdir_walk>
f0101b0d:	83 c4 10             	add    $0x10,%esp
f0101b10:	f6 00 04             	testb  $0x4,(%eax)
f0101b13:	74 19                	je     f0101b2e <mem_init+0xb2a>
f0101b15:	68 44 50 10 f0       	push   $0xf0105044
f0101b1a:	68 3b 54 10 f0       	push   $0xf010543b
f0101b1f:	68 83 03 00 00       	push   $0x383
f0101b24:	68 15 54 10 f0       	push   $0xf0105415
f0101b29:	e8 72 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b2e:	6a 02                	push   $0x2
f0101b30:	68 00 00 40 00       	push   $0x400000
f0101b35:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b38:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101b3e:	e8 49 f4 ff ff       	call   f0100f8c <page_insert>
f0101b43:	83 c4 10             	add    $0x10,%esp
f0101b46:	85 c0                	test   %eax,%eax
f0101b48:	78 19                	js     f0101b63 <mem_init+0xb5f>
f0101b4a:	68 7c 50 10 f0       	push   $0xf010507c
f0101b4f:	68 3b 54 10 f0       	push   $0xf010543b
f0101b54:	68 86 03 00 00       	push   $0x386
f0101b59:	68 15 54 10 f0       	push   $0xf0105415
f0101b5e:	e8 3d e5 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b63:	6a 02                	push   $0x2
f0101b65:	68 00 10 00 00       	push   $0x1000
f0101b6a:	53                   	push   %ebx
f0101b6b:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101b71:	e8 16 f4 ff ff       	call   f0100f8c <page_insert>
f0101b76:	83 c4 10             	add    $0x10,%esp
f0101b79:	85 c0                	test   %eax,%eax
f0101b7b:	74 19                	je     f0101b96 <mem_init+0xb92>
f0101b7d:	68 b4 50 10 f0       	push   $0xf01050b4
f0101b82:	68 3b 54 10 f0       	push   $0xf010543b
f0101b87:	68 89 03 00 00       	push   $0x389
f0101b8c:	68 15 54 10 f0       	push   $0xf0105415
f0101b91:	e8 0a e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b96:	83 ec 04             	sub    $0x4,%esp
f0101b99:	6a 00                	push   $0x0
f0101b9b:	68 00 10 00 00       	push   $0x1000
f0101ba0:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101ba6:	e8 5a f2 ff ff       	call   f0100e05 <pgdir_walk>
f0101bab:	83 c4 10             	add    $0x10,%esp
f0101bae:	f6 00 04             	testb  $0x4,(%eax)
f0101bb1:	74 19                	je     f0101bcc <mem_init+0xbc8>
f0101bb3:	68 44 50 10 f0       	push   $0xf0105044
f0101bb8:	68 3b 54 10 f0       	push   $0xf010543b
f0101bbd:	68 8a 03 00 00       	push   $0x38a
f0101bc2:	68 15 54 10 f0       	push   $0xf0105415
f0101bc7:	e8 d4 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bcc:	8b 3d 48 dc 17 f0    	mov    0xf017dc48,%edi
f0101bd2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bd7:	89 f8                	mov    %edi,%eax
f0101bd9:	e8 54 ed ff ff       	call   f0100932 <check_va2pa>
f0101bde:	89 c1                	mov    %eax,%ecx
f0101be0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101be3:	89 d8                	mov    %ebx,%eax
f0101be5:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f0101beb:	c1 f8 03             	sar    $0x3,%eax
f0101bee:	c1 e0 0c             	shl    $0xc,%eax
f0101bf1:	39 c1                	cmp    %eax,%ecx
f0101bf3:	74 19                	je     f0101c0e <mem_init+0xc0a>
f0101bf5:	68 f0 50 10 f0       	push   $0xf01050f0
f0101bfa:	68 3b 54 10 f0       	push   $0xf010543b
f0101bff:	68 8d 03 00 00       	push   $0x38d
f0101c04:	68 15 54 10 f0       	push   $0xf0105415
f0101c09:	e8 92 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c0e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c13:	89 f8                	mov    %edi,%eax
f0101c15:	e8 18 ed ff ff       	call   f0100932 <check_va2pa>
f0101c1a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c1d:	74 19                	je     f0101c38 <mem_init+0xc34>
f0101c1f:	68 1c 51 10 f0       	push   $0xf010511c
f0101c24:	68 3b 54 10 f0       	push   $0xf010543b
f0101c29:	68 8e 03 00 00       	push   $0x38e
f0101c2e:	68 15 54 10 f0       	push   $0xf0105415
f0101c33:	e8 68 e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c38:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c3d:	74 19                	je     f0101c58 <mem_init+0xc54>
f0101c3f:	68 43 56 10 f0       	push   $0xf0105643
f0101c44:	68 3b 54 10 f0       	push   $0xf010543b
f0101c49:	68 90 03 00 00       	push   $0x390
f0101c4e:	68 15 54 10 f0       	push   $0xf0105415
f0101c53:	e8 48 e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c58:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c5d:	74 19                	je     f0101c78 <mem_init+0xc74>
f0101c5f:	68 54 56 10 f0       	push   $0xf0105654
f0101c64:	68 3b 54 10 f0       	push   $0xf010543b
f0101c69:	68 91 03 00 00       	push   $0x391
f0101c6e:	68 15 54 10 f0       	push   $0xf0105415
f0101c73:	e8 28 e4 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c78:	83 ec 0c             	sub    $0xc,%esp
f0101c7b:	6a 00                	push   $0x0
f0101c7d:	e8 b1 f0 ff ff       	call   f0100d33 <page_alloc>
f0101c82:	83 c4 10             	add    $0x10,%esp
f0101c85:	85 c0                	test   %eax,%eax
f0101c87:	74 04                	je     f0101c8d <mem_init+0xc89>
f0101c89:	39 c6                	cmp    %eax,%esi
f0101c8b:	74 19                	je     f0101ca6 <mem_init+0xca2>
f0101c8d:	68 4c 51 10 f0       	push   $0xf010514c
f0101c92:	68 3b 54 10 f0       	push   $0xf010543b
f0101c97:	68 94 03 00 00       	push   $0x394
f0101c9c:	68 15 54 10 f0       	push   $0xf0105415
f0101ca1:	e8 fa e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ca6:	83 ec 08             	sub    $0x8,%esp
f0101ca9:	6a 00                	push   $0x0
f0101cab:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101cb1:	e8 9b f2 ff ff       	call   f0100f51 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cb6:	8b 3d 48 dc 17 f0    	mov    0xf017dc48,%edi
f0101cbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cc1:	89 f8                	mov    %edi,%eax
f0101cc3:	e8 6a ec ff ff       	call   f0100932 <check_va2pa>
f0101cc8:	83 c4 10             	add    $0x10,%esp
f0101ccb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cce:	74 19                	je     f0101ce9 <mem_init+0xce5>
f0101cd0:	68 70 51 10 f0       	push   $0xf0105170
f0101cd5:	68 3b 54 10 f0       	push   $0xf010543b
f0101cda:	68 98 03 00 00       	push   $0x398
f0101cdf:	68 15 54 10 f0       	push   $0xf0105415
f0101ce4:	e8 b7 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ce9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cee:	89 f8                	mov    %edi,%eax
f0101cf0:	e8 3d ec ff ff       	call   f0100932 <check_va2pa>
f0101cf5:	89 da                	mov    %ebx,%edx
f0101cf7:	2b 15 4c dc 17 f0    	sub    0xf017dc4c,%edx
f0101cfd:	c1 fa 03             	sar    $0x3,%edx
f0101d00:	c1 e2 0c             	shl    $0xc,%edx
f0101d03:	39 d0                	cmp    %edx,%eax
f0101d05:	74 19                	je     f0101d20 <mem_init+0xd1c>
f0101d07:	68 1c 51 10 f0       	push   $0xf010511c
f0101d0c:	68 3b 54 10 f0       	push   $0xf010543b
f0101d11:	68 99 03 00 00       	push   $0x399
f0101d16:	68 15 54 10 f0       	push   $0xf0105415
f0101d1b:	e8 80 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d20:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d25:	74 19                	je     f0101d40 <mem_init+0xd3c>
f0101d27:	68 fa 55 10 f0       	push   $0xf01055fa
f0101d2c:	68 3b 54 10 f0       	push   $0xf010543b
f0101d31:	68 9a 03 00 00       	push   $0x39a
f0101d36:	68 15 54 10 f0       	push   $0xf0105415
f0101d3b:	e8 60 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d40:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d45:	74 19                	je     f0101d60 <mem_init+0xd5c>
f0101d47:	68 54 56 10 f0       	push   $0xf0105654
f0101d4c:	68 3b 54 10 f0       	push   $0xf010543b
f0101d51:	68 9b 03 00 00       	push   $0x39b
f0101d56:	68 15 54 10 f0       	push   $0xf0105415
f0101d5b:	e8 40 e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d60:	6a 00                	push   $0x0
f0101d62:	68 00 10 00 00       	push   $0x1000
f0101d67:	53                   	push   %ebx
f0101d68:	57                   	push   %edi
f0101d69:	e8 1e f2 ff ff       	call   f0100f8c <page_insert>
f0101d6e:	83 c4 10             	add    $0x10,%esp
f0101d71:	85 c0                	test   %eax,%eax
f0101d73:	74 19                	je     f0101d8e <mem_init+0xd8a>
f0101d75:	68 94 51 10 f0       	push   $0xf0105194
f0101d7a:	68 3b 54 10 f0       	push   $0xf010543b
f0101d7f:	68 9e 03 00 00       	push   $0x39e
f0101d84:	68 15 54 10 f0       	push   $0xf0105415
f0101d89:	e8 12 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101d8e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d93:	75 19                	jne    f0101dae <mem_init+0xdaa>
f0101d95:	68 65 56 10 f0       	push   $0xf0105665
f0101d9a:	68 3b 54 10 f0       	push   $0xf010543b
f0101d9f:	68 9f 03 00 00       	push   $0x39f
f0101da4:	68 15 54 10 f0       	push   $0xf0105415
f0101da9:	e8 f2 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101dae:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101db1:	74 19                	je     f0101dcc <mem_init+0xdc8>
f0101db3:	68 71 56 10 f0       	push   $0xf0105671
f0101db8:	68 3b 54 10 f0       	push   $0xf010543b
f0101dbd:	68 a0 03 00 00       	push   $0x3a0
f0101dc2:	68 15 54 10 f0       	push   $0xf0105415
f0101dc7:	e8 d4 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dcc:	83 ec 08             	sub    $0x8,%esp
f0101dcf:	68 00 10 00 00       	push   $0x1000
f0101dd4:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101dda:	e8 72 f1 ff ff       	call   f0100f51 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ddf:	8b 3d 48 dc 17 f0    	mov    0xf017dc48,%edi
f0101de5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dea:	89 f8                	mov    %edi,%eax
f0101dec:	e8 41 eb ff ff       	call   f0100932 <check_va2pa>
f0101df1:	83 c4 10             	add    $0x10,%esp
f0101df4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df7:	74 19                	je     f0101e12 <mem_init+0xe0e>
f0101df9:	68 70 51 10 f0       	push   $0xf0105170
f0101dfe:	68 3b 54 10 f0       	push   $0xf010543b
f0101e03:	68 a4 03 00 00       	push   $0x3a4
f0101e08:	68 15 54 10 f0       	push   $0xf0105415
f0101e0d:	e8 8e e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e12:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e17:	89 f8                	mov    %edi,%eax
f0101e19:	e8 14 eb ff ff       	call   f0100932 <check_va2pa>
f0101e1e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e21:	74 19                	je     f0101e3c <mem_init+0xe38>
f0101e23:	68 cc 51 10 f0       	push   $0xf01051cc
f0101e28:	68 3b 54 10 f0       	push   $0xf010543b
f0101e2d:	68 a5 03 00 00       	push   $0x3a5
f0101e32:	68 15 54 10 f0       	push   $0xf0105415
f0101e37:	e8 64 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e3c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e41:	74 19                	je     f0101e5c <mem_init+0xe58>
f0101e43:	68 86 56 10 f0       	push   $0xf0105686
f0101e48:	68 3b 54 10 f0       	push   $0xf010543b
f0101e4d:	68 a6 03 00 00       	push   $0x3a6
f0101e52:	68 15 54 10 f0       	push   $0xf0105415
f0101e57:	e8 44 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e5c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e61:	74 19                	je     f0101e7c <mem_init+0xe78>
f0101e63:	68 54 56 10 f0       	push   $0xf0105654
f0101e68:	68 3b 54 10 f0       	push   $0xf010543b
f0101e6d:	68 a7 03 00 00       	push   $0x3a7
f0101e72:	68 15 54 10 f0       	push   $0xf0105415
f0101e77:	e8 24 e2 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e7c:	83 ec 0c             	sub    $0xc,%esp
f0101e7f:	6a 00                	push   $0x0
f0101e81:	e8 ad ee ff ff       	call   f0100d33 <page_alloc>
f0101e86:	83 c4 10             	add    $0x10,%esp
f0101e89:	39 c3                	cmp    %eax,%ebx
f0101e8b:	75 04                	jne    f0101e91 <mem_init+0xe8d>
f0101e8d:	85 c0                	test   %eax,%eax
f0101e8f:	75 19                	jne    f0101eaa <mem_init+0xea6>
f0101e91:	68 f4 51 10 f0       	push   $0xf01051f4
f0101e96:	68 3b 54 10 f0       	push   $0xf010543b
f0101e9b:	68 aa 03 00 00       	push   $0x3aa
f0101ea0:	68 15 54 10 f0       	push   $0xf0105415
f0101ea5:	e8 f6 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101eaa:	83 ec 0c             	sub    $0xc,%esp
f0101ead:	6a 00                	push   $0x0
f0101eaf:	e8 7f ee ff ff       	call   f0100d33 <page_alloc>
f0101eb4:	83 c4 10             	add    $0x10,%esp
f0101eb7:	85 c0                	test   %eax,%eax
f0101eb9:	74 19                	je     f0101ed4 <mem_init+0xed0>
f0101ebb:	68 a8 55 10 f0       	push   $0xf01055a8
f0101ec0:	68 3b 54 10 f0       	push   $0xf010543b
f0101ec5:	68 ad 03 00 00       	push   $0x3ad
f0101eca:	68 15 54 10 f0       	push   $0xf0105415
f0101ecf:	e8 cc e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ed4:	8b 0d 48 dc 17 f0    	mov    0xf017dc48,%ecx
f0101eda:	8b 11                	mov    (%ecx),%edx
f0101edc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ee2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee5:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f0101eeb:	c1 f8 03             	sar    $0x3,%eax
f0101eee:	c1 e0 0c             	shl    $0xc,%eax
f0101ef1:	39 c2                	cmp    %eax,%edx
f0101ef3:	74 19                	je     f0101f0e <mem_init+0xf0a>
f0101ef5:	68 98 4e 10 f0       	push   $0xf0104e98
f0101efa:	68 3b 54 10 f0       	push   $0xf010543b
f0101eff:	68 b0 03 00 00       	push   $0x3b0
f0101f04:	68 15 54 10 f0       	push   $0xf0105415
f0101f09:	e8 92 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f0e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f17:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f1c:	74 19                	je     f0101f37 <mem_init+0xf33>
f0101f1e:	68 0b 56 10 f0       	push   $0xf010560b
f0101f23:	68 3b 54 10 f0       	push   $0xf010543b
f0101f28:	68 b2 03 00 00       	push   $0x3b2
f0101f2d:	68 15 54 10 f0       	push   $0xf0105415
f0101f32:	e8 69 e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f3a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f40:	83 ec 0c             	sub    $0xc,%esp
f0101f43:	50                   	push   %eax
f0101f44:	e8 5a ee ff ff       	call   f0100da3 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f49:	83 c4 0c             	add    $0xc,%esp
f0101f4c:	6a 01                	push   $0x1
f0101f4e:	68 00 10 40 00       	push   $0x401000
f0101f53:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0101f59:	e8 a7 ee ff ff       	call   f0100e05 <pgdir_walk>
f0101f5e:	89 c7                	mov    %eax,%edi
f0101f60:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f63:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f0101f68:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f6b:	8b 40 04             	mov    0x4(%eax),%eax
f0101f6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f73:	8b 0d 44 dc 17 f0    	mov    0xf017dc44,%ecx
f0101f79:	89 c2                	mov    %eax,%edx
f0101f7b:	c1 ea 0c             	shr    $0xc,%edx
f0101f7e:	83 c4 10             	add    $0x10,%esp
f0101f81:	39 ca                	cmp    %ecx,%edx
f0101f83:	72 15                	jb     f0101f9a <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f85:	50                   	push   %eax
f0101f86:	68 58 4c 10 f0       	push   $0xf0104c58
f0101f8b:	68 b9 03 00 00       	push   $0x3b9
f0101f90:	68 15 54 10 f0       	push   $0xf0105415
f0101f95:	e8 06 e1 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f9a:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f9f:	39 c7                	cmp    %eax,%edi
f0101fa1:	74 19                	je     f0101fbc <mem_init+0xfb8>
f0101fa3:	68 97 56 10 f0       	push   $0xf0105697
f0101fa8:	68 3b 54 10 f0       	push   $0xf010543b
f0101fad:	68 ba 03 00 00       	push   $0x3ba
f0101fb2:	68 15 54 10 f0       	push   $0xf0105415
f0101fb7:	e8 e4 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fbc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fbf:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fc6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fcf:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f0101fd5:	c1 f8 03             	sar    $0x3,%eax
f0101fd8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fdb:	89 c2                	mov    %eax,%edx
f0101fdd:	c1 ea 0c             	shr    $0xc,%edx
f0101fe0:	39 d1                	cmp    %edx,%ecx
f0101fe2:	77 12                	ja     f0101ff6 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe4:	50                   	push   %eax
f0101fe5:	68 58 4c 10 f0       	push   $0xf0104c58
f0101fea:	6a 56                	push   $0x56
f0101fec:	68 21 54 10 f0       	push   $0xf0105421
f0101ff1:	e8 aa e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ff6:	83 ec 04             	sub    $0x4,%esp
f0101ff9:	68 00 10 00 00       	push   $0x1000
f0101ffe:	68 ff 00 00 00       	push   $0xff
f0102003:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102008:	50                   	push   %eax
f0102009:	e8 b1 22 00 00       	call   f01042bf <memset>
	page_free(pp0);
f010200e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102011:	89 3c 24             	mov    %edi,(%esp)
f0102014:	e8 8a ed ff ff       	call   f0100da3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102019:	83 c4 0c             	add    $0xc,%esp
f010201c:	6a 01                	push   $0x1
f010201e:	6a 00                	push   $0x0
f0102020:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0102026:	e8 da ed ff ff       	call   f0100e05 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010202b:	89 fa                	mov    %edi,%edx
f010202d:	2b 15 4c dc 17 f0    	sub    0xf017dc4c,%edx
f0102033:	c1 fa 03             	sar    $0x3,%edx
f0102036:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102039:	89 d0                	mov    %edx,%eax
f010203b:	c1 e8 0c             	shr    $0xc,%eax
f010203e:	83 c4 10             	add    $0x10,%esp
f0102041:	3b 05 44 dc 17 f0    	cmp    0xf017dc44,%eax
f0102047:	72 12                	jb     f010205b <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102049:	52                   	push   %edx
f010204a:	68 58 4c 10 f0       	push   $0xf0104c58
f010204f:	6a 56                	push   $0x56
f0102051:	68 21 54 10 f0       	push   $0xf0105421
f0102056:	e8 45 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010205b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102061:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102064:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010206a:	f6 00 01             	testb  $0x1,(%eax)
f010206d:	74 19                	je     f0102088 <mem_init+0x1084>
f010206f:	68 af 56 10 f0       	push   $0xf01056af
f0102074:	68 3b 54 10 f0       	push   $0xf010543b
f0102079:	68 c4 03 00 00       	push   $0x3c4
f010207e:	68 15 54 10 f0       	push   $0xf0105415
f0102083:	e8 18 e0 ff ff       	call   f01000a0 <_panic>
f0102088:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010208b:	39 c2                	cmp    %eax,%edx
f010208d:	75 db                	jne    f010206a <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010208f:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f0102094:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010209a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020a3:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020a6:	89 3d 80 cf 17 f0    	mov    %edi,0xf017cf80

	// free the pages we took
	page_free(pp0);
f01020ac:	83 ec 0c             	sub    $0xc,%esp
f01020af:	50                   	push   %eax
f01020b0:	e8 ee ec ff ff       	call   f0100da3 <page_free>
	page_free(pp1);
f01020b5:	89 1c 24             	mov    %ebx,(%esp)
f01020b8:	e8 e6 ec ff ff       	call   f0100da3 <page_free>
	page_free(pp2);
f01020bd:	89 34 24             	mov    %esi,(%esp)
f01020c0:	e8 de ec ff ff       	call   f0100da3 <page_free>

	cprintf("check_page() succeeded!\n");
f01020c5:	c7 04 24 c6 56 10 f0 	movl   $0xf01056c6,(%esp)
f01020cc:	e8 5d 0e 00 00       	call   f0102f2e <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01020d1:	a1 4c dc 17 f0       	mov    0xf017dc4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020d6:	83 c4 10             	add    $0x10,%esp
f01020d9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020de:	77 15                	ja     f01020f5 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020e0:	50                   	push   %eax
f01020e1:	68 9c 4d 10 f0       	push   $0xf0104d9c
f01020e6:	68 b6 00 00 00       	push   $0xb6
f01020eb:	68 15 54 10 f0       	push   $0xf0105415
f01020f0:	e8 ab df ff ff       	call   f01000a0 <_panic>
f01020f5:	83 ec 08             	sub    $0x8,%esp
f01020f8:	6a 04                	push   $0x4
f01020fa:	05 00 00 00 10       	add    $0x10000000,%eax
f01020ff:	50                   	push   %eax
f0102100:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102105:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010210a:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f010210f:	e8 84 ed ff ff       	call   f0100e98 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U); 
f0102114:	a1 8c cf 17 f0       	mov    0xf017cf8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102119:	83 c4 10             	add    $0x10,%esp
f010211c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102121:	77 15                	ja     f0102138 <mem_init+0x1134>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102123:	50                   	push   %eax
f0102124:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102129:	68 be 00 00 00       	push   $0xbe
f010212e:	68 15 54 10 f0       	push   $0xf0105415
f0102133:	e8 68 df ff ff       	call   f01000a0 <_panic>
f0102138:	83 ec 08             	sub    $0x8,%esp
f010213b:	6a 04                	push   $0x4
f010213d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102142:	50                   	push   %eax
f0102143:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102148:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010214d:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f0102152:	e8 41 ed ff ff       	call   f0100e98 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102157:	83 c4 10             	add    $0x10,%esp
f010215a:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f010215f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102164:	77 15                	ja     f010217b <mem_init+0x1177>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102166:	50                   	push   %eax
f0102167:	68 9c 4d 10 f0       	push   $0xf0104d9c
f010216c:	68 ca 00 00 00       	push   $0xca
f0102171:	68 15 54 10 f0       	push   $0xf0105415
f0102176:	e8 25 df ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010217b:	83 ec 08             	sub    $0x8,%esp
f010217e:	6a 02                	push   $0x2
f0102180:	68 00 10 11 00       	push   $0x111000
f0102185:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010218a:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010218f:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f0102194:	e8 ff ec ff ff       	call   f0100e98 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102199:	83 c4 08             	add    $0x8,%esp
f010219c:	6a 02                	push   $0x2
f010219e:	6a 00                	push   $0x0
f01021a0:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021a5:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021aa:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
f01021af:	e8 e4 ec ff ff       	call   f0100e98 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021b4:	8b 1d 48 dc 17 f0    	mov    0xf017dc48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021ba:	a1 44 dc 17 f0       	mov    0xf017dc44,%eax
f01021bf:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021c2:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01021c9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01021ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021d1:	8b 3d 4c dc 17 f0    	mov    0xf017dc4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01021d7:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01021da:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021dd:	be 00 00 00 00       	mov    $0x0,%esi
f01021e2:	eb 55                	jmp    f0102239 <mem_init+0x1235>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021e4:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f01021ea:	89 d8                	mov    %ebx,%eax
f01021ec:	e8 41 e7 ff ff       	call   f0100932 <check_va2pa>
f01021f1:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021f8:	77 15                	ja     f010220f <mem_init+0x120b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021fa:	57                   	push   %edi
f01021fb:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102200:	68 01 03 00 00       	push   $0x301
f0102205:	68 15 54 10 f0       	push   $0xf0105415
f010220a:	e8 91 de ff ff       	call   f01000a0 <_panic>
f010220f:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102216:	39 d0                	cmp    %edx,%eax
f0102218:	74 19                	je     f0102233 <mem_init+0x122f>
f010221a:	68 18 52 10 f0       	push   $0xf0105218
f010221f:	68 3b 54 10 f0       	push   $0xf010543b
f0102224:	68 01 03 00 00       	push   $0x301
f0102229:	68 15 54 10 f0       	push   $0xf0105415
f010222e:	e8 6d de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102233:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102239:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010223c:	77 a6                	ja     f01021e4 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010223e:	8b 3d 8c cf 17 f0    	mov    0xf017cf8c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102244:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102247:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010224c:	89 f2                	mov    %esi,%edx
f010224e:	89 d8                	mov    %ebx,%eax
f0102250:	e8 dd e6 ff ff       	call   f0100932 <check_va2pa>
f0102255:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010225c:	77 15                	ja     f0102273 <mem_init+0x126f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010225e:	57                   	push   %edi
f010225f:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102264:	68 06 03 00 00       	push   $0x306
f0102269:	68 15 54 10 f0       	push   $0xf0105415
f010226e:	e8 2d de ff ff       	call   f01000a0 <_panic>
f0102273:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f010227a:	39 c2                	cmp    %eax,%edx
f010227c:	74 19                	je     f0102297 <mem_init+0x1293>
f010227e:	68 4c 52 10 f0       	push   $0xf010524c
f0102283:	68 3b 54 10 f0       	push   $0xf010543b
f0102288:	68 06 03 00 00       	push   $0x306
f010228d:	68 15 54 10 f0       	push   $0xf0105415
f0102292:	e8 09 de ff ff       	call   f01000a0 <_panic>
f0102297:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010229d:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01022a3:	75 a7                	jne    f010224c <mem_init+0x1248>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022a5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022a8:	c1 e7 0c             	shl    $0xc,%edi
f01022ab:	be 00 00 00 00       	mov    $0x0,%esi
f01022b0:	eb 30                	jmp    f01022e2 <mem_init+0x12de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01022b2:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01022b8:	89 d8                	mov    %ebx,%eax
f01022ba:	e8 73 e6 ff ff       	call   f0100932 <check_va2pa>
f01022bf:	39 c6                	cmp    %eax,%esi
f01022c1:	74 19                	je     f01022dc <mem_init+0x12d8>
f01022c3:	68 80 52 10 f0       	push   $0xf0105280
f01022c8:	68 3b 54 10 f0       	push   $0xf010543b
f01022cd:	68 0a 03 00 00       	push   $0x30a
f01022d2:	68 15 54 10 f0       	push   $0xf0105415
f01022d7:	e8 c4 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022dc:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01022e2:	39 fe                	cmp    %edi,%esi
f01022e4:	72 cc                	jb     f01022b2 <mem_init+0x12ae>
f01022e6:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01022eb:	89 f2                	mov    %esi,%edx
f01022ed:	89 d8                	mov    %ebx,%eax
f01022ef:	e8 3e e6 ff ff       	call   f0100932 <check_va2pa>
f01022f4:	8d 96 00 90 11 10    	lea    0x10119000(%esi),%edx
f01022fa:	39 c2                	cmp    %eax,%edx
f01022fc:	74 19                	je     f0102317 <mem_init+0x1313>
f01022fe:	68 a8 52 10 f0       	push   $0xf01052a8
f0102303:	68 3b 54 10 f0       	push   $0xf010543b
f0102308:	68 0e 03 00 00       	push   $0x30e
f010230d:	68 15 54 10 f0       	push   $0xf0105415
f0102312:	e8 89 dd ff ff       	call   f01000a0 <_panic>
f0102317:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010231d:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102323:	75 c6                	jne    f01022eb <mem_init+0x12e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102325:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010232a:	89 d8                	mov    %ebx,%eax
f010232c:	e8 01 e6 ff ff       	call   f0100932 <check_va2pa>
f0102331:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102334:	74 51                	je     f0102387 <mem_init+0x1383>
f0102336:	68 f0 52 10 f0       	push   $0xf01052f0
f010233b:	68 3b 54 10 f0       	push   $0xf010543b
f0102340:	68 0f 03 00 00       	push   $0x30f
f0102345:	68 15 54 10 f0       	push   $0xf0105415
f010234a:	e8 51 dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010234f:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102354:	72 36                	jb     f010238c <mem_init+0x1388>
f0102356:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010235b:	76 07                	jbe    f0102364 <mem_init+0x1360>
f010235d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102362:	75 28                	jne    f010238c <mem_init+0x1388>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102364:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102368:	0f 85 83 00 00 00    	jne    f01023f1 <mem_init+0x13ed>
f010236e:	68 df 56 10 f0       	push   $0xf01056df
f0102373:	68 3b 54 10 f0       	push   $0xf010543b
f0102378:	68 18 03 00 00       	push   $0x318
f010237d:	68 15 54 10 f0       	push   $0xf0105415
f0102382:	e8 19 dd ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102387:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010238c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102391:	76 3f                	jbe    f01023d2 <mem_init+0x13ce>
				assert(pgdir[i] & PTE_P);
f0102393:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102396:	f6 c2 01             	test   $0x1,%dl
f0102399:	75 19                	jne    f01023b4 <mem_init+0x13b0>
f010239b:	68 df 56 10 f0       	push   $0xf01056df
f01023a0:	68 3b 54 10 f0       	push   $0xf010543b
f01023a5:	68 1c 03 00 00       	push   $0x31c
f01023aa:	68 15 54 10 f0       	push   $0xf0105415
f01023af:	e8 ec dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01023b4:	f6 c2 02             	test   $0x2,%dl
f01023b7:	75 38                	jne    f01023f1 <mem_init+0x13ed>
f01023b9:	68 f0 56 10 f0       	push   $0xf01056f0
f01023be:	68 3b 54 10 f0       	push   $0xf010543b
f01023c3:	68 1d 03 00 00       	push   $0x31d
f01023c8:	68 15 54 10 f0       	push   $0xf0105415
f01023cd:	e8 ce dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f01023d2:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01023d6:	74 19                	je     f01023f1 <mem_init+0x13ed>
f01023d8:	68 01 57 10 f0       	push   $0xf0105701
f01023dd:	68 3b 54 10 f0       	push   $0xf010543b
f01023e2:	68 1f 03 00 00       	push   $0x31f
f01023e7:	68 15 54 10 f0       	push   $0xf0105415
f01023ec:	e8 af dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023f1:	83 c0 01             	add    $0x1,%eax
f01023f4:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023f9:	0f 86 50 ff ff ff    	jbe    f010234f <mem_init+0x134b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01023ff:	83 ec 0c             	sub    $0xc,%esp
f0102402:	68 20 53 10 f0       	push   $0xf0105320
f0102407:	e8 22 0b 00 00       	call   f0102f2e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010240c:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102411:	83 c4 10             	add    $0x10,%esp
f0102414:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102419:	77 15                	ja     f0102430 <mem_init+0x142c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010241b:	50                   	push   %eax
f010241c:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102421:	68 de 00 00 00       	push   $0xde
f0102426:	68 15 54 10 f0       	push   $0xf0105415
f010242b:	e8 70 dc ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102430:	05 00 00 00 10       	add    $0x10000000,%eax
f0102435:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102438:	b8 00 00 00 00       	mov    $0x0,%eax
f010243d:	e8 54 e5 ff ff       	call   f0100996 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102442:	0f 20 c0             	mov    %cr0,%eax
f0102445:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102448:	0d 23 00 05 80       	or     $0x80050023,%eax
f010244d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102450:	83 ec 0c             	sub    $0xc,%esp
f0102453:	6a 00                	push   $0x0
f0102455:	e8 d9 e8 ff ff       	call   f0100d33 <page_alloc>
f010245a:	89 c3                	mov    %eax,%ebx
f010245c:	83 c4 10             	add    $0x10,%esp
f010245f:	85 c0                	test   %eax,%eax
f0102461:	75 19                	jne    f010247c <mem_init+0x1478>
f0102463:	68 fd 54 10 f0       	push   $0xf01054fd
f0102468:	68 3b 54 10 f0       	push   $0xf010543b
f010246d:	68 df 03 00 00       	push   $0x3df
f0102472:	68 15 54 10 f0       	push   $0xf0105415
f0102477:	e8 24 dc ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f010247c:	83 ec 0c             	sub    $0xc,%esp
f010247f:	6a 00                	push   $0x0
f0102481:	e8 ad e8 ff ff       	call   f0100d33 <page_alloc>
f0102486:	89 c7                	mov    %eax,%edi
f0102488:	83 c4 10             	add    $0x10,%esp
f010248b:	85 c0                	test   %eax,%eax
f010248d:	75 19                	jne    f01024a8 <mem_init+0x14a4>
f010248f:	68 13 55 10 f0       	push   $0xf0105513
f0102494:	68 3b 54 10 f0       	push   $0xf010543b
f0102499:	68 e0 03 00 00       	push   $0x3e0
f010249e:	68 15 54 10 f0       	push   $0xf0105415
f01024a3:	e8 f8 db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01024a8:	83 ec 0c             	sub    $0xc,%esp
f01024ab:	6a 00                	push   $0x0
f01024ad:	e8 81 e8 ff ff       	call   f0100d33 <page_alloc>
f01024b2:	89 c6                	mov    %eax,%esi
f01024b4:	83 c4 10             	add    $0x10,%esp
f01024b7:	85 c0                	test   %eax,%eax
f01024b9:	75 19                	jne    f01024d4 <mem_init+0x14d0>
f01024bb:	68 29 55 10 f0       	push   $0xf0105529
f01024c0:	68 3b 54 10 f0       	push   $0xf010543b
f01024c5:	68 e1 03 00 00       	push   $0x3e1
f01024ca:	68 15 54 10 f0       	push   $0xf0105415
f01024cf:	e8 cc db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f01024d4:	83 ec 0c             	sub    $0xc,%esp
f01024d7:	53                   	push   %ebx
f01024d8:	e8 c6 e8 ff ff       	call   f0100da3 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024dd:	89 f8                	mov    %edi,%eax
f01024df:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f01024e5:	c1 f8 03             	sar    $0x3,%eax
f01024e8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024eb:	89 c2                	mov    %eax,%edx
f01024ed:	c1 ea 0c             	shr    $0xc,%edx
f01024f0:	83 c4 10             	add    $0x10,%esp
f01024f3:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f01024f9:	72 12                	jb     f010250d <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024fb:	50                   	push   %eax
f01024fc:	68 58 4c 10 f0       	push   $0xf0104c58
f0102501:	6a 56                	push   $0x56
f0102503:	68 21 54 10 f0       	push   $0xf0105421
f0102508:	e8 93 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010250d:	83 ec 04             	sub    $0x4,%esp
f0102510:	68 00 10 00 00       	push   $0x1000
f0102515:	6a 01                	push   $0x1
f0102517:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010251c:	50                   	push   %eax
f010251d:	e8 9d 1d 00 00       	call   f01042bf <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102522:	89 f0                	mov    %esi,%eax
f0102524:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f010252a:	c1 f8 03             	sar    $0x3,%eax
f010252d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102530:	89 c2                	mov    %eax,%edx
f0102532:	c1 ea 0c             	shr    $0xc,%edx
f0102535:	83 c4 10             	add    $0x10,%esp
f0102538:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f010253e:	72 12                	jb     f0102552 <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102540:	50                   	push   %eax
f0102541:	68 58 4c 10 f0       	push   $0xf0104c58
f0102546:	6a 56                	push   $0x56
f0102548:	68 21 54 10 f0       	push   $0xf0105421
f010254d:	e8 4e db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102552:	83 ec 04             	sub    $0x4,%esp
f0102555:	68 00 10 00 00       	push   $0x1000
f010255a:	6a 02                	push   $0x2
f010255c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102561:	50                   	push   %eax
f0102562:	e8 58 1d 00 00       	call   f01042bf <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102567:	6a 02                	push   $0x2
f0102569:	68 00 10 00 00       	push   $0x1000
f010256e:	57                   	push   %edi
f010256f:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f0102575:	e8 12 ea ff ff       	call   f0100f8c <page_insert>
	assert(pp1->pp_ref == 1);
f010257a:	83 c4 20             	add    $0x20,%esp
f010257d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102582:	74 19                	je     f010259d <mem_init+0x1599>
f0102584:	68 fa 55 10 f0       	push   $0xf01055fa
f0102589:	68 3b 54 10 f0       	push   $0xf010543b
f010258e:	68 e6 03 00 00       	push   $0x3e6
f0102593:	68 15 54 10 f0       	push   $0xf0105415
f0102598:	e8 03 db ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010259d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01025a4:	01 01 01 
f01025a7:	74 19                	je     f01025c2 <mem_init+0x15be>
f01025a9:	68 40 53 10 f0       	push   $0xf0105340
f01025ae:	68 3b 54 10 f0       	push   $0xf010543b
f01025b3:	68 e7 03 00 00       	push   $0x3e7
f01025b8:	68 15 54 10 f0       	push   $0xf0105415
f01025bd:	e8 de da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01025c2:	6a 02                	push   $0x2
f01025c4:	68 00 10 00 00       	push   $0x1000
f01025c9:	56                   	push   %esi
f01025ca:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f01025d0:	e8 b7 e9 ff ff       	call   f0100f8c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01025d5:	83 c4 10             	add    $0x10,%esp
f01025d8:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01025df:	02 02 02 
f01025e2:	74 19                	je     f01025fd <mem_init+0x15f9>
f01025e4:	68 64 53 10 f0       	push   $0xf0105364
f01025e9:	68 3b 54 10 f0       	push   $0xf010543b
f01025ee:	68 e9 03 00 00       	push   $0x3e9
f01025f3:	68 15 54 10 f0       	push   $0xf0105415
f01025f8:	e8 a3 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f01025fd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102602:	74 19                	je     f010261d <mem_init+0x1619>
f0102604:	68 1c 56 10 f0       	push   $0xf010561c
f0102609:	68 3b 54 10 f0       	push   $0xf010543b
f010260e:	68 ea 03 00 00       	push   $0x3ea
f0102613:	68 15 54 10 f0       	push   $0xf0105415
f0102618:	e8 83 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010261d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102622:	74 19                	je     f010263d <mem_init+0x1639>
f0102624:	68 86 56 10 f0       	push   $0xf0105686
f0102629:	68 3b 54 10 f0       	push   $0xf010543b
f010262e:	68 eb 03 00 00       	push   $0x3eb
f0102633:	68 15 54 10 f0       	push   $0xf0105415
f0102638:	e8 63 da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010263d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102644:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102647:	89 f0                	mov    %esi,%eax
f0102649:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f010264f:	c1 f8 03             	sar    $0x3,%eax
f0102652:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102655:	89 c2                	mov    %eax,%edx
f0102657:	c1 ea 0c             	shr    $0xc,%edx
f010265a:	3b 15 44 dc 17 f0    	cmp    0xf017dc44,%edx
f0102660:	72 12                	jb     f0102674 <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102662:	50                   	push   %eax
f0102663:	68 58 4c 10 f0       	push   $0xf0104c58
f0102668:	6a 56                	push   $0x56
f010266a:	68 21 54 10 f0       	push   $0xf0105421
f010266f:	e8 2c da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102674:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010267b:	03 03 03 
f010267e:	74 19                	je     f0102699 <mem_init+0x1695>
f0102680:	68 88 53 10 f0       	push   $0xf0105388
f0102685:	68 3b 54 10 f0       	push   $0xf010543b
f010268a:	68 ed 03 00 00       	push   $0x3ed
f010268f:	68 15 54 10 f0       	push   $0xf0105415
f0102694:	e8 07 da ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102699:	83 ec 08             	sub    $0x8,%esp
f010269c:	68 00 10 00 00       	push   $0x1000
f01026a1:	ff 35 48 dc 17 f0    	pushl  0xf017dc48
f01026a7:	e8 a5 e8 ff ff       	call   f0100f51 <page_remove>
	assert(pp2->pp_ref == 0);
f01026ac:	83 c4 10             	add    $0x10,%esp
f01026af:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026b4:	74 19                	je     f01026cf <mem_init+0x16cb>
f01026b6:	68 54 56 10 f0       	push   $0xf0105654
f01026bb:	68 3b 54 10 f0       	push   $0xf010543b
f01026c0:	68 ef 03 00 00       	push   $0x3ef
f01026c5:	68 15 54 10 f0       	push   $0xf0105415
f01026ca:	e8 d1 d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026cf:	8b 0d 48 dc 17 f0    	mov    0xf017dc48,%ecx
f01026d5:	8b 11                	mov    (%ecx),%edx
f01026d7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026dd:	89 d8                	mov    %ebx,%eax
f01026df:	2b 05 4c dc 17 f0    	sub    0xf017dc4c,%eax
f01026e5:	c1 f8 03             	sar    $0x3,%eax
f01026e8:	c1 e0 0c             	shl    $0xc,%eax
f01026eb:	39 c2                	cmp    %eax,%edx
f01026ed:	74 19                	je     f0102708 <mem_init+0x1704>
f01026ef:	68 98 4e 10 f0       	push   $0xf0104e98
f01026f4:	68 3b 54 10 f0       	push   $0xf010543b
f01026f9:	68 f2 03 00 00       	push   $0x3f2
f01026fe:	68 15 54 10 f0       	push   $0xf0105415
f0102703:	e8 98 d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102708:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010270e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102713:	74 19                	je     f010272e <mem_init+0x172a>
f0102715:	68 0b 56 10 f0       	push   $0xf010560b
f010271a:	68 3b 54 10 f0       	push   $0xf010543b
f010271f:	68 f4 03 00 00       	push   $0x3f4
f0102724:	68 15 54 10 f0       	push   $0xf0105415
f0102729:	e8 72 d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f010272e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102734:	83 ec 0c             	sub    $0xc,%esp
f0102737:	53                   	push   %ebx
f0102738:	e8 66 e6 ff ff       	call   f0100da3 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010273d:	c7 04 24 b4 53 10 f0 	movl   $0xf01053b4,(%esp)
f0102744:	e8 e5 07 00 00       	call   f0102f2e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102749:	83 c4 10             	add    $0x10,%esp
f010274c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010274f:	5b                   	pop    %ebx
f0102750:	5e                   	pop    %esi
f0102751:	5f                   	pop    %edi
f0102752:	5d                   	pop    %ebp
f0102753:	c3                   	ret    

f0102754 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102754:	55                   	push   %ebp
f0102755:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102757:	8b 45 0c             	mov    0xc(%ebp),%eax
f010275a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010275d:	5d                   	pop    %ebp
f010275e:	c3                   	ret    

f010275f <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010275f:	55                   	push   %ebp
f0102760:	89 e5                	mov    %esp,%ebp
f0102762:	57                   	push   %edi
f0102763:	56                   	push   %esi
f0102764:	53                   	push   %ebx
f0102765:	83 ec 1c             	sub    $0x1c,%esp
f0102768:	8b 7d 08             	mov    0x8(%ebp),%edi
f010276b:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	char * end = NULL;
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
f010276e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102771:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102776:	89 c3                	mov    %eax,%ebx
f0102778:	89 45 e0             	mov    %eax,-0x20(%ebp)
	end = ROUNDUP((char *)(va + len), PGSIZE);
f010277b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010277e:	03 45 10             	add    0x10(%ebp),%eax
f0102781:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102786:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010278b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f010278e:	eb 4e                	jmp    f01027de <user_mem_check+0x7f>
		cur = pgdir_walk(env->env_pgdir, (void *)start, 0);
f0102790:	83 ec 04             	sub    $0x4,%esp
f0102793:	6a 00                	push   $0x0
f0102795:	53                   	push   %ebx
f0102796:	ff 77 5c             	pushl  0x5c(%edi)
f0102799:	e8 67 e6 ff ff       	call   f0100e05 <pgdir_walk>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
f010279e:	89 da                	mov    %ebx,%edx
f01027a0:	83 c4 10             	add    $0x10,%esp
f01027a3:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f01027a9:	77 0c                	ja     f01027b7 <user_mem_check+0x58>
f01027ab:	85 c0                	test   %eax,%eax
f01027ad:	74 08                	je     f01027b7 <user_mem_check+0x58>
f01027af:	89 f1                	mov    %esi,%ecx
f01027b1:	23 08                	and    (%eax),%ecx
f01027b3:	39 ce                	cmp    %ecx,%esi
f01027b5:	74 21                	je     f01027d8 <user_mem_check+0x79>
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
f01027b7:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f01027ba:	75 0f                	jne    f01027cb <user_mem_check+0x6c>
					user_mem_check_addr = (uintptr_t)va;
f01027bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027bf:	a3 7c cf 17 f0       	mov    %eax,0xf017cf7c
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
			  }
			  return -E_FAULT;
f01027c4:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027c9:	eb 1d                	jmp    f01027e8 <user_mem_check+0x89>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
					user_mem_check_addr = (uintptr_t)va;
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
f01027cb:	89 15 7c cf 17 f0    	mov    %edx,0xf017cf7c
			  }
			  return -E_FAULT;
f01027d1:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027d6:	eb 10                	jmp    f01027e8 <user_mem_check+0x89>
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
	end = ROUNDUP((char *)(va + len), PGSIZE);
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f01027d8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027de:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01027e1:	72 ad                	jb     f0102790 <user_mem_check+0x31>
			  }
			  return -E_FAULT;
		}
		
}
	return 0;
f01027e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027eb:	5b                   	pop    %ebx
f01027ec:	5e                   	pop    %esi
f01027ed:	5f                   	pop    %edi
f01027ee:	5d                   	pop    %ebp
f01027ef:	c3                   	ret    

f01027f0 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01027f0:	55                   	push   %ebp
f01027f1:	89 e5                	mov    %esp,%ebp
f01027f3:	53                   	push   %ebx
f01027f4:	83 ec 04             	sub    $0x4,%esp
f01027f7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01027fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01027fd:	83 c8 04             	or     $0x4,%eax
f0102800:	50                   	push   %eax
f0102801:	ff 75 10             	pushl  0x10(%ebp)
f0102804:	ff 75 0c             	pushl  0xc(%ebp)
f0102807:	53                   	push   %ebx
f0102808:	e8 52 ff ff ff       	call   f010275f <user_mem_check>
f010280d:	83 c4 10             	add    $0x10,%esp
f0102810:	85 c0                	test   %eax,%eax
f0102812:	79 21                	jns    f0102835 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102814:	83 ec 04             	sub    $0x4,%esp
f0102817:	ff 35 7c cf 17 f0    	pushl  0xf017cf7c
f010281d:	ff 73 48             	pushl  0x48(%ebx)
f0102820:	68 e0 53 10 f0       	push   $0xf01053e0
f0102825:	e8 04 07 00 00       	call   f0102f2e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f010282a:	89 1c 24             	mov    %ebx,(%esp)
f010282d:	e8 e3 05 00 00       	call   f0102e15 <env_destroy>
f0102832:	83 c4 10             	add    $0x10,%esp
	}
}
f0102835:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102838:	c9                   	leave  
f0102839:	c3                   	ret    

f010283a <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010283a:	55                   	push   %ebp
f010283b:	89 e5                	mov    %esp,%ebp
f010283d:	57                   	push   %edi
f010283e:	56                   	push   %esi
f010283f:	53                   	push   %ebx
f0102840:	83 ec 0c             	sub    $0xc,%esp
f0102843:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
f0102845:	89 d3                	mov    %edx,%ebx
f0102847:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void *)ROUNDUP((uint32_t)va + len, PGSIZE);
f010284d:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102854:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE)
f010285a:	eb 58                	jmp    f01028b4 <region_alloc+0x7a>
	{
		p = page_alloc(0);
f010285c:	83 ec 0c             	sub    $0xc,%esp
f010285f:	6a 00                	push   $0x0
f0102861:	e8 cd e4 ff ff       	call   f0100d33 <page_alloc>
		if(p == NULL)
f0102866:	83 c4 10             	add    $0x10,%esp
f0102869:	85 c0                	test   %eax,%eax
f010286b:	75 17                	jne    f0102884 <region_alloc+0x4a>
			panic(" region alloc, allocation falied.");
f010286d:	83 ec 04             	sub    $0x4,%esp
f0102870:	68 10 57 10 f0       	push   $0xf0105710
f0102875:	68 2b 01 00 00       	push   $0x12b
f010287a:	68 fa 57 10 f0       	push   $0xf01057fa
f010287f:	e8 1c d8 ff ff       	call   f01000a0 <_panic>
		r = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
f0102884:	6a 06                	push   $0x6
f0102886:	53                   	push   %ebx
f0102887:	50                   	push   %eax
f0102888:	ff 77 5c             	pushl  0x5c(%edi)
f010288b:	e8 fc e6 ff ff       	call   f0100f8c <page_insert>
		if(r != 0)
f0102890:	83 c4 10             	add    $0x10,%esp
f0102893:	85 c0                	test   %eax,%eax
f0102895:	74 17                	je     f01028ae <region_alloc+0x74>
		{
			panic("region alloc error");
f0102897:	83 ec 04             	sub    $0x4,%esp
f010289a:	68 05 58 10 f0       	push   $0xf0105805
f010289f:	68 2f 01 00 00       	push   $0x12f
f01028a4:	68 fa 57 10 f0       	push   $0xf01057fa
f01028a9:	e8 f2 d7 ff ff       	call   f01000a0 <_panic>
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
	void* end = (void *)ROUNDUP((uint32_t)va + len, PGSIZE);
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE)
f01028ae:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028b4:	39 f3                	cmp    %esi,%ebx
f01028b6:	72 a4                	jb     f010285c <region_alloc+0x22>
		{
			panic("region alloc error");
		}

	}
}
f01028b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01028bb:	5b                   	pop    %ebx
f01028bc:	5e                   	pop    %esi
f01028bd:	5f                   	pop    %edi
f01028be:	5d                   	pop    %ebp
f01028bf:	c3                   	ret    

f01028c0 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01028c0:	55                   	push   %ebp
f01028c1:	89 e5                	mov    %esp,%ebp
f01028c3:	8b 55 08             	mov    0x8(%ebp),%edx
f01028c6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01028c9:	85 d2                	test   %edx,%edx
f01028cb:	75 11                	jne    f01028de <envid2env+0x1e>
		*env_store = curenv;
f01028cd:	a1 88 cf 17 f0       	mov    0xf017cf88,%eax
f01028d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028d5:	89 01                	mov    %eax,(%ecx)
		return 0;
f01028d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01028dc:	eb 5e                	jmp    f010293c <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01028de:	89 d0                	mov    %edx,%eax
f01028e0:	25 ff 03 00 00       	and    $0x3ff,%eax
f01028e5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028e8:	c1 e0 05             	shl    $0x5,%eax
f01028eb:	03 05 8c cf 17 f0    	add    0xf017cf8c,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01028f1:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01028f5:	74 05                	je     f01028fc <envid2env+0x3c>
f01028f7:	3b 50 48             	cmp    0x48(%eax),%edx
f01028fa:	74 10                	je     f010290c <envid2env+0x4c>
		*env_store = 0;
f01028fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028ff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102905:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010290a:	eb 30                	jmp    f010293c <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010290c:	84 c9                	test   %cl,%cl
f010290e:	74 22                	je     f0102932 <envid2env+0x72>
f0102910:	8b 15 88 cf 17 f0    	mov    0xf017cf88,%edx
f0102916:	39 d0                	cmp    %edx,%eax
f0102918:	74 18                	je     f0102932 <envid2env+0x72>
f010291a:	8b 4a 48             	mov    0x48(%edx),%ecx
f010291d:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102920:	74 10                	je     f0102932 <envid2env+0x72>
		*env_store = 0;
f0102922:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102925:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010292b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102930:	eb 0a                	jmp    f010293c <envid2env+0x7c>
	}

	*env_store = e;
f0102932:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102935:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102937:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010293c:	5d                   	pop    %ebp
f010293d:	c3                   	ret    

f010293e <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010293e:	55                   	push   %ebp
f010293f:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102941:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102946:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102949:	b8 23 00 00 00       	mov    $0x23,%eax
f010294e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102950:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102952:	b8 10 00 00 00       	mov    $0x10,%eax
f0102957:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102959:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f010295b:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010295d:	ea 64 29 10 f0 08 00 	ljmp   $0x8,$0xf0102964
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102964:	b8 00 00 00 00       	mov    $0x0,%eax
f0102969:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010296c:	5d                   	pop    %ebp
f010296d:	c3                   	ret    

f010296e <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010296e:	55                   	push   %ebp
f010296f:	89 e5                	mov    %esp,%ebp
f0102971:	56                   	push   %esi
f0102972:	53                   	push   %ebx
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1;i>=0;i--)
	{
		envs[i].env_id = 0;
f0102973:	8b 35 8c cf 17 f0    	mov    0xf017cf8c,%esi
f0102979:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010297f:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102982:	ba 00 00 00 00       	mov    $0x0,%edx
f0102987:	89 c1                	mov    %eax,%ecx
f0102989:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f0102990:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f0102997:	89 50 44             	mov    %edx,0x44(%eax)
f010299a:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f010299d:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1;i>=0;i--)
f010299f:	39 d8                	cmp    %ebx,%eax
f01029a1:	75 e4                	jne    f0102987 <env_init+0x19>
f01029a3:	89 35 90 cf 17 f0    	mov    %esi,0xf017cf90
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f01029a9:	e8 90 ff ff ff       	call   f010293e <env_init_percpu>
}
f01029ae:	5b                   	pop    %ebx
f01029af:	5e                   	pop    %esi
f01029b0:	5d                   	pop    %ebp
f01029b1:	c3                   	ret    

f01029b2 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01029b2:	55                   	push   %ebp
f01029b3:	89 e5                	mov    %esp,%ebp
f01029b5:	53                   	push   %ebx
f01029b6:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01029b9:	8b 1d 90 cf 17 f0    	mov    0xf017cf90,%ebx
f01029bf:	85 db                	test   %ebx,%ebx
f01029c1:	0f 84 61 01 00 00    	je     f0102b28 <env_alloc+0x176>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01029c7:	83 ec 0c             	sub    $0xc,%esp
f01029ca:	6a 01                	push   $0x1
f01029cc:	e8 62 e3 ff ff       	call   f0100d33 <page_alloc>
f01029d1:	83 c4 10             	add    $0x10,%esp
f01029d4:	85 c0                	test   %eax,%eax
f01029d6:	0f 84 53 01 00 00    	je     f0102b2f <env_alloc+0x17d>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029dc:	89 c2                	mov    %eax,%edx
f01029de:	2b 15 4c dc 17 f0    	sub    0xf017dc4c,%edx
f01029e4:	c1 fa 03             	sar    $0x3,%edx
f01029e7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029ea:	89 d1                	mov    %edx,%ecx
f01029ec:	c1 e9 0c             	shr    $0xc,%ecx
f01029ef:	3b 0d 44 dc 17 f0    	cmp    0xf017dc44,%ecx
f01029f5:	72 12                	jb     f0102a09 <env_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029f7:	52                   	push   %edx
f01029f8:	68 58 4c 10 f0       	push   $0xf0104c58
f01029fd:	6a 56                	push   $0x56
f01029ff:	68 21 54 10 f0       	push   $0xf0105421
f0102a04:	e8 97 d6 ff ff       	call   f01000a0 <_panic>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
f0102a09:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102a0f:	89 53 5c             	mov    %edx,0x5c(%ebx)
	p->pp_ref++;
f0102a12:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0102a17:	b8 00 00 00 00       	mov    $0x0,%eax
	
	for(i=0;i<PDX(UTOP);i++)
	{
		e->env_pgdir[i] = 0;
f0102a1c:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102a1f:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0102a26:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;
	
	for(i=0;i<PDX(UTOP);i++)
f0102a29:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0102a2e:	75 ec                	jne    f0102a1c <env_alloc+0x6a>
		e->env_pgdir[i] = 0;
	}
	
	for(i=PDX(UTOP); i<NPDENTRIES; i++)
	{
		e->env_pgdir[i] = kern_pgdir[i];
f0102a30:	8b 15 48 dc 17 f0    	mov    0xf017dc48,%edx
f0102a36:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102a39:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0102a3c:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102a3f:	83 c0 04             	add    $0x4,%eax
	for(i=0;i<PDX(UTOP);i++)
	{
		e->env_pgdir[i] = 0;
	}
	
	for(i=PDX(UTOP); i<NPDENTRIES; i++)
f0102a42:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102a47:	75 e7                	jne    f0102a30 <env_alloc+0x7e>
	{
		e->env_pgdir[i] = kern_pgdir[i];
	}
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102a49:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a4c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a51:	77 15                	ja     f0102a68 <env_alloc+0xb6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a53:	50                   	push   %eax
f0102a54:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102a59:	68 cc 00 00 00       	push   $0xcc
f0102a5e:	68 fa 57 10 f0       	push   $0xf01057fa
f0102a63:	e8 38 d6 ff ff       	call   f01000a0 <_panic>
f0102a68:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102a6e:	83 ca 05             	or     $0x5,%edx
f0102a71:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102a77:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a7a:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102a7f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102a84:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a89:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102a8c:	89 da                	mov    %ebx,%edx
f0102a8e:	2b 15 8c cf 17 f0    	sub    0xf017cf8c,%edx
f0102a94:	c1 fa 05             	sar    $0x5,%edx
f0102a97:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a9d:	09 d0                	or     %edx,%eax
f0102a9f:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102aa2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102aa5:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102aa8:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102aaf:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102ab6:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102abd:	83 ec 04             	sub    $0x4,%esp
f0102ac0:	6a 44                	push   $0x44
f0102ac2:	6a 00                	push   $0x0
f0102ac4:	53                   	push   %ebx
f0102ac5:	e8 f5 17 00 00       	call   f01042bf <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102aca:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102ad0:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102ad6:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102adc:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102ae3:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102ae9:	8b 43 44             	mov    0x44(%ebx),%eax
f0102aec:	a3 90 cf 17 f0       	mov    %eax,0xf017cf90
	*newenv_store = e;
f0102af1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102af4:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102af6:	8b 53 48             	mov    0x48(%ebx),%edx
f0102af9:	a1 88 cf 17 f0       	mov    0xf017cf88,%eax
f0102afe:	83 c4 10             	add    $0x10,%esp
f0102b01:	85 c0                	test   %eax,%eax
f0102b03:	74 05                	je     f0102b0a <env_alloc+0x158>
f0102b05:	8b 40 48             	mov    0x48(%eax),%eax
f0102b08:	eb 05                	jmp    f0102b0f <env_alloc+0x15d>
f0102b0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b0f:	83 ec 04             	sub    $0x4,%esp
f0102b12:	52                   	push   %edx
f0102b13:	50                   	push   %eax
f0102b14:	68 18 58 10 f0       	push   $0xf0105818
f0102b19:	e8 10 04 00 00       	call   f0102f2e <cprintf>
	return 0;
f0102b1e:	83 c4 10             	add    $0x10,%esp
f0102b21:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b26:	eb 0c                	jmp    f0102b34 <env_alloc+0x182>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102b28:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102b2d:	eb 05                	jmp    f0102b34 <env_alloc+0x182>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102b2f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102b34:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102b37:	c9                   	leave  
f0102b38:	c3                   	ret    

f0102b39 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102b39:	55                   	push   %ebp
f0102b3a:	89 e5                	mov    %esp,%ebp
f0102b3c:	57                   	push   %edi
f0102b3d:	56                   	push   %esi
f0102b3e:	53                   	push   %ebx
f0102b3f:	83 ec 34             	sub    $0x34,%esp
f0102b42:	8b 7d 08             	mov    0x8(%ebp),%edi
    // LAB 3: Your code here.
    struct Env *e;
    int rc;
    if((rc = env_alloc(&e, 0)) != 0) {
f0102b45:	6a 00                	push   $0x0
f0102b47:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102b4a:	50                   	push   %eax
f0102b4b:	e8 62 fe ff ff       	call   f01029b2 <env_alloc>
f0102b50:	83 c4 10             	add    $0x10,%esp
f0102b53:	85 c0                	test   %eax,%eax
f0102b55:	74 17                	je     f0102b6e <env_create+0x35>
        panic("env_create failed: env_alloc failed.\n");
f0102b57:	83 ec 04             	sub    $0x4,%esp
f0102b5a:	68 34 57 10 f0       	push   $0xf0105734
f0102b5f:	68 8d 01 00 00       	push   $0x18d
f0102b64:	68 fa 57 10 f0       	push   $0xf01057fa
f0102b69:	e8 32 d5 ff ff       	call   f01000a0 <_panic>
    }

    load_icode(e, binary);
f0102b6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b71:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	    struct Elf* header = (struct Elf*)binary;
	    
	    if(header->e_magic != ELF_MAGIC) {
f0102b74:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102b7a:	74 17                	je     f0102b93 <env_create+0x5a>
		panic("load_icode failed: The binary we load is not elf.\n");
f0102b7c:	83 ec 04             	sub    $0x4,%esp
f0102b7f:	68 5c 57 10 f0       	push   $0xf010575c
f0102b84:	68 5e 01 00 00       	push   $0x15e
f0102b89:	68 fa 57 10 f0       	push   $0xf01057fa
f0102b8e:	e8 0d d5 ff ff       	call   f01000a0 <_panic>
	    }

	    if(header->e_entry == 0){
f0102b93:	8b 47 18             	mov    0x18(%edi),%eax
f0102b96:	85 c0                	test   %eax,%eax
f0102b98:	75 17                	jne    f0102bb1 <env_create+0x78>
		panic("load_icode failed: The elf file can't be excuterd.\n");
f0102b9a:	83 ec 04             	sub    $0x4,%esp
f0102b9d:	68 90 57 10 f0       	push   $0xf0105790
f0102ba2:	68 62 01 00 00       	push   $0x162
f0102ba7:	68 fa 57 10 f0       	push   $0xf01057fa
f0102bac:	e8 ef d4 ff ff       	call   f01000a0 <_panic>
	    }

	    e->env_tf.tf_eip = header->e_entry;
f0102bb1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102bb4:	89 41 30             	mov    %eax,0x30(%ecx)

	    lcr3(PADDR(e->env_pgdir));   //?????
f0102bb7:	8b 41 5c             	mov    0x5c(%ecx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bbf:	77 15                	ja     f0102bd6 <env_create+0x9d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bc1:	50                   	push   %eax
f0102bc2:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102bc7:	68 67 01 00 00       	push   $0x167
f0102bcc:	68 fa 57 10 f0       	push   $0xf01057fa
f0102bd1:	e8 ca d4 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102bd6:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bdb:	0f 22 d8             	mov    %eax,%cr3

	    struct Proghdr *ph, *eph;
	    ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
f0102bde:	89 fb                	mov    %edi,%ebx
f0102be0:	03 5f 1c             	add    0x1c(%edi),%ebx
	    eph = ph + header->e_phnum;
f0102be3:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102be7:	c1 e6 05             	shl    $0x5,%esi
f0102bea:	01 de                	add    %ebx,%esi
f0102bec:	eb 44                	jmp    f0102c32 <env_create+0xf9>
	    for(; ph < eph; ph++) {
		if(ph->p_type == ELF_PROG_LOAD) {
f0102bee:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102bf1:	75 3c                	jne    f0102c2f <env_create+0xf6>
		    if(ph->p_memsz - ph->p_filesz < 0) {
		        panic("load icode failed : p_memsz < p_filesz.\n");
		    }

		    region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102bf3:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102bf6:	8b 53 08             	mov    0x8(%ebx),%edx
f0102bf9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102bfc:	e8 39 fc ff ff       	call   f010283a <region_alloc>
		    memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102c01:	83 ec 04             	sub    $0x4,%esp
f0102c04:	ff 73 10             	pushl  0x10(%ebx)
f0102c07:	89 f8                	mov    %edi,%eax
f0102c09:	03 43 04             	add    0x4(%ebx),%eax
f0102c0c:	50                   	push   %eax
f0102c0d:	ff 73 08             	pushl  0x8(%ebx)
f0102c10:	e8 f7 16 00 00       	call   f010430c <memmove>
		    memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f0102c15:	8b 43 10             	mov    0x10(%ebx),%eax
f0102c18:	83 c4 0c             	add    $0xc,%esp
f0102c1b:	8b 53 14             	mov    0x14(%ebx),%edx
f0102c1e:	29 c2                	sub    %eax,%edx
f0102c20:	52                   	push   %edx
f0102c21:	6a 00                	push   $0x0
f0102c23:	03 43 08             	add    0x8(%ebx),%eax
f0102c26:	50                   	push   %eax
f0102c27:	e8 93 16 00 00       	call   f01042bf <memset>
f0102c2c:	83 c4 10             	add    $0x10,%esp
	    lcr3(PADDR(e->env_pgdir));   //?????

	    struct Proghdr *ph, *eph;
	    ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
	    eph = ph + header->e_phnum;
	    for(; ph < eph; ph++) {
f0102c2f:	83 c3 20             	add    $0x20,%ebx
f0102c32:	39 de                	cmp    %ebx,%esi
f0102c34:	77 b8                	ja     f0102bee <env_create+0xb5>
		}
    } 
     
    // Now map one page for the program's initial stack
    // at virtual address USTACKTOP - PGSIZE.
    region_alloc(e,(void *)(USTACKTOP-PGSIZE), PGSIZE);
f0102c36:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102c3b:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102c40:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c43:	e8 f2 fb ff ff       	call   f010283a <region_alloc>
    if((rc = env_alloc(&e, 0)) != 0) {
        panic("env_create failed: env_alloc failed.\n");
    }

    load_icode(e, binary);
    e->env_type = type;
f0102c48:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c4b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c4e:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102c51:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c54:	5b                   	pop    %ebx
f0102c55:	5e                   	pop    %esi
f0102c56:	5f                   	pop    %edi
f0102c57:	5d                   	pop    %ebp
f0102c58:	c3                   	ret    

f0102c59 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102c59:	55                   	push   %ebp
f0102c5a:	89 e5                	mov    %esp,%ebp
f0102c5c:	57                   	push   %edi
f0102c5d:	56                   	push   %esi
f0102c5e:	53                   	push   %ebx
f0102c5f:	83 ec 1c             	sub    $0x1c,%esp
f0102c62:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102c65:	8b 15 88 cf 17 f0    	mov    0xf017cf88,%edx
f0102c6b:	39 fa                	cmp    %edi,%edx
f0102c6d:	75 29                	jne    f0102c98 <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c6f:	a1 48 dc 17 f0       	mov    0xf017dc48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c74:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c79:	77 15                	ja     f0102c90 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c7b:	50                   	push   %eax
f0102c7c:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102c81:	68 a2 01 00 00       	push   $0x1a2
f0102c86:	68 fa 57 10 f0       	push   $0xf01057fa
f0102c8b:	e8 10 d4 ff ff       	call   f01000a0 <_panic>
f0102c90:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c95:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c98:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c9b:	85 d2                	test   %edx,%edx
f0102c9d:	74 05                	je     f0102ca4 <env_free+0x4b>
f0102c9f:	8b 42 48             	mov    0x48(%edx),%eax
f0102ca2:	eb 05                	jmp    f0102ca9 <env_free+0x50>
f0102ca4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ca9:	83 ec 04             	sub    $0x4,%esp
f0102cac:	51                   	push   %ecx
f0102cad:	50                   	push   %eax
f0102cae:	68 2d 58 10 f0       	push   $0xf010582d
f0102cb3:	e8 76 02 00 00       	call   f0102f2e <cprintf>
f0102cb8:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102cbb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102cc2:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102cc5:	89 d0                	mov    %edx,%eax
f0102cc7:	c1 e0 02             	shl    $0x2,%eax
f0102cca:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102ccd:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cd0:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102cd3:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102cd9:	0f 84 a8 00 00 00    	je     f0102d87 <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102cdf:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ce5:	89 f0                	mov    %esi,%eax
f0102ce7:	c1 e8 0c             	shr    $0xc,%eax
f0102cea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ced:	39 05 44 dc 17 f0    	cmp    %eax,0xf017dc44
f0102cf3:	77 15                	ja     f0102d0a <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102cf5:	56                   	push   %esi
f0102cf6:	68 58 4c 10 f0       	push   $0xf0104c58
f0102cfb:	68 b1 01 00 00       	push   $0x1b1
f0102d00:	68 fa 57 10 f0       	push   $0xf01057fa
f0102d05:	e8 96 d3 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d0d:	c1 e0 16             	shl    $0x16,%eax
f0102d10:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d13:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102d18:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102d1f:	01 
f0102d20:	74 17                	je     f0102d39 <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102d22:	83 ec 08             	sub    $0x8,%esp
f0102d25:	89 d8                	mov    %ebx,%eax
f0102d27:	c1 e0 0c             	shl    $0xc,%eax
f0102d2a:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102d2d:	50                   	push   %eax
f0102d2e:	ff 77 5c             	pushl  0x5c(%edi)
f0102d31:	e8 1b e2 ff ff       	call   f0100f51 <page_remove>
f0102d36:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102d39:	83 c3 01             	add    $0x1,%ebx
f0102d3c:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102d42:	75 d4                	jne    f0102d18 <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102d44:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d47:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d4a:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d51:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d54:	3b 05 44 dc 17 f0    	cmp    0xf017dc44,%eax
f0102d5a:	72 14                	jb     f0102d70 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102d5c:	83 ec 04             	sub    $0x4,%esp
f0102d5f:	68 40 4d 10 f0       	push   $0xf0104d40
f0102d64:	6a 4f                	push   $0x4f
f0102d66:	68 21 54 10 f0       	push   $0xf0105421
f0102d6b:	e8 30 d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d70:	83 ec 0c             	sub    $0xc,%esp
f0102d73:	a1 4c dc 17 f0       	mov    0xf017dc4c,%eax
f0102d78:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d7b:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d7e:	50                   	push   %eax
f0102d7f:	e8 5a e0 ff ff       	call   f0100dde <page_decref>
f0102d84:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d87:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d8b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d8e:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d93:	0f 85 29 ff ff ff    	jne    f0102cc2 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d99:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d9c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102da1:	77 15                	ja     f0102db8 <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102da3:	50                   	push   %eax
f0102da4:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102da9:	68 bf 01 00 00       	push   $0x1bf
f0102dae:	68 fa 57 10 f0       	push   $0xf01057fa
f0102db3:	e8 e8 d2 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102db8:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102dbf:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dc4:	c1 e8 0c             	shr    $0xc,%eax
f0102dc7:	3b 05 44 dc 17 f0    	cmp    0xf017dc44,%eax
f0102dcd:	72 14                	jb     f0102de3 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102dcf:	83 ec 04             	sub    $0x4,%esp
f0102dd2:	68 40 4d 10 f0       	push   $0xf0104d40
f0102dd7:	6a 4f                	push   $0x4f
f0102dd9:	68 21 54 10 f0       	push   $0xf0105421
f0102dde:	e8 bd d2 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102de3:	83 ec 0c             	sub    $0xc,%esp
f0102de6:	8b 15 4c dc 17 f0    	mov    0xf017dc4c,%edx
f0102dec:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102def:	50                   	push   %eax
f0102df0:	e8 e9 df ff ff       	call   f0100dde <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102df5:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102dfc:	a1 90 cf 17 f0       	mov    0xf017cf90,%eax
f0102e01:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e04:	89 3d 90 cf 17 f0    	mov    %edi,0xf017cf90
}
f0102e0a:	83 c4 10             	add    $0x10,%esp
f0102e0d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e10:	5b                   	pop    %ebx
f0102e11:	5e                   	pop    %esi
f0102e12:	5f                   	pop    %edi
f0102e13:	5d                   	pop    %ebp
f0102e14:	c3                   	ret    

f0102e15 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e15:	55                   	push   %ebp
f0102e16:	89 e5                	mov    %esp,%ebp
f0102e18:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e1b:	ff 75 08             	pushl  0x8(%ebp)
f0102e1e:	e8 36 fe ff ff       	call   f0102c59 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e23:	c7 04 24 c4 57 10 f0 	movl   $0xf01057c4,(%esp)
f0102e2a:	e8 ff 00 00 00       	call   f0102f2e <cprintf>
f0102e2f:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e32:	83 ec 0c             	sub    $0xc,%esp
f0102e35:	6a 00                	push   $0x0
f0102e37:	e8 58 d9 ff ff       	call   f0100794 <monitor>
f0102e3c:	83 c4 10             	add    $0x10,%esp
f0102e3f:	eb f1                	jmp    f0102e32 <env_destroy+0x1d>

f0102e41 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e41:	55                   	push   %ebp
f0102e42:	89 e5                	mov    %esp,%ebp
f0102e44:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102e47:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e4a:	61                   	popa   
f0102e4b:	07                   	pop    %es
f0102e4c:	1f                   	pop    %ds
f0102e4d:	83 c4 08             	add    $0x8,%esp
f0102e50:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102e51:	68 43 58 10 f0       	push   $0xf0105843
f0102e56:	68 e7 01 00 00       	push   $0x1e7
f0102e5b:	68 fa 57 10 f0       	push   $0xf01057fa
f0102e60:	e8 3b d2 ff ff       	call   f01000a0 <_panic>

f0102e65 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102e65:	55                   	push   %ebp
f0102e66:	89 e5                	mov    %esp,%ebp
f0102e68:	83 ec 08             	sub    $0x8,%esp
f0102e6b:	8b 45 08             	mov    0x8(%ebp),%eax
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	if(curenv != NULL && curenv->env_status == ENV_RUNNING) {
f0102e6e:	8b 15 88 cf 17 f0    	mov    0xf017cf88,%edx
f0102e74:	85 d2                	test   %edx,%edx
f0102e76:	74 0d                	je     f0102e85 <env_run+0x20>
f0102e78:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0102e7c:	75 07                	jne    f0102e85 <env_run+0x20>
        curenv->env_status = ENV_RUNNABLE;
f0102e7e:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
    }

    curenv = e;
f0102e85:	a3 88 cf 17 f0       	mov    %eax,0xf017cf88
    curenv->env_status = ENV_RUNNING;
f0102e8a:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
    curenv->env_runs++;
f0102e91:	83 40 58 01          	addl   $0x1,0x58(%eax)
    lcr3(PADDR(curenv->env_pgdir));
f0102e95:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e98:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102e9e:	77 15                	ja     f0102eb5 <env_run+0x50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ea0:	52                   	push   %edx
f0102ea1:	68 9c 4d 10 f0       	push   $0xf0104d9c
f0102ea6:	68 0d 02 00 00       	push   $0x20d
f0102eab:	68 fa 57 10 f0       	push   $0xf01057fa
f0102eb0:	e8 eb d1 ff ff       	call   f01000a0 <_panic>
f0102eb5:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0102ebb:	0f 22 da             	mov    %edx,%cr3

    env_pop_tf(&curenv->env_tf);
f0102ebe:	83 ec 0c             	sub    $0xc,%esp
f0102ec1:	50                   	push   %eax
f0102ec2:	e8 7a ff ff ff       	call   f0102e41 <env_pop_tf>

f0102ec7 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ec7:	55                   	push   %ebp
f0102ec8:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102eca:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ecf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ed2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ed3:	ba 71 00 00 00       	mov    $0x71,%edx
f0102ed8:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ed9:	0f b6 c0             	movzbl %al,%eax
}
f0102edc:	5d                   	pop    %ebp
f0102edd:	c3                   	ret    

f0102ede <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ede:	55                   	push   %ebp
f0102edf:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ee1:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ee6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ee9:	ee                   	out    %al,(%dx)
f0102eea:	ba 71 00 00 00       	mov    $0x71,%edx
f0102eef:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ef2:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ef3:	5d                   	pop    %ebp
f0102ef4:	c3                   	ret    

f0102ef5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ef5:	55                   	push   %ebp
f0102ef6:	89 e5                	mov    %esp,%ebp
f0102ef8:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102efb:	ff 75 08             	pushl  0x8(%ebp)
f0102efe:	e8 04 d7 ff ff       	call   f0100607 <cputchar>
	*cnt++;
}
f0102f03:	83 c4 10             	add    $0x10,%esp
f0102f06:	c9                   	leave  
f0102f07:	c3                   	ret    

f0102f08 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f08:	55                   	push   %ebp
f0102f09:	89 e5                	mov    %esp,%ebp
f0102f0b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102f0e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f15:	ff 75 0c             	pushl  0xc(%ebp)
f0102f18:	ff 75 08             	pushl  0x8(%ebp)
f0102f1b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f1e:	50                   	push   %eax
f0102f1f:	68 f5 2e 10 f0       	push   $0xf0102ef5
f0102f24:	e8 0a 0d 00 00       	call   f0103c33 <vprintfmt>
	return cnt;
}
f0102f29:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f2c:	c9                   	leave  
f0102f2d:	c3                   	ret    

f0102f2e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f2e:	55                   	push   %ebp
f0102f2f:	89 e5                	mov    %esp,%ebp
f0102f31:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f34:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f37:	50                   	push   %eax
f0102f38:	ff 75 08             	pushl  0x8(%ebp)
f0102f3b:	e8 c8 ff ff ff       	call   f0102f08 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f40:	c9                   	leave  
f0102f41:	c3                   	ret    

f0102f42 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102f42:	55                   	push   %ebp
f0102f43:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102f45:	b8 c0 d7 17 f0       	mov    $0xf017d7c0,%eax
f0102f4a:	c7 05 c4 d7 17 f0 00 	movl   $0xf0000000,0xf017d7c4
f0102f51:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102f54:	66 c7 05 c8 d7 17 f0 	movw   $0x10,0xf017d7c8
f0102f5b:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102f5d:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f0102f64:	67 00 
f0102f66:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0102f6c:	89 c2                	mov    %eax,%edx
f0102f6e:	c1 ea 10             	shr    $0x10,%edx
f0102f71:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0102f77:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0102f7e:	c1 e8 18             	shr    $0x18,%eax
f0102f81:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f86:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102f8d:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f92:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102f95:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0102f9a:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f9d:	5d                   	pop    %ebp
f0102f9e:	c3                   	ret    

f0102f9f <trap_init>:
}


void
trap_init(void)
{
f0102f9f:	55                   	push   %ebp
f0102fa0:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0102fa2:	b8 7c 36 10 f0       	mov    $0xf010367c,%eax
f0102fa7:	66 a3 a0 cf 17 f0    	mov    %ax,0xf017cfa0
f0102fad:	66 c7 05 a2 cf 17 f0 	movw   $0x8,0xf017cfa2
f0102fb4:	08 00 
f0102fb6:	c6 05 a4 cf 17 f0 00 	movb   $0x0,0xf017cfa4
f0102fbd:	c6 05 a5 cf 17 f0 8e 	movb   $0x8e,0xf017cfa5
f0102fc4:	c1 e8 10             	shr    $0x10,%eax
f0102fc7:	66 a3 a6 cf 17 f0    	mov    %ax,0xf017cfa6
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f0102fcd:	b8 82 36 10 f0       	mov    $0xf0103682,%eax
f0102fd2:	66 a3 a8 cf 17 f0    	mov    %ax,0xf017cfa8
f0102fd8:	66 c7 05 aa cf 17 f0 	movw   $0x8,0xf017cfaa
f0102fdf:	08 00 
f0102fe1:	c6 05 ac cf 17 f0 00 	movb   $0x0,0xf017cfac
f0102fe8:	c6 05 ad cf 17 f0 8e 	movb   $0x8e,0xf017cfad
f0102fef:	c1 e8 10             	shr    $0x10,%eax
f0102ff2:	66 a3 ae cf 17 f0    	mov    %ax,0xf017cfae
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f0102ff8:	b8 88 36 10 f0       	mov    $0xf0103688,%eax
f0102ffd:	66 a3 b0 cf 17 f0    	mov    %ax,0xf017cfb0
f0103003:	66 c7 05 b2 cf 17 f0 	movw   $0x8,0xf017cfb2
f010300a:	08 00 
f010300c:	c6 05 b4 cf 17 f0 00 	movb   $0x0,0xf017cfb4
f0103013:	c6 05 b5 cf 17 f0 8e 	movb   $0x8e,0xf017cfb5
f010301a:	c1 e8 10             	shr    $0x10,%eax
f010301d:	66 a3 b6 cf 17 f0    	mov    %ax,0xf017cfb6
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f0103023:	b8 8e 36 10 f0       	mov    $0xf010368e,%eax
f0103028:	66 a3 b8 cf 17 f0    	mov    %ax,0xf017cfb8
f010302e:	66 c7 05 ba cf 17 f0 	movw   $0x8,0xf017cfba
f0103035:	08 00 
f0103037:	c6 05 bc cf 17 f0 00 	movb   $0x0,0xf017cfbc
f010303e:	c6 05 bd cf 17 f0 ee 	movb   $0xee,0xf017cfbd
f0103045:	c1 e8 10             	shr    $0x10,%eax
f0103048:	66 a3 be cf 17 f0    	mov    %ax,0xf017cfbe
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f010304e:	b8 94 36 10 f0       	mov    $0xf0103694,%eax
f0103053:	66 a3 c0 cf 17 f0    	mov    %ax,0xf017cfc0
f0103059:	66 c7 05 c2 cf 17 f0 	movw   $0x8,0xf017cfc2
f0103060:	08 00 
f0103062:	c6 05 c4 cf 17 f0 00 	movb   $0x0,0xf017cfc4
f0103069:	c6 05 c5 cf 17 f0 8e 	movb   $0x8e,0xf017cfc5
f0103070:	c1 e8 10             	shr    $0x10,%eax
f0103073:	66 a3 c6 cf 17 f0    	mov    %ax,0xf017cfc6
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f0103079:	b8 9a 36 10 f0       	mov    $0xf010369a,%eax
f010307e:	66 a3 c8 cf 17 f0    	mov    %ax,0xf017cfc8
f0103084:	66 c7 05 ca cf 17 f0 	movw   $0x8,0xf017cfca
f010308b:	08 00 
f010308d:	c6 05 cc cf 17 f0 00 	movb   $0x0,0xf017cfcc
f0103094:	c6 05 cd cf 17 f0 8e 	movb   $0x8e,0xf017cfcd
f010309b:	c1 e8 10             	shr    $0x10,%eax
f010309e:	66 a3 ce cf 17 f0    	mov    %ax,0xf017cfce
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f01030a4:	b8 a0 36 10 f0       	mov    $0xf01036a0,%eax
f01030a9:	66 a3 d0 cf 17 f0    	mov    %ax,0xf017cfd0
f01030af:	66 c7 05 d2 cf 17 f0 	movw   $0x8,0xf017cfd2
f01030b6:	08 00 
f01030b8:	c6 05 d4 cf 17 f0 00 	movb   $0x0,0xf017cfd4
f01030bf:	c6 05 d5 cf 17 f0 8e 	movb   $0x8e,0xf017cfd5
f01030c6:	c1 e8 10             	shr    $0x10,%eax
f01030c9:	66 a3 d6 cf 17 f0    	mov    %ax,0xf017cfd6
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f01030cf:	b8 a6 36 10 f0       	mov    $0xf01036a6,%eax
f01030d4:	66 a3 d8 cf 17 f0    	mov    %ax,0xf017cfd8
f01030da:	66 c7 05 da cf 17 f0 	movw   $0x8,0xf017cfda
f01030e1:	08 00 
f01030e3:	c6 05 dc cf 17 f0 00 	movb   $0x0,0xf017cfdc
f01030ea:	c6 05 dd cf 17 f0 8e 	movb   $0x8e,0xf017cfdd
f01030f1:	c1 e8 10             	shr    $0x10,%eax
f01030f4:	66 a3 de cf 17 f0    	mov    %ax,0xf017cfde
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f01030fa:	b8 ac 36 10 f0       	mov    $0xf01036ac,%eax
f01030ff:	66 a3 e0 cf 17 f0    	mov    %ax,0xf017cfe0
f0103105:	66 c7 05 e2 cf 17 f0 	movw   $0x8,0xf017cfe2
f010310c:	08 00 
f010310e:	c6 05 e4 cf 17 f0 00 	movb   $0x0,0xf017cfe4
f0103115:	c6 05 e5 cf 17 f0 8e 	movb   $0x8e,0xf017cfe5
f010311c:	c1 e8 10             	shr    $0x10,%eax
f010311f:	66 a3 e6 cf 17 f0    	mov    %ax,0xf017cfe6
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f0103125:	b8 b0 36 10 f0       	mov    $0xf01036b0,%eax
f010312a:	66 a3 f0 cf 17 f0    	mov    %ax,0xf017cff0
f0103130:	66 c7 05 f2 cf 17 f0 	movw   $0x8,0xf017cff2
f0103137:	08 00 
f0103139:	c6 05 f4 cf 17 f0 00 	movb   $0x0,0xf017cff4
f0103140:	c6 05 f5 cf 17 f0 8e 	movb   $0x8e,0xf017cff5
f0103147:	c1 e8 10             	shr    $0x10,%eax
f010314a:	66 a3 f6 cf 17 f0    	mov    %ax,0xf017cff6
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f0103150:	b8 b4 36 10 f0       	mov    $0xf01036b4,%eax
f0103155:	66 a3 f8 cf 17 f0    	mov    %ax,0xf017cff8
f010315b:	66 c7 05 fa cf 17 f0 	movw   $0x8,0xf017cffa
f0103162:	08 00 
f0103164:	c6 05 fc cf 17 f0 00 	movb   $0x0,0xf017cffc
f010316b:	c6 05 fd cf 17 f0 8e 	movb   $0x8e,0xf017cffd
f0103172:	c1 e8 10             	shr    $0x10,%eax
f0103175:	66 a3 fe cf 17 f0    	mov    %ax,0xf017cffe
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f010317b:	b8 b8 36 10 f0       	mov    $0xf01036b8,%eax
f0103180:	66 a3 00 d0 17 f0    	mov    %ax,0xf017d000
f0103186:	66 c7 05 02 d0 17 f0 	movw   $0x8,0xf017d002
f010318d:	08 00 
f010318f:	c6 05 04 d0 17 f0 00 	movb   $0x0,0xf017d004
f0103196:	c6 05 05 d0 17 f0 8e 	movb   $0x8e,0xf017d005
f010319d:	c1 e8 10             	shr    $0x10,%eax
f01031a0:	66 a3 06 d0 17 f0    	mov    %ax,0xf017d006
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f01031a6:	b8 bc 36 10 f0       	mov    $0xf01036bc,%eax
f01031ab:	66 a3 08 d0 17 f0    	mov    %ax,0xf017d008
f01031b1:	66 c7 05 0a d0 17 f0 	movw   $0x8,0xf017d00a
f01031b8:	08 00 
f01031ba:	c6 05 0c d0 17 f0 00 	movb   $0x0,0xf017d00c
f01031c1:	c6 05 0d d0 17 f0 8e 	movb   $0x8e,0xf017d00d
f01031c8:	c1 e8 10             	shr    $0x10,%eax
f01031cb:	66 a3 0e d0 17 f0    	mov    %ax,0xf017d00e
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f01031d1:	b8 c0 36 10 f0       	mov    $0xf01036c0,%eax
f01031d6:	66 a3 10 d0 17 f0    	mov    %ax,0xf017d010
f01031dc:	66 c7 05 12 d0 17 f0 	movw   $0x8,0xf017d012
f01031e3:	08 00 
f01031e5:	c6 05 14 d0 17 f0 00 	movb   $0x0,0xf017d014
f01031ec:	c6 05 15 d0 17 f0 8e 	movb   $0x8e,0xf017d015
f01031f3:	c1 e8 10             	shr    $0x10,%eax
f01031f6:	66 a3 16 d0 17 f0    	mov    %ax,0xf017d016
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f01031fc:	b8 c4 36 10 f0       	mov    $0xf01036c4,%eax
f0103201:	66 a3 20 d0 17 f0    	mov    %ax,0xf017d020
f0103207:	66 c7 05 22 d0 17 f0 	movw   $0x8,0xf017d022
f010320e:	08 00 
f0103210:	c6 05 24 d0 17 f0 00 	movb   $0x0,0xf017d024
f0103217:	c6 05 25 d0 17 f0 8e 	movb   $0x8e,0xf017d025
f010321e:	c1 e8 10             	shr    $0x10,%eax
f0103221:	66 a3 26 d0 17 f0    	mov    %ax,0xf017d026
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f0103227:	b8 ca 36 10 f0       	mov    $0xf01036ca,%eax
f010322c:	66 a3 28 d0 17 f0    	mov    %ax,0xf017d028
f0103232:	66 c7 05 2a d0 17 f0 	movw   $0x8,0xf017d02a
f0103239:	08 00 
f010323b:	c6 05 2c d0 17 f0 00 	movb   $0x0,0xf017d02c
f0103242:	c6 05 2d d0 17 f0 8e 	movb   $0x8e,0xf017d02d
f0103249:	c1 e8 10             	shr    $0x10,%eax
f010324c:	66 a3 2e d0 17 f0    	mov    %ax,0xf017d02e
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f0103252:	b8 ce 36 10 f0       	mov    $0xf01036ce,%eax
f0103257:	66 a3 30 d0 17 f0    	mov    %ax,0xf017d030
f010325d:	66 c7 05 32 d0 17 f0 	movw   $0x8,0xf017d032
f0103264:	08 00 
f0103266:	c6 05 34 d0 17 f0 00 	movb   $0x0,0xf017d034
f010326d:	c6 05 35 d0 17 f0 8e 	movb   $0x8e,0xf017d035
f0103274:	c1 e8 10             	shr    $0x10,%eax
f0103277:	66 a3 36 d0 17 f0    	mov    %ax,0xf017d036
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f010327d:	b8 d4 36 10 f0       	mov    $0xf01036d4,%eax
f0103282:	66 a3 38 d0 17 f0    	mov    %ax,0xf017d038
f0103288:	66 c7 05 3a d0 17 f0 	movw   $0x8,0xf017d03a
f010328f:	08 00 
f0103291:	c6 05 3c d0 17 f0 00 	movb   $0x0,0xf017d03c
f0103298:	c6 05 3d d0 17 f0 8e 	movb   $0x8e,0xf017d03d
f010329f:	c1 e8 10             	shr    $0x10,%eax
f01032a2:	66 a3 3e d0 17 f0    	mov    %ax,0xf017d03e
SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f01032a8:	b8 da 36 10 f0       	mov    $0xf01036da,%eax
f01032ad:	66 a3 20 d1 17 f0    	mov    %ax,0xf017d120
f01032b3:	66 c7 05 22 d1 17 f0 	movw   $0x8,0xf017d122
f01032ba:	08 00 
f01032bc:	c6 05 24 d1 17 f0 00 	movb   $0x0,0xf017d124
f01032c3:	c6 05 25 d1 17 f0 ee 	movb   $0xee,0xf017d125
f01032ca:	c1 e8 10             	shr    $0x10,%eax
f01032cd:	66 a3 26 d1 17 f0    	mov    %ax,0xf017d126
	// Per-CPU setup 
	trap_init_percpu();
f01032d3:	e8 6a fc ff ff       	call   f0102f42 <trap_init_percpu>
}
f01032d8:	5d                   	pop    %ebp
f01032d9:	c3                   	ret    

f01032da <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01032da:	55                   	push   %ebp
f01032db:	89 e5                	mov    %esp,%ebp
f01032dd:	53                   	push   %ebx
f01032de:	83 ec 0c             	sub    $0xc,%esp
f01032e1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01032e4:	ff 33                	pushl  (%ebx)
f01032e6:	68 4f 58 10 f0       	push   $0xf010584f
f01032eb:	e8 3e fc ff ff       	call   f0102f2e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01032f0:	83 c4 08             	add    $0x8,%esp
f01032f3:	ff 73 04             	pushl  0x4(%ebx)
f01032f6:	68 5e 58 10 f0       	push   $0xf010585e
f01032fb:	e8 2e fc ff ff       	call   f0102f2e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103300:	83 c4 08             	add    $0x8,%esp
f0103303:	ff 73 08             	pushl  0x8(%ebx)
f0103306:	68 6d 58 10 f0       	push   $0xf010586d
f010330b:	e8 1e fc ff ff       	call   f0102f2e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103310:	83 c4 08             	add    $0x8,%esp
f0103313:	ff 73 0c             	pushl  0xc(%ebx)
f0103316:	68 7c 58 10 f0       	push   $0xf010587c
f010331b:	e8 0e fc ff ff       	call   f0102f2e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103320:	83 c4 08             	add    $0x8,%esp
f0103323:	ff 73 10             	pushl  0x10(%ebx)
f0103326:	68 8b 58 10 f0       	push   $0xf010588b
f010332b:	e8 fe fb ff ff       	call   f0102f2e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103330:	83 c4 08             	add    $0x8,%esp
f0103333:	ff 73 14             	pushl  0x14(%ebx)
f0103336:	68 9a 58 10 f0       	push   $0xf010589a
f010333b:	e8 ee fb ff ff       	call   f0102f2e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103340:	83 c4 08             	add    $0x8,%esp
f0103343:	ff 73 18             	pushl  0x18(%ebx)
f0103346:	68 a9 58 10 f0       	push   $0xf01058a9
f010334b:	e8 de fb ff ff       	call   f0102f2e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103350:	83 c4 08             	add    $0x8,%esp
f0103353:	ff 73 1c             	pushl  0x1c(%ebx)
f0103356:	68 b8 58 10 f0       	push   $0xf01058b8
f010335b:	e8 ce fb ff ff       	call   f0102f2e <cprintf>
}
f0103360:	83 c4 10             	add    $0x10,%esp
f0103363:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103366:	c9                   	leave  
f0103367:	c3                   	ret    

f0103368 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103368:	55                   	push   %ebp
f0103369:	89 e5                	mov    %esp,%ebp
f010336b:	56                   	push   %esi
f010336c:	53                   	push   %ebx
f010336d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103370:	83 ec 08             	sub    $0x8,%esp
f0103373:	53                   	push   %ebx
f0103374:	68 ee 59 10 f0       	push   $0xf01059ee
f0103379:	e8 b0 fb ff ff       	call   f0102f2e <cprintf>
	print_regs(&tf->tf_regs);
f010337e:	89 1c 24             	mov    %ebx,(%esp)
f0103381:	e8 54 ff ff ff       	call   f01032da <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103386:	83 c4 08             	add    $0x8,%esp
f0103389:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010338d:	50                   	push   %eax
f010338e:	68 09 59 10 f0       	push   $0xf0105909
f0103393:	e8 96 fb ff ff       	call   f0102f2e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103398:	83 c4 08             	add    $0x8,%esp
f010339b:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010339f:	50                   	push   %eax
f01033a0:	68 1c 59 10 f0       	push   $0xf010591c
f01033a5:	e8 84 fb ff ff       	call   f0102f2e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033aa:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01033ad:	83 c4 10             	add    $0x10,%esp
f01033b0:	83 f8 13             	cmp    $0x13,%eax
f01033b3:	77 09                	ja     f01033be <print_trapframe+0x56>
		return excnames[trapno];
f01033b5:	8b 14 85 c0 5b 10 f0 	mov    -0xfefa440(,%eax,4),%edx
f01033bc:	eb 10                	jmp    f01033ce <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01033be:	83 f8 30             	cmp    $0x30,%eax
f01033c1:	b9 d3 58 10 f0       	mov    $0xf01058d3,%ecx
f01033c6:	ba c7 58 10 f0       	mov    $0xf01058c7,%edx
f01033cb:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01033ce:	83 ec 04             	sub    $0x4,%esp
f01033d1:	52                   	push   %edx
f01033d2:	50                   	push   %eax
f01033d3:	68 2f 59 10 f0       	push   $0xf010592f
f01033d8:	e8 51 fb ff ff       	call   f0102f2e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01033dd:	83 c4 10             	add    $0x10,%esp
f01033e0:	3b 1d a0 d7 17 f0    	cmp    0xf017d7a0,%ebx
f01033e6:	75 1a                	jne    f0103402 <print_trapframe+0x9a>
f01033e8:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01033ec:	75 14                	jne    f0103402 <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01033ee:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01033f1:	83 ec 08             	sub    $0x8,%esp
f01033f4:	50                   	push   %eax
f01033f5:	68 41 59 10 f0       	push   $0xf0105941
f01033fa:	e8 2f fb ff ff       	call   f0102f2e <cprintf>
f01033ff:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103402:	83 ec 08             	sub    $0x8,%esp
f0103405:	ff 73 2c             	pushl  0x2c(%ebx)
f0103408:	68 50 59 10 f0       	push   $0xf0105950
f010340d:	e8 1c fb ff ff       	call   f0102f2e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103412:	83 c4 10             	add    $0x10,%esp
f0103415:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103419:	75 49                	jne    f0103464 <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010341b:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010341e:	89 c2                	mov    %eax,%edx
f0103420:	83 e2 01             	and    $0x1,%edx
f0103423:	ba ed 58 10 f0       	mov    $0xf01058ed,%edx
f0103428:	b9 e2 58 10 f0       	mov    $0xf01058e2,%ecx
f010342d:	0f 44 ca             	cmove  %edx,%ecx
f0103430:	89 c2                	mov    %eax,%edx
f0103432:	83 e2 02             	and    $0x2,%edx
f0103435:	ba ff 58 10 f0       	mov    $0xf01058ff,%edx
f010343a:	be f9 58 10 f0       	mov    $0xf01058f9,%esi
f010343f:	0f 45 d6             	cmovne %esi,%edx
f0103442:	83 e0 04             	and    $0x4,%eax
f0103445:	be 19 5a 10 f0       	mov    $0xf0105a19,%esi
f010344a:	b8 04 59 10 f0       	mov    $0xf0105904,%eax
f010344f:	0f 44 c6             	cmove  %esi,%eax
f0103452:	51                   	push   %ecx
f0103453:	52                   	push   %edx
f0103454:	50                   	push   %eax
f0103455:	68 5e 59 10 f0       	push   $0xf010595e
f010345a:	e8 cf fa ff ff       	call   f0102f2e <cprintf>
f010345f:	83 c4 10             	add    $0x10,%esp
f0103462:	eb 10                	jmp    f0103474 <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103464:	83 ec 0c             	sub    $0xc,%esp
f0103467:	68 dd 56 10 f0       	push   $0xf01056dd
f010346c:	e8 bd fa ff ff       	call   f0102f2e <cprintf>
f0103471:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103474:	83 ec 08             	sub    $0x8,%esp
f0103477:	ff 73 30             	pushl  0x30(%ebx)
f010347a:	68 6d 59 10 f0       	push   $0xf010596d
f010347f:	e8 aa fa ff ff       	call   f0102f2e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103484:	83 c4 08             	add    $0x8,%esp
f0103487:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010348b:	50                   	push   %eax
f010348c:	68 7c 59 10 f0       	push   $0xf010597c
f0103491:	e8 98 fa ff ff       	call   f0102f2e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103496:	83 c4 08             	add    $0x8,%esp
f0103499:	ff 73 38             	pushl  0x38(%ebx)
f010349c:	68 8f 59 10 f0       	push   $0xf010598f
f01034a1:	e8 88 fa ff ff       	call   f0102f2e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01034a6:	83 c4 10             	add    $0x10,%esp
f01034a9:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01034ad:	74 25                	je     f01034d4 <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01034af:	83 ec 08             	sub    $0x8,%esp
f01034b2:	ff 73 3c             	pushl  0x3c(%ebx)
f01034b5:	68 9e 59 10 f0       	push   $0xf010599e
f01034ba:	e8 6f fa ff ff       	call   f0102f2e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01034bf:	83 c4 08             	add    $0x8,%esp
f01034c2:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01034c6:	50                   	push   %eax
f01034c7:	68 ad 59 10 f0       	push   $0xf01059ad
f01034cc:	e8 5d fa ff ff       	call   f0102f2e <cprintf>
f01034d1:	83 c4 10             	add    $0x10,%esp
	}
}
f01034d4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01034d7:	5b                   	pop    %ebx
f01034d8:	5e                   	pop    %esi
f01034d9:	5d                   	pop    %ebp
f01034da:	c3                   	ret    

f01034db <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01034db:	55                   	push   %ebp
f01034dc:	89 e5                	mov    %esp,%ebp
f01034de:	53                   	push   %ebx
f01034df:	83 ec 04             	sub    $0x4,%esp
f01034e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01034e5:	0f 20 d0             	mov    %cr2,%eax
}
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01034e8:	ff 73 30             	pushl  0x30(%ebx)
f01034eb:	50                   	push   %eax
f01034ec:	a1 88 cf 17 f0       	mov    0xf017cf88,%eax
f01034f1:	ff 70 48             	pushl  0x48(%eax)
f01034f4:	68 64 5b 10 f0       	push   $0xf0105b64
f01034f9:	e8 30 fa ff ff       	call   f0102f2e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01034fe:	89 1c 24             	mov    %ebx,(%esp)
f0103501:	e8 62 fe ff ff       	call   f0103368 <print_trapframe>
	env_destroy(curenv);
f0103506:	83 c4 04             	add    $0x4,%esp
f0103509:	ff 35 88 cf 17 f0    	pushl  0xf017cf88
f010350f:	e8 01 f9 ff ff       	call   f0102e15 <env_destroy>
}
f0103514:	83 c4 10             	add    $0x10,%esp
f0103517:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010351a:	c9                   	leave  
f010351b:	c3                   	ret    

f010351c <trap>:
}
}

void
trap(struct Trapframe *tf)
{
f010351c:	55                   	push   %ebp
f010351d:	89 e5                	mov    %esp,%ebp
f010351f:	57                   	push   %edi
f0103520:	56                   	push   %esi
f0103521:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103524:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103525:	9c                   	pushf  
f0103526:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103527:	f6 c4 02             	test   $0x2,%ah
f010352a:	74 19                	je     f0103545 <trap+0x29>
f010352c:	68 c0 59 10 f0       	push   $0xf01059c0
f0103531:	68 3b 54 10 f0       	push   $0xf010543b
f0103536:	68 e4 00 00 00       	push   $0xe4
f010353b:	68 d9 59 10 f0       	push   $0xf01059d9
f0103540:	e8 5b cb ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103545:	83 ec 08             	sub    $0x8,%esp
f0103548:	56                   	push   %esi
f0103549:	68 e5 59 10 f0       	push   $0xf01059e5
f010354e:	e8 db f9 ff ff       	call   f0102f2e <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103553:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103557:	83 e0 03             	and    $0x3,%eax
f010355a:	83 c4 10             	add    $0x10,%esp
f010355d:	66 83 f8 03          	cmp    $0x3,%ax
f0103561:	75 31                	jne    f0103594 <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f0103563:	a1 88 cf 17 f0       	mov    0xf017cf88,%eax
f0103568:	85 c0                	test   %eax,%eax
f010356a:	75 19                	jne    f0103585 <trap+0x69>
f010356c:	68 00 5a 10 f0       	push   $0xf0105a00
f0103571:	68 3b 54 10 f0       	push   $0xf010543b
f0103576:	68 ea 00 00 00       	push   $0xea
f010357b:	68 d9 59 10 f0       	push   $0xf01059d9
f0103580:	e8 1b cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103585:	b9 11 00 00 00       	mov    $0x11,%ecx
f010358a:	89 c7                	mov    %eax,%edi
f010358c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f010358e:	8b 35 88 cf 17 f0    	mov    0xf017cf88,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103594:	89 35 a0 d7 17 f0    	mov    %esi,0xf017d7a0
trap_dispatch(struct Trapframe *tf)
{
int32_t ret_code;	
// Handle processor exceptions.
	// LAB 3: Your code here.
switch(tf->tf_trapno) {
f010359a:	8b 46 28             	mov    0x28(%esi),%eax
f010359d:	83 f8 03             	cmp    $0x3,%eax
f01035a0:	74 29                	je     f01035cb <trap+0xaf>
f01035a2:	83 f8 03             	cmp    $0x3,%eax
f01035a5:	77 07                	ja     f01035ae <trap+0x92>
f01035a7:	83 f8 01             	cmp    $0x1,%eax
f01035aa:	74 35                	je     f01035e1 <trap+0xc5>
f01035ac:	eb 62                	jmp    f0103610 <trap+0xf4>
f01035ae:	83 f8 0e             	cmp    $0xe,%eax
f01035b1:	74 07                	je     f01035ba <trap+0x9e>
f01035b3:	83 f8 30             	cmp    $0x30,%eax
f01035b6:	74 37                	je     f01035ef <trap+0xd3>
f01035b8:	eb 56                	jmp    f0103610 <trap+0xf4>
		case (T_PGFLT):
			page_fault_handler(tf);
f01035ba:	83 ec 0c             	sub    $0xc,%esp
f01035bd:	56                   	push   %esi
f01035be:	e8 18 ff ff ff       	call   f01034db <page_fault_handler>
f01035c3:	83 c4 10             	add    $0x10,%esp
f01035c6:	e9 80 00 00 00       	jmp    f010364b <trap+0x12f>
			break; 
		case (T_BRKPT):
			print_trapframe(tf);
f01035cb:	83 ec 0c             	sub    $0xc,%esp
f01035ce:	56                   	push   %esi
f01035cf:	e8 94 fd ff ff       	call   f0103368 <print_trapframe>
			monitor(tf);		
f01035d4:	89 34 24             	mov    %esi,(%esp)
f01035d7:	e8 b8 d1 ff ff       	call   f0100794 <monitor>
f01035dc:	83 c4 10             	add    $0x10,%esp
f01035df:	eb 6a                	jmp    f010364b <trap+0x12f>
			break;
		case (T_DEBUG):
			monitor(tf);
f01035e1:	83 ec 0c             	sub    $0xc,%esp
f01035e4:	56                   	push   %esi
f01035e5:	e8 aa d1 ff ff       	call   f0100794 <monitor>
f01035ea:	83 c4 10             	add    $0x10,%esp
f01035ed:	eb 5c                	jmp    f010364b <trap+0x12f>
			break;
		case (T_SYSCALL):
	//		print_trapframe(tf);
			ret_code = syscall(
f01035ef:	83 ec 08             	sub    $0x8,%esp
f01035f2:	ff 76 04             	pushl  0x4(%esi)
f01035f5:	ff 36                	pushl  (%esi)
f01035f7:	ff 76 10             	pushl  0x10(%esi)
f01035fa:	ff 76 18             	pushl  0x18(%esi)
f01035fd:	ff 76 14             	pushl  0x14(%esi)
f0103600:	ff 76 1c             	pushl  0x1c(%esi)
f0103603:	e8 ea 00 00 00       	call   f01036f2 <syscall>
					tf->tf_regs.reg_edx,
					tf->tf_regs.reg_ecx,
					tf->tf_regs.reg_ebx,
					tf->tf_regs.reg_edi,
					tf->tf_regs.reg_esi);
			tf->tf_regs.reg_eax = ret_code;
f0103608:	89 46 1c             	mov    %eax,0x1c(%esi)
f010360b:	83 c4 20             	add    $0x20,%esp
f010360e:	eb 3b                	jmp    f010364b <trap+0x12f>
			break;
default:
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103610:	83 ec 0c             	sub    $0xc,%esp
f0103613:	56                   	push   %esi
f0103614:	e8 4f fd ff ff       	call   f0103368 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103619:	83 c4 10             	add    $0x10,%esp
f010361c:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103621:	75 17                	jne    f010363a <trap+0x11e>
		panic("unhandled trap in kernel");
f0103623:	83 ec 04             	sub    $0x4,%esp
f0103626:	68 07 5a 10 f0       	push   $0xf0105a07
f010362b:	68 d2 00 00 00       	push   $0xd2
f0103630:	68 d9 59 10 f0       	push   $0xf01059d9
f0103635:	e8 66 ca ff ff       	call   f01000a0 <_panic>
	else {
		env_destroy(curenv);
f010363a:	83 ec 0c             	sub    $0xc,%esp
f010363d:	ff 35 88 cf 17 f0    	pushl  0xf017cf88
f0103643:	e8 cd f7 ff ff       	call   f0102e15 <env_destroy>
f0103648:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010364b:	a1 88 cf 17 f0       	mov    0xf017cf88,%eax
f0103650:	85 c0                	test   %eax,%eax
f0103652:	74 06                	je     f010365a <trap+0x13e>
f0103654:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103658:	74 19                	je     f0103673 <trap+0x157>
f010365a:	68 88 5b 10 f0       	push   $0xf0105b88
f010365f:	68 3b 54 10 f0       	push   $0xf010543b
f0103664:	68 fc 00 00 00       	push   $0xfc
f0103669:	68 d9 59 10 f0       	push   $0xf01059d9
f010366e:	e8 2d ca ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103673:	83 ec 0c             	sub    $0xc,%esp
f0103676:	50                   	push   %eax
f0103677:	e8 e9 f7 ff ff       	call   f0102e65 <env_run>

f010367c <t_divide>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f010367c:	6a 00                	push   $0x0
f010367e:	6a 00                	push   $0x0
f0103680:	eb 5e                	jmp    f01036e0 <_alltraps>

f0103682 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f0103682:	6a 00                	push   $0x0
f0103684:	6a 01                	push   $0x1
f0103686:	eb 58                	jmp    f01036e0 <_alltraps>

f0103688 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f0103688:	6a 00                	push   $0x0
f010368a:	6a 02                	push   $0x2
f010368c:	eb 52                	jmp    f01036e0 <_alltraps>

f010368e <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f010368e:	6a 00                	push   $0x0
f0103690:	6a 03                	push   $0x3
f0103692:	eb 4c                	jmp    f01036e0 <_alltraps>

f0103694 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f0103694:	6a 00                	push   $0x0
f0103696:	6a 04                	push   $0x4
f0103698:	eb 46                	jmp    f01036e0 <_alltraps>

f010369a <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f010369a:	6a 00                	push   $0x0
f010369c:	6a 05                	push   $0x5
f010369e:	eb 40                	jmp    f01036e0 <_alltraps>

f01036a0 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f01036a0:	6a 00                	push   $0x0
f01036a2:	6a 06                	push   $0x6
f01036a4:	eb 3a                	jmp    f01036e0 <_alltraps>

f01036a6 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f01036a6:	6a 00                	push   $0x0
f01036a8:	6a 07                	push   $0x7
f01036aa:	eb 34                	jmp    f01036e0 <_alltraps>

f01036ac <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f01036ac:	6a 08                	push   $0x8
f01036ae:	eb 30                	jmp    f01036e0 <_alltraps>

f01036b0 <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f01036b0:	6a 0a                	push   $0xa
f01036b2:	eb 2c                	jmp    f01036e0 <_alltraps>

f01036b4 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f01036b4:	6a 0b                	push   $0xb
f01036b6:	eb 28                	jmp    f01036e0 <_alltraps>

f01036b8 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f01036b8:	6a 0c                	push   $0xc
f01036ba:	eb 24                	jmp    f01036e0 <_alltraps>

f01036bc <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f01036bc:	6a 0d                	push   $0xd
f01036be:	eb 20                	jmp    f01036e0 <_alltraps>

f01036c0 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f01036c0:	6a 0e                	push   $0xe
f01036c2:	eb 1c                	jmp    f01036e0 <_alltraps>

f01036c4 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f01036c4:	6a 00                	push   $0x0
f01036c6:	6a 10                	push   $0x10
f01036c8:	eb 16                	jmp    f01036e0 <_alltraps>

f01036ca <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f01036ca:	6a 11                	push   $0x11
f01036cc:	eb 12                	jmp    f01036e0 <_alltraps>

f01036ce <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f01036ce:	6a 00                	push   $0x0
f01036d0:	6a 12                	push   $0x12
f01036d2:	eb 0c                	jmp    f01036e0 <_alltraps>

f01036d4 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f01036d4:	6a 00                	push   $0x0
f01036d6:	6a 13                	push   $0x13
f01036d8:	eb 06                	jmp    f01036e0 <_alltraps>

f01036da <t_syscall>:

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f01036da:	6a 00                	push   $0x0
f01036dc:	6a 30                	push   $0x30
f01036de:	eb 00                	jmp    f01036e0 <_alltraps>

f01036e0 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f01036e0:	1e                   	push   %ds
	pushl %es
f01036e1:	06                   	push   %es
	pushal 
f01036e2:	60                   	pusha  

	movl $GD_KD, %eax
f01036e3:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax, %ds
f01036e8:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01036ea:	8e c0                	mov    %eax,%es

	push %esp
f01036ec:	54                   	push   %esp
	call trap	
f01036ed:	e8 2a fe ff ff       	call   f010351c <trap>

f01036f2 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01036f2:	55                   	push   %ebp
f01036f3:	89 e5                	mov    %esp,%ebp
f01036f5:	83 ec 18             	sub    $0x18,%esp
f01036f8:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f01036fb:	83 f8 01             	cmp    $0x1,%eax
f01036fe:	74 44                	je     f0103744 <syscall+0x52>
f0103700:	83 f8 01             	cmp    $0x1,%eax
f0103703:	72 0f                	jb     f0103714 <syscall+0x22>
f0103705:	83 f8 02             	cmp    $0x2,%eax
f0103708:	74 41                	je     f010374b <syscall+0x59>
f010370a:	83 f8 03             	cmp    $0x3,%eax
f010370d:	74 46                	je     f0103755 <syscall+0x63>
f010370f:	e9 a6 00 00 00       	jmp    f01037ba <syscall+0xc8>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, 0);
f0103714:	6a 00                	push   $0x0
f0103716:	ff 75 10             	pushl  0x10(%ebp)
f0103719:	ff 75 0c             	pushl  0xc(%ebp)
f010371c:	ff 35 88 cf 17 f0    	pushl  0xf017cf88
f0103722:	e8 c9 f0 ff ff       	call   f01027f0 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103727:	83 c4 0c             	add    $0xc,%esp
f010372a:	ff 75 0c             	pushl  0xc(%ebp)
f010372d:	ff 75 10             	pushl  0x10(%ebp)
f0103730:	68 10 5c 10 f0       	push   $0xf0105c10
f0103735:	e8 f4 f7 ff ff       	call   f0102f2e <cprintf>
f010373a:	83 c4 10             	add    $0x10,%esp
	//panic("syscall not implemented");

	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
f010373d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103742:	eb 7b                	jmp    f01037bf <syscall+0xcd>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103744:	e8 6c cd ff ff       	call   f01004b5 <cons_getc>
	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
f0103749:	eb 74                	jmp    f01037bf <syscall+0xcd>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010374b:	a1 88 cf 17 f0       	mov    0xf017cf88,%eax
f0103750:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
		case (SYS_getenvid):
			return sys_getenvid();
f0103753:	eb 6a                	jmp    f01037bf <syscall+0xcd>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103755:	83 ec 04             	sub    $0x4,%esp
f0103758:	6a 01                	push   $0x1
f010375a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010375d:	50                   	push   %eax
f010375e:	ff 75 0c             	pushl  0xc(%ebp)
f0103761:	e8 5a f1 ff ff       	call   f01028c0 <envid2env>
f0103766:	83 c4 10             	add    $0x10,%esp
f0103769:	85 c0                	test   %eax,%eax
f010376b:	78 52                	js     f01037bf <syscall+0xcd>
		return r;
	if (e == curenv)
f010376d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103770:	8b 15 88 cf 17 f0    	mov    0xf017cf88,%edx
f0103776:	39 d0                	cmp    %edx,%eax
f0103778:	75 15                	jne    f010378f <syscall+0x9d>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010377a:	83 ec 08             	sub    $0x8,%esp
f010377d:	ff 70 48             	pushl  0x48(%eax)
f0103780:	68 15 5c 10 f0       	push   $0xf0105c15
f0103785:	e8 a4 f7 ff ff       	call   f0102f2e <cprintf>
f010378a:	83 c4 10             	add    $0x10,%esp
f010378d:	eb 16                	jmp    f01037a5 <syscall+0xb3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010378f:	83 ec 04             	sub    $0x4,%esp
f0103792:	ff 70 48             	pushl  0x48(%eax)
f0103795:	ff 72 48             	pushl  0x48(%edx)
f0103798:	68 30 5c 10 f0       	push   $0xf0105c30
f010379d:	e8 8c f7 ff ff       	call   f0102f2e <cprintf>
f01037a2:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01037a5:	83 ec 0c             	sub    $0xc,%esp
f01037a8:	ff 75 f4             	pushl  -0xc(%ebp)
f01037ab:	e8 65 f6 ff ff       	call   f0102e15 <env_destroy>
f01037b0:	83 c4 10             	add    $0x10,%esp
	return 0;
f01037b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01037b8:	eb 05                	jmp    f01037bf <syscall+0xcd>
		case (SYS_getenvid):
			return sys_getenvid();
		case (SYS_env_destroy):
			return sys_env_destroy(a1);
		default:
			return -E_INVAL;
f01037ba:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
}
f01037bf:	c9                   	leave  
f01037c0:	c3                   	ret    

f01037c1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01037c1:	55                   	push   %ebp
f01037c2:	89 e5                	mov    %esp,%ebp
f01037c4:	57                   	push   %edi
f01037c5:	56                   	push   %esi
f01037c6:	53                   	push   %ebx
f01037c7:	83 ec 14             	sub    $0x14,%esp
f01037ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01037cd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01037d0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01037d3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01037d6:	8b 1a                	mov    (%edx),%ebx
f01037d8:	8b 01                	mov    (%ecx),%eax
f01037da:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01037dd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01037e4:	eb 7f                	jmp    f0103865 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01037e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01037e9:	01 d8                	add    %ebx,%eax
f01037eb:	89 c6                	mov    %eax,%esi
f01037ed:	c1 ee 1f             	shr    $0x1f,%esi
f01037f0:	01 c6                	add    %eax,%esi
f01037f2:	d1 fe                	sar    %esi
f01037f4:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01037f7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01037fa:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01037fd:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01037ff:	eb 03                	jmp    f0103804 <stab_binsearch+0x43>
			m--;
f0103801:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103804:	39 c3                	cmp    %eax,%ebx
f0103806:	7f 0d                	jg     f0103815 <stab_binsearch+0x54>
f0103808:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010380c:	83 ea 0c             	sub    $0xc,%edx
f010380f:	39 f9                	cmp    %edi,%ecx
f0103811:	75 ee                	jne    f0103801 <stab_binsearch+0x40>
f0103813:	eb 05                	jmp    f010381a <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103815:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103818:	eb 4b                	jmp    f0103865 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010381a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010381d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103820:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103824:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103827:	76 11                	jbe    f010383a <stab_binsearch+0x79>
			*region_left = m;
f0103829:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010382c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010382e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103831:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103838:	eb 2b                	jmp    f0103865 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010383a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010383d:	73 14                	jae    f0103853 <stab_binsearch+0x92>
			*region_right = m - 1;
f010383f:	83 e8 01             	sub    $0x1,%eax
f0103842:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103845:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103848:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010384a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103851:	eb 12                	jmp    f0103865 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103853:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103856:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103858:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010385c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010385e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103865:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103868:	0f 8e 78 ff ff ff    	jle    f01037e6 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010386e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103872:	75 0f                	jne    f0103883 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103874:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103877:	8b 00                	mov    (%eax),%eax
f0103879:	83 e8 01             	sub    $0x1,%eax
f010387c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010387f:	89 06                	mov    %eax,(%esi)
f0103881:	eb 2c                	jmp    f01038af <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103883:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103886:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103888:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010388b:	8b 0e                	mov    (%esi),%ecx
f010388d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103890:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103893:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103896:	eb 03                	jmp    f010389b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103898:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010389b:	39 c8                	cmp    %ecx,%eax
f010389d:	7e 0b                	jle    f01038aa <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010389f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01038a3:	83 ea 0c             	sub    $0xc,%edx
f01038a6:	39 df                	cmp    %ebx,%edi
f01038a8:	75 ee                	jne    f0103898 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01038aa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01038ad:	89 06                	mov    %eax,(%esi)
	}
}
f01038af:	83 c4 14             	add    $0x14,%esp
f01038b2:	5b                   	pop    %ebx
f01038b3:	5e                   	pop    %esi
f01038b4:	5f                   	pop    %edi
f01038b5:	5d                   	pop    %ebp
f01038b6:	c3                   	ret    

f01038b7 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.

int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01038b7:	55                   	push   %ebp
f01038b8:	89 e5                	mov    %esp,%ebp
f01038ba:	57                   	push   %edi
f01038bb:	56                   	push   %esi
f01038bc:	53                   	push   %ebx
f01038bd:	83 ec 3c             	sub    $0x3c,%esp
f01038c0:	8b 75 08             	mov    0x8(%ebp),%esi
f01038c3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01038c6:	c7 03 48 5c 10 f0    	movl   $0xf0105c48,(%ebx)
	info->eip_line = 0;
f01038cc:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01038d3:	c7 43 08 48 5c 10 f0 	movl   $0xf0105c48,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01038da:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01038e1:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01038e4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01038eb:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01038f1:	77 21                	ja     f0103914 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01038f3:	a1 00 00 20 00       	mov    0x200000,%eax
f01038f8:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f01038fb:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103900:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103906:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103909:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f010390f:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103912:	eb 1a                	jmp    f010392e <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103914:	c7 45 bc 3e 00 11 f0 	movl   $0xf011003e,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010391b:	c7 45 c0 c9 d5 10 f0 	movl   $0xf010d5c9,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103922:	b8 c8 d5 10 f0       	mov    $0xf010d5c8,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103927:	c7 45 b8 70 5e 10 f0 	movl   $0xf0105e70,-0x48(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010392e:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103931:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f0103934:	0f 83 ad 01 00 00    	jae    f0103ae7 <debuginfo_eip+0x230>
f010393a:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f010393e:	0f 85 aa 01 00 00    	jne    f0103aee <debuginfo_eip+0x237>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103944:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010394b:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010394e:	29 f8                	sub    %edi,%eax
f0103950:	c1 f8 02             	sar    $0x2,%eax
f0103953:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103959:	83 e8 01             	sub    $0x1,%eax
f010395c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010395f:	56                   	push   %esi
f0103960:	6a 64                	push   $0x64
f0103962:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103965:	89 c1                	mov    %eax,%ecx
f0103967:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010396a:	89 f8                	mov    %edi,%eax
f010396c:	e8 50 fe ff ff       	call   f01037c1 <stab_binsearch>
	if (lfile == 0)
f0103971:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103974:	83 c4 08             	add    $0x8,%esp
f0103977:	85 c0                	test   %eax,%eax
f0103979:	0f 84 76 01 00 00    	je     f0103af5 <debuginfo_eip+0x23e>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010397f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103982:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103985:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103988:	56                   	push   %esi
f0103989:	6a 24                	push   $0x24
f010398b:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010398e:	89 c1                	mov    %eax,%ecx
f0103990:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103993:	89 f8                	mov    %edi,%eax
f0103995:	e8 27 fe ff ff       	call   f01037c1 <stab_binsearch>

	if (lfun <= rfun) {
f010399a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010399d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01039a0:	83 c4 08             	add    $0x8,%esp
f01039a3:	39 c8                	cmp    %ecx,%eax
f01039a5:	7f 2e                	jg     f01039d5 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01039a7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01039aa:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01039ad:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01039b0:	8b 12                	mov    (%edx),%edx
f01039b2:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01039b5:	2b 7d c0             	sub    -0x40(%ebp),%edi
f01039b8:	39 fa                	cmp    %edi,%edx
f01039ba:	73 06                	jae    f01039c2 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01039bc:	03 55 c0             	add    -0x40(%ebp),%edx
f01039bf:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01039c2:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01039c5:	8b 57 08             	mov    0x8(%edi),%edx
f01039c8:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01039cb:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01039cd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01039d0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01039d3:	eb 0f                	jmp    f01039e4 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01039d5:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01039d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01039de:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039e1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01039e4:	83 ec 08             	sub    $0x8,%esp
f01039e7:	6a 3a                	push   $0x3a
f01039e9:	ff 73 08             	pushl  0x8(%ebx)
f01039ec:	e8 b2 08 00 00       	call   f01042a3 <strfind>
f01039f1:	2b 43 08             	sub    0x8(%ebx),%eax
f01039f4:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
        info->eip_file = stabstr + stabs[lfile].n_strx;
f01039f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01039fa:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01039fd:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103a00:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0103a03:	03 0c 87             	add    (%edi,%eax,4),%ecx
f0103a06:	89 0b                	mov    %ecx,(%ebx)
        stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103a08:	83 c4 08             	add    $0x8,%esp
f0103a0b:	56                   	push   %esi
f0103a0c:	6a 44                	push   $0x44
f0103a0e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103a11:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103a14:	89 fe                	mov    %edi,%esi
f0103a16:	89 f8                	mov    %edi,%eax
f0103a18:	e8 a4 fd ff ff       	call   f01037c1 <stab_binsearch>
        if (lline > rline) {
f0103a1d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103a20:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103a23:	83 c4 10             	add    $0x10,%esp
f0103a26:	39 c2                	cmp    %eax,%edx
f0103a28:	0f 8f ce 00 00 00    	jg     f0103afc <debuginfo_eip+0x245>
            return -1;
        } else {
            info->eip_line = stabs[rline].n_desc;
f0103a2e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103a31:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f0103a36:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103a39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103a3c:	89 d0                	mov    %edx,%eax
f0103a3e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103a41:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103a44:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103a48:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a4b:	eb 0a                	jmp    f0103a57 <debuginfo_eip+0x1a0>
f0103a4d:	83 e8 01             	sub    $0x1,%eax
f0103a50:	83 ea 0c             	sub    $0xc,%edx
f0103a53:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103a57:	39 c7                	cmp    %eax,%edi
f0103a59:	7e 05                	jle    f0103a60 <debuginfo_eip+0x1a9>
f0103a5b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a5e:	eb 47                	jmp    f0103aa7 <debuginfo_eip+0x1f0>
	       && stabs[lline].n_type != N_SOL
f0103a60:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103a64:	80 f9 84             	cmp    $0x84,%cl
f0103a67:	75 0e                	jne    f0103a77 <debuginfo_eip+0x1c0>
f0103a69:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a6c:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103a70:	74 1c                	je     f0103a8e <debuginfo_eip+0x1d7>
f0103a72:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103a75:	eb 17                	jmp    f0103a8e <debuginfo_eip+0x1d7>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103a77:	80 f9 64             	cmp    $0x64,%cl
f0103a7a:	75 d1                	jne    f0103a4d <debuginfo_eip+0x196>
f0103a7c:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103a80:	74 cb                	je     f0103a4d <debuginfo_eip+0x196>
f0103a82:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a85:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103a89:	74 03                	je     f0103a8e <debuginfo_eip+0x1d7>
f0103a8b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103a8e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103a91:	8b 75 b8             	mov    -0x48(%ebp),%esi
f0103a94:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0103a97:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103a9a:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103a9d:	29 f0                	sub    %esi,%eax
f0103a9f:	39 c2                	cmp    %eax,%edx
f0103aa1:	73 04                	jae    f0103aa7 <debuginfo_eip+0x1f0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103aa3:	01 f2                	add    %esi,%edx
f0103aa5:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103aa7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103aaa:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103aad:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103ab2:	39 f2                	cmp    %esi,%edx
f0103ab4:	7d 52                	jge    f0103b08 <debuginfo_eip+0x251>
		for (lline = lfun + 1;
f0103ab6:	83 c2 01             	add    $0x1,%edx
f0103ab9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103abc:	89 d0                	mov    %edx,%eax
f0103abe:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103ac1:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103ac4:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103ac7:	eb 04                	jmp    f0103acd <debuginfo_eip+0x216>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103ac9:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103acd:	39 c6                	cmp    %eax,%esi
f0103acf:	7e 32                	jle    f0103b03 <debuginfo_eip+0x24c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103ad1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103ad5:	83 c0 01             	add    $0x1,%eax
f0103ad8:	83 c2 0c             	add    $0xc,%edx
f0103adb:	80 f9 a0             	cmp    $0xa0,%cl
f0103ade:	74 e9                	je     f0103ac9 <debuginfo_eip+0x212>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ae0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ae5:	eb 21                	jmp    f0103b08 <debuginfo_eip+0x251>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103ae7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103aec:	eb 1a                	jmp    f0103b08 <debuginfo_eip+0x251>
f0103aee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103af3:	eb 13                	jmp    f0103b08 <debuginfo_eip+0x251>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103af5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103afa:	eb 0c                	jmp    f0103b08 <debuginfo_eip+0x251>
	//	which one.
	// Your code here.
        info->eip_file = stabstr + stabs[lfile].n_strx;
        stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
        if (lline > rline) {
            return -1;
f0103afc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103b01:	eb 05                	jmp    f0103b08 <debuginfo_eip+0x251>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103b03:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b08:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b0b:	5b                   	pop    %ebx
f0103b0c:	5e                   	pop    %esi
f0103b0d:	5f                   	pop    %edi
f0103b0e:	5d                   	pop    %ebp
f0103b0f:	c3                   	ret    

f0103b10 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b10:	55                   	push   %ebp
f0103b11:	89 e5                	mov    %esp,%ebp
f0103b13:	57                   	push   %edi
f0103b14:	56                   	push   %esi
f0103b15:	53                   	push   %ebx
f0103b16:	83 ec 1c             	sub    $0x1c,%esp
f0103b19:	89 c7                	mov    %eax,%edi
f0103b1b:	89 d6                	mov    %edx,%esi
f0103b1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b20:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b23:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103b26:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b29:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b2c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103b31:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b34:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103b37:	39 d3                	cmp    %edx,%ebx
f0103b39:	72 05                	jb     f0103b40 <printnum+0x30>
f0103b3b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103b3e:	77 45                	ja     f0103b85 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b40:	83 ec 0c             	sub    $0xc,%esp
f0103b43:	ff 75 18             	pushl  0x18(%ebp)
f0103b46:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b49:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103b4c:	53                   	push   %ebx
f0103b4d:	ff 75 10             	pushl  0x10(%ebp)
f0103b50:	83 ec 08             	sub    $0x8,%esp
f0103b53:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b56:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b59:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b5c:	ff 75 d8             	pushl  -0x28(%ebp)
f0103b5f:	e8 6c 09 00 00       	call   f01044d0 <__udivdi3>
f0103b64:	83 c4 18             	add    $0x18,%esp
f0103b67:	52                   	push   %edx
f0103b68:	50                   	push   %eax
f0103b69:	89 f2                	mov    %esi,%edx
f0103b6b:	89 f8                	mov    %edi,%eax
f0103b6d:	e8 9e ff ff ff       	call   f0103b10 <printnum>
f0103b72:	83 c4 20             	add    $0x20,%esp
f0103b75:	eb 18                	jmp    f0103b8f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103b77:	83 ec 08             	sub    $0x8,%esp
f0103b7a:	56                   	push   %esi
f0103b7b:	ff 75 18             	pushl  0x18(%ebp)
f0103b7e:	ff d7                	call   *%edi
f0103b80:	83 c4 10             	add    $0x10,%esp
f0103b83:	eb 03                	jmp    f0103b88 <printnum+0x78>
f0103b85:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103b88:	83 eb 01             	sub    $0x1,%ebx
f0103b8b:	85 db                	test   %ebx,%ebx
f0103b8d:	7f e8                	jg     f0103b77 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103b8f:	83 ec 08             	sub    $0x8,%esp
f0103b92:	56                   	push   %esi
f0103b93:	83 ec 04             	sub    $0x4,%esp
f0103b96:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103b99:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b9c:	ff 75 dc             	pushl  -0x24(%ebp)
f0103b9f:	ff 75 d8             	pushl  -0x28(%ebp)
f0103ba2:	e8 59 0a 00 00       	call   f0104600 <__umoddi3>
f0103ba7:	83 c4 14             	add    $0x14,%esp
f0103baa:	0f be 80 52 5c 10 f0 	movsbl -0xfefa3ae(%eax),%eax
f0103bb1:	50                   	push   %eax
f0103bb2:	ff d7                	call   *%edi
}
f0103bb4:	83 c4 10             	add    $0x10,%esp
f0103bb7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bba:	5b                   	pop    %ebx
f0103bbb:	5e                   	pop    %esi
f0103bbc:	5f                   	pop    %edi
f0103bbd:	5d                   	pop    %ebp
f0103bbe:	c3                   	ret    

f0103bbf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103bbf:	55                   	push   %ebp
f0103bc0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103bc2:	83 fa 01             	cmp    $0x1,%edx
f0103bc5:	7e 0e                	jle    f0103bd5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103bc7:	8b 10                	mov    (%eax),%edx
f0103bc9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103bcc:	89 08                	mov    %ecx,(%eax)
f0103bce:	8b 02                	mov    (%edx),%eax
f0103bd0:	8b 52 04             	mov    0x4(%edx),%edx
f0103bd3:	eb 22                	jmp    f0103bf7 <getuint+0x38>
	else if (lflag)
f0103bd5:	85 d2                	test   %edx,%edx
f0103bd7:	74 10                	je     f0103be9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103bd9:	8b 10                	mov    (%eax),%edx
f0103bdb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103bde:	89 08                	mov    %ecx,(%eax)
f0103be0:	8b 02                	mov    (%edx),%eax
f0103be2:	ba 00 00 00 00       	mov    $0x0,%edx
f0103be7:	eb 0e                	jmp    f0103bf7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103be9:	8b 10                	mov    (%eax),%edx
f0103beb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103bee:	89 08                	mov    %ecx,(%eax)
f0103bf0:	8b 02                	mov    (%edx),%eax
f0103bf2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103bf7:	5d                   	pop    %ebp
f0103bf8:	c3                   	ret    

f0103bf9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103bf9:	55                   	push   %ebp
f0103bfa:	89 e5                	mov    %esp,%ebp
f0103bfc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103bff:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c03:	8b 10                	mov    (%eax),%edx
f0103c05:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c08:	73 0a                	jae    f0103c14 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c0a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103c0d:	89 08                	mov    %ecx,(%eax)
f0103c0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c12:	88 02                	mov    %al,(%edx)
}
f0103c14:	5d                   	pop    %ebp
f0103c15:	c3                   	ret    

f0103c16 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c16:	55                   	push   %ebp
f0103c17:	89 e5                	mov    %esp,%ebp
f0103c19:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c1c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c1f:	50                   	push   %eax
f0103c20:	ff 75 10             	pushl  0x10(%ebp)
f0103c23:	ff 75 0c             	pushl  0xc(%ebp)
f0103c26:	ff 75 08             	pushl  0x8(%ebp)
f0103c29:	e8 05 00 00 00       	call   f0103c33 <vprintfmt>
	va_end(ap);
}
f0103c2e:	83 c4 10             	add    $0x10,%esp
f0103c31:	c9                   	leave  
f0103c32:	c3                   	ret    

f0103c33 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c33:	55                   	push   %ebp
f0103c34:	89 e5                	mov    %esp,%ebp
f0103c36:	57                   	push   %edi
f0103c37:	56                   	push   %esi
f0103c38:	53                   	push   %ebx
f0103c39:	83 ec 2c             	sub    $0x2c,%esp
f0103c3c:	8b 75 08             	mov    0x8(%ebp),%esi
f0103c3f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c42:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103c45:	eb 12                	jmp    f0103c59 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c47:	85 c0                	test   %eax,%eax
f0103c49:	0f 84 a9 03 00 00    	je     f0103ff8 <vprintfmt+0x3c5>
				return;
			putch(ch, putdat);
f0103c4f:	83 ec 08             	sub    $0x8,%esp
f0103c52:	53                   	push   %ebx
f0103c53:	50                   	push   %eax
f0103c54:	ff d6                	call   *%esi
f0103c56:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103c59:	83 c7 01             	add    $0x1,%edi
f0103c5c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103c60:	83 f8 25             	cmp    $0x25,%eax
f0103c63:	75 e2                	jne    f0103c47 <vprintfmt+0x14>
f0103c65:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103c69:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103c70:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103c77:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103c7e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c83:	eb 07                	jmp    f0103c8c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c85:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103c88:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c8c:	8d 47 01             	lea    0x1(%edi),%eax
f0103c8f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c92:	0f b6 07             	movzbl (%edi),%eax
f0103c95:	0f b6 c8             	movzbl %al,%ecx
f0103c98:	83 e8 23             	sub    $0x23,%eax
f0103c9b:	3c 55                	cmp    $0x55,%al
f0103c9d:	0f 87 3a 03 00 00    	ja     f0103fdd <vprintfmt+0x3aa>
f0103ca3:	0f b6 c0             	movzbl %al,%eax
f0103ca6:	ff 24 85 e0 5c 10 f0 	jmp    *-0xfefa320(,%eax,4)
f0103cad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103cb0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103cb4:	eb d6                	jmp    f0103c8c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cb6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103cb9:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cbe:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103cc1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103cc4:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103cc8:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103ccb:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103cce:	83 fa 09             	cmp    $0x9,%edx
f0103cd1:	77 39                	ja     f0103d0c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103cd3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103cd6:	eb e9                	jmp    f0103cc1 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103cd8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cdb:	8d 48 04             	lea    0x4(%eax),%ecx
f0103cde:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103ce1:	8b 00                	mov    (%eax),%eax
f0103ce3:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ce6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103ce9:	eb 27                	jmp    f0103d12 <vprintfmt+0xdf>
f0103ceb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103cee:	85 c0                	test   %eax,%eax
f0103cf0:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103cf5:	0f 49 c8             	cmovns %eax,%ecx
f0103cf8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cfb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103cfe:	eb 8c                	jmp    f0103c8c <vprintfmt+0x59>
f0103d00:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d03:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103d0a:	eb 80                	jmp    f0103c8c <vprintfmt+0x59>
f0103d0c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103d0f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103d12:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103d16:	0f 89 70 ff ff ff    	jns    f0103c8c <vprintfmt+0x59>
				width = precision, precision = -1;
f0103d1c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103d22:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103d29:	e9 5e ff ff ff       	jmp    f0103c8c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d2e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d34:	e9 53 ff ff ff       	jmp    f0103c8c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d39:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d3c:	8d 50 04             	lea    0x4(%eax),%edx
f0103d3f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d42:	83 ec 08             	sub    $0x8,%esp
f0103d45:	53                   	push   %ebx
f0103d46:	ff 30                	pushl  (%eax)
f0103d48:	ff d6                	call   *%esi
			break;
f0103d4a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103d50:	e9 04 ff ff ff       	jmp    f0103c59 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d55:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d58:	8d 50 04             	lea    0x4(%eax),%edx
f0103d5b:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d5e:	8b 00                	mov    (%eax),%eax
f0103d60:	99                   	cltd   
f0103d61:	31 d0                	xor    %edx,%eax
f0103d63:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103d65:	83 f8 07             	cmp    $0x7,%eax
f0103d68:	7f 0b                	jg     f0103d75 <vprintfmt+0x142>
f0103d6a:	8b 14 85 40 5e 10 f0 	mov    -0xfefa1c0(,%eax,4),%edx
f0103d71:	85 d2                	test   %edx,%edx
f0103d73:	75 18                	jne    f0103d8d <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103d75:	50                   	push   %eax
f0103d76:	68 6a 5c 10 f0       	push   $0xf0105c6a
f0103d7b:	53                   	push   %ebx
f0103d7c:	56                   	push   %esi
f0103d7d:	e8 94 fe ff ff       	call   f0103c16 <printfmt>
f0103d82:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d85:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103d88:	e9 cc fe ff ff       	jmp    f0103c59 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103d8d:	52                   	push   %edx
f0103d8e:	68 4d 54 10 f0       	push   $0xf010544d
f0103d93:	53                   	push   %ebx
f0103d94:	56                   	push   %esi
f0103d95:	e8 7c fe ff ff       	call   f0103c16 <printfmt>
f0103d9a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103da0:	e9 b4 fe ff ff       	jmp    f0103c59 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103da5:	8b 45 14             	mov    0x14(%ebp),%eax
f0103da8:	8d 50 04             	lea    0x4(%eax),%edx
f0103dab:	89 55 14             	mov    %edx,0x14(%ebp)
f0103dae:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103db0:	85 ff                	test   %edi,%edi
f0103db2:	b8 63 5c 10 f0       	mov    $0xf0105c63,%eax
f0103db7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103dba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103dbe:	0f 8e 94 00 00 00    	jle    f0103e58 <vprintfmt+0x225>
f0103dc4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103dc8:	0f 84 98 00 00 00    	je     f0103e66 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103dce:	83 ec 08             	sub    $0x8,%esp
f0103dd1:	ff 75 d0             	pushl  -0x30(%ebp)
f0103dd4:	57                   	push   %edi
f0103dd5:	e8 7f 03 00 00       	call   f0104159 <strnlen>
f0103dda:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ddd:	29 c1                	sub    %eax,%ecx
f0103ddf:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103de2:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103de5:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103de9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103dec:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103def:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103df1:	eb 0f                	jmp    f0103e02 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103df3:	83 ec 08             	sub    $0x8,%esp
f0103df6:	53                   	push   %ebx
f0103df7:	ff 75 e0             	pushl  -0x20(%ebp)
f0103dfa:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103dfc:	83 ef 01             	sub    $0x1,%edi
f0103dff:	83 c4 10             	add    $0x10,%esp
f0103e02:	85 ff                	test   %edi,%edi
f0103e04:	7f ed                	jg     f0103df3 <vprintfmt+0x1c0>
f0103e06:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e09:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103e0c:	85 c9                	test   %ecx,%ecx
f0103e0e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e13:	0f 49 c1             	cmovns %ecx,%eax
f0103e16:	29 c1                	sub    %eax,%ecx
f0103e18:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e1b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e1e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e21:	89 cb                	mov    %ecx,%ebx
f0103e23:	eb 4d                	jmp    f0103e72 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e25:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103e29:	74 1b                	je     f0103e46 <vprintfmt+0x213>
f0103e2b:	0f be c0             	movsbl %al,%eax
f0103e2e:	83 e8 20             	sub    $0x20,%eax
f0103e31:	83 f8 5e             	cmp    $0x5e,%eax
f0103e34:	76 10                	jbe    f0103e46 <vprintfmt+0x213>
					putch('?', putdat);
f0103e36:	83 ec 08             	sub    $0x8,%esp
f0103e39:	ff 75 0c             	pushl  0xc(%ebp)
f0103e3c:	6a 3f                	push   $0x3f
f0103e3e:	ff 55 08             	call   *0x8(%ebp)
f0103e41:	83 c4 10             	add    $0x10,%esp
f0103e44:	eb 0d                	jmp    f0103e53 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103e46:	83 ec 08             	sub    $0x8,%esp
f0103e49:	ff 75 0c             	pushl  0xc(%ebp)
f0103e4c:	52                   	push   %edx
f0103e4d:	ff 55 08             	call   *0x8(%ebp)
f0103e50:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e53:	83 eb 01             	sub    $0x1,%ebx
f0103e56:	eb 1a                	jmp    f0103e72 <vprintfmt+0x23f>
f0103e58:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e5b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e5e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e61:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e64:	eb 0c                	jmp    f0103e72 <vprintfmt+0x23f>
f0103e66:	89 75 08             	mov    %esi,0x8(%ebp)
f0103e69:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103e6c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103e6f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103e72:	83 c7 01             	add    $0x1,%edi
f0103e75:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103e79:	0f be d0             	movsbl %al,%edx
f0103e7c:	85 d2                	test   %edx,%edx
f0103e7e:	74 23                	je     f0103ea3 <vprintfmt+0x270>
f0103e80:	85 f6                	test   %esi,%esi
f0103e82:	78 a1                	js     f0103e25 <vprintfmt+0x1f2>
f0103e84:	83 ee 01             	sub    $0x1,%esi
f0103e87:	79 9c                	jns    f0103e25 <vprintfmt+0x1f2>
f0103e89:	89 df                	mov    %ebx,%edi
f0103e8b:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e8e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e91:	eb 18                	jmp    f0103eab <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103e93:	83 ec 08             	sub    $0x8,%esp
f0103e96:	53                   	push   %ebx
f0103e97:	6a 20                	push   $0x20
f0103e99:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103e9b:	83 ef 01             	sub    $0x1,%edi
f0103e9e:	83 c4 10             	add    $0x10,%esp
f0103ea1:	eb 08                	jmp    f0103eab <vprintfmt+0x278>
f0103ea3:	89 df                	mov    %ebx,%edi
f0103ea5:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ea8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103eab:	85 ff                	test   %edi,%edi
f0103ead:	7f e4                	jg     f0103e93 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103eaf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103eb2:	e9 a2 fd ff ff       	jmp    f0103c59 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103eb7:	83 fa 01             	cmp    $0x1,%edx
f0103eba:	7e 16                	jle    f0103ed2 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103ebc:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ebf:	8d 50 08             	lea    0x8(%eax),%edx
f0103ec2:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ec5:	8b 50 04             	mov    0x4(%eax),%edx
f0103ec8:	8b 00                	mov    (%eax),%eax
f0103eca:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ecd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103ed0:	eb 32                	jmp    f0103f04 <vprintfmt+0x2d1>
	else if (lflag)
f0103ed2:	85 d2                	test   %edx,%edx
f0103ed4:	74 18                	je     f0103eee <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103ed6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ed9:	8d 50 04             	lea    0x4(%eax),%edx
f0103edc:	89 55 14             	mov    %edx,0x14(%ebp)
f0103edf:	8b 00                	mov    (%eax),%eax
f0103ee1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ee4:	89 c1                	mov    %eax,%ecx
f0103ee6:	c1 f9 1f             	sar    $0x1f,%ecx
f0103ee9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103eec:	eb 16                	jmp    f0103f04 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103eee:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ef1:	8d 50 04             	lea    0x4(%eax),%edx
f0103ef4:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ef7:	8b 00                	mov    (%eax),%eax
f0103ef9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103efc:	89 c1                	mov    %eax,%ecx
f0103efe:	c1 f9 1f             	sar    $0x1f,%ecx
f0103f01:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103f04:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f07:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f0a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f0f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103f13:	0f 89 90 00 00 00    	jns    f0103fa9 <vprintfmt+0x376>
				putch('-', putdat);
f0103f19:	83 ec 08             	sub    $0x8,%esp
f0103f1c:	53                   	push   %ebx
f0103f1d:	6a 2d                	push   $0x2d
f0103f1f:	ff d6                	call   *%esi
				num = -(long long) num;
f0103f21:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103f24:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103f27:	f7 d8                	neg    %eax
f0103f29:	83 d2 00             	adc    $0x0,%edx
f0103f2c:	f7 da                	neg    %edx
f0103f2e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103f31:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103f36:	eb 71                	jmp    f0103fa9 <vprintfmt+0x376>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103f38:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f3b:	e8 7f fc ff ff       	call   f0103bbf <getuint>
			base = 10;
f0103f40:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103f45:	eb 62                	jmp    f0103fa9 <vprintfmt+0x376>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103f47:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f4a:	e8 70 fc ff ff       	call   f0103bbf <getuint>
                        base = 8;
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
f0103f4f:	83 ec 0c             	sub    $0xc,%esp
f0103f52:	0f be 4d d4          	movsbl -0x2c(%ebp),%ecx
f0103f56:	51                   	push   %ecx
f0103f57:	ff 75 e0             	pushl  -0x20(%ebp)
f0103f5a:	6a 08                	push   $0x8
f0103f5c:	52                   	push   %edx
f0103f5d:	50                   	push   %eax
f0103f5e:	89 da                	mov    %ebx,%edx
f0103f60:	89 f0                	mov    %esi,%eax
f0103f62:	e8 a9 fb ff ff       	call   f0103b10 <printnum>
                        break;
f0103f67:	83 c4 20             	add    $0x20,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f6a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
                        printnum(putch, putdat, num, base, width, padc);
                        break;
f0103f6d:	e9 e7 fc ff ff       	jmp    f0103c59 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0103f72:	83 ec 08             	sub    $0x8,%esp
f0103f75:	53                   	push   %ebx
f0103f76:	6a 30                	push   $0x30
f0103f78:	ff d6                	call   *%esi
			putch('x', putdat);
f0103f7a:	83 c4 08             	add    $0x8,%esp
f0103f7d:	53                   	push   %ebx
f0103f7e:	6a 78                	push   $0x78
f0103f80:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103f82:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f85:	8d 50 04             	lea    0x4(%eax),%edx
f0103f88:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103f8b:	8b 00                	mov    (%eax),%eax
f0103f8d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103f92:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103f95:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103f9a:	eb 0d                	jmp    f0103fa9 <vprintfmt+0x376>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103f9c:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f9f:	e8 1b fc ff ff       	call   f0103bbf <getuint>
			base = 16;
f0103fa4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103fa9:	83 ec 0c             	sub    $0xc,%esp
f0103fac:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103fb0:	57                   	push   %edi
f0103fb1:	ff 75 e0             	pushl  -0x20(%ebp)
f0103fb4:	51                   	push   %ecx
f0103fb5:	52                   	push   %edx
f0103fb6:	50                   	push   %eax
f0103fb7:	89 da                	mov    %ebx,%edx
f0103fb9:	89 f0                	mov    %esi,%eax
f0103fbb:	e8 50 fb ff ff       	call   f0103b10 <printnum>
			break;
f0103fc0:	83 c4 20             	add    $0x20,%esp
f0103fc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fc6:	e9 8e fc ff ff       	jmp    f0103c59 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103fcb:	83 ec 08             	sub    $0x8,%esp
f0103fce:	53                   	push   %ebx
f0103fcf:	51                   	push   %ecx
f0103fd0:	ff d6                	call   *%esi
			break;
f0103fd2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fd5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103fd8:	e9 7c fc ff ff       	jmp    f0103c59 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103fdd:	83 ec 08             	sub    $0x8,%esp
f0103fe0:	53                   	push   %ebx
f0103fe1:	6a 25                	push   $0x25
f0103fe3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103fe5:	83 c4 10             	add    $0x10,%esp
f0103fe8:	eb 03                	jmp    f0103fed <vprintfmt+0x3ba>
f0103fea:	83 ef 01             	sub    $0x1,%edi
f0103fed:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103ff1:	75 f7                	jne    f0103fea <vprintfmt+0x3b7>
f0103ff3:	e9 61 fc ff ff       	jmp    f0103c59 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103ff8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ffb:	5b                   	pop    %ebx
f0103ffc:	5e                   	pop    %esi
f0103ffd:	5f                   	pop    %edi
f0103ffe:	5d                   	pop    %ebp
f0103fff:	c3                   	ret    

f0104000 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104000:	55                   	push   %ebp
f0104001:	89 e5                	mov    %esp,%ebp
f0104003:	83 ec 18             	sub    $0x18,%esp
f0104006:	8b 45 08             	mov    0x8(%ebp),%eax
f0104009:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010400c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010400f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104013:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104016:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010401d:	85 c0                	test   %eax,%eax
f010401f:	74 26                	je     f0104047 <vsnprintf+0x47>
f0104021:	85 d2                	test   %edx,%edx
f0104023:	7e 22                	jle    f0104047 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104025:	ff 75 14             	pushl  0x14(%ebp)
f0104028:	ff 75 10             	pushl  0x10(%ebp)
f010402b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010402e:	50                   	push   %eax
f010402f:	68 f9 3b 10 f0       	push   $0xf0103bf9
f0104034:	e8 fa fb ff ff       	call   f0103c33 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104039:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010403c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010403f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104042:	83 c4 10             	add    $0x10,%esp
f0104045:	eb 05                	jmp    f010404c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104047:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010404c:	c9                   	leave  
f010404d:	c3                   	ret    

f010404e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010404e:	55                   	push   %ebp
f010404f:	89 e5                	mov    %esp,%ebp
f0104051:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104054:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104057:	50                   	push   %eax
f0104058:	ff 75 10             	pushl  0x10(%ebp)
f010405b:	ff 75 0c             	pushl  0xc(%ebp)
f010405e:	ff 75 08             	pushl  0x8(%ebp)
f0104061:	e8 9a ff ff ff       	call   f0104000 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104066:	c9                   	leave  
f0104067:	c3                   	ret    

f0104068 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104068:	55                   	push   %ebp
f0104069:	89 e5                	mov    %esp,%ebp
f010406b:	57                   	push   %edi
f010406c:	56                   	push   %esi
f010406d:	53                   	push   %ebx
f010406e:	83 ec 0c             	sub    $0xc,%esp
f0104071:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104074:	85 c0                	test   %eax,%eax
f0104076:	74 11                	je     f0104089 <readline+0x21>
		cprintf("%s", prompt);
f0104078:	83 ec 08             	sub    $0x8,%esp
f010407b:	50                   	push   %eax
f010407c:	68 4d 54 10 f0       	push   $0xf010544d
f0104081:	e8 a8 ee ff ff       	call   f0102f2e <cprintf>
f0104086:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104089:	83 ec 0c             	sub    $0xc,%esp
f010408c:	6a 00                	push   $0x0
f010408e:	e8 95 c5 ff ff       	call   f0100628 <iscons>
f0104093:	89 c7                	mov    %eax,%edi
f0104095:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104098:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010409d:	e8 75 c5 ff ff       	call   f0100617 <getchar>
f01040a2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01040a4:	85 c0                	test   %eax,%eax
f01040a6:	79 18                	jns    f01040c0 <readline+0x58>
			cprintf("read error: %e\n", c);
f01040a8:	83 ec 08             	sub    $0x8,%esp
f01040ab:	50                   	push   %eax
f01040ac:	68 60 5e 10 f0       	push   $0xf0105e60
f01040b1:	e8 78 ee ff ff       	call   f0102f2e <cprintf>
			return NULL;
f01040b6:	83 c4 10             	add    $0x10,%esp
f01040b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01040be:	eb 79                	jmp    f0104139 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01040c0:	83 f8 08             	cmp    $0x8,%eax
f01040c3:	0f 94 c2             	sete   %dl
f01040c6:	83 f8 7f             	cmp    $0x7f,%eax
f01040c9:	0f 94 c0             	sete   %al
f01040cc:	08 c2                	or     %al,%dl
f01040ce:	74 1a                	je     f01040ea <readline+0x82>
f01040d0:	85 f6                	test   %esi,%esi
f01040d2:	7e 16                	jle    f01040ea <readline+0x82>
			if (echoing)
f01040d4:	85 ff                	test   %edi,%edi
f01040d6:	74 0d                	je     f01040e5 <readline+0x7d>
				cputchar('\b');
f01040d8:	83 ec 0c             	sub    $0xc,%esp
f01040db:	6a 08                	push   $0x8
f01040dd:	e8 25 c5 ff ff       	call   f0100607 <cputchar>
f01040e2:	83 c4 10             	add    $0x10,%esp
			i--;
f01040e5:	83 ee 01             	sub    $0x1,%esi
f01040e8:	eb b3                	jmp    f010409d <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01040ea:	83 fb 1f             	cmp    $0x1f,%ebx
f01040ed:	7e 23                	jle    f0104112 <readline+0xaa>
f01040ef:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01040f5:	7f 1b                	jg     f0104112 <readline+0xaa>
			if (echoing)
f01040f7:	85 ff                	test   %edi,%edi
f01040f9:	74 0c                	je     f0104107 <readline+0x9f>
				cputchar(c);
f01040fb:	83 ec 0c             	sub    $0xc,%esp
f01040fe:	53                   	push   %ebx
f01040ff:	e8 03 c5 ff ff       	call   f0100607 <cputchar>
f0104104:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104107:	88 9e 40 d8 17 f0    	mov    %bl,-0xfe827c0(%esi)
f010410d:	8d 76 01             	lea    0x1(%esi),%esi
f0104110:	eb 8b                	jmp    f010409d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104112:	83 fb 0a             	cmp    $0xa,%ebx
f0104115:	74 05                	je     f010411c <readline+0xb4>
f0104117:	83 fb 0d             	cmp    $0xd,%ebx
f010411a:	75 81                	jne    f010409d <readline+0x35>
			if (echoing)
f010411c:	85 ff                	test   %edi,%edi
f010411e:	74 0d                	je     f010412d <readline+0xc5>
				cputchar('\n');
f0104120:	83 ec 0c             	sub    $0xc,%esp
f0104123:	6a 0a                	push   $0xa
f0104125:	e8 dd c4 ff ff       	call   f0100607 <cputchar>
f010412a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010412d:	c6 86 40 d8 17 f0 00 	movb   $0x0,-0xfe827c0(%esi)
			return buf;
f0104134:	b8 40 d8 17 f0       	mov    $0xf017d840,%eax
		}
	}
}
f0104139:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010413c:	5b                   	pop    %ebx
f010413d:	5e                   	pop    %esi
f010413e:	5f                   	pop    %edi
f010413f:	5d                   	pop    %ebp
f0104140:	c3                   	ret    

f0104141 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104141:	55                   	push   %ebp
f0104142:	89 e5                	mov    %esp,%ebp
f0104144:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104147:	b8 00 00 00 00       	mov    $0x0,%eax
f010414c:	eb 03                	jmp    f0104151 <strlen+0x10>
		n++;
f010414e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104151:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104155:	75 f7                	jne    f010414e <strlen+0xd>
		n++;
	return n;
}
f0104157:	5d                   	pop    %ebp
f0104158:	c3                   	ret    

f0104159 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104159:	55                   	push   %ebp
f010415a:	89 e5                	mov    %esp,%ebp
f010415c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010415f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104162:	ba 00 00 00 00       	mov    $0x0,%edx
f0104167:	eb 03                	jmp    f010416c <strnlen+0x13>
		n++;
f0104169:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010416c:	39 c2                	cmp    %eax,%edx
f010416e:	74 08                	je     f0104178 <strnlen+0x1f>
f0104170:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104174:	75 f3                	jne    f0104169 <strnlen+0x10>
f0104176:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104178:	5d                   	pop    %ebp
f0104179:	c3                   	ret    

f010417a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010417a:	55                   	push   %ebp
f010417b:	89 e5                	mov    %esp,%ebp
f010417d:	53                   	push   %ebx
f010417e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104181:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104184:	89 c2                	mov    %eax,%edx
f0104186:	83 c2 01             	add    $0x1,%edx
f0104189:	83 c1 01             	add    $0x1,%ecx
f010418c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104190:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104193:	84 db                	test   %bl,%bl
f0104195:	75 ef                	jne    f0104186 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104197:	5b                   	pop    %ebx
f0104198:	5d                   	pop    %ebp
f0104199:	c3                   	ret    

f010419a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010419a:	55                   	push   %ebp
f010419b:	89 e5                	mov    %esp,%ebp
f010419d:	53                   	push   %ebx
f010419e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01041a1:	53                   	push   %ebx
f01041a2:	e8 9a ff ff ff       	call   f0104141 <strlen>
f01041a7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01041aa:	ff 75 0c             	pushl  0xc(%ebp)
f01041ad:	01 d8                	add    %ebx,%eax
f01041af:	50                   	push   %eax
f01041b0:	e8 c5 ff ff ff       	call   f010417a <strcpy>
	return dst;
}
f01041b5:	89 d8                	mov    %ebx,%eax
f01041b7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01041ba:	c9                   	leave  
f01041bb:	c3                   	ret    

f01041bc <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01041bc:	55                   	push   %ebp
f01041bd:	89 e5                	mov    %esp,%ebp
f01041bf:	56                   	push   %esi
f01041c0:	53                   	push   %ebx
f01041c1:	8b 75 08             	mov    0x8(%ebp),%esi
f01041c4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041c7:	89 f3                	mov    %esi,%ebx
f01041c9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01041cc:	89 f2                	mov    %esi,%edx
f01041ce:	eb 0f                	jmp    f01041df <strncpy+0x23>
		*dst++ = *src;
f01041d0:	83 c2 01             	add    $0x1,%edx
f01041d3:	0f b6 01             	movzbl (%ecx),%eax
f01041d6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01041d9:	80 39 01             	cmpb   $0x1,(%ecx)
f01041dc:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01041df:	39 da                	cmp    %ebx,%edx
f01041e1:	75 ed                	jne    f01041d0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01041e3:	89 f0                	mov    %esi,%eax
f01041e5:	5b                   	pop    %ebx
f01041e6:	5e                   	pop    %esi
f01041e7:	5d                   	pop    %ebp
f01041e8:	c3                   	ret    

f01041e9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01041e9:	55                   	push   %ebp
f01041ea:	89 e5                	mov    %esp,%ebp
f01041ec:	56                   	push   %esi
f01041ed:	53                   	push   %ebx
f01041ee:	8b 75 08             	mov    0x8(%ebp),%esi
f01041f1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01041f4:	8b 55 10             	mov    0x10(%ebp),%edx
f01041f7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01041f9:	85 d2                	test   %edx,%edx
f01041fb:	74 21                	je     f010421e <strlcpy+0x35>
f01041fd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104201:	89 f2                	mov    %esi,%edx
f0104203:	eb 09                	jmp    f010420e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104205:	83 c2 01             	add    $0x1,%edx
f0104208:	83 c1 01             	add    $0x1,%ecx
f010420b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010420e:	39 c2                	cmp    %eax,%edx
f0104210:	74 09                	je     f010421b <strlcpy+0x32>
f0104212:	0f b6 19             	movzbl (%ecx),%ebx
f0104215:	84 db                	test   %bl,%bl
f0104217:	75 ec                	jne    f0104205 <strlcpy+0x1c>
f0104219:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010421b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010421e:	29 f0                	sub    %esi,%eax
}
f0104220:	5b                   	pop    %ebx
f0104221:	5e                   	pop    %esi
f0104222:	5d                   	pop    %ebp
f0104223:	c3                   	ret    

f0104224 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104224:	55                   	push   %ebp
f0104225:	89 e5                	mov    %esp,%ebp
f0104227:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010422a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010422d:	eb 06                	jmp    f0104235 <strcmp+0x11>
		p++, q++;
f010422f:	83 c1 01             	add    $0x1,%ecx
f0104232:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104235:	0f b6 01             	movzbl (%ecx),%eax
f0104238:	84 c0                	test   %al,%al
f010423a:	74 04                	je     f0104240 <strcmp+0x1c>
f010423c:	3a 02                	cmp    (%edx),%al
f010423e:	74 ef                	je     f010422f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104240:	0f b6 c0             	movzbl %al,%eax
f0104243:	0f b6 12             	movzbl (%edx),%edx
f0104246:	29 d0                	sub    %edx,%eax
}
f0104248:	5d                   	pop    %ebp
f0104249:	c3                   	ret    

f010424a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010424a:	55                   	push   %ebp
f010424b:	89 e5                	mov    %esp,%ebp
f010424d:	53                   	push   %ebx
f010424e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104251:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104254:	89 c3                	mov    %eax,%ebx
f0104256:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104259:	eb 06                	jmp    f0104261 <strncmp+0x17>
		n--, p++, q++;
f010425b:	83 c0 01             	add    $0x1,%eax
f010425e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104261:	39 d8                	cmp    %ebx,%eax
f0104263:	74 15                	je     f010427a <strncmp+0x30>
f0104265:	0f b6 08             	movzbl (%eax),%ecx
f0104268:	84 c9                	test   %cl,%cl
f010426a:	74 04                	je     f0104270 <strncmp+0x26>
f010426c:	3a 0a                	cmp    (%edx),%cl
f010426e:	74 eb                	je     f010425b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104270:	0f b6 00             	movzbl (%eax),%eax
f0104273:	0f b6 12             	movzbl (%edx),%edx
f0104276:	29 d0                	sub    %edx,%eax
f0104278:	eb 05                	jmp    f010427f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010427a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010427f:	5b                   	pop    %ebx
f0104280:	5d                   	pop    %ebp
f0104281:	c3                   	ret    

f0104282 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104282:	55                   	push   %ebp
f0104283:	89 e5                	mov    %esp,%ebp
f0104285:	8b 45 08             	mov    0x8(%ebp),%eax
f0104288:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010428c:	eb 07                	jmp    f0104295 <strchr+0x13>
		if (*s == c)
f010428e:	38 ca                	cmp    %cl,%dl
f0104290:	74 0f                	je     f01042a1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104292:	83 c0 01             	add    $0x1,%eax
f0104295:	0f b6 10             	movzbl (%eax),%edx
f0104298:	84 d2                	test   %dl,%dl
f010429a:	75 f2                	jne    f010428e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010429c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01042a1:	5d                   	pop    %ebp
f01042a2:	c3                   	ret    

f01042a3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01042a3:	55                   	push   %ebp
f01042a4:	89 e5                	mov    %esp,%ebp
f01042a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01042a9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01042ad:	eb 03                	jmp    f01042b2 <strfind+0xf>
f01042af:	83 c0 01             	add    $0x1,%eax
f01042b2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01042b5:	38 ca                	cmp    %cl,%dl
f01042b7:	74 04                	je     f01042bd <strfind+0x1a>
f01042b9:	84 d2                	test   %dl,%dl
f01042bb:	75 f2                	jne    f01042af <strfind+0xc>
			break;
	return (char *) s;
}
f01042bd:	5d                   	pop    %ebp
f01042be:	c3                   	ret    

f01042bf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01042bf:	55                   	push   %ebp
f01042c0:	89 e5                	mov    %esp,%ebp
f01042c2:	57                   	push   %edi
f01042c3:	56                   	push   %esi
f01042c4:	53                   	push   %ebx
f01042c5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042c8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01042cb:	85 c9                	test   %ecx,%ecx
f01042cd:	74 36                	je     f0104305 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01042cf:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01042d5:	75 28                	jne    f01042ff <memset+0x40>
f01042d7:	f6 c1 03             	test   $0x3,%cl
f01042da:	75 23                	jne    f01042ff <memset+0x40>
		c &= 0xFF;
f01042dc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01042e0:	89 d3                	mov    %edx,%ebx
f01042e2:	c1 e3 08             	shl    $0x8,%ebx
f01042e5:	89 d6                	mov    %edx,%esi
f01042e7:	c1 e6 18             	shl    $0x18,%esi
f01042ea:	89 d0                	mov    %edx,%eax
f01042ec:	c1 e0 10             	shl    $0x10,%eax
f01042ef:	09 f0                	or     %esi,%eax
f01042f1:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01042f3:	89 d8                	mov    %ebx,%eax
f01042f5:	09 d0                	or     %edx,%eax
f01042f7:	c1 e9 02             	shr    $0x2,%ecx
f01042fa:	fc                   	cld    
f01042fb:	f3 ab                	rep stos %eax,%es:(%edi)
f01042fd:	eb 06                	jmp    f0104305 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01042ff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104302:	fc                   	cld    
f0104303:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104305:	89 f8                	mov    %edi,%eax
f0104307:	5b                   	pop    %ebx
f0104308:	5e                   	pop    %esi
f0104309:	5f                   	pop    %edi
f010430a:	5d                   	pop    %ebp
f010430b:	c3                   	ret    

f010430c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010430c:	55                   	push   %ebp
f010430d:	89 e5                	mov    %esp,%ebp
f010430f:	57                   	push   %edi
f0104310:	56                   	push   %esi
f0104311:	8b 45 08             	mov    0x8(%ebp),%eax
f0104314:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104317:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010431a:	39 c6                	cmp    %eax,%esi
f010431c:	73 35                	jae    f0104353 <memmove+0x47>
f010431e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104321:	39 d0                	cmp    %edx,%eax
f0104323:	73 2e                	jae    f0104353 <memmove+0x47>
		s += n;
		d += n;
f0104325:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104328:	89 d6                	mov    %edx,%esi
f010432a:	09 fe                	or     %edi,%esi
f010432c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104332:	75 13                	jne    f0104347 <memmove+0x3b>
f0104334:	f6 c1 03             	test   $0x3,%cl
f0104337:	75 0e                	jne    f0104347 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104339:	83 ef 04             	sub    $0x4,%edi
f010433c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010433f:	c1 e9 02             	shr    $0x2,%ecx
f0104342:	fd                   	std    
f0104343:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104345:	eb 09                	jmp    f0104350 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104347:	83 ef 01             	sub    $0x1,%edi
f010434a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010434d:	fd                   	std    
f010434e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104350:	fc                   	cld    
f0104351:	eb 1d                	jmp    f0104370 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104353:	89 f2                	mov    %esi,%edx
f0104355:	09 c2                	or     %eax,%edx
f0104357:	f6 c2 03             	test   $0x3,%dl
f010435a:	75 0f                	jne    f010436b <memmove+0x5f>
f010435c:	f6 c1 03             	test   $0x3,%cl
f010435f:	75 0a                	jne    f010436b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104361:	c1 e9 02             	shr    $0x2,%ecx
f0104364:	89 c7                	mov    %eax,%edi
f0104366:	fc                   	cld    
f0104367:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104369:	eb 05                	jmp    f0104370 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010436b:	89 c7                	mov    %eax,%edi
f010436d:	fc                   	cld    
f010436e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104370:	5e                   	pop    %esi
f0104371:	5f                   	pop    %edi
f0104372:	5d                   	pop    %ebp
f0104373:	c3                   	ret    

f0104374 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104374:	55                   	push   %ebp
f0104375:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104377:	ff 75 10             	pushl  0x10(%ebp)
f010437a:	ff 75 0c             	pushl  0xc(%ebp)
f010437d:	ff 75 08             	pushl  0x8(%ebp)
f0104380:	e8 87 ff ff ff       	call   f010430c <memmove>
}
f0104385:	c9                   	leave  
f0104386:	c3                   	ret    

f0104387 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104387:	55                   	push   %ebp
f0104388:	89 e5                	mov    %esp,%ebp
f010438a:	56                   	push   %esi
f010438b:	53                   	push   %ebx
f010438c:	8b 45 08             	mov    0x8(%ebp),%eax
f010438f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104392:	89 c6                	mov    %eax,%esi
f0104394:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104397:	eb 1a                	jmp    f01043b3 <memcmp+0x2c>
		if (*s1 != *s2)
f0104399:	0f b6 08             	movzbl (%eax),%ecx
f010439c:	0f b6 1a             	movzbl (%edx),%ebx
f010439f:	38 d9                	cmp    %bl,%cl
f01043a1:	74 0a                	je     f01043ad <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01043a3:	0f b6 c1             	movzbl %cl,%eax
f01043a6:	0f b6 db             	movzbl %bl,%ebx
f01043a9:	29 d8                	sub    %ebx,%eax
f01043ab:	eb 0f                	jmp    f01043bc <memcmp+0x35>
		s1++, s2++;
f01043ad:	83 c0 01             	add    $0x1,%eax
f01043b0:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01043b3:	39 f0                	cmp    %esi,%eax
f01043b5:	75 e2                	jne    f0104399 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01043b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01043bc:	5b                   	pop    %ebx
f01043bd:	5e                   	pop    %esi
f01043be:	5d                   	pop    %ebp
f01043bf:	c3                   	ret    

f01043c0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01043c0:	55                   	push   %ebp
f01043c1:	89 e5                	mov    %esp,%ebp
f01043c3:	53                   	push   %ebx
f01043c4:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01043c7:	89 c1                	mov    %eax,%ecx
f01043c9:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01043cc:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01043d0:	eb 0a                	jmp    f01043dc <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01043d2:	0f b6 10             	movzbl (%eax),%edx
f01043d5:	39 da                	cmp    %ebx,%edx
f01043d7:	74 07                	je     f01043e0 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01043d9:	83 c0 01             	add    $0x1,%eax
f01043dc:	39 c8                	cmp    %ecx,%eax
f01043de:	72 f2                	jb     f01043d2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01043e0:	5b                   	pop    %ebx
f01043e1:	5d                   	pop    %ebp
f01043e2:	c3                   	ret    

f01043e3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01043e3:	55                   	push   %ebp
f01043e4:	89 e5                	mov    %esp,%ebp
f01043e6:	57                   	push   %edi
f01043e7:	56                   	push   %esi
f01043e8:	53                   	push   %ebx
f01043e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043ec:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043ef:	eb 03                	jmp    f01043f4 <strtol+0x11>
		s++;
f01043f1:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01043f4:	0f b6 01             	movzbl (%ecx),%eax
f01043f7:	3c 20                	cmp    $0x20,%al
f01043f9:	74 f6                	je     f01043f1 <strtol+0xe>
f01043fb:	3c 09                	cmp    $0x9,%al
f01043fd:	74 f2                	je     f01043f1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01043ff:	3c 2b                	cmp    $0x2b,%al
f0104401:	75 0a                	jne    f010440d <strtol+0x2a>
		s++;
f0104403:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104406:	bf 00 00 00 00       	mov    $0x0,%edi
f010440b:	eb 11                	jmp    f010441e <strtol+0x3b>
f010440d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104412:	3c 2d                	cmp    $0x2d,%al
f0104414:	75 08                	jne    f010441e <strtol+0x3b>
		s++, neg = 1;
f0104416:	83 c1 01             	add    $0x1,%ecx
f0104419:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010441e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104424:	75 15                	jne    f010443b <strtol+0x58>
f0104426:	80 39 30             	cmpb   $0x30,(%ecx)
f0104429:	75 10                	jne    f010443b <strtol+0x58>
f010442b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010442f:	75 7c                	jne    f01044ad <strtol+0xca>
		s += 2, base = 16;
f0104431:	83 c1 02             	add    $0x2,%ecx
f0104434:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104439:	eb 16                	jmp    f0104451 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010443b:	85 db                	test   %ebx,%ebx
f010443d:	75 12                	jne    f0104451 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010443f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104444:	80 39 30             	cmpb   $0x30,(%ecx)
f0104447:	75 08                	jne    f0104451 <strtol+0x6e>
		s++, base = 8;
f0104449:	83 c1 01             	add    $0x1,%ecx
f010444c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104451:	b8 00 00 00 00       	mov    $0x0,%eax
f0104456:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104459:	0f b6 11             	movzbl (%ecx),%edx
f010445c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010445f:	89 f3                	mov    %esi,%ebx
f0104461:	80 fb 09             	cmp    $0x9,%bl
f0104464:	77 08                	ja     f010446e <strtol+0x8b>
			dig = *s - '0';
f0104466:	0f be d2             	movsbl %dl,%edx
f0104469:	83 ea 30             	sub    $0x30,%edx
f010446c:	eb 22                	jmp    f0104490 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010446e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104471:	89 f3                	mov    %esi,%ebx
f0104473:	80 fb 19             	cmp    $0x19,%bl
f0104476:	77 08                	ja     f0104480 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104478:	0f be d2             	movsbl %dl,%edx
f010447b:	83 ea 57             	sub    $0x57,%edx
f010447e:	eb 10                	jmp    f0104490 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104480:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104483:	89 f3                	mov    %esi,%ebx
f0104485:	80 fb 19             	cmp    $0x19,%bl
f0104488:	77 16                	ja     f01044a0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010448a:	0f be d2             	movsbl %dl,%edx
f010448d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104490:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104493:	7d 0b                	jge    f01044a0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104495:	83 c1 01             	add    $0x1,%ecx
f0104498:	0f af 45 10          	imul   0x10(%ebp),%eax
f010449c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010449e:	eb b9                	jmp    f0104459 <strtol+0x76>

	if (endptr)
f01044a0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01044a4:	74 0d                	je     f01044b3 <strtol+0xd0>
		*endptr = (char *) s;
f01044a6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01044a9:	89 0e                	mov    %ecx,(%esi)
f01044ab:	eb 06                	jmp    f01044b3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01044ad:	85 db                	test   %ebx,%ebx
f01044af:	74 98                	je     f0104449 <strtol+0x66>
f01044b1:	eb 9e                	jmp    f0104451 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01044b3:	89 c2                	mov    %eax,%edx
f01044b5:	f7 da                	neg    %edx
f01044b7:	85 ff                	test   %edi,%edi
f01044b9:	0f 45 c2             	cmovne %edx,%eax
}
f01044bc:	5b                   	pop    %ebx
f01044bd:	5e                   	pop    %esi
f01044be:	5f                   	pop    %edi
f01044bf:	5d                   	pop    %ebp
f01044c0:	c3                   	ret    
f01044c1:	66 90                	xchg   %ax,%ax
f01044c3:	66 90                	xchg   %ax,%ax
f01044c5:	66 90                	xchg   %ax,%ax
f01044c7:	66 90                	xchg   %ax,%ax
f01044c9:	66 90                	xchg   %ax,%ax
f01044cb:	66 90                	xchg   %ax,%ax
f01044cd:	66 90                	xchg   %ax,%ax
f01044cf:	90                   	nop

f01044d0 <__udivdi3>:
f01044d0:	55                   	push   %ebp
f01044d1:	57                   	push   %edi
f01044d2:	56                   	push   %esi
f01044d3:	53                   	push   %ebx
f01044d4:	83 ec 1c             	sub    $0x1c,%esp
f01044d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01044db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01044df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01044e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01044e7:	85 f6                	test   %esi,%esi
f01044e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01044ed:	89 ca                	mov    %ecx,%edx
f01044ef:	89 f8                	mov    %edi,%eax
f01044f1:	75 3d                	jne    f0104530 <__udivdi3+0x60>
f01044f3:	39 cf                	cmp    %ecx,%edi
f01044f5:	0f 87 c5 00 00 00    	ja     f01045c0 <__udivdi3+0xf0>
f01044fb:	85 ff                	test   %edi,%edi
f01044fd:	89 fd                	mov    %edi,%ebp
f01044ff:	75 0b                	jne    f010450c <__udivdi3+0x3c>
f0104501:	b8 01 00 00 00       	mov    $0x1,%eax
f0104506:	31 d2                	xor    %edx,%edx
f0104508:	f7 f7                	div    %edi
f010450a:	89 c5                	mov    %eax,%ebp
f010450c:	89 c8                	mov    %ecx,%eax
f010450e:	31 d2                	xor    %edx,%edx
f0104510:	f7 f5                	div    %ebp
f0104512:	89 c1                	mov    %eax,%ecx
f0104514:	89 d8                	mov    %ebx,%eax
f0104516:	89 cf                	mov    %ecx,%edi
f0104518:	f7 f5                	div    %ebp
f010451a:	89 c3                	mov    %eax,%ebx
f010451c:	89 d8                	mov    %ebx,%eax
f010451e:	89 fa                	mov    %edi,%edx
f0104520:	83 c4 1c             	add    $0x1c,%esp
f0104523:	5b                   	pop    %ebx
f0104524:	5e                   	pop    %esi
f0104525:	5f                   	pop    %edi
f0104526:	5d                   	pop    %ebp
f0104527:	c3                   	ret    
f0104528:	90                   	nop
f0104529:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104530:	39 ce                	cmp    %ecx,%esi
f0104532:	77 74                	ja     f01045a8 <__udivdi3+0xd8>
f0104534:	0f bd fe             	bsr    %esi,%edi
f0104537:	83 f7 1f             	xor    $0x1f,%edi
f010453a:	0f 84 98 00 00 00    	je     f01045d8 <__udivdi3+0x108>
f0104540:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104545:	89 f9                	mov    %edi,%ecx
f0104547:	89 c5                	mov    %eax,%ebp
f0104549:	29 fb                	sub    %edi,%ebx
f010454b:	d3 e6                	shl    %cl,%esi
f010454d:	89 d9                	mov    %ebx,%ecx
f010454f:	d3 ed                	shr    %cl,%ebp
f0104551:	89 f9                	mov    %edi,%ecx
f0104553:	d3 e0                	shl    %cl,%eax
f0104555:	09 ee                	or     %ebp,%esi
f0104557:	89 d9                	mov    %ebx,%ecx
f0104559:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010455d:	89 d5                	mov    %edx,%ebp
f010455f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104563:	d3 ed                	shr    %cl,%ebp
f0104565:	89 f9                	mov    %edi,%ecx
f0104567:	d3 e2                	shl    %cl,%edx
f0104569:	89 d9                	mov    %ebx,%ecx
f010456b:	d3 e8                	shr    %cl,%eax
f010456d:	09 c2                	or     %eax,%edx
f010456f:	89 d0                	mov    %edx,%eax
f0104571:	89 ea                	mov    %ebp,%edx
f0104573:	f7 f6                	div    %esi
f0104575:	89 d5                	mov    %edx,%ebp
f0104577:	89 c3                	mov    %eax,%ebx
f0104579:	f7 64 24 0c          	mull   0xc(%esp)
f010457d:	39 d5                	cmp    %edx,%ebp
f010457f:	72 10                	jb     f0104591 <__udivdi3+0xc1>
f0104581:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104585:	89 f9                	mov    %edi,%ecx
f0104587:	d3 e6                	shl    %cl,%esi
f0104589:	39 c6                	cmp    %eax,%esi
f010458b:	73 07                	jae    f0104594 <__udivdi3+0xc4>
f010458d:	39 d5                	cmp    %edx,%ebp
f010458f:	75 03                	jne    f0104594 <__udivdi3+0xc4>
f0104591:	83 eb 01             	sub    $0x1,%ebx
f0104594:	31 ff                	xor    %edi,%edi
f0104596:	89 d8                	mov    %ebx,%eax
f0104598:	89 fa                	mov    %edi,%edx
f010459a:	83 c4 1c             	add    $0x1c,%esp
f010459d:	5b                   	pop    %ebx
f010459e:	5e                   	pop    %esi
f010459f:	5f                   	pop    %edi
f01045a0:	5d                   	pop    %ebp
f01045a1:	c3                   	ret    
f01045a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01045a8:	31 ff                	xor    %edi,%edi
f01045aa:	31 db                	xor    %ebx,%ebx
f01045ac:	89 d8                	mov    %ebx,%eax
f01045ae:	89 fa                	mov    %edi,%edx
f01045b0:	83 c4 1c             	add    $0x1c,%esp
f01045b3:	5b                   	pop    %ebx
f01045b4:	5e                   	pop    %esi
f01045b5:	5f                   	pop    %edi
f01045b6:	5d                   	pop    %ebp
f01045b7:	c3                   	ret    
f01045b8:	90                   	nop
f01045b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01045c0:	89 d8                	mov    %ebx,%eax
f01045c2:	f7 f7                	div    %edi
f01045c4:	31 ff                	xor    %edi,%edi
f01045c6:	89 c3                	mov    %eax,%ebx
f01045c8:	89 d8                	mov    %ebx,%eax
f01045ca:	89 fa                	mov    %edi,%edx
f01045cc:	83 c4 1c             	add    $0x1c,%esp
f01045cf:	5b                   	pop    %ebx
f01045d0:	5e                   	pop    %esi
f01045d1:	5f                   	pop    %edi
f01045d2:	5d                   	pop    %ebp
f01045d3:	c3                   	ret    
f01045d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01045d8:	39 ce                	cmp    %ecx,%esi
f01045da:	72 0c                	jb     f01045e8 <__udivdi3+0x118>
f01045dc:	31 db                	xor    %ebx,%ebx
f01045de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01045e2:	0f 87 34 ff ff ff    	ja     f010451c <__udivdi3+0x4c>
f01045e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01045ed:	e9 2a ff ff ff       	jmp    f010451c <__udivdi3+0x4c>
f01045f2:	66 90                	xchg   %ax,%ax
f01045f4:	66 90                	xchg   %ax,%ax
f01045f6:	66 90                	xchg   %ax,%ax
f01045f8:	66 90                	xchg   %ax,%ax
f01045fa:	66 90                	xchg   %ax,%ax
f01045fc:	66 90                	xchg   %ax,%ax
f01045fe:	66 90                	xchg   %ax,%ax

f0104600 <__umoddi3>:
f0104600:	55                   	push   %ebp
f0104601:	57                   	push   %edi
f0104602:	56                   	push   %esi
f0104603:	53                   	push   %ebx
f0104604:	83 ec 1c             	sub    $0x1c,%esp
f0104607:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010460b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010460f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104613:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104617:	85 d2                	test   %edx,%edx
f0104619:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010461d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104621:	89 f3                	mov    %esi,%ebx
f0104623:	89 3c 24             	mov    %edi,(%esp)
f0104626:	89 74 24 04          	mov    %esi,0x4(%esp)
f010462a:	75 1c                	jne    f0104648 <__umoddi3+0x48>
f010462c:	39 f7                	cmp    %esi,%edi
f010462e:	76 50                	jbe    f0104680 <__umoddi3+0x80>
f0104630:	89 c8                	mov    %ecx,%eax
f0104632:	89 f2                	mov    %esi,%edx
f0104634:	f7 f7                	div    %edi
f0104636:	89 d0                	mov    %edx,%eax
f0104638:	31 d2                	xor    %edx,%edx
f010463a:	83 c4 1c             	add    $0x1c,%esp
f010463d:	5b                   	pop    %ebx
f010463e:	5e                   	pop    %esi
f010463f:	5f                   	pop    %edi
f0104640:	5d                   	pop    %ebp
f0104641:	c3                   	ret    
f0104642:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104648:	39 f2                	cmp    %esi,%edx
f010464a:	89 d0                	mov    %edx,%eax
f010464c:	77 52                	ja     f01046a0 <__umoddi3+0xa0>
f010464e:	0f bd ea             	bsr    %edx,%ebp
f0104651:	83 f5 1f             	xor    $0x1f,%ebp
f0104654:	75 5a                	jne    f01046b0 <__umoddi3+0xb0>
f0104656:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010465a:	0f 82 e0 00 00 00    	jb     f0104740 <__umoddi3+0x140>
f0104660:	39 0c 24             	cmp    %ecx,(%esp)
f0104663:	0f 86 d7 00 00 00    	jbe    f0104740 <__umoddi3+0x140>
f0104669:	8b 44 24 08          	mov    0x8(%esp),%eax
f010466d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104671:	83 c4 1c             	add    $0x1c,%esp
f0104674:	5b                   	pop    %ebx
f0104675:	5e                   	pop    %esi
f0104676:	5f                   	pop    %edi
f0104677:	5d                   	pop    %ebp
f0104678:	c3                   	ret    
f0104679:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104680:	85 ff                	test   %edi,%edi
f0104682:	89 fd                	mov    %edi,%ebp
f0104684:	75 0b                	jne    f0104691 <__umoddi3+0x91>
f0104686:	b8 01 00 00 00       	mov    $0x1,%eax
f010468b:	31 d2                	xor    %edx,%edx
f010468d:	f7 f7                	div    %edi
f010468f:	89 c5                	mov    %eax,%ebp
f0104691:	89 f0                	mov    %esi,%eax
f0104693:	31 d2                	xor    %edx,%edx
f0104695:	f7 f5                	div    %ebp
f0104697:	89 c8                	mov    %ecx,%eax
f0104699:	f7 f5                	div    %ebp
f010469b:	89 d0                	mov    %edx,%eax
f010469d:	eb 99                	jmp    f0104638 <__umoddi3+0x38>
f010469f:	90                   	nop
f01046a0:	89 c8                	mov    %ecx,%eax
f01046a2:	89 f2                	mov    %esi,%edx
f01046a4:	83 c4 1c             	add    $0x1c,%esp
f01046a7:	5b                   	pop    %ebx
f01046a8:	5e                   	pop    %esi
f01046a9:	5f                   	pop    %edi
f01046aa:	5d                   	pop    %ebp
f01046ab:	c3                   	ret    
f01046ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01046b0:	8b 34 24             	mov    (%esp),%esi
f01046b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01046b8:	89 e9                	mov    %ebp,%ecx
f01046ba:	29 ef                	sub    %ebp,%edi
f01046bc:	d3 e0                	shl    %cl,%eax
f01046be:	89 f9                	mov    %edi,%ecx
f01046c0:	89 f2                	mov    %esi,%edx
f01046c2:	d3 ea                	shr    %cl,%edx
f01046c4:	89 e9                	mov    %ebp,%ecx
f01046c6:	09 c2                	or     %eax,%edx
f01046c8:	89 d8                	mov    %ebx,%eax
f01046ca:	89 14 24             	mov    %edx,(%esp)
f01046cd:	89 f2                	mov    %esi,%edx
f01046cf:	d3 e2                	shl    %cl,%edx
f01046d1:	89 f9                	mov    %edi,%ecx
f01046d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01046d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01046db:	d3 e8                	shr    %cl,%eax
f01046dd:	89 e9                	mov    %ebp,%ecx
f01046df:	89 c6                	mov    %eax,%esi
f01046e1:	d3 e3                	shl    %cl,%ebx
f01046e3:	89 f9                	mov    %edi,%ecx
f01046e5:	89 d0                	mov    %edx,%eax
f01046e7:	d3 e8                	shr    %cl,%eax
f01046e9:	89 e9                	mov    %ebp,%ecx
f01046eb:	09 d8                	or     %ebx,%eax
f01046ed:	89 d3                	mov    %edx,%ebx
f01046ef:	89 f2                	mov    %esi,%edx
f01046f1:	f7 34 24             	divl   (%esp)
f01046f4:	89 d6                	mov    %edx,%esi
f01046f6:	d3 e3                	shl    %cl,%ebx
f01046f8:	f7 64 24 04          	mull   0x4(%esp)
f01046fc:	39 d6                	cmp    %edx,%esi
f01046fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104702:	89 d1                	mov    %edx,%ecx
f0104704:	89 c3                	mov    %eax,%ebx
f0104706:	72 08                	jb     f0104710 <__umoddi3+0x110>
f0104708:	75 11                	jne    f010471b <__umoddi3+0x11b>
f010470a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010470e:	73 0b                	jae    f010471b <__umoddi3+0x11b>
f0104710:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104714:	1b 14 24             	sbb    (%esp),%edx
f0104717:	89 d1                	mov    %edx,%ecx
f0104719:	89 c3                	mov    %eax,%ebx
f010471b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010471f:	29 da                	sub    %ebx,%edx
f0104721:	19 ce                	sbb    %ecx,%esi
f0104723:	89 f9                	mov    %edi,%ecx
f0104725:	89 f0                	mov    %esi,%eax
f0104727:	d3 e0                	shl    %cl,%eax
f0104729:	89 e9                	mov    %ebp,%ecx
f010472b:	d3 ea                	shr    %cl,%edx
f010472d:	89 e9                	mov    %ebp,%ecx
f010472f:	d3 ee                	shr    %cl,%esi
f0104731:	09 d0                	or     %edx,%eax
f0104733:	89 f2                	mov    %esi,%edx
f0104735:	83 c4 1c             	add    $0x1c,%esp
f0104738:	5b                   	pop    %ebx
f0104739:	5e                   	pop    %esi
f010473a:	5f                   	pop    %edi
f010473b:	5d                   	pop    %ebp
f010473c:	c3                   	ret    
f010473d:	8d 76 00             	lea    0x0(%esi),%esi
f0104740:	29 f9                	sub    %edi,%ecx
f0104742:	19 d6                	sbb    %edx,%esi
f0104744:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104748:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010474c:	e9 18 ff ff ff       	jmp    f0104669 <__umoddi3+0x69>
