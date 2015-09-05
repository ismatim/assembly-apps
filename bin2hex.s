#include <mips/regdef.h>
#include <sys/syscall.h>


  .data
Arg_Long:
  .asciiz "-l"

  ##############################################
  # Main : Stack Frame 
  ##############################################
  # 52 -> Tope
  # 48 -> ra pointer
  # 44 -> fp pointer
  # 40 -> gp pointer
  # 32 -> palabra leida
  # 28 -> s2 ( iterador de caracteres procesados por renglon)
  # 24 -> s1
  # 20 -> s0
  # 16 -> longitud de lineas a imprimir
  # 12 -> registro a3
  # 08 -> registro a2
  # 04 -> registro a1
  # 00 -> registro a0
  ##############################################
#define STACK_MAIN_SIZE 52
#define RA_MAIN_POS (STACK_MAIN_SIZE - 4)
#define FP_MAIN_POS (RA_MAIN_POS - 4)
#define GP_MAIN_POS (FP_MAIN_POS -4)

  .text
  .align  2
  .globl main
  .ent  main
main:
  .frame $fp, STACK_MAIN_SIZE, ra
  .set  noreorder
  .cpload t9
  .set  reorder
  subu  sp, sp, STACK_MAIN_SIZE
  .cprestore GP_MAIN_POS
  
  sw  ra, RA_MAIN_POS(sp)
  sw  $fp, FP_MAIN_POS(sp)
  sw  gp, GP_MAIN_POS(sp)
  move  $fp, sp
  sw s0, 20(sp)
  sw s1, 24(sp)
  sw s3, 28(sp)
  sw a0,  STACK_MAIN_SIZE(sp)
  sw a1,  (STACK_MAIN_SIZE + 4)(sp)
  sw a2,  (STACK_MAIN_SIZE + 8)(sp)
  sw a3,  (STACK_MAIN_SIZE + 12)(sp)
  
  # en caso de que exista el argumento -l, lo proceso
  li v0, 16 # cantidad por defoult de valores hexa por linea
  li t0, 1 # valor de a0 cuando no hay argumentos
  beq a0, t0, store_arguments
  jal processCmdLine
  beqz v0, return # si la cantidad de caracteres a imprimir es cero
                    # es porque el usuario introdujo mal la linea 
                    # de comandos, entonces el programa finaliza
  
store_arguments:
  # guardo la longtud de las lineas a imprimir en 16(sp)
  sw v0, 16(sp) 
  move s2, v0 # s2 sera el iterador de la valores a imprimir por
              # linea
               
  #******************************************************
