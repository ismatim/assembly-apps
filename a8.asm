#
#
# 20060501 - Bug fix: save/restore en stack frame de get_digit.
#          - Simplificacion: acceso a la tabla digit.
# 20060428 - Version inicial.
#
	.text
	.globl main

main:
	subu	$sp, $sp, 32	# push stack frame
	sw	$ra, 20($sp)	# save return address
	sw	$fp, 16($sp)	# save frame pointer
	addiu	$fp, $sp, 28	# set frame pointer

	la	$a0, str1	# printf("Ingrese entero positivo: ");
	li	$v0, 4
	syscall

	li	$v0, 5		# scanf("%d", &a);
	syscall

	bgez	$v0, ok		# if (a >= 0) goto ok

	la	$a0, str2	# printf("Error: el entero es negativo\n");
	li	$v0, 4
	syscall

	j	end
ok:
	move	$a0, $v0	# ($a0 = a)
	jal	get_digit	# get_digit(a);

	la	$a0, nl		# printf("\n");
	li	$v0, 4
	syscall
end:
	lw	$ra, 20($sp)	# restore return address
	lw	$fp, 16($sp)	# restore frame pointer
	addiu	$sp, $sp, 32	# pop stack frame
	jr	$ra		# return
	
get_digit:
	subu	$sp, $sp, 32	# push stack frame
	sw	$ra, 20($sp)	# save return address
	sw	$fp, 16($sp)	# save frame pointer
	addiu	$fp, $sp, 28	# set frame pointer
	sw	$s0, 0($fp) 	# save $s0 (callee saved register to be used)

	rem	$s0, $a0, 10	# r = a % 10; (digito)
	divu	$a0, $a0, 10	# a /= 10;

	beqz	$a0, end_gd	# if (a == 0) goto end_gd

	jal	get_digit	# get_digit(a)

end_gd:
	mul	$a0, $s0, 4	# escalo el digito para que me de el indice en
				# digit (vector de words, es decir 4 bytes/elem).
	lw	$a0, digit($a0)	# printf("%s", digit[r]); (ver nota 1)
	li	$v0, 4
	syscall

	la	$a0, sp		# printf(" ");
	li	$v0, 4
	syscall

	lw 	$s0, 0($fp)	# restore $s0
	lw	$ra, 20($sp)	# restore return address
	lw	$fp, 16($sp)	# restore frame pointer
	addiu	$sp, $sp, 32	# pop stack frame
	jr	$ra		# return
	
	.data
	
str1:	.asciiz	"Ingrese entero positivo: "
str2:	.asciiz "Error: el entero es negativo\n"
sp:	.asciiz " "
nl:	.asciiz	"\n"

D0:	.asciiz	"cero"
D1:	.asciiz	"uno"
D2:	.asciiz	"dos"
D3:	.asciiz	"tres"
D4:	.asciiz	"cuatro"
D5:	.asciiz	"cinco"
D6:	.asciiz "seis"
D7:	.asciiz "siete"
D8:	.asciiz "ocho"
D9:	.asciiz	"nueve"

digit:	.word	D0,D1,D2,D3,D4,D5,D6,D7,D8,D9

# Notas:
# (1): cargo $a0 con el elemento con indice $s0 de digit, que es la
# direccion de la cadena del numero correspondiente al digito extraido con la
# instruccion "rem". Uso esa direccion como el argumento para print_string.
