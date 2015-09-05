# return.c
# --------	
#
# int main(int argc, char** argv)
# {
# 	return argc;
# }
#
###############################################################################

	.text
	.globl	main
main:
	subu	$sp,$sp,16	# creo stack frame
	sw	$fp,12($sp)
	sw	$gp,8($sp)
	move	$fp,$sp

	sw	$a0,16($fp)	# aqui almaceno args (argc = 1er arg)
	sw	$a1,20($fp)	# (argv = 2do arg)
	lw	$v0,16($fp)	# return argc;

	move	$sp,$fp		# destruyo stack frame
	lw	$fp,12($sp)
	addu	$sp,$sp,16
	j	$ra