Primary_loop:
  #******************************************************
  # Decremento el iterador de impresion de caracteres
  
  
  # Intentamos leer un byte de informacion de stdin, usando
  # el stack del proceso como lugar de almacenamiento.  
  # syscall: "read" ret: "ssize_t" args: "int" "void *" "size_t"
  
  li  v0, SYS_read # llamada al sistema para leer caracteres
  li  a0, 0        # a0: file descriptor number.
  la  a1, 32(sp)   # a1: data pointer.
  li  a2, 1        # a2: available space.
  syscall

  
  # Verificamos el retorno de la llamada a SYS_read: si termino
  # bien, continuamos. De lo contrario, retornamos al sistema.
  #
  # Primero, inspeccionamos el valor del registro a3: debe ser
  # cero cuando no han ocurrido errores, y distinto de cero en
  # los demas casos.
  #
  bne a3, zero, read_error

  # En este punto, sabemos que $a3 es nulo: necesitamos revisar
  # el valor de retorno de SYS_read, i.e. cantidad de bytes que
  # se acaban de leer. Si la cantidad es exactamente 1, quiere
  # decir que tenemos leido un caracter en memoria; si es nula,
  # quiere decir que el stream ha llegado al final. Si ocurren
  # otros valores, los tratamos como error.
  #
  beq v0, zero, eof
  li  t0, 1
  bne v0, t0, read_error

  # Procesamos el caracter leido :
  # nibbleSplit toma un caracter de un byte, colocado en a0 
  # y retorna su valor numerico binario, 
  # donde coloca a su nible menos significativo en v0 y a su 
  # nible mas significativo en v1. Luego hexNum2Char toma
  # cada nible ( digito en hexa ), y lo convierte a su 
  # reprecentacion en ascii

  lbu a0, 32(sp)
  jal nibbleSplit
  move a0, v0
  jal hexNum2Char
  move s1, v0
  # ahora v0 contiene el valor de retorno de hexNum2Char
  move a0, v1
  jal hexNum2Char
  move s0, v0
  move v0, zero
  
 
  # syscall: "write" ret: "ssize_t" args: "int" "const void *" "size_t" 
  li  v0, SYS_write # llamada a systema de para escritura de caracteres.
  li  a0, 1         # a0: file descriptor number.
  la  a1, 32(sp)    # a1: input data pointer.
  sw  s1, 32(sp)
  li  a2, 1         # a2: output byte size.
  syscall
  # Revisamos el retorno de SYS_write: si $a3 es no-nulo, quiere
  # decir que ha ocurrido un error. En caso contrario, imitamos
  # lo hecho en SYS_read, revisando el valor de la cantidad de
  # informacion que ha sido enviada.
  #
  bne a3, zero, write_error
  li  t0, 1
  bne v0, t0, write_error  

  # sigo el mismo procedimiento para el envio del siguiente byte
  li  v0, SYS_write # llamada a systema de para escritura de caracteres.
  li  a0, 1         # a0: file descriptor number.
  la  a1, 32(sp)    # a1: input data pointer.
  sw  s0, 32(sp)
  li  a2, 1         # a2: output byte size.
  syscall
  bne a3, zero, write_error
  li  t0, 1
  bne v0, t0, write_error  
  
  # Evaluo si debo colocar un fin de linea en el archivo de salida
  subu s2, s2, 1 # decremento el contador
  bgtu s2, 1, Primary_loop # por el hecho de que el decremento se hace
                           # en la parte inferior del ciclo. se cuenta hasta
                           # 1
  lw s2, 16(sp)
  # coloco el fin de linea imprimir en el lugar correspondiente
  li t0, '\n'
  li  v0, SYS_write # llamada a systema de para escritura de caracteres.
  li  a0, 1         # a0: file descriptor number.
  la  a1, 32(sp)    # a1: input data pointer.
  sw  t0, 32(sp)
  li  a2, 1         # a2: output byte size.
  syscall
  bne a3, zero, write_error
  li  t0, 1
  bne v0, t0, write_error   
  # Volvemos a iterar, intentando leer otro caracter de entrada.
  
  b Primary_loop

write_error:
read_error:
  li  v0, SYS_exit
  li  a0, 1
  syscall


eof:
  # fuerzo a que el programa finalice con un fin de linea
  # coloco el fin de linea imprimir en el lugar correspondiente
  lbu t0, 16(sp)
  beq s2, t0, return # si el ultimo caracter fue un fin de linea
                     # no vuelvo a imprimir
  li t0, '\n'
  li  v0, SYS_write # llamada a systema de para escritura de caracteres.
  li  a0, 1         # a0: file descriptor number.
  la  a1, 32(sp)    # a1: input data pointer.
  sw  t0, 32(sp)
  li  a2, 1         # a2: output byte size.
  syscall
  bne a3, zero, write_error
  li  t0, 1
  bne v0, t0, write_error     # Finalmente, volvemos al sistema operativo devolviendo un
  # codigo de retorno nulo.
  #
return:
  # Volvemos al sistema operativo, devolviendo un c�digo 
  # de retorno nulo.
  
  lw a0, STACK_MAIN_SIZE(sp)
  lw a1, (STACK_MAIN_SIZE + 4)(sp)
  lw a2, (STACK_MAIN_SIZE + 8)(sp)
  lw a3, (STACK_MAIN_SIZE + 12)(sp)
  lw s0, 20(sp)
  lw s1, 24(sp)
  move  v0, zero
  lw  ra, RA_MAIN_POS(sp)
  lw  $fp, FP_MAIN_POS(sp)
  lw  gp, GP_MAIN_POS(sp)
  addu  sp, sp, STACK_MAIN_SIZE
  j ra
  .end  main


  #*****************************************************
  #                     processCmdLine
  # precesa la opcio de loongitud de salida de la linea 
  # de comando
  # Agumento : 
  #           a0 y a1, tal cual los recibe el main
  # Retorno : 
  #           v0 : valor binario de linea de comandos
  #                con la cantidad de caracteres a imprimir
  #                por linea
  #*****************************************************
#define STACK_CMD_LINE_SIZE 32
#define RA_CMD_LINE_POS (STACK_CMD_LINE_SIZE - 4)
#define FP_CMD_LINE_POS (RA_CMD_LINE_POS - 4)
#define GP_CMD_LINE_POS (FP_CMD_LINE_POS -4)

.text
  .globl processCmdLine 
  .ent   processCmdLine
