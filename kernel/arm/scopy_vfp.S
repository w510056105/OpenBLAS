/***************************************************************************
Copyright (c) 2013, The OpenBLAS Project
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in
the documentation and/or other materials provided with the
distribution.
3. Neither the name of the OpenBLAS project nor the names of
its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE OPENBLAS PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*****************************************************************************/

/**************************************************************************************
* 2013/11/07 Saar
* 	 BLASTEST 		: OK
* 	 CTEST			: OK
* 	 TEST			: OK
*
**************************************************************************************/

#define ASSEMBLER
#include "common.h"

#define STACKSIZE 256

#define	N	r0
#define	X	r1
#define	INC_X	r2
#define	OLD_Y	r3


/******************************************************
* [fp, #-128] - [fp, #-64] is reserved
* for store and restore of floating point
* registers
*******************************************************/

#define OLD_INC_Y	[fp, #4 ]

#define I	r5
#define Y	r6
#define INC_Y	r7

#define X_PRE	256

/**************************************************************************************
* Macro definitions
**************************************************************************************/

.macro COPY_F8

	pld	[ X, #X_PRE  ]
	vldmia.f32	X!, { s0 - s3 }
	vldmia.f32	X!, { s4 - s7 }
	vstmia.f32	Y!, { s0 - s3 }
	vstmia.f32	Y!, { s4 - s7 }

.endm

.macro COPY_F1

	vldmia.f32	X!, { s0 }
	vstmia.f32	Y!, { s0 }

.endm


/*************************************************************************************************************************/

.macro COPY_S4

	nop
	vldmia.f32	X, { s0 }
	vstmia.f32	Y, { s0 }
	add	X, X, INC_X
	add	Y, Y, INC_Y

	vldmia.f32	X, { s1 }
	vstmia.f32	Y, { s1 }
	add	X, X, INC_X
	add	Y, Y, INC_Y

	vldmia.f32	X, { s0 }
	vstmia.f32	Y, { s0 }
	add	X, X, INC_X
	add	Y, Y, INC_Y

	vldmia.f32	X, { s1 }
	vstmia.f32	Y, { s1 }
	add	X, X, INC_X
	add	Y, Y, INC_Y

.endm


.macro COPY_S1

	vldmia.f32	X, { s0 }
	vstmia.f32	Y, { s0 }
	add	X, X, INC_X
	add	Y, Y, INC_Y

.endm



/**************************************************************************************
* End of macro definitions
**************************************************************************************/

	PROLOGUE

	.align 5

	push	{r4 - r9, fp}
	add	fp, sp, #24
	sub	sp, sp, #STACKSIZE				// reserve stack

	sub	r4, fp, #128
	vstm	r4, { s8 - s15} 				// store floating point registers

	mov	Y, OLD_Y
	ldr	INC_Y, OLD_INC_Y

	cmp	N, #0
	ble	scopy_kernel_L999

	cmp	INC_X, #0
	beq	scopy_kernel_L999

	cmp	INC_Y, #0
	beq	scopy_kernel_L999

	cmp	INC_X, #1
	bne	scopy_kernel_S_BEGIN

	cmp	INC_Y, #1
	bne	scopy_kernel_S_BEGIN

scopy_kernel_F_BEGIN:

	asrs	I, N, #3					// I = N / 8
	ble	scopy_kernel_F1

scopy_kernel_F8:

	COPY_F8

	subs	I, I, #1
	bne	scopy_kernel_F8

scopy_kernel_F1:

	ands	I, N, #7
	ble	scopy_kernel_L999

scopy_kernel_F10:

	COPY_F1

	subs    I, I, #1
        bne     scopy_kernel_F10

	b	scopy_kernel_L999

scopy_kernel_S_BEGIN:

	lsl	INC_X, INC_X, #2				// INC_X * SIZE
	lsl	INC_Y, INC_Y, #2				// INC_Y * SIZE

	asrs	I, N, #2					// I = N / 4
	ble	scopy_kernel_S1

scopy_kernel_S4:

	COPY_S4

	subs	I, I, #1
	bne	scopy_kernel_S4

scopy_kernel_S1:

	ands	I, N, #3
	ble	scopy_kernel_L999

scopy_kernel_S10:

	COPY_S1

	subs    I, I, #1
        bne     scopy_kernel_S10






scopy_kernel_L999:

	sub	r3, fp, #128
	vldm	r3, { s8 - s15}					// restore floating point registers

	mov	r0, #0						// set return value
	sub	sp, fp, #24
	pop	{r4 - r9, fp}
	bx	lr

	EPILOGUE

