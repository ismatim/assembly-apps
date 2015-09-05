
        .text
        .globl  main


#### Programa principal 

main: 
        subu    $sp,$sp,24      # stack de 24 bytes
                                # CAMBIO: siempre hay que asegurar que el stack
                                # esté alineado a 8 bytes.
	sw	$fp,20($sp)	            # CAMBIO: siempre se guarda el "frame pointer"
	sw	$gp,16($sp)             # CAMBIO: siempre se guarda el "global pointer"
                                # CAMBIO: 8 bytes se reservan para dos variables
                                # de tipo entero.
                                # CAMBIO: siempre queda un gap de 8 bytes, que
                                # aún no sabemos para qué sirven :-)
	move	$fp,$sp             # CAMBIO: el "frame pointer" se hace apuntar
                                # al mismo lugar que el "stack pointer".
                                # CAMBIO: no se protege $ra si no se va a modificar.

        lw      $t1,12($fp)     # CAMBIO: inicializamos la variable en donde
        move    $t1,$zero       # se acumula el resultado. Ojo, esa variable
        sw      $t1,12($fp)     # está en memoria, y asumimos "no optimización",
                                # por lo que no podemos usar registros.

while:  la      $a0, pnum       # el reg a0 es el parametro para al hacer syscall
        li      $v0, 4          # Llamada al sistema 4 -> imprimir string
        syscall

        li      $v0,5           # llamada al sistema 5 -> leer un integer
        syscall

        sw      $v0,8($fp)      # CAMBIO: estamos usando una variable local
                                # en la posición 8($fp)
        lw      $t0,8($fp)      # v0->t0 asi puedo trabajar tranquilo con t0
        lw      $t1,12($fp)     # CAMBIO: en otra variable local tenemos la
                                # acumulación.
        addu    $t1,$t1,$t0     # t1 = t1+t0
        sw      $t1,12($fp)     # CAMBIO: volvemos a llevar el dato a la
                                # variable local.
        lw      $t0,8($fp)      # CAMBIO: se vuelve a traer el dato. Pensar que
        bnez    $t0,while       # estamos en una arquitectura LOAD/STORE y
                                # asumimos que esto lo generó un compilador
                                # sin optimización.

        #### Como t0=0 debo imprimir el resultado ####
        li      $v0,4           # codigo del sistema 4: indica que se imprime un string
        la      $a0,msge        # pasaje de argumentos, $a0 tiene la direccion de msge
        syscall
        
        li      $v0,1           # llamada al sistema para que imprima el valor integer
        lw      $a0,12($fp)     # CAMBIO: volvemos a traer el dato desde memoria.
        syscall

        #### Libero la memoria pedida ####
	move	$sp,$fp		# destruccion del stack frame
	lw	$fp,20($sp)     # CAMBIO: el "global pointer" no se restaura.
	addu	$sp,$sp,24
	j	$ra

        .rdata                  # CAMBIO: rdata es "read-only data"

pnum:   .asciiz "Ingrese un entero (0 termina): \n"
msge:   .asciiz "Resultado acumulado: "