processCmdLine:  
  .frame $fp, STACK_CMD_LINE_SIZE, ra
  .set  noreorder
  .cpload t9
  .set  reorder
  subu  sp, sp, STACK_CMD_LINE_SIZE
  .cprestore GP_CMD_LINE_POS
  
  sw  ra, RA_CMD_LINE_POS(sp)
  sw  $fp, FP_CMD_LINE_POS(sp)
  sw  gp, GP_CMD_LINE_POS(sp)
  move  $fp, sp  
  sw a0,  STACK_CMD_LINE_SIZE(sp)
  sw a1,  (STACK_CMD_LINE_SIZE + 4)(sp)
  sw a2,  (STACK_CMD_LINE_SIZE + 8)(sp)
  sw a3,  (STACK_CMD_LINE_SIZE + 12)(sp)
  
  # Me fijo si la cantidad de argumentos es la correcta
  li t0, 3 # cantdad OK de a0
  bne a0, t0, count_arg_bad
  
  # Valido el primer argumento obligatorio leido, este debe ser "-l"
  la a0, Arg_Long # a0 apunta a la cadena Arg_Long 
  addi a1, a1, 4  # apunta al argumento arv[1]
  lw a1, 0(a1) # desreferencio el puntero a punteros a1, o sea a1 = a1*
  jal MyStrcmp
  bgtz v0, arg_ref_invalid
  
    
  # recupero los valores originales de los argumentos
  lw a0, STACK_CMD_LINE_SIZE(sp)
  lw a1, (STACK_CMD_LINE_SIZE + 4)(sp)
  # Para utilizar la funcion dec2Int, es necesario que a0 apunte a la 
  # cadena que reprecenta el valor numerico 
  
  addi a0, a1, 8 # hago que a0 apunte a argv[2]
  lw a0, 0(a0) # desreferencio el puntero a punteros a0, o sea a0 = a0*
  jal dec2Int
  bgtz v1, arg_long_invalid
  
  # si esta todo OK, salgo directamente por end_processCmdLine
  b end_processCmdLine

count_arg_bad:
arg_ref_invalid:
arg_long_invalid:
  # En el caso de que v0 es cero ( caso absurdo ) indica que se produjo un 
  # se intro dujo una linea de comando no valida
  move v0, zero

end_processCmdLine:
  lw a0, STACK_CMD_LINE_SIZE(sp)
  lw a1, (STACK_CMD_LINE_SIZE + 4)(sp)
  lw a2, (STACK_CMD_LINE_SIZE + 8)(sp)
  lw a3, (STACK_CMD_LINE_SIZE + 12)(sp)
  lw  ra, RA_CMD_LINE_POS(sp)
  lw  $fp, FP_CMD_LINE_POS(sp)
  lw  gp, GP_CMD_LINE_POS(sp)
  addu  sp, sp, STACK_CMD_LINE_SIZE
  j ra
  .end processCmdLine
  


	#*****************************************************
  #                   nibbleSplit
  # toma un caracter de 1 byte en ascii y devuelve 
  # 2 bytes, que contienen los 2 nibles por separados 
  # del correspodiente valor numerico del caracter de
  # entrada
  # Como todo byte se puede procesar, no hay precondicion
  # necesaria
  #*****************************************************
#define STACK_NIBBLE_SPLIT_SIZE 32
#define FP_NIBBLE_SPLIT_POS (STACK_NIBBLE_SPLIT_SIZE - 4)
#define GP_NIBBLE_SPLIT_POS (FP_NIBBLE_SPLIT_POS - 4)

.text
  .globl nibbleSplit
  .ent   nibbleSplit
  #-------------------------------------------
  #                nibbleSplit
  #     a0 -> valor en ascii de caracter
  # Observacion : se asume que el caracter a convertir 
  #               es de un byte
  # Valores de Retorno : 
  #      v0 -> nible menos significativo del caracter
  #      v1 -> nible mas significativo del caracter
  #-------------------------------------------
nibbleSplit:
  .frame $fp, STACK_NIBBLE_SPLIT_SIZE, ra
  .set  noreorder
  .cpload t9
  .set  reorder
  subu  sp, sp, STACK_NIBBLE_SPLIT_SIZE
  .cprestore GP_NIBBLE_SPLIT_POS
  sw  $fp, FP_NIBBLE_SPLIT_POS(sp)
  sw  gp, GP_NIBBLE_SPLIT_POS(sp)
  move  $fp, sp
  sw a0, STACK_NIBBLE_SPLIT_SIZE(sp)
  sw a1, (STACK_NIBBLE_SPLIT_SIZE + 4)(sp)
  sw a2, (STACK_NIBBLE_SPLIT_SIZE + 8)(sp)
  sw a3, (STACK_NIBBLE_SPLIT_SIZE + 12)(sp)
  
  li t0, 0x10
  #tomamos el primer nible:
  div a0, t0
  mflo v0
  mfhi v1

