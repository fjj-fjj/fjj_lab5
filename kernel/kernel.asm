
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c4478793          	addi	a5,a5,-956 # 80005ca0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0278793          	addi	a5,a5,-510 # 80000ea8 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	af2080e7          	jalr	-1294(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3a6080e7          	jalr	934(ra) # 800024cc <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b64080e7          	jalr	-1180(ra) # 80000cb2 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	a62080e7          	jalr	-1438(ra) # 80000bfe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	83e080e7          	jalr	-1986(ra) # 80001a08 <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	042080e7          	jalr	66(ra) # 8000221c <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	260080e7          	jalr	608(ra) # 80002476 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a80080e7          	jalr	-1408(ra) # 80000cb2 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	926080e7          	jalr	-1754(ra) # 80000bfe <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	22c080e7          	jalr	556(ra) # 80002522 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9ac080e7          	jalr	-1620(ra) # 80000cb2 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	f52080e7          	jalr	-174(ra) # 8000239c <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	702080e7          	jalr	1794(ra) # 80000b6e <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	53478793          	addi	a5,a5,1332 # 800219b0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b5850513          	addi	a0,a0,-1192 # 800080c8 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5fa080e7          	jalr	1530(ra) # 80000bfe <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	550080e7          	jalr	1360(ra) # 80000cb2 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	3e6080e7          	jalr	998(ra) # 80000b6e <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	390080e7          	jalr	912(ra) # 80000b6e <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3b8080e7          	jalr	952(ra) # 80000bb2 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	42a080e7          	jalr	1066(ra) # 80000c52 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	afa080e7          	jalr	-1286(ra) # 8000239c <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	318080e7          	jalr	792(ra) # 80000bfe <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	8e0080e7          	jalr	-1824(ra) # 8000221c <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	330080e7          	jalr	816(ra) # 80000cb2 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	210080e7          	jalr	528(ra) # 80000bfe <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b2080e7          	jalr	690(ra) # 80000cb2 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2bc080e7          	jalr	700(ra) # 80000cfa <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1ae080e7          	jalr	430(ra) # 80000bfe <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	24e080e7          	jalr	590(ra) # 80000cb2 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac2080e7          	jalr	-1342(ra) # 80000542 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0095ee63          	bltu	a1,s1,80000ac2 <freerange+0x3a>
    80000aaa:	892e                	mv	s2,a1
    kfree(p);
    80000aac:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	6985                	lui	s3,0x1
    kfree(p);
    80000ab0:	01448533          	add	a0,s1,s4
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	f5e080e7          	jalr	-162(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94ce                	add	s1,s1,s3
    80000abe:	fe9979e3          	bgeu	s2,s1,80000ab0 <freerange+0x28>
}
    80000ac2:	70a2                	ld	ra,40(sp)
    80000ac4:	7402                	ld	s0,32(sp)
    80000ac6:	64e2                	ld	s1,24(sp)
    80000ac8:	6942                	ld	s2,16(sp)
    80000aca:	69a2                	ld	s3,8(sp)
    80000acc:	6a02                	ld	s4,0(sp)
    80000ace:	6145                	addi	sp,sp,48
    80000ad0:	8082                	ret

0000000080000ad2 <kinit>:
{
    80000ad2:	1141                	addi	sp,sp,-16
    80000ad4:	e406                	sd	ra,8(sp)
    80000ad6:	e022                	sd	s0,0(sp)
    80000ad8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ada:	00007597          	auipc	a1,0x7
    80000ade:	58e58593          	addi	a1,a1,1422 # 80008068 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	084080e7          	jalr	132(ra) # 80000b6e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00025517          	auipc	a0,0x25
    80000afa:	50a50513          	addi	a0,a0,1290 # 80026000 <end>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f8a080e7          	jalr	-118(ra) # 80000a88 <freerange>
}
    80000b06:	60a2                	ld	ra,8(sp)
    80000b08:	6402                	ld	s0,0(sp)
    80000b0a:	0141                	addi	sp,sp,16
    80000b0c:	8082                	ret

0000000080000b0e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b18:	00011497          	auipc	s1,0x11
    80000b1c:	e1848493          	addi	s1,s1,-488 # 80011930 <kmem>
    80000b20:	8526                	mv	a0,s1
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	0dc080e7          	jalr	220(ra) # 80000bfe <acquire>
  r = kmem.freelist;
    80000b2a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2c:	c885                	beqz	s1,80000b5c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2e:	609c                	ld	a5,0(s1)
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	e0050513          	addi	a0,a0,-512 # 80011930 <kmem>
    80000b38:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	178080e7          	jalr	376(ra) # 80000cb2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	1b2080e7          	jalr	434(ra) # 80000cfa <memset>
  return (void*)r;
}
    80000b50:	8526                	mv	a0,s1
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6105                	addi	sp,sp,32
    80000b5a:	8082                	ret
  release(&kmem.lock);
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	14e080e7          	jalr	334(ra) # 80000cb2 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7a:	00053823          	sd	zero,16(a0)
}
    80000b7e:	6422                	ld	s0,8(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b84:	411c                	lw	a5,0(a0)
    80000b86:	e399                	bnez	a5,80000b8c <holding+0x8>
    80000b88:	4501                	li	a0,0
  return r;
}
    80000b8a:	8082                	ret
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	6904                	ld	s1,16(a0)
    80000b98:	00001097          	auipc	ra,0x1
    80000b9c:	e54080e7          	jalr	-428(ra) # 800019ec <mycpu>
    80000ba0:	40a48533          	sub	a0,s1,a0
    80000ba4:	00153513          	seqz	a0,a0
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret

0000000080000bb2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb2:	1101                	addi	sp,sp,-32
    80000bb4:	ec06                	sd	ra,24(sp)
    80000bb6:	e822                	sd	s0,16(sp)
    80000bb8:	e426                	sd	s1,8(sp)
    80000bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbc:	100024f3          	csrr	s1,sstatus
    80000bc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bca:	00001097          	auipc	ra,0x1
    80000bce:	e22080e7          	jalr	-478(ra) # 800019ec <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	e16080e7          	jalr	-490(ra) # 800019ec <mycpu>
    80000bde:	5d3c                	lw	a5,120(a0)
    80000be0:	2785                	addiw	a5,a5,1
    80000be2:	dd3c                	sw	a5,120(a0)
}
    80000be4:	60e2                	ld	ra,24(sp)
    80000be6:	6442                	ld	s0,16(sp)
    80000be8:	64a2                	ld	s1,8(sp)
    80000bea:	6105                	addi	sp,sp,32
    80000bec:	8082                	ret
    mycpu()->intena = old;
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	dfe080e7          	jalr	-514(ra) # 800019ec <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf6:	8085                	srli	s1,s1,0x1
    80000bf8:	8885                	andi	s1,s1,1
    80000bfa:	dd64                	sw	s1,124(a0)
    80000bfc:	bfe9                	j	80000bd6 <push_off+0x24>

0000000080000bfe <acquire>:
{
    80000bfe:	1101                	addi	sp,sp,-32
    80000c00:	ec06                	sd	ra,24(sp)
    80000c02:	e822                	sd	s0,16(sp)
    80000c04:	e426                	sd	s1,8(sp)
    80000c06:	1000                	addi	s0,sp,32
    80000c08:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	fa8080e7          	jalr	-88(ra) # 80000bb2 <push_off>
  if(holding(lk))
    80000c12:	8526                	mv	a0,s1
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	f70080e7          	jalr	-144(ra) # 80000b84 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1c:	4705                	li	a4,1
  if(holding(lk))
    80000c1e:	e115                	bnez	a0,80000c42 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c20:	87ba                	mv	a5,a4
    80000c22:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c26:	2781                	sext.w	a5,a5
    80000c28:	ffe5                	bnez	a5,80000c20 <acquire+0x22>
  __sync_synchronize();
    80000c2a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	dbe080e7          	jalr	-578(ra) # 800019ec <mycpu>
    80000c36:	e888                	sd	a0,16(s1)
}
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret
    panic("acquire");
    80000c42:	00007517          	auipc	a0,0x7
    80000c46:	42e50513          	addi	a0,a0,1070 # 80008070 <digits+0x30>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	8f8080e7          	jalr	-1800(ra) # 80000542 <panic>

0000000080000c52 <pop_off>:

void
pop_off(void)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e406                	sd	ra,8(sp)
    80000c56:	e022                	sd	s0,0(sp)
    80000c58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	d92080e7          	jalr	-622(ra) # 800019ec <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c68:	e78d                	bnez	a5,80000c92 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	02f05b63          	blez	a5,80000ca2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c70:	37fd                	addiw	a5,a5,-1
    80000c72:	0007871b          	sext.w	a4,a5
    80000c76:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c78:	eb09                	bnez	a4,80000c8a <pop_off+0x38>
    80000c7a:	5d7c                	lw	a5,124(a0)
    80000c7c:	c799                	beqz	a5,80000c8a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c86:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8a:	60a2                	ld	ra,8(sp)
    80000c8c:	6402                	ld	s0,0(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret
    panic("pop_off - interruptible");
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3e650513          	addi	a0,a0,998 # 80008078 <digits+0x38>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	8a8080e7          	jalr	-1880(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca2:	00007517          	auipc	a0,0x7
    80000ca6:	3ee50513          	addi	a0,a0,1006 # 80008090 <digits+0x50>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	898080e7          	jalr	-1896(ra) # 80000542 <panic>

0000000080000cb2 <release>:
{
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	1000                	addi	s0,sp,32
    80000cbc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	ec6080e7          	jalr	-314(ra) # 80000b84 <holding>
    80000cc6:	c115                	beqz	a0,80000cea <release+0x38>
  lk->cpu = 0;
    80000cc8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ccc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd0:	0f50000f          	fence	iorw,ow
    80000cd4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	f7a080e7          	jalr	-134(ra) # 80000c52 <pop_off>
}
    80000ce0:	60e2                	ld	ra,24(sp)
    80000ce2:	6442                	ld	s0,16(sp)
    80000ce4:	64a2                	ld	s1,8(sp)
    80000ce6:	6105                	addi	sp,sp,32
    80000ce8:	8082                	ret
    panic("release");
    80000cea:	00007517          	auipc	a0,0x7
    80000cee:	3ae50513          	addi	a0,a0,942 # 80008098 <digits+0x58>
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	850080e7          	jalr	-1968(ra) # 80000542 <panic>

0000000080000cfa <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfa:	1141                	addi	sp,sp,-16
    80000cfc:	e422                	sd	s0,8(sp)
    80000cfe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d00:	ca19                	beqz	a2,80000d16 <memset+0x1c>
    80000d02:	87aa                	mv	a5,a0
    80000d04:	1602                	slli	a2,a2,0x20
    80000d06:	9201                	srli	a2,a2,0x20
    80000d08:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d10:	0785                	addi	a5,a5,1
    80000d12:	fee79de3          	bne	a5,a4,80000d0c <memset+0x12>
  }
  return dst;
}
    80000d16:	6422                	ld	s0,8(sp)
    80000d18:	0141                	addi	sp,sp,16
    80000d1a:	8082                	ret

0000000080000d1c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d22:	ca05                	beqz	a2,80000d52 <memcmp+0x36>
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	1682                	slli	a3,a3,0x20
    80000d2a:	9281                	srli	a3,a3,0x20
    80000d2c:	0685                	addi	a3,a3,1
    80000d2e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d30:	00054783          	lbu	a5,0(a0)
    80000d34:	0005c703          	lbu	a4,0(a1)
    80000d38:	00e79863          	bne	a5,a4,80000d48 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3c:	0505                	addi	a0,a0,1
    80000d3e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d40:	fed518e3          	bne	a0,a3,80000d30 <memcmp+0x14>
  }

  return 0;
    80000d44:	4501                	li	a0,0
    80000d46:	a019                	j	80000d4c <memcmp+0x30>
      return *s1 - *s2;
    80000d48:	40e7853b          	subw	a0,a5,a4
}
    80000d4c:	6422                	ld	s0,8(sp)
    80000d4e:	0141                	addi	sp,sp,16
    80000d50:	8082                	ret
  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	bfe5                	j	80000d4c <memcmp+0x30>

0000000080000d56 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5c:	02a5e563          	bltu	a1,a0,80000d86 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6069b          	addiw	a3,a2,-1
    80000d64:	ce11                	beqz	a2,80000d80 <memmove+0x2a>
    80000d66:	1682                	slli	a3,a3,0x20
    80000d68:	9281                	srli	a3,a3,0x20
    80000d6a:	0685                	addi	a3,a3,1
    80000d6c:	96ae                	add	a3,a3,a1
    80000d6e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d70:	0585                	addi	a1,a1,1
    80000d72:	0785                	addi	a5,a5,1
    80000d74:	fff5c703          	lbu	a4,-1(a1)
    80000d78:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7c:	fed59ae3          	bne	a1,a3,80000d70 <memmove+0x1a>

  return dst;
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret
  if(s < d && s + n > d){
    80000d86:	02061713          	slli	a4,a2,0x20
    80000d8a:	9301                	srli	a4,a4,0x20
    80000d8c:	00e587b3          	add	a5,a1,a4
    80000d90:	fcf578e3          	bgeu	a0,a5,80000d60 <memmove+0xa>
    d += n;
    80000d94:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	d27d                	beqz	a2,80000d80 <memmove+0x2a>
    80000d9c:	02069613          	slli	a2,a3,0x20
    80000da0:	9201                	srli	a2,a2,0x20
    80000da2:	fff64613          	not	a2,a2
    80000da6:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da8:	17fd                	addi	a5,a5,-1
    80000daa:	177d                	addi	a4,a4,-1
    80000dac:	0007c683          	lbu	a3,0(a5)
    80000db0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db4:	fef61ae3          	bne	a2,a5,80000da8 <memmove+0x52>
    80000db8:	b7e1                	j	80000d80 <memmove+0x2a>

0000000080000dba <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e406                	sd	ra,8(sp)
    80000dbe:	e022                	sd	s0,0(sp)
    80000dc0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f94080e7          	jalr	-108(ra) # 80000d56 <memmove>
}
    80000dca:	60a2                	ld	ra,8(sp)
    80000dcc:	6402                	ld	s0,0(sp)
    80000dce:	0141                	addi	sp,sp,16
    80000dd0:	8082                	ret

0000000080000dd2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd8:	ce11                	beqz	a2,80000df4 <strncmp+0x22>
    80000dda:	00054783          	lbu	a5,0(a0)
    80000dde:	cf89                	beqz	a5,80000df8 <strncmp+0x26>
    80000de0:	0005c703          	lbu	a4,0(a1)
    80000de4:	00f71a63          	bne	a4,a5,80000df8 <strncmp+0x26>
    n--, p++, q++;
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	0505                	addi	a0,a0,1
    80000dec:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dee:	f675                	bnez	a2,80000dda <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	a809                	j	80000e04 <strncmp+0x32>
    80000df4:	4501                	li	a0,0
    80000df6:	a039                	j	80000e04 <strncmp+0x32>
  if(n == 0)
    80000df8:	ca09                	beqz	a2,80000e0a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfa:	00054503          	lbu	a0,0(a0)
    80000dfe:	0005c783          	lbu	a5,0(a1)
    80000e02:	9d1d                	subw	a0,a0,a5
}
    80000e04:	6422                	ld	s0,8(sp)
    80000e06:	0141                	addi	sp,sp,16
    80000e08:	8082                	ret
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	bfe5                	j	80000e04 <strncmp+0x32>

0000000080000e0e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0e:	1141                	addi	sp,sp,-16
    80000e10:	e422                	sd	s0,8(sp)
    80000e12:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e14:	872a                	mv	a4,a0
    80000e16:	8832                	mv	a6,a2
    80000e18:	367d                	addiw	a2,a2,-1
    80000e1a:	01005963          	blez	a6,80000e2c <strncpy+0x1e>
    80000e1e:	0705                	addi	a4,a4,1
    80000e20:	0005c783          	lbu	a5,0(a1)
    80000e24:	fef70fa3          	sb	a5,-1(a4)
    80000e28:	0585                	addi	a1,a1,1
    80000e2a:	f7f5                	bnez	a5,80000e16 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2c:	86ba                	mv	a3,a4
    80000e2e:	00c05c63          	blez	a2,80000e46 <strncpy+0x38>
    *s++ = 0;
    80000e32:	0685                	addi	a3,a3,1
    80000e34:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e38:	fff6c793          	not	a5,a3
    80000e3c:	9fb9                	addw	a5,a5,a4
    80000e3e:	010787bb          	addw	a5,a5,a6
    80000e42:	fef048e3          	bgtz	a5,80000e32 <strncpy+0x24>
  return os;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e52:	02c05363          	blez	a2,80000e78 <safestrcpy+0x2c>
    80000e56:	fff6069b          	addiw	a3,a2,-1
    80000e5a:	1682                	slli	a3,a3,0x20
    80000e5c:	9281                	srli	a3,a3,0x20
    80000e5e:	96ae                	add	a3,a3,a1
    80000e60:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e62:	00d58963          	beq	a1,a3,80000e74 <safestrcpy+0x28>
    80000e66:	0585                	addi	a1,a1,1
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fff5c703          	lbu	a4,-1(a1)
    80000e6e:	fee78fa3          	sb	a4,-1(a5)
    80000e72:	fb65                	bnez	a4,80000e62 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e74:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret

0000000080000e7e <strlen>:

int
strlen(const char *s)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e422                	sd	s0,8(sp)
    80000e82:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e84:	00054783          	lbu	a5,0(a0)
    80000e88:	cf91                	beqz	a5,80000ea4 <strlen+0x26>
    80000e8a:	0505                	addi	a0,a0,1
    80000e8c:	87aa                	mv	a5,a0
    80000e8e:	4685                	li	a3,1
    80000e90:	9e89                	subw	a3,a3,a0
    80000e92:	00f6853b          	addw	a0,a3,a5
    80000e96:	0785                	addi	a5,a5,1
    80000e98:	fff7c703          	lbu	a4,-1(a5)
    80000e9c:	fb7d                	bnez	a4,80000e92 <strlen+0x14>
    ;
  return n;
}
    80000e9e:	6422                	ld	s0,8(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea4:	4501                	li	a0,0
    80000ea6:	bfe5                	j	80000e9e <strlen+0x20>

0000000080000ea8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e406                	sd	ra,8(sp)
    80000eac:	e022                	sd	s0,0(sp)
    80000eae:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	b2c080e7          	jalr	-1236(ra) # 800019dc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb8:	00008717          	auipc	a4,0x8
    80000ebc:	15470713          	addi	a4,a4,340 # 8000900c <started>
  if(cpuid() == 0){
    80000ec0:	c139                	beqz	a0,80000f06 <main+0x5e>
    while(started == 0)
    80000ec2:	431c                	lw	a5,0(a4)
    80000ec4:	2781                	sext.w	a5,a5
    80000ec6:	dff5                	beqz	a5,80000ec2 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	b10080e7          	jalr	-1264(ra) # 800019dc <cpuid>
    80000ed4:	85aa                	mv	a1,a0
    80000ed6:	00007517          	auipc	a0,0x7
    80000eda:	1e250513          	addi	a0,a0,482 # 800080b8 <digits+0x78>
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	6ae080e7          	jalr	1710(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	0d8080e7          	jalr	216(ra) # 80000fbe <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	00001097          	auipc	ra,0x1
    80000ef2:	774080e7          	jalr	1908(ra) # 80002662 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	dea080e7          	jalr	-534(ra) # 80005ce0 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	03e080e7          	jalr	62(ra) # 80001f3c <scheduler>
    consoleinit();
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	54e080e7          	jalr	1358(ra) # 80000454 <consoleinit>
    printfinit();
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	85e080e7          	jalr	-1954(ra) # 8000076c <printfinit>
    printf("\n");
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1b250513          	addi	a0,a0,434 # 800080c8 <digits+0x88>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66e080e7          	jalr	1646(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f26:	00007517          	auipc	a0,0x7
    80000f2a:	17a50513          	addi	a0,a0,378 # 800080a0 <digits+0x60>
    80000f2e:	fffff097          	auipc	ra,0xfffff
    80000f32:	65e080e7          	jalr	1630(ra) # 8000058c <printf>
    printf("\n");
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	19250513          	addi	a0,a0,402 # 800080c8 <digits+0x88>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	64e080e7          	jalr	1614(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	b8c080e7          	jalr	-1140(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	318080e7          	jalr	792(ra) # 80001266 <kvminit>
    kvminithart();   // turn on paging
    80000f56:	00000097          	auipc	ra,0x0
    80000f5a:	068080e7          	jalr	104(ra) # 80000fbe <kvminithart>
    procinit();      // process table
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	9ae080e7          	jalr	-1618(ra) # 8000190c <procinit>
    trapinit();      // trap vectors
    80000f66:	00001097          	auipc	ra,0x1
    80000f6a:	6d4080e7          	jalr	1748(ra) # 8000263a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	6f4080e7          	jalr	1780(ra) # 80002662 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	d54080e7          	jalr	-684(ra) # 80005cca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f7e:	00005097          	auipc	ra,0x5
    80000f82:	d62080e7          	jalr	-670(ra) # 80005ce0 <plicinithart>
    binit();         // buffer cache
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	f0e080e7          	jalr	-242(ra) # 80002e94 <binit>
    iinit();         // inode cache
    80000f8e:	00002097          	auipc	ra,0x2
    80000f92:	59e080e7          	jalr	1438(ra) # 8000352c <iinit>
    fileinit();      // file table
    80000f96:	00003097          	auipc	ra,0x3
    80000f9a:	53c080e7          	jalr	1340(ra) # 800044d2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f9e:	00005097          	auipc	ra,0x5
    80000fa2:	e4a080e7          	jalr	-438(ra) # 80005de8 <virtio_disk_init>
    userinit();      // first user process
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	d2c080e7          	jalr	-724(ra) # 80001cd2 <userinit>
    __sync_synchronize();
    80000fae:	0ff0000f          	fence
    started = 1;
    80000fb2:	4785                	li	a5,1
    80000fb4:	00008717          	auipc	a4,0x8
    80000fb8:	04f72c23          	sw	a5,88(a4) # 8000900c <started>
    80000fbc:	b789                	j	80000efe <main+0x56>

0000000080000fbe <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fbe:	1141                	addi	sp,sp,-16
    80000fc0:	e422                	sd	s0,8(sp)
    80000fc2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fc4:	00008797          	auipc	a5,0x8
    80000fc8:	04c7b783          	ld	a5,76(a5) # 80009010 <kernel_pagetable>
    80000fcc:	83b1                	srli	a5,a5,0xc
    80000fce:	577d                	li	a4,-1
    80000fd0:	177e                	slli	a4,a4,0x3f
    80000fd2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fd4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fd8:	12000073          	sfence.vma
  sfence_vma();
}
    80000fdc:	6422                	ld	s0,8(sp)
    80000fde:	0141                	addi	sp,sp,16
    80000fe0:	8082                	ret

0000000080000fe2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe2:	7139                	addi	sp,sp,-64
    80000fe4:	fc06                	sd	ra,56(sp)
    80000fe6:	f822                	sd	s0,48(sp)
    80000fe8:	f426                	sd	s1,40(sp)
    80000fea:	f04a                	sd	s2,32(sp)
    80000fec:	ec4e                	sd	s3,24(sp)
    80000fee:	e852                	sd	s4,16(sp)
    80000ff0:	e456                	sd	s5,8(sp)
    80000ff2:	e05a                	sd	s6,0(sp)
    80000ff4:	0080                	addi	s0,sp,64
    80000ff6:	84aa                	mv	s1,a0
    80000ff8:	89ae                	mv	s3,a1
    80000ffa:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ffc:	57fd                	li	a5,-1
    80000ffe:	83e9                	srli	a5,a5,0x1a
    80001000:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001002:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001004:	04b7f263          	bgeu	a5,a1,80001048 <walk+0x66>
    panic("walk");
    80001008:	00007517          	auipc	a0,0x7
    8000100c:	0c850513          	addi	a0,a0,200 # 800080d0 <digits+0x90>
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	532080e7          	jalr	1330(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001018:	060a8663          	beqz	s5,80001084 <walk+0xa2>
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	af2080e7          	jalr	-1294(ra) # 80000b0e <kalloc>
    80001024:	84aa                	mv	s1,a0
    80001026:	c529                	beqz	a0,80001070 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001028:	6605                	lui	a2,0x1
    8000102a:	4581                	li	a1,0
    8000102c:	00000097          	auipc	ra,0x0
    80001030:	cce080e7          	jalr	-818(ra) # 80000cfa <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001034:	00c4d793          	srli	a5,s1,0xc
    80001038:	07aa                	slli	a5,a5,0xa
    8000103a:	0017e793          	ori	a5,a5,1
    8000103e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001042:	3a5d                	addiw	s4,s4,-9
    80001044:	036a0063          	beq	s4,s6,80001064 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001048:	0149d933          	srl	s2,s3,s4
    8000104c:	1ff97913          	andi	s2,s2,511
    80001050:	090e                	slli	s2,s2,0x3
    80001052:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001054:	00093483          	ld	s1,0(s2)
    80001058:	0014f793          	andi	a5,s1,1
    8000105c:	dfd5                	beqz	a5,80001018 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000105e:	80a9                	srli	s1,s1,0xa
    80001060:	04b2                	slli	s1,s1,0xc
    80001062:	b7c5                	j	80001042 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001064:	00c9d513          	srli	a0,s3,0xc
    80001068:	1ff57513          	andi	a0,a0,511
    8000106c:	050e                	slli	a0,a0,0x3
    8000106e:	9526                	add	a0,a0,s1
}
    80001070:	70e2                	ld	ra,56(sp)
    80001072:	7442                	ld	s0,48(sp)
    80001074:	74a2                	ld	s1,40(sp)
    80001076:	7902                	ld	s2,32(sp)
    80001078:	69e2                	ld	s3,24(sp)
    8000107a:	6a42                	ld	s4,16(sp)
    8000107c:	6aa2                	ld	s5,8(sp)
    8000107e:	6b02                	ld	s6,0(sp)
    80001080:	6121                	addi	sp,sp,64
    80001082:	8082                	ret
        return 0;
    80001084:	4501                	li	a0,0
    80001086:	b7ed                	j	80001070 <walk+0x8e>

0000000080001088 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001088:	1101                	addi	sp,sp,-32
    8000108a:	ec06                	sd	ra,24(sp)
    8000108c:	e822                	sd	s0,16(sp)
    8000108e:	e426                	sd	s1,8(sp)
    80001090:	1000                	addi	s0,sp,32
    80001092:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001094:	1552                	slli	a0,a0,0x34
    80001096:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000109a:	4601                	li	a2,0
    8000109c:	00008517          	auipc	a0,0x8
    800010a0:	f7453503          	ld	a0,-140(a0) # 80009010 <kernel_pagetable>
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	f3e080e7          	jalr	-194(ra) # 80000fe2 <walk>
  if(pte == 0)
    800010ac:	cd09                	beqz	a0,800010c6 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010ae:	6108                	ld	a0,0(a0)
    800010b0:	00157793          	andi	a5,a0,1
    800010b4:	c38d                	beqz	a5,800010d6 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010b6:	8129                	srli	a0,a0,0xa
    800010b8:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010ba:	9526                	add	a0,a0,s1
    800010bc:	60e2                	ld	ra,24(sp)
    800010be:	6442                	ld	s0,16(sp)
    800010c0:	64a2                	ld	s1,8(sp)
    800010c2:	6105                	addi	sp,sp,32
    800010c4:	8082                	ret
    panic("kvmpa");
    800010c6:	00007517          	auipc	a0,0x7
    800010ca:	01250513          	addi	a0,a0,18 # 800080d8 <digits+0x98>
    800010ce:	fffff097          	auipc	ra,0xfffff
    800010d2:	474080e7          	jalr	1140(ra) # 80000542 <panic>
    panic("kvmpa");
    800010d6:	00007517          	auipc	a0,0x7
    800010da:	00250513          	addi	a0,a0,2 # 800080d8 <digits+0x98>
    800010de:	fffff097          	auipc	ra,0xfffff
    800010e2:	464080e7          	jalr	1124(ra) # 80000542 <panic>

00000000800010e6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e6:	715d                	addi	sp,sp,-80
    800010e8:	e486                	sd	ra,72(sp)
    800010ea:	e0a2                	sd	s0,64(sp)
    800010ec:	fc26                	sd	s1,56(sp)
    800010ee:	f84a                	sd	s2,48(sp)
    800010f0:	f44e                	sd	s3,40(sp)
    800010f2:	f052                	sd	s4,32(sp)
    800010f4:	ec56                	sd	s5,24(sp)
    800010f6:	e85a                	sd	s6,16(sp)
    800010f8:	e45e                	sd	s7,8(sp)
    800010fa:	0880                	addi	s0,sp,80
    800010fc:	8aaa                	mv	s5,a0
    800010fe:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001100:	777d                	lui	a4,0xfffff
    80001102:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001106:	167d                	addi	a2,a2,-1
    80001108:	00b609b3          	add	s3,a2,a1
    8000110c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001110:	893e                	mv	s2,a5
    80001112:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001116:	6b85                	lui	s7,0x1
    80001118:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000111c:	4605                	li	a2,1
    8000111e:	85ca                	mv	a1,s2
    80001120:	8556                	mv	a0,s5
    80001122:	00000097          	auipc	ra,0x0
    80001126:	ec0080e7          	jalr	-320(ra) # 80000fe2 <walk>
    8000112a:	c51d                	beqz	a0,80001158 <mappages+0x72>
    if(*pte & PTE_V)
    8000112c:	611c                	ld	a5,0(a0)
    8000112e:	8b85                	andi	a5,a5,1
    80001130:	ef81                	bnez	a5,80001148 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001132:	80b1                	srli	s1,s1,0xc
    80001134:	04aa                	slli	s1,s1,0xa
    80001136:	0164e4b3          	or	s1,s1,s6
    8000113a:	0014e493          	ori	s1,s1,1
    8000113e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001140:	03390863          	beq	s2,s3,80001170 <mappages+0x8a>
    a += PGSIZE;
    80001144:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001146:	bfc9                	j	80001118 <mappages+0x32>
      panic("remap");
    80001148:	00007517          	auipc	a0,0x7
    8000114c:	f9850513          	addi	a0,a0,-104 # 800080e0 <digits+0xa0>
    80001150:	fffff097          	auipc	ra,0xfffff
    80001154:	3f2080e7          	jalr	1010(ra) # 80000542 <panic>
      return -1;
    80001158:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000115a:	60a6                	ld	ra,72(sp)
    8000115c:	6406                	ld	s0,64(sp)
    8000115e:	74e2                	ld	s1,56(sp)
    80001160:	7942                	ld	s2,48(sp)
    80001162:	79a2                	ld	s3,40(sp)
    80001164:	7a02                	ld	s4,32(sp)
    80001166:	6ae2                	ld	s5,24(sp)
    80001168:	6b42                	ld	s6,16(sp)
    8000116a:	6ba2                	ld	s7,8(sp)
    8000116c:	6161                	addi	sp,sp,80
    8000116e:	8082                	ret
  return 0;
    80001170:	4501                	li	a0,0
    80001172:	b7e5                	j	8000115a <mappages+0x74>

0000000080001174 <walkaddr>:
{
    80001174:	7179                	addi	sp,sp,-48
    80001176:	f406                	sd	ra,40(sp)
    80001178:	f022                	sd	s0,32(sp)
    8000117a:	ec26                	sd	s1,24(sp)
    8000117c:	e84a                	sd	s2,16(sp)
    8000117e:	e44e                	sd	s3,8(sp)
    80001180:	1800                	addi	s0,sp,48
    80001182:	892a                	mv	s2,a0
    80001184:	84ae                	mv	s1,a1
  struct proc *p=myproc();
    80001186:	00001097          	auipc	ra,0x1
    8000118a:	882080e7          	jalr	-1918(ra) # 80001a08 <myproc>
  if(va >= MAXVA)
    8000118e:	57fd                	li	a5,-1
    80001190:	83e9                	srli	a5,a5,0x1a
    80001192:	0097fa63          	bgeu	a5,s1,800011a6 <walkaddr+0x32>
    return 0;
    80001196:	4501                	li	a0,0
}
    80001198:	70a2                	ld	ra,40(sp)
    8000119a:	7402                	ld	s0,32(sp)
    8000119c:	64e2                	ld	s1,24(sp)
    8000119e:	6942                	ld	s2,16(sp)
    800011a0:	69a2                	ld	s3,8(sp)
    800011a2:	6145                	addi	sp,sp,48
    800011a4:	8082                	ret
    800011a6:	89aa                	mv	s3,a0
  pte = walk(pagetable, va, 0);
    800011a8:	4601                	li	a2,0
    800011aa:	85a6                	mv	a1,s1
    800011ac:	854a                	mv	a0,s2
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	e34080e7          	jalr	-460(ra) # 80000fe2 <walk>
  if(pte==0||((*pte & PTE_V)==0))
    800011b6:	c509                	beqz	a0,800011c0 <walkaddr+0x4c>
    800011b8:	611c                	ld	a5,0(a0)
    800011ba:	0017f713          	andi	a4,a5,1
    800011be:	e32d                	bnez	a4,80001220 <walkaddr+0xac>
    if(va>=p->sz||va<=PGROUNDDOWN(p->trapframe->sp))
    800011c0:	0489b783          	ld	a5,72(s3) # 1048 <_entry-0x7fffefb8>
       return 0;
    800011c4:	4501                	li	a0,0
    if(va>=p->sz||va<=PGROUNDDOWN(p->trapframe->sp))
    800011c6:	fcf4f9e3          	bgeu	s1,a5,80001198 <walkaddr+0x24>
    800011ca:	0589b783          	ld	a5,88(s3)
    800011ce:	7b98                	ld	a4,48(a5)
    800011d0:	77fd                	lui	a5,0xfffff
    800011d2:	8ff9                	and	a5,a5,a4
    800011d4:	fc97f2e3          	bgeu	a5,s1,80001198 <walkaddr+0x24>
      uint64 ka=(uint64)kalloc();
    800011d8:	00000097          	auipc	ra,0x0
    800011dc:	936080e7          	jalr	-1738(ra) # 80000b0e <kalloc>
    800011e0:	892a                	mv	s2,a0
        return 0;
    800011e2:	4501                	li	a0,0
      if(ka==0)
    800011e4:	fa090ae3          	beqz	s2,80001198 <walkaddr+0x24>
        memset((void*)ka,0,PGSIZE);
    800011e8:	6605                	lui	a2,0x1
    800011ea:	4581                	li	a1,0
    800011ec:	854a                	mv	a0,s2
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	b0c080e7          	jalr	-1268(ra) # 80000cfa <memset>
	if(mappages(p->pagetable,va,PGSIZE,ka,PTE_W|PTE_U|PTE_R)!=0)
    800011f6:	4759                	li	a4,22
    800011f8:	86ca                	mv	a3,s2
    800011fa:	6605                	lui	a2,0x1
    800011fc:	75fd                	lui	a1,0xfffff
    800011fe:	8de5                	and	a1,a1,s1
    80001200:	0509b503          	ld	a0,80(s3)
    80001204:	00000097          	auipc	ra,0x0
    80001208:	ee2080e7          	jalr	-286(ra) # 800010e6 <mappages>
    8000120c:	87aa                	mv	a5,a0
	return 0;
    8000120e:	4501                	li	a0,0
	if(mappages(p->pagetable,va,PGSIZE,ka,PTE_W|PTE_U|PTE_R)!=0)
    80001210:	d7c1                	beqz	a5,80001198 <walkaddr+0x24>
	  kfree((void*)ka);
    80001212:	854a                	mv	a0,s2
    80001214:	fffff097          	auipc	ra,0xfffff
    80001218:	7fe080e7          	jalr	2046(ra) # 80000a12 <kfree>
	  return 0;
    8000121c:	4501                	li	a0,0
    8000121e:	bfad                	j	80001198 <walkaddr+0x24>
  if((*pte & PTE_U) == 0)
    80001220:	0107f513          	andi	a0,a5,16
    80001224:	d935                	beqz	a0,80001198 <walkaddr+0x24>
  pa = PTE2PA(*pte);
    80001226:	00a7d513          	srli	a0,a5,0xa
    8000122a:	0532                	slli	a0,a0,0xc
  return pa;
    8000122c:	b7b5                	j	80001198 <walkaddr+0x24>

000000008000122e <kvmmap>:
{
    8000122e:	1141                	addi	sp,sp,-16
    80001230:	e406                	sd	ra,8(sp)
    80001232:	e022                	sd	s0,0(sp)
    80001234:	0800                	addi	s0,sp,16
    80001236:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001238:	86ae                	mv	a3,a1
    8000123a:	85aa                	mv	a1,a0
    8000123c:	00008517          	auipc	a0,0x8
    80001240:	dd453503          	ld	a0,-556(a0) # 80009010 <kernel_pagetable>
    80001244:	00000097          	auipc	ra,0x0
    80001248:	ea2080e7          	jalr	-350(ra) # 800010e6 <mappages>
    8000124c:	e509                	bnez	a0,80001256 <kvmmap+0x28>
}
    8000124e:	60a2                	ld	ra,8(sp)
    80001250:	6402                	ld	s0,0(sp)
    80001252:	0141                	addi	sp,sp,16
    80001254:	8082                	ret
    panic("kvmmap");
    80001256:	00007517          	auipc	a0,0x7
    8000125a:	e9250513          	addi	a0,a0,-366 # 800080e8 <digits+0xa8>
    8000125e:	fffff097          	auipc	ra,0xfffff
    80001262:	2e4080e7          	jalr	740(ra) # 80000542 <panic>

0000000080001266 <kvminit>:
{
    80001266:	1101                	addi	sp,sp,-32
    80001268:	ec06                	sd	ra,24(sp)
    8000126a:	e822                	sd	s0,16(sp)
    8000126c:	e426                	sd	s1,8(sp)
    8000126e:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001270:	00000097          	auipc	ra,0x0
    80001274:	89e080e7          	jalr	-1890(ra) # 80000b0e <kalloc>
    80001278:	00008797          	auipc	a5,0x8
    8000127c:	d8a7bc23          	sd	a0,-616(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001280:	6605                	lui	a2,0x1
    80001282:	4581                	li	a1,0
    80001284:	00000097          	auipc	ra,0x0
    80001288:	a76080e7          	jalr	-1418(ra) # 80000cfa <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000128c:	4699                	li	a3,6
    8000128e:	6605                	lui	a2,0x1
    80001290:	100005b7          	lui	a1,0x10000
    80001294:	10000537          	lui	a0,0x10000
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f96080e7          	jalr	-106(ra) # 8000122e <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012a0:	4699                	li	a3,6
    800012a2:	6605                	lui	a2,0x1
    800012a4:	100015b7          	lui	a1,0x10001
    800012a8:	10001537          	lui	a0,0x10001
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	f82080e7          	jalr	-126(ra) # 8000122e <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012b4:	4699                	li	a3,6
    800012b6:	6641                	lui	a2,0x10
    800012b8:	020005b7          	lui	a1,0x2000
    800012bc:	02000537          	lui	a0,0x2000
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	f6e080e7          	jalr	-146(ra) # 8000122e <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012c8:	4699                	li	a3,6
    800012ca:	00400637          	lui	a2,0x400
    800012ce:	0c0005b7          	lui	a1,0xc000
    800012d2:	0c000537          	lui	a0,0xc000
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	f58080e7          	jalr	-168(ra) # 8000122e <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012de:	00007497          	auipc	s1,0x7
    800012e2:	d2248493          	addi	s1,s1,-734 # 80008000 <etext>
    800012e6:	46a9                	li	a3,10
    800012e8:	80007617          	auipc	a2,0x80007
    800012ec:	d1860613          	addi	a2,a2,-744 # 8000 <_entry-0x7fff8000>
    800012f0:	4585                	li	a1,1
    800012f2:	05fe                	slli	a1,a1,0x1f
    800012f4:	852e                	mv	a0,a1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	f38080e7          	jalr	-200(ra) # 8000122e <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012fe:	4699                	li	a3,6
    80001300:	4645                	li	a2,17
    80001302:	066e                	slli	a2,a2,0x1b
    80001304:	8e05                	sub	a2,a2,s1
    80001306:	85a6                	mv	a1,s1
    80001308:	8526                	mv	a0,s1
    8000130a:	00000097          	auipc	ra,0x0
    8000130e:	f24080e7          	jalr	-220(ra) # 8000122e <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001312:	46a9                	li	a3,10
    80001314:	6605                	lui	a2,0x1
    80001316:	00006597          	auipc	a1,0x6
    8000131a:	cea58593          	addi	a1,a1,-790 # 80007000 <_trampoline>
    8000131e:	04000537          	lui	a0,0x4000
    80001322:	157d                	addi	a0,a0,-1
    80001324:	0532                	slli	a0,a0,0xc
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	f08080e7          	jalr	-248(ra) # 8000122e <kvmmap>
}
    8000132e:	60e2                	ld	ra,24(sp)
    80001330:	6442                	ld	s0,16(sp)
    80001332:	64a2                	ld	s1,8(sp)
    80001334:	6105                	addi	sp,sp,32
    80001336:	8082                	ret

0000000080001338 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001338:	715d                	addi	sp,sp,-80
    8000133a:	e486                	sd	ra,72(sp)
    8000133c:	e0a2                	sd	s0,64(sp)
    8000133e:	fc26                	sd	s1,56(sp)
    80001340:	f84a                	sd	s2,48(sp)
    80001342:	f44e                	sd	s3,40(sp)
    80001344:	f052                	sd	s4,32(sp)
    80001346:	ec56                	sd	s5,24(sp)
    80001348:	e85a                	sd	s6,16(sp)
    8000134a:	e45e                	sd	s7,8(sp)
    8000134c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000134e:	03459793          	slli	a5,a1,0x34
    80001352:	e795                	bnez	a5,8000137e <uvmunmap+0x46>
    80001354:	8a2a                	mv	s4,a0
    80001356:	892e                	mv	s2,a1
    80001358:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135a:	0632                	slli	a2,a2,0xc
    8000135c:	00b609b3          	add	s3,a2,a1
    if((*pte & PTE_V) == 0)
    {
      //panic("uvmunmap: not mapped");
      continue;
    }
    if(PTE_FLAGS(*pte) == PTE_V)
    80001360:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001362:	6a85                	lui	s5,0x1
    80001364:	0535e263          	bltu	a1,s3,800013a8 <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001368:	60a6                	ld	ra,72(sp)
    8000136a:	6406                	ld	s0,64(sp)
    8000136c:	74e2                	ld	s1,56(sp)
    8000136e:	7942                	ld	s2,48(sp)
    80001370:	79a2                	ld	s3,40(sp)
    80001372:	7a02                	ld	s4,32(sp)
    80001374:	6ae2                	ld	s5,24(sp)
    80001376:	6b42                	ld	s6,16(sp)
    80001378:	6ba2                	ld	s7,8(sp)
    8000137a:	6161                	addi	sp,sp,80
    8000137c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000137e:	00007517          	auipc	a0,0x7
    80001382:	d7250513          	addi	a0,a0,-654 # 800080f0 <digits+0xb0>
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	1bc080e7          	jalr	444(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    8000138e:	00007517          	auipc	a0,0x7
    80001392:	d7a50513          	addi	a0,a0,-646 # 80008108 <digits+0xc8>
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	1ac080e7          	jalr	428(ra) # 80000542 <panic>
    *pte = 0;
    8000139e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013a2:	9956                	add	s2,s2,s5
    800013a4:	fd3972e3          	bgeu	s2,s3,80001368 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013a8:	4601                	li	a2,0
    800013aa:	85ca                	mv	a1,s2
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	c34080e7          	jalr	-972(ra) # 80000fe2 <walk>
    800013b6:	84aa                	mv	s1,a0
    800013b8:	d56d                	beqz	a0,800013a2 <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    800013ba:	611c                	ld	a5,0(a0)
    800013bc:	0017f713          	andi	a4,a5,1
    800013c0:	d36d                	beqz	a4,800013a2 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c2:	3ff7f713          	andi	a4,a5,1023
    800013c6:	fd7704e3          	beq	a4,s7,8000138e <uvmunmap+0x56>
    if(do_free){
    800013ca:	fc0b0ae3          	beqz	s6,8000139e <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    800013ce:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800013d0:	00c79513          	slli	a0,a5,0xc
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	63e080e7          	jalr	1598(ra) # 80000a12 <kfree>
    800013dc:	b7c9                	j	8000139e <uvmunmap+0x66>

00000000800013de <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013de:	1101                	addi	sp,sp,-32
    800013e0:	ec06                	sd	ra,24(sp)
    800013e2:	e822                	sd	s0,16(sp)
    800013e4:	e426                	sd	s1,8(sp)
    800013e6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013e8:	fffff097          	auipc	ra,0xfffff
    800013ec:	726080e7          	jalr	1830(ra) # 80000b0e <kalloc>
    800013f0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f2:	c519                	beqz	a0,80001400 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	902080e7          	jalr	-1790(ra) # 80000cfa <memset>
  return pagetable;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret

000000008000140c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000140c:	7179                	addi	sp,sp,-48
    8000140e:	f406                	sd	ra,40(sp)
    80001410:	f022                	sd	s0,32(sp)
    80001412:	ec26                	sd	s1,24(sp)
    80001414:	e84a                	sd	s2,16(sp)
    80001416:	e44e                	sd	s3,8(sp)
    80001418:	e052                	sd	s4,0(sp)
    8000141a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000141c:	6785                	lui	a5,0x1
    8000141e:	04f67863          	bgeu	a2,a5,8000146e <uvminit+0x62>
    80001422:	8a2a                	mv	s4,a0
    80001424:	89ae                	mv	s3,a1
    80001426:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001428:	fffff097          	auipc	ra,0xfffff
    8000142c:	6e6080e7          	jalr	1766(ra) # 80000b0e <kalloc>
    80001430:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001432:	6605                	lui	a2,0x1
    80001434:	4581                	li	a1,0
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	8c4080e7          	jalr	-1852(ra) # 80000cfa <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000143e:	4779                	li	a4,30
    80001440:	86ca                	mv	a3,s2
    80001442:	6605                	lui	a2,0x1
    80001444:	4581                	li	a1,0
    80001446:	8552                	mv	a0,s4
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	c9e080e7          	jalr	-866(ra) # 800010e6 <mappages>
  memmove(mem, src, sz);
    80001450:	8626                	mv	a2,s1
    80001452:	85ce                	mv	a1,s3
    80001454:	854a                	mv	a0,s2
    80001456:	00000097          	auipc	ra,0x0
    8000145a:	900080e7          	jalr	-1792(ra) # 80000d56 <memmove>
}
    8000145e:	70a2                	ld	ra,40(sp)
    80001460:	7402                	ld	s0,32(sp)
    80001462:	64e2                	ld	s1,24(sp)
    80001464:	6942                	ld	s2,16(sp)
    80001466:	69a2                	ld	s3,8(sp)
    80001468:	6a02                	ld	s4,0(sp)
    8000146a:	6145                	addi	sp,sp,48
    8000146c:	8082                	ret
    panic("inituvm: more than a page");
    8000146e:	00007517          	auipc	a0,0x7
    80001472:	cb250513          	addi	a0,a0,-846 # 80008120 <digits+0xe0>
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	0cc080e7          	jalr	204(ra) # 80000542 <panic>

000000008000147e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000147e:	1101                	addi	sp,sp,-32
    80001480:	ec06                	sd	ra,24(sp)
    80001482:	e822                	sd	s0,16(sp)
    80001484:	e426                	sd	s1,8(sp)
    80001486:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001488:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000148a:	00b67d63          	bgeu	a2,a1,800014a4 <uvmdealloc+0x26>
    8000148e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001490:	6785                	lui	a5,0x1
    80001492:	17fd                	addi	a5,a5,-1
    80001494:	00f60733          	add	a4,a2,a5
    80001498:	767d                	lui	a2,0xfffff
    8000149a:	8f71                	and	a4,a4,a2
    8000149c:	97ae                	add	a5,a5,a1
    8000149e:	8ff1                	and	a5,a5,a2
    800014a0:	00f76863          	bltu	a4,a5,800014b0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014a4:	8526                	mv	a0,s1
    800014a6:	60e2                	ld	ra,24(sp)
    800014a8:	6442                	ld	s0,16(sp)
    800014aa:	64a2                	ld	s1,8(sp)
    800014ac:	6105                	addi	sp,sp,32
    800014ae:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b0:	8f99                	sub	a5,a5,a4
    800014b2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014b4:	4685                	li	a3,1
    800014b6:	0007861b          	sext.w	a2,a5
    800014ba:	85ba                	mv	a1,a4
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	e7c080e7          	jalr	-388(ra) # 80001338 <uvmunmap>
    800014c4:	b7c5                	j	800014a4 <uvmdealloc+0x26>

00000000800014c6 <uvmalloc>:
  if(newsz < oldsz)
    800014c6:	0ab66163          	bltu	a2,a1,80001568 <uvmalloc+0xa2>
{
    800014ca:	7139                	addi	sp,sp,-64
    800014cc:	fc06                	sd	ra,56(sp)
    800014ce:	f822                	sd	s0,48(sp)
    800014d0:	f426                	sd	s1,40(sp)
    800014d2:	f04a                	sd	s2,32(sp)
    800014d4:	ec4e                	sd	s3,24(sp)
    800014d6:	e852                	sd	s4,16(sp)
    800014d8:	e456                	sd	s5,8(sp)
    800014da:	0080                	addi	s0,sp,64
    800014dc:	8aaa                	mv	s5,a0
    800014de:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e0:	6985                	lui	s3,0x1
    800014e2:	19fd                	addi	s3,s3,-1
    800014e4:	95ce                	add	a1,a1,s3
    800014e6:	79fd                	lui	s3,0xfffff
    800014e8:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ec:	08c9f063          	bgeu	s3,a2,8000156c <uvmalloc+0xa6>
    800014f0:	894e                	mv	s2,s3
    mem = kalloc();
    800014f2:	fffff097          	auipc	ra,0xfffff
    800014f6:	61c080e7          	jalr	1564(ra) # 80000b0e <kalloc>
    800014fa:	84aa                	mv	s1,a0
    if(mem == 0){
    800014fc:	c51d                	beqz	a0,8000152a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014fe:	6605                	lui	a2,0x1
    80001500:	4581                	li	a1,0
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	7f8080e7          	jalr	2040(ra) # 80000cfa <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000150a:	4779                	li	a4,30
    8000150c:	86a6                	mv	a3,s1
    8000150e:	6605                	lui	a2,0x1
    80001510:	85ca                	mv	a1,s2
    80001512:	8556                	mv	a0,s5
    80001514:	00000097          	auipc	ra,0x0
    80001518:	bd2080e7          	jalr	-1070(ra) # 800010e6 <mappages>
    8000151c:	e905                	bnez	a0,8000154c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000151e:	6785                	lui	a5,0x1
    80001520:	993e                	add	s2,s2,a5
    80001522:	fd4968e3          	bltu	s2,s4,800014f2 <uvmalloc+0x2c>
  return newsz;
    80001526:	8552                	mv	a0,s4
    80001528:	a809                	j	8000153a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000152a:	864e                	mv	a2,s3
    8000152c:	85ca                	mv	a1,s2
    8000152e:	8556                	mv	a0,s5
    80001530:	00000097          	auipc	ra,0x0
    80001534:	f4e080e7          	jalr	-178(ra) # 8000147e <uvmdealloc>
      return 0;
    80001538:	4501                	li	a0,0
}
    8000153a:	70e2                	ld	ra,56(sp)
    8000153c:	7442                	ld	s0,48(sp)
    8000153e:	74a2                	ld	s1,40(sp)
    80001540:	7902                	ld	s2,32(sp)
    80001542:	69e2                	ld	s3,24(sp)
    80001544:	6a42                	ld	s4,16(sp)
    80001546:	6aa2                	ld	s5,8(sp)
    80001548:	6121                	addi	sp,sp,64
    8000154a:	8082                	ret
      kfree(mem);
    8000154c:	8526                	mv	a0,s1
    8000154e:	fffff097          	auipc	ra,0xfffff
    80001552:	4c4080e7          	jalr	1220(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001556:	864e                	mv	a2,s3
    80001558:	85ca                	mv	a1,s2
    8000155a:	8556                	mv	a0,s5
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	f22080e7          	jalr	-222(ra) # 8000147e <uvmdealloc>
      return 0;
    80001564:	4501                	li	a0,0
    80001566:	bfd1                	j	8000153a <uvmalloc+0x74>
    return oldsz;
    80001568:	852e                	mv	a0,a1
}
    8000156a:	8082                	ret
  return newsz;
    8000156c:	8532                	mv	a0,a2
    8000156e:	b7f1                	j	8000153a <uvmalloc+0x74>

0000000080001570 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001570:	7179                	addi	sp,sp,-48
    80001572:	f406                	sd	ra,40(sp)
    80001574:	f022                	sd	s0,32(sp)
    80001576:	ec26                	sd	s1,24(sp)
    80001578:	e84a                	sd	s2,16(sp)
    8000157a:	e44e                	sd	s3,8(sp)
    8000157c:	e052                	sd	s4,0(sp)
    8000157e:	1800                	addi	s0,sp,48
    80001580:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001582:	84aa                	mv	s1,a0
    80001584:	6905                	lui	s2,0x1
    80001586:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001588:	4985                	li	s3,1
    8000158a:	a821                	j	800015a2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000158c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000158e:	0532                	slli	a0,a0,0xc
    80001590:	00000097          	auipc	ra,0x0
    80001594:	fe0080e7          	jalr	-32(ra) # 80001570 <freewalk>
      pagetable[i] = 0;
    80001598:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000159c:	04a1                	addi	s1,s1,8
    8000159e:	03248163          	beq	s1,s2,800015c0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a4:	00f57793          	andi	a5,a0,15
    800015a8:	ff3782e3          	beq	a5,s3,8000158c <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015ac:	8905                	andi	a0,a0,1
    800015ae:	d57d                	beqz	a0,8000159c <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b0:	00007517          	auipc	a0,0x7
    800015b4:	b9050513          	addi	a0,a0,-1136 # 80008140 <digits+0x100>
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	f8a080e7          	jalr	-118(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c0:	8552                	mv	a0,s4
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	450080e7          	jalr	1104(ra) # 80000a12 <kfree>
}
    800015ca:	70a2                	ld	ra,40(sp)
    800015cc:	7402                	ld	s0,32(sp)
    800015ce:	64e2                	ld	s1,24(sp)
    800015d0:	6942                	ld	s2,16(sp)
    800015d2:	69a2                	ld	s3,8(sp)
    800015d4:	6a02                	ld	s4,0(sp)
    800015d6:	6145                	addi	sp,sp,48
    800015d8:	8082                	ret

00000000800015da <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015da:	1101                	addi	sp,sp,-32
    800015dc:	ec06                	sd	ra,24(sp)
    800015de:	e822                	sd	s0,16(sp)
    800015e0:	e426                	sd	s1,8(sp)
    800015e2:	1000                	addi	s0,sp,32
    800015e4:	84aa                	mv	s1,a0
  if(sz > 0)
    800015e6:	e999                	bnez	a1,800015fc <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015e8:	8526                	mv	a0,s1
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	f86080e7          	jalr	-122(ra) # 80001570 <freewalk>
}
    800015f2:	60e2                	ld	ra,24(sp)
    800015f4:	6442                	ld	s0,16(sp)
    800015f6:	64a2                	ld	s1,8(sp)
    800015f8:	6105                	addi	sp,sp,32
    800015fa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015fc:	6605                	lui	a2,0x1
    800015fe:	167d                	addi	a2,a2,-1
    80001600:	962e                	add	a2,a2,a1
    80001602:	4685                	li	a3,1
    80001604:	8231                	srli	a2,a2,0xc
    80001606:	4581                	li	a1,0
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	d30080e7          	jalr	-720(ra) # 80001338 <uvmunmap>
    80001610:	bfe1                	j	800015e8 <uvmfree+0xe>

0000000080001612 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001612:	ca4d                	beqz	a2,800016c4 <uvmcopy+0xb2>
{
    80001614:	715d                	addi	sp,sp,-80
    80001616:	e486                	sd	ra,72(sp)
    80001618:	e0a2                	sd	s0,64(sp)
    8000161a:	fc26                	sd	s1,56(sp)
    8000161c:	f84a                	sd	s2,48(sp)
    8000161e:	f44e                	sd	s3,40(sp)
    80001620:	f052                	sd	s4,32(sp)
    80001622:	ec56                	sd	s5,24(sp)
    80001624:	e85a                	sd	s6,16(sp)
    80001626:	e45e                	sd	s7,8(sp)
    80001628:	0880                	addi	s0,sp,80
    8000162a:	8aaa                	mv	s5,a0
    8000162c:	8b2e                	mv	s6,a1
    8000162e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001630:	4481                	li	s1,0
    80001632:	a029                	j	8000163c <uvmcopy+0x2a>
    80001634:	6785                	lui	a5,0x1
    80001636:	94be                	add	s1,s1,a5
    80001638:	0744fa63          	bgeu	s1,s4,800016ac <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    8000163c:	4601                	li	a2,0
    8000163e:	85a6                	mv	a1,s1
    80001640:	8556                	mv	a0,s5
    80001642:	00000097          	auipc	ra,0x0
    80001646:	9a0080e7          	jalr	-1632(ra) # 80000fe2 <walk>
    8000164a:	d56d                	beqz	a0,80001634 <uvmcopy+0x22>
    {
       //panic("uvmcopy: pte should exist");
       continue;
    }
    if((*pte & PTE_V) == 0)
    8000164c:	6118                	ld	a4,0(a0)
    8000164e:	00177793          	andi	a5,a4,1
    80001652:	d3ed                	beqz	a5,80001634 <uvmcopy+0x22>
    {
       //panic("uvmcopy: page not present");
       continue;
    }
    pa = PTE2PA(*pte);
    80001654:	00a75593          	srli	a1,a4,0xa
    80001658:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000165c:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	4ae080e7          	jalr	1198(ra) # 80000b0e <kalloc>
    80001668:	89aa                	mv	s3,a0
    8000166a:	c515                	beqz	a0,80001696 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000166c:	6605                	lui	a2,0x1
    8000166e:	85de                	mv	a1,s7
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	6e6080e7          	jalr	1766(ra) # 80000d56 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001678:	874a                	mv	a4,s2
    8000167a:	86ce                	mv	a3,s3
    8000167c:	6605                	lui	a2,0x1
    8000167e:	85a6                	mv	a1,s1
    80001680:	855a                	mv	a0,s6
    80001682:	00000097          	auipc	ra,0x0
    80001686:	a64080e7          	jalr	-1436(ra) # 800010e6 <mappages>
    8000168a:	d54d                	beqz	a0,80001634 <uvmcopy+0x22>
      kfree(mem);
    8000168c:	854e                	mv	a0,s3
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	384080e7          	jalr	900(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001696:	4685                	li	a3,1
    80001698:	00c4d613          	srli	a2,s1,0xc
    8000169c:	4581                	li	a1,0
    8000169e:	855a                	mv	a0,s6
    800016a0:	00000097          	auipc	ra,0x0
    800016a4:	c98080e7          	jalr	-872(ra) # 80001338 <uvmunmap>
  return -1;
    800016a8:	557d                	li	a0,-1
    800016aa:	a011                	j	800016ae <uvmcopy+0x9c>
  return 0;
    800016ac:	4501                	li	a0,0
}
    800016ae:	60a6                	ld	ra,72(sp)
    800016b0:	6406                	ld	s0,64(sp)
    800016b2:	74e2                	ld	s1,56(sp)
    800016b4:	7942                	ld	s2,48(sp)
    800016b6:	79a2                	ld	s3,40(sp)
    800016b8:	7a02                	ld	s4,32(sp)
    800016ba:	6ae2                	ld	s5,24(sp)
    800016bc:	6b42                	ld	s6,16(sp)
    800016be:	6ba2                	ld	s7,8(sp)
    800016c0:	6161                	addi	sp,sp,80
    800016c2:	8082                	ret
  return 0;
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret

00000000800016c8 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016c8:	1141                	addi	sp,sp,-16
    800016ca:	e406                	sd	ra,8(sp)
    800016cc:	e022                	sd	s0,0(sp)
    800016ce:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016d0:	4601                	li	a2,0
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	910080e7          	jalr	-1776(ra) # 80000fe2 <walk>
  if(pte == 0)
    800016da:	c901                	beqz	a0,800016ea <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016dc:	611c                	ld	a5,0(a0)
    800016de:	9bbd                	andi	a5,a5,-17
    800016e0:	e11c                	sd	a5,0(a0)
}
    800016e2:	60a2                	ld	ra,8(sp)
    800016e4:	6402                	ld	s0,0(sp)
    800016e6:	0141                	addi	sp,sp,16
    800016e8:	8082                	ret
    panic("uvmclear");
    800016ea:	00007517          	auipc	a0,0x7
    800016ee:	a6650513          	addi	a0,a0,-1434 # 80008150 <digits+0x110>
    800016f2:	fffff097          	auipc	ra,0xfffff
    800016f6:	e50080e7          	jalr	-432(ra) # 80000542 <panic>

00000000800016fa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fa:	c6bd                	beqz	a3,80001768 <copyout+0x6e>
{
    800016fc:	715d                	addi	sp,sp,-80
    800016fe:	e486                	sd	ra,72(sp)
    80001700:	e0a2                	sd	s0,64(sp)
    80001702:	fc26                	sd	s1,56(sp)
    80001704:	f84a                	sd	s2,48(sp)
    80001706:	f44e                	sd	s3,40(sp)
    80001708:	f052                	sd	s4,32(sp)
    8000170a:	ec56                	sd	s5,24(sp)
    8000170c:	e85a                	sd	s6,16(sp)
    8000170e:	e45e                	sd	s7,8(sp)
    80001710:	e062                	sd	s8,0(sp)
    80001712:	0880                	addi	s0,sp,80
    80001714:	8b2a                	mv	s6,a0
    80001716:	8c2e                	mv	s8,a1
    80001718:	8a32                	mv	s4,a2
    8000171a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000171c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000171e:	6a85                	lui	s5,0x1
    80001720:	a015                	j	80001744 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001722:	9562                	add	a0,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	85d2                	mv	a1,s4
    8000172a:	41250533          	sub	a0,a0,s2
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	628080e7          	jalr	1576(ra) # 80000d56 <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    src += n;
    8000173a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	a28080e7          	jalr	-1496(ra) # 80001174 <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000175c:	fc99f3e3          	bgeu	s3,s1,80001722 <copyout+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	b7c1                	j	80001722 <copyout+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyout+0x74>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyin>:
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;
  while(len > 0){
    80001786:	caa5                	beqz	a3,800017f6 <copyin+0x70>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	e062                	sd	s8,0(sp)
    8000179e:	0880                	addi	s0,sp,80
    800017a0:	8b2a                	mv	s6,a0
    800017a2:	8a2e                	mv	s4,a1
    800017a4:	8c32                	mv	s8,a2
    800017a6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017a8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
    {
       return -1;
    }
    n = PGSIZE - (srcva - va0);
    800017aa:	6a85                	lui	s5,0x1
    800017ac:	a01d                	j	800017d2 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017ae:	018505b3          	add	a1,a0,s8
    800017b2:	0004861b          	sext.w	a2,s1
    800017b6:	412585b3          	sub	a1,a1,s2
    800017ba:	8552                	mv	a0,s4
    800017bc:	fffff097          	auipc	ra,0xfffff
    800017c0:	59a080e7          	jalr	1434(ra) # 80000d56 <memmove>

    len -= n;
    800017c4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017c8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017ca:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ce:	02098263          	beqz	s3,800017f2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	855a                	mv	a0,s6
    800017da:	00000097          	auipc	ra,0x0
    800017de:	99a080e7          	jalr	-1638(ra) # 80001174 <walkaddr>
    if(pa0 == 0)
    800017e2:	cd01                	beqz	a0,800017fa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017e4:	418904b3          	sub	s1,s2,s8
    800017e8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ea:	fc99f2e3          	bgeu	s3,s1,800017ae <copyin+0x28>
    800017ee:	84ce                	mv	s1,s3
    800017f0:	bf7d                	j	800017ae <copyin+0x28>
  }
  return 0;
    800017f2:	4501                	li	a0,0
    800017f4:	a021                	j	800017fc <copyin+0x76>
    800017f6:	4501                	li	a0,0
}
    800017f8:	8082                	ret
       return -1;
    800017fa:	557d                	li	a0,-1
}
    800017fc:	60a6                	ld	ra,72(sp)
    800017fe:	6406                	ld	s0,64(sp)
    80001800:	74e2                	ld	s1,56(sp)
    80001802:	7942                	ld	s2,48(sp)
    80001804:	79a2                	ld	s3,40(sp)
    80001806:	7a02                	ld	s4,32(sp)
    80001808:	6ae2                	ld	s5,24(sp)
    8000180a:	6b42                	ld	s6,16(sp)
    8000180c:	6ba2                	ld	s7,8(sp)
    8000180e:	6c02                	ld	s8,0(sp)
    80001810:	6161                	addi	sp,sp,80
    80001812:	8082                	ret

0000000080001814 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001814:	c6c5                	beqz	a3,800018bc <copyinstr+0xa8>
{
    80001816:	715d                	addi	sp,sp,-80
    80001818:	e486                	sd	ra,72(sp)
    8000181a:	e0a2                	sd	s0,64(sp)
    8000181c:	fc26                	sd	s1,56(sp)
    8000181e:	f84a                	sd	s2,48(sp)
    80001820:	f44e                	sd	s3,40(sp)
    80001822:	f052                	sd	s4,32(sp)
    80001824:	ec56                	sd	s5,24(sp)
    80001826:	e85a                	sd	s6,16(sp)
    80001828:	e45e                	sd	s7,8(sp)
    8000182a:	0880                	addi	s0,sp,80
    8000182c:	8a2a                	mv	s4,a0
    8000182e:	8b2e                	mv	s6,a1
    80001830:	8bb2                	mv	s7,a2
    80001832:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001834:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001836:	6985                	lui	s3,0x1
    80001838:	a035                	j	80001864 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000183a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000183e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001840:	0017b793          	seqz	a5,a5
    80001844:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001848:	60a6                	ld	ra,72(sp)
    8000184a:	6406                	ld	s0,64(sp)
    8000184c:	74e2                	ld	s1,56(sp)
    8000184e:	7942                	ld	s2,48(sp)
    80001850:	79a2                	ld	s3,40(sp)
    80001852:	7a02                	ld	s4,32(sp)
    80001854:	6ae2                	ld	s5,24(sp)
    80001856:	6b42                	ld	s6,16(sp)
    80001858:	6ba2                	ld	s7,8(sp)
    8000185a:	6161                	addi	sp,sp,80
    8000185c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000185e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001862:	c8a9                	beqz	s1,800018b4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001864:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001868:	85ca                	mv	a1,s2
    8000186a:	8552                	mv	a0,s4
    8000186c:	00000097          	auipc	ra,0x0
    80001870:	908080e7          	jalr	-1784(ra) # 80001174 <walkaddr>
    if(pa0 == 0)
    80001874:	c131                	beqz	a0,800018b8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001876:	41790833          	sub	a6,s2,s7
    8000187a:	984e                	add	a6,a6,s3
    if(n > max)
    8000187c:	0104f363          	bgeu	s1,a6,80001882 <copyinstr+0x6e>
    80001880:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001882:	955e                	add	a0,a0,s7
    80001884:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001888:	fc080be3          	beqz	a6,8000185e <copyinstr+0x4a>
    8000188c:	985a                	add	a6,a6,s6
    8000188e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001890:	41650633          	sub	a2,a0,s6
    80001894:	14fd                	addi	s1,s1,-1
    80001896:	9b26                	add	s6,s6,s1
    80001898:	00f60733          	add	a4,a2,a5
    8000189c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018a0:	df49                	beqz	a4,8000183a <copyinstr+0x26>
        *dst = *p;
    800018a2:	00e78023          	sb	a4,0(a5)
      --max;
    800018a6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018aa:	0785                	addi	a5,a5,1
    while(n > 0){
    800018ac:	ff0796e3          	bne	a5,a6,80001898 <copyinstr+0x84>
      dst++;
    800018b0:	8b42                	mv	s6,a6
    800018b2:	b775                	j	8000185e <copyinstr+0x4a>
    800018b4:	4781                	li	a5,0
    800018b6:	b769                	j	80001840 <copyinstr+0x2c>
      return -1;
    800018b8:	557d                	li	a0,-1
    800018ba:	b779                	j	80001848 <copyinstr+0x34>
  int got_null = 0;
    800018bc:	4781                	li	a5,0
  if(got_null){
    800018be:	0017b793          	seqz	a5,a5
    800018c2:	40f00533          	neg	a0,a5
}
    800018c6:	8082                	ret

00000000800018c8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018c8:	1101                	addi	sp,sp,-32
    800018ca:	ec06                	sd	ra,24(sp)
    800018cc:	e822                	sd	s0,16(sp)
    800018ce:	e426                	sd	s1,8(sp)
    800018d0:	1000                	addi	s0,sp,32
    800018d2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	2b0080e7          	jalr	688(ra) # 80000b84 <holding>
    800018dc:	c909                	beqz	a0,800018ee <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018de:	749c                	ld	a5,40(s1)
    800018e0:	00978f63          	beq	a5,s1,800018fe <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018e4:	60e2                	ld	ra,24(sp)
    800018e6:	6442                	ld	s0,16(sp)
    800018e8:	64a2                	ld	s1,8(sp)
    800018ea:	6105                	addi	sp,sp,32
    800018ec:	8082                	ret
    panic("wakeup1");
    800018ee:	00007517          	auipc	a0,0x7
    800018f2:	87250513          	addi	a0,a0,-1934 # 80008160 <digits+0x120>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	c4c080e7          	jalr	-948(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018fe:	4c98                	lw	a4,24(s1)
    80001900:	4785                	li	a5,1
    80001902:	fef711e3          	bne	a4,a5,800018e4 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001906:	4789                	li	a5,2
    80001908:	cc9c                	sw	a5,24(s1)
}
    8000190a:	bfe9                	j	800018e4 <wakeup1+0x1c>

000000008000190c <procinit>:
{
    8000190c:	715d                	addi	sp,sp,-80
    8000190e:	e486                	sd	ra,72(sp)
    80001910:	e0a2                	sd	s0,64(sp)
    80001912:	fc26                	sd	s1,56(sp)
    80001914:	f84a                	sd	s2,48(sp)
    80001916:	f44e                	sd	s3,40(sp)
    80001918:	f052                	sd	s4,32(sp)
    8000191a:	ec56                	sd	s5,24(sp)
    8000191c:	e85a                	sd	s6,16(sp)
    8000191e:	e45e                	sd	s7,8(sp)
    80001920:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001922:	00007597          	auipc	a1,0x7
    80001926:	84658593          	addi	a1,a1,-1978 # 80008168 <digits+0x128>
    8000192a:	00010517          	auipc	a0,0x10
    8000192e:	02650513          	addi	a0,a0,38 # 80011950 <pid_lock>
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	23c080e7          	jalr	572(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00010917          	auipc	s2,0x10
    8000193e:	42e90913          	addi	s2,s2,1070 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001942:	00007b97          	auipc	s7,0x7
    80001946:	82eb8b93          	addi	s7,s7,-2002 # 80008170 <digits+0x130>
      uint64 va = KSTACK((int) (p - proc));
    8000194a:	8b4a                	mv	s6,s2
    8000194c:	00006a97          	auipc	s5,0x6
    80001950:	6b4a8a93          	addi	s5,s5,1716 # 80008000 <etext>
    80001954:	040009b7          	lui	s3,0x4000
    80001958:	19fd                	addi	s3,s3,-1
    8000195a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	00016a17          	auipc	s4,0x16
    80001960:	e0ca0a13          	addi	s4,s4,-500 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001964:	85de                	mv	a1,s7
    80001966:	854a                	mv	a0,s2
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	206080e7          	jalr	518(ra) # 80000b6e <initlock>
      char *pa = kalloc();
    80001970:	fffff097          	auipc	ra,0xfffff
    80001974:	19e080e7          	jalr	414(ra) # 80000b0e <kalloc>
    80001978:	85aa                	mv	a1,a0
      if(pa == 0)
    8000197a:	c929                	beqz	a0,800019cc <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000197c:	416904b3          	sub	s1,s2,s6
    80001980:	848d                	srai	s1,s1,0x3
    80001982:	000ab783          	ld	a5,0(s5)
    80001986:	02f484b3          	mul	s1,s1,a5
    8000198a:	2485                	addiw	s1,s1,1
    8000198c:	00d4949b          	slliw	s1,s1,0xd
    80001990:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001994:	4699                	li	a3,6
    80001996:	6605                	lui	a2,0x1
    80001998:	8526                	mv	a0,s1
    8000199a:	00000097          	auipc	ra,0x0
    8000199e:	894080e7          	jalr	-1900(ra) # 8000122e <kvmmap>
      p->kstack = va;
    800019a2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a6:	16890913          	addi	s2,s2,360
    800019aa:	fb491de3          	bne	s2,s4,80001964 <procinit+0x58>
  kvminithart();
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	610080e7          	jalr	1552(ra) # 80000fbe <kvminithart>
}
    800019b6:	60a6                	ld	ra,72(sp)
    800019b8:	6406                	ld	s0,64(sp)
    800019ba:	74e2                	ld	s1,56(sp)
    800019bc:	7942                	ld	s2,48(sp)
    800019be:	79a2                	ld	s3,40(sp)
    800019c0:	7a02                	ld	s4,32(sp)
    800019c2:	6ae2                	ld	s5,24(sp)
    800019c4:	6b42                	ld	s6,16(sp)
    800019c6:	6ba2                	ld	s7,8(sp)
    800019c8:	6161                	addi	sp,sp,80
    800019ca:	8082                	ret
        panic("kalloc");
    800019cc:	00006517          	auipc	a0,0x6
    800019d0:	7ac50513          	addi	a0,a0,1964 # 80008178 <digits+0x138>
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	b6e080e7          	jalr	-1170(ra) # 80000542 <panic>

00000000800019dc <cpuid>:
{
    800019dc:	1141                	addi	sp,sp,-16
    800019de:	e422                	sd	s0,8(sp)
    800019e0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019e2:	8512                	mv	a0,tp
}
    800019e4:	2501                	sext.w	a0,a0
    800019e6:	6422                	ld	s0,8(sp)
    800019e8:	0141                	addi	sp,sp,16
    800019ea:	8082                	ret

00000000800019ec <mycpu>:
mycpu(void) {
    800019ec:	1141                	addi	sp,sp,-16
    800019ee:	e422                	sd	s0,8(sp)
    800019f0:	0800                	addi	s0,sp,16
    800019f2:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019f4:	2781                	sext.w	a5,a5
    800019f6:	079e                	slli	a5,a5,0x7
}
    800019f8:	00010517          	auipc	a0,0x10
    800019fc:	f7050513          	addi	a0,a0,-144 # 80011968 <cpus>
    80001a00:	953e                	add	a0,a0,a5
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <myproc>:
myproc(void) {
    80001a08:	1101                	addi	sp,sp,-32
    80001a0a:	ec06                	sd	ra,24(sp)
    80001a0c:	e822                	sd	s0,16(sp)
    80001a0e:	e426                	sd	s1,8(sp)
    80001a10:	1000                	addi	s0,sp,32
  push_off();
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	1a0080e7          	jalr	416(ra) # 80000bb2 <push_off>
    80001a1a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a1c:	2781                	sext.w	a5,a5
    80001a1e:	079e                	slli	a5,a5,0x7
    80001a20:	00010717          	auipc	a4,0x10
    80001a24:	f3070713          	addi	a4,a4,-208 # 80011950 <pid_lock>
    80001a28:	97ba                	add	a5,a5,a4
    80001a2a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	226080e7          	jalr	550(ra) # 80000c52 <pop_off>
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6105                	addi	sp,sp,32
    80001a3e:	8082                	ret

0000000080001a40 <forkret>:
{
    80001a40:	1141                	addi	sp,sp,-16
    80001a42:	e406                	sd	ra,8(sp)
    80001a44:	e022                	sd	s0,0(sp)
    80001a46:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a48:	00000097          	auipc	ra,0x0
    80001a4c:	fc0080e7          	jalr	-64(ra) # 80001a08 <myproc>
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	262080e7          	jalr	610(ra) # 80000cb2 <release>
  if (first) {
    80001a58:	00007797          	auipc	a5,0x7
    80001a5c:	d787a783          	lw	a5,-648(a5) # 800087d0 <first.1>
    80001a60:	eb89                	bnez	a5,80001a72 <forkret+0x32>
  usertrapret();
    80001a62:	00001097          	auipc	ra,0x1
    80001a66:	c18080e7          	jalr	-1000(ra) # 8000267a <usertrapret>
}
    80001a6a:	60a2                	ld	ra,8(sp)
    80001a6c:	6402                	ld	s0,0(sp)
    80001a6e:	0141                	addi	sp,sp,16
    80001a70:	8082                	ret
    first = 0;
    80001a72:	00007797          	auipc	a5,0x7
    80001a76:	d407af23          	sw	zero,-674(a5) # 800087d0 <first.1>
    fsinit(ROOTDEV);
    80001a7a:	4505                	li	a0,1
    80001a7c:	00002097          	auipc	ra,0x2
    80001a80:	a30080e7          	jalr	-1488(ra) # 800034ac <fsinit>
    80001a84:	bff9                	j	80001a62 <forkret+0x22>

0000000080001a86 <allocpid>:
allocpid() {
    80001a86:	1101                	addi	sp,sp,-32
    80001a88:	ec06                	sd	ra,24(sp)
    80001a8a:	e822                	sd	s0,16(sp)
    80001a8c:	e426                	sd	s1,8(sp)
    80001a8e:	e04a                	sd	s2,0(sp)
    80001a90:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a92:	00010917          	auipc	s2,0x10
    80001a96:	ebe90913          	addi	s2,s2,-322 # 80011950 <pid_lock>
    80001a9a:	854a                	mv	a0,s2
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	162080e7          	jalr	354(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001aa4:	00007797          	auipc	a5,0x7
    80001aa8:	d3078793          	addi	a5,a5,-720 # 800087d4 <nextpid>
    80001aac:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aae:	0014871b          	addiw	a4,s1,1
    80001ab2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ab4:	854a                	mv	a0,s2
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	1fc080e7          	jalr	508(ra) # 80000cb2 <release>
}
    80001abe:	8526                	mv	a0,s1
    80001ac0:	60e2                	ld	ra,24(sp)
    80001ac2:	6442                	ld	s0,16(sp)
    80001ac4:	64a2                	ld	s1,8(sp)
    80001ac6:	6902                	ld	s2,0(sp)
    80001ac8:	6105                	addi	sp,sp,32
    80001aca:	8082                	ret

0000000080001acc <proc_pagetable>:
{
    80001acc:	1101                	addi	sp,sp,-32
    80001ace:	ec06                	sd	ra,24(sp)
    80001ad0:	e822                	sd	s0,16(sp)
    80001ad2:	e426                	sd	s1,8(sp)
    80001ad4:	e04a                	sd	s2,0(sp)
    80001ad6:	1000                	addi	s0,sp,32
    80001ad8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	904080e7          	jalr	-1788(ra) # 800013de <uvmcreate>
    80001ae2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ae4:	c121                	beqz	a0,80001b24 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ae6:	4729                	li	a4,10
    80001ae8:	00005697          	auipc	a3,0x5
    80001aec:	51868693          	addi	a3,a3,1304 # 80007000 <_trampoline>
    80001af0:	6605                	lui	a2,0x1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	5ec080e7          	jalr	1516(ra) # 800010e6 <mappages>
    80001b02:	02054863          	bltz	a0,80001b32 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b06:	4719                	li	a4,6
    80001b08:	05893683          	ld	a3,88(s2)
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	020005b7          	lui	a1,0x2000
    80001b12:	15fd                	addi	a1,a1,-1
    80001b14:	05b6                	slli	a1,a1,0xd
    80001b16:	8526                	mv	a0,s1
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	5ce080e7          	jalr	1486(ra) # 800010e6 <mappages>
    80001b20:	02054163          	bltz	a0,80001b42 <proc_pagetable+0x76>
}
    80001b24:	8526                	mv	a0,s1
    80001b26:	60e2                	ld	ra,24(sp)
    80001b28:	6442                	ld	s0,16(sp)
    80001b2a:	64a2                	ld	s1,8(sp)
    80001b2c:	6902                	ld	s2,0(sp)
    80001b2e:	6105                	addi	sp,sp,32
    80001b30:	8082                	ret
    uvmfree(pagetable, 0);
    80001b32:	4581                	li	a1,0
    80001b34:	8526                	mv	a0,s1
    80001b36:	00000097          	auipc	ra,0x0
    80001b3a:	aa4080e7          	jalr	-1372(ra) # 800015da <uvmfree>
    return 0;
    80001b3e:	4481                	li	s1,0
    80001b40:	b7d5                	j	80001b24 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b42:	4681                	li	a3,0
    80001b44:	4605                	li	a2,1
    80001b46:	040005b7          	lui	a1,0x4000
    80001b4a:	15fd                	addi	a1,a1,-1
    80001b4c:	05b2                	slli	a1,a1,0xc
    80001b4e:	8526                	mv	a0,s1
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	7e8080e7          	jalr	2024(ra) # 80001338 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b58:	4581                	li	a1,0
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	00000097          	auipc	ra,0x0
    80001b60:	a7e080e7          	jalr	-1410(ra) # 800015da <uvmfree>
    return 0;
    80001b64:	4481                	li	s1,0
    80001b66:	bf7d                	j	80001b24 <proc_pagetable+0x58>

0000000080001b68 <proc_freepagetable>:
{
    80001b68:	1101                	addi	sp,sp,-32
    80001b6a:	ec06                	sd	ra,24(sp)
    80001b6c:	e822                	sd	s0,16(sp)
    80001b6e:	e426                	sd	s1,8(sp)
    80001b70:	e04a                	sd	s2,0(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	84aa                	mv	s1,a0
    80001b76:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b78:	4681                	li	a3,0
    80001b7a:	4605                	li	a2,1
    80001b7c:	040005b7          	lui	a1,0x4000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b2                	slli	a1,a1,0xc
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	7b4080e7          	jalr	1972(ra) # 80001338 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b8c:	4681                	li	a3,0
    80001b8e:	4605                	li	a2,1
    80001b90:	020005b7          	lui	a1,0x2000
    80001b94:	15fd                	addi	a1,a1,-1
    80001b96:	05b6                	slli	a1,a1,0xd
    80001b98:	8526                	mv	a0,s1
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	79e080e7          	jalr	1950(ra) # 80001338 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ba2:	85ca                	mv	a1,s2
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	a34080e7          	jalr	-1484(ra) # 800015da <uvmfree>
}
    80001bae:	60e2                	ld	ra,24(sp)
    80001bb0:	6442                	ld	s0,16(sp)
    80001bb2:	64a2                	ld	s1,8(sp)
    80001bb4:	6902                	ld	s2,0(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <freeproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	1000                	addi	s0,sp,32
    80001bc4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bc6:	6d28                	ld	a0,88(a0)
    80001bc8:	c509                	beqz	a0,80001bd2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	e48080e7          	jalr	-440(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001bd2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bd6:	68a8                	ld	a0,80(s1)
    80001bd8:	c511                	beqz	a0,80001be4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bda:	64ac                	ld	a1,72(s1)
    80001bdc:	00000097          	auipc	ra,0x0
    80001be0:	f8c080e7          	jalr	-116(ra) # 80001b68 <proc_freepagetable>
  p->pagetable = 0;
    80001be4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bec:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bf0:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bf4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf8:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bfc:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c00:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c04:	0004ac23          	sw	zero,24(s1)
}
    80001c08:	60e2                	ld	ra,24(sp)
    80001c0a:	6442                	ld	s0,16(sp)
    80001c0c:	64a2                	ld	s1,8(sp)
    80001c0e:	6105                	addi	sp,sp,32
    80001c10:	8082                	ret

0000000080001c12 <allocproc>:
{
    80001c12:	1101                	addi	sp,sp,-32
    80001c14:	ec06                	sd	ra,24(sp)
    80001c16:	e822                	sd	s0,16(sp)
    80001c18:	e426                	sd	s1,8(sp)
    80001c1a:	e04a                	sd	s2,0(sp)
    80001c1c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1e:	00010497          	auipc	s1,0x10
    80001c22:	14a48493          	addi	s1,s1,330 # 80011d68 <proc>
    80001c26:	00016917          	auipc	s2,0x16
    80001c2a:	b4290913          	addi	s2,s2,-1214 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	fce080e7          	jalr	-50(ra) # 80000bfe <acquire>
    if(p->state == UNUSED) {
    80001c38:	4c9c                	lw	a5,24(s1)
    80001c3a:	cf81                	beqz	a5,80001c52 <allocproc+0x40>
      release(&p->lock);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	074080e7          	jalr	116(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c46:	16848493          	addi	s1,s1,360
    80001c4a:	ff2492e3          	bne	s1,s2,80001c2e <allocproc+0x1c>
  return 0;
    80001c4e:	4481                	li	s1,0
    80001c50:	a0b9                	j	80001c9e <allocproc+0x8c>
  p->pid = allocpid();
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	e34080e7          	jalr	-460(ra) # 80001a86 <allocpid>
    80001c5a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	eb2080e7          	jalr	-334(ra) # 80000b0e <kalloc>
    80001c64:	892a                	mv	s2,a0
    80001c66:	eca8                	sd	a0,88(s1)
    80001c68:	c131                	beqz	a0,80001cac <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	e60080e7          	jalr	-416(ra) # 80001acc <proc_pagetable>
    80001c74:	892a                	mv	s2,a0
    80001c76:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c78:	c129                	beqz	a0,80001cba <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c7a:	07000613          	li	a2,112
    80001c7e:	4581                	li	a1,0
    80001c80:	06048513          	addi	a0,s1,96
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	076080e7          	jalr	118(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001c8c:	00000797          	auipc	a5,0x0
    80001c90:	db478793          	addi	a5,a5,-588 # 80001a40 <forkret>
    80001c94:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c96:	60bc                	ld	a5,64(s1)
    80001c98:	6705                	lui	a4,0x1
    80001c9a:	97ba                	add	a5,a5,a4
    80001c9c:	f4bc                	sd	a5,104(s1)
}
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	60e2                	ld	ra,24(sp)
    80001ca2:	6442                	ld	s0,16(sp)
    80001ca4:	64a2                	ld	s1,8(sp)
    80001ca6:	6902                	ld	s2,0(sp)
    80001ca8:	6105                	addi	sp,sp,32
    80001caa:	8082                	ret
    release(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	004080e7          	jalr	4(ra) # 80000cb2 <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	b7dd                	j	80001c9e <allocproc+0x8c>
    freeproc(p);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	efe080e7          	jalr	-258(ra) # 80001bba <freeproc>
    release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	fec080e7          	jalr	-20(ra) # 80000cb2 <release>
    return 0;
    80001cce:	84ca                	mv	s1,s2
    80001cd0:	b7f9                	j	80001c9e <allocproc+0x8c>

0000000080001cd2 <userinit>:
{
    80001cd2:	1101                	addi	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	f36080e7          	jalr	-202(ra) # 80001c12 <allocproc>
    80001ce4:	84aa                	mv	s1,a0
  initproc = p;
    80001ce6:	00007797          	auipc	a5,0x7
    80001cea:	32a7b923          	sd	a0,818(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cee:	03400613          	li	a2,52
    80001cf2:	00007597          	auipc	a1,0x7
    80001cf6:	aee58593          	addi	a1,a1,-1298 # 800087e0 <initcode>
    80001cfa:	6928                	ld	a0,80(a0)
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	710080e7          	jalr	1808(ra) # 8000140c <uvminit>
  p->sz = PGSIZE;
    80001d04:	6785                	lui	a5,0x1
    80001d06:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0e:	6cb8                	ld	a4,88(s1)
    80001d10:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d12:	4641                	li	a2,16
    80001d14:	00006597          	auipc	a1,0x6
    80001d18:	46c58593          	addi	a1,a1,1132 # 80008180 <digits+0x140>
    80001d1c:	15848513          	addi	a0,s1,344
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	12c080e7          	jalr	300(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001d28:	00006517          	auipc	a0,0x6
    80001d2c:	46850513          	addi	a0,a0,1128 # 80008190 <digits+0x150>
    80001d30:	00002097          	auipc	ra,0x2
    80001d34:	1a8080e7          	jalr	424(ra) # 80003ed8 <namei>
    80001d38:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3c:	4789                	li	a5,2
    80001d3e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f70080e7          	jalr	-144(ra) # 80000cb2 <release>
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret

0000000080001d54 <growproc>:
{
    80001d54:	1101                	addi	sp,sp,-32
    80001d56:	ec06                	sd	ra,24(sp)
    80001d58:	e822                	sd	s0,16(sp)
    80001d5a:	e426                	sd	s1,8(sp)
    80001d5c:	e04a                	sd	s2,0(sp)
    80001d5e:	1000                	addi	s0,sp,32
    80001d60:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d62:	00000097          	auipc	ra,0x0
    80001d66:	ca6080e7          	jalr	-858(ra) # 80001a08 <myproc>
    80001d6a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d6c:	652c                	ld	a1,72(a0)
    80001d6e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d72:	00904f63          	bgtz	s1,80001d90 <growproc+0x3c>
  } else if(n < 0){
    80001d76:	0204cc63          	bltz	s1,80001dae <growproc+0x5a>
  p->sz = sz;
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d82:	4501                	li	a0,0
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6902                	ld	s2,0(sp)
    80001d8c:	6105                	addi	sp,sp,32
    80001d8e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d90:	9e25                	addw	a2,a2,s1
    80001d92:	1602                	slli	a2,a2,0x20
    80001d94:	9201                	srli	a2,a2,0x20
    80001d96:	1582                	slli	a1,a1,0x20
    80001d98:	9181                	srli	a1,a1,0x20
    80001d9a:	6928                	ld	a0,80(a0)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	72a080e7          	jalr	1834(ra) # 800014c6 <uvmalloc>
    80001da4:	0005061b          	sext.w	a2,a0
    80001da8:	fa69                	bnez	a2,80001d7a <growproc+0x26>
      return -1;
    80001daa:	557d                	li	a0,-1
    80001dac:	bfe1                	j	80001d84 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dae:	9e25                	addw	a2,a2,s1
    80001db0:	1602                	slli	a2,a2,0x20
    80001db2:	9201                	srli	a2,a2,0x20
    80001db4:	1582                	slli	a1,a1,0x20
    80001db6:	9181                	srli	a1,a1,0x20
    80001db8:	6928                	ld	a0,80(a0)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	6c4080e7          	jalr	1732(ra) # 8000147e <uvmdealloc>
    80001dc2:	0005061b          	sext.w	a2,a0
    80001dc6:	bf55                	j	80001d7a <growproc+0x26>

0000000080001dc8 <fork>:
{
    80001dc8:	7139                	addi	sp,sp,-64
    80001dca:	fc06                	sd	ra,56(sp)
    80001dcc:	f822                	sd	s0,48(sp)
    80001dce:	f426                	sd	s1,40(sp)
    80001dd0:	f04a                	sd	s2,32(sp)
    80001dd2:	ec4e                	sd	s3,24(sp)
    80001dd4:	e852                	sd	s4,16(sp)
    80001dd6:	e456                	sd	s5,8(sp)
    80001dd8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	c2e080e7          	jalr	-978(ra) # 80001a08 <myproc>
    80001de2:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	e2e080e7          	jalr	-466(ra) # 80001c12 <allocproc>
    80001dec:	c17d                	beqz	a0,80001ed2 <fork+0x10a>
    80001dee:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df0:	048ab603          	ld	a2,72(s5)
    80001df4:	692c                	ld	a1,80(a0)
    80001df6:	050ab503          	ld	a0,80(s5)
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	818080e7          	jalr	-2024(ra) # 80001612 <uvmcopy>
    80001e02:	04054a63          	bltz	a0,80001e56 <fork+0x8e>
  np->sz = p->sz;
    80001e06:	048ab783          	ld	a5,72(s5)
    80001e0a:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e0e:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e12:	058ab683          	ld	a3,88(s5)
    80001e16:	87b6                	mv	a5,a3
    80001e18:	058a3703          	ld	a4,88(s4)
    80001e1c:	12068693          	addi	a3,a3,288
    80001e20:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e24:	6788                	ld	a0,8(a5)
    80001e26:	6b8c                	ld	a1,16(a5)
    80001e28:	6f90                	ld	a2,24(a5)
    80001e2a:	01073023          	sd	a6,0(a4)
    80001e2e:	e708                	sd	a0,8(a4)
    80001e30:	eb0c                	sd	a1,16(a4)
    80001e32:	ef10                	sd	a2,24(a4)
    80001e34:	02078793          	addi	a5,a5,32
    80001e38:	02070713          	addi	a4,a4,32
    80001e3c:	fed792e3          	bne	a5,a3,80001e20 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e40:	058a3783          	ld	a5,88(s4)
    80001e44:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e48:	0d0a8493          	addi	s1,s5,208
    80001e4c:	0d0a0913          	addi	s2,s4,208
    80001e50:	150a8993          	addi	s3,s5,336
    80001e54:	a00d                	j	80001e76 <fork+0xae>
    freeproc(np);
    80001e56:	8552                	mv	a0,s4
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	d62080e7          	jalr	-670(ra) # 80001bba <freeproc>
    release(&np->lock);
    80001e60:	8552                	mv	a0,s4
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e50080e7          	jalr	-432(ra) # 80000cb2 <release>
    return -1;
    80001e6a:	54fd                	li	s1,-1
    80001e6c:	a889                	j	80001ebe <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001e6e:	04a1                	addi	s1,s1,8
    80001e70:	0921                	addi	s2,s2,8
    80001e72:	01348b63          	beq	s1,s3,80001e88 <fork+0xc0>
    if(p->ofile[i])
    80001e76:	6088                	ld	a0,0(s1)
    80001e78:	d97d                	beqz	a0,80001e6e <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e7a:	00002097          	auipc	ra,0x2
    80001e7e:	6ea080e7          	jalr	1770(ra) # 80004564 <filedup>
    80001e82:	00a93023          	sd	a0,0(s2)
    80001e86:	b7e5                	j	80001e6e <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e88:	150ab503          	ld	a0,336(s5)
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	85a080e7          	jalr	-1958(ra) # 800036e6 <idup>
    80001e94:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e98:	4641                	li	a2,16
    80001e9a:	158a8593          	addi	a1,s5,344
    80001e9e:	158a0513          	addi	a0,s4,344
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	faa080e7          	jalr	-86(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    80001eaa:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001eae:	4789                	li	a5,2
    80001eb0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eb4:	8552                	mv	a0,s4
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	dfc080e7          	jalr	-516(ra) # 80000cb2 <release>
}
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	70e2                	ld	ra,56(sp)
    80001ec2:	7442                	ld	s0,48(sp)
    80001ec4:	74a2                	ld	s1,40(sp)
    80001ec6:	7902                	ld	s2,32(sp)
    80001ec8:	69e2                	ld	s3,24(sp)
    80001eca:	6a42                	ld	s4,16(sp)
    80001ecc:	6aa2                	ld	s5,8(sp)
    80001ece:	6121                	addi	sp,sp,64
    80001ed0:	8082                	ret
    return -1;
    80001ed2:	54fd                	li	s1,-1
    80001ed4:	b7ed                	j	80001ebe <fork+0xf6>

0000000080001ed6 <reparent>:
{
    80001ed6:	7179                	addi	sp,sp,-48
    80001ed8:	f406                	sd	ra,40(sp)
    80001eda:	f022                	sd	s0,32(sp)
    80001edc:	ec26                	sd	s1,24(sp)
    80001ede:	e84a                	sd	s2,16(sp)
    80001ee0:	e44e                	sd	s3,8(sp)
    80001ee2:	e052                	sd	s4,0(sp)
    80001ee4:	1800                	addi	s0,sp,48
    80001ee6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ee8:	00010497          	auipc	s1,0x10
    80001eec:	e8048493          	addi	s1,s1,-384 # 80011d68 <proc>
      pp->parent = initproc;
    80001ef0:	00007a17          	auipc	s4,0x7
    80001ef4:	128a0a13          	addi	s4,s4,296 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ef8:	00016997          	auipc	s3,0x16
    80001efc:	87098993          	addi	s3,s3,-1936 # 80017768 <tickslock>
    80001f00:	a029                	j	80001f0a <reparent+0x34>
    80001f02:	16848493          	addi	s1,s1,360
    80001f06:	03348363          	beq	s1,s3,80001f2c <reparent+0x56>
    if(pp->parent == p){
    80001f0a:	709c                	ld	a5,32(s1)
    80001f0c:	ff279be3          	bne	a5,s2,80001f02 <reparent+0x2c>
      acquire(&pp->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	cec080e7          	jalr	-788(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    80001f1a:	000a3783          	ld	a5,0(s4)
    80001f1e:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	d90080e7          	jalr	-624(ra) # 80000cb2 <release>
    80001f2a:	bfe1                	j	80001f02 <reparent+0x2c>
}
    80001f2c:	70a2                	ld	ra,40(sp)
    80001f2e:	7402                	ld	s0,32(sp)
    80001f30:	64e2                	ld	s1,24(sp)
    80001f32:	6942                	ld	s2,16(sp)
    80001f34:	69a2                	ld	s3,8(sp)
    80001f36:	6a02                	ld	s4,0(sp)
    80001f38:	6145                	addi	sp,sp,48
    80001f3a:	8082                	ret

0000000080001f3c <scheduler>:
{
    80001f3c:	711d                	addi	sp,sp,-96
    80001f3e:	ec86                	sd	ra,88(sp)
    80001f40:	e8a2                	sd	s0,80(sp)
    80001f42:	e4a6                	sd	s1,72(sp)
    80001f44:	e0ca                	sd	s2,64(sp)
    80001f46:	fc4e                	sd	s3,56(sp)
    80001f48:	f852                	sd	s4,48(sp)
    80001f4a:	f456                	sd	s5,40(sp)
    80001f4c:	f05a                	sd	s6,32(sp)
    80001f4e:	ec5e                	sd	s7,24(sp)
    80001f50:	e862                	sd	s8,16(sp)
    80001f52:	e466                	sd	s9,8(sp)
    80001f54:	1080                	addi	s0,sp,96
    80001f56:	8792                	mv	a5,tp
  int id = r_tp();
    80001f58:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f5a:	00779c13          	slli	s8,a5,0x7
    80001f5e:	00010717          	auipc	a4,0x10
    80001f62:	9f270713          	addi	a4,a4,-1550 # 80011950 <pid_lock>
    80001f66:	9762                	add	a4,a4,s8
    80001f68:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f6c:	00010717          	auipc	a4,0x10
    80001f70:	a0470713          	addi	a4,a4,-1532 # 80011970 <cpus+0x8>
    80001f74:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    80001f76:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    80001f78:	4a89                	li	s5,2
        c->proc = p;
    80001f7a:	079e                	slli	a5,a5,0x7
    80001f7c:	00010b17          	auipc	s6,0x10
    80001f80:	9d4b0b13          	addi	s6,s6,-1580 # 80011950 <pid_lock>
    80001f84:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f86:	00015a17          	auipc	s4,0x15
    80001f8a:	7e2a0a13          	addi	s4,s4,2018 # 80017768 <tickslock>
    80001f8e:	a8a1                	j	80001fe6 <scheduler+0xaa>
      release(&p->lock);
    80001f90:	8526                	mv	a0,s1
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	d20080e7          	jalr	-736(ra) # 80000cb2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f9a:	16848493          	addi	s1,s1,360
    80001f9e:	03448a63          	beq	s1,s4,80001fd2 <scheduler+0x96>
      acquire(&p->lock);
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	c5a080e7          	jalr	-934(ra) # 80000bfe <acquire>
      if(p->state != UNUSED) {
    80001fac:	4c9c                	lw	a5,24(s1)
    80001fae:	d3ed                	beqz	a5,80001f90 <scheduler+0x54>
        nproc++;
    80001fb0:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001fb2:	fd579fe3          	bne	a5,s5,80001f90 <scheduler+0x54>
        p->state = RUNNING;
    80001fb6:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001fba:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001fbe:	06048593          	addi	a1,s1,96
    80001fc2:	8562                	mv	a0,s8
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	60c080e7          	jalr	1548(ra) # 800025d0 <swtch>
        c->proc = 0;
    80001fcc:	000b3c23          	sd	zero,24(s6)
    80001fd0:	b7c1                	j	80001f90 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001fd2:	013aca63          	blt	s5,s3,80001fe6 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fda:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fde:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fe2:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fee:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80001ff2:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff4:	00010497          	auipc	s1,0x10
    80001ff8:	d7448493          	addi	s1,s1,-652 # 80011d68 <proc>
        p->state = RUNNING;
    80001ffc:	4b8d                	li	s7,3
    80001ffe:	b755                	j	80001fa2 <scheduler+0x66>

0000000080002000 <sched>:
{
    80002000:	7179                	addi	sp,sp,-48
    80002002:	f406                	sd	ra,40(sp)
    80002004:	f022                	sd	s0,32(sp)
    80002006:	ec26                	sd	s1,24(sp)
    80002008:	e84a                	sd	s2,16(sp)
    8000200a:	e44e                	sd	s3,8(sp)
    8000200c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	9fa080e7          	jalr	-1542(ra) # 80001a08 <myproc>
    80002016:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	b6c080e7          	jalr	-1172(ra) # 80000b84 <holding>
    80002020:	c93d                	beqz	a0,80002096 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002024:	2781                	sext.w	a5,a5
    80002026:	079e                	slli	a5,a5,0x7
    80002028:	00010717          	auipc	a4,0x10
    8000202c:	92870713          	addi	a4,a4,-1752 # 80011950 <pid_lock>
    80002030:	97ba                	add	a5,a5,a4
    80002032:	0907a703          	lw	a4,144(a5)
    80002036:	4785                	li	a5,1
    80002038:	06f71763          	bne	a4,a5,800020a6 <sched+0xa6>
  if(p->state == RUNNING)
    8000203c:	4c98                	lw	a4,24(s1)
    8000203e:	478d                	li	a5,3
    80002040:	06f70b63          	beq	a4,a5,800020b6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002044:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002048:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000204a:	efb5                	bnez	a5,800020c6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000204e:	00010917          	auipc	s2,0x10
    80002052:	90290913          	addi	s2,s2,-1790 # 80011950 <pid_lock>
    80002056:	2781                	sext.w	a5,a5
    80002058:	079e                	slli	a5,a5,0x7
    8000205a:	97ca                	add	a5,a5,s2
    8000205c:	0947a983          	lw	s3,148(a5)
    80002060:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002062:	2781                	sext.w	a5,a5
    80002064:	079e                	slli	a5,a5,0x7
    80002066:	00010597          	auipc	a1,0x10
    8000206a:	90a58593          	addi	a1,a1,-1782 # 80011970 <cpus+0x8>
    8000206e:	95be                	add	a1,a1,a5
    80002070:	06048513          	addi	a0,s1,96
    80002074:	00000097          	auipc	ra,0x0
    80002078:	55c080e7          	jalr	1372(ra) # 800025d0 <swtch>
    8000207c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000207e:	2781                	sext.w	a5,a5
    80002080:	079e                	slli	a5,a5,0x7
    80002082:	97ca                	add	a5,a5,s2
    80002084:	0937aa23          	sw	s3,148(a5)
}
    80002088:	70a2                	ld	ra,40(sp)
    8000208a:	7402                	ld	s0,32(sp)
    8000208c:	64e2                	ld	s1,24(sp)
    8000208e:	6942                	ld	s2,16(sp)
    80002090:	69a2                	ld	s3,8(sp)
    80002092:	6145                	addi	sp,sp,48
    80002094:	8082                	ret
    panic("sched p->lock");
    80002096:	00006517          	auipc	a0,0x6
    8000209a:	10250513          	addi	a0,a0,258 # 80008198 <digits+0x158>
    8000209e:	ffffe097          	auipc	ra,0xffffe
    800020a2:	4a4080e7          	jalr	1188(ra) # 80000542 <panic>
    panic("sched locks");
    800020a6:	00006517          	auipc	a0,0x6
    800020aa:	10250513          	addi	a0,a0,258 # 800081a8 <digits+0x168>
    800020ae:	ffffe097          	auipc	ra,0xffffe
    800020b2:	494080e7          	jalr	1172(ra) # 80000542 <panic>
    panic("sched running");
    800020b6:	00006517          	auipc	a0,0x6
    800020ba:	10250513          	addi	a0,a0,258 # 800081b8 <digits+0x178>
    800020be:	ffffe097          	auipc	ra,0xffffe
    800020c2:	484080e7          	jalr	1156(ra) # 80000542 <panic>
    panic("sched interruptible");
    800020c6:	00006517          	auipc	a0,0x6
    800020ca:	10250513          	addi	a0,a0,258 # 800081c8 <digits+0x188>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	474080e7          	jalr	1140(ra) # 80000542 <panic>

00000000800020d6 <exit>:
{
    800020d6:	7179                	addi	sp,sp,-48
    800020d8:	f406                	sd	ra,40(sp)
    800020da:	f022                	sd	s0,32(sp)
    800020dc:	ec26                	sd	s1,24(sp)
    800020de:	e84a                	sd	s2,16(sp)
    800020e0:	e44e                	sd	s3,8(sp)
    800020e2:	e052                	sd	s4,0(sp)
    800020e4:	1800                	addi	s0,sp,48
    800020e6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020e8:	00000097          	auipc	ra,0x0
    800020ec:	920080e7          	jalr	-1760(ra) # 80001a08 <myproc>
    800020f0:	89aa                	mv	s3,a0
  if(p == initproc)
    800020f2:	00007797          	auipc	a5,0x7
    800020f6:	f267b783          	ld	a5,-218(a5) # 80009018 <initproc>
    800020fa:	0d050493          	addi	s1,a0,208
    800020fe:	15050913          	addi	s2,a0,336
    80002102:	02a79363          	bne	a5,a0,80002128 <exit+0x52>
    panic("init exiting");
    80002106:	00006517          	auipc	a0,0x6
    8000210a:	0da50513          	addi	a0,a0,218 # 800081e0 <digits+0x1a0>
    8000210e:	ffffe097          	auipc	ra,0xffffe
    80002112:	434080e7          	jalr	1076(ra) # 80000542 <panic>
      fileclose(f);
    80002116:	00002097          	auipc	ra,0x2
    8000211a:	4a0080e7          	jalr	1184(ra) # 800045b6 <fileclose>
      p->ofile[fd] = 0;
    8000211e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002122:	04a1                	addi	s1,s1,8
    80002124:	01248563          	beq	s1,s2,8000212e <exit+0x58>
    if(p->ofile[fd]){
    80002128:	6088                	ld	a0,0(s1)
    8000212a:	f575                	bnez	a0,80002116 <exit+0x40>
    8000212c:	bfdd                	j	80002122 <exit+0x4c>
  begin_op();
    8000212e:	00002097          	auipc	ra,0x2
    80002132:	fb6080e7          	jalr	-74(ra) # 800040e4 <begin_op>
  iput(p->cwd);
    80002136:	1509b503          	ld	a0,336(s3)
    8000213a:	00001097          	auipc	ra,0x1
    8000213e:	7a4080e7          	jalr	1956(ra) # 800038de <iput>
  end_op();
    80002142:	00002097          	auipc	ra,0x2
    80002146:	022080e7          	jalr	34(ra) # 80004164 <end_op>
  p->cwd = 0;
    8000214a:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000214e:	00007497          	auipc	s1,0x7
    80002152:	eca48493          	addi	s1,s1,-310 # 80009018 <initproc>
    80002156:	6088                	ld	a0,0(s1)
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	aa6080e7          	jalr	-1370(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    80002160:	6088                	ld	a0,0(s1)
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	766080e7          	jalr	1894(ra) # 800018c8 <wakeup1>
  release(&initproc->lock);
    8000216a:	6088                	ld	a0,0(s1)
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b46080e7          	jalr	-1210(ra) # 80000cb2 <release>
  acquire(&p->lock);
    80002174:	854e                	mv	a0,s3
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	a88080e7          	jalr	-1400(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    8000217e:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002182:	854e                	mv	a0,s3
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	b2e080e7          	jalr	-1234(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    8000218c:	8526                	mv	a0,s1
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	a70080e7          	jalr	-1424(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    80002196:	854e                	mv	a0,s3
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	a66080e7          	jalr	-1434(ra) # 80000bfe <acquire>
  reparent(p);
    800021a0:	854e                	mv	a0,s3
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	d34080e7          	jalr	-716(ra) # 80001ed6 <reparent>
  wakeup1(original_parent);
    800021aa:	8526                	mv	a0,s1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	71c080e7          	jalr	1820(ra) # 800018c8 <wakeup1>
  p->xstate = status;
    800021b4:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021b8:	4791                	li	a5,4
    800021ba:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	af2080e7          	jalr	-1294(ra) # 80000cb2 <release>
  sched();
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	e38080e7          	jalr	-456(ra) # 80002000 <sched>
  panic("zombie exit");
    800021d0:	00006517          	auipc	a0,0x6
    800021d4:	02050513          	addi	a0,a0,32 # 800081f0 <digits+0x1b0>
    800021d8:	ffffe097          	auipc	ra,0xffffe
    800021dc:	36a080e7          	jalr	874(ra) # 80000542 <panic>

00000000800021e0 <yield>:
{
    800021e0:	1101                	addi	sp,sp,-32
    800021e2:	ec06                	sd	ra,24(sp)
    800021e4:	e822                	sd	s0,16(sp)
    800021e6:	e426                	sd	s1,8(sp)
    800021e8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	81e080e7          	jalr	-2018(ra) # 80001a08 <myproc>
    800021f2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	a0a080e7          	jalr	-1526(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    800021fc:	4789                	li	a5,2
    800021fe:	cc9c                	sw	a5,24(s1)
  sched();
    80002200:	00000097          	auipc	ra,0x0
    80002204:	e00080e7          	jalr	-512(ra) # 80002000 <sched>
  release(&p->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	aa8080e7          	jalr	-1368(ra) # 80000cb2 <release>
}
    80002212:	60e2                	ld	ra,24(sp)
    80002214:	6442                	ld	s0,16(sp)
    80002216:	64a2                	ld	s1,8(sp)
    80002218:	6105                	addi	sp,sp,32
    8000221a:	8082                	ret

000000008000221c <sleep>:
{
    8000221c:	7179                	addi	sp,sp,-48
    8000221e:	f406                	sd	ra,40(sp)
    80002220:	f022                	sd	s0,32(sp)
    80002222:	ec26                	sd	s1,24(sp)
    80002224:	e84a                	sd	s2,16(sp)
    80002226:	e44e                	sd	s3,8(sp)
    80002228:	1800                	addi	s0,sp,48
    8000222a:	89aa                	mv	s3,a0
    8000222c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	7da080e7          	jalr	2010(ra) # 80001a08 <myproc>
    80002236:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002238:	05250663          	beq	a0,s2,80002284 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	9c2080e7          	jalr	-1598(ra) # 80000bfe <acquire>
    release(lk);
    80002244:	854a                	mv	a0,s2
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a6c080e7          	jalr	-1428(ra) # 80000cb2 <release>
  p->chan = chan;
    8000224e:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002252:	4785                	li	a5,1
    80002254:	cc9c                	sw	a5,24(s1)
  sched();
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	daa080e7          	jalr	-598(ra) # 80002000 <sched>
  p->chan = 0;
    8000225e:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a4e080e7          	jalr	-1458(ra) # 80000cb2 <release>
    acquire(lk);
    8000226c:	854a                	mv	a0,s2
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	990080e7          	jalr	-1648(ra) # 80000bfe <acquire>
}
    80002276:	70a2                	ld	ra,40(sp)
    80002278:	7402                	ld	s0,32(sp)
    8000227a:	64e2                	ld	s1,24(sp)
    8000227c:	6942                	ld	s2,16(sp)
    8000227e:	69a2                	ld	s3,8(sp)
    80002280:	6145                	addi	sp,sp,48
    80002282:	8082                	ret
  p->chan = chan;
    80002284:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002288:	4785                	li	a5,1
    8000228a:	cd1c                	sw	a5,24(a0)
  sched();
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	d74080e7          	jalr	-652(ra) # 80002000 <sched>
  p->chan = 0;
    80002294:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002298:	bff9                	j	80002276 <sleep+0x5a>

000000008000229a <wait>:
{
    8000229a:	715d                	addi	sp,sp,-80
    8000229c:	e486                	sd	ra,72(sp)
    8000229e:	e0a2                	sd	s0,64(sp)
    800022a0:	fc26                	sd	s1,56(sp)
    800022a2:	f84a                	sd	s2,48(sp)
    800022a4:	f44e                	sd	s3,40(sp)
    800022a6:	f052                	sd	s4,32(sp)
    800022a8:	ec56                	sd	s5,24(sp)
    800022aa:	e85a                	sd	s6,16(sp)
    800022ac:	e45e                	sd	s7,8(sp)
    800022ae:	0880                	addi	s0,sp,80
    800022b0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	756080e7          	jalr	1878(ra) # 80001a08 <myproc>
    800022ba:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	942080e7          	jalr	-1726(ra) # 80000bfe <acquire>
    havekids = 0;
    800022c4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022c6:	4a11                	li	s4,4
        havekids = 1;
    800022c8:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022ca:	00015997          	auipc	s3,0x15
    800022ce:	49e98993          	addi	s3,s3,1182 # 80017768 <tickslock>
    havekids = 0;
    800022d2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022d4:	00010497          	auipc	s1,0x10
    800022d8:	a9448493          	addi	s1,s1,-1388 # 80011d68 <proc>
    800022dc:	a08d                	j	8000233e <wait+0xa4>
          pid = np->pid;
    800022de:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022e2:	000b0e63          	beqz	s6,800022fe <wait+0x64>
    800022e6:	4691                	li	a3,4
    800022e8:	03448613          	addi	a2,s1,52
    800022ec:	85da                	mv	a1,s6
    800022ee:	05093503          	ld	a0,80(s2)
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	408080e7          	jalr	1032(ra) # 800016fa <copyout>
    800022fa:	02054263          	bltz	a0,8000231e <wait+0x84>
          freeproc(np);
    800022fe:	8526                	mv	a0,s1
    80002300:	00000097          	auipc	ra,0x0
    80002304:	8ba080e7          	jalr	-1862(ra) # 80001bba <freeproc>
          release(&np->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	9a8080e7          	jalr	-1624(ra) # 80000cb2 <release>
          release(&p->lock);
    80002312:	854a                	mv	a0,s2
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	99e080e7          	jalr	-1634(ra) # 80000cb2 <release>
          return pid;
    8000231c:	a8a9                	j	80002376 <wait+0xdc>
            release(&np->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	992080e7          	jalr	-1646(ra) # 80000cb2 <release>
            release(&p->lock);
    80002328:	854a                	mv	a0,s2
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	988080e7          	jalr	-1656(ra) # 80000cb2 <release>
            return -1;
    80002332:	59fd                	li	s3,-1
    80002334:	a089                	j	80002376 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002336:	16848493          	addi	s1,s1,360
    8000233a:	03348463          	beq	s1,s3,80002362 <wait+0xc8>
      if(np->parent == p){
    8000233e:	709c                	ld	a5,32(s1)
    80002340:	ff279be3          	bne	a5,s2,80002336 <wait+0x9c>
        acquire(&np->lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	8b8080e7          	jalr	-1864(ra) # 80000bfe <acquire>
        if(np->state == ZOMBIE){
    8000234e:	4c9c                	lw	a5,24(s1)
    80002350:	f94787e3          	beq	a5,s4,800022de <wait+0x44>
        release(&np->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	95c080e7          	jalr	-1700(ra) # 80000cb2 <release>
        havekids = 1;
    8000235e:	8756                	mv	a4,s5
    80002360:	bfd9                	j	80002336 <wait+0x9c>
    if(!havekids || p->killed){
    80002362:	c701                	beqz	a4,8000236a <wait+0xd0>
    80002364:	03092783          	lw	a5,48(s2)
    80002368:	c39d                	beqz	a5,8000238e <wait+0xf4>
      release(&p->lock);
    8000236a:	854a                	mv	a0,s2
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	946080e7          	jalr	-1722(ra) # 80000cb2 <release>
      return -1;
    80002374:	59fd                	li	s3,-1
}
    80002376:	854e                	mv	a0,s3
    80002378:	60a6                	ld	ra,72(sp)
    8000237a:	6406                	ld	s0,64(sp)
    8000237c:	74e2                	ld	s1,56(sp)
    8000237e:	7942                	ld	s2,48(sp)
    80002380:	79a2                	ld	s3,40(sp)
    80002382:	7a02                	ld	s4,32(sp)
    80002384:	6ae2                	ld	s5,24(sp)
    80002386:	6b42                	ld	s6,16(sp)
    80002388:	6ba2                	ld	s7,8(sp)
    8000238a:	6161                	addi	sp,sp,80
    8000238c:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000238e:	85ca                	mv	a1,s2
    80002390:	854a                	mv	a0,s2
    80002392:	00000097          	auipc	ra,0x0
    80002396:	e8a080e7          	jalr	-374(ra) # 8000221c <sleep>
    havekids = 0;
    8000239a:	bf25                	j	800022d2 <wait+0x38>

000000008000239c <wakeup>:
{
    8000239c:	7139                	addi	sp,sp,-64
    8000239e:	fc06                	sd	ra,56(sp)
    800023a0:	f822                	sd	s0,48(sp)
    800023a2:	f426                	sd	s1,40(sp)
    800023a4:	f04a                	sd	s2,32(sp)
    800023a6:	ec4e                	sd	s3,24(sp)
    800023a8:	e852                	sd	s4,16(sp)
    800023aa:	e456                	sd	s5,8(sp)
    800023ac:	0080                	addi	s0,sp,64
    800023ae:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b0:	00010497          	auipc	s1,0x10
    800023b4:	9b848493          	addi	s1,s1,-1608 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023b8:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023ba:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023bc:	00015917          	auipc	s2,0x15
    800023c0:	3ac90913          	addi	s2,s2,940 # 80017768 <tickslock>
    800023c4:	a811                	j	800023d8 <wakeup+0x3c>
    release(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8ea080e7          	jalr	-1814(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d0:	16848493          	addi	s1,s1,360
    800023d4:	03248063          	beq	s1,s2,800023f4 <wakeup+0x58>
    acquire(&p->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	824080e7          	jalr	-2012(ra) # 80000bfe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023e2:	4c9c                	lw	a5,24(s1)
    800023e4:	ff3791e3          	bne	a5,s3,800023c6 <wakeup+0x2a>
    800023e8:	749c                	ld	a5,40(s1)
    800023ea:	fd479ee3          	bne	a5,s4,800023c6 <wakeup+0x2a>
      p->state = RUNNABLE;
    800023ee:	0154ac23          	sw	s5,24(s1)
    800023f2:	bfd1                	j	800023c6 <wakeup+0x2a>
}
    800023f4:	70e2                	ld	ra,56(sp)
    800023f6:	7442                	ld	s0,48(sp)
    800023f8:	74a2                	ld	s1,40(sp)
    800023fa:	7902                	ld	s2,32(sp)
    800023fc:	69e2                	ld	s3,24(sp)
    800023fe:	6a42                	ld	s4,16(sp)
    80002400:	6aa2                	ld	s5,8(sp)
    80002402:	6121                	addi	sp,sp,64
    80002404:	8082                	ret

0000000080002406 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002406:	7179                	addi	sp,sp,-48
    80002408:	f406                	sd	ra,40(sp)
    8000240a:	f022                	sd	s0,32(sp)
    8000240c:	ec26                	sd	s1,24(sp)
    8000240e:	e84a                	sd	s2,16(sp)
    80002410:	e44e                	sd	s3,8(sp)
    80002412:	1800                	addi	s0,sp,48
    80002414:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002416:	00010497          	auipc	s1,0x10
    8000241a:	95248493          	addi	s1,s1,-1710 # 80011d68 <proc>
    8000241e:	00015997          	auipc	s3,0x15
    80002422:	34a98993          	addi	s3,s3,842 # 80017768 <tickslock>
    acquire(&p->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	7d6080e7          	jalr	2006(ra) # 80000bfe <acquire>
    if(p->pid == pid){
    80002430:	5c9c                	lw	a5,56(s1)
    80002432:	01278d63          	beq	a5,s2,8000244c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002436:	8526                	mv	a0,s1
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	87a080e7          	jalr	-1926(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002440:	16848493          	addi	s1,s1,360
    80002444:	ff3491e3          	bne	s1,s3,80002426 <kill+0x20>
  }
  return -1;
    80002448:	557d                	li	a0,-1
    8000244a:	a821                	j	80002462 <kill+0x5c>
      p->killed = 1;
    8000244c:	4785                	li	a5,1
    8000244e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002450:	4c98                	lw	a4,24(s1)
    80002452:	00f70f63          	beq	a4,a5,80002470 <kill+0x6a>
      release(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	85a080e7          	jalr	-1958(ra) # 80000cb2 <release>
      return 0;
    80002460:	4501                	li	a0,0
}
    80002462:	70a2                	ld	ra,40(sp)
    80002464:	7402                	ld	s0,32(sp)
    80002466:	64e2                	ld	s1,24(sp)
    80002468:	6942                	ld	s2,16(sp)
    8000246a:	69a2                	ld	s3,8(sp)
    8000246c:	6145                	addi	sp,sp,48
    8000246e:	8082                	ret
        p->state = RUNNABLE;
    80002470:	4789                	li	a5,2
    80002472:	cc9c                	sw	a5,24(s1)
    80002474:	b7cd                	j	80002456 <kill+0x50>

0000000080002476 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002476:	7179                	addi	sp,sp,-48
    80002478:	f406                	sd	ra,40(sp)
    8000247a:	f022                	sd	s0,32(sp)
    8000247c:	ec26                	sd	s1,24(sp)
    8000247e:	e84a                	sd	s2,16(sp)
    80002480:	e44e                	sd	s3,8(sp)
    80002482:	e052                	sd	s4,0(sp)
    80002484:	1800                	addi	s0,sp,48
    80002486:	84aa                	mv	s1,a0
    80002488:	892e                	mv	s2,a1
    8000248a:	89b2                	mv	s3,a2
    8000248c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	57a080e7          	jalr	1402(ra) # 80001a08 <myproc>
  if(user_dst){
    80002496:	c08d                	beqz	s1,800024b8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002498:	86d2                	mv	a3,s4
    8000249a:	864e                	mv	a2,s3
    8000249c:	85ca                	mv	a1,s2
    8000249e:	6928                	ld	a0,80(a0)
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	25a080e7          	jalr	602(ra) # 800016fa <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024a8:	70a2                	ld	ra,40(sp)
    800024aa:	7402                	ld	s0,32(sp)
    800024ac:	64e2                	ld	s1,24(sp)
    800024ae:	6942                	ld	s2,16(sp)
    800024b0:	69a2                	ld	s3,8(sp)
    800024b2:	6a02                	ld	s4,0(sp)
    800024b4:	6145                	addi	sp,sp,48
    800024b6:	8082                	ret
    memmove((char *)dst, src, len);
    800024b8:	000a061b          	sext.w	a2,s4
    800024bc:	85ce                	mv	a1,s3
    800024be:	854a                	mv	a0,s2
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	896080e7          	jalr	-1898(ra) # 80000d56 <memmove>
    return 0;
    800024c8:	8526                	mv	a0,s1
    800024ca:	bff9                	j	800024a8 <either_copyout+0x32>

00000000800024cc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024cc:	7179                	addi	sp,sp,-48
    800024ce:	f406                	sd	ra,40(sp)
    800024d0:	f022                	sd	s0,32(sp)
    800024d2:	ec26                	sd	s1,24(sp)
    800024d4:	e84a                	sd	s2,16(sp)
    800024d6:	e44e                	sd	s3,8(sp)
    800024d8:	e052                	sd	s4,0(sp)
    800024da:	1800                	addi	s0,sp,48
    800024dc:	892a                	mv	s2,a0
    800024de:	84ae                	mv	s1,a1
    800024e0:	89b2                	mv	s3,a2
    800024e2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	524080e7          	jalr	1316(ra) # 80001a08 <myproc>
  if(user_src){
    800024ec:	c08d                	beqz	s1,8000250e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ee:	86d2                	mv	a3,s4
    800024f0:	864e                	mv	a2,s3
    800024f2:	85ca                	mv	a1,s2
    800024f4:	6928                	ld	a0,80(a0)
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	290080e7          	jalr	656(ra) # 80001786 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024fe:	70a2                	ld	ra,40(sp)
    80002500:	7402                	ld	s0,32(sp)
    80002502:	64e2                	ld	s1,24(sp)
    80002504:	6942                	ld	s2,16(sp)
    80002506:	69a2                	ld	s3,8(sp)
    80002508:	6a02                	ld	s4,0(sp)
    8000250a:	6145                	addi	sp,sp,48
    8000250c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000250e:	000a061b          	sext.w	a2,s4
    80002512:	85ce                	mv	a1,s3
    80002514:	854a                	mv	a0,s2
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	840080e7          	jalr	-1984(ra) # 80000d56 <memmove>
    return 0;
    8000251e:	8526                	mv	a0,s1
    80002520:	bff9                	j	800024fe <either_copyin+0x32>

0000000080002522 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002522:	715d                	addi	sp,sp,-80
    80002524:	e486                	sd	ra,72(sp)
    80002526:	e0a2                	sd	s0,64(sp)
    80002528:	fc26                	sd	s1,56(sp)
    8000252a:	f84a                	sd	s2,48(sp)
    8000252c:	f44e                	sd	s3,40(sp)
    8000252e:	f052                	sd	s4,32(sp)
    80002530:	ec56                	sd	s5,24(sp)
    80002532:	e85a                	sd	s6,16(sp)
    80002534:	e45e                	sd	s7,8(sp)
    80002536:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002538:	00006517          	auipc	a0,0x6
    8000253c:	b9050513          	addi	a0,a0,-1136 # 800080c8 <digits+0x88>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	04c080e7          	jalr	76(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002548:	00010497          	auipc	s1,0x10
    8000254c:	97848493          	addi	s1,s1,-1672 # 80011ec0 <proc+0x158>
    80002550:	00015917          	auipc	s2,0x15
    80002554:	37090913          	addi	s2,s2,880 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000255a:	00006997          	auipc	s3,0x6
    8000255e:	ca698993          	addi	s3,s3,-858 # 80008200 <digits+0x1c0>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	00006a97          	auipc	s5,0x6
    80002566:	ca6a8a93          	addi	s5,s5,-858 # 80008208 <digits+0x1c8>
    printf("\n");
    8000256a:	00006a17          	auipc	s4,0x6
    8000256e:	b5ea0a13          	addi	s4,s4,-1186 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002572:	00006b97          	auipc	s7,0x6
    80002576:	cceb8b93          	addi	s7,s7,-818 # 80008240 <states.0>
    8000257a:	a00d                	j	8000259c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000257c:	ee06a583          	lw	a1,-288(a3)
    80002580:	8556                	mv	a0,s5
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	00a080e7          	jalr	10(ra) # 8000058c <printf>
    printf("\n");
    8000258a:	8552                	mv	a0,s4
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	000080e7          	jalr	ra # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002594:	16848493          	addi	s1,s1,360
    80002598:	03248163          	beq	s1,s2,800025ba <procdump+0x98>
    if(p->state == UNUSED)
    8000259c:	86a6                	mv	a3,s1
    8000259e:	ec04a783          	lw	a5,-320(s1)
    800025a2:	dbed                	beqz	a5,80002594 <procdump+0x72>
      state = "???";
    800025a4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a6:	fcfb6be3          	bltu	s6,a5,8000257c <procdump+0x5a>
    800025aa:	1782                	slli	a5,a5,0x20
    800025ac:	9381                	srli	a5,a5,0x20
    800025ae:	078e                	slli	a5,a5,0x3
    800025b0:	97de                	add	a5,a5,s7
    800025b2:	6390                	ld	a2,0(a5)
    800025b4:	f661                	bnez	a2,8000257c <procdump+0x5a>
      state = "???";
    800025b6:	864e                	mv	a2,s3
    800025b8:	b7d1                	j	8000257c <procdump+0x5a>
  }
}
    800025ba:	60a6                	ld	ra,72(sp)
    800025bc:	6406                	ld	s0,64(sp)
    800025be:	74e2                	ld	s1,56(sp)
    800025c0:	7942                	ld	s2,48(sp)
    800025c2:	79a2                	ld	s3,40(sp)
    800025c4:	7a02                	ld	s4,32(sp)
    800025c6:	6ae2                	ld	s5,24(sp)
    800025c8:	6b42                	ld	s6,16(sp)
    800025ca:	6ba2                	ld	s7,8(sp)
    800025cc:	6161                	addi	sp,sp,80
    800025ce:	8082                	ret

00000000800025d0 <swtch>:
    800025d0:	00153023          	sd	ra,0(a0)
    800025d4:	00253423          	sd	sp,8(a0)
    800025d8:	e900                	sd	s0,16(a0)
    800025da:	ed04                	sd	s1,24(a0)
    800025dc:	03253023          	sd	s2,32(a0)
    800025e0:	03353423          	sd	s3,40(a0)
    800025e4:	03453823          	sd	s4,48(a0)
    800025e8:	03553c23          	sd	s5,56(a0)
    800025ec:	05653023          	sd	s6,64(a0)
    800025f0:	05753423          	sd	s7,72(a0)
    800025f4:	05853823          	sd	s8,80(a0)
    800025f8:	05953c23          	sd	s9,88(a0)
    800025fc:	07a53023          	sd	s10,96(a0)
    80002600:	07b53423          	sd	s11,104(a0)
    80002604:	0005b083          	ld	ra,0(a1)
    80002608:	0085b103          	ld	sp,8(a1)
    8000260c:	6980                	ld	s0,16(a1)
    8000260e:	6d84                	ld	s1,24(a1)
    80002610:	0205b903          	ld	s2,32(a1)
    80002614:	0285b983          	ld	s3,40(a1)
    80002618:	0305ba03          	ld	s4,48(a1)
    8000261c:	0385ba83          	ld	s5,56(a1)
    80002620:	0405bb03          	ld	s6,64(a1)
    80002624:	0485bb83          	ld	s7,72(a1)
    80002628:	0505bc03          	ld	s8,80(a1)
    8000262c:	0585bc83          	ld	s9,88(a1)
    80002630:	0605bd03          	ld	s10,96(a1)
    80002634:	0685bd83          	ld	s11,104(a1)
    80002638:	8082                	ret

000000008000263a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000263a:	1141                	addi	sp,sp,-16
    8000263c:	e406                	sd	ra,8(sp)
    8000263e:	e022                	sd	s0,0(sp)
    80002640:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002642:	00006597          	auipc	a1,0x6
    80002646:	c2658593          	addi	a1,a1,-986 # 80008268 <states.0+0x28>
    8000264a:	00015517          	auipc	a0,0x15
    8000264e:	11e50513          	addi	a0,a0,286 # 80017768 <tickslock>
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	51c080e7          	jalr	1308(ra) # 80000b6e <initlock>
}
    8000265a:	60a2                	ld	ra,8(sp)
    8000265c:	6402                	ld	s0,0(sp)
    8000265e:	0141                	addi	sp,sp,16
    80002660:	8082                	ret

0000000080002662 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002662:	1141                	addi	sp,sp,-16
    80002664:	e422                	sd	s0,8(sp)
    80002666:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002668:	00003797          	auipc	a5,0x3
    8000266c:	5a878793          	addi	a5,a5,1448 # 80005c10 <kernelvec>
    80002670:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002674:	6422                	ld	s0,8(sp)
    80002676:	0141                	addi	sp,sp,16
    80002678:	8082                	ret

000000008000267a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000267a:	1141                	addi	sp,sp,-16
    8000267c:	e406                	sd	ra,8(sp)
    8000267e:	e022                	sd	s0,0(sp)
    80002680:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002682:	fffff097          	auipc	ra,0xfffff
    80002686:	386080e7          	jalr	902(ra) # 80001a08 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000268a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000268e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002690:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002694:	00005617          	auipc	a2,0x5
    80002698:	96c60613          	addi	a2,a2,-1684 # 80007000 <_trampoline>
    8000269c:	00005697          	auipc	a3,0x5
    800026a0:	96468693          	addi	a3,a3,-1692 # 80007000 <_trampoline>
    800026a4:	8e91                	sub	a3,a3,a2
    800026a6:	040007b7          	lui	a5,0x4000
    800026aa:	17fd                	addi	a5,a5,-1
    800026ac:	07b2                	slli	a5,a5,0xc
    800026ae:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026b4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026b6:	180026f3          	csrr	a3,satp
    800026ba:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026bc:	6d38                	ld	a4,88(a0)
    800026be:	6134                	ld	a3,64(a0)
    800026c0:	6585                	lui	a1,0x1
    800026c2:	96ae                	add	a3,a3,a1
    800026c4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026c6:	6d38                	ld	a4,88(a0)
    800026c8:	00000697          	auipc	a3,0x0
    800026cc:	13868693          	addi	a3,a3,312 # 80002800 <usertrap>
    800026d0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026d2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026d4:	8692                	mv	a3,tp
    800026d6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026dc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026e0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026e8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ea:	6f18                	ld	a4,24(a4)
    800026ec:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026f0:	692c                	ld	a1,80(a0)
    800026f2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026f4:	00005717          	auipc	a4,0x5
    800026f8:	99c70713          	addi	a4,a4,-1636 # 80007090 <userret>
    800026fc:	8f11                	sub	a4,a4,a2
    800026fe:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002700:	577d                	li	a4,-1
    80002702:	177e                	slli	a4,a4,0x3f
    80002704:	8dd9                	or	a1,a1,a4
    80002706:	02000537          	lui	a0,0x2000
    8000270a:	157d                	addi	a0,a0,-1
    8000270c:	0536                	slli	a0,a0,0xd
    8000270e:	9782                	jalr	a5
}
    80002710:	60a2                	ld	ra,8(sp)
    80002712:	6402                	ld	s0,0(sp)
    80002714:	0141                	addi	sp,sp,16
    80002716:	8082                	ret

0000000080002718 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002718:	1101                	addi	sp,sp,-32
    8000271a:	ec06                	sd	ra,24(sp)
    8000271c:	e822                	sd	s0,16(sp)
    8000271e:	e426                	sd	s1,8(sp)
    80002720:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002722:	00015497          	auipc	s1,0x15
    80002726:	04648493          	addi	s1,s1,70 # 80017768 <tickslock>
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	4d2080e7          	jalr	1234(ra) # 80000bfe <acquire>
  ticks++;
    80002734:	00007517          	auipc	a0,0x7
    80002738:	8ec50513          	addi	a0,a0,-1812 # 80009020 <ticks>
    8000273c:	411c                	lw	a5,0(a0)
    8000273e:	2785                	addiw	a5,a5,1
    80002740:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002742:	00000097          	auipc	ra,0x0
    80002746:	c5a080e7          	jalr	-934(ra) # 8000239c <wakeup>
  release(&tickslock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	566080e7          	jalr	1382(ra) # 80000cb2 <release>
}
    80002754:	60e2                	ld	ra,24(sp)
    80002756:	6442                	ld	s0,16(sp)
    80002758:	64a2                	ld	s1,8(sp)
    8000275a:	6105                	addi	sp,sp,32
    8000275c:	8082                	ret

000000008000275e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000275e:	1101                	addi	sp,sp,-32
    80002760:	ec06                	sd	ra,24(sp)
    80002762:	e822                	sd	s0,16(sp)
    80002764:	e426                	sd	s1,8(sp)
    80002766:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002768:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000276c:	00074d63          	bltz	a4,80002786 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002770:	57fd                	li	a5,-1
    80002772:	17fe                	slli	a5,a5,0x3f
    80002774:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002776:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002778:	06f70363          	beq	a4,a5,800027de <devintr+0x80>
  }
}
    8000277c:	60e2                	ld	ra,24(sp)
    8000277e:	6442                	ld	s0,16(sp)
    80002780:	64a2                	ld	s1,8(sp)
    80002782:	6105                	addi	sp,sp,32
    80002784:	8082                	ret
     (scause & 0xff) == 9){
    80002786:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000278a:	46a5                	li	a3,9
    8000278c:	fed792e3          	bne	a5,a3,80002770 <devintr+0x12>
    int irq = plic_claim();
    80002790:	00003097          	auipc	ra,0x3
    80002794:	588080e7          	jalr	1416(ra) # 80005d18 <plic_claim>
    80002798:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000279a:	47a9                	li	a5,10
    8000279c:	02f50763          	beq	a0,a5,800027ca <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027a0:	4785                	li	a5,1
    800027a2:	02f50963          	beq	a0,a5,800027d4 <devintr+0x76>
    return 1;
    800027a6:	4505                	li	a0,1
    } else if(irq){
    800027a8:	d8f1                	beqz	s1,8000277c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027aa:	85a6                	mv	a1,s1
    800027ac:	00006517          	auipc	a0,0x6
    800027b0:	ac450513          	addi	a0,a0,-1340 # 80008270 <states.0+0x30>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	dd8080e7          	jalr	-552(ra) # 8000058c <printf>
      plic_complete(irq);
    800027bc:	8526                	mv	a0,s1
    800027be:	00003097          	auipc	ra,0x3
    800027c2:	57e080e7          	jalr	1406(ra) # 80005d3c <plic_complete>
    return 1;
    800027c6:	4505                	li	a0,1
    800027c8:	bf55                	j	8000277c <devintr+0x1e>
      uartintr();
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	1f8080e7          	jalr	504(ra) # 800009c2 <uartintr>
    800027d2:	b7ed                	j	800027bc <devintr+0x5e>
      virtio_disk_intr();
    800027d4:	00004097          	auipc	ra,0x4
    800027d8:	9e2080e7          	jalr	-1566(ra) # 800061b6 <virtio_disk_intr>
    800027dc:	b7c5                	j	800027bc <devintr+0x5e>
    if(cpuid() == 0){
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	1fe080e7          	jalr	510(ra) # 800019dc <cpuid>
    800027e6:	c901                	beqz	a0,800027f6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027e8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ee:	14479073          	csrw	sip,a5
    return 2;
    800027f2:	4509                	li	a0,2
    800027f4:	b761                	j	8000277c <devintr+0x1e>
      clockintr();
    800027f6:	00000097          	auipc	ra,0x0
    800027fa:	f22080e7          	jalr	-222(ra) # 80002718 <clockintr>
    800027fe:	b7ed                	j	800027e8 <devintr+0x8a>

0000000080002800 <usertrap>:
{
    80002800:	7179                	addi	sp,sp,-48
    80002802:	f406                	sd	ra,40(sp)
    80002804:	f022                	sd	s0,32(sp)
    80002806:	ec26                	sd	s1,24(sp)
    80002808:	e84a                	sd	s2,16(sp)
    8000280a:	e44e                	sd	s3,8(sp)
    8000280c:	e052                	sd	s4,0(sp)
    8000280e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002810:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002814:	1007f793          	andi	a5,a5,256
    80002818:	e7a5                	bnez	a5,80002880 <usertrap+0x80>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000281a:	00003797          	auipc	a5,0x3
    8000281e:	3f678793          	addi	a5,a5,1014 # 80005c10 <kernelvec>
    80002822:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002826:	fffff097          	auipc	ra,0xfffff
    8000282a:	1e2080e7          	jalr	482(ra) # 80001a08 <myproc>
    8000282e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002830:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002832:	14102773          	csrr	a4,sepc
    80002836:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002838:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000283c:	47a1                	li	a5,8
    8000283e:	04f71f63          	bne	a4,a5,8000289c <usertrap+0x9c>
    if(p->killed)
    80002842:	591c                	lw	a5,48(a0)
    80002844:	e7b1                	bnez	a5,80002890 <usertrap+0x90>
    p->trapframe->epc += 4;
    80002846:	6cb8                	ld	a4,88(s1)
    80002848:	6f1c                	ld	a5,24(a4)
    8000284a:	0791                	addi	a5,a5,4
    8000284c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002852:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002856:	10079073          	csrw	sstatus,a5
    syscall();
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	36c080e7          	jalr	876(ra) # 80002bc6 <syscall>
  if(p->killed)
    80002862:	589c                	lw	a5,48(s1)
    80002864:	10079e63          	bnez	a5,80002980 <usertrap+0x180>
  usertrapret();
    80002868:	00000097          	auipc	ra,0x0
    8000286c:	e12080e7          	jalr	-494(ra) # 8000267a <usertrapret>
}
    80002870:	70a2                	ld	ra,40(sp)
    80002872:	7402                	ld	s0,32(sp)
    80002874:	64e2                	ld	s1,24(sp)
    80002876:	6942                	ld	s2,16(sp)
    80002878:	69a2                	ld	s3,8(sp)
    8000287a:	6a02                	ld	s4,0(sp)
    8000287c:	6145                	addi	sp,sp,48
    8000287e:	8082                	ret
    panic("usertrap: not from user mode");
    80002880:	00006517          	auipc	a0,0x6
    80002884:	a1050513          	addi	a0,a0,-1520 # 80008290 <states.0+0x50>
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	cba080e7          	jalr	-838(ra) # 80000542 <panic>
      exit(-1);
    80002890:	557d                	li	a0,-1
    80002892:	00000097          	auipc	ra,0x0
    80002896:	844080e7          	jalr	-1980(ra) # 800020d6 <exit>
    8000289a:	b775                	j	80002846 <usertrap+0x46>
  else if((which_dev = devintr()) != 0){
    8000289c:	00000097          	auipc	ra,0x0
    800028a0:	ec2080e7          	jalr	-318(ra) # 8000275e <devintr>
    800028a4:	892a                	mv	s2,a0
    800028a6:	e971                	bnez	a0,8000297a <usertrap+0x17a>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028a8:	14202773          	csrr	a4,scause
  else if(r_scause()==13||r_scause()==15)
    800028ac:	47b5                	li	a5,13
    800028ae:	00f70763          	beq	a4,a5,800028bc <usertrap+0xbc>
    800028b2:	14202773          	csrr	a4,scause
    800028b6:	47bd                	li	a5,15
    800028b8:	08f71763          	bne	a4,a5,80002946 <usertrap+0x146>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028bc:	143029f3          	csrr	s3,stval
    if(va>=p->sz||va<=PGROUNDDOWN(p->trapframe->sp))
    800028c0:	64bc                	ld	a5,72(s1)
    800028c2:	00f9f863          	bgeu	s3,a5,800028d2 <usertrap+0xd2>
    800028c6:	6cbc                	ld	a5,88(s1)
    800028c8:	7b98                	ld	a4,48(a5)
    800028ca:	77fd                	lui	a5,0xfffff
    800028cc:	8ff9                	and	a5,a5,a4
    800028ce:	0337e163          	bltu	a5,s3,800028f0 <usertrap+0xf0>
      p->killed=1;
    800028d2:	4785                	li	a5,1
    800028d4:	d89c                	sw	a5,48(s1)
    exit(-1);
    800028d6:	557d                	li	a0,-1
    800028d8:	fffff097          	auipc	ra,0xfffff
    800028dc:	7fe080e7          	jalr	2046(ra) # 800020d6 <exit>
  if(which_dev == 2)
    800028e0:	4789                	li	a5,2
    800028e2:	f8f913e3          	bne	s2,a5,80002868 <usertrap+0x68>
    yield();
    800028e6:	00000097          	auipc	ra,0x0
    800028ea:	8fa080e7          	jalr	-1798(ra) # 800021e0 <yield>
    800028ee:	bfad                	j	80002868 <usertrap+0x68>
       uint64 ka=(uint64)kalloc();
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	21e080e7          	jalr	542(ra) # 80000b0e <kalloc>
    800028f8:	8a2a                	mv	s4,a0
       if(ka==0)
    800028fa:	c91d                	beqz	a0,80002930 <usertrap+0x130>
         memset((void*)ka,0,PGSIZE);
    800028fc:	6605                	lui	a2,0x1
    800028fe:	4581                	li	a1,0
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	3fa080e7          	jalr	1018(ra) # 80000cfa <memset>
         if(mappages(p->pagetable,va,PGSIZE,ka,PTE_W|PTE_U|PTE_R)!=0)
    80002908:	4759                	li	a4,22
    8000290a:	86d2                	mv	a3,s4
    8000290c:	6605                	lui	a2,0x1
    8000290e:	75fd                	lui	a1,0xfffff
    80002910:	00b9f5b3          	and	a1,s3,a1
    80002914:	68a8                	ld	a0,80(s1)
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	7d0080e7          	jalr	2000(ra) # 800010e6 <mappages>
    8000291e:	d131                	beqz	a0,80002862 <usertrap+0x62>
           kfree((void*)ka);
    80002920:	8552                	mv	a0,s4
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	0f0080e7          	jalr	240(ra) # 80000a12 <kfree>
	   p->killed=1;
    8000292a:	4785                	li	a5,1
    8000292c:	d89c                	sw	a5,48(s1)
    8000292e:	b765                	j	800028d6 <usertrap+0xd6>
         p->killed=1;
    80002930:	4785                	li	a5,1
    80002932:	d89c                	sw	a5,48(s1)
	 printf("fail to allocate memory\n");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	97c50513          	addi	a0,a0,-1668 # 800082b0 <states.0+0x70>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c50080e7          	jalr	-944(ra) # 8000058c <printf>
    80002944:	bf39                	j	80002862 <usertrap+0x62>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002946:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000294a:	5c90                	lw	a2,56(s1)
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	98450513          	addi	a0,a0,-1660 # 800082d0 <states.0+0x90>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	c38080e7          	jalr	-968(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002960:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002964:	00006517          	auipc	a0,0x6
    80002968:	99c50513          	addi	a0,a0,-1636 # 80008300 <states.0+0xc0>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c20080e7          	jalr	-992(ra) # 8000058c <printf>
    p->killed = 1;
    80002974:	4785                	li	a5,1
    80002976:	d89c                	sw	a5,48(s1)
    80002978:	bfb9                	j	800028d6 <usertrap+0xd6>
  if(p->killed)
    8000297a:	589c                	lw	a5,48(s1)
    8000297c:	d3b5                	beqz	a5,800028e0 <usertrap+0xe0>
    8000297e:	bfa1                	j	800028d6 <usertrap+0xd6>
    80002980:	4901                	li	s2,0
    80002982:	bf91                	j	800028d6 <usertrap+0xd6>

0000000080002984 <kerneltrap>:
{
    80002984:	7179                	addi	sp,sp,-48
    80002986:	f406                	sd	ra,40(sp)
    80002988:	f022                	sd	s0,32(sp)
    8000298a:	ec26                	sd	s1,24(sp)
    8000298c:	e84a                	sd	s2,16(sp)
    8000298e:	e44e                	sd	s3,8(sp)
    80002990:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002992:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000299e:	1004f793          	andi	a5,s1,256
    800029a2:	cb85                	beqz	a5,800029d2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029a8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029aa:	ef85                	bnez	a5,800029e2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	db2080e7          	jalr	-590(ra) # 8000275e <devintr>
    800029b4:	cd1d                	beqz	a0,800029f2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b6:	4789                	li	a5,2
    800029b8:	06f50a63          	beq	a0,a5,80002a2c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029bc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c0:	10049073          	csrw	sstatus,s1
}
    800029c4:	70a2                	ld	ra,40(sp)
    800029c6:	7402                	ld	s0,32(sp)
    800029c8:	64e2                	ld	s1,24(sp)
    800029ca:	6942                	ld	s2,16(sp)
    800029cc:	69a2                	ld	s3,8(sp)
    800029ce:	6145                	addi	sp,sp,48
    800029d0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	94e50513          	addi	a0,a0,-1714 # 80008320 <states.0+0xe0>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	b68080e7          	jalr	-1176(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	96650513          	addi	a0,a0,-1690 # 80008348 <states.0+0x108>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b58080e7          	jalr	-1192(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    800029f2:	85ce                	mv	a1,s3
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	97450513          	addi	a0,a0,-1676 # 80008368 <states.0+0x128>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b90080e7          	jalr	-1136(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a08:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	96c50513          	addi	a0,a0,-1684 # 80008378 <states.0+0x138>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b78080e7          	jalr	-1160(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	97450513          	addi	a0,a0,-1676 # 80008390 <states.0+0x150>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b1e080e7          	jalr	-1250(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	fdc080e7          	jalr	-36(ra) # 80001a08 <myproc>
    80002a34:	d541                	beqz	a0,800029bc <kerneltrap+0x38>
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	fd2080e7          	jalr	-46(ra) # 80001a08 <myproc>
    80002a3e:	4d18                	lw	a4,24(a0)
    80002a40:	478d                	li	a5,3
    80002a42:	f6f71de3          	bne	a4,a5,800029bc <kerneltrap+0x38>
    yield();
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	79a080e7          	jalr	1946(ra) # 800021e0 <yield>
    80002a4e:	b7bd                	j	800029bc <kerneltrap+0x38>

0000000080002a50 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a50:	1101                	addi	sp,sp,-32
    80002a52:	ec06                	sd	ra,24(sp)
    80002a54:	e822                	sd	s0,16(sp)
    80002a56:	e426                	sd	s1,8(sp)
    80002a58:	1000                	addi	s0,sp,32
    80002a5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	fac080e7          	jalr	-84(ra) # 80001a08 <myproc>
  switch (n) {
    80002a64:	4795                	li	a5,5
    80002a66:	0497e163          	bltu	a5,s1,80002aa8 <argraw+0x58>
    80002a6a:	048a                	slli	s1,s1,0x2
    80002a6c:	00006717          	auipc	a4,0x6
    80002a70:	95c70713          	addi	a4,a4,-1700 # 800083c8 <states.0+0x188>
    80002a74:	94ba                	add	s1,s1,a4
    80002a76:	409c                	lw	a5,0(s1)
    80002a78:	97ba                	add	a5,a5,a4
    80002a7a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a7c:	6d3c                	ld	a5,88(a0)
    80002a7e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6105                	addi	sp,sp,32
    80002a88:	8082                	ret
    return p->trapframe->a1;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	7fa8                	ld	a0,120(a5)
    80002a8e:	bfcd                	j	80002a80 <argraw+0x30>
    return p->trapframe->a2;
    80002a90:	6d3c                	ld	a5,88(a0)
    80002a92:	63c8                	ld	a0,128(a5)
    80002a94:	b7f5                	j	80002a80 <argraw+0x30>
    return p->trapframe->a3;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	67c8                	ld	a0,136(a5)
    80002a9a:	b7dd                	j	80002a80 <argraw+0x30>
    return p->trapframe->a4;
    80002a9c:	6d3c                	ld	a5,88(a0)
    80002a9e:	6bc8                	ld	a0,144(a5)
    80002aa0:	b7c5                	j	80002a80 <argraw+0x30>
    return p->trapframe->a5;
    80002aa2:	6d3c                	ld	a5,88(a0)
    80002aa4:	6fc8                	ld	a0,152(a5)
    80002aa6:	bfe9                	j	80002a80 <argraw+0x30>
  panic("argraw");
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	8f850513          	addi	a0,a0,-1800 # 800083a0 <states.0+0x160>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	a92080e7          	jalr	-1390(ra) # 80000542 <panic>

0000000080002ab8 <fetchaddr>:
{
    80002ab8:	1101                	addi	sp,sp,-32
    80002aba:	ec06                	sd	ra,24(sp)
    80002abc:	e822                	sd	s0,16(sp)
    80002abe:	e426                	sd	s1,8(sp)
    80002ac0:	e04a                	sd	s2,0(sp)
    80002ac2:	1000                	addi	s0,sp,32
    80002ac4:	84aa                	mv	s1,a0
    80002ac6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	f40080e7          	jalr	-192(ra) # 80001a08 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ad0:	653c                	ld	a5,72(a0)
    80002ad2:	02f4f863          	bgeu	s1,a5,80002b02 <fetchaddr+0x4a>
    80002ad6:	00848713          	addi	a4,s1,8
    80002ada:	02e7e663          	bltu	a5,a4,80002b06 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ade:	46a1                	li	a3,8
    80002ae0:	8626                	mv	a2,s1
    80002ae2:	85ca                	mv	a1,s2
    80002ae4:	6928                	ld	a0,80(a0)
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	ca0080e7          	jalr	-864(ra) # 80001786 <copyin>
    80002aee:	00a03533          	snez	a0,a0
    80002af2:	40a00533          	neg	a0,a0
}
    80002af6:	60e2                	ld	ra,24(sp)
    80002af8:	6442                	ld	s0,16(sp)
    80002afa:	64a2                	ld	s1,8(sp)
    80002afc:	6902                	ld	s2,0(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret
    return -1;
    80002b02:	557d                	li	a0,-1
    80002b04:	bfcd                	j	80002af6 <fetchaddr+0x3e>
    80002b06:	557d                	li	a0,-1
    80002b08:	b7fd                	j	80002af6 <fetchaddr+0x3e>

0000000080002b0a <fetchstr>:
{
    80002b0a:	7179                	addi	sp,sp,-48
    80002b0c:	f406                	sd	ra,40(sp)
    80002b0e:	f022                	sd	s0,32(sp)
    80002b10:	ec26                	sd	s1,24(sp)
    80002b12:	e84a                	sd	s2,16(sp)
    80002b14:	e44e                	sd	s3,8(sp)
    80002b16:	1800                	addi	s0,sp,48
    80002b18:	892a                	mv	s2,a0
    80002b1a:	84ae                	mv	s1,a1
    80002b1c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	eea080e7          	jalr	-278(ra) # 80001a08 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b26:	86ce                	mv	a3,s3
    80002b28:	864a                	mv	a2,s2
    80002b2a:	85a6                	mv	a1,s1
    80002b2c:	6928                	ld	a0,80(a0)
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	ce6080e7          	jalr	-794(ra) # 80001814 <copyinstr>
  if(err < 0)
    80002b36:	00054763          	bltz	a0,80002b44 <fetchstr+0x3a>
  return strlen(buf);
    80002b3a:	8526                	mv	a0,s1
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	342080e7          	jalr	834(ra) # 80000e7e <strlen>
}
    80002b44:	70a2                	ld	ra,40(sp)
    80002b46:	7402                	ld	s0,32(sp)
    80002b48:	64e2                	ld	s1,24(sp)
    80002b4a:	6942                	ld	s2,16(sp)
    80002b4c:	69a2                	ld	s3,8(sp)
    80002b4e:	6145                	addi	sp,sp,48
    80002b50:	8082                	ret

0000000080002b52 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b52:	1101                	addi	sp,sp,-32
    80002b54:	ec06                	sd	ra,24(sp)
    80002b56:	e822                	sd	s0,16(sp)
    80002b58:	e426                	sd	s1,8(sp)
    80002b5a:	1000                	addi	s0,sp,32
    80002b5c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b5e:	00000097          	auipc	ra,0x0
    80002b62:	ef2080e7          	jalr	-270(ra) # 80002a50 <argraw>
    80002b66:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b68:	4501                	li	a0,0
    80002b6a:	60e2                	ld	ra,24(sp)
    80002b6c:	6442                	ld	s0,16(sp)
    80002b6e:	64a2                	ld	s1,8(sp)
    80002b70:	6105                	addi	sp,sp,32
    80002b72:	8082                	ret

0000000080002b74 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b74:	1101                	addi	sp,sp,-32
    80002b76:	ec06                	sd	ra,24(sp)
    80002b78:	e822                	sd	s0,16(sp)
    80002b7a:	e426                	sd	s1,8(sp)
    80002b7c:	1000                	addi	s0,sp,32
    80002b7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	ed0080e7          	jalr	-304(ra) # 80002a50 <argraw>
    80002b88:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b8a:	4501                	li	a0,0
    80002b8c:	60e2                	ld	ra,24(sp)
    80002b8e:	6442                	ld	s0,16(sp)
    80002b90:	64a2                	ld	s1,8(sp)
    80002b92:	6105                	addi	sp,sp,32
    80002b94:	8082                	ret

0000000080002b96 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b96:	1101                	addi	sp,sp,-32
    80002b98:	ec06                	sd	ra,24(sp)
    80002b9a:	e822                	sd	s0,16(sp)
    80002b9c:	e426                	sd	s1,8(sp)
    80002b9e:	e04a                	sd	s2,0(sp)
    80002ba0:	1000                	addi	s0,sp,32
    80002ba2:	84ae                	mv	s1,a1
    80002ba4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	eaa080e7          	jalr	-342(ra) # 80002a50 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bae:	864a                	mv	a2,s2
    80002bb0:	85a6                	mv	a1,s1
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	f58080e7          	jalr	-168(ra) # 80002b0a <fetchstr>
}
    80002bba:	60e2                	ld	ra,24(sp)
    80002bbc:	6442                	ld	s0,16(sp)
    80002bbe:	64a2                	ld	s1,8(sp)
    80002bc0:	6902                	ld	s2,0(sp)
    80002bc2:	6105                	addi	sp,sp,32
    80002bc4:	8082                	ret

0000000080002bc6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	e04a                	sd	s2,0(sp)
    80002bd0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	e36080e7          	jalr	-458(ra) # 80001a08 <myproc>
    80002bda:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bdc:	05853903          	ld	s2,88(a0)
    80002be0:	0a893783          	ld	a5,168(s2)
    80002be4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002be8:	37fd                	addiw	a5,a5,-1
    80002bea:	4751                	li	a4,20
    80002bec:	00f76f63          	bltu	a4,a5,80002c0a <syscall+0x44>
    80002bf0:	00369713          	slli	a4,a3,0x3
    80002bf4:	00005797          	auipc	a5,0x5
    80002bf8:	7ec78793          	addi	a5,a5,2028 # 800083e0 <syscalls>
    80002bfc:	97ba                	add	a5,a5,a4
    80002bfe:	639c                	ld	a5,0(a5)
    80002c00:	c789                	beqz	a5,80002c0a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c02:	9782                	jalr	a5
    80002c04:	06a93823          	sd	a0,112(s2)
    80002c08:	a839                	j	80002c26 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c0a:	15848613          	addi	a2,s1,344
    80002c0e:	5c8c                	lw	a1,56(s1)
    80002c10:	00005517          	auipc	a0,0x5
    80002c14:	79850513          	addi	a0,a0,1944 # 800083a8 <states.0+0x168>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	974080e7          	jalr	-1676(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c20:	6cbc                	ld	a5,88(s1)
    80002c22:	577d                	li	a4,-1
    80002c24:	fbb8                	sd	a4,112(a5)
  }
}
    80002c26:	60e2                	ld	ra,24(sp)
    80002c28:	6442                	ld	s0,16(sp)
    80002c2a:	64a2                	ld	s1,8(sp)
    80002c2c:	6902                	ld	s2,0(sp)
    80002c2e:	6105                	addi	sp,sp,32
    80002c30:	8082                	ret

0000000080002c32 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c32:	1101                	addi	sp,sp,-32
    80002c34:	ec06                	sd	ra,24(sp)
    80002c36:	e822                	sd	s0,16(sp)
    80002c38:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c3a:	fec40593          	addi	a1,s0,-20
    80002c3e:	4501                	li	a0,0
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	f12080e7          	jalr	-238(ra) # 80002b52 <argint>
    return -1;
    80002c48:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c4a:	00054963          	bltz	a0,80002c5c <sys_exit+0x2a>
  exit(n);
    80002c4e:	fec42503          	lw	a0,-20(s0)
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	484080e7          	jalr	1156(ra) # 800020d6 <exit>
  return 0;  // not reached
    80002c5a:	4781                	li	a5,0
}
    80002c5c:	853e                	mv	a0,a5
    80002c5e:	60e2                	ld	ra,24(sp)
    80002c60:	6442                	ld	s0,16(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret

0000000080002c66 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c66:	1141                	addi	sp,sp,-16
    80002c68:	e406                	sd	ra,8(sp)
    80002c6a:	e022                	sd	s0,0(sp)
    80002c6c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	d9a080e7          	jalr	-614(ra) # 80001a08 <myproc>
}
    80002c76:	5d08                	lw	a0,56(a0)
    80002c78:	60a2                	ld	ra,8(sp)
    80002c7a:	6402                	ld	s0,0(sp)
    80002c7c:	0141                	addi	sp,sp,16
    80002c7e:	8082                	ret

0000000080002c80 <sys_fork>:

uint64
sys_fork(void)
{
    80002c80:	1141                	addi	sp,sp,-16
    80002c82:	e406                	sd	ra,8(sp)
    80002c84:	e022                	sd	s0,0(sp)
    80002c86:	0800                	addi	s0,sp,16
  return fork();
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	140080e7          	jalr	320(ra) # 80001dc8 <fork>
}
    80002c90:	60a2                	ld	ra,8(sp)
    80002c92:	6402                	ld	s0,0(sp)
    80002c94:	0141                	addi	sp,sp,16
    80002c96:	8082                	ret

0000000080002c98 <sys_wait>:

uint64
sys_wait(void)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ca0:	fe840593          	addi	a1,s0,-24
    80002ca4:	4501                	li	a0,0
    80002ca6:	00000097          	auipc	ra,0x0
    80002caa:	ece080e7          	jalr	-306(ra) # 80002b74 <argaddr>
    80002cae:	87aa                	mv	a5,a0
    return -1;
    80002cb0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cb2:	0007c863          	bltz	a5,80002cc2 <sys_wait+0x2a>
  return wait(p);
    80002cb6:	fe843503          	ld	a0,-24(s0)
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	5e0080e7          	jalr	1504(ra) # 8000229a <wait>
}
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret

0000000080002cca <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cca:	7139                	addi	sp,sp,-64
    80002ccc:	fc06                	sd	ra,56(sp)
    80002cce:	f822                	sd	s0,48(sp)
    80002cd0:	f426                	sd	s1,40(sp)
    80002cd2:	f04a                	sd	s2,32(sp)
    80002cd4:	ec4e                	sd	s3,24(sp)
    80002cd6:	0080                	addi	s0,sp,64
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cd8:	fcc40593          	addi	a1,s0,-52
    80002cdc:	4501                	li	a0,0
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	e74080e7          	jalr	-396(ra) # 80002b52 <argint>
    return -1;
    80002ce6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ce8:	06054463          	bltz	a0,80002d50 <sys_sbrk+0x86>
  addr = myproc()->sz;
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	d1c080e7          	jalr	-740(ra) # 80001a08 <myproc>
    80002cf4:	4524                	lw	s1,72(a0)
  //if(growproc(n) < 0)
    //return -1;
  if(n>=0)
    80002cf6:	fcc42783          	lw	a5,-52(s0)
    80002cfa:	0607d363          	bgez	a5,80002d60 <sys_sbrk+0x96>
  myproc()->sz+=n;
  else
  {
    if(addr+n<0)
    80002cfe:	0097873b          	addw	a4,a5,s1
    return -1;
    80002d02:	57fd                	li	a5,-1
    if(addr+n<0)
    80002d04:	04074663          	bltz	a4,80002d50 <sys_sbrk+0x86>
    else
    {
      uvmdealloc(myproc()->pagetable,myproc()->sz,myproc()->sz+n);
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	d00080e7          	jalr	-768(ra) # 80001a08 <myproc>
    80002d10:	05053903          	ld	s2,80(a0)
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	cf4080e7          	jalr	-780(ra) # 80001a08 <myproc>
    80002d1c:	04853983          	ld	s3,72(a0)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	ce8080e7          	jalr	-792(ra) # 80001a08 <myproc>
    80002d28:	fcc42603          	lw	a2,-52(s0)
    80002d2c:	653c                	ld	a5,72(a0)
    80002d2e:	963e                	add	a2,a2,a5
    80002d30:	85ce                	mv	a1,s3
    80002d32:	854a                	mv	a0,s2
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	74a080e7          	jalr	1866(ra) # 8000147e <uvmdealloc>
      myproc()->sz+=n;
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	ccc080e7          	jalr	-820(ra) # 80001a08 <myproc>
    80002d44:	fcc42703          	lw	a4,-52(s0)
    80002d48:	653c                	ld	a5,72(a0)
    80002d4a:	97ba                	add	a5,a5,a4
    80002d4c:	e53c                	sd	a5,72(a0)
    }    
  }
  return addr;
    80002d4e:	87a6                	mv	a5,s1
}
    80002d50:	853e                	mv	a0,a5
    80002d52:	70e2                	ld	ra,56(sp)
    80002d54:	7442                	ld	s0,48(sp)
    80002d56:	74a2                	ld	s1,40(sp)
    80002d58:	7902                	ld	s2,32(sp)
    80002d5a:	69e2                	ld	s3,24(sp)
    80002d5c:	6121                	addi	sp,sp,64
    80002d5e:	8082                	ret
  myproc()->sz+=n;
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	ca8080e7          	jalr	-856(ra) # 80001a08 <myproc>
    80002d68:	fcc42703          	lw	a4,-52(s0)
    80002d6c:	653c                	ld	a5,72(a0)
    80002d6e:	97ba                	add	a5,a5,a4
    80002d70:	e53c                	sd	a5,72(a0)
    80002d72:	bff1                	j	80002d4e <sys_sbrk+0x84>

0000000080002d74 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d74:	7139                	addi	sp,sp,-64
    80002d76:	fc06                	sd	ra,56(sp)
    80002d78:	f822                	sd	s0,48(sp)
    80002d7a:	f426                	sd	s1,40(sp)
    80002d7c:	f04a                	sd	s2,32(sp)
    80002d7e:	ec4e                	sd	s3,24(sp)
    80002d80:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d82:	fcc40593          	addi	a1,s0,-52
    80002d86:	4501                	li	a0,0
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	dca080e7          	jalr	-566(ra) # 80002b52 <argint>
    return -1;
    80002d90:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d92:	06054563          	bltz	a0,80002dfc <sys_sleep+0x88>
  acquire(&tickslock);
    80002d96:	00015517          	auipc	a0,0x15
    80002d9a:	9d250513          	addi	a0,a0,-1582 # 80017768 <tickslock>
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	e60080e7          	jalr	-416(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80002da6:	00006917          	auipc	s2,0x6
    80002daa:	27a92903          	lw	s2,634(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002dae:	fcc42783          	lw	a5,-52(s0)
    80002db2:	cf85                	beqz	a5,80002dea <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db4:	00015997          	auipc	s3,0x15
    80002db8:	9b498993          	addi	s3,s3,-1612 # 80017768 <tickslock>
    80002dbc:	00006497          	auipc	s1,0x6
    80002dc0:	26448493          	addi	s1,s1,612 # 80009020 <ticks>
    if(myproc()->killed){
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	c44080e7          	jalr	-956(ra) # 80001a08 <myproc>
    80002dcc:	591c                	lw	a5,48(a0)
    80002dce:	ef9d                	bnez	a5,80002e0c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dd0:	85ce                	mv	a1,s3
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	448080e7          	jalr	1096(ra) # 8000221c <sleep>
  while(ticks - ticks0 < n){
    80002ddc:	409c                	lw	a5,0(s1)
    80002dde:	412787bb          	subw	a5,a5,s2
    80002de2:	fcc42703          	lw	a4,-52(s0)
    80002de6:	fce7efe3          	bltu	a5,a4,80002dc4 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dea:	00015517          	auipc	a0,0x15
    80002dee:	97e50513          	addi	a0,a0,-1666 # 80017768 <tickslock>
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	ec0080e7          	jalr	-320(ra) # 80000cb2 <release>
  return 0;
    80002dfa:	4781                	li	a5,0
}
    80002dfc:	853e                	mv	a0,a5
    80002dfe:	70e2                	ld	ra,56(sp)
    80002e00:	7442                	ld	s0,48(sp)
    80002e02:	74a2                	ld	s1,40(sp)
    80002e04:	7902                	ld	s2,32(sp)
    80002e06:	69e2                	ld	s3,24(sp)
    80002e08:	6121                	addi	sp,sp,64
    80002e0a:	8082                	ret
      release(&tickslock);
    80002e0c:	00015517          	auipc	a0,0x15
    80002e10:	95c50513          	addi	a0,a0,-1700 # 80017768 <tickslock>
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	e9e080e7          	jalr	-354(ra) # 80000cb2 <release>
      return -1;
    80002e1c:	57fd                	li	a5,-1
    80002e1e:	bff9                	j	80002dfc <sys_sleep+0x88>

0000000080002e20 <sys_kill>:

uint64
sys_kill(void)
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e28:	fec40593          	addi	a1,s0,-20
    80002e2c:	4501                	li	a0,0
    80002e2e:	00000097          	auipc	ra,0x0
    80002e32:	d24080e7          	jalr	-732(ra) # 80002b52 <argint>
    80002e36:	87aa                	mv	a5,a0
    return -1;
    80002e38:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e3a:	0007c863          	bltz	a5,80002e4a <sys_kill+0x2a>
  return kill(pid);
    80002e3e:	fec42503          	lw	a0,-20(s0)
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	5c4080e7          	jalr	1476(ra) # 80002406 <kill>
}
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	6105                	addi	sp,sp,32
    80002e50:	8082                	ret

0000000080002e52 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e52:	1101                	addi	sp,sp,-32
    80002e54:	ec06                	sd	ra,24(sp)
    80002e56:	e822                	sd	s0,16(sp)
    80002e58:	e426                	sd	s1,8(sp)
    80002e5a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e5c:	00015517          	auipc	a0,0x15
    80002e60:	90c50513          	addi	a0,a0,-1780 # 80017768 <tickslock>
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	d9a080e7          	jalr	-614(ra) # 80000bfe <acquire>
  xticks = ticks;
    80002e6c:	00006497          	auipc	s1,0x6
    80002e70:	1b44a483          	lw	s1,436(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e74:	00015517          	auipc	a0,0x15
    80002e78:	8f450513          	addi	a0,a0,-1804 # 80017768 <tickslock>
    80002e7c:	ffffe097          	auipc	ra,0xffffe
    80002e80:	e36080e7          	jalr	-458(ra) # 80000cb2 <release>
  return xticks;
}
    80002e84:	02049513          	slli	a0,s1,0x20
    80002e88:	9101                	srli	a0,a0,0x20
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e94:	7179                	addi	sp,sp,-48
    80002e96:	f406                	sd	ra,40(sp)
    80002e98:	f022                	sd	s0,32(sp)
    80002e9a:	ec26                	sd	s1,24(sp)
    80002e9c:	e84a                	sd	s2,16(sp)
    80002e9e:	e44e                	sd	s3,8(sp)
    80002ea0:	e052                	sd	s4,0(sp)
    80002ea2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ea4:	00005597          	auipc	a1,0x5
    80002ea8:	5ec58593          	addi	a1,a1,1516 # 80008490 <syscalls+0xb0>
    80002eac:	00015517          	auipc	a0,0x15
    80002eb0:	8d450513          	addi	a0,a0,-1836 # 80017780 <bcache>
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	cba080e7          	jalr	-838(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ebc:	0001d797          	auipc	a5,0x1d
    80002ec0:	8c478793          	addi	a5,a5,-1852 # 8001f780 <bcache+0x8000>
    80002ec4:	0001d717          	auipc	a4,0x1d
    80002ec8:	b2470713          	addi	a4,a4,-1244 # 8001f9e8 <bcache+0x8268>
    80002ecc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ed0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed4:	00015497          	auipc	s1,0x15
    80002ed8:	8c448493          	addi	s1,s1,-1852 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002edc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ede:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ee0:	00005a17          	auipc	s4,0x5
    80002ee4:	5b8a0a13          	addi	s4,s4,1464 # 80008498 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ee8:	2b893783          	ld	a5,696(s2)
    80002eec:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eee:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ef2:	85d2                	mv	a1,s4
    80002ef4:	01048513          	addi	a0,s1,16
    80002ef8:	00001097          	auipc	ra,0x1
    80002efc:	4b0080e7          	jalr	1200(ra) # 800043a8 <initsleeplock>
    bcache.head.next->prev = b;
    80002f00:	2b893783          	ld	a5,696(s2)
    80002f04:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f06:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f0a:	45848493          	addi	s1,s1,1112
    80002f0e:	fd349de3          	bne	s1,s3,80002ee8 <binit+0x54>
  }
}
    80002f12:	70a2                	ld	ra,40(sp)
    80002f14:	7402                	ld	s0,32(sp)
    80002f16:	64e2                	ld	s1,24(sp)
    80002f18:	6942                	ld	s2,16(sp)
    80002f1a:	69a2                	ld	s3,8(sp)
    80002f1c:	6a02                	ld	s4,0(sp)
    80002f1e:	6145                	addi	sp,sp,48
    80002f20:	8082                	ret

0000000080002f22 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f22:	7179                	addi	sp,sp,-48
    80002f24:	f406                	sd	ra,40(sp)
    80002f26:	f022                	sd	s0,32(sp)
    80002f28:	ec26                	sd	s1,24(sp)
    80002f2a:	e84a                	sd	s2,16(sp)
    80002f2c:	e44e                	sd	s3,8(sp)
    80002f2e:	1800                	addi	s0,sp,48
    80002f30:	892a                	mv	s2,a0
    80002f32:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f34:	00015517          	auipc	a0,0x15
    80002f38:	84c50513          	addi	a0,a0,-1972 # 80017780 <bcache>
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	cc2080e7          	jalr	-830(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f44:	0001d497          	auipc	s1,0x1d
    80002f48:	af44b483          	ld	s1,-1292(s1) # 8001fa38 <bcache+0x82b8>
    80002f4c:	0001d797          	auipc	a5,0x1d
    80002f50:	a9c78793          	addi	a5,a5,-1380 # 8001f9e8 <bcache+0x8268>
    80002f54:	02f48f63          	beq	s1,a5,80002f92 <bread+0x70>
    80002f58:	873e                	mv	a4,a5
    80002f5a:	a021                	j	80002f62 <bread+0x40>
    80002f5c:	68a4                	ld	s1,80(s1)
    80002f5e:	02e48a63          	beq	s1,a4,80002f92 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f62:	449c                	lw	a5,8(s1)
    80002f64:	ff279ce3          	bne	a5,s2,80002f5c <bread+0x3a>
    80002f68:	44dc                	lw	a5,12(s1)
    80002f6a:	ff3799e3          	bne	a5,s3,80002f5c <bread+0x3a>
      b->refcnt++;
    80002f6e:	40bc                	lw	a5,64(s1)
    80002f70:	2785                	addiw	a5,a5,1
    80002f72:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f74:	00015517          	auipc	a0,0x15
    80002f78:	80c50513          	addi	a0,a0,-2036 # 80017780 <bcache>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	d36080e7          	jalr	-714(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002f84:	01048513          	addi	a0,s1,16
    80002f88:	00001097          	auipc	ra,0x1
    80002f8c:	45a080e7          	jalr	1114(ra) # 800043e2 <acquiresleep>
      return b;
    80002f90:	a8b9                	j	80002fee <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f92:	0001d497          	auipc	s1,0x1d
    80002f96:	a9e4b483          	ld	s1,-1378(s1) # 8001fa30 <bcache+0x82b0>
    80002f9a:	0001d797          	auipc	a5,0x1d
    80002f9e:	a4e78793          	addi	a5,a5,-1458 # 8001f9e8 <bcache+0x8268>
    80002fa2:	00f48863          	beq	s1,a5,80002fb2 <bread+0x90>
    80002fa6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fa8:	40bc                	lw	a5,64(s1)
    80002faa:	cf81                	beqz	a5,80002fc2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fac:	64a4                	ld	s1,72(s1)
    80002fae:	fee49de3          	bne	s1,a4,80002fa8 <bread+0x86>
  panic("bget: no buffers");
    80002fb2:	00005517          	auipc	a0,0x5
    80002fb6:	4ee50513          	addi	a0,a0,1262 # 800084a0 <syscalls+0xc0>
    80002fba:	ffffd097          	auipc	ra,0xffffd
    80002fbe:	588080e7          	jalr	1416(ra) # 80000542 <panic>
      b->dev = dev;
    80002fc2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fc6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fca:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fce:	4785                	li	a5,1
    80002fd0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fd2:	00014517          	auipc	a0,0x14
    80002fd6:	7ae50513          	addi	a0,a0,1966 # 80017780 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	cd8080e7          	jalr	-808(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002fe2:	01048513          	addi	a0,s1,16
    80002fe6:	00001097          	auipc	ra,0x1
    80002fea:	3fc080e7          	jalr	1020(ra) # 800043e2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fee:	409c                	lw	a5,0(s1)
    80002ff0:	cb89                	beqz	a5,80003002 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ff2:	8526                	mv	a0,s1
    80002ff4:	70a2                	ld	ra,40(sp)
    80002ff6:	7402                	ld	s0,32(sp)
    80002ff8:	64e2                	ld	s1,24(sp)
    80002ffa:	6942                	ld	s2,16(sp)
    80002ffc:	69a2                	ld	s3,8(sp)
    80002ffe:	6145                	addi	sp,sp,48
    80003000:	8082                	ret
    virtio_disk_rw(b, 0);
    80003002:	4581                	li	a1,0
    80003004:	8526                	mv	a0,s1
    80003006:	00003097          	auipc	ra,0x3
    8000300a:	f26080e7          	jalr	-218(ra) # 80005f2c <virtio_disk_rw>
    b->valid = 1;
    8000300e:	4785                	li	a5,1
    80003010:	c09c                	sw	a5,0(s1)
  return b;
    80003012:	b7c5                	j	80002ff2 <bread+0xd0>

0000000080003014 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003014:	1101                	addi	sp,sp,-32
    80003016:	ec06                	sd	ra,24(sp)
    80003018:	e822                	sd	s0,16(sp)
    8000301a:	e426                	sd	s1,8(sp)
    8000301c:	1000                	addi	s0,sp,32
    8000301e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003020:	0541                	addi	a0,a0,16
    80003022:	00001097          	auipc	ra,0x1
    80003026:	45a080e7          	jalr	1114(ra) # 8000447c <holdingsleep>
    8000302a:	cd01                	beqz	a0,80003042 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000302c:	4585                	li	a1,1
    8000302e:	8526                	mv	a0,s1
    80003030:	00003097          	auipc	ra,0x3
    80003034:	efc080e7          	jalr	-260(ra) # 80005f2c <virtio_disk_rw>
}
    80003038:	60e2                	ld	ra,24(sp)
    8000303a:	6442                	ld	s0,16(sp)
    8000303c:	64a2                	ld	s1,8(sp)
    8000303e:	6105                	addi	sp,sp,32
    80003040:	8082                	ret
    panic("bwrite");
    80003042:	00005517          	auipc	a0,0x5
    80003046:	47650513          	addi	a0,a0,1142 # 800084b8 <syscalls+0xd8>
    8000304a:	ffffd097          	auipc	ra,0xffffd
    8000304e:	4f8080e7          	jalr	1272(ra) # 80000542 <panic>

0000000080003052 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	e04a                	sd	s2,0(sp)
    8000305c:	1000                	addi	s0,sp,32
    8000305e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003060:	01050913          	addi	s2,a0,16
    80003064:	854a                	mv	a0,s2
    80003066:	00001097          	auipc	ra,0x1
    8000306a:	416080e7          	jalr	1046(ra) # 8000447c <holdingsleep>
    8000306e:	c92d                	beqz	a0,800030e0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003070:	854a                	mv	a0,s2
    80003072:	00001097          	auipc	ra,0x1
    80003076:	3c6080e7          	jalr	966(ra) # 80004438 <releasesleep>

  acquire(&bcache.lock);
    8000307a:	00014517          	auipc	a0,0x14
    8000307e:	70650513          	addi	a0,a0,1798 # 80017780 <bcache>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	b7c080e7          	jalr	-1156(ra) # 80000bfe <acquire>
  b->refcnt--;
    8000308a:	40bc                	lw	a5,64(s1)
    8000308c:	37fd                	addiw	a5,a5,-1
    8000308e:	0007871b          	sext.w	a4,a5
    80003092:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003094:	eb05                	bnez	a4,800030c4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003096:	68bc                	ld	a5,80(s1)
    80003098:	64b8                	ld	a4,72(s1)
    8000309a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000309c:	64bc                	ld	a5,72(s1)
    8000309e:	68b8                	ld	a4,80(s1)
    800030a0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030a2:	0001c797          	auipc	a5,0x1c
    800030a6:	6de78793          	addi	a5,a5,1758 # 8001f780 <bcache+0x8000>
    800030aa:	2b87b703          	ld	a4,696(a5)
    800030ae:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030b0:	0001d717          	auipc	a4,0x1d
    800030b4:	93870713          	addi	a4,a4,-1736 # 8001f9e8 <bcache+0x8268>
    800030b8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ba:	2b87b703          	ld	a4,696(a5)
    800030be:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030c0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030c4:	00014517          	auipc	a0,0x14
    800030c8:	6bc50513          	addi	a0,a0,1724 # 80017780 <bcache>
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	be6080e7          	jalr	-1050(ra) # 80000cb2 <release>
}
    800030d4:	60e2                	ld	ra,24(sp)
    800030d6:	6442                	ld	s0,16(sp)
    800030d8:	64a2                	ld	s1,8(sp)
    800030da:	6902                	ld	s2,0(sp)
    800030dc:	6105                	addi	sp,sp,32
    800030de:	8082                	ret
    panic("brelse");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	3e050513          	addi	a0,a0,992 # 800084c0 <syscalls+0xe0>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	45a080e7          	jalr	1114(ra) # 80000542 <panic>

00000000800030f0 <bpin>:

void
bpin(struct buf *b) {
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	1000                	addi	s0,sp,32
    800030fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030fc:	00014517          	auipc	a0,0x14
    80003100:	68450513          	addi	a0,a0,1668 # 80017780 <bcache>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	afa080e7          	jalr	-1286(ra) # 80000bfe <acquire>
  b->refcnt++;
    8000310c:	40bc                	lw	a5,64(s1)
    8000310e:	2785                	addiw	a5,a5,1
    80003110:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003112:	00014517          	auipc	a0,0x14
    80003116:	66e50513          	addi	a0,a0,1646 # 80017780 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	b98080e7          	jalr	-1128(ra) # 80000cb2 <release>
}
    80003122:	60e2                	ld	ra,24(sp)
    80003124:	6442                	ld	s0,16(sp)
    80003126:	64a2                	ld	s1,8(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret

000000008000312c <bunpin>:

void
bunpin(struct buf *b) {
    8000312c:	1101                	addi	sp,sp,-32
    8000312e:	ec06                	sd	ra,24(sp)
    80003130:	e822                	sd	s0,16(sp)
    80003132:	e426                	sd	s1,8(sp)
    80003134:	1000                	addi	s0,sp,32
    80003136:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003138:	00014517          	auipc	a0,0x14
    8000313c:	64850513          	addi	a0,a0,1608 # 80017780 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	abe080e7          	jalr	-1346(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003148:	40bc                	lw	a5,64(s1)
    8000314a:	37fd                	addiw	a5,a5,-1
    8000314c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000314e:	00014517          	auipc	a0,0x14
    80003152:	63250513          	addi	a0,a0,1586 # 80017780 <bcache>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	b5c080e7          	jalr	-1188(ra) # 80000cb2 <release>
}
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	64a2                	ld	s1,8(sp)
    80003164:	6105                	addi	sp,sp,32
    80003166:	8082                	ret

0000000080003168 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003168:	1101                	addi	sp,sp,-32
    8000316a:	ec06                	sd	ra,24(sp)
    8000316c:	e822                	sd	s0,16(sp)
    8000316e:	e426                	sd	s1,8(sp)
    80003170:	e04a                	sd	s2,0(sp)
    80003172:	1000                	addi	s0,sp,32
    80003174:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003176:	00d5d59b          	srliw	a1,a1,0xd
    8000317a:	0001d797          	auipc	a5,0x1d
    8000317e:	ce27a783          	lw	a5,-798(a5) # 8001fe5c <sb+0x1c>
    80003182:	9dbd                	addw	a1,a1,a5
    80003184:	00000097          	auipc	ra,0x0
    80003188:	d9e080e7          	jalr	-610(ra) # 80002f22 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000318c:	0074f713          	andi	a4,s1,7
    80003190:	4785                	li	a5,1
    80003192:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003196:	14ce                	slli	s1,s1,0x33
    80003198:	90d9                	srli	s1,s1,0x36
    8000319a:	00950733          	add	a4,a0,s1
    8000319e:	05874703          	lbu	a4,88(a4)
    800031a2:	00e7f6b3          	and	a3,a5,a4
    800031a6:	c69d                	beqz	a3,800031d4 <bfree+0x6c>
    800031a8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031aa:	94aa                	add	s1,s1,a0
    800031ac:	fff7c793          	not	a5,a5
    800031b0:	8ff9                	and	a5,a5,a4
    800031b2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031b6:	00001097          	auipc	ra,0x1
    800031ba:	104080e7          	jalr	260(ra) # 800042ba <log_write>
  brelse(bp);
    800031be:	854a                	mv	a0,s2
    800031c0:	00000097          	auipc	ra,0x0
    800031c4:	e92080e7          	jalr	-366(ra) # 80003052 <brelse>
}
    800031c8:	60e2                	ld	ra,24(sp)
    800031ca:	6442                	ld	s0,16(sp)
    800031cc:	64a2                	ld	s1,8(sp)
    800031ce:	6902                	ld	s2,0(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret
    panic("freeing free block");
    800031d4:	00005517          	auipc	a0,0x5
    800031d8:	2f450513          	addi	a0,a0,756 # 800084c8 <syscalls+0xe8>
    800031dc:	ffffd097          	auipc	ra,0xffffd
    800031e0:	366080e7          	jalr	870(ra) # 80000542 <panic>

00000000800031e4 <balloc>:
{
    800031e4:	711d                	addi	sp,sp,-96
    800031e6:	ec86                	sd	ra,88(sp)
    800031e8:	e8a2                	sd	s0,80(sp)
    800031ea:	e4a6                	sd	s1,72(sp)
    800031ec:	e0ca                	sd	s2,64(sp)
    800031ee:	fc4e                	sd	s3,56(sp)
    800031f0:	f852                	sd	s4,48(sp)
    800031f2:	f456                	sd	s5,40(sp)
    800031f4:	f05a                	sd	s6,32(sp)
    800031f6:	ec5e                	sd	s7,24(sp)
    800031f8:	e862                	sd	s8,16(sp)
    800031fa:	e466                	sd	s9,8(sp)
    800031fc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031fe:	0001d797          	auipc	a5,0x1d
    80003202:	c467a783          	lw	a5,-954(a5) # 8001fe44 <sb+0x4>
    80003206:	cbd1                	beqz	a5,8000329a <balloc+0xb6>
    80003208:	8baa                	mv	s7,a0
    8000320a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000320c:	0001db17          	auipc	s6,0x1d
    80003210:	c34b0b13          	addi	s6,s6,-972 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003214:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003216:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003218:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000321a:	6c89                	lui	s9,0x2
    8000321c:	a831                	j	80003238 <balloc+0x54>
    brelse(bp);
    8000321e:	854a                	mv	a0,s2
    80003220:	00000097          	auipc	ra,0x0
    80003224:	e32080e7          	jalr	-462(ra) # 80003052 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003228:	015c87bb          	addw	a5,s9,s5
    8000322c:	00078a9b          	sext.w	s5,a5
    80003230:	004b2703          	lw	a4,4(s6)
    80003234:	06eaf363          	bgeu	s5,a4,8000329a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003238:	41fad79b          	sraiw	a5,s5,0x1f
    8000323c:	0137d79b          	srliw	a5,a5,0x13
    80003240:	015787bb          	addw	a5,a5,s5
    80003244:	40d7d79b          	sraiw	a5,a5,0xd
    80003248:	01cb2583          	lw	a1,28(s6)
    8000324c:	9dbd                	addw	a1,a1,a5
    8000324e:	855e                	mv	a0,s7
    80003250:	00000097          	auipc	ra,0x0
    80003254:	cd2080e7          	jalr	-814(ra) # 80002f22 <bread>
    80003258:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325a:	004b2503          	lw	a0,4(s6)
    8000325e:	000a849b          	sext.w	s1,s5
    80003262:	8662                	mv	a2,s8
    80003264:	faa4fde3          	bgeu	s1,a0,8000321e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003268:	41f6579b          	sraiw	a5,a2,0x1f
    8000326c:	01d7d69b          	srliw	a3,a5,0x1d
    80003270:	00c6873b          	addw	a4,a3,a2
    80003274:	00777793          	andi	a5,a4,7
    80003278:	9f95                	subw	a5,a5,a3
    8000327a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000327e:	4037571b          	sraiw	a4,a4,0x3
    80003282:	00e906b3          	add	a3,s2,a4
    80003286:	0586c683          	lbu	a3,88(a3)
    8000328a:	00d7f5b3          	and	a1,a5,a3
    8000328e:	cd91                	beqz	a1,800032aa <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003290:	2605                	addiw	a2,a2,1
    80003292:	2485                	addiw	s1,s1,1
    80003294:	fd4618e3          	bne	a2,s4,80003264 <balloc+0x80>
    80003298:	b759                	j	8000321e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000329a:	00005517          	auipc	a0,0x5
    8000329e:	24650513          	addi	a0,a0,582 # 800084e0 <syscalls+0x100>
    800032a2:	ffffd097          	auipc	ra,0xffffd
    800032a6:	2a0080e7          	jalr	672(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032aa:	974a                	add	a4,a4,s2
    800032ac:	8fd5                	or	a5,a5,a3
    800032ae:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	006080e7          	jalr	6(ra) # 800042ba <log_write>
        brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	d94080e7          	jalr	-620(ra) # 80003052 <brelse>
  bp = bread(dev, bno);
    800032c6:	85a6                	mv	a1,s1
    800032c8:	855e                	mv	a0,s7
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	c58080e7          	jalr	-936(ra) # 80002f22 <bread>
    800032d2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032d4:	40000613          	li	a2,1024
    800032d8:	4581                	li	a1,0
    800032da:	05850513          	addi	a0,a0,88
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	a1c080e7          	jalr	-1508(ra) # 80000cfa <memset>
  log_write(bp);
    800032e6:	854a                	mv	a0,s2
    800032e8:	00001097          	auipc	ra,0x1
    800032ec:	fd2080e7          	jalr	-46(ra) # 800042ba <log_write>
  brelse(bp);
    800032f0:	854a                	mv	a0,s2
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	d60080e7          	jalr	-672(ra) # 80003052 <brelse>
}
    800032fa:	8526                	mv	a0,s1
    800032fc:	60e6                	ld	ra,88(sp)
    800032fe:	6446                	ld	s0,80(sp)
    80003300:	64a6                	ld	s1,72(sp)
    80003302:	6906                	ld	s2,64(sp)
    80003304:	79e2                	ld	s3,56(sp)
    80003306:	7a42                	ld	s4,48(sp)
    80003308:	7aa2                	ld	s5,40(sp)
    8000330a:	7b02                	ld	s6,32(sp)
    8000330c:	6be2                	ld	s7,24(sp)
    8000330e:	6c42                	ld	s8,16(sp)
    80003310:	6ca2                	ld	s9,8(sp)
    80003312:	6125                	addi	sp,sp,96
    80003314:	8082                	ret

0000000080003316 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003316:	7179                	addi	sp,sp,-48
    80003318:	f406                	sd	ra,40(sp)
    8000331a:	f022                	sd	s0,32(sp)
    8000331c:	ec26                	sd	s1,24(sp)
    8000331e:	e84a                	sd	s2,16(sp)
    80003320:	e44e                	sd	s3,8(sp)
    80003322:	e052                	sd	s4,0(sp)
    80003324:	1800                	addi	s0,sp,48
    80003326:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003328:	47ad                	li	a5,11
    8000332a:	04b7fe63          	bgeu	a5,a1,80003386 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000332e:	ff45849b          	addiw	s1,a1,-12
    80003332:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003336:	0ff00793          	li	a5,255
    8000333a:	0ae7e363          	bltu	a5,a4,800033e0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000333e:	08052583          	lw	a1,128(a0)
    80003342:	c5ad                	beqz	a1,800033ac <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003344:	00092503          	lw	a0,0(s2)
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	bda080e7          	jalr	-1062(ra) # 80002f22 <bread>
    80003350:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003352:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003356:	02049593          	slli	a1,s1,0x20
    8000335a:	9181                	srli	a1,a1,0x20
    8000335c:	058a                	slli	a1,a1,0x2
    8000335e:	00b784b3          	add	s1,a5,a1
    80003362:	0004a983          	lw	s3,0(s1)
    80003366:	04098d63          	beqz	s3,800033c0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000336a:	8552                	mv	a0,s4
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	ce6080e7          	jalr	-794(ra) # 80003052 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003374:	854e                	mv	a0,s3
    80003376:	70a2                	ld	ra,40(sp)
    80003378:	7402                	ld	s0,32(sp)
    8000337a:	64e2                	ld	s1,24(sp)
    8000337c:	6942                	ld	s2,16(sp)
    8000337e:	69a2                	ld	s3,8(sp)
    80003380:	6a02                	ld	s4,0(sp)
    80003382:	6145                	addi	sp,sp,48
    80003384:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003386:	02059493          	slli	s1,a1,0x20
    8000338a:	9081                	srli	s1,s1,0x20
    8000338c:	048a                	slli	s1,s1,0x2
    8000338e:	94aa                	add	s1,s1,a0
    80003390:	0504a983          	lw	s3,80(s1)
    80003394:	fe0990e3          	bnez	s3,80003374 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003398:	4108                	lw	a0,0(a0)
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	e4a080e7          	jalr	-438(ra) # 800031e4 <balloc>
    800033a2:	0005099b          	sext.w	s3,a0
    800033a6:	0534a823          	sw	s3,80(s1)
    800033aa:	b7e9                	j	80003374 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033ac:	4108                	lw	a0,0(a0)
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	e36080e7          	jalr	-458(ra) # 800031e4 <balloc>
    800033b6:	0005059b          	sext.w	a1,a0
    800033ba:	08b92023          	sw	a1,128(s2)
    800033be:	b759                	j	80003344 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033c0:	00092503          	lw	a0,0(s2)
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	e20080e7          	jalr	-480(ra) # 800031e4 <balloc>
    800033cc:	0005099b          	sext.w	s3,a0
    800033d0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033d4:	8552                	mv	a0,s4
    800033d6:	00001097          	auipc	ra,0x1
    800033da:	ee4080e7          	jalr	-284(ra) # 800042ba <log_write>
    800033de:	b771                	j	8000336a <bmap+0x54>
  panic("bmap: out of range");
    800033e0:	00005517          	auipc	a0,0x5
    800033e4:	11850513          	addi	a0,a0,280 # 800084f8 <syscalls+0x118>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	15a080e7          	jalr	346(ra) # 80000542 <panic>

00000000800033f0 <iget>:
{
    800033f0:	7179                	addi	sp,sp,-48
    800033f2:	f406                	sd	ra,40(sp)
    800033f4:	f022                	sd	s0,32(sp)
    800033f6:	ec26                	sd	s1,24(sp)
    800033f8:	e84a                	sd	s2,16(sp)
    800033fa:	e44e                	sd	s3,8(sp)
    800033fc:	e052                	sd	s4,0(sp)
    800033fe:	1800                	addi	s0,sp,48
    80003400:	89aa                	mv	s3,a0
    80003402:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003404:	0001d517          	auipc	a0,0x1d
    80003408:	a5c50513          	addi	a0,a0,-1444 # 8001fe60 <icache>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	7f2080e7          	jalr	2034(ra) # 80000bfe <acquire>
  empty = 0;
    80003414:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003416:	0001d497          	auipc	s1,0x1d
    8000341a:	a6248493          	addi	s1,s1,-1438 # 8001fe78 <icache+0x18>
    8000341e:	0001e697          	auipc	a3,0x1e
    80003422:	4ea68693          	addi	a3,a3,1258 # 80021908 <log>
    80003426:	a039                	j	80003434 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003428:	02090b63          	beqz	s2,8000345e <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000342c:	08848493          	addi	s1,s1,136
    80003430:	02d48a63          	beq	s1,a3,80003464 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003434:	449c                	lw	a5,8(s1)
    80003436:	fef059e3          	blez	a5,80003428 <iget+0x38>
    8000343a:	4098                	lw	a4,0(s1)
    8000343c:	ff3716e3          	bne	a4,s3,80003428 <iget+0x38>
    80003440:	40d8                	lw	a4,4(s1)
    80003442:	ff4713e3          	bne	a4,s4,80003428 <iget+0x38>
      ip->ref++;
    80003446:	2785                	addiw	a5,a5,1
    80003448:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000344a:	0001d517          	auipc	a0,0x1d
    8000344e:	a1650513          	addi	a0,a0,-1514 # 8001fe60 <icache>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	860080e7          	jalr	-1952(ra) # 80000cb2 <release>
      return ip;
    8000345a:	8926                	mv	s2,s1
    8000345c:	a03d                	j	8000348a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000345e:	f7f9                	bnez	a5,8000342c <iget+0x3c>
    80003460:	8926                	mv	s2,s1
    80003462:	b7e9                	j	8000342c <iget+0x3c>
  if(empty == 0)
    80003464:	02090c63          	beqz	s2,8000349c <iget+0xac>
  ip->dev = dev;
    80003468:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000346c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003470:	4785                	li	a5,1
    80003472:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003476:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000347a:	0001d517          	auipc	a0,0x1d
    8000347e:	9e650513          	addi	a0,a0,-1562 # 8001fe60 <icache>
    80003482:	ffffe097          	auipc	ra,0xffffe
    80003486:	830080e7          	jalr	-2000(ra) # 80000cb2 <release>
}
    8000348a:	854a                	mv	a0,s2
    8000348c:	70a2                	ld	ra,40(sp)
    8000348e:	7402                	ld	s0,32(sp)
    80003490:	64e2                	ld	s1,24(sp)
    80003492:	6942                	ld	s2,16(sp)
    80003494:	69a2                	ld	s3,8(sp)
    80003496:	6a02                	ld	s4,0(sp)
    80003498:	6145                	addi	sp,sp,48
    8000349a:	8082                	ret
    panic("iget: no inodes");
    8000349c:	00005517          	auipc	a0,0x5
    800034a0:	07450513          	addi	a0,a0,116 # 80008510 <syscalls+0x130>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	09e080e7          	jalr	158(ra) # 80000542 <panic>

00000000800034ac <fsinit>:
fsinit(int dev) {
    800034ac:	7179                	addi	sp,sp,-48
    800034ae:	f406                	sd	ra,40(sp)
    800034b0:	f022                	sd	s0,32(sp)
    800034b2:	ec26                	sd	s1,24(sp)
    800034b4:	e84a                	sd	s2,16(sp)
    800034b6:	e44e                	sd	s3,8(sp)
    800034b8:	1800                	addi	s0,sp,48
    800034ba:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034bc:	4585                	li	a1,1
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	a64080e7          	jalr	-1436(ra) # 80002f22 <bread>
    800034c6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034c8:	0001d997          	auipc	s3,0x1d
    800034cc:	97898993          	addi	s3,s3,-1672 # 8001fe40 <sb>
    800034d0:	02000613          	li	a2,32
    800034d4:	05850593          	addi	a1,a0,88
    800034d8:	854e                	mv	a0,s3
    800034da:	ffffe097          	auipc	ra,0xffffe
    800034de:	87c080e7          	jalr	-1924(ra) # 80000d56 <memmove>
  brelse(bp);
    800034e2:	8526                	mv	a0,s1
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	b6e080e7          	jalr	-1170(ra) # 80003052 <brelse>
  if(sb.magic != FSMAGIC)
    800034ec:	0009a703          	lw	a4,0(s3)
    800034f0:	102037b7          	lui	a5,0x10203
    800034f4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034f8:	02f71263          	bne	a4,a5,8000351c <fsinit+0x70>
  initlog(dev, &sb);
    800034fc:	0001d597          	auipc	a1,0x1d
    80003500:	94458593          	addi	a1,a1,-1724 # 8001fe40 <sb>
    80003504:	854a                	mv	a0,s2
    80003506:	00001097          	auipc	ra,0x1
    8000350a:	b3c080e7          	jalr	-1220(ra) # 80004042 <initlog>
}
    8000350e:	70a2                	ld	ra,40(sp)
    80003510:	7402                	ld	s0,32(sp)
    80003512:	64e2                	ld	s1,24(sp)
    80003514:	6942                	ld	s2,16(sp)
    80003516:	69a2                	ld	s3,8(sp)
    80003518:	6145                	addi	sp,sp,48
    8000351a:	8082                	ret
    panic("invalid file system");
    8000351c:	00005517          	auipc	a0,0x5
    80003520:	00450513          	addi	a0,a0,4 # 80008520 <syscalls+0x140>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	01e080e7          	jalr	30(ra) # 80000542 <panic>

000000008000352c <iinit>:
{
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000353a:	00005597          	auipc	a1,0x5
    8000353e:	ffe58593          	addi	a1,a1,-2 # 80008538 <syscalls+0x158>
    80003542:	0001d517          	auipc	a0,0x1d
    80003546:	91e50513          	addi	a0,a0,-1762 # 8001fe60 <icache>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	624080e7          	jalr	1572(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003552:	0001d497          	auipc	s1,0x1d
    80003556:	93648493          	addi	s1,s1,-1738 # 8001fe88 <icache+0x28>
    8000355a:	0001e997          	auipc	s3,0x1e
    8000355e:	3be98993          	addi	s3,s3,958 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003562:	00005917          	auipc	s2,0x5
    80003566:	fde90913          	addi	s2,s2,-34 # 80008540 <syscalls+0x160>
    8000356a:	85ca                	mv	a1,s2
    8000356c:	8526                	mv	a0,s1
    8000356e:	00001097          	auipc	ra,0x1
    80003572:	e3a080e7          	jalr	-454(ra) # 800043a8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003576:	08848493          	addi	s1,s1,136
    8000357a:	ff3498e3          	bne	s1,s3,8000356a <iinit+0x3e>
}
    8000357e:	70a2                	ld	ra,40(sp)
    80003580:	7402                	ld	s0,32(sp)
    80003582:	64e2                	ld	s1,24(sp)
    80003584:	6942                	ld	s2,16(sp)
    80003586:	69a2                	ld	s3,8(sp)
    80003588:	6145                	addi	sp,sp,48
    8000358a:	8082                	ret

000000008000358c <ialloc>:
{
    8000358c:	715d                	addi	sp,sp,-80
    8000358e:	e486                	sd	ra,72(sp)
    80003590:	e0a2                	sd	s0,64(sp)
    80003592:	fc26                	sd	s1,56(sp)
    80003594:	f84a                	sd	s2,48(sp)
    80003596:	f44e                	sd	s3,40(sp)
    80003598:	f052                	sd	s4,32(sp)
    8000359a:	ec56                	sd	s5,24(sp)
    8000359c:	e85a                	sd	s6,16(sp)
    8000359e:	e45e                	sd	s7,8(sp)
    800035a0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a2:	0001d717          	auipc	a4,0x1d
    800035a6:	8aa72703          	lw	a4,-1878(a4) # 8001fe4c <sb+0xc>
    800035aa:	4785                	li	a5,1
    800035ac:	04e7fa63          	bgeu	a5,a4,80003600 <ialloc+0x74>
    800035b0:	8aaa                	mv	s5,a0
    800035b2:	8bae                	mv	s7,a1
    800035b4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035b6:	0001da17          	auipc	s4,0x1d
    800035ba:	88aa0a13          	addi	s4,s4,-1910 # 8001fe40 <sb>
    800035be:	00048b1b          	sext.w	s6,s1
    800035c2:	0044d793          	srli	a5,s1,0x4
    800035c6:	018a2583          	lw	a1,24(s4)
    800035ca:	9dbd                	addw	a1,a1,a5
    800035cc:	8556                	mv	a0,s5
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	954080e7          	jalr	-1708(ra) # 80002f22 <bread>
    800035d6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035d8:	05850993          	addi	s3,a0,88
    800035dc:	00f4f793          	andi	a5,s1,15
    800035e0:	079a                	slli	a5,a5,0x6
    800035e2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035e4:	00099783          	lh	a5,0(s3)
    800035e8:	c785                	beqz	a5,80003610 <ialloc+0x84>
    brelse(bp);
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	a68080e7          	jalr	-1432(ra) # 80003052 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f2:	0485                	addi	s1,s1,1
    800035f4:	00ca2703          	lw	a4,12(s4)
    800035f8:	0004879b          	sext.w	a5,s1
    800035fc:	fce7e1e3          	bltu	a5,a4,800035be <ialloc+0x32>
  panic("ialloc: no inodes");
    80003600:	00005517          	auipc	a0,0x5
    80003604:	f4850513          	addi	a0,a0,-184 # 80008548 <syscalls+0x168>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	f3a080e7          	jalr	-198(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    80003610:	04000613          	li	a2,64
    80003614:	4581                	li	a1,0
    80003616:	854e                	mv	a0,s3
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	6e2080e7          	jalr	1762(ra) # 80000cfa <memset>
      dip->type = type;
    80003620:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003624:	854a                	mv	a0,s2
    80003626:	00001097          	auipc	ra,0x1
    8000362a:	c94080e7          	jalr	-876(ra) # 800042ba <log_write>
      brelse(bp);
    8000362e:	854a                	mv	a0,s2
    80003630:	00000097          	auipc	ra,0x0
    80003634:	a22080e7          	jalr	-1502(ra) # 80003052 <brelse>
      return iget(dev, inum);
    80003638:	85da                	mv	a1,s6
    8000363a:	8556                	mv	a0,s5
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	db4080e7          	jalr	-588(ra) # 800033f0 <iget>
}
    80003644:	60a6                	ld	ra,72(sp)
    80003646:	6406                	ld	s0,64(sp)
    80003648:	74e2                	ld	s1,56(sp)
    8000364a:	7942                	ld	s2,48(sp)
    8000364c:	79a2                	ld	s3,40(sp)
    8000364e:	7a02                	ld	s4,32(sp)
    80003650:	6ae2                	ld	s5,24(sp)
    80003652:	6b42                	ld	s6,16(sp)
    80003654:	6ba2                	ld	s7,8(sp)
    80003656:	6161                	addi	sp,sp,80
    80003658:	8082                	ret

000000008000365a <iupdate>:
{
    8000365a:	1101                	addi	sp,sp,-32
    8000365c:	ec06                	sd	ra,24(sp)
    8000365e:	e822                	sd	s0,16(sp)
    80003660:	e426                	sd	s1,8(sp)
    80003662:	e04a                	sd	s2,0(sp)
    80003664:	1000                	addi	s0,sp,32
    80003666:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003668:	415c                	lw	a5,4(a0)
    8000366a:	0047d79b          	srliw	a5,a5,0x4
    8000366e:	0001c597          	auipc	a1,0x1c
    80003672:	7ea5a583          	lw	a1,2026(a1) # 8001fe58 <sb+0x18>
    80003676:	9dbd                	addw	a1,a1,a5
    80003678:	4108                	lw	a0,0(a0)
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	8a8080e7          	jalr	-1880(ra) # 80002f22 <bread>
    80003682:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003684:	05850793          	addi	a5,a0,88
    80003688:	40c8                	lw	a0,4(s1)
    8000368a:	893d                	andi	a0,a0,15
    8000368c:	051a                	slli	a0,a0,0x6
    8000368e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003690:	04449703          	lh	a4,68(s1)
    80003694:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003698:	04649703          	lh	a4,70(s1)
    8000369c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036a0:	04849703          	lh	a4,72(s1)
    800036a4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036a8:	04a49703          	lh	a4,74(s1)
    800036ac:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036b0:	44f8                	lw	a4,76(s1)
    800036b2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036b4:	03400613          	li	a2,52
    800036b8:	05048593          	addi	a1,s1,80
    800036bc:	0531                	addi	a0,a0,12
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	698080e7          	jalr	1688(ra) # 80000d56 <memmove>
  log_write(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	bf2080e7          	jalr	-1038(ra) # 800042ba <log_write>
  brelse(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	980080e7          	jalr	-1664(ra) # 80003052 <brelse>
}
    800036da:	60e2                	ld	ra,24(sp)
    800036dc:	6442                	ld	s0,16(sp)
    800036de:	64a2                	ld	s1,8(sp)
    800036e0:	6902                	ld	s2,0(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret

00000000800036e6 <idup>:
{
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	1000                	addi	s0,sp,32
    800036f0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036f2:	0001c517          	auipc	a0,0x1c
    800036f6:	76e50513          	addi	a0,a0,1902 # 8001fe60 <icache>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	504080e7          	jalr	1284(ra) # 80000bfe <acquire>
  ip->ref++;
    80003702:	449c                	lw	a5,8(s1)
    80003704:	2785                	addiw	a5,a5,1
    80003706:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003708:	0001c517          	auipc	a0,0x1c
    8000370c:	75850513          	addi	a0,a0,1880 # 8001fe60 <icache>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	5a2080e7          	jalr	1442(ra) # 80000cb2 <release>
}
    80003718:	8526                	mv	a0,s1
    8000371a:	60e2                	ld	ra,24(sp)
    8000371c:	6442                	ld	s0,16(sp)
    8000371e:	64a2                	ld	s1,8(sp)
    80003720:	6105                	addi	sp,sp,32
    80003722:	8082                	ret

0000000080003724 <ilock>:
{
    80003724:	1101                	addi	sp,sp,-32
    80003726:	ec06                	sd	ra,24(sp)
    80003728:	e822                	sd	s0,16(sp)
    8000372a:	e426                	sd	s1,8(sp)
    8000372c:	e04a                	sd	s2,0(sp)
    8000372e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003730:	c115                	beqz	a0,80003754 <ilock+0x30>
    80003732:	84aa                	mv	s1,a0
    80003734:	451c                	lw	a5,8(a0)
    80003736:	00f05f63          	blez	a5,80003754 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000373a:	0541                	addi	a0,a0,16
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	ca6080e7          	jalr	-858(ra) # 800043e2 <acquiresleep>
  if(ip->valid == 0){
    80003744:	40bc                	lw	a5,64(s1)
    80003746:	cf99                	beqz	a5,80003764 <ilock+0x40>
}
    80003748:	60e2                	ld	ra,24(sp)
    8000374a:	6442                	ld	s0,16(sp)
    8000374c:	64a2                	ld	s1,8(sp)
    8000374e:	6902                	ld	s2,0(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret
    panic("ilock");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	e0c50513          	addi	a0,a0,-500 # 80008560 <syscalls+0x180>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	de6080e7          	jalr	-538(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003764:	40dc                	lw	a5,4(s1)
    80003766:	0047d79b          	srliw	a5,a5,0x4
    8000376a:	0001c597          	auipc	a1,0x1c
    8000376e:	6ee5a583          	lw	a1,1774(a1) # 8001fe58 <sb+0x18>
    80003772:	9dbd                	addw	a1,a1,a5
    80003774:	4088                	lw	a0,0(s1)
    80003776:	fffff097          	auipc	ra,0xfffff
    8000377a:	7ac080e7          	jalr	1964(ra) # 80002f22 <bread>
    8000377e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003780:	05850593          	addi	a1,a0,88
    80003784:	40dc                	lw	a5,4(s1)
    80003786:	8bbd                	andi	a5,a5,15
    80003788:	079a                	slli	a5,a5,0x6
    8000378a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000378c:	00059783          	lh	a5,0(a1)
    80003790:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003794:	00259783          	lh	a5,2(a1)
    80003798:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000379c:	00459783          	lh	a5,4(a1)
    800037a0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037a4:	00659783          	lh	a5,6(a1)
    800037a8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037ac:	459c                	lw	a5,8(a1)
    800037ae:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037b0:	03400613          	li	a2,52
    800037b4:	05b1                	addi	a1,a1,12
    800037b6:	05048513          	addi	a0,s1,80
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	59c080e7          	jalr	1436(ra) # 80000d56 <memmove>
    brelse(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	88e080e7          	jalr	-1906(ra) # 80003052 <brelse>
    ip->valid = 1;
    800037cc:	4785                	li	a5,1
    800037ce:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037d0:	04449783          	lh	a5,68(s1)
    800037d4:	fbb5                	bnez	a5,80003748 <ilock+0x24>
      panic("ilock: no type");
    800037d6:	00005517          	auipc	a0,0x5
    800037da:	d9250513          	addi	a0,a0,-622 # 80008568 <syscalls+0x188>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	d64080e7          	jalr	-668(ra) # 80000542 <panic>

00000000800037e6 <iunlock>:
{
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	e426                	sd	s1,8(sp)
    800037ee:	e04a                	sd	s2,0(sp)
    800037f0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037f2:	c905                	beqz	a0,80003822 <iunlock+0x3c>
    800037f4:	84aa                	mv	s1,a0
    800037f6:	01050913          	addi	s2,a0,16
    800037fa:	854a                	mv	a0,s2
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	c80080e7          	jalr	-896(ra) # 8000447c <holdingsleep>
    80003804:	cd19                	beqz	a0,80003822 <iunlock+0x3c>
    80003806:	449c                	lw	a5,8(s1)
    80003808:	00f05d63          	blez	a5,80003822 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000380c:	854a                	mv	a0,s2
    8000380e:	00001097          	auipc	ra,0x1
    80003812:	c2a080e7          	jalr	-982(ra) # 80004438 <releasesleep>
}
    80003816:	60e2                	ld	ra,24(sp)
    80003818:	6442                	ld	s0,16(sp)
    8000381a:	64a2                	ld	s1,8(sp)
    8000381c:	6902                	ld	s2,0(sp)
    8000381e:	6105                	addi	sp,sp,32
    80003820:	8082                	ret
    panic("iunlock");
    80003822:	00005517          	auipc	a0,0x5
    80003826:	d5650513          	addi	a0,a0,-682 # 80008578 <syscalls+0x198>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	d18080e7          	jalr	-744(ra) # 80000542 <panic>

0000000080003832 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003832:	7179                	addi	sp,sp,-48
    80003834:	f406                	sd	ra,40(sp)
    80003836:	f022                	sd	s0,32(sp)
    80003838:	ec26                	sd	s1,24(sp)
    8000383a:	e84a                	sd	s2,16(sp)
    8000383c:	e44e                	sd	s3,8(sp)
    8000383e:	e052                	sd	s4,0(sp)
    80003840:	1800                	addi	s0,sp,48
    80003842:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003844:	05050493          	addi	s1,a0,80
    80003848:	08050913          	addi	s2,a0,128
    8000384c:	a021                	j	80003854 <itrunc+0x22>
    8000384e:	0491                	addi	s1,s1,4
    80003850:	01248d63          	beq	s1,s2,8000386a <itrunc+0x38>
    if(ip->addrs[i]){
    80003854:	408c                	lw	a1,0(s1)
    80003856:	dde5                	beqz	a1,8000384e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003858:	0009a503          	lw	a0,0(s3)
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	90c080e7          	jalr	-1780(ra) # 80003168 <bfree>
      ip->addrs[i] = 0;
    80003864:	0004a023          	sw	zero,0(s1)
    80003868:	b7dd                	j	8000384e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000386a:	0809a583          	lw	a1,128(s3)
    8000386e:	e185                	bnez	a1,8000388e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003870:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003874:	854e                	mv	a0,s3
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	de4080e7          	jalr	-540(ra) # 8000365a <iupdate>
}
    8000387e:	70a2                	ld	ra,40(sp)
    80003880:	7402                	ld	s0,32(sp)
    80003882:	64e2                	ld	s1,24(sp)
    80003884:	6942                	ld	s2,16(sp)
    80003886:	69a2                	ld	s3,8(sp)
    80003888:	6a02                	ld	s4,0(sp)
    8000388a:	6145                	addi	sp,sp,48
    8000388c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000388e:	0009a503          	lw	a0,0(s3)
    80003892:	fffff097          	auipc	ra,0xfffff
    80003896:	690080e7          	jalr	1680(ra) # 80002f22 <bread>
    8000389a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000389c:	05850493          	addi	s1,a0,88
    800038a0:	45850913          	addi	s2,a0,1112
    800038a4:	a021                	j	800038ac <itrunc+0x7a>
    800038a6:	0491                	addi	s1,s1,4
    800038a8:	01248b63          	beq	s1,s2,800038be <itrunc+0x8c>
      if(a[j])
    800038ac:	408c                	lw	a1,0(s1)
    800038ae:	dde5                	beqz	a1,800038a6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038b0:	0009a503          	lw	a0,0(s3)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	8b4080e7          	jalr	-1868(ra) # 80003168 <bfree>
    800038bc:	b7ed                	j	800038a6 <itrunc+0x74>
    brelse(bp);
    800038be:	8552                	mv	a0,s4
    800038c0:	fffff097          	auipc	ra,0xfffff
    800038c4:	792080e7          	jalr	1938(ra) # 80003052 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038c8:	0809a583          	lw	a1,128(s3)
    800038cc:	0009a503          	lw	a0,0(s3)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	898080e7          	jalr	-1896(ra) # 80003168 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038d8:	0809a023          	sw	zero,128(s3)
    800038dc:	bf51                	j	80003870 <itrunc+0x3e>

00000000800038de <iput>:
{
    800038de:	1101                	addi	sp,sp,-32
    800038e0:	ec06                	sd	ra,24(sp)
    800038e2:	e822                	sd	s0,16(sp)
    800038e4:	e426                	sd	s1,8(sp)
    800038e6:	e04a                	sd	s2,0(sp)
    800038e8:	1000                	addi	s0,sp,32
    800038ea:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038ec:	0001c517          	auipc	a0,0x1c
    800038f0:	57450513          	addi	a0,a0,1396 # 8001fe60 <icache>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	30a080e7          	jalr	778(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038fc:	4498                	lw	a4,8(s1)
    800038fe:	4785                	li	a5,1
    80003900:	02f70363          	beq	a4,a5,80003926 <iput+0x48>
  ip->ref--;
    80003904:	449c                	lw	a5,8(s1)
    80003906:	37fd                	addiw	a5,a5,-1
    80003908:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000390a:	0001c517          	auipc	a0,0x1c
    8000390e:	55650513          	addi	a0,a0,1366 # 8001fe60 <icache>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	3a0080e7          	jalr	928(ra) # 80000cb2 <release>
}
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	64a2                	ld	s1,8(sp)
    80003920:	6902                	ld	s2,0(sp)
    80003922:	6105                	addi	sp,sp,32
    80003924:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003926:	40bc                	lw	a5,64(s1)
    80003928:	dff1                	beqz	a5,80003904 <iput+0x26>
    8000392a:	04a49783          	lh	a5,74(s1)
    8000392e:	fbf9                	bnez	a5,80003904 <iput+0x26>
    acquiresleep(&ip->lock);
    80003930:	01048913          	addi	s2,s1,16
    80003934:	854a                	mv	a0,s2
    80003936:	00001097          	auipc	ra,0x1
    8000393a:	aac080e7          	jalr	-1364(ra) # 800043e2 <acquiresleep>
    release(&icache.lock);
    8000393e:	0001c517          	auipc	a0,0x1c
    80003942:	52250513          	addi	a0,a0,1314 # 8001fe60 <icache>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	36c080e7          	jalr	876(ra) # 80000cb2 <release>
    itrunc(ip);
    8000394e:	8526                	mv	a0,s1
    80003950:	00000097          	auipc	ra,0x0
    80003954:	ee2080e7          	jalr	-286(ra) # 80003832 <itrunc>
    ip->type = 0;
    80003958:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000395c:	8526                	mv	a0,s1
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	cfc080e7          	jalr	-772(ra) # 8000365a <iupdate>
    ip->valid = 0;
    80003966:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000396a:	854a                	mv	a0,s2
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	acc080e7          	jalr	-1332(ra) # 80004438 <releasesleep>
    acquire(&icache.lock);
    80003974:	0001c517          	auipc	a0,0x1c
    80003978:	4ec50513          	addi	a0,a0,1260 # 8001fe60 <icache>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	282080e7          	jalr	642(ra) # 80000bfe <acquire>
    80003984:	b741                	j	80003904 <iput+0x26>

0000000080003986 <iunlockput>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	1000                	addi	s0,sp,32
    80003990:	84aa                	mv	s1,a0
  iunlock(ip);
    80003992:	00000097          	auipc	ra,0x0
    80003996:	e54080e7          	jalr	-428(ra) # 800037e6 <iunlock>
  iput(ip);
    8000399a:	8526                	mv	a0,s1
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	f42080e7          	jalr	-190(ra) # 800038de <iput>
}
    800039a4:	60e2                	ld	ra,24(sp)
    800039a6:	6442                	ld	s0,16(sp)
    800039a8:	64a2                	ld	s1,8(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret

00000000800039ae <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039ae:	1141                	addi	sp,sp,-16
    800039b0:	e422                	sd	s0,8(sp)
    800039b2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039b4:	411c                	lw	a5,0(a0)
    800039b6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039b8:	415c                	lw	a5,4(a0)
    800039ba:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039bc:	04451783          	lh	a5,68(a0)
    800039c0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039c4:	04a51783          	lh	a5,74(a0)
    800039c8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039cc:	04c56783          	lwu	a5,76(a0)
    800039d0:	e99c                	sd	a5,16(a1)
}
    800039d2:	6422                	ld	s0,8(sp)
    800039d4:	0141                	addi	sp,sp,16
    800039d6:	8082                	ret

00000000800039d8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039d8:	457c                	lw	a5,76(a0)
    800039da:	0ed7e963          	bltu	a5,a3,80003acc <readi+0xf4>
{
    800039de:	7159                	addi	sp,sp,-112
    800039e0:	f486                	sd	ra,104(sp)
    800039e2:	f0a2                	sd	s0,96(sp)
    800039e4:	eca6                	sd	s1,88(sp)
    800039e6:	e8ca                	sd	s2,80(sp)
    800039e8:	e4ce                	sd	s3,72(sp)
    800039ea:	e0d2                	sd	s4,64(sp)
    800039ec:	fc56                	sd	s5,56(sp)
    800039ee:	f85a                	sd	s6,48(sp)
    800039f0:	f45e                	sd	s7,40(sp)
    800039f2:	f062                	sd	s8,32(sp)
    800039f4:	ec66                	sd	s9,24(sp)
    800039f6:	e86a                	sd	s10,16(sp)
    800039f8:	e46e                	sd	s11,8(sp)
    800039fa:	1880                	addi	s0,sp,112
    800039fc:	8baa                	mv	s7,a0
    800039fe:	8c2e                	mv	s8,a1
    80003a00:	8ab2                	mv	s5,a2
    80003a02:	84b6                	mv	s1,a3
    80003a04:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a06:	9f35                	addw	a4,a4,a3
    return 0;
    80003a08:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a0a:	0ad76063          	bltu	a4,a3,80003aaa <readi+0xd2>
  if(off + n > ip->size)
    80003a0e:	00e7f463          	bgeu	a5,a4,80003a16 <readi+0x3e>
    n = ip->size - off;
    80003a12:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a16:	0a0b0963          	beqz	s6,80003ac8 <readi+0xf0>
    80003a1a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a20:	5cfd                	li	s9,-1
    80003a22:	a82d                	j	80003a5c <readi+0x84>
    80003a24:	020a1d93          	slli	s11,s4,0x20
    80003a28:	020ddd93          	srli	s11,s11,0x20
    80003a2c:	05890793          	addi	a5,s2,88
    80003a30:	86ee                	mv	a3,s11
    80003a32:	963e                	add	a2,a2,a5
    80003a34:	85d6                	mv	a1,s5
    80003a36:	8562                	mv	a0,s8
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	a3e080e7          	jalr	-1474(ra) # 80002476 <either_copyout>
    80003a40:	05950d63          	beq	a0,s9,80003a9a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a44:	854a                	mv	a0,s2
    80003a46:	fffff097          	auipc	ra,0xfffff
    80003a4a:	60c080e7          	jalr	1548(ra) # 80003052 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4e:	013a09bb          	addw	s3,s4,s3
    80003a52:	009a04bb          	addw	s1,s4,s1
    80003a56:	9aee                	add	s5,s5,s11
    80003a58:	0569f763          	bgeu	s3,s6,80003aa6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a5c:	000ba903          	lw	s2,0(s7)
    80003a60:	00a4d59b          	srliw	a1,s1,0xa
    80003a64:	855e                	mv	a0,s7
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	8b0080e7          	jalr	-1872(ra) # 80003316 <bmap>
    80003a6e:	0005059b          	sext.w	a1,a0
    80003a72:	854a                	mv	a0,s2
    80003a74:	fffff097          	auipc	ra,0xfffff
    80003a78:	4ae080e7          	jalr	1198(ra) # 80002f22 <bread>
    80003a7c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7e:	3ff4f613          	andi	a2,s1,1023
    80003a82:	40cd07bb          	subw	a5,s10,a2
    80003a86:	413b073b          	subw	a4,s6,s3
    80003a8a:	8a3e                	mv	s4,a5
    80003a8c:	2781                	sext.w	a5,a5
    80003a8e:	0007069b          	sext.w	a3,a4
    80003a92:	f8f6f9e3          	bgeu	a3,a5,80003a24 <readi+0x4c>
    80003a96:	8a3a                	mv	s4,a4
    80003a98:	b771                	j	80003a24 <readi+0x4c>
      brelse(bp);
    80003a9a:	854a                	mv	a0,s2
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	5b6080e7          	jalr	1462(ra) # 80003052 <brelse>
      tot = -1;
    80003aa4:	59fd                	li	s3,-1
  }
  return tot;
    80003aa6:	0009851b          	sext.w	a0,s3
}
    80003aaa:	70a6                	ld	ra,104(sp)
    80003aac:	7406                	ld	s0,96(sp)
    80003aae:	64e6                	ld	s1,88(sp)
    80003ab0:	6946                	ld	s2,80(sp)
    80003ab2:	69a6                	ld	s3,72(sp)
    80003ab4:	6a06                	ld	s4,64(sp)
    80003ab6:	7ae2                	ld	s5,56(sp)
    80003ab8:	7b42                	ld	s6,48(sp)
    80003aba:	7ba2                	ld	s7,40(sp)
    80003abc:	7c02                	ld	s8,32(sp)
    80003abe:	6ce2                	ld	s9,24(sp)
    80003ac0:	6d42                	ld	s10,16(sp)
    80003ac2:	6da2                	ld	s11,8(sp)
    80003ac4:	6165                	addi	sp,sp,112
    80003ac6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac8:	89da                	mv	s3,s6
    80003aca:	bff1                	j	80003aa6 <readi+0xce>
    return 0;
    80003acc:	4501                	li	a0,0
}
    80003ace:	8082                	ret

0000000080003ad0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ad0:	457c                	lw	a5,76(a0)
    80003ad2:	10d7e763          	bltu	a5,a3,80003be0 <writei+0x110>
{
    80003ad6:	7159                	addi	sp,sp,-112
    80003ad8:	f486                	sd	ra,104(sp)
    80003ada:	f0a2                	sd	s0,96(sp)
    80003adc:	eca6                	sd	s1,88(sp)
    80003ade:	e8ca                	sd	s2,80(sp)
    80003ae0:	e4ce                	sd	s3,72(sp)
    80003ae2:	e0d2                	sd	s4,64(sp)
    80003ae4:	fc56                	sd	s5,56(sp)
    80003ae6:	f85a                	sd	s6,48(sp)
    80003ae8:	f45e                	sd	s7,40(sp)
    80003aea:	f062                	sd	s8,32(sp)
    80003aec:	ec66                	sd	s9,24(sp)
    80003aee:	e86a                	sd	s10,16(sp)
    80003af0:	e46e                	sd	s11,8(sp)
    80003af2:	1880                	addi	s0,sp,112
    80003af4:	8baa                	mv	s7,a0
    80003af6:	8c2e                	mv	s8,a1
    80003af8:	8ab2                	mv	s5,a2
    80003afa:	8936                	mv	s2,a3
    80003afc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003afe:	00e687bb          	addw	a5,a3,a4
    80003b02:	0ed7e163          	bltu	a5,a3,80003be4 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b06:	00043737          	lui	a4,0x43
    80003b0a:	0cf76f63          	bltu	a4,a5,80003be8 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b0e:	0a0b0863          	beqz	s6,80003bbe <writei+0xee>
    80003b12:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b14:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b18:	5cfd                	li	s9,-1
    80003b1a:	a091                	j	80003b5e <writei+0x8e>
    80003b1c:	02099d93          	slli	s11,s3,0x20
    80003b20:	020ddd93          	srli	s11,s11,0x20
    80003b24:	05848793          	addi	a5,s1,88
    80003b28:	86ee                	mv	a3,s11
    80003b2a:	8656                	mv	a2,s5
    80003b2c:	85e2                	mv	a1,s8
    80003b2e:	953e                	add	a0,a0,a5
    80003b30:	fffff097          	auipc	ra,0xfffff
    80003b34:	99c080e7          	jalr	-1636(ra) # 800024cc <either_copyin>
    80003b38:	07950263          	beq	a0,s9,80003b9c <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003b3c:	8526                	mv	a0,s1
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	77c080e7          	jalr	1916(ra) # 800042ba <log_write>
    brelse(bp);
    80003b46:	8526                	mv	a0,s1
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	50a080e7          	jalr	1290(ra) # 80003052 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b50:	01498a3b          	addw	s4,s3,s4
    80003b54:	0129893b          	addw	s2,s3,s2
    80003b58:	9aee                	add	s5,s5,s11
    80003b5a:	056a7763          	bgeu	s4,s6,80003ba8 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b5e:	000ba483          	lw	s1,0(s7)
    80003b62:	00a9559b          	srliw	a1,s2,0xa
    80003b66:	855e                	mv	a0,s7
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	7ae080e7          	jalr	1966(ra) # 80003316 <bmap>
    80003b70:	0005059b          	sext.w	a1,a0
    80003b74:	8526                	mv	a0,s1
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	3ac080e7          	jalr	940(ra) # 80002f22 <bread>
    80003b7e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b80:	3ff97513          	andi	a0,s2,1023
    80003b84:	40ad07bb          	subw	a5,s10,a0
    80003b88:	414b073b          	subw	a4,s6,s4
    80003b8c:	89be                	mv	s3,a5
    80003b8e:	2781                	sext.w	a5,a5
    80003b90:	0007069b          	sext.w	a3,a4
    80003b94:	f8f6f4e3          	bgeu	a3,a5,80003b1c <writei+0x4c>
    80003b98:	89ba                	mv	s3,a4
    80003b9a:	b749                	j	80003b1c <writei+0x4c>
      brelse(bp);
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	4b4080e7          	jalr	1204(ra) # 80003052 <brelse>
      n = -1;
    80003ba6:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003ba8:	04cba783          	lw	a5,76(s7)
    80003bac:	0127f463          	bgeu	a5,s2,80003bb4 <writei+0xe4>
      ip->size = off;
    80003bb0:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bb4:	855e                	mv	a0,s7
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	aa4080e7          	jalr	-1372(ra) # 8000365a <iupdate>
  }

  return n;
    80003bbe:	000b051b          	sext.w	a0,s6
}
    80003bc2:	70a6                	ld	ra,104(sp)
    80003bc4:	7406                	ld	s0,96(sp)
    80003bc6:	64e6                	ld	s1,88(sp)
    80003bc8:	6946                	ld	s2,80(sp)
    80003bca:	69a6                	ld	s3,72(sp)
    80003bcc:	6a06                	ld	s4,64(sp)
    80003bce:	7ae2                	ld	s5,56(sp)
    80003bd0:	7b42                	ld	s6,48(sp)
    80003bd2:	7ba2                	ld	s7,40(sp)
    80003bd4:	7c02                	ld	s8,32(sp)
    80003bd6:	6ce2                	ld	s9,24(sp)
    80003bd8:	6d42                	ld	s10,16(sp)
    80003bda:	6da2                	ld	s11,8(sp)
    80003bdc:	6165                	addi	sp,sp,112
    80003bde:	8082                	ret
    return -1;
    80003be0:	557d                	li	a0,-1
}
    80003be2:	8082                	ret
    return -1;
    80003be4:	557d                	li	a0,-1
    80003be6:	bff1                	j	80003bc2 <writei+0xf2>
    return -1;
    80003be8:	557d                	li	a0,-1
    80003bea:	bfe1                	j	80003bc2 <writei+0xf2>

0000000080003bec <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bec:	1141                	addi	sp,sp,-16
    80003bee:	e406                	sd	ra,8(sp)
    80003bf0:	e022                	sd	s0,0(sp)
    80003bf2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bf4:	4639                	li	a2,14
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	1dc080e7          	jalr	476(ra) # 80000dd2 <strncmp>
}
    80003bfe:	60a2                	ld	ra,8(sp)
    80003c00:	6402                	ld	s0,0(sp)
    80003c02:	0141                	addi	sp,sp,16
    80003c04:	8082                	ret

0000000080003c06 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c06:	7139                	addi	sp,sp,-64
    80003c08:	fc06                	sd	ra,56(sp)
    80003c0a:	f822                	sd	s0,48(sp)
    80003c0c:	f426                	sd	s1,40(sp)
    80003c0e:	f04a                	sd	s2,32(sp)
    80003c10:	ec4e                	sd	s3,24(sp)
    80003c12:	e852                	sd	s4,16(sp)
    80003c14:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c16:	04451703          	lh	a4,68(a0)
    80003c1a:	4785                	li	a5,1
    80003c1c:	00f71a63          	bne	a4,a5,80003c30 <dirlookup+0x2a>
    80003c20:	892a                	mv	s2,a0
    80003c22:	89ae                	mv	s3,a1
    80003c24:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c26:	457c                	lw	a5,76(a0)
    80003c28:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c2a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c2c:	e79d                	bnez	a5,80003c5a <dirlookup+0x54>
    80003c2e:	a8a5                	j	80003ca6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c30:	00005517          	auipc	a0,0x5
    80003c34:	95050513          	addi	a0,a0,-1712 # 80008580 <syscalls+0x1a0>
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	90a080e7          	jalr	-1782(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003c40:	00005517          	auipc	a0,0x5
    80003c44:	95850513          	addi	a0,a0,-1704 # 80008598 <syscalls+0x1b8>
    80003c48:	ffffd097          	auipc	ra,0xffffd
    80003c4c:	8fa080e7          	jalr	-1798(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c50:	24c1                	addiw	s1,s1,16
    80003c52:	04c92783          	lw	a5,76(s2)
    80003c56:	04f4f763          	bgeu	s1,a5,80003ca4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c5a:	4741                	li	a4,16
    80003c5c:	86a6                	mv	a3,s1
    80003c5e:	fc040613          	addi	a2,s0,-64
    80003c62:	4581                	li	a1,0
    80003c64:	854a                	mv	a0,s2
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	d72080e7          	jalr	-654(ra) # 800039d8 <readi>
    80003c6e:	47c1                	li	a5,16
    80003c70:	fcf518e3          	bne	a0,a5,80003c40 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c74:	fc045783          	lhu	a5,-64(s0)
    80003c78:	dfe1                	beqz	a5,80003c50 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c7a:	fc240593          	addi	a1,s0,-62
    80003c7e:	854e                	mv	a0,s3
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	f6c080e7          	jalr	-148(ra) # 80003bec <namecmp>
    80003c88:	f561                	bnez	a0,80003c50 <dirlookup+0x4a>
      if(poff)
    80003c8a:	000a0463          	beqz	s4,80003c92 <dirlookup+0x8c>
        *poff = off;
    80003c8e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c92:	fc045583          	lhu	a1,-64(s0)
    80003c96:	00092503          	lw	a0,0(s2)
    80003c9a:	fffff097          	auipc	ra,0xfffff
    80003c9e:	756080e7          	jalr	1878(ra) # 800033f0 <iget>
    80003ca2:	a011                	j	80003ca6 <dirlookup+0xa0>
  return 0;
    80003ca4:	4501                	li	a0,0
}
    80003ca6:	70e2                	ld	ra,56(sp)
    80003ca8:	7442                	ld	s0,48(sp)
    80003caa:	74a2                	ld	s1,40(sp)
    80003cac:	7902                	ld	s2,32(sp)
    80003cae:	69e2                	ld	s3,24(sp)
    80003cb0:	6a42                	ld	s4,16(sp)
    80003cb2:	6121                	addi	sp,sp,64
    80003cb4:	8082                	ret

0000000080003cb6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cb6:	711d                	addi	sp,sp,-96
    80003cb8:	ec86                	sd	ra,88(sp)
    80003cba:	e8a2                	sd	s0,80(sp)
    80003cbc:	e4a6                	sd	s1,72(sp)
    80003cbe:	e0ca                	sd	s2,64(sp)
    80003cc0:	fc4e                	sd	s3,56(sp)
    80003cc2:	f852                	sd	s4,48(sp)
    80003cc4:	f456                	sd	s5,40(sp)
    80003cc6:	f05a                	sd	s6,32(sp)
    80003cc8:	ec5e                	sd	s7,24(sp)
    80003cca:	e862                	sd	s8,16(sp)
    80003ccc:	e466                	sd	s9,8(sp)
    80003cce:	1080                	addi	s0,sp,96
    80003cd0:	84aa                	mv	s1,a0
    80003cd2:	8aae                	mv	s5,a1
    80003cd4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cd6:	00054703          	lbu	a4,0(a0)
    80003cda:	02f00793          	li	a5,47
    80003cde:	02f70363          	beq	a4,a5,80003d04 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ce2:	ffffe097          	auipc	ra,0xffffe
    80003ce6:	d26080e7          	jalr	-730(ra) # 80001a08 <myproc>
    80003cea:	15053503          	ld	a0,336(a0)
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	9f8080e7          	jalr	-1544(ra) # 800036e6 <idup>
    80003cf6:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cf8:	02f00913          	li	s2,47
  len = path - s;
    80003cfc:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003cfe:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d00:	4b85                	li	s7,1
    80003d02:	a865                	j	80003dba <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d04:	4585                	li	a1,1
    80003d06:	4505                	li	a0,1
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	6e8080e7          	jalr	1768(ra) # 800033f0 <iget>
    80003d10:	89aa                	mv	s3,a0
    80003d12:	b7dd                	j	80003cf8 <namex+0x42>
      iunlockput(ip);
    80003d14:	854e                	mv	a0,s3
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	c70080e7          	jalr	-912(ra) # 80003986 <iunlockput>
      return 0;
    80003d1e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d20:	854e                	mv	a0,s3
    80003d22:	60e6                	ld	ra,88(sp)
    80003d24:	6446                	ld	s0,80(sp)
    80003d26:	64a6                	ld	s1,72(sp)
    80003d28:	6906                	ld	s2,64(sp)
    80003d2a:	79e2                	ld	s3,56(sp)
    80003d2c:	7a42                	ld	s4,48(sp)
    80003d2e:	7aa2                	ld	s5,40(sp)
    80003d30:	7b02                	ld	s6,32(sp)
    80003d32:	6be2                	ld	s7,24(sp)
    80003d34:	6c42                	ld	s8,16(sp)
    80003d36:	6ca2                	ld	s9,8(sp)
    80003d38:	6125                	addi	sp,sp,96
    80003d3a:	8082                	ret
      iunlock(ip);
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	aa8080e7          	jalr	-1368(ra) # 800037e6 <iunlock>
      return ip;
    80003d46:	bfe9                	j	80003d20 <namex+0x6a>
      iunlockput(ip);
    80003d48:	854e                	mv	a0,s3
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	c3c080e7          	jalr	-964(ra) # 80003986 <iunlockput>
      return 0;
    80003d52:	89e6                	mv	s3,s9
    80003d54:	b7f1                	j	80003d20 <namex+0x6a>
  len = path - s;
    80003d56:	40b48633          	sub	a2,s1,a1
    80003d5a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d5e:	099c5463          	bge	s8,s9,80003de6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d62:	4639                	li	a2,14
    80003d64:	8552                	mv	a0,s4
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	ff0080e7          	jalr	-16(ra) # 80000d56 <memmove>
  while(*path == '/')
    80003d6e:	0004c783          	lbu	a5,0(s1)
    80003d72:	01279763          	bne	a5,s2,80003d80 <namex+0xca>
    path++;
    80003d76:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d78:	0004c783          	lbu	a5,0(s1)
    80003d7c:	ff278de3          	beq	a5,s2,80003d76 <namex+0xc0>
    ilock(ip);
    80003d80:	854e                	mv	a0,s3
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	9a2080e7          	jalr	-1630(ra) # 80003724 <ilock>
    if(ip->type != T_DIR){
    80003d8a:	04499783          	lh	a5,68(s3)
    80003d8e:	f97793e3          	bne	a5,s7,80003d14 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d92:	000a8563          	beqz	s5,80003d9c <namex+0xe6>
    80003d96:	0004c783          	lbu	a5,0(s1)
    80003d9a:	d3cd                	beqz	a5,80003d3c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d9c:	865a                	mv	a2,s6
    80003d9e:	85d2                	mv	a1,s4
    80003da0:	854e                	mv	a0,s3
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	e64080e7          	jalr	-412(ra) # 80003c06 <dirlookup>
    80003daa:	8caa                	mv	s9,a0
    80003dac:	dd51                	beqz	a0,80003d48 <namex+0x92>
    iunlockput(ip);
    80003dae:	854e                	mv	a0,s3
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	bd6080e7          	jalr	-1066(ra) # 80003986 <iunlockput>
    ip = next;
    80003db8:	89e6                	mv	s3,s9
  while(*path == '/')
    80003dba:	0004c783          	lbu	a5,0(s1)
    80003dbe:	05279763          	bne	a5,s2,80003e0c <namex+0x156>
    path++;
    80003dc2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc4:	0004c783          	lbu	a5,0(s1)
    80003dc8:	ff278de3          	beq	a5,s2,80003dc2 <namex+0x10c>
  if(*path == 0)
    80003dcc:	c79d                	beqz	a5,80003dfa <namex+0x144>
    path++;
    80003dce:	85a6                	mv	a1,s1
  len = path - s;
    80003dd0:	8cda                	mv	s9,s6
    80003dd2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003dd4:	01278963          	beq	a5,s2,80003de6 <namex+0x130>
    80003dd8:	dfbd                	beqz	a5,80003d56 <namex+0xa0>
    path++;
    80003dda:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ddc:	0004c783          	lbu	a5,0(s1)
    80003de0:	ff279ce3          	bne	a5,s2,80003dd8 <namex+0x122>
    80003de4:	bf8d                	j	80003d56 <namex+0xa0>
    memmove(name, s, len);
    80003de6:	2601                	sext.w	a2,a2
    80003de8:	8552                	mv	a0,s4
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	f6c080e7          	jalr	-148(ra) # 80000d56 <memmove>
    name[len] = 0;
    80003df2:	9cd2                	add	s9,s9,s4
    80003df4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003df8:	bf9d                	j	80003d6e <namex+0xb8>
  if(nameiparent){
    80003dfa:	f20a83e3          	beqz	s5,80003d20 <namex+0x6a>
    iput(ip);
    80003dfe:	854e                	mv	a0,s3
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	ade080e7          	jalr	-1314(ra) # 800038de <iput>
    return 0;
    80003e08:	4981                	li	s3,0
    80003e0a:	bf19                	j	80003d20 <namex+0x6a>
  if(*path == 0)
    80003e0c:	d7fd                	beqz	a5,80003dfa <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	85a6                	mv	a1,s1
    80003e14:	b7d1                	j	80003dd8 <namex+0x122>

0000000080003e16 <dirlink>:
{
    80003e16:	7139                	addi	sp,sp,-64
    80003e18:	fc06                	sd	ra,56(sp)
    80003e1a:	f822                	sd	s0,48(sp)
    80003e1c:	f426                	sd	s1,40(sp)
    80003e1e:	f04a                	sd	s2,32(sp)
    80003e20:	ec4e                	sd	s3,24(sp)
    80003e22:	e852                	sd	s4,16(sp)
    80003e24:	0080                	addi	s0,sp,64
    80003e26:	892a                	mv	s2,a0
    80003e28:	8a2e                	mv	s4,a1
    80003e2a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e2c:	4601                	li	a2,0
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	dd8080e7          	jalr	-552(ra) # 80003c06 <dirlookup>
    80003e36:	e93d                	bnez	a0,80003eac <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e38:	04c92483          	lw	s1,76(s2)
    80003e3c:	c49d                	beqz	s1,80003e6a <dirlink+0x54>
    80003e3e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e40:	4741                	li	a4,16
    80003e42:	86a6                	mv	a3,s1
    80003e44:	fc040613          	addi	a2,s0,-64
    80003e48:	4581                	li	a1,0
    80003e4a:	854a                	mv	a0,s2
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	b8c080e7          	jalr	-1140(ra) # 800039d8 <readi>
    80003e54:	47c1                	li	a5,16
    80003e56:	06f51163          	bne	a0,a5,80003eb8 <dirlink+0xa2>
    if(de.inum == 0)
    80003e5a:	fc045783          	lhu	a5,-64(s0)
    80003e5e:	c791                	beqz	a5,80003e6a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e60:	24c1                	addiw	s1,s1,16
    80003e62:	04c92783          	lw	a5,76(s2)
    80003e66:	fcf4ede3          	bltu	s1,a5,80003e40 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e6a:	4639                	li	a2,14
    80003e6c:	85d2                	mv	a1,s4
    80003e6e:	fc240513          	addi	a0,s0,-62
    80003e72:	ffffd097          	auipc	ra,0xffffd
    80003e76:	f9c080e7          	jalr	-100(ra) # 80000e0e <strncpy>
  de.inum = inum;
    80003e7a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e7e:	4741                	li	a4,16
    80003e80:	86a6                	mv	a3,s1
    80003e82:	fc040613          	addi	a2,s0,-64
    80003e86:	4581                	li	a1,0
    80003e88:	854a                	mv	a0,s2
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	c46080e7          	jalr	-954(ra) # 80003ad0 <writei>
    80003e92:	872a                	mv	a4,a0
    80003e94:	47c1                	li	a5,16
  return 0;
    80003e96:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e98:	02f71863          	bne	a4,a5,80003ec8 <dirlink+0xb2>
}
    80003e9c:	70e2                	ld	ra,56(sp)
    80003e9e:	7442                	ld	s0,48(sp)
    80003ea0:	74a2                	ld	s1,40(sp)
    80003ea2:	7902                	ld	s2,32(sp)
    80003ea4:	69e2                	ld	s3,24(sp)
    80003ea6:	6a42                	ld	s4,16(sp)
    80003ea8:	6121                	addi	sp,sp,64
    80003eaa:	8082                	ret
    iput(ip);
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	a32080e7          	jalr	-1486(ra) # 800038de <iput>
    return -1;
    80003eb4:	557d                	li	a0,-1
    80003eb6:	b7dd                	j	80003e9c <dirlink+0x86>
      panic("dirlink read");
    80003eb8:	00004517          	auipc	a0,0x4
    80003ebc:	6f050513          	addi	a0,a0,1776 # 800085a8 <syscalls+0x1c8>
    80003ec0:	ffffc097          	auipc	ra,0xffffc
    80003ec4:	682080e7          	jalr	1666(ra) # 80000542 <panic>
    panic("dirlink");
    80003ec8:	00005517          	auipc	a0,0x5
    80003ecc:	80050513          	addi	a0,a0,-2048 # 800086c8 <syscalls+0x2e8>
    80003ed0:	ffffc097          	auipc	ra,0xffffc
    80003ed4:	672080e7          	jalr	1650(ra) # 80000542 <panic>

0000000080003ed8 <namei>:

struct inode*
namei(char *path)
{
    80003ed8:	1101                	addi	sp,sp,-32
    80003eda:	ec06                	sd	ra,24(sp)
    80003edc:	e822                	sd	s0,16(sp)
    80003ede:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ee0:	fe040613          	addi	a2,s0,-32
    80003ee4:	4581                	li	a1,0
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	dd0080e7          	jalr	-560(ra) # 80003cb6 <namex>
}
    80003eee:	60e2                	ld	ra,24(sp)
    80003ef0:	6442                	ld	s0,16(sp)
    80003ef2:	6105                	addi	sp,sp,32
    80003ef4:	8082                	ret

0000000080003ef6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ef6:	1141                	addi	sp,sp,-16
    80003ef8:	e406                	sd	ra,8(sp)
    80003efa:	e022                	sd	s0,0(sp)
    80003efc:	0800                	addi	s0,sp,16
    80003efe:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f00:	4585                	li	a1,1
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	db4080e7          	jalr	-588(ra) # 80003cb6 <namex>
}
    80003f0a:	60a2                	ld	ra,8(sp)
    80003f0c:	6402                	ld	s0,0(sp)
    80003f0e:	0141                	addi	sp,sp,16
    80003f10:	8082                	ret

0000000080003f12 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f12:	1101                	addi	sp,sp,-32
    80003f14:	ec06                	sd	ra,24(sp)
    80003f16:	e822                	sd	s0,16(sp)
    80003f18:	e426                	sd	s1,8(sp)
    80003f1a:	e04a                	sd	s2,0(sp)
    80003f1c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f1e:	0001e917          	auipc	s2,0x1e
    80003f22:	9ea90913          	addi	s2,s2,-1558 # 80021908 <log>
    80003f26:	01892583          	lw	a1,24(s2)
    80003f2a:	02892503          	lw	a0,40(s2)
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	ff4080e7          	jalr	-12(ra) # 80002f22 <bread>
    80003f36:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f38:	02c92683          	lw	a3,44(s2)
    80003f3c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f3e:	02d05763          	blez	a3,80003f6c <write_head+0x5a>
    80003f42:	0001e797          	auipc	a5,0x1e
    80003f46:	9f678793          	addi	a5,a5,-1546 # 80021938 <log+0x30>
    80003f4a:	05c50713          	addi	a4,a0,92
    80003f4e:	36fd                	addiw	a3,a3,-1
    80003f50:	1682                	slli	a3,a3,0x20
    80003f52:	9281                	srli	a3,a3,0x20
    80003f54:	068a                	slli	a3,a3,0x2
    80003f56:	0001e617          	auipc	a2,0x1e
    80003f5a:	9e660613          	addi	a2,a2,-1562 # 8002193c <log+0x34>
    80003f5e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f60:	4390                	lw	a2,0(a5)
    80003f62:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f64:	0791                	addi	a5,a5,4
    80003f66:	0711                	addi	a4,a4,4
    80003f68:	fed79ce3          	bne	a5,a3,80003f60 <write_head+0x4e>
  }
  bwrite(buf);
    80003f6c:	8526                	mv	a0,s1
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	0a6080e7          	jalr	166(ra) # 80003014 <bwrite>
  brelse(buf);
    80003f76:	8526                	mv	a0,s1
    80003f78:	fffff097          	auipc	ra,0xfffff
    80003f7c:	0da080e7          	jalr	218(ra) # 80003052 <brelse>
}
    80003f80:	60e2                	ld	ra,24(sp)
    80003f82:	6442                	ld	s0,16(sp)
    80003f84:	64a2                	ld	s1,8(sp)
    80003f86:	6902                	ld	s2,0(sp)
    80003f88:	6105                	addi	sp,sp,32
    80003f8a:	8082                	ret

0000000080003f8c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f8c:	0001e797          	auipc	a5,0x1e
    80003f90:	9a87a783          	lw	a5,-1624(a5) # 80021934 <log+0x2c>
    80003f94:	0af05663          	blez	a5,80004040 <install_trans+0xb4>
{
    80003f98:	7139                	addi	sp,sp,-64
    80003f9a:	fc06                	sd	ra,56(sp)
    80003f9c:	f822                	sd	s0,48(sp)
    80003f9e:	f426                	sd	s1,40(sp)
    80003fa0:	f04a                	sd	s2,32(sp)
    80003fa2:	ec4e                	sd	s3,24(sp)
    80003fa4:	e852                	sd	s4,16(sp)
    80003fa6:	e456                	sd	s5,8(sp)
    80003fa8:	0080                	addi	s0,sp,64
    80003faa:	0001ea97          	auipc	s5,0x1e
    80003fae:	98ea8a93          	addi	s5,s5,-1650 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fb2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fb4:	0001e997          	auipc	s3,0x1e
    80003fb8:	95498993          	addi	s3,s3,-1708 # 80021908 <log>
    80003fbc:	0189a583          	lw	a1,24(s3)
    80003fc0:	014585bb          	addw	a1,a1,s4
    80003fc4:	2585                	addiw	a1,a1,1
    80003fc6:	0289a503          	lw	a0,40(s3)
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	f58080e7          	jalr	-168(ra) # 80002f22 <bread>
    80003fd2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fd4:	000aa583          	lw	a1,0(s5)
    80003fd8:	0289a503          	lw	a0,40(s3)
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	f46080e7          	jalr	-186(ra) # 80002f22 <bread>
    80003fe4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fe6:	40000613          	li	a2,1024
    80003fea:	05890593          	addi	a1,s2,88
    80003fee:	05850513          	addi	a0,a0,88
    80003ff2:	ffffd097          	auipc	ra,0xffffd
    80003ff6:	d64080e7          	jalr	-668(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	018080e7          	jalr	24(ra) # 80003014 <bwrite>
    bunpin(dbuf);
    80004004:	8526                	mv	a0,s1
    80004006:	fffff097          	auipc	ra,0xfffff
    8000400a:	126080e7          	jalr	294(ra) # 8000312c <bunpin>
    brelse(lbuf);
    8000400e:	854a                	mv	a0,s2
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	042080e7          	jalr	66(ra) # 80003052 <brelse>
    brelse(dbuf);
    80004018:	8526                	mv	a0,s1
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	038080e7          	jalr	56(ra) # 80003052 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004022:	2a05                	addiw	s4,s4,1
    80004024:	0a91                	addi	s5,s5,4
    80004026:	02c9a783          	lw	a5,44(s3)
    8000402a:	f8fa49e3          	blt	s4,a5,80003fbc <install_trans+0x30>
}
    8000402e:	70e2                	ld	ra,56(sp)
    80004030:	7442                	ld	s0,48(sp)
    80004032:	74a2                	ld	s1,40(sp)
    80004034:	7902                	ld	s2,32(sp)
    80004036:	69e2                	ld	s3,24(sp)
    80004038:	6a42                	ld	s4,16(sp)
    8000403a:	6aa2                	ld	s5,8(sp)
    8000403c:	6121                	addi	sp,sp,64
    8000403e:	8082                	ret
    80004040:	8082                	ret

0000000080004042 <initlog>:
{
    80004042:	7179                	addi	sp,sp,-48
    80004044:	f406                	sd	ra,40(sp)
    80004046:	f022                	sd	s0,32(sp)
    80004048:	ec26                	sd	s1,24(sp)
    8000404a:	e84a                	sd	s2,16(sp)
    8000404c:	e44e                	sd	s3,8(sp)
    8000404e:	1800                	addi	s0,sp,48
    80004050:	892a                	mv	s2,a0
    80004052:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004054:	0001e497          	auipc	s1,0x1e
    80004058:	8b448493          	addi	s1,s1,-1868 # 80021908 <log>
    8000405c:	00004597          	auipc	a1,0x4
    80004060:	55c58593          	addi	a1,a1,1372 # 800085b8 <syscalls+0x1d8>
    80004064:	8526                	mv	a0,s1
    80004066:	ffffd097          	auipc	ra,0xffffd
    8000406a:	b08080e7          	jalr	-1272(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    8000406e:	0149a583          	lw	a1,20(s3)
    80004072:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004074:	0109a783          	lw	a5,16(s3)
    80004078:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000407a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000407e:	854a                	mv	a0,s2
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	ea2080e7          	jalr	-350(ra) # 80002f22 <bread>
  log.lh.n = lh->n;
    80004088:	4d34                	lw	a3,88(a0)
    8000408a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000408c:	02d05563          	blez	a3,800040b6 <initlog+0x74>
    80004090:	05c50793          	addi	a5,a0,92
    80004094:	0001e717          	auipc	a4,0x1e
    80004098:	8a470713          	addi	a4,a4,-1884 # 80021938 <log+0x30>
    8000409c:	36fd                	addiw	a3,a3,-1
    8000409e:	1682                	slli	a3,a3,0x20
    800040a0:	9281                	srli	a3,a3,0x20
    800040a2:	068a                	slli	a3,a3,0x2
    800040a4:	06050613          	addi	a2,a0,96
    800040a8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800040aa:	4390                	lw	a2,0(a5)
    800040ac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040ae:	0791                	addi	a5,a5,4
    800040b0:	0711                	addi	a4,a4,4
    800040b2:	fed79ce3          	bne	a5,a3,800040aa <initlog+0x68>
  brelse(buf);
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	f9c080e7          	jalr	-100(ra) # 80003052 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	ece080e7          	jalr	-306(ra) # 80003f8c <install_trans>
  log.lh.n = 0;
    800040c6:	0001e797          	auipc	a5,0x1e
    800040ca:	8607a723          	sw	zero,-1938(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040ce:	00000097          	auipc	ra,0x0
    800040d2:	e44080e7          	jalr	-444(ra) # 80003f12 <write_head>
}
    800040d6:	70a2                	ld	ra,40(sp)
    800040d8:	7402                	ld	s0,32(sp)
    800040da:	64e2                	ld	s1,24(sp)
    800040dc:	6942                	ld	s2,16(sp)
    800040de:	69a2                	ld	s3,8(sp)
    800040e0:	6145                	addi	sp,sp,48
    800040e2:	8082                	ret

00000000800040e4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040e4:	1101                	addi	sp,sp,-32
    800040e6:	ec06                	sd	ra,24(sp)
    800040e8:	e822                	sd	s0,16(sp)
    800040ea:	e426                	sd	s1,8(sp)
    800040ec:	e04a                	sd	s2,0(sp)
    800040ee:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040f0:	0001e517          	auipc	a0,0x1e
    800040f4:	81850513          	addi	a0,a0,-2024 # 80021908 <log>
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	b06080e7          	jalr	-1274(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    80004100:	0001e497          	auipc	s1,0x1e
    80004104:	80848493          	addi	s1,s1,-2040 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004108:	4979                	li	s2,30
    8000410a:	a039                	j	80004118 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000410c:	85a6                	mv	a1,s1
    8000410e:	8526                	mv	a0,s1
    80004110:	ffffe097          	auipc	ra,0xffffe
    80004114:	10c080e7          	jalr	268(ra) # 8000221c <sleep>
    if(log.committing){
    80004118:	50dc                	lw	a5,36(s1)
    8000411a:	fbed                	bnez	a5,8000410c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411c:	509c                	lw	a5,32(s1)
    8000411e:	0017871b          	addiw	a4,a5,1
    80004122:	0007069b          	sext.w	a3,a4
    80004126:	0027179b          	slliw	a5,a4,0x2
    8000412a:	9fb9                	addw	a5,a5,a4
    8000412c:	0017979b          	slliw	a5,a5,0x1
    80004130:	54d8                	lw	a4,44(s1)
    80004132:	9fb9                	addw	a5,a5,a4
    80004134:	00f95963          	bge	s2,a5,80004146 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004138:	85a6                	mv	a1,s1
    8000413a:	8526                	mv	a0,s1
    8000413c:	ffffe097          	auipc	ra,0xffffe
    80004140:	0e0080e7          	jalr	224(ra) # 8000221c <sleep>
    80004144:	bfd1                	j	80004118 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004146:	0001d517          	auipc	a0,0x1d
    8000414a:	7c250513          	addi	a0,a0,1986 # 80021908 <log>
    8000414e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004150:	ffffd097          	auipc	ra,0xffffd
    80004154:	b62080e7          	jalr	-1182(ra) # 80000cb2 <release>
      break;
    }
  }
}
    80004158:	60e2                	ld	ra,24(sp)
    8000415a:	6442                	ld	s0,16(sp)
    8000415c:	64a2                	ld	s1,8(sp)
    8000415e:	6902                	ld	s2,0(sp)
    80004160:	6105                	addi	sp,sp,32
    80004162:	8082                	ret

0000000080004164 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004164:	7139                	addi	sp,sp,-64
    80004166:	fc06                	sd	ra,56(sp)
    80004168:	f822                	sd	s0,48(sp)
    8000416a:	f426                	sd	s1,40(sp)
    8000416c:	f04a                	sd	s2,32(sp)
    8000416e:	ec4e                	sd	s3,24(sp)
    80004170:	e852                	sd	s4,16(sp)
    80004172:	e456                	sd	s5,8(sp)
    80004174:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004176:	0001d497          	auipc	s1,0x1d
    8000417a:	79248493          	addi	s1,s1,1938 # 80021908 <log>
    8000417e:	8526                	mv	a0,s1
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	a7e080e7          	jalr	-1410(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    80004188:	509c                	lw	a5,32(s1)
    8000418a:	37fd                	addiw	a5,a5,-1
    8000418c:	0007891b          	sext.w	s2,a5
    80004190:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004192:	50dc                	lw	a5,36(s1)
    80004194:	e7b9                	bnez	a5,800041e2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004196:	04091e63          	bnez	s2,800041f2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000419a:	0001d497          	auipc	s1,0x1d
    8000419e:	76e48493          	addi	s1,s1,1902 # 80021908 <log>
    800041a2:	4785                	li	a5,1
    800041a4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	b0a080e7          	jalr	-1270(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041b0:	54dc                	lw	a5,44(s1)
    800041b2:	06f04763          	bgtz	a5,80004220 <end_op+0xbc>
    acquire(&log.lock);
    800041b6:	0001d497          	auipc	s1,0x1d
    800041ba:	75248493          	addi	s1,s1,1874 # 80021908 <log>
    800041be:	8526                	mv	a0,s1
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	a3e080e7          	jalr	-1474(ra) # 80000bfe <acquire>
    log.committing = 0;
    800041c8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041cc:	8526                	mv	a0,s1
    800041ce:	ffffe097          	auipc	ra,0xffffe
    800041d2:	1ce080e7          	jalr	462(ra) # 8000239c <wakeup>
    release(&log.lock);
    800041d6:	8526                	mv	a0,s1
    800041d8:	ffffd097          	auipc	ra,0xffffd
    800041dc:	ada080e7          	jalr	-1318(ra) # 80000cb2 <release>
}
    800041e0:	a03d                	j	8000420e <end_op+0xaa>
    panic("log.committing");
    800041e2:	00004517          	auipc	a0,0x4
    800041e6:	3de50513          	addi	a0,a0,990 # 800085c0 <syscalls+0x1e0>
    800041ea:	ffffc097          	auipc	ra,0xffffc
    800041ee:	358080e7          	jalr	856(ra) # 80000542 <panic>
    wakeup(&log);
    800041f2:	0001d497          	auipc	s1,0x1d
    800041f6:	71648493          	addi	s1,s1,1814 # 80021908 <log>
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffe097          	auipc	ra,0xffffe
    80004200:	1a0080e7          	jalr	416(ra) # 8000239c <wakeup>
  release(&log.lock);
    80004204:	8526                	mv	a0,s1
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	aac080e7          	jalr	-1364(ra) # 80000cb2 <release>
}
    8000420e:	70e2                	ld	ra,56(sp)
    80004210:	7442                	ld	s0,48(sp)
    80004212:	74a2                	ld	s1,40(sp)
    80004214:	7902                	ld	s2,32(sp)
    80004216:	69e2                	ld	s3,24(sp)
    80004218:	6a42                	ld	s4,16(sp)
    8000421a:	6aa2                	ld	s5,8(sp)
    8000421c:	6121                	addi	sp,sp,64
    8000421e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004220:	0001da97          	auipc	s5,0x1d
    80004224:	718a8a93          	addi	s5,s5,1816 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004228:	0001da17          	auipc	s4,0x1d
    8000422c:	6e0a0a13          	addi	s4,s4,1760 # 80021908 <log>
    80004230:	018a2583          	lw	a1,24(s4)
    80004234:	012585bb          	addw	a1,a1,s2
    80004238:	2585                	addiw	a1,a1,1
    8000423a:	028a2503          	lw	a0,40(s4)
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	ce4080e7          	jalr	-796(ra) # 80002f22 <bread>
    80004246:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004248:	000aa583          	lw	a1,0(s5)
    8000424c:	028a2503          	lw	a0,40(s4)
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	cd2080e7          	jalr	-814(ra) # 80002f22 <bread>
    80004258:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000425a:	40000613          	li	a2,1024
    8000425e:	05850593          	addi	a1,a0,88
    80004262:	05848513          	addi	a0,s1,88
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	af0080e7          	jalr	-1296(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	da4080e7          	jalr	-604(ra) # 80003014 <bwrite>
    brelse(from);
    80004278:	854e                	mv	a0,s3
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	dd8080e7          	jalr	-552(ra) # 80003052 <brelse>
    brelse(to);
    80004282:	8526                	mv	a0,s1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	dce080e7          	jalr	-562(ra) # 80003052 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428c:	2905                	addiw	s2,s2,1
    8000428e:	0a91                	addi	s5,s5,4
    80004290:	02ca2783          	lw	a5,44(s4)
    80004294:	f8f94ee3          	blt	s2,a5,80004230 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	c7a080e7          	jalr	-902(ra) # 80003f12 <write_head>
    install_trans(); // Now install writes to home locations
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	cec080e7          	jalr	-788(ra) # 80003f8c <install_trans>
    log.lh.n = 0;
    800042a8:	0001d797          	auipc	a5,0x1d
    800042ac:	6807a623          	sw	zero,1676(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042b0:	00000097          	auipc	ra,0x0
    800042b4:	c62080e7          	jalr	-926(ra) # 80003f12 <write_head>
    800042b8:	bdfd                	j	800041b6 <end_op+0x52>

00000000800042ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042ba:	1101                	addi	sp,sp,-32
    800042bc:	ec06                	sd	ra,24(sp)
    800042be:	e822                	sd	s0,16(sp)
    800042c0:	e426                	sd	s1,8(sp)
    800042c2:	e04a                	sd	s2,0(sp)
    800042c4:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042c6:	0001d717          	auipc	a4,0x1d
    800042ca:	66e72703          	lw	a4,1646(a4) # 80021934 <log+0x2c>
    800042ce:	47f5                	li	a5,29
    800042d0:	08e7c063          	blt	a5,a4,80004350 <log_write+0x96>
    800042d4:	84aa                	mv	s1,a0
    800042d6:	0001d797          	auipc	a5,0x1d
    800042da:	64e7a783          	lw	a5,1614(a5) # 80021924 <log+0x1c>
    800042de:	37fd                	addiw	a5,a5,-1
    800042e0:	06f75863          	bge	a4,a5,80004350 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042e4:	0001d797          	auipc	a5,0x1d
    800042e8:	6447a783          	lw	a5,1604(a5) # 80021928 <log+0x20>
    800042ec:	06f05a63          	blez	a5,80004360 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800042f0:	0001d917          	auipc	s2,0x1d
    800042f4:	61890913          	addi	s2,s2,1560 # 80021908 <log>
    800042f8:	854a                	mv	a0,s2
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	904080e7          	jalr	-1788(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004302:	02c92603          	lw	a2,44(s2)
    80004306:	06c05563          	blez	a2,80004370 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000430a:	44cc                	lw	a1,12(s1)
    8000430c:	0001d717          	auipc	a4,0x1d
    80004310:	62c70713          	addi	a4,a4,1580 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004314:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004316:	4314                	lw	a3,0(a4)
    80004318:	04b68d63          	beq	a3,a1,80004372 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000431c:	2785                	addiw	a5,a5,1
    8000431e:	0711                	addi	a4,a4,4
    80004320:	fec79be3          	bne	a5,a2,80004316 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004324:	0621                	addi	a2,a2,8
    80004326:	060a                	slli	a2,a2,0x2
    80004328:	0001d797          	auipc	a5,0x1d
    8000432c:	5e078793          	addi	a5,a5,1504 # 80021908 <log>
    80004330:	963e                	add	a2,a2,a5
    80004332:	44dc                	lw	a5,12(s1)
    80004334:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004336:	8526                	mv	a0,s1
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	db8080e7          	jalr	-584(ra) # 800030f0 <bpin>
    log.lh.n++;
    80004340:	0001d717          	auipc	a4,0x1d
    80004344:	5c870713          	addi	a4,a4,1480 # 80021908 <log>
    80004348:	575c                	lw	a5,44(a4)
    8000434a:	2785                	addiw	a5,a5,1
    8000434c:	d75c                	sw	a5,44(a4)
    8000434e:	a83d                	j	8000438c <log_write+0xd2>
    panic("too big a transaction");
    80004350:	00004517          	auipc	a0,0x4
    80004354:	28050513          	addi	a0,a0,640 # 800085d0 <syscalls+0x1f0>
    80004358:	ffffc097          	auipc	ra,0xffffc
    8000435c:	1ea080e7          	jalr	490(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004360:	00004517          	auipc	a0,0x4
    80004364:	28850513          	addi	a0,a0,648 # 800085e8 <syscalls+0x208>
    80004368:	ffffc097          	auipc	ra,0xffffc
    8000436c:	1da080e7          	jalr	474(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004370:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004372:	00878713          	addi	a4,a5,8
    80004376:	00271693          	slli	a3,a4,0x2
    8000437a:	0001d717          	auipc	a4,0x1d
    8000437e:	58e70713          	addi	a4,a4,1422 # 80021908 <log>
    80004382:	9736                	add	a4,a4,a3
    80004384:	44d4                	lw	a3,12(s1)
    80004386:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004388:	faf607e3          	beq	a2,a5,80004336 <log_write+0x7c>
  }
  release(&log.lock);
    8000438c:	0001d517          	auipc	a0,0x1d
    80004390:	57c50513          	addi	a0,a0,1404 # 80021908 <log>
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	91e080e7          	jalr	-1762(ra) # 80000cb2 <release>
}
    8000439c:	60e2                	ld	ra,24(sp)
    8000439e:	6442                	ld	s0,16(sp)
    800043a0:	64a2                	ld	s1,8(sp)
    800043a2:	6902                	ld	s2,0(sp)
    800043a4:	6105                	addi	sp,sp,32
    800043a6:	8082                	ret

00000000800043a8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043a8:	1101                	addi	sp,sp,-32
    800043aa:	ec06                	sd	ra,24(sp)
    800043ac:	e822                	sd	s0,16(sp)
    800043ae:	e426                	sd	s1,8(sp)
    800043b0:	e04a                	sd	s2,0(sp)
    800043b2:	1000                	addi	s0,sp,32
    800043b4:	84aa                	mv	s1,a0
    800043b6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043b8:	00004597          	auipc	a1,0x4
    800043bc:	25058593          	addi	a1,a1,592 # 80008608 <syscalls+0x228>
    800043c0:	0521                	addi	a0,a0,8
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	7ac080e7          	jalr	1964(ra) # 80000b6e <initlock>
  lk->name = name;
    800043ca:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043ce:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043d2:	0204a423          	sw	zero,40(s1)
}
    800043d6:	60e2                	ld	ra,24(sp)
    800043d8:	6442                	ld	s0,16(sp)
    800043da:	64a2                	ld	s1,8(sp)
    800043dc:	6902                	ld	s2,0(sp)
    800043de:	6105                	addi	sp,sp,32
    800043e0:	8082                	ret

00000000800043e2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043e2:	1101                	addi	sp,sp,-32
    800043e4:	ec06                	sd	ra,24(sp)
    800043e6:	e822                	sd	s0,16(sp)
    800043e8:	e426                	sd	s1,8(sp)
    800043ea:	e04a                	sd	s2,0(sp)
    800043ec:	1000                	addi	s0,sp,32
    800043ee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043f0:	00850913          	addi	s2,a0,8
    800043f4:	854a                	mv	a0,s2
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	808080e7          	jalr	-2040(ra) # 80000bfe <acquire>
  while (lk->locked) {
    800043fe:	409c                	lw	a5,0(s1)
    80004400:	cb89                	beqz	a5,80004412 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004402:	85ca                	mv	a1,s2
    80004404:	8526                	mv	a0,s1
    80004406:	ffffe097          	auipc	ra,0xffffe
    8000440a:	e16080e7          	jalr	-490(ra) # 8000221c <sleep>
  while (lk->locked) {
    8000440e:	409c                	lw	a5,0(s1)
    80004410:	fbed                	bnez	a5,80004402 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004412:	4785                	li	a5,1
    80004414:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	5f2080e7          	jalr	1522(ra) # 80001a08 <myproc>
    8000441e:	5d1c                	lw	a5,56(a0)
    80004420:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004422:	854a                	mv	a0,s2
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	88e080e7          	jalr	-1906(ra) # 80000cb2 <release>
}
    8000442c:	60e2                	ld	ra,24(sp)
    8000442e:	6442                	ld	s0,16(sp)
    80004430:	64a2                	ld	s1,8(sp)
    80004432:	6902                	ld	s2,0(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004438:	1101                	addi	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	e426                	sd	s1,8(sp)
    80004440:	e04a                	sd	s2,0(sp)
    80004442:	1000                	addi	s0,sp,32
    80004444:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004446:	00850913          	addi	s2,a0,8
    8000444a:	854a                	mv	a0,s2
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	7b2080e7          	jalr	1970(ra) # 80000bfe <acquire>
  lk->locked = 0;
    80004454:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004458:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffe097          	auipc	ra,0xffffe
    80004462:	f3e080e7          	jalr	-194(ra) # 8000239c <wakeup>
  release(&lk->lk);
    80004466:	854a                	mv	a0,s2
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	84a080e7          	jalr	-1974(ra) # 80000cb2 <release>
}
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6902                	ld	s2,0(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret

000000008000447c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000447c:	7179                	addi	sp,sp,-48
    8000447e:	f406                	sd	ra,40(sp)
    80004480:	f022                	sd	s0,32(sp)
    80004482:	ec26                	sd	s1,24(sp)
    80004484:	e84a                	sd	s2,16(sp)
    80004486:	e44e                	sd	s3,8(sp)
    80004488:	1800                	addi	s0,sp,48
    8000448a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000448c:	00850913          	addi	s2,a0,8
    80004490:	854a                	mv	a0,s2
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	76c080e7          	jalr	1900(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000449a:	409c                	lw	a5,0(s1)
    8000449c:	ef99                	bnez	a5,800044ba <holdingsleep+0x3e>
    8000449e:	4481                	li	s1,0
  release(&lk->lk);
    800044a0:	854a                	mv	a0,s2
    800044a2:	ffffd097          	auipc	ra,0xffffd
    800044a6:	810080e7          	jalr	-2032(ra) # 80000cb2 <release>
  return r;
}
    800044aa:	8526                	mv	a0,s1
    800044ac:	70a2                	ld	ra,40(sp)
    800044ae:	7402                	ld	s0,32(sp)
    800044b0:	64e2                	ld	s1,24(sp)
    800044b2:	6942                	ld	s2,16(sp)
    800044b4:	69a2                	ld	s3,8(sp)
    800044b6:	6145                	addi	sp,sp,48
    800044b8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ba:	0284a983          	lw	s3,40(s1)
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	54a080e7          	jalr	1354(ra) # 80001a08 <myproc>
    800044c6:	5d04                	lw	s1,56(a0)
    800044c8:	413484b3          	sub	s1,s1,s3
    800044cc:	0014b493          	seqz	s1,s1
    800044d0:	bfc1                	j	800044a0 <holdingsleep+0x24>

00000000800044d2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044d2:	1141                	addi	sp,sp,-16
    800044d4:	e406                	sd	ra,8(sp)
    800044d6:	e022                	sd	s0,0(sp)
    800044d8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044da:	00004597          	auipc	a1,0x4
    800044de:	13e58593          	addi	a1,a1,318 # 80008618 <syscalls+0x238>
    800044e2:	0001d517          	auipc	a0,0x1d
    800044e6:	56e50513          	addi	a0,a0,1390 # 80021a50 <ftable>
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	684080e7          	jalr	1668(ra) # 80000b6e <initlock>
}
    800044f2:	60a2                	ld	ra,8(sp)
    800044f4:	6402                	ld	s0,0(sp)
    800044f6:	0141                	addi	sp,sp,16
    800044f8:	8082                	ret

00000000800044fa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044fa:	1101                	addi	sp,sp,-32
    800044fc:	ec06                	sd	ra,24(sp)
    800044fe:	e822                	sd	s0,16(sp)
    80004500:	e426                	sd	s1,8(sp)
    80004502:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004504:	0001d517          	auipc	a0,0x1d
    80004508:	54c50513          	addi	a0,a0,1356 # 80021a50 <ftable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	6f2080e7          	jalr	1778(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004514:	0001d497          	auipc	s1,0x1d
    80004518:	55448493          	addi	s1,s1,1364 # 80021a68 <ftable+0x18>
    8000451c:	0001e717          	auipc	a4,0x1e
    80004520:	4ec70713          	addi	a4,a4,1260 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004524:	40dc                	lw	a5,4(s1)
    80004526:	cf99                	beqz	a5,80004544 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004528:	02848493          	addi	s1,s1,40
    8000452c:	fee49ce3          	bne	s1,a4,80004524 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004530:	0001d517          	auipc	a0,0x1d
    80004534:	52050513          	addi	a0,a0,1312 # 80021a50 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	77a080e7          	jalr	1914(ra) # 80000cb2 <release>
  return 0;
    80004540:	4481                	li	s1,0
    80004542:	a819                	j	80004558 <filealloc+0x5e>
      f->ref = 1;
    80004544:	4785                	li	a5,1
    80004546:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004548:	0001d517          	auipc	a0,0x1d
    8000454c:	50850513          	addi	a0,a0,1288 # 80021a50 <ftable>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	762080e7          	jalr	1890(ra) # 80000cb2 <release>
}
    80004558:	8526                	mv	a0,s1
    8000455a:	60e2                	ld	ra,24(sp)
    8000455c:	6442                	ld	s0,16(sp)
    8000455e:	64a2                	ld	s1,8(sp)
    80004560:	6105                	addi	sp,sp,32
    80004562:	8082                	ret

0000000080004564 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	e426                	sd	s1,8(sp)
    8000456c:	1000                	addi	s0,sp,32
    8000456e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	4e050513          	addi	a0,a0,1248 # 80021a50 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	686080e7          	jalr	1670(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004580:	40dc                	lw	a5,4(s1)
    80004582:	02f05263          	blez	a5,800045a6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004586:	2785                	addiw	a5,a5,1
    80004588:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000458a:	0001d517          	auipc	a0,0x1d
    8000458e:	4c650513          	addi	a0,a0,1222 # 80021a50 <ftable>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	720080e7          	jalr	1824(ra) # 80000cb2 <release>
  return f;
}
    8000459a:	8526                	mv	a0,s1
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret
    panic("filedup");
    800045a6:	00004517          	auipc	a0,0x4
    800045aa:	07a50513          	addi	a0,a0,122 # 80008620 <syscalls+0x240>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	f94080e7          	jalr	-108(ra) # 80000542 <panic>

00000000800045b6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045b6:	7139                	addi	sp,sp,-64
    800045b8:	fc06                	sd	ra,56(sp)
    800045ba:	f822                	sd	s0,48(sp)
    800045bc:	f426                	sd	s1,40(sp)
    800045be:	f04a                	sd	s2,32(sp)
    800045c0:	ec4e                	sd	s3,24(sp)
    800045c2:	e852                	sd	s4,16(sp)
    800045c4:	e456                	sd	s5,8(sp)
    800045c6:	0080                	addi	s0,sp,64
    800045c8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ca:	0001d517          	auipc	a0,0x1d
    800045ce:	48650513          	addi	a0,a0,1158 # 80021a50 <ftable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	62c080e7          	jalr	1580(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    800045da:	40dc                	lw	a5,4(s1)
    800045dc:	06f05163          	blez	a5,8000463e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045e0:	37fd                	addiw	a5,a5,-1
    800045e2:	0007871b          	sext.w	a4,a5
    800045e6:	c0dc                	sw	a5,4(s1)
    800045e8:	06e04363          	bgtz	a4,8000464e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045ec:	0004a903          	lw	s2,0(s1)
    800045f0:	0094ca83          	lbu	s5,9(s1)
    800045f4:	0104ba03          	ld	s4,16(s1)
    800045f8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045fc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004600:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004604:	0001d517          	auipc	a0,0x1d
    80004608:	44c50513          	addi	a0,a0,1100 # 80021a50 <ftable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	6a6080e7          	jalr	1702(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    80004614:	4785                	li	a5,1
    80004616:	04f90d63          	beq	s2,a5,80004670 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000461a:	3979                	addiw	s2,s2,-2
    8000461c:	4785                	li	a5,1
    8000461e:	0527e063          	bltu	a5,s2,8000465e <fileclose+0xa8>
    begin_op();
    80004622:	00000097          	auipc	ra,0x0
    80004626:	ac2080e7          	jalr	-1342(ra) # 800040e4 <begin_op>
    iput(ff.ip);
    8000462a:	854e                	mv	a0,s3
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	2b2080e7          	jalr	690(ra) # 800038de <iput>
    end_op();
    80004634:	00000097          	auipc	ra,0x0
    80004638:	b30080e7          	jalr	-1232(ra) # 80004164 <end_op>
    8000463c:	a00d                	j	8000465e <fileclose+0xa8>
    panic("fileclose");
    8000463e:	00004517          	auipc	a0,0x4
    80004642:	fea50513          	addi	a0,a0,-22 # 80008628 <syscalls+0x248>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	efc080e7          	jalr	-260(ra) # 80000542 <panic>
    release(&ftable.lock);
    8000464e:	0001d517          	auipc	a0,0x1d
    80004652:	40250513          	addi	a0,a0,1026 # 80021a50 <ftable>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	65c080e7          	jalr	1628(ra) # 80000cb2 <release>
  }
}
    8000465e:	70e2                	ld	ra,56(sp)
    80004660:	7442                	ld	s0,48(sp)
    80004662:	74a2                	ld	s1,40(sp)
    80004664:	7902                	ld	s2,32(sp)
    80004666:	69e2                	ld	s3,24(sp)
    80004668:	6a42                	ld	s4,16(sp)
    8000466a:	6aa2                	ld	s5,8(sp)
    8000466c:	6121                	addi	sp,sp,64
    8000466e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004670:	85d6                	mv	a1,s5
    80004672:	8552                	mv	a0,s4
    80004674:	00000097          	auipc	ra,0x0
    80004678:	372080e7          	jalr	882(ra) # 800049e6 <pipeclose>
    8000467c:	b7cd                	j	8000465e <fileclose+0xa8>

000000008000467e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000467e:	715d                	addi	sp,sp,-80
    80004680:	e486                	sd	ra,72(sp)
    80004682:	e0a2                	sd	s0,64(sp)
    80004684:	fc26                	sd	s1,56(sp)
    80004686:	f84a                	sd	s2,48(sp)
    80004688:	f44e                	sd	s3,40(sp)
    8000468a:	0880                	addi	s0,sp,80
    8000468c:	84aa                	mv	s1,a0
    8000468e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004690:	ffffd097          	auipc	ra,0xffffd
    80004694:	378080e7          	jalr	888(ra) # 80001a08 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004698:	409c                	lw	a5,0(s1)
    8000469a:	37f9                	addiw	a5,a5,-2
    8000469c:	4705                	li	a4,1
    8000469e:	04f76763          	bltu	a4,a5,800046ec <filestat+0x6e>
    800046a2:	892a                	mv	s2,a0
    ilock(f->ip);
    800046a4:	6c88                	ld	a0,24(s1)
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	07e080e7          	jalr	126(ra) # 80003724 <ilock>
    stati(f->ip, &st);
    800046ae:	fb840593          	addi	a1,s0,-72
    800046b2:	6c88                	ld	a0,24(s1)
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	2fa080e7          	jalr	762(ra) # 800039ae <stati>
    iunlock(f->ip);
    800046bc:	6c88                	ld	a0,24(s1)
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	128080e7          	jalr	296(ra) # 800037e6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046c6:	46e1                	li	a3,24
    800046c8:	fb840613          	addi	a2,s0,-72
    800046cc:	85ce                	mv	a1,s3
    800046ce:	05093503          	ld	a0,80(s2)
    800046d2:	ffffd097          	auipc	ra,0xffffd
    800046d6:	028080e7          	jalr	40(ra) # 800016fa <copyout>
    800046da:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046de:	60a6                	ld	ra,72(sp)
    800046e0:	6406                	ld	s0,64(sp)
    800046e2:	74e2                	ld	s1,56(sp)
    800046e4:	7942                	ld	s2,48(sp)
    800046e6:	79a2                	ld	s3,40(sp)
    800046e8:	6161                	addi	sp,sp,80
    800046ea:	8082                	ret
  return -1;
    800046ec:	557d                	li	a0,-1
    800046ee:	bfc5                	j	800046de <filestat+0x60>

00000000800046f0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046f0:	7179                	addi	sp,sp,-48
    800046f2:	f406                	sd	ra,40(sp)
    800046f4:	f022                	sd	s0,32(sp)
    800046f6:	ec26                	sd	s1,24(sp)
    800046f8:	e84a                	sd	s2,16(sp)
    800046fa:	e44e                	sd	s3,8(sp)
    800046fc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046fe:	00854783          	lbu	a5,8(a0)
    80004702:	c3d5                	beqz	a5,800047a6 <fileread+0xb6>
    80004704:	84aa                	mv	s1,a0
    80004706:	89ae                	mv	s3,a1
    80004708:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000470a:	411c                	lw	a5,0(a0)
    8000470c:	4705                	li	a4,1
    8000470e:	04e78963          	beq	a5,a4,80004760 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004712:	470d                	li	a4,3
    80004714:	04e78d63          	beq	a5,a4,8000476e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004718:	4709                	li	a4,2
    8000471a:	06e79e63          	bne	a5,a4,80004796 <fileread+0xa6>
    ilock(f->ip);
    8000471e:	6d08                	ld	a0,24(a0)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	004080e7          	jalr	4(ra) # 80003724 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004728:	874a                	mv	a4,s2
    8000472a:	5094                	lw	a3,32(s1)
    8000472c:	864e                	mv	a2,s3
    8000472e:	4585                	li	a1,1
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	2a6080e7          	jalr	678(ra) # 800039d8 <readi>
    8000473a:	892a                	mv	s2,a0
    8000473c:	00a05563          	blez	a0,80004746 <fileread+0x56>
      f->off += r;
    80004740:	509c                	lw	a5,32(s1)
    80004742:	9fa9                	addw	a5,a5,a0
    80004744:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	09e080e7          	jalr	158(ra) # 800037e6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004750:	854a                	mv	a0,s2
    80004752:	70a2                	ld	ra,40(sp)
    80004754:	7402                	ld	s0,32(sp)
    80004756:	64e2                	ld	s1,24(sp)
    80004758:	6942                	ld	s2,16(sp)
    8000475a:	69a2                	ld	s3,8(sp)
    8000475c:	6145                	addi	sp,sp,48
    8000475e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004760:	6908                	ld	a0,16(a0)
    80004762:	00000097          	auipc	ra,0x0
    80004766:	3f4080e7          	jalr	1012(ra) # 80004b56 <piperead>
    8000476a:	892a                	mv	s2,a0
    8000476c:	b7d5                	j	80004750 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000476e:	02451783          	lh	a5,36(a0)
    80004772:	03079693          	slli	a3,a5,0x30
    80004776:	92c1                	srli	a3,a3,0x30
    80004778:	4725                	li	a4,9
    8000477a:	02d76863          	bltu	a4,a3,800047aa <fileread+0xba>
    8000477e:	0792                	slli	a5,a5,0x4
    80004780:	0001d717          	auipc	a4,0x1d
    80004784:	23070713          	addi	a4,a4,560 # 800219b0 <devsw>
    80004788:	97ba                	add	a5,a5,a4
    8000478a:	639c                	ld	a5,0(a5)
    8000478c:	c38d                	beqz	a5,800047ae <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000478e:	4505                	li	a0,1
    80004790:	9782                	jalr	a5
    80004792:	892a                	mv	s2,a0
    80004794:	bf75                	j	80004750 <fileread+0x60>
    panic("fileread");
    80004796:	00004517          	auipc	a0,0x4
    8000479a:	ea250513          	addi	a0,a0,-350 # 80008638 <syscalls+0x258>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	da4080e7          	jalr	-604(ra) # 80000542 <panic>
    return -1;
    800047a6:	597d                	li	s2,-1
    800047a8:	b765                	j	80004750 <fileread+0x60>
      return -1;
    800047aa:	597d                	li	s2,-1
    800047ac:	b755                	j	80004750 <fileread+0x60>
    800047ae:	597d                	li	s2,-1
    800047b0:	b745                	j	80004750 <fileread+0x60>

00000000800047b2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047b2:	00954783          	lbu	a5,9(a0)
    800047b6:	14078563          	beqz	a5,80004900 <filewrite+0x14e>
{
    800047ba:	715d                	addi	sp,sp,-80
    800047bc:	e486                	sd	ra,72(sp)
    800047be:	e0a2                	sd	s0,64(sp)
    800047c0:	fc26                	sd	s1,56(sp)
    800047c2:	f84a                	sd	s2,48(sp)
    800047c4:	f44e                	sd	s3,40(sp)
    800047c6:	f052                	sd	s4,32(sp)
    800047c8:	ec56                	sd	s5,24(sp)
    800047ca:	e85a                	sd	s6,16(sp)
    800047cc:	e45e                	sd	s7,8(sp)
    800047ce:	e062                	sd	s8,0(sp)
    800047d0:	0880                	addi	s0,sp,80
    800047d2:	892a                	mv	s2,a0
    800047d4:	8aae                	mv	s5,a1
    800047d6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047d8:	411c                	lw	a5,0(a0)
    800047da:	4705                	li	a4,1
    800047dc:	02e78263          	beq	a5,a4,80004800 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e0:	470d                	li	a4,3
    800047e2:	02e78563          	beq	a5,a4,8000480c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047e6:	4709                	li	a4,2
    800047e8:	10e79463          	bne	a5,a4,800048f0 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047ec:	0ec05e63          	blez	a2,800048e8 <filewrite+0x136>
    int i = 0;
    800047f0:	4981                	li	s3,0
    800047f2:	6b05                	lui	s6,0x1
    800047f4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047f8:	6b85                	lui	s7,0x1
    800047fa:	c00b8b9b          	addiw	s7,s7,-1024
    800047fe:	a851                	j	80004892 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004800:	6908                	ld	a0,16(a0)
    80004802:	00000097          	auipc	ra,0x0
    80004806:	254080e7          	jalr	596(ra) # 80004a56 <pipewrite>
    8000480a:	a85d                	j	800048c0 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000480c:	02451783          	lh	a5,36(a0)
    80004810:	03079693          	slli	a3,a5,0x30
    80004814:	92c1                	srli	a3,a3,0x30
    80004816:	4725                	li	a4,9
    80004818:	0ed76663          	bltu	a4,a3,80004904 <filewrite+0x152>
    8000481c:	0792                	slli	a5,a5,0x4
    8000481e:	0001d717          	auipc	a4,0x1d
    80004822:	19270713          	addi	a4,a4,402 # 800219b0 <devsw>
    80004826:	97ba                	add	a5,a5,a4
    80004828:	679c                	ld	a5,8(a5)
    8000482a:	cff9                	beqz	a5,80004908 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000482c:	4505                	li	a0,1
    8000482e:	9782                	jalr	a5
    80004830:	a841                	j	800048c0 <filewrite+0x10e>
    80004832:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004836:	00000097          	auipc	ra,0x0
    8000483a:	8ae080e7          	jalr	-1874(ra) # 800040e4 <begin_op>
      ilock(f->ip);
    8000483e:	01893503          	ld	a0,24(s2)
    80004842:	fffff097          	auipc	ra,0xfffff
    80004846:	ee2080e7          	jalr	-286(ra) # 80003724 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000484a:	8762                	mv	a4,s8
    8000484c:	02092683          	lw	a3,32(s2)
    80004850:	01598633          	add	a2,s3,s5
    80004854:	4585                	li	a1,1
    80004856:	01893503          	ld	a0,24(s2)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	276080e7          	jalr	630(ra) # 80003ad0 <writei>
    80004862:	84aa                	mv	s1,a0
    80004864:	02a05f63          	blez	a0,800048a2 <filewrite+0xf0>
        f->off += r;
    80004868:	02092783          	lw	a5,32(s2)
    8000486c:	9fa9                	addw	a5,a5,a0
    8000486e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004872:	01893503          	ld	a0,24(s2)
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	f70080e7          	jalr	-144(ra) # 800037e6 <iunlock>
      end_op();
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	8e6080e7          	jalr	-1818(ra) # 80004164 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004886:	049c1963          	bne	s8,s1,800048d8 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000488a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000488e:	0349d663          	bge	s3,s4,800048ba <filewrite+0x108>
      int n1 = n - i;
    80004892:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004896:	84be                	mv	s1,a5
    80004898:	2781                	sext.w	a5,a5
    8000489a:	f8fb5ce3          	bge	s6,a5,80004832 <filewrite+0x80>
    8000489e:	84de                	mv	s1,s7
    800048a0:	bf49                	j	80004832 <filewrite+0x80>
      iunlock(f->ip);
    800048a2:	01893503          	ld	a0,24(s2)
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	f40080e7          	jalr	-192(ra) # 800037e6 <iunlock>
      end_op();
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	8b6080e7          	jalr	-1866(ra) # 80004164 <end_op>
      if(r < 0)
    800048b6:	fc04d8e3          	bgez	s1,80004886 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048ba:	8552                	mv	a0,s4
    800048bc:	033a1863          	bne	s4,s3,800048ec <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048c0:	60a6                	ld	ra,72(sp)
    800048c2:	6406                	ld	s0,64(sp)
    800048c4:	74e2                	ld	s1,56(sp)
    800048c6:	7942                	ld	s2,48(sp)
    800048c8:	79a2                	ld	s3,40(sp)
    800048ca:	7a02                	ld	s4,32(sp)
    800048cc:	6ae2                	ld	s5,24(sp)
    800048ce:	6b42                	ld	s6,16(sp)
    800048d0:	6ba2                	ld	s7,8(sp)
    800048d2:	6c02                	ld	s8,0(sp)
    800048d4:	6161                	addi	sp,sp,80
    800048d6:	8082                	ret
        panic("short filewrite");
    800048d8:	00004517          	auipc	a0,0x4
    800048dc:	d7050513          	addi	a0,a0,-656 # 80008648 <syscalls+0x268>
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	c62080e7          	jalr	-926(ra) # 80000542 <panic>
    int i = 0;
    800048e8:	4981                	li	s3,0
    800048ea:	bfc1                	j	800048ba <filewrite+0x108>
    ret = (i == n ? n : -1);
    800048ec:	557d                	li	a0,-1
    800048ee:	bfc9                	j	800048c0 <filewrite+0x10e>
    panic("filewrite");
    800048f0:	00004517          	auipc	a0,0x4
    800048f4:	d6850513          	addi	a0,a0,-664 # 80008658 <syscalls+0x278>
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	c4a080e7          	jalr	-950(ra) # 80000542 <panic>
    return -1;
    80004900:	557d                	li	a0,-1
}
    80004902:	8082                	ret
      return -1;
    80004904:	557d                	li	a0,-1
    80004906:	bf6d                	j	800048c0 <filewrite+0x10e>
    80004908:	557d                	li	a0,-1
    8000490a:	bf5d                	j	800048c0 <filewrite+0x10e>

000000008000490c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000490c:	7179                	addi	sp,sp,-48
    8000490e:	f406                	sd	ra,40(sp)
    80004910:	f022                	sd	s0,32(sp)
    80004912:	ec26                	sd	s1,24(sp)
    80004914:	e84a                	sd	s2,16(sp)
    80004916:	e44e                	sd	s3,8(sp)
    80004918:	e052                	sd	s4,0(sp)
    8000491a:	1800                	addi	s0,sp,48
    8000491c:	84aa                	mv	s1,a0
    8000491e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004920:	0005b023          	sd	zero,0(a1)
    80004924:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	bd2080e7          	jalr	-1070(ra) # 800044fa <filealloc>
    80004930:	e088                	sd	a0,0(s1)
    80004932:	c551                	beqz	a0,800049be <pipealloc+0xb2>
    80004934:	00000097          	auipc	ra,0x0
    80004938:	bc6080e7          	jalr	-1082(ra) # 800044fa <filealloc>
    8000493c:	00aa3023          	sd	a0,0(s4)
    80004940:	c92d                	beqz	a0,800049b2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	1cc080e7          	jalr	460(ra) # 80000b0e <kalloc>
    8000494a:	892a                	mv	s2,a0
    8000494c:	c125                	beqz	a0,800049ac <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000494e:	4985                	li	s3,1
    80004950:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004954:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004958:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000495c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004960:	00004597          	auipc	a1,0x4
    80004964:	d0858593          	addi	a1,a1,-760 # 80008668 <syscalls+0x288>
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	206080e7          	jalr	518(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    80004970:	609c                	ld	a5,0(s1)
    80004972:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004976:	609c                	ld	a5,0(s1)
    80004978:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000497c:	609c                	ld	a5,0(s1)
    8000497e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004982:	609c                	ld	a5,0(s1)
    80004984:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004988:	000a3783          	ld	a5,0(s4)
    8000498c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004990:	000a3783          	ld	a5,0(s4)
    80004994:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004998:	000a3783          	ld	a5,0(s4)
    8000499c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049a0:	000a3783          	ld	a5,0(s4)
    800049a4:	0127b823          	sd	s2,16(a5)
  return 0;
    800049a8:	4501                	li	a0,0
    800049aa:	a025                	j	800049d2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049ac:	6088                	ld	a0,0(s1)
    800049ae:	e501                	bnez	a0,800049b6 <pipealloc+0xaa>
    800049b0:	a039                	j	800049be <pipealloc+0xb2>
    800049b2:	6088                	ld	a0,0(s1)
    800049b4:	c51d                	beqz	a0,800049e2 <pipealloc+0xd6>
    fileclose(*f0);
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	c00080e7          	jalr	-1024(ra) # 800045b6 <fileclose>
  if(*f1)
    800049be:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049c2:	557d                	li	a0,-1
  if(*f1)
    800049c4:	c799                	beqz	a5,800049d2 <pipealloc+0xc6>
    fileclose(*f1);
    800049c6:	853e                	mv	a0,a5
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	bee080e7          	jalr	-1042(ra) # 800045b6 <fileclose>
  return -1;
    800049d0:	557d                	li	a0,-1
}
    800049d2:	70a2                	ld	ra,40(sp)
    800049d4:	7402                	ld	s0,32(sp)
    800049d6:	64e2                	ld	s1,24(sp)
    800049d8:	6942                	ld	s2,16(sp)
    800049da:	69a2                	ld	s3,8(sp)
    800049dc:	6a02                	ld	s4,0(sp)
    800049de:	6145                	addi	sp,sp,48
    800049e0:	8082                	ret
  return -1;
    800049e2:	557d                	li	a0,-1
    800049e4:	b7fd                	j	800049d2 <pipealloc+0xc6>

00000000800049e6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049e6:	1101                	addi	sp,sp,-32
    800049e8:	ec06                	sd	ra,24(sp)
    800049ea:	e822                	sd	s0,16(sp)
    800049ec:	e426                	sd	s1,8(sp)
    800049ee:	e04a                	sd	s2,0(sp)
    800049f0:	1000                	addi	s0,sp,32
    800049f2:	84aa                	mv	s1,a0
    800049f4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	208080e7          	jalr	520(ra) # 80000bfe <acquire>
  if(writable){
    800049fe:	02090d63          	beqz	s2,80004a38 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a02:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a06:	21848513          	addi	a0,s1,536
    80004a0a:	ffffe097          	auipc	ra,0xffffe
    80004a0e:	992080e7          	jalr	-1646(ra) # 8000239c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a12:	2204b783          	ld	a5,544(s1)
    80004a16:	eb95                	bnez	a5,80004a4a <pipeclose+0x64>
    release(&pi->lock);
    80004a18:	8526                	mv	a0,s1
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	298080e7          	jalr	664(ra) # 80000cb2 <release>
    kfree((char*)pi);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	fee080e7          	jalr	-18(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004a2c:	60e2                	ld	ra,24(sp)
    80004a2e:	6442                	ld	s0,16(sp)
    80004a30:	64a2                	ld	s1,8(sp)
    80004a32:	6902                	ld	s2,0(sp)
    80004a34:	6105                	addi	sp,sp,32
    80004a36:	8082                	ret
    pi->readopen = 0;
    80004a38:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a3c:	21c48513          	addi	a0,s1,540
    80004a40:	ffffe097          	auipc	ra,0xffffe
    80004a44:	95c080e7          	jalr	-1700(ra) # 8000239c <wakeup>
    80004a48:	b7e9                	j	80004a12 <pipeclose+0x2c>
    release(&pi->lock);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	266080e7          	jalr	614(ra) # 80000cb2 <release>
}
    80004a54:	bfe1                	j	80004a2c <pipeclose+0x46>

0000000080004a56 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a56:	711d                	addi	sp,sp,-96
    80004a58:	ec86                	sd	ra,88(sp)
    80004a5a:	e8a2                	sd	s0,80(sp)
    80004a5c:	e4a6                	sd	s1,72(sp)
    80004a5e:	e0ca                	sd	s2,64(sp)
    80004a60:	fc4e                	sd	s3,56(sp)
    80004a62:	f852                	sd	s4,48(sp)
    80004a64:	f456                	sd	s5,40(sp)
    80004a66:	f05a                	sd	s6,32(sp)
    80004a68:	ec5e                	sd	s7,24(sp)
    80004a6a:	e862                	sd	s8,16(sp)
    80004a6c:	1080                	addi	s0,sp,96
    80004a6e:	84aa                	mv	s1,a0
    80004a70:	8b2e                	mv	s6,a1
    80004a72:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a74:	ffffd097          	auipc	ra,0xffffd
    80004a78:	f94080e7          	jalr	-108(ra) # 80001a08 <myproc>
    80004a7c:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a7e:	8526                	mv	a0,s1
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	17e080e7          	jalr	382(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004a88:	09505763          	blez	s5,80004b16 <pipewrite+0xc0>
    80004a8c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a8e:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a92:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a96:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a98:	2184a783          	lw	a5,536(s1)
    80004a9c:	21c4a703          	lw	a4,540(s1)
    80004aa0:	2007879b          	addiw	a5,a5,512
    80004aa4:	02f71b63          	bne	a4,a5,80004ada <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004aa8:	2204a783          	lw	a5,544(s1)
    80004aac:	c3d1                	beqz	a5,80004b30 <pipewrite+0xda>
    80004aae:	03092783          	lw	a5,48(s2)
    80004ab2:	efbd                	bnez	a5,80004b30 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004ab4:	8552                	mv	a0,s4
    80004ab6:	ffffe097          	auipc	ra,0xffffe
    80004aba:	8e6080e7          	jalr	-1818(ra) # 8000239c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004abe:	85a6                	mv	a1,s1
    80004ac0:	854e                	mv	a0,s3
    80004ac2:	ffffd097          	auipc	ra,0xffffd
    80004ac6:	75a080e7          	jalr	1882(ra) # 8000221c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004aca:	2184a783          	lw	a5,536(s1)
    80004ace:	21c4a703          	lw	a4,540(s1)
    80004ad2:	2007879b          	addiw	a5,a5,512
    80004ad6:	fcf709e3          	beq	a4,a5,80004aa8 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ada:	4685                	li	a3,1
    80004adc:	865a                	mv	a2,s6
    80004ade:	faf40593          	addi	a1,s0,-81
    80004ae2:	05093503          	ld	a0,80(s2)
    80004ae6:	ffffd097          	auipc	ra,0xffffd
    80004aea:	ca0080e7          	jalr	-864(ra) # 80001786 <copyin>
    80004aee:	03850563          	beq	a0,s8,80004b18 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004af2:	21c4a783          	lw	a5,540(s1)
    80004af6:	0017871b          	addiw	a4,a5,1
    80004afa:	20e4ae23          	sw	a4,540(s1)
    80004afe:	1ff7f793          	andi	a5,a5,511
    80004b02:	97a6                	add	a5,a5,s1
    80004b04:	faf44703          	lbu	a4,-81(s0)
    80004b08:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b0c:	2b85                	addiw	s7,s7,1
    80004b0e:	0b05                	addi	s6,s6,1
    80004b10:	f97a94e3          	bne	s5,s7,80004a98 <pipewrite+0x42>
    80004b14:	a011                	j	80004b18 <pipewrite+0xc2>
    80004b16:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004b18:	21848513          	addi	a0,s1,536
    80004b1c:	ffffe097          	auipc	ra,0xffffe
    80004b20:	880080e7          	jalr	-1920(ra) # 8000239c <wakeup>
  release(&pi->lock);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	18c080e7          	jalr	396(ra) # 80000cb2 <release>
  return i;
    80004b2e:	a039                	j	80004b3c <pipewrite+0xe6>
        release(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	180080e7          	jalr	384(ra) # 80000cb2 <release>
        return -1;
    80004b3a:	5bfd                	li	s7,-1
}
    80004b3c:	855e                	mv	a0,s7
    80004b3e:	60e6                	ld	ra,88(sp)
    80004b40:	6446                	ld	s0,80(sp)
    80004b42:	64a6                	ld	s1,72(sp)
    80004b44:	6906                	ld	s2,64(sp)
    80004b46:	79e2                	ld	s3,56(sp)
    80004b48:	7a42                	ld	s4,48(sp)
    80004b4a:	7aa2                	ld	s5,40(sp)
    80004b4c:	7b02                	ld	s6,32(sp)
    80004b4e:	6be2                	ld	s7,24(sp)
    80004b50:	6c42                	ld	s8,16(sp)
    80004b52:	6125                	addi	sp,sp,96
    80004b54:	8082                	ret

0000000080004b56 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b56:	715d                	addi	sp,sp,-80
    80004b58:	e486                	sd	ra,72(sp)
    80004b5a:	e0a2                	sd	s0,64(sp)
    80004b5c:	fc26                	sd	s1,56(sp)
    80004b5e:	f84a                	sd	s2,48(sp)
    80004b60:	f44e                	sd	s3,40(sp)
    80004b62:	f052                	sd	s4,32(sp)
    80004b64:	ec56                	sd	s5,24(sp)
    80004b66:	e85a                	sd	s6,16(sp)
    80004b68:	0880                	addi	s0,sp,80
    80004b6a:	84aa                	mv	s1,a0
    80004b6c:	892e                	mv	s2,a1
    80004b6e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b70:	ffffd097          	auipc	ra,0xffffd
    80004b74:	e98080e7          	jalr	-360(ra) # 80001a08 <myproc>
    80004b78:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b7a:	8526                	mv	a0,s1
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	082080e7          	jalr	130(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b84:	2184a703          	lw	a4,536(s1)
    80004b88:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b8c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b90:	02f71463          	bne	a4,a5,80004bb8 <piperead+0x62>
    80004b94:	2244a783          	lw	a5,548(s1)
    80004b98:	c385                	beqz	a5,80004bb8 <piperead+0x62>
    if(pr->killed){
    80004b9a:	030a2783          	lw	a5,48(s4)
    80004b9e:	ebc1                	bnez	a5,80004c2e <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ba0:	85a6                	mv	a1,s1
    80004ba2:	854e                	mv	a0,s3
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	678080e7          	jalr	1656(ra) # 8000221c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bac:	2184a703          	lw	a4,536(s1)
    80004bb0:	21c4a783          	lw	a5,540(s1)
    80004bb4:	fef700e3          	beq	a4,a5,80004b94 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bba:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bbc:	05505363          	blez	s5,80004c02 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004bc0:	2184a783          	lw	a5,536(s1)
    80004bc4:	21c4a703          	lw	a4,540(s1)
    80004bc8:	02f70d63          	beq	a4,a5,80004c02 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bcc:	0017871b          	addiw	a4,a5,1
    80004bd0:	20e4ac23          	sw	a4,536(s1)
    80004bd4:	1ff7f793          	andi	a5,a5,511
    80004bd8:	97a6                	add	a5,a5,s1
    80004bda:	0187c783          	lbu	a5,24(a5)
    80004bde:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be2:	4685                	li	a3,1
    80004be4:	fbf40613          	addi	a2,s0,-65
    80004be8:	85ca                	mv	a1,s2
    80004bea:	050a3503          	ld	a0,80(s4)
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	b0c080e7          	jalr	-1268(ra) # 800016fa <copyout>
    80004bf6:	01650663          	beq	a0,s6,80004c02 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bfa:	2985                	addiw	s3,s3,1
    80004bfc:	0905                	addi	s2,s2,1
    80004bfe:	fd3a91e3          	bne	s5,s3,80004bc0 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c02:	21c48513          	addi	a0,s1,540
    80004c06:	ffffd097          	auipc	ra,0xffffd
    80004c0a:	796080e7          	jalr	1942(ra) # 8000239c <wakeup>
  release(&pi->lock);
    80004c0e:	8526                	mv	a0,s1
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	0a2080e7          	jalr	162(ra) # 80000cb2 <release>
  return i;
}
    80004c18:	854e                	mv	a0,s3
    80004c1a:	60a6                	ld	ra,72(sp)
    80004c1c:	6406                	ld	s0,64(sp)
    80004c1e:	74e2                	ld	s1,56(sp)
    80004c20:	7942                	ld	s2,48(sp)
    80004c22:	79a2                	ld	s3,40(sp)
    80004c24:	7a02                	ld	s4,32(sp)
    80004c26:	6ae2                	ld	s5,24(sp)
    80004c28:	6b42                	ld	s6,16(sp)
    80004c2a:	6161                	addi	sp,sp,80
    80004c2c:	8082                	ret
      release(&pi->lock);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	082080e7          	jalr	130(ra) # 80000cb2 <release>
      return -1;
    80004c38:	59fd                	li	s3,-1
    80004c3a:	bff9                	j	80004c18 <piperead+0xc2>

0000000080004c3c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c3c:	de010113          	addi	sp,sp,-544
    80004c40:	20113c23          	sd	ra,536(sp)
    80004c44:	20813823          	sd	s0,528(sp)
    80004c48:	20913423          	sd	s1,520(sp)
    80004c4c:	21213023          	sd	s2,512(sp)
    80004c50:	ffce                	sd	s3,504(sp)
    80004c52:	fbd2                	sd	s4,496(sp)
    80004c54:	f7d6                	sd	s5,488(sp)
    80004c56:	f3da                	sd	s6,480(sp)
    80004c58:	efde                	sd	s7,472(sp)
    80004c5a:	ebe2                	sd	s8,464(sp)
    80004c5c:	e7e6                	sd	s9,456(sp)
    80004c5e:	e3ea                	sd	s10,448(sp)
    80004c60:	ff6e                	sd	s11,440(sp)
    80004c62:	1400                	addi	s0,sp,544
    80004c64:	892a                	mv	s2,a0
    80004c66:	dea43423          	sd	a0,-536(s0)
    80004c6a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c6e:	ffffd097          	auipc	ra,0xffffd
    80004c72:	d9a080e7          	jalr	-614(ra) # 80001a08 <myproc>
    80004c76:	84aa                	mv	s1,a0

  begin_op();
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	46c080e7          	jalr	1132(ra) # 800040e4 <begin_op>

  if((ip = namei(path)) == 0){
    80004c80:	854a                	mv	a0,s2
    80004c82:	fffff097          	auipc	ra,0xfffff
    80004c86:	256080e7          	jalr	598(ra) # 80003ed8 <namei>
    80004c8a:	c93d                	beqz	a0,80004d00 <exec+0xc4>
    80004c8c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	a96080e7          	jalr	-1386(ra) # 80003724 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c96:	04000713          	li	a4,64
    80004c9a:	4681                	li	a3,0
    80004c9c:	e4840613          	addi	a2,s0,-440
    80004ca0:	4581                	li	a1,0
    80004ca2:	8556                	mv	a0,s5
    80004ca4:	fffff097          	auipc	ra,0xfffff
    80004ca8:	d34080e7          	jalr	-716(ra) # 800039d8 <readi>
    80004cac:	04000793          	li	a5,64
    80004cb0:	00f51a63          	bne	a0,a5,80004cc4 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cb4:	e4842703          	lw	a4,-440(s0)
    80004cb8:	464c47b7          	lui	a5,0x464c4
    80004cbc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cc0:	04f70663          	beq	a4,a5,80004d0c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cc4:	8556                	mv	a0,s5
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	cc0080e7          	jalr	-832(ra) # 80003986 <iunlockput>
    end_op();
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	496080e7          	jalr	1174(ra) # 80004164 <end_op>
  }
  return -1;
    80004cd6:	557d                	li	a0,-1
}
    80004cd8:	21813083          	ld	ra,536(sp)
    80004cdc:	21013403          	ld	s0,528(sp)
    80004ce0:	20813483          	ld	s1,520(sp)
    80004ce4:	20013903          	ld	s2,512(sp)
    80004ce8:	79fe                	ld	s3,504(sp)
    80004cea:	7a5e                	ld	s4,496(sp)
    80004cec:	7abe                	ld	s5,488(sp)
    80004cee:	7b1e                	ld	s6,480(sp)
    80004cf0:	6bfe                	ld	s7,472(sp)
    80004cf2:	6c5e                	ld	s8,464(sp)
    80004cf4:	6cbe                	ld	s9,456(sp)
    80004cf6:	6d1e                	ld	s10,448(sp)
    80004cf8:	7dfa                	ld	s11,440(sp)
    80004cfa:	22010113          	addi	sp,sp,544
    80004cfe:	8082                	ret
    end_op();
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	464080e7          	jalr	1124(ra) # 80004164 <end_op>
    return -1;
    80004d08:	557d                	li	a0,-1
    80004d0a:	b7f9                	j	80004cd8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d0c:	8526                	mv	a0,s1
    80004d0e:	ffffd097          	auipc	ra,0xffffd
    80004d12:	dbe080e7          	jalr	-578(ra) # 80001acc <proc_pagetable>
    80004d16:	8b2a                	mv	s6,a0
    80004d18:	d555                	beqz	a0,80004cc4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1a:	e6842783          	lw	a5,-408(s0)
    80004d1e:	e8045703          	lhu	a4,-384(s0)
    80004d22:	c735                	beqz	a4,80004d8e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d24:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d26:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d2a:	6a05                	lui	s4,0x1
    80004d2c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d30:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004d34:	6d85                	lui	s11,0x1
    80004d36:	7d7d                	lui	s10,0xfffff
    80004d38:	ac1d                	j	80004f6e <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d3a:	00004517          	auipc	a0,0x4
    80004d3e:	93650513          	addi	a0,a0,-1738 # 80008670 <syscalls+0x290>
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	800080e7          	jalr	-2048(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d4a:	874a                	mv	a4,s2
    80004d4c:	009c86bb          	addw	a3,s9,s1
    80004d50:	4581                	li	a1,0
    80004d52:	8556                	mv	a0,s5
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	c84080e7          	jalr	-892(ra) # 800039d8 <readi>
    80004d5c:	2501                	sext.w	a0,a0
    80004d5e:	1aa91863          	bne	s2,a0,80004f0e <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d62:	009d84bb          	addw	s1,s11,s1
    80004d66:	013d09bb          	addw	s3,s10,s3
    80004d6a:	1f74f263          	bgeu	s1,s7,80004f4e <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d6e:	02049593          	slli	a1,s1,0x20
    80004d72:	9181                	srli	a1,a1,0x20
    80004d74:	95e2                	add	a1,a1,s8
    80004d76:	855a                	mv	a0,s6
    80004d78:	ffffc097          	auipc	ra,0xffffc
    80004d7c:	3fc080e7          	jalr	1020(ra) # 80001174 <walkaddr>
    80004d80:	862a                	mv	a2,a0
    if(pa == 0)
    80004d82:	dd45                	beqz	a0,80004d3a <exec+0xfe>
      n = PGSIZE;
    80004d84:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d86:	fd49f2e3          	bgeu	s3,s4,80004d4a <exec+0x10e>
      n = sz - i;
    80004d8a:	894e                	mv	s2,s3
    80004d8c:	bf7d                	j	80004d4a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d8e:	4481                	li	s1,0
  iunlockput(ip);
    80004d90:	8556                	mv	a0,s5
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	bf4080e7          	jalr	-1036(ra) # 80003986 <iunlockput>
  end_op();
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	3ca080e7          	jalr	970(ra) # 80004164 <end_op>
  p = myproc();
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	c66080e7          	jalr	-922(ra) # 80001a08 <myproc>
    80004daa:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dac:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004db0:	6785                	lui	a5,0x1
    80004db2:	17fd                	addi	a5,a5,-1
    80004db4:	94be                	add	s1,s1,a5
    80004db6:	77fd                	lui	a5,0xfffff
    80004db8:	8fe5                	and	a5,a5,s1
    80004dba:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dbe:	6609                	lui	a2,0x2
    80004dc0:	963e                	add	a2,a2,a5
    80004dc2:	85be                	mv	a1,a5
    80004dc4:	855a                	mv	a0,s6
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	700080e7          	jalr	1792(ra) # 800014c6 <uvmalloc>
    80004dce:	8c2a                	mv	s8,a0
  ip = 0;
    80004dd0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dd2:	12050e63          	beqz	a0,80004f0e <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dd6:	75f9                	lui	a1,0xffffe
    80004dd8:	95aa                	add	a1,a1,a0
    80004dda:	855a                	mv	a0,s6
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	8ec080e7          	jalr	-1812(ra) # 800016c8 <uvmclear>
  stackbase = sp - PGSIZE;
    80004de4:	7afd                	lui	s5,0xfffff
    80004de6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004de8:	df043783          	ld	a5,-528(s0)
    80004dec:	6388                	ld	a0,0(a5)
    80004dee:	c925                	beqz	a0,80004e5e <exec+0x222>
    80004df0:	e8840993          	addi	s3,s0,-376
    80004df4:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004df8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dfa:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	082080e7          	jalr	130(ra) # 80000e7e <strlen>
    80004e04:	0015079b          	addiw	a5,a0,1
    80004e08:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e0c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e10:	13596363          	bltu	s2,s5,80004f36 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e14:	df043d83          	ld	s11,-528(s0)
    80004e18:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e1c:	8552                	mv	a0,s4
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	060080e7          	jalr	96(ra) # 80000e7e <strlen>
    80004e26:	0015069b          	addiw	a3,a0,1
    80004e2a:	8652                	mv	a2,s4
    80004e2c:	85ca                	mv	a1,s2
    80004e2e:	855a                	mv	a0,s6
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	8ca080e7          	jalr	-1846(ra) # 800016fa <copyout>
    80004e38:	10054363          	bltz	a0,80004f3e <exec+0x302>
    ustack[argc] = sp;
    80004e3c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e40:	0485                	addi	s1,s1,1
    80004e42:	008d8793          	addi	a5,s11,8
    80004e46:	def43823          	sd	a5,-528(s0)
    80004e4a:	008db503          	ld	a0,8(s11)
    80004e4e:	c911                	beqz	a0,80004e62 <exec+0x226>
    if(argc >= MAXARG)
    80004e50:	09a1                	addi	s3,s3,8
    80004e52:	fb3c95e3          	bne	s9,s3,80004dfc <exec+0x1c0>
  sz = sz1;
    80004e56:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e5a:	4a81                	li	s5,0
    80004e5c:	a84d                	j	80004f0e <exec+0x2d2>
  sp = sz;
    80004e5e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e60:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e62:	00349793          	slli	a5,s1,0x3
    80004e66:	f9040713          	addi	a4,s0,-112
    80004e6a:	97ba                	add	a5,a5,a4
    80004e6c:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004e70:	00148693          	addi	a3,s1,1
    80004e74:	068e                	slli	a3,a3,0x3
    80004e76:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e7a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e7e:	01597663          	bgeu	s2,s5,80004e8a <exec+0x24e>
  sz = sz1;
    80004e82:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e86:	4a81                	li	s5,0
    80004e88:	a059                	j	80004f0e <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e8a:	e8840613          	addi	a2,s0,-376
    80004e8e:	85ca                	mv	a1,s2
    80004e90:	855a                	mv	a0,s6
    80004e92:	ffffd097          	auipc	ra,0xffffd
    80004e96:	868080e7          	jalr	-1944(ra) # 800016fa <copyout>
    80004e9a:	0a054663          	bltz	a0,80004f46 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e9e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004ea2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ea6:	de843783          	ld	a5,-536(s0)
    80004eaa:	0007c703          	lbu	a4,0(a5)
    80004eae:	cf11                	beqz	a4,80004eca <exec+0x28e>
    80004eb0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eb2:	02f00693          	li	a3,47
    80004eb6:	a039                	j	80004ec4 <exec+0x288>
      last = s+1;
    80004eb8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ebc:	0785                	addi	a5,a5,1
    80004ebe:	fff7c703          	lbu	a4,-1(a5)
    80004ec2:	c701                	beqz	a4,80004eca <exec+0x28e>
    if(*s == '/')
    80004ec4:	fed71ce3          	bne	a4,a3,80004ebc <exec+0x280>
    80004ec8:	bfc5                	j	80004eb8 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004eca:	4641                	li	a2,16
    80004ecc:	de843583          	ld	a1,-536(s0)
    80004ed0:	158b8513          	addi	a0,s7,344
    80004ed4:	ffffc097          	auipc	ra,0xffffc
    80004ed8:	f78080e7          	jalr	-136(ra) # 80000e4c <safestrcpy>
  oldpagetable = p->pagetable;
    80004edc:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ee0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ee4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ee8:	058bb783          	ld	a5,88(s7)
    80004eec:	e6043703          	ld	a4,-416(s0)
    80004ef0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ef2:	058bb783          	ld	a5,88(s7)
    80004ef6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004efa:	85ea                	mv	a1,s10
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	c6c080e7          	jalr	-916(ra) # 80001b68 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f04:	0004851b          	sext.w	a0,s1
    80004f08:	bbc1                	j	80004cd8 <exec+0x9c>
    80004f0a:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f0e:	df843583          	ld	a1,-520(s0)
    80004f12:	855a                	mv	a0,s6
    80004f14:	ffffd097          	auipc	ra,0xffffd
    80004f18:	c54080e7          	jalr	-940(ra) # 80001b68 <proc_freepagetable>
  if(ip){
    80004f1c:	da0a94e3          	bnez	s5,80004cc4 <exec+0x88>
  return -1;
    80004f20:	557d                	li	a0,-1
    80004f22:	bb5d                	j	80004cd8 <exec+0x9c>
    80004f24:	de943c23          	sd	s1,-520(s0)
    80004f28:	b7dd                	j	80004f0e <exec+0x2d2>
    80004f2a:	de943c23          	sd	s1,-520(s0)
    80004f2e:	b7c5                	j	80004f0e <exec+0x2d2>
    80004f30:	de943c23          	sd	s1,-520(s0)
    80004f34:	bfe9                	j	80004f0e <exec+0x2d2>
  sz = sz1;
    80004f36:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f3a:	4a81                	li	s5,0
    80004f3c:	bfc9                	j	80004f0e <exec+0x2d2>
  sz = sz1;
    80004f3e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f42:	4a81                	li	s5,0
    80004f44:	b7e9                	j	80004f0e <exec+0x2d2>
  sz = sz1;
    80004f46:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f4a:	4a81                	li	s5,0
    80004f4c:	b7c9                	j	80004f0e <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f4e:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f52:	e0843783          	ld	a5,-504(s0)
    80004f56:	0017869b          	addiw	a3,a5,1
    80004f5a:	e0d43423          	sd	a3,-504(s0)
    80004f5e:	e0043783          	ld	a5,-512(s0)
    80004f62:	0387879b          	addiw	a5,a5,56
    80004f66:	e8045703          	lhu	a4,-384(s0)
    80004f6a:	e2e6d3e3          	bge	a3,a4,80004d90 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f6e:	2781                	sext.w	a5,a5
    80004f70:	e0f43023          	sd	a5,-512(s0)
    80004f74:	03800713          	li	a4,56
    80004f78:	86be                	mv	a3,a5
    80004f7a:	e1040613          	addi	a2,s0,-496
    80004f7e:	4581                	li	a1,0
    80004f80:	8556                	mv	a0,s5
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	a56080e7          	jalr	-1450(ra) # 800039d8 <readi>
    80004f8a:	03800793          	li	a5,56
    80004f8e:	f6f51ee3          	bne	a0,a5,80004f0a <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f92:	e1042783          	lw	a5,-496(s0)
    80004f96:	4705                	li	a4,1
    80004f98:	fae79de3          	bne	a5,a4,80004f52 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f9c:	e3843603          	ld	a2,-456(s0)
    80004fa0:	e3043783          	ld	a5,-464(s0)
    80004fa4:	f8f660e3          	bltu	a2,a5,80004f24 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fa8:	e2043783          	ld	a5,-480(s0)
    80004fac:	963e                	add	a2,a2,a5
    80004fae:	f6f66ee3          	bltu	a2,a5,80004f2a <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fb2:	85a6                	mv	a1,s1
    80004fb4:	855a                	mv	a0,s6
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	510080e7          	jalr	1296(ra) # 800014c6 <uvmalloc>
    80004fbe:	dea43c23          	sd	a0,-520(s0)
    80004fc2:	d53d                	beqz	a0,80004f30 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004fc4:	e2043c03          	ld	s8,-480(s0)
    80004fc8:	de043783          	ld	a5,-544(s0)
    80004fcc:	00fc77b3          	and	a5,s8,a5
    80004fd0:	ff9d                	bnez	a5,80004f0e <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fd2:	e1842c83          	lw	s9,-488(s0)
    80004fd6:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fda:	f60b8ae3          	beqz	s7,80004f4e <exec+0x312>
    80004fde:	89de                	mv	s3,s7
    80004fe0:	4481                	li	s1,0
    80004fe2:	b371                	j	80004d6e <exec+0x132>

0000000080004fe4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fe4:	7179                	addi	sp,sp,-48
    80004fe6:	f406                	sd	ra,40(sp)
    80004fe8:	f022                	sd	s0,32(sp)
    80004fea:	ec26                	sd	s1,24(sp)
    80004fec:	e84a                	sd	s2,16(sp)
    80004fee:	1800                	addi	s0,sp,48
    80004ff0:	892e                	mv	s2,a1
    80004ff2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ff4:	fdc40593          	addi	a1,s0,-36
    80004ff8:	ffffe097          	auipc	ra,0xffffe
    80004ffc:	b5a080e7          	jalr	-1190(ra) # 80002b52 <argint>
    80005000:	04054063          	bltz	a0,80005040 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005004:	fdc42703          	lw	a4,-36(s0)
    80005008:	47bd                	li	a5,15
    8000500a:	02e7ed63          	bltu	a5,a4,80005044 <argfd+0x60>
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	9fa080e7          	jalr	-1542(ra) # 80001a08 <myproc>
    80005016:	fdc42703          	lw	a4,-36(s0)
    8000501a:	01a70793          	addi	a5,a4,26
    8000501e:	078e                	slli	a5,a5,0x3
    80005020:	953e                	add	a0,a0,a5
    80005022:	611c                	ld	a5,0(a0)
    80005024:	c395                	beqz	a5,80005048 <argfd+0x64>
    return -1;
  if(pfd)
    80005026:	00090463          	beqz	s2,8000502e <argfd+0x4a>
    *pfd = fd;
    8000502a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000502e:	4501                	li	a0,0
  if(pf)
    80005030:	c091                	beqz	s1,80005034 <argfd+0x50>
    *pf = f;
    80005032:	e09c                	sd	a5,0(s1)
}
    80005034:	70a2                	ld	ra,40(sp)
    80005036:	7402                	ld	s0,32(sp)
    80005038:	64e2                	ld	s1,24(sp)
    8000503a:	6942                	ld	s2,16(sp)
    8000503c:	6145                	addi	sp,sp,48
    8000503e:	8082                	ret
    return -1;
    80005040:	557d                	li	a0,-1
    80005042:	bfcd                	j	80005034 <argfd+0x50>
    return -1;
    80005044:	557d                	li	a0,-1
    80005046:	b7fd                	j	80005034 <argfd+0x50>
    80005048:	557d                	li	a0,-1
    8000504a:	b7ed                	j	80005034 <argfd+0x50>

000000008000504c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000504c:	1101                	addi	sp,sp,-32
    8000504e:	ec06                	sd	ra,24(sp)
    80005050:	e822                	sd	s0,16(sp)
    80005052:	e426                	sd	s1,8(sp)
    80005054:	1000                	addi	s0,sp,32
    80005056:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005058:	ffffd097          	auipc	ra,0xffffd
    8000505c:	9b0080e7          	jalr	-1616(ra) # 80001a08 <myproc>
    80005060:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005062:	0d050793          	addi	a5,a0,208
    80005066:	4501                	li	a0,0
    80005068:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000506a:	6398                	ld	a4,0(a5)
    8000506c:	cb19                	beqz	a4,80005082 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000506e:	2505                	addiw	a0,a0,1
    80005070:	07a1                	addi	a5,a5,8
    80005072:	fed51ce3          	bne	a0,a3,8000506a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005076:	557d                	li	a0,-1
}
    80005078:	60e2                	ld	ra,24(sp)
    8000507a:	6442                	ld	s0,16(sp)
    8000507c:	64a2                	ld	s1,8(sp)
    8000507e:	6105                	addi	sp,sp,32
    80005080:	8082                	ret
      p->ofile[fd] = f;
    80005082:	01a50793          	addi	a5,a0,26
    80005086:	078e                	slli	a5,a5,0x3
    80005088:	963e                	add	a2,a2,a5
    8000508a:	e204                	sd	s1,0(a2)
      return fd;
    8000508c:	b7f5                	j	80005078 <fdalloc+0x2c>

000000008000508e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000508e:	715d                	addi	sp,sp,-80
    80005090:	e486                	sd	ra,72(sp)
    80005092:	e0a2                	sd	s0,64(sp)
    80005094:	fc26                	sd	s1,56(sp)
    80005096:	f84a                	sd	s2,48(sp)
    80005098:	f44e                	sd	s3,40(sp)
    8000509a:	f052                	sd	s4,32(sp)
    8000509c:	ec56                	sd	s5,24(sp)
    8000509e:	0880                	addi	s0,sp,80
    800050a0:	89ae                	mv	s3,a1
    800050a2:	8ab2                	mv	s5,a2
    800050a4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050a6:	fb040593          	addi	a1,s0,-80
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	e4c080e7          	jalr	-436(ra) # 80003ef6 <nameiparent>
    800050b2:	892a                	mv	s2,a0
    800050b4:	12050e63          	beqz	a0,800051f0 <create+0x162>
    return 0;

  ilock(dp);
    800050b8:	ffffe097          	auipc	ra,0xffffe
    800050bc:	66c080e7          	jalr	1644(ra) # 80003724 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050c0:	4601                	li	a2,0
    800050c2:	fb040593          	addi	a1,s0,-80
    800050c6:	854a                	mv	a0,s2
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	b3e080e7          	jalr	-1218(ra) # 80003c06 <dirlookup>
    800050d0:	84aa                	mv	s1,a0
    800050d2:	c921                	beqz	a0,80005122 <create+0x94>
    iunlockput(dp);
    800050d4:	854a                	mv	a0,s2
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	8b0080e7          	jalr	-1872(ra) # 80003986 <iunlockput>
    ilock(ip);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffe097          	auipc	ra,0xffffe
    800050e4:	644080e7          	jalr	1604(ra) # 80003724 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050e8:	2981                	sext.w	s3,s3
    800050ea:	4789                	li	a5,2
    800050ec:	02f99463          	bne	s3,a5,80005114 <create+0x86>
    800050f0:	0444d783          	lhu	a5,68(s1)
    800050f4:	37f9                	addiw	a5,a5,-2
    800050f6:	17c2                	slli	a5,a5,0x30
    800050f8:	93c1                	srli	a5,a5,0x30
    800050fa:	4705                	li	a4,1
    800050fc:	00f76c63          	bltu	a4,a5,80005114 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005100:	8526                	mv	a0,s1
    80005102:	60a6                	ld	ra,72(sp)
    80005104:	6406                	ld	s0,64(sp)
    80005106:	74e2                	ld	s1,56(sp)
    80005108:	7942                	ld	s2,48(sp)
    8000510a:	79a2                	ld	s3,40(sp)
    8000510c:	7a02                	ld	s4,32(sp)
    8000510e:	6ae2                	ld	s5,24(sp)
    80005110:	6161                	addi	sp,sp,80
    80005112:	8082                	ret
    iunlockput(ip);
    80005114:	8526                	mv	a0,s1
    80005116:	fffff097          	auipc	ra,0xfffff
    8000511a:	870080e7          	jalr	-1936(ra) # 80003986 <iunlockput>
    return 0;
    8000511e:	4481                	li	s1,0
    80005120:	b7c5                	j	80005100 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005122:	85ce                	mv	a1,s3
    80005124:	00092503          	lw	a0,0(s2)
    80005128:	ffffe097          	auipc	ra,0xffffe
    8000512c:	464080e7          	jalr	1124(ra) # 8000358c <ialloc>
    80005130:	84aa                	mv	s1,a0
    80005132:	c521                	beqz	a0,8000517a <create+0xec>
  ilock(ip);
    80005134:	ffffe097          	auipc	ra,0xffffe
    80005138:	5f0080e7          	jalr	1520(ra) # 80003724 <ilock>
  ip->major = major;
    8000513c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005140:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005144:	4a05                	li	s4,1
    80005146:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000514a:	8526                	mv	a0,s1
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	50e080e7          	jalr	1294(ra) # 8000365a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005154:	2981                	sext.w	s3,s3
    80005156:	03498a63          	beq	s3,s4,8000518a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000515a:	40d0                	lw	a2,4(s1)
    8000515c:	fb040593          	addi	a1,s0,-80
    80005160:	854a                	mv	a0,s2
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	cb4080e7          	jalr	-844(ra) # 80003e16 <dirlink>
    8000516a:	06054b63          	bltz	a0,800051e0 <create+0x152>
  iunlockput(dp);
    8000516e:	854a                	mv	a0,s2
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	816080e7          	jalr	-2026(ra) # 80003986 <iunlockput>
  return ip;
    80005178:	b761                	j	80005100 <create+0x72>
    panic("create: ialloc");
    8000517a:	00003517          	auipc	a0,0x3
    8000517e:	51650513          	addi	a0,a0,1302 # 80008690 <syscalls+0x2b0>
    80005182:	ffffb097          	auipc	ra,0xffffb
    80005186:	3c0080e7          	jalr	960(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    8000518a:	04a95783          	lhu	a5,74(s2)
    8000518e:	2785                	addiw	a5,a5,1
    80005190:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005194:	854a                	mv	a0,s2
    80005196:	ffffe097          	auipc	ra,0xffffe
    8000519a:	4c4080e7          	jalr	1220(ra) # 8000365a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000519e:	40d0                	lw	a2,4(s1)
    800051a0:	00003597          	auipc	a1,0x3
    800051a4:	50058593          	addi	a1,a1,1280 # 800086a0 <syscalls+0x2c0>
    800051a8:	8526                	mv	a0,s1
    800051aa:	fffff097          	auipc	ra,0xfffff
    800051ae:	c6c080e7          	jalr	-916(ra) # 80003e16 <dirlink>
    800051b2:	00054f63          	bltz	a0,800051d0 <create+0x142>
    800051b6:	00492603          	lw	a2,4(s2)
    800051ba:	00003597          	auipc	a1,0x3
    800051be:	4ee58593          	addi	a1,a1,1262 # 800086a8 <syscalls+0x2c8>
    800051c2:	8526                	mv	a0,s1
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	c52080e7          	jalr	-942(ra) # 80003e16 <dirlink>
    800051cc:	f80557e3          	bgez	a0,8000515a <create+0xcc>
      panic("create dots");
    800051d0:	00003517          	auipc	a0,0x3
    800051d4:	4e050513          	addi	a0,a0,1248 # 800086b0 <syscalls+0x2d0>
    800051d8:	ffffb097          	auipc	ra,0xffffb
    800051dc:	36a080e7          	jalr	874(ra) # 80000542 <panic>
    panic("create: dirlink");
    800051e0:	00003517          	auipc	a0,0x3
    800051e4:	4e050513          	addi	a0,a0,1248 # 800086c0 <syscalls+0x2e0>
    800051e8:	ffffb097          	auipc	ra,0xffffb
    800051ec:	35a080e7          	jalr	858(ra) # 80000542 <panic>
    return 0;
    800051f0:	84aa                	mv	s1,a0
    800051f2:	b739                	j	80005100 <create+0x72>

00000000800051f4 <sys_dup>:
{
    800051f4:	7179                	addi	sp,sp,-48
    800051f6:	f406                	sd	ra,40(sp)
    800051f8:	f022                	sd	s0,32(sp)
    800051fa:	ec26                	sd	s1,24(sp)
    800051fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051fe:	fd840613          	addi	a2,s0,-40
    80005202:	4581                	li	a1,0
    80005204:	4501                	li	a0,0
    80005206:	00000097          	auipc	ra,0x0
    8000520a:	dde080e7          	jalr	-546(ra) # 80004fe4 <argfd>
    return -1;
    8000520e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005210:	02054363          	bltz	a0,80005236 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005214:	fd843503          	ld	a0,-40(s0)
    80005218:	00000097          	auipc	ra,0x0
    8000521c:	e34080e7          	jalr	-460(ra) # 8000504c <fdalloc>
    80005220:	84aa                	mv	s1,a0
    return -1;
    80005222:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005224:	00054963          	bltz	a0,80005236 <sys_dup+0x42>
  filedup(f);
    80005228:	fd843503          	ld	a0,-40(s0)
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	338080e7          	jalr	824(ra) # 80004564 <filedup>
  return fd;
    80005234:	87a6                	mv	a5,s1
}
    80005236:	853e                	mv	a0,a5
    80005238:	70a2                	ld	ra,40(sp)
    8000523a:	7402                	ld	s0,32(sp)
    8000523c:	64e2                	ld	s1,24(sp)
    8000523e:	6145                	addi	sp,sp,48
    80005240:	8082                	ret

0000000080005242 <sys_read>:
{
    80005242:	7179                	addi	sp,sp,-48
    80005244:	f406                	sd	ra,40(sp)
    80005246:	f022                	sd	s0,32(sp)
    80005248:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524a:	fe840613          	addi	a2,s0,-24
    8000524e:	4581                	li	a1,0
    80005250:	4501                	li	a0,0
    80005252:	00000097          	auipc	ra,0x0
    80005256:	d92080e7          	jalr	-622(ra) # 80004fe4 <argfd>
    return -1;
    8000525a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525c:	04054163          	bltz	a0,8000529e <sys_read+0x5c>
    80005260:	fe440593          	addi	a1,s0,-28
    80005264:	4509                	li	a0,2
    80005266:	ffffe097          	auipc	ra,0xffffe
    8000526a:	8ec080e7          	jalr	-1812(ra) # 80002b52 <argint>
    return -1;
    8000526e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005270:	02054763          	bltz	a0,8000529e <sys_read+0x5c>
    80005274:	fd840593          	addi	a1,s0,-40
    80005278:	4505                	li	a0,1
    8000527a:	ffffe097          	auipc	ra,0xffffe
    8000527e:	8fa080e7          	jalr	-1798(ra) # 80002b74 <argaddr>
    return -1;
    80005282:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005284:	00054d63          	bltz	a0,8000529e <sys_read+0x5c>
  return fileread(f, p, n);
    80005288:	fe442603          	lw	a2,-28(s0)
    8000528c:	fd843583          	ld	a1,-40(s0)
    80005290:	fe843503          	ld	a0,-24(s0)
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	45c080e7          	jalr	1116(ra) # 800046f0 <fileread>
    8000529c:	87aa                	mv	a5,a0
}
    8000529e:	853e                	mv	a0,a5
    800052a0:	70a2                	ld	ra,40(sp)
    800052a2:	7402                	ld	s0,32(sp)
    800052a4:	6145                	addi	sp,sp,48
    800052a6:	8082                	ret

00000000800052a8 <sys_write>:
{
    800052a8:	7179                	addi	sp,sp,-48
    800052aa:	f406                	sd	ra,40(sp)
    800052ac:	f022                	sd	s0,32(sp)
    800052ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b0:	fe840613          	addi	a2,s0,-24
    800052b4:	4581                	li	a1,0
    800052b6:	4501                	li	a0,0
    800052b8:	00000097          	auipc	ra,0x0
    800052bc:	d2c080e7          	jalr	-724(ra) # 80004fe4 <argfd>
    return -1;
    800052c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c2:	04054163          	bltz	a0,80005304 <sys_write+0x5c>
    800052c6:	fe440593          	addi	a1,s0,-28
    800052ca:	4509                	li	a0,2
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	886080e7          	jalr	-1914(ra) # 80002b52 <argint>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d6:	02054763          	bltz	a0,80005304 <sys_write+0x5c>
    800052da:	fd840593          	addi	a1,s0,-40
    800052de:	4505                	li	a0,1
    800052e0:	ffffe097          	auipc	ra,0xffffe
    800052e4:	894080e7          	jalr	-1900(ra) # 80002b74 <argaddr>
    return -1;
    800052e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ea:	00054d63          	bltz	a0,80005304 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052ee:	fe442603          	lw	a2,-28(s0)
    800052f2:	fd843583          	ld	a1,-40(s0)
    800052f6:	fe843503          	ld	a0,-24(s0)
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	4b8080e7          	jalr	1208(ra) # 800047b2 <filewrite>
    80005302:	87aa                	mv	a5,a0
}
    80005304:	853e                	mv	a0,a5
    80005306:	70a2                	ld	ra,40(sp)
    80005308:	7402                	ld	s0,32(sp)
    8000530a:	6145                	addi	sp,sp,48
    8000530c:	8082                	ret

000000008000530e <sys_close>:
{
    8000530e:	1101                	addi	sp,sp,-32
    80005310:	ec06                	sd	ra,24(sp)
    80005312:	e822                	sd	s0,16(sp)
    80005314:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005316:	fe040613          	addi	a2,s0,-32
    8000531a:	fec40593          	addi	a1,s0,-20
    8000531e:	4501                	li	a0,0
    80005320:	00000097          	auipc	ra,0x0
    80005324:	cc4080e7          	jalr	-828(ra) # 80004fe4 <argfd>
    return -1;
    80005328:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000532a:	02054463          	bltz	a0,80005352 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	6da080e7          	jalr	1754(ra) # 80001a08 <myproc>
    80005336:	fec42783          	lw	a5,-20(s0)
    8000533a:	07e9                	addi	a5,a5,26
    8000533c:	078e                	slli	a5,a5,0x3
    8000533e:	97aa                	add	a5,a5,a0
    80005340:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005344:	fe043503          	ld	a0,-32(s0)
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	26e080e7          	jalr	622(ra) # 800045b6 <fileclose>
  return 0;
    80005350:	4781                	li	a5,0
}
    80005352:	853e                	mv	a0,a5
    80005354:	60e2                	ld	ra,24(sp)
    80005356:	6442                	ld	s0,16(sp)
    80005358:	6105                	addi	sp,sp,32
    8000535a:	8082                	ret

000000008000535c <sys_fstat>:
{
    8000535c:	1101                	addi	sp,sp,-32
    8000535e:	ec06                	sd	ra,24(sp)
    80005360:	e822                	sd	s0,16(sp)
    80005362:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005364:	fe840613          	addi	a2,s0,-24
    80005368:	4581                	li	a1,0
    8000536a:	4501                	li	a0,0
    8000536c:	00000097          	auipc	ra,0x0
    80005370:	c78080e7          	jalr	-904(ra) # 80004fe4 <argfd>
    return -1;
    80005374:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005376:	02054563          	bltz	a0,800053a0 <sys_fstat+0x44>
    8000537a:	fe040593          	addi	a1,s0,-32
    8000537e:	4505                	li	a0,1
    80005380:	ffffd097          	auipc	ra,0xffffd
    80005384:	7f4080e7          	jalr	2036(ra) # 80002b74 <argaddr>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000538a:	00054b63          	bltz	a0,800053a0 <sys_fstat+0x44>
  return filestat(f, st);
    8000538e:	fe043583          	ld	a1,-32(s0)
    80005392:	fe843503          	ld	a0,-24(s0)
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	2e8080e7          	jalr	744(ra) # 8000467e <filestat>
    8000539e:	87aa                	mv	a5,a0
}
    800053a0:	853e                	mv	a0,a5
    800053a2:	60e2                	ld	ra,24(sp)
    800053a4:	6442                	ld	s0,16(sp)
    800053a6:	6105                	addi	sp,sp,32
    800053a8:	8082                	ret

00000000800053aa <sys_link>:
{
    800053aa:	7169                	addi	sp,sp,-304
    800053ac:	f606                	sd	ra,296(sp)
    800053ae:	f222                	sd	s0,288(sp)
    800053b0:	ee26                	sd	s1,280(sp)
    800053b2:	ea4a                	sd	s2,272(sp)
    800053b4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b6:	08000613          	li	a2,128
    800053ba:	ed040593          	addi	a1,s0,-304
    800053be:	4501                	li	a0,0
    800053c0:	ffffd097          	auipc	ra,0xffffd
    800053c4:	7d6080e7          	jalr	2006(ra) # 80002b96 <argstr>
    return -1;
    800053c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ca:	10054e63          	bltz	a0,800054e6 <sys_link+0x13c>
    800053ce:	08000613          	li	a2,128
    800053d2:	f5040593          	addi	a1,s0,-176
    800053d6:	4505                	li	a0,1
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	7be080e7          	jalr	1982(ra) # 80002b96 <argstr>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053e2:	10054263          	bltz	a0,800054e6 <sys_link+0x13c>
  begin_op();
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	cfe080e7          	jalr	-770(ra) # 800040e4 <begin_op>
  if((ip = namei(old)) == 0){
    800053ee:	ed040513          	addi	a0,s0,-304
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	ae6080e7          	jalr	-1306(ra) # 80003ed8 <namei>
    800053fa:	84aa                	mv	s1,a0
    800053fc:	c551                	beqz	a0,80005488 <sys_link+0xde>
  ilock(ip);
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	326080e7          	jalr	806(ra) # 80003724 <ilock>
  if(ip->type == T_DIR){
    80005406:	04449703          	lh	a4,68(s1)
    8000540a:	4785                	li	a5,1
    8000540c:	08f70463          	beq	a4,a5,80005494 <sys_link+0xea>
  ip->nlink++;
    80005410:	04a4d783          	lhu	a5,74(s1)
    80005414:	2785                	addiw	a5,a5,1
    80005416:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000541a:	8526                	mv	a0,s1
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	23e080e7          	jalr	574(ra) # 8000365a <iupdate>
  iunlock(ip);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffe097          	auipc	ra,0xffffe
    8000542a:	3c0080e7          	jalr	960(ra) # 800037e6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000542e:	fd040593          	addi	a1,s0,-48
    80005432:	f5040513          	addi	a0,s0,-176
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	ac0080e7          	jalr	-1344(ra) # 80003ef6 <nameiparent>
    8000543e:	892a                	mv	s2,a0
    80005440:	c935                	beqz	a0,800054b4 <sys_link+0x10a>
  ilock(dp);
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	2e2080e7          	jalr	738(ra) # 80003724 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000544a:	00092703          	lw	a4,0(s2)
    8000544e:	409c                	lw	a5,0(s1)
    80005450:	04f71d63          	bne	a4,a5,800054aa <sys_link+0x100>
    80005454:	40d0                	lw	a2,4(s1)
    80005456:	fd040593          	addi	a1,s0,-48
    8000545a:	854a                	mv	a0,s2
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	9ba080e7          	jalr	-1606(ra) # 80003e16 <dirlink>
    80005464:	04054363          	bltz	a0,800054aa <sys_link+0x100>
  iunlockput(dp);
    80005468:	854a                	mv	a0,s2
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	51c080e7          	jalr	1308(ra) # 80003986 <iunlockput>
  iput(ip);
    80005472:	8526                	mv	a0,s1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	46a080e7          	jalr	1130(ra) # 800038de <iput>
  end_op();
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	ce8080e7          	jalr	-792(ra) # 80004164 <end_op>
  return 0;
    80005484:	4781                	li	a5,0
    80005486:	a085                	j	800054e6 <sys_link+0x13c>
    end_op();
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	cdc080e7          	jalr	-804(ra) # 80004164 <end_op>
    return -1;
    80005490:	57fd                	li	a5,-1
    80005492:	a891                	j	800054e6 <sys_link+0x13c>
    iunlockput(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	4f0080e7          	jalr	1264(ra) # 80003986 <iunlockput>
    end_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	cc6080e7          	jalr	-826(ra) # 80004164 <end_op>
    return -1;
    800054a6:	57fd                	li	a5,-1
    800054a8:	a83d                	j	800054e6 <sys_link+0x13c>
    iunlockput(dp);
    800054aa:	854a                	mv	a0,s2
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	4da080e7          	jalr	1242(ra) # 80003986 <iunlockput>
  ilock(ip);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	26e080e7          	jalr	622(ra) # 80003724 <ilock>
  ip->nlink--;
    800054be:	04a4d783          	lhu	a5,74(s1)
    800054c2:	37fd                	addiw	a5,a5,-1
    800054c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	190080e7          	jalr	400(ra) # 8000365a <iupdate>
  iunlockput(ip);
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	4b2080e7          	jalr	1202(ra) # 80003986 <iunlockput>
  end_op();
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	c88080e7          	jalr	-888(ra) # 80004164 <end_op>
  return -1;
    800054e4:	57fd                	li	a5,-1
}
    800054e6:	853e                	mv	a0,a5
    800054e8:	70b2                	ld	ra,296(sp)
    800054ea:	7412                	ld	s0,288(sp)
    800054ec:	64f2                	ld	s1,280(sp)
    800054ee:	6952                	ld	s2,272(sp)
    800054f0:	6155                	addi	sp,sp,304
    800054f2:	8082                	ret

00000000800054f4 <sys_unlink>:
{
    800054f4:	7151                	addi	sp,sp,-240
    800054f6:	f586                	sd	ra,232(sp)
    800054f8:	f1a2                	sd	s0,224(sp)
    800054fa:	eda6                	sd	s1,216(sp)
    800054fc:	e9ca                	sd	s2,208(sp)
    800054fe:	e5ce                	sd	s3,200(sp)
    80005500:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005502:	08000613          	li	a2,128
    80005506:	f3040593          	addi	a1,s0,-208
    8000550a:	4501                	li	a0,0
    8000550c:	ffffd097          	auipc	ra,0xffffd
    80005510:	68a080e7          	jalr	1674(ra) # 80002b96 <argstr>
    80005514:	18054163          	bltz	a0,80005696 <sys_unlink+0x1a2>
  begin_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	bcc080e7          	jalr	-1076(ra) # 800040e4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005520:	fb040593          	addi	a1,s0,-80
    80005524:	f3040513          	addi	a0,s0,-208
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	9ce080e7          	jalr	-1586(ra) # 80003ef6 <nameiparent>
    80005530:	84aa                	mv	s1,a0
    80005532:	c979                	beqz	a0,80005608 <sys_unlink+0x114>
  ilock(dp);
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	1f0080e7          	jalr	496(ra) # 80003724 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000553c:	00003597          	auipc	a1,0x3
    80005540:	16458593          	addi	a1,a1,356 # 800086a0 <syscalls+0x2c0>
    80005544:	fb040513          	addi	a0,s0,-80
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	6a4080e7          	jalr	1700(ra) # 80003bec <namecmp>
    80005550:	14050a63          	beqz	a0,800056a4 <sys_unlink+0x1b0>
    80005554:	00003597          	auipc	a1,0x3
    80005558:	15458593          	addi	a1,a1,340 # 800086a8 <syscalls+0x2c8>
    8000555c:	fb040513          	addi	a0,s0,-80
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	68c080e7          	jalr	1676(ra) # 80003bec <namecmp>
    80005568:	12050e63          	beqz	a0,800056a4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000556c:	f2c40613          	addi	a2,s0,-212
    80005570:	fb040593          	addi	a1,s0,-80
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	690080e7          	jalr	1680(ra) # 80003c06 <dirlookup>
    8000557e:	892a                	mv	s2,a0
    80005580:	12050263          	beqz	a0,800056a4 <sys_unlink+0x1b0>
  ilock(ip);
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	1a0080e7          	jalr	416(ra) # 80003724 <ilock>
  if(ip->nlink < 1)
    8000558c:	04a91783          	lh	a5,74(s2)
    80005590:	08f05263          	blez	a5,80005614 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005594:	04491703          	lh	a4,68(s2)
    80005598:	4785                	li	a5,1
    8000559a:	08f70563          	beq	a4,a5,80005624 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000559e:	4641                	li	a2,16
    800055a0:	4581                	li	a1,0
    800055a2:	fc040513          	addi	a0,s0,-64
    800055a6:	ffffb097          	auipc	ra,0xffffb
    800055aa:	754080e7          	jalr	1876(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ae:	4741                	li	a4,16
    800055b0:	f2c42683          	lw	a3,-212(s0)
    800055b4:	fc040613          	addi	a2,s0,-64
    800055b8:	4581                	li	a1,0
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	514080e7          	jalr	1300(ra) # 80003ad0 <writei>
    800055c4:	47c1                	li	a5,16
    800055c6:	0af51563          	bne	a0,a5,80005670 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ca:	04491703          	lh	a4,68(s2)
    800055ce:	4785                	li	a5,1
    800055d0:	0af70863          	beq	a4,a5,80005680 <sys_unlink+0x18c>
  iunlockput(dp);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	3b0080e7          	jalr	944(ra) # 80003986 <iunlockput>
  ip->nlink--;
    800055de:	04a95783          	lhu	a5,74(s2)
    800055e2:	37fd                	addiw	a5,a5,-1
    800055e4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055e8:	854a                	mv	a0,s2
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	070080e7          	jalr	112(ra) # 8000365a <iupdate>
  iunlockput(ip);
    800055f2:	854a                	mv	a0,s2
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	392080e7          	jalr	914(ra) # 80003986 <iunlockput>
  end_op();
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	b68080e7          	jalr	-1176(ra) # 80004164 <end_op>
  return 0;
    80005604:	4501                	li	a0,0
    80005606:	a84d                	j	800056b8 <sys_unlink+0x1c4>
    end_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	b5c080e7          	jalr	-1188(ra) # 80004164 <end_op>
    return -1;
    80005610:	557d                	li	a0,-1
    80005612:	a05d                	j	800056b8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005614:	00003517          	auipc	a0,0x3
    80005618:	0bc50513          	addi	a0,a0,188 # 800086d0 <syscalls+0x2f0>
    8000561c:	ffffb097          	auipc	ra,0xffffb
    80005620:	f26080e7          	jalr	-218(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005624:	04c92703          	lw	a4,76(s2)
    80005628:	02000793          	li	a5,32
    8000562c:	f6e7f9e3          	bgeu	a5,a4,8000559e <sys_unlink+0xaa>
    80005630:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005634:	4741                	li	a4,16
    80005636:	86ce                	mv	a3,s3
    80005638:	f1840613          	addi	a2,s0,-232
    8000563c:	4581                	li	a1,0
    8000563e:	854a                	mv	a0,s2
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	398080e7          	jalr	920(ra) # 800039d8 <readi>
    80005648:	47c1                	li	a5,16
    8000564a:	00f51b63          	bne	a0,a5,80005660 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000564e:	f1845783          	lhu	a5,-232(s0)
    80005652:	e7a1                	bnez	a5,8000569a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005654:	29c1                	addiw	s3,s3,16
    80005656:	04c92783          	lw	a5,76(s2)
    8000565a:	fcf9ede3          	bltu	s3,a5,80005634 <sys_unlink+0x140>
    8000565e:	b781                	j	8000559e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005660:	00003517          	auipc	a0,0x3
    80005664:	08850513          	addi	a0,a0,136 # 800086e8 <syscalls+0x308>
    80005668:	ffffb097          	auipc	ra,0xffffb
    8000566c:	eda080e7          	jalr	-294(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005670:	00003517          	auipc	a0,0x3
    80005674:	09050513          	addi	a0,a0,144 # 80008700 <syscalls+0x320>
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	eca080e7          	jalr	-310(ra) # 80000542 <panic>
    dp->nlink--;
    80005680:	04a4d783          	lhu	a5,74(s1)
    80005684:	37fd                	addiw	a5,a5,-1
    80005686:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	fce080e7          	jalr	-50(ra) # 8000365a <iupdate>
    80005694:	b781                	j	800055d4 <sys_unlink+0xe0>
    return -1;
    80005696:	557d                	li	a0,-1
    80005698:	a005                	j	800056b8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	2ea080e7          	jalr	746(ra) # 80003986 <iunlockput>
  iunlockput(dp);
    800056a4:	8526                	mv	a0,s1
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	2e0080e7          	jalr	736(ra) # 80003986 <iunlockput>
  end_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	ab6080e7          	jalr	-1354(ra) # 80004164 <end_op>
  return -1;
    800056b6:	557d                	li	a0,-1
}
    800056b8:	70ae                	ld	ra,232(sp)
    800056ba:	740e                	ld	s0,224(sp)
    800056bc:	64ee                	ld	s1,216(sp)
    800056be:	694e                	ld	s2,208(sp)
    800056c0:	69ae                	ld	s3,200(sp)
    800056c2:	616d                	addi	sp,sp,240
    800056c4:	8082                	ret

00000000800056c6 <sys_open>:

uint64
sys_open(void)
{
    800056c6:	7131                	addi	sp,sp,-192
    800056c8:	fd06                	sd	ra,184(sp)
    800056ca:	f922                	sd	s0,176(sp)
    800056cc:	f526                	sd	s1,168(sp)
    800056ce:	f14a                	sd	s2,160(sp)
    800056d0:	ed4e                	sd	s3,152(sp)
    800056d2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056d4:	08000613          	li	a2,128
    800056d8:	f5040593          	addi	a1,s0,-176
    800056dc:	4501                	li	a0,0
    800056de:	ffffd097          	auipc	ra,0xffffd
    800056e2:	4b8080e7          	jalr	1208(ra) # 80002b96 <argstr>
    return -1;
    800056e6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056e8:	0c054163          	bltz	a0,800057aa <sys_open+0xe4>
    800056ec:	f4c40593          	addi	a1,s0,-180
    800056f0:	4505                	li	a0,1
    800056f2:	ffffd097          	auipc	ra,0xffffd
    800056f6:	460080e7          	jalr	1120(ra) # 80002b52 <argint>
    800056fa:	0a054863          	bltz	a0,800057aa <sys_open+0xe4>

  begin_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	9e6080e7          	jalr	-1562(ra) # 800040e4 <begin_op>

  if(omode & O_CREATE){
    80005706:	f4c42783          	lw	a5,-180(s0)
    8000570a:	2007f793          	andi	a5,a5,512
    8000570e:	cbdd                	beqz	a5,800057c4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005710:	4681                	li	a3,0
    80005712:	4601                	li	a2,0
    80005714:	4589                	li	a1,2
    80005716:	f5040513          	addi	a0,s0,-176
    8000571a:	00000097          	auipc	ra,0x0
    8000571e:	974080e7          	jalr	-1676(ra) # 8000508e <create>
    80005722:	892a                	mv	s2,a0
    if(ip == 0){
    80005724:	c959                	beqz	a0,800057ba <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005726:	04491703          	lh	a4,68(s2)
    8000572a:	478d                	li	a5,3
    8000572c:	00f71763          	bne	a4,a5,8000573a <sys_open+0x74>
    80005730:	04695703          	lhu	a4,70(s2)
    80005734:	47a5                	li	a5,9
    80005736:	0ce7ec63          	bltu	a5,a4,8000580e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	dc0080e7          	jalr	-576(ra) # 800044fa <filealloc>
    80005742:	89aa                	mv	s3,a0
    80005744:	10050263          	beqz	a0,80005848 <sys_open+0x182>
    80005748:	00000097          	auipc	ra,0x0
    8000574c:	904080e7          	jalr	-1788(ra) # 8000504c <fdalloc>
    80005750:	84aa                	mv	s1,a0
    80005752:	0e054663          	bltz	a0,8000583e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005756:	04491703          	lh	a4,68(s2)
    8000575a:	478d                	li	a5,3
    8000575c:	0cf70463          	beq	a4,a5,80005824 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005760:	4789                	li	a5,2
    80005762:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005766:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000576a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000576e:	f4c42783          	lw	a5,-180(s0)
    80005772:	0017c713          	xori	a4,a5,1
    80005776:	8b05                	andi	a4,a4,1
    80005778:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000577c:	0037f713          	andi	a4,a5,3
    80005780:	00e03733          	snez	a4,a4
    80005784:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005788:	4007f793          	andi	a5,a5,1024
    8000578c:	c791                	beqz	a5,80005798 <sys_open+0xd2>
    8000578e:	04491703          	lh	a4,68(s2)
    80005792:	4789                	li	a5,2
    80005794:	08f70f63          	beq	a4,a5,80005832 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005798:	854a                	mv	a0,s2
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	04c080e7          	jalr	76(ra) # 800037e6 <iunlock>
  end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	9c2080e7          	jalr	-1598(ra) # 80004164 <end_op>

  return fd;
}
    800057aa:	8526                	mv	a0,s1
    800057ac:	70ea                	ld	ra,184(sp)
    800057ae:	744a                	ld	s0,176(sp)
    800057b0:	74aa                	ld	s1,168(sp)
    800057b2:	790a                	ld	s2,160(sp)
    800057b4:	69ea                	ld	s3,152(sp)
    800057b6:	6129                	addi	sp,sp,192
    800057b8:	8082                	ret
      end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	9aa080e7          	jalr	-1622(ra) # 80004164 <end_op>
      return -1;
    800057c2:	b7e5                	j	800057aa <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057c4:	f5040513          	addi	a0,s0,-176
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	710080e7          	jalr	1808(ra) # 80003ed8 <namei>
    800057d0:	892a                	mv	s2,a0
    800057d2:	c905                	beqz	a0,80005802 <sys_open+0x13c>
    ilock(ip);
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	f50080e7          	jalr	-176(ra) # 80003724 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057dc:	04491703          	lh	a4,68(s2)
    800057e0:	4785                	li	a5,1
    800057e2:	f4f712e3          	bne	a4,a5,80005726 <sys_open+0x60>
    800057e6:	f4c42783          	lw	a5,-180(s0)
    800057ea:	dba1                	beqz	a5,8000573a <sys_open+0x74>
      iunlockput(ip);
    800057ec:	854a                	mv	a0,s2
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	198080e7          	jalr	408(ra) # 80003986 <iunlockput>
      end_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	96e080e7          	jalr	-1682(ra) # 80004164 <end_op>
      return -1;
    800057fe:	54fd                	li	s1,-1
    80005800:	b76d                	j	800057aa <sys_open+0xe4>
      end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	962080e7          	jalr	-1694(ra) # 80004164 <end_op>
      return -1;
    8000580a:	54fd                	li	s1,-1
    8000580c:	bf79                	j	800057aa <sys_open+0xe4>
    iunlockput(ip);
    8000580e:	854a                	mv	a0,s2
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	176080e7          	jalr	374(ra) # 80003986 <iunlockput>
    end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	94c080e7          	jalr	-1716(ra) # 80004164 <end_op>
    return -1;
    80005820:	54fd                	li	s1,-1
    80005822:	b761                	j	800057aa <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005824:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005828:	04691783          	lh	a5,70(s2)
    8000582c:	02f99223          	sh	a5,36(s3)
    80005830:	bf2d                	j	8000576a <sys_open+0xa4>
    itrunc(ip);
    80005832:	854a                	mv	a0,s2
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	ffe080e7          	jalr	-2(ra) # 80003832 <itrunc>
    8000583c:	bfb1                	j	80005798 <sys_open+0xd2>
      fileclose(f);
    8000583e:	854e                	mv	a0,s3
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	d76080e7          	jalr	-650(ra) # 800045b6 <fileclose>
    iunlockput(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	13c080e7          	jalr	316(ra) # 80003986 <iunlockput>
    end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	912080e7          	jalr	-1774(ra) # 80004164 <end_op>
    return -1;
    8000585a:	54fd                	li	s1,-1
    8000585c:	b7b9                	j	800057aa <sys_open+0xe4>

000000008000585e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000585e:	7175                	addi	sp,sp,-144
    80005860:	e506                	sd	ra,136(sp)
    80005862:	e122                	sd	s0,128(sp)
    80005864:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	87e080e7          	jalr	-1922(ra) # 800040e4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000586e:	08000613          	li	a2,128
    80005872:	f7040593          	addi	a1,s0,-144
    80005876:	4501                	li	a0,0
    80005878:	ffffd097          	auipc	ra,0xffffd
    8000587c:	31e080e7          	jalr	798(ra) # 80002b96 <argstr>
    80005880:	02054963          	bltz	a0,800058b2 <sys_mkdir+0x54>
    80005884:	4681                	li	a3,0
    80005886:	4601                	li	a2,0
    80005888:	4585                	li	a1,1
    8000588a:	f7040513          	addi	a0,s0,-144
    8000588e:	00000097          	auipc	ra,0x0
    80005892:	800080e7          	jalr	-2048(ra) # 8000508e <create>
    80005896:	cd11                	beqz	a0,800058b2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	0ee080e7          	jalr	238(ra) # 80003986 <iunlockput>
  end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	8c4080e7          	jalr	-1852(ra) # 80004164 <end_op>
  return 0;
    800058a8:	4501                	li	a0,0
}
    800058aa:	60aa                	ld	ra,136(sp)
    800058ac:	640a                	ld	s0,128(sp)
    800058ae:	6149                	addi	sp,sp,144
    800058b0:	8082                	ret
    end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	8b2080e7          	jalr	-1870(ra) # 80004164 <end_op>
    return -1;
    800058ba:	557d                	li	a0,-1
    800058bc:	b7fd                	j	800058aa <sys_mkdir+0x4c>

00000000800058be <sys_mknod>:

uint64
sys_mknod(void)
{
    800058be:	7135                	addi	sp,sp,-160
    800058c0:	ed06                	sd	ra,152(sp)
    800058c2:	e922                	sd	s0,144(sp)
    800058c4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	81e080e7          	jalr	-2018(ra) # 800040e4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ce:	08000613          	li	a2,128
    800058d2:	f7040593          	addi	a1,s0,-144
    800058d6:	4501                	li	a0,0
    800058d8:	ffffd097          	auipc	ra,0xffffd
    800058dc:	2be080e7          	jalr	702(ra) # 80002b96 <argstr>
    800058e0:	04054a63          	bltz	a0,80005934 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058e4:	f6c40593          	addi	a1,s0,-148
    800058e8:	4505                	li	a0,1
    800058ea:	ffffd097          	auipc	ra,0xffffd
    800058ee:	268080e7          	jalr	616(ra) # 80002b52 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058f2:	04054163          	bltz	a0,80005934 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058f6:	f6840593          	addi	a1,s0,-152
    800058fa:	4509                	li	a0,2
    800058fc:	ffffd097          	auipc	ra,0xffffd
    80005900:	256080e7          	jalr	598(ra) # 80002b52 <argint>
     argint(1, &major) < 0 ||
    80005904:	02054863          	bltz	a0,80005934 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005908:	f6841683          	lh	a3,-152(s0)
    8000590c:	f6c41603          	lh	a2,-148(s0)
    80005910:	458d                	li	a1,3
    80005912:	f7040513          	addi	a0,s0,-144
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	778080e7          	jalr	1912(ra) # 8000508e <create>
     argint(2, &minor) < 0 ||
    8000591e:	c919                	beqz	a0,80005934 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	066080e7          	jalr	102(ra) # 80003986 <iunlockput>
  end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	83c080e7          	jalr	-1988(ra) # 80004164 <end_op>
  return 0;
    80005930:	4501                	li	a0,0
    80005932:	a031                	j	8000593e <sys_mknod+0x80>
    end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	830080e7          	jalr	-2000(ra) # 80004164 <end_op>
    return -1;
    8000593c:	557d                	li	a0,-1
}
    8000593e:	60ea                	ld	ra,152(sp)
    80005940:	644a                	ld	s0,144(sp)
    80005942:	610d                	addi	sp,sp,160
    80005944:	8082                	ret

0000000080005946 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005946:	7135                	addi	sp,sp,-160
    80005948:	ed06                	sd	ra,152(sp)
    8000594a:	e922                	sd	s0,144(sp)
    8000594c:	e526                	sd	s1,136(sp)
    8000594e:	e14a                	sd	s2,128(sp)
    80005950:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005952:	ffffc097          	auipc	ra,0xffffc
    80005956:	0b6080e7          	jalr	182(ra) # 80001a08 <myproc>
    8000595a:	892a                	mv	s2,a0
  
  begin_op();
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	788080e7          	jalr	1928(ra) # 800040e4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005964:	08000613          	li	a2,128
    80005968:	f6040593          	addi	a1,s0,-160
    8000596c:	4501                	li	a0,0
    8000596e:	ffffd097          	auipc	ra,0xffffd
    80005972:	228080e7          	jalr	552(ra) # 80002b96 <argstr>
    80005976:	04054b63          	bltz	a0,800059cc <sys_chdir+0x86>
    8000597a:	f6040513          	addi	a0,s0,-160
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	55a080e7          	jalr	1370(ra) # 80003ed8 <namei>
    80005986:	84aa                	mv	s1,a0
    80005988:	c131                	beqz	a0,800059cc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	d9a080e7          	jalr	-614(ra) # 80003724 <ilock>
  if(ip->type != T_DIR){
    80005992:	04449703          	lh	a4,68(s1)
    80005996:	4785                	li	a5,1
    80005998:	04f71063          	bne	a4,a5,800059d8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	e48080e7          	jalr	-440(ra) # 800037e6 <iunlock>
  iput(p->cwd);
    800059a6:	15093503          	ld	a0,336(s2)
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	f34080e7          	jalr	-204(ra) # 800038de <iput>
  end_op();
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	7b2080e7          	jalr	1970(ra) # 80004164 <end_op>
  p->cwd = ip;
    800059ba:	14993823          	sd	s1,336(s2)
  return 0;
    800059be:	4501                	li	a0,0
}
    800059c0:	60ea                	ld	ra,152(sp)
    800059c2:	644a                	ld	s0,144(sp)
    800059c4:	64aa                	ld	s1,136(sp)
    800059c6:	690a                	ld	s2,128(sp)
    800059c8:	610d                	addi	sp,sp,160
    800059ca:	8082                	ret
    end_op();
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	798080e7          	jalr	1944(ra) # 80004164 <end_op>
    return -1;
    800059d4:	557d                	li	a0,-1
    800059d6:	b7ed                	j	800059c0 <sys_chdir+0x7a>
    iunlockput(ip);
    800059d8:	8526                	mv	a0,s1
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	fac080e7          	jalr	-84(ra) # 80003986 <iunlockput>
    end_op();
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	782080e7          	jalr	1922(ra) # 80004164 <end_op>
    return -1;
    800059ea:	557d                	li	a0,-1
    800059ec:	bfd1                	j	800059c0 <sys_chdir+0x7a>

00000000800059ee <sys_exec>:

uint64
sys_exec(void)
{
    800059ee:	7145                	addi	sp,sp,-464
    800059f0:	e786                	sd	ra,456(sp)
    800059f2:	e3a2                	sd	s0,448(sp)
    800059f4:	ff26                	sd	s1,440(sp)
    800059f6:	fb4a                	sd	s2,432(sp)
    800059f8:	f74e                	sd	s3,424(sp)
    800059fa:	f352                	sd	s4,416(sp)
    800059fc:	ef56                	sd	s5,408(sp)
    800059fe:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a00:	08000613          	li	a2,128
    80005a04:	f4040593          	addi	a1,s0,-192
    80005a08:	4501                	li	a0,0
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	18c080e7          	jalr	396(ra) # 80002b96 <argstr>
    return -1;
    80005a12:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a14:	0c054a63          	bltz	a0,80005ae8 <sys_exec+0xfa>
    80005a18:	e3840593          	addi	a1,s0,-456
    80005a1c:	4505                	li	a0,1
    80005a1e:	ffffd097          	auipc	ra,0xffffd
    80005a22:	156080e7          	jalr	342(ra) # 80002b74 <argaddr>
    80005a26:	0c054163          	bltz	a0,80005ae8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a2a:	10000613          	li	a2,256
    80005a2e:	4581                	li	a1,0
    80005a30:	e4040513          	addi	a0,s0,-448
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	2c6080e7          	jalr	710(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a3c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a40:	89a6                	mv	s3,s1
    80005a42:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a44:	02000a13          	li	s4,32
    80005a48:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a4c:	00391793          	slli	a5,s2,0x3
    80005a50:	e3040593          	addi	a1,s0,-464
    80005a54:	e3843503          	ld	a0,-456(s0)
    80005a58:	953e                	add	a0,a0,a5
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	05e080e7          	jalr	94(ra) # 80002ab8 <fetchaddr>
    80005a62:	02054a63          	bltz	a0,80005a96 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a66:	e3043783          	ld	a5,-464(s0)
    80005a6a:	c3b9                	beqz	a5,80005ab0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a6c:	ffffb097          	auipc	ra,0xffffb
    80005a70:	0a2080e7          	jalr	162(ra) # 80000b0e <kalloc>
    80005a74:	85aa                	mv	a1,a0
    80005a76:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a7a:	cd11                	beqz	a0,80005a96 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a7c:	6605                	lui	a2,0x1
    80005a7e:	e3043503          	ld	a0,-464(s0)
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	088080e7          	jalr	136(ra) # 80002b0a <fetchstr>
    80005a8a:	00054663          	bltz	a0,80005a96 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a8e:	0905                	addi	s2,s2,1
    80005a90:	09a1                	addi	s3,s3,8
    80005a92:	fb491be3          	bne	s2,s4,80005a48 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a96:	10048913          	addi	s2,s1,256
    80005a9a:	6088                	ld	a0,0(s1)
    80005a9c:	c529                	beqz	a0,80005ae6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	f74080e7          	jalr	-140(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa6:	04a1                	addi	s1,s1,8
    80005aa8:	ff2499e3          	bne	s1,s2,80005a9a <sys_exec+0xac>
  return -1;
    80005aac:	597d                	li	s2,-1
    80005aae:	a82d                	j	80005ae8 <sys_exec+0xfa>
      argv[i] = 0;
    80005ab0:	0a8e                	slli	s5,s5,0x3
    80005ab2:	fc040793          	addi	a5,s0,-64
    80005ab6:	9abe                	add	s5,s5,a5
    80005ab8:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005abc:	e4040593          	addi	a1,s0,-448
    80005ac0:	f4040513          	addi	a0,s0,-192
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	178080e7          	jalr	376(ra) # 80004c3c <exec>
    80005acc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ace:	10048993          	addi	s3,s1,256
    80005ad2:	6088                	ld	a0,0(s1)
    80005ad4:	c911                	beqz	a0,80005ae8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	f3c080e7          	jalr	-196(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ade:	04a1                	addi	s1,s1,8
    80005ae0:	ff3499e3          	bne	s1,s3,80005ad2 <sys_exec+0xe4>
    80005ae4:	a011                	j	80005ae8 <sys_exec+0xfa>
  return -1;
    80005ae6:	597d                	li	s2,-1
}
    80005ae8:	854a                	mv	a0,s2
    80005aea:	60be                	ld	ra,456(sp)
    80005aec:	641e                	ld	s0,448(sp)
    80005aee:	74fa                	ld	s1,440(sp)
    80005af0:	795a                	ld	s2,432(sp)
    80005af2:	79ba                	ld	s3,424(sp)
    80005af4:	7a1a                	ld	s4,416(sp)
    80005af6:	6afa                	ld	s5,408(sp)
    80005af8:	6179                	addi	sp,sp,464
    80005afa:	8082                	ret

0000000080005afc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005afc:	7139                	addi	sp,sp,-64
    80005afe:	fc06                	sd	ra,56(sp)
    80005b00:	f822                	sd	s0,48(sp)
    80005b02:	f426                	sd	s1,40(sp)
    80005b04:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b06:	ffffc097          	auipc	ra,0xffffc
    80005b0a:	f02080e7          	jalr	-254(ra) # 80001a08 <myproc>
    80005b0e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b10:	fd840593          	addi	a1,s0,-40
    80005b14:	4501                	li	a0,0
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	05e080e7          	jalr	94(ra) # 80002b74 <argaddr>
    return -1;
    80005b1e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b20:	0e054063          	bltz	a0,80005c00 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b24:	fc840593          	addi	a1,s0,-56
    80005b28:	fd040513          	addi	a0,s0,-48
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	de0080e7          	jalr	-544(ra) # 8000490c <pipealloc>
    return -1;
    80005b34:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b36:	0c054563          	bltz	a0,80005c00 <sys_pipe+0x104>
  fd0 = -1;
    80005b3a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b3e:	fd043503          	ld	a0,-48(s0)
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	50a080e7          	jalr	1290(ra) # 8000504c <fdalloc>
    80005b4a:	fca42223          	sw	a0,-60(s0)
    80005b4e:	08054c63          	bltz	a0,80005be6 <sys_pipe+0xea>
    80005b52:	fc843503          	ld	a0,-56(s0)
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	4f6080e7          	jalr	1270(ra) # 8000504c <fdalloc>
    80005b5e:	fca42023          	sw	a0,-64(s0)
    80005b62:	06054863          	bltz	a0,80005bd2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b66:	4691                	li	a3,4
    80005b68:	fc440613          	addi	a2,s0,-60
    80005b6c:	fd843583          	ld	a1,-40(s0)
    80005b70:	68a8                	ld	a0,80(s1)
    80005b72:	ffffc097          	auipc	ra,0xffffc
    80005b76:	b88080e7          	jalr	-1144(ra) # 800016fa <copyout>
    80005b7a:	02054063          	bltz	a0,80005b9a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b7e:	4691                	li	a3,4
    80005b80:	fc040613          	addi	a2,s0,-64
    80005b84:	fd843583          	ld	a1,-40(s0)
    80005b88:	0591                	addi	a1,a1,4
    80005b8a:	68a8                	ld	a0,80(s1)
    80005b8c:	ffffc097          	auipc	ra,0xffffc
    80005b90:	b6e080e7          	jalr	-1170(ra) # 800016fa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b94:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b96:	06055563          	bgez	a0,80005c00 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b9a:	fc442783          	lw	a5,-60(s0)
    80005b9e:	07e9                	addi	a5,a5,26
    80005ba0:	078e                	slli	a5,a5,0x3
    80005ba2:	97a6                	add	a5,a5,s1
    80005ba4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ba8:	fc042503          	lw	a0,-64(s0)
    80005bac:	0569                	addi	a0,a0,26
    80005bae:	050e                	slli	a0,a0,0x3
    80005bb0:	9526                	add	a0,a0,s1
    80005bb2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bb6:	fd043503          	ld	a0,-48(s0)
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	9fc080e7          	jalr	-1540(ra) # 800045b6 <fileclose>
    fileclose(wf);
    80005bc2:	fc843503          	ld	a0,-56(s0)
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	9f0080e7          	jalr	-1552(ra) # 800045b6 <fileclose>
    return -1;
    80005bce:	57fd                	li	a5,-1
    80005bd0:	a805                	j	80005c00 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bd2:	fc442783          	lw	a5,-60(s0)
    80005bd6:	0007c863          	bltz	a5,80005be6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bda:	01a78513          	addi	a0,a5,26
    80005bde:	050e                	slli	a0,a0,0x3
    80005be0:	9526                	add	a0,a0,s1
    80005be2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005be6:	fd043503          	ld	a0,-48(s0)
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	9cc080e7          	jalr	-1588(ra) # 800045b6 <fileclose>
    fileclose(wf);
    80005bf2:	fc843503          	ld	a0,-56(s0)
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	9c0080e7          	jalr	-1600(ra) # 800045b6 <fileclose>
    return -1;
    80005bfe:	57fd                	li	a5,-1
}
    80005c00:	853e                	mv	a0,a5
    80005c02:	70e2                	ld	ra,56(sp)
    80005c04:	7442                	ld	s0,48(sp)
    80005c06:	74a2                	ld	s1,40(sp)
    80005c08:	6121                	addi	sp,sp,64
    80005c0a:	8082                	ret
    80005c0c:	0000                	unimp
	...

0000000080005c10 <kernelvec>:
    80005c10:	7111                	addi	sp,sp,-256
    80005c12:	e006                	sd	ra,0(sp)
    80005c14:	e40a                	sd	sp,8(sp)
    80005c16:	e80e                	sd	gp,16(sp)
    80005c18:	ec12                	sd	tp,24(sp)
    80005c1a:	f016                	sd	t0,32(sp)
    80005c1c:	f41a                	sd	t1,40(sp)
    80005c1e:	f81e                	sd	t2,48(sp)
    80005c20:	fc22                	sd	s0,56(sp)
    80005c22:	e0a6                	sd	s1,64(sp)
    80005c24:	e4aa                	sd	a0,72(sp)
    80005c26:	e8ae                	sd	a1,80(sp)
    80005c28:	ecb2                	sd	a2,88(sp)
    80005c2a:	f0b6                	sd	a3,96(sp)
    80005c2c:	f4ba                	sd	a4,104(sp)
    80005c2e:	f8be                	sd	a5,112(sp)
    80005c30:	fcc2                	sd	a6,120(sp)
    80005c32:	e146                	sd	a7,128(sp)
    80005c34:	e54a                	sd	s2,136(sp)
    80005c36:	e94e                	sd	s3,144(sp)
    80005c38:	ed52                	sd	s4,152(sp)
    80005c3a:	f156                	sd	s5,160(sp)
    80005c3c:	f55a                	sd	s6,168(sp)
    80005c3e:	f95e                	sd	s7,176(sp)
    80005c40:	fd62                	sd	s8,184(sp)
    80005c42:	e1e6                	sd	s9,192(sp)
    80005c44:	e5ea                	sd	s10,200(sp)
    80005c46:	e9ee                	sd	s11,208(sp)
    80005c48:	edf2                	sd	t3,216(sp)
    80005c4a:	f1f6                	sd	t4,224(sp)
    80005c4c:	f5fa                	sd	t5,232(sp)
    80005c4e:	f9fe                	sd	t6,240(sp)
    80005c50:	d35fc0ef          	jal	ra,80002984 <kerneltrap>
    80005c54:	6082                	ld	ra,0(sp)
    80005c56:	6122                	ld	sp,8(sp)
    80005c58:	61c2                	ld	gp,16(sp)
    80005c5a:	7282                	ld	t0,32(sp)
    80005c5c:	7322                	ld	t1,40(sp)
    80005c5e:	73c2                	ld	t2,48(sp)
    80005c60:	7462                	ld	s0,56(sp)
    80005c62:	6486                	ld	s1,64(sp)
    80005c64:	6526                	ld	a0,72(sp)
    80005c66:	65c6                	ld	a1,80(sp)
    80005c68:	6666                	ld	a2,88(sp)
    80005c6a:	7686                	ld	a3,96(sp)
    80005c6c:	7726                	ld	a4,104(sp)
    80005c6e:	77c6                	ld	a5,112(sp)
    80005c70:	7866                	ld	a6,120(sp)
    80005c72:	688a                	ld	a7,128(sp)
    80005c74:	692a                	ld	s2,136(sp)
    80005c76:	69ca                	ld	s3,144(sp)
    80005c78:	6a6a                	ld	s4,152(sp)
    80005c7a:	7a8a                	ld	s5,160(sp)
    80005c7c:	7b2a                	ld	s6,168(sp)
    80005c7e:	7bca                	ld	s7,176(sp)
    80005c80:	7c6a                	ld	s8,184(sp)
    80005c82:	6c8e                	ld	s9,192(sp)
    80005c84:	6d2e                	ld	s10,200(sp)
    80005c86:	6dce                	ld	s11,208(sp)
    80005c88:	6e6e                	ld	t3,216(sp)
    80005c8a:	7e8e                	ld	t4,224(sp)
    80005c8c:	7f2e                	ld	t5,232(sp)
    80005c8e:	7fce                	ld	t6,240(sp)
    80005c90:	6111                	addi	sp,sp,256
    80005c92:	10200073          	sret
    80005c96:	00000013          	nop
    80005c9a:	00000013          	nop
    80005c9e:	0001                	nop

0000000080005ca0 <timervec>:
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	e10c                	sd	a1,0(a0)
    80005ca6:	e510                	sd	a2,8(a0)
    80005ca8:	e914                	sd	a3,16(a0)
    80005caa:	710c                	ld	a1,32(a0)
    80005cac:	7510                	ld	a2,40(a0)
    80005cae:	6194                	ld	a3,0(a1)
    80005cb0:	96b2                	add	a3,a3,a2
    80005cb2:	e194                	sd	a3,0(a1)
    80005cb4:	4589                	li	a1,2
    80005cb6:	14459073          	csrw	sip,a1
    80005cba:	6914                	ld	a3,16(a0)
    80005cbc:	6510                	ld	a2,8(a0)
    80005cbe:	610c                	ld	a1,0(a0)
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	30200073          	mret
	...

0000000080005cca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cca:	1141                	addi	sp,sp,-16
    80005ccc:	e422                	sd	s0,8(sp)
    80005cce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cd0:	0c0007b7          	lui	a5,0xc000
    80005cd4:	4705                	li	a4,1
    80005cd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cd8:	c3d8                	sw	a4,4(a5)
}
    80005cda:	6422                	ld	s0,8(sp)
    80005cdc:	0141                	addi	sp,sp,16
    80005cde:	8082                	ret

0000000080005ce0 <plicinithart>:

void
plicinithart(void)
{
    80005ce0:	1141                	addi	sp,sp,-16
    80005ce2:	e406                	sd	ra,8(sp)
    80005ce4:	e022                	sd	s0,0(sp)
    80005ce6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	cf4080e7          	jalr	-780(ra) # 800019dc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cf0:	0085171b          	slliw	a4,a0,0x8
    80005cf4:	0c0027b7          	lui	a5,0xc002
    80005cf8:	97ba                	add	a5,a5,a4
    80005cfa:	40200713          	li	a4,1026
    80005cfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d02:	00d5151b          	slliw	a0,a0,0xd
    80005d06:	0c2017b7          	lui	a5,0xc201
    80005d0a:	953e                	add	a0,a0,a5
    80005d0c:	00052023          	sw	zero,0(a0)
}
    80005d10:	60a2                	ld	ra,8(sp)
    80005d12:	6402                	ld	s0,0(sp)
    80005d14:	0141                	addi	sp,sp,16
    80005d16:	8082                	ret

0000000080005d18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d18:	1141                	addi	sp,sp,-16
    80005d1a:	e406                	sd	ra,8(sp)
    80005d1c:	e022                	sd	s0,0(sp)
    80005d1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d20:	ffffc097          	auipc	ra,0xffffc
    80005d24:	cbc080e7          	jalr	-836(ra) # 800019dc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d28:	00d5179b          	slliw	a5,a0,0xd
    80005d2c:	0c201537          	lui	a0,0xc201
    80005d30:	953e                	add	a0,a0,a5
  return irq;
}
    80005d32:	4148                	lw	a0,4(a0)
    80005d34:	60a2                	ld	ra,8(sp)
    80005d36:	6402                	ld	s0,0(sp)
    80005d38:	0141                	addi	sp,sp,16
    80005d3a:	8082                	ret

0000000080005d3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d3c:	1101                	addi	sp,sp,-32
    80005d3e:	ec06                	sd	ra,24(sp)
    80005d40:	e822                	sd	s0,16(sp)
    80005d42:	e426                	sd	s1,8(sp)
    80005d44:	1000                	addi	s0,sp,32
    80005d46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c94080e7          	jalr	-876(ra) # 800019dc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d50:	00d5151b          	slliw	a0,a0,0xd
    80005d54:	0c2017b7          	lui	a5,0xc201
    80005d58:	97aa                	add	a5,a5,a0
    80005d5a:	c3c4                	sw	s1,4(a5)
}
    80005d5c:	60e2                	ld	ra,24(sp)
    80005d5e:	6442                	ld	s0,16(sp)
    80005d60:	64a2                	ld	s1,8(sp)
    80005d62:	6105                	addi	sp,sp,32
    80005d64:	8082                	ret

0000000080005d66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d66:	1141                	addi	sp,sp,-16
    80005d68:	e406                	sd	ra,8(sp)
    80005d6a:	e022                	sd	s0,0(sp)
    80005d6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d6e:	479d                	li	a5,7
    80005d70:	04a7cc63          	blt	a5,a0,80005dc8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d74:	0001d797          	auipc	a5,0x1d
    80005d78:	28c78793          	addi	a5,a5,652 # 80023000 <disk>
    80005d7c:	00a78733          	add	a4,a5,a0
    80005d80:	6789                	lui	a5,0x2
    80005d82:	97ba                	add	a5,a5,a4
    80005d84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d88:	eba1                	bnez	a5,80005dd8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d8a:	00451713          	slli	a4,a0,0x4
    80005d8e:	0001f797          	auipc	a5,0x1f
    80005d92:	2727b783          	ld	a5,626(a5) # 80025000 <disk+0x2000>
    80005d96:	97ba                	add	a5,a5,a4
    80005d98:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d9c:	0001d797          	auipc	a5,0x1d
    80005da0:	26478793          	addi	a5,a5,612 # 80023000 <disk>
    80005da4:	97aa                	add	a5,a5,a0
    80005da6:	6509                	lui	a0,0x2
    80005da8:	953e                	add	a0,a0,a5
    80005daa:	4785                	li	a5,1
    80005dac:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005db0:	0001f517          	auipc	a0,0x1f
    80005db4:	26850513          	addi	a0,a0,616 # 80025018 <disk+0x2018>
    80005db8:	ffffc097          	auipc	ra,0xffffc
    80005dbc:	5e4080e7          	jalr	1508(ra) # 8000239c <wakeup>
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005dc8:	00003517          	auipc	a0,0x3
    80005dcc:	94850513          	addi	a0,a0,-1720 # 80008710 <syscalls+0x330>
    80005dd0:	ffffa097          	auipc	ra,0xffffa
    80005dd4:	772080e7          	jalr	1906(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	95050513          	addi	a0,a0,-1712 # 80008728 <syscalls+0x348>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	762080e7          	jalr	1890(ra) # 80000542 <panic>

0000000080005de8 <virtio_disk_init>:
{
    80005de8:	1101                	addi	sp,sp,-32
    80005dea:	ec06                	sd	ra,24(sp)
    80005dec:	e822                	sd	s0,16(sp)
    80005dee:	e426                	sd	s1,8(sp)
    80005df0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005df2:	00003597          	auipc	a1,0x3
    80005df6:	94e58593          	addi	a1,a1,-1714 # 80008740 <syscalls+0x360>
    80005dfa:	0001f517          	auipc	a0,0x1f
    80005dfe:	2ae50513          	addi	a0,a0,686 # 800250a8 <disk+0x20a8>
    80005e02:	ffffb097          	auipc	ra,0xffffb
    80005e06:	d6c080e7          	jalr	-660(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e0a:	100017b7          	lui	a5,0x10001
    80005e0e:	4398                	lw	a4,0(a5)
    80005e10:	2701                	sext.w	a4,a4
    80005e12:	747277b7          	lui	a5,0x74727
    80005e16:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e1a:	0ef71163          	bne	a4,a5,80005efc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e1e:	100017b7          	lui	a5,0x10001
    80005e22:	43dc                	lw	a5,4(a5)
    80005e24:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e26:	4705                	li	a4,1
    80005e28:	0ce79a63          	bne	a5,a4,80005efc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e2c:	100017b7          	lui	a5,0x10001
    80005e30:	479c                	lw	a5,8(a5)
    80005e32:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e34:	4709                	li	a4,2
    80005e36:	0ce79363          	bne	a5,a4,80005efc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e3a:	100017b7          	lui	a5,0x10001
    80005e3e:	47d8                	lw	a4,12(a5)
    80005e40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e42:	554d47b7          	lui	a5,0x554d4
    80005e46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e4a:	0af71963          	bne	a4,a5,80005efc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	4705                	li	a4,1
    80005e54:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e56:	470d                	li	a4,3
    80005e58:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e5a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e5c:	c7ffe737          	lui	a4,0xc7ffe
    80005e60:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e64:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e66:	2701                	sext.w	a4,a4
    80005e68:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6a:	472d                	li	a4,11
    80005e6c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	473d                	li	a4,15
    80005e70:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e72:	6705                	lui	a4,0x1
    80005e74:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e76:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e7a:	5bdc                	lw	a5,52(a5)
    80005e7c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e7e:	c7d9                	beqz	a5,80005f0c <virtio_disk_init+0x124>
  if(max < NUM)
    80005e80:	471d                	li	a4,7
    80005e82:	08f77d63          	bgeu	a4,a5,80005f1c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e86:	100014b7          	lui	s1,0x10001
    80005e8a:	47a1                	li	a5,8
    80005e8c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e8e:	6609                	lui	a2,0x2
    80005e90:	4581                	li	a1,0
    80005e92:	0001d517          	auipc	a0,0x1d
    80005e96:	16e50513          	addi	a0,a0,366 # 80023000 <disk>
    80005e9a:	ffffb097          	auipc	ra,0xffffb
    80005e9e:	e60080e7          	jalr	-416(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ea2:	0001d717          	auipc	a4,0x1d
    80005ea6:	15e70713          	addi	a4,a4,350 # 80023000 <disk>
    80005eaa:	00c75793          	srli	a5,a4,0xc
    80005eae:	2781                	sext.w	a5,a5
    80005eb0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005eb2:	0001f797          	auipc	a5,0x1f
    80005eb6:	14e78793          	addi	a5,a5,334 # 80025000 <disk+0x2000>
    80005eba:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005ebc:	0001d717          	auipc	a4,0x1d
    80005ec0:	1c470713          	addi	a4,a4,452 # 80023080 <disk+0x80>
    80005ec4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ec6:	0001e717          	auipc	a4,0x1e
    80005eca:	13a70713          	addi	a4,a4,314 # 80024000 <disk+0x1000>
    80005ece:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ed0:	4705                	li	a4,1
    80005ed2:	00e78c23          	sb	a4,24(a5)
    80005ed6:	00e78ca3          	sb	a4,25(a5)
    80005eda:	00e78d23          	sb	a4,26(a5)
    80005ede:	00e78da3          	sb	a4,27(a5)
    80005ee2:	00e78e23          	sb	a4,28(a5)
    80005ee6:	00e78ea3          	sb	a4,29(a5)
    80005eea:	00e78f23          	sb	a4,30(a5)
    80005eee:	00e78fa3          	sb	a4,31(a5)
}
    80005ef2:	60e2                	ld	ra,24(sp)
    80005ef4:	6442                	ld	s0,16(sp)
    80005ef6:	64a2                	ld	s1,8(sp)
    80005ef8:	6105                	addi	sp,sp,32
    80005efa:	8082                	ret
    panic("could not find virtio disk");
    80005efc:	00003517          	auipc	a0,0x3
    80005f00:	85450513          	addi	a0,a0,-1964 # 80008750 <syscalls+0x370>
    80005f04:	ffffa097          	auipc	ra,0xffffa
    80005f08:	63e080e7          	jalr	1598(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005f0c:	00003517          	auipc	a0,0x3
    80005f10:	86450513          	addi	a0,a0,-1948 # 80008770 <syscalls+0x390>
    80005f14:	ffffa097          	auipc	ra,0xffffa
    80005f18:	62e080e7          	jalr	1582(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005f1c:	00003517          	auipc	a0,0x3
    80005f20:	87450513          	addi	a0,a0,-1932 # 80008790 <syscalls+0x3b0>
    80005f24:	ffffa097          	auipc	ra,0xffffa
    80005f28:	61e080e7          	jalr	1566(ra) # 80000542 <panic>

0000000080005f2c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f2c:	7175                	addi	sp,sp,-144
    80005f2e:	e506                	sd	ra,136(sp)
    80005f30:	e122                	sd	s0,128(sp)
    80005f32:	fca6                	sd	s1,120(sp)
    80005f34:	f8ca                	sd	s2,112(sp)
    80005f36:	f4ce                	sd	s3,104(sp)
    80005f38:	f0d2                	sd	s4,96(sp)
    80005f3a:	ecd6                	sd	s5,88(sp)
    80005f3c:	e8da                	sd	s6,80(sp)
    80005f3e:	e4de                	sd	s7,72(sp)
    80005f40:	e0e2                	sd	s8,64(sp)
    80005f42:	fc66                	sd	s9,56(sp)
    80005f44:	f86a                	sd	s10,48(sp)
    80005f46:	f46e                	sd	s11,40(sp)
    80005f48:	0900                	addi	s0,sp,144
    80005f4a:	8aaa                	mv	s5,a0
    80005f4c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f4e:	00c52c83          	lw	s9,12(a0)
    80005f52:	001c9c9b          	slliw	s9,s9,0x1
    80005f56:	1c82                	slli	s9,s9,0x20
    80005f58:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f5c:	0001f517          	auipc	a0,0x1f
    80005f60:	14c50513          	addi	a0,a0,332 # 800250a8 <disk+0x20a8>
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	c9a080e7          	jalr	-870(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    80005f6c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f6e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f70:	0001dc17          	auipc	s8,0x1d
    80005f74:	090c0c13          	addi	s8,s8,144 # 80023000 <disk>
    80005f78:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f7a:	4b0d                	li	s6,3
    80005f7c:	a0ad                	j	80005fe6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f7e:	00fc0733          	add	a4,s8,a5
    80005f82:	975e                	add	a4,a4,s7
    80005f84:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f88:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f8a:	0207c563          	bltz	a5,80005fb4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f8e:	2905                	addiw	s2,s2,1
    80005f90:	0611                	addi	a2,a2,4
    80005f92:	19690d63          	beq	s2,s6,8000612c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f96:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f98:	0001f717          	auipc	a4,0x1f
    80005f9c:	08070713          	addi	a4,a4,128 # 80025018 <disk+0x2018>
    80005fa0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005fa2:	00074683          	lbu	a3,0(a4)
    80005fa6:	fee1                	bnez	a3,80005f7e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fa8:	2785                	addiw	a5,a5,1
    80005faa:	0705                	addi	a4,a4,1
    80005fac:	fe979be3          	bne	a5,s1,80005fa2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fb0:	57fd                	li	a5,-1
    80005fb2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fb4:	01205d63          	blez	s2,80005fce <virtio_disk_rw+0xa2>
    80005fb8:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fba:	000a2503          	lw	a0,0(s4)
    80005fbe:	00000097          	auipc	ra,0x0
    80005fc2:	da8080e7          	jalr	-600(ra) # 80005d66 <free_desc>
      for(int j = 0; j < i; j++)
    80005fc6:	2d85                	addiw	s11,s11,1
    80005fc8:	0a11                	addi	s4,s4,4
    80005fca:	ffb918e3          	bne	s2,s11,80005fba <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fce:	0001f597          	auipc	a1,0x1f
    80005fd2:	0da58593          	addi	a1,a1,218 # 800250a8 <disk+0x20a8>
    80005fd6:	0001f517          	auipc	a0,0x1f
    80005fda:	04250513          	addi	a0,a0,66 # 80025018 <disk+0x2018>
    80005fde:	ffffc097          	auipc	ra,0xffffc
    80005fe2:	23e080e7          	jalr	574(ra) # 8000221c <sleep>
  for(int i = 0; i < 3; i++){
    80005fe6:	f8040a13          	addi	s4,s0,-128
{
    80005fea:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fec:	894e                	mv	s2,s3
    80005fee:	b765                	j	80005f96 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005ff0:	0001f717          	auipc	a4,0x1f
    80005ff4:	01073703          	ld	a4,16(a4) # 80025000 <disk+0x2000>
    80005ff8:	973e                	add	a4,a4,a5
    80005ffa:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005ffe:	0001d517          	auipc	a0,0x1d
    80006002:	00250513          	addi	a0,a0,2 # 80023000 <disk>
    80006006:	0001f717          	auipc	a4,0x1f
    8000600a:	ffa70713          	addi	a4,a4,-6 # 80025000 <disk+0x2000>
    8000600e:	6314                	ld	a3,0(a4)
    80006010:	96be                	add	a3,a3,a5
    80006012:	00c6d603          	lhu	a2,12(a3)
    80006016:	00166613          	ori	a2,a2,1
    8000601a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000601e:	f8842683          	lw	a3,-120(s0)
    80006022:	6310                	ld	a2,0(a4)
    80006024:	97b2                	add	a5,a5,a2
    80006026:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000602a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000602e:	0612                	slli	a2,a2,0x4
    80006030:	962a                	add	a2,a2,a0
    80006032:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006036:	00469793          	slli	a5,a3,0x4
    8000603a:	630c                	ld	a1,0(a4)
    8000603c:	95be                	add	a1,a1,a5
    8000603e:	6689                	lui	a3,0x2
    80006040:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006044:	96ca                	add	a3,a3,s2
    80006046:	96aa                	add	a3,a3,a0
    80006048:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000604a:	6314                	ld	a3,0(a4)
    8000604c:	96be                	add	a3,a3,a5
    8000604e:	4585                	li	a1,1
    80006050:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006052:	6314                	ld	a3,0(a4)
    80006054:	96be                	add	a3,a3,a5
    80006056:	4509                	li	a0,2
    80006058:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000605c:	6314                	ld	a3,0(a4)
    8000605e:	97b6                	add	a5,a5,a3
    80006060:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006064:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006068:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000606c:	6714                	ld	a3,8(a4)
    8000606e:	0026d783          	lhu	a5,2(a3)
    80006072:	8b9d                	andi	a5,a5,7
    80006074:	0789                	addi	a5,a5,2
    80006076:	0786                	slli	a5,a5,0x1
    80006078:	97b6                	add	a5,a5,a3
    8000607a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000607e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006082:	6718                	ld	a4,8(a4)
    80006084:	00275783          	lhu	a5,2(a4)
    80006088:	2785                	addiw	a5,a5,1
    8000608a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000608e:	100017b7          	lui	a5,0x10001
    80006092:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006096:	004aa783          	lw	a5,4(s5)
    8000609a:	02b79163          	bne	a5,a1,800060bc <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000609e:	0001f917          	auipc	s2,0x1f
    800060a2:	00a90913          	addi	s2,s2,10 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800060a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060a8:	85ca                	mv	a1,s2
    800060aa:	8556                	mv	a0,s5
    800060ac:	ffffc097          	auipc	ra,0xffffc
    800060b0:	170080e7          	jalr	368(ra) # 8000221c <sleep>
  while(b->disk == 1) {
    800060b4:	004aa783          	lw	a5,4(s5)
    800060b8:	fe9788e3          	beq	a5,s1,800060a8 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060bc:	f8042483          	lw	s1,-128(s0)
    800060c0:	20048793          	addi	a5,s1,512
    800060c4:	00479713          	slli	a4,a5,0x4
    800060c8:	0001d797          	auipc	a5,0x1d
    800060cc:	f3878793          	addi	a5,a5,-200 # 80023000 <disk>
    800060d0:	97ba                	add	a5,a5,a4
    800060d2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060d6:	0001f917          	auipc	s2,0x1f
    800060da:	f2a90913          	addi	s2,s2,-214 # 80025000 <disk+0x2000>
    800060de:	a019                	j	800060e4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    800060e0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800060e4:	8526                	mv	a0,s1
    800060e6:	00000097          	auipc	ra,0x0
    800060ea:	c80080e7          	jalr	-896(ra) # 80005d66 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060ee:	0492                	slli	s1,s1,0x4
    800060f0:	00093783          	ld	a5,0(s2)
    800060f4:	94be                	add	s1,s1,a5
    800060f6:	00c4d783          	lhu	a5,12(s1)
    800060fa:	8b85                	andi	a5,a5,1
    800060fc:	f3f5                	bnez	a5,800060e0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060fe:	0001f517          	auipc	a0,0x1f
    80006102:	faa50513          	addi	a0,a0,-86 # 800250a8 <disk+0x20a8>
    80006106:	ffffb097          	auipc	ra,0xffffb
    8000610a:	bac080e7          	jalr	-1108(ra) # 80000cb2 <release>
}
    8000610e:	60aa                	ld	ra,136(sp)
    80006110:	640a                	ld	s0,128(sp)
    80006112:	74e6                	ld	s1,120(sp)
    80006114:	7946                	ld	s2,112(sp)
    80006116:	79a6                	ld	s3,104(sp)
    80006118:	7a06                	ld	s4,96(sp)
    8000611a:	6ae6                	ld	s5,88(sp)
    8000611c:	6b46                	ld	s6,80(sp)
    8000611e:	6ba6                	ld	s7,72(sp)
    80006120:	6c06                	ld	s8,64(sp)
    80006122:	7ce2                	ld	s9,56(sp)
    80006124:	7d42                	ld	s10,48(sp)
    80006126:	7da2                	ld	s11,40(sp)
    80006128:	6149                	addi	sp,sp,144
    8000612a:	8082                	ret
  if(write)
    8000612c:	01a037b3          	snez	a5,s10
    80006130:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006134:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006138:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000613c:	f8042483          	lw	s1,-128(s0)
    80006140:	00449913          	slli	s2,s1,0x4
    80006144:	0001f997          	auipc	s3,0x1f
    80006148:	ebc98993          	addi	s3,s3,-324 # 80025000 <disk+0x2000>
    8000614c:	0009ba03          	ld	s4,0(s3)
    80006150:	9a4a                	add	s4,s4,s2
    80006152:	f7040513          	addi	a0,s0,-144
    80006156:	ffffb097          	auipc	ra,0xffffb
    8000615a:	f32080e7          	jalr	-206(ra) # 80001088 <kvmpa>
    8000615e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006162:	0009b783          	ld	a5,0(s3)
    80006166:	97ca                	add	a5,a5,s2
    80006168:	4741                	li	a4,16
    8000616a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000616c:	0009b783          	ld	a5,0(s3)
    80006170:	97ca                	add	a5,a5,s2
    80006172:	4705                	li	a4,1
    80006174:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006178:	f8442783          	lw	a5,-124(s0)
    8000617c:	0009b703          	ld	a4,0(s3)
    80006180:	974a                	add	a4,a4,s2
    80006182:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006186:	0792                	slli	a5,a5,0x4
    80006188:	0009b703          	ld	a4,0(s3)
    8000618c:	973e                	add	a4,a4,a5
    8000618e:	058a8693          	addi	a3,s5,88
    80006192:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006194:	0009b703          	ld	a4,0(s3)
    80006198:	973e                	add	a4,a4,a5
    8000619a:	40000693          	li	a3,1024
    8000619e:	c714                	sw	a3,8(a4)
  if(write)
    800061a0:	e40d18e3          	bnez	s10,80005ff0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061a4:	0001f717          	auipc	a4,0x1f
    800061a8:	e5c73703          	ld	a4,-420(a4) # 80025000 <disk+0x2000>
    800061ac:	973e                	add	a4,a4,a5
    800061ae:	4689                	li	a3,2
    800061b0:	00d71623          	sh	a3,12(a4)
    800061b4:	b5a9                	j	80005ffe <virtio_disk_rw+0xd2>

00000000800061b6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061b6:	1101                	addi	sp,sp,-32
    800061b8:	ec06                	sd	ra,24(sp)
    800061ba:	e822                	sd	s0,16(sp)
    800061bc:	e426                	sd	s1,8(sp)
    800061be:	e04a                	sd	s2,0(sp)
    800061c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061c2:	0001f517          	auipc	a0,0x1f
    800061c6:	ee650513          	addi	a0,a0,-282 # 800250a8 <disk+0x20a8>
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	a34080e7          	jalr	-1484(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061d2:	0001f717          	auipc	a4,0x1f
    800061d6:	e2e70713          	addi	a4,a4,-466 # 80025000 <disk+0x2000>
    800061da:	02075783          	lhu	a5,32(a4)
    800061de:	6b18                	ld	a4,16(a4)
    800061e0:	00275683          	lhu	a3,2(a4)
    800061e4:	8ebd                	xor	a3,a3,a5
    800061e6:	8a9d                	andi	a3,a3,7
    800061e8:	cab9                	beqz	a3,8000623e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800061ea:	0001d917          	auipc	s2,0x1d
    800061ee:	e1690913          	addi	s2,s2,-490 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061f2:	0001f497          	auipc	s1,0x1f
    800061f6:	e0e48493          	addi	s1,s1,-498 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800061fa:	078e                	slli	a5,a5,0x3
    800061fc:	97ba                	add	a5,a5,a4
    800061fe:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006200:	20078713          	addi	a4,a5,512
    80006204:	0712                	slli	a4,a4,0x4
    80006206:	974a                	add	a4,a4,s2
    80006208:	03074703          	lbu	a4,48(a4)
    8000620c:	ef21                	bnez	a4,80006264 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000620e:	20078793          	addi	a5,a5,512
    80006212:	0792                	slli	a5,a5,0x4
    80006214:	97ca                	add	a5,a5,s2
    80006216:	7798                	ld	a4,40(a5)
    80006218:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000621c:	7788                	ld	a0,40(a5)
    8000621e:	ffffc097          	auipc	ra,0xffffc
    80006222:	17e080e7          	jalr	382(ra) # 8000239c <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006226:	0204d783          	lhu	a5,32(s1)
    8000622a:	2785                	addiw	a5,a5,1
    8000622c:	8b9d                	andi	a5,a5,7
    8000622e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006232:	6898                	ld	a4,16(s1)
    80006234:	00275683          	lhu	a3,2(a4)
    80006238:	8a9d                	andi	a3,a3,7
    8000623a:	fcf690e3          	bne	a3,a5,800061fa <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000623e:	10001737          	lui	a4,0x10001
    80006242:	533c                	lw	a5,96(a4)
    80006244:	8b8d                	andi	a5,a5,3
    80006246:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006248:	0001f517          	auipc	a0,0x1f
    8000624c:	e6050513          	addi	a0,a0,-416 # 800250a8 <disk+0x20a8>
    80006250:	ffffb097          	auipc	ra,0xffffb
    80006254:	a62080e7          	jalr	-1438(ra) # 80000cb2 <release>
}
    80006258:	60e2                	ld	ra,24(sp)
    8000625a:	6442                	ld	s0,16(sp)
    8000625c:	64a2                	ld	s1,8(sp)
    8000625e:	6902                	ld	s2,0(sp)
    80006260:	6105                	addi	sp,sp,32
    80006262:	8082                	ret
      panic("virtio_disk_intr status");
    80006264:	00002517          	auipc	a0,0x2
    80006268:	54c50513          	addi	a0,a0,1356 # 800087b0 <syscalls+0x3d0>
    8000626c:	ffffa097          	auipc	ra,0xffffa
    80006270:	2d6080e7          	jalr	726(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