return_nibbleSplit:
  lw a0, STACK_NIBBLE_SPLIT_SIZE(sp)
  lw a1, (STACK_NIBBLE_SPLIT_SIZE + 4)(sp)
  lw a2, (STACK_NIBBLE_SPLIT_SIZE + 8)(sp)
  lw a3, (STACK_NIBBLE_SPLIT_SIZE + 12)(sp)
  # Destruimos el frame.
  lw  gp, GP_NIBBLE_SPLIT_POS(sp)
  lw $fp, FP_NIBBLE_SPLIT_POS(sp)
  addu  sp, sp, STACK_NIBBLE_SPLIT_SIZE
  # Retorno.
  j ra
  .end nibbleSplit
  #*****************************************************

  #*****************************************************
  #                   MyStrcmp
  # Argumentos: Las cadenas deben terminar con el 
  #             Caracter null
  #            a0 -> Puntero de cadena a comparar
  #            a1 -> Puntero de cadena a comaprar
  # Retorno :
  #           v0 = 0 -> las cadenas son igules
  #           v0 = 1 -> las cadenas son diferentes 
  #*****************************************************
#define STACK_MYSTRCMP_SIZE 32
#define FP_MYSTRCMP_POS (STACK_MYSTRCMP_SIZE - 4)
#define GP_MYSTRCMP_POS (FP_MAIN_POS -4)
.text
  .globl MyStrcmp
  .ent   MyStrcmp

MyStrcmp:
  .frame $fp, STACK_MYSTRCMP_SIZE, ra
  .set  noreorder
  .cpload t9
  .set  reorder
  subu  sp, sp, STACK_MYSTRCMP_SIZE
  .cprestore GP_MYSTRCMP_POS
  sw  $fp, FP_MYSTRCMP_POS(sp)
  sw  gp, GP_MYSTRCMP_POS(sp)
  move  $fp, sp
  sw a0, STACK_MYSTRCMP_SIZE(sp)  
  sw a1, (STACK_MYSTRCMP_SIZE + 4)(sp)
  sw a2, (STACK_MYSTRCMP_SIZE + 8)(sp)
  sw a3, (STACK_MYSTRCMP_SIZE + 12)(sp)
  
  move v0, zero # son iguales hasta que se demuestre lo contrario
  
MyStrcmp_loop:
  lb t0, 0(a0)
  lb t1, 0(a1)
  addi a0, a0, 1
  addi a1, a1, 1
  addu t2, t1, t0
  beqz t2, return_MyStrcmp
  beq t1, t0, MyStrcmp_loop
Are_different:
  li v0, 1

return_MyStrcmp:
  lw a0, STACK_MYSTRCMP_SIZE(sp)  
  lw a1, (STACK_MYSTRCMP_SIZE + 4)(sp)
  lw a2, (STACK_MYSTRCMP_SIZE + 8)(sp)
  lw a3, (STACK_MYSTRCMP_SIZE + 12)(sp)
  lw  $fp, FP_MYSTRCMP_POS(sp)
  lw  gp, GP_MYSTRCMP_POS(sp)
  addu sp, sp, STACK_MYSTRCMP_SIZE
  j ra
  .end MyStrcmp
  #*****************************************************


  #*****************************************************
  #                   hexNum2Char
  #*****************************************************
  # toma un valor numerico de un digito en hexa y devuelve 
  # el digito correspondiente en ascii 
  # se asume que el digito ingresado es menor a o igual
  # a 0x0f
  # Argumentos : 
  #       a0 -> digito numerico
  # Valores de Retorno : 
  #      v0 -> caracter ascii correspondiente
  #-------------------------------------------
#define STACK_HEXNUM2CHAR_SIZE 32
#define FP_HEXNUM2CHAR_POS (STACK_HEXNUM2CHAR_SIZE - 4)  
#define GP_HEXNUM2CHAR_POS (FP_HEXNUM2CHAR_POS -4)

.data
hexaChain: # Cadena para obtener el ascii equivalente
           # para cada valor numerico
  .asciiz "0123456789ABCDEF"
.text
  .globl hexNum2Char 
  .ent   hexNum2Char 

 
hexNum2Char:
  .frame $fp, STACK_HEXNUM2CHAR_SIZE, ra
  .set  noreorder
  .cpload t9
  .set  reorder
  subu  sp, sp, STACK_HEXNUM2CHAR_SIZE 
  .cprestore GP_HEXNUM2CHAR_POS
  sw  $fp, FP_HEXNUM2CHAR_POS(sp)
  sw  gp, GP_HEXNUM2CHAR_POS(sp)
  move  $fp, sp
  sw a0, STACK_HEXNUM2CHAR_SIZE(sp)
  sw a1, (STACK_HEXNUM2CHAR_SIZE + 4)(sp)
  sw a2, (STACK_HEXNUM2CHAR_SIZE + 8)(sp)
  sw a3, (STACK_HEXNUM2CHAR_SIZE + 12)(sp)
  
  la t0, hexaChain
  move t1, zero  # limpiamos el registro t1
  add t1, t0, a0 # t1 apunta al caracter correspondiente
  lbu v0, 0(t1)  # indexo en la cadena hexaChain el digito
                 # correspondiente
  
return_hexNum2Char:
  # recupero los registros guardados
  lw a0, STACK_HEXNUM2CHAR_SIZE(sp)
  lw a1, (STACK_HEXNUM2CHAR_SIZE + 4)(sp)
  lw a2, (STACK_HEXNUM2CHAR_SIZE + 8)(sp)
  lw a3, (STACK_HEXNUM2CHAR_SIZE + 12)(sp)
  # Destruimos el frame.
  lw  gp, GP_HEXNUM2CHAR_POS(sp)
  lw $fp, FP_HEXNUM2CHAR_POS(sp)
  addu  sp, sp, STACK_HEXNUM2CHAR_SIZE
  # Retorno.
  j ra
  .end hexNum2Char
  
  
  #*****************************************************
  
  #*****************************************************
  #                     dec2Int
  # Convierte un string que reprecenta un numero decimal
  # en su correspondiente binario
  # Precondicion : El numero decimal a leer es una 
  #                cadena de caracteres terminadas en null
  # Agumento : 
  #           puntero a la cadena de caracteres
  # Retorno : 
  #           v0 : word con valor decimal correspondiente en
  #                binario
  #           v1 : word con valor de error
  #*****************************************************
  #define STACK_DEC2INT_SIZE 32
  #define FP_DEC2INT_POS (STACK_DEC2INT_SIZE - 4)
  #define GP_DEC2INT_POS (FP_DEC2INT_POS -4)
.text
  .globl dec2Int 
  .ent   dec2Int

dec2Int:
  .frame $fp, STACK_DEC2INT_SIZE, ra
  .set  noreorder
  .cpload t9
  .set  reorder
  subu  sp, sp, STACK_DEC2INT_SIZE
  .cprestore GP_DEC2INT_POS
  sw  $fp, FP_DEC2INT_POS(sp)
  sw  gp, GP_DEC2INT_POS(sp)
  move  $fp, sp
  sw a0, STACK_DEC2INT_SIZE(sp)
  sw a1, (STACK_DEC2INT_SIZE + 4)(sp)
  sw a2, (STACK_DEC2INT_SIZE + 8)(sp)
  sw a3, (STACK_DEC2INT_SIZE + 12)(sp)

  li t1, 10
  move v0, zero
  move v1, zero
  
dec2Int_calc_loop:
  lbu t0, 0(a0) # guardo el byte en t0
  beqz t0, end_calc # llego al final del argumento
  mulo v0, v0, t1
  sub t0, t0, '0'
  bgt t0, 9, dec2Int_IsNotDecimal
  add v0, v0, t0
  add a0, a0, 1
  b dec2Int_calc_loop

dec2Int_IsNotDecimal:
  li v1, 1

end_calc:
  lw a0, STACK_DEC2INT_SIZE(sp)
  lw a1, (STACK_DEC2INT_SIZE + 4)(sp)
  lw a2, (STACK_DEC2INT_SIZE + 8)(sp)
  lw a3, (STACK_DEC2INT_SIZE + 12)(sp)
  lw  $fp, FP_DEC2INT_POS(sp)
  lw  gp, GP_DEC2INT_POS(sp)
  addu  sp, sp, STACK_DEC2INT_SIZE
  # Retorno
  j ra
  .end dec2Int
  #*****************************************************

  #*****************************************************
  

