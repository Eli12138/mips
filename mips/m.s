

# Maximum and minimum values for the 3 parameters.
# 常量定义，相当于C语言的#define
MIN_WORLD_SIZE	=    1
MAX_WORLD_SIZE	=  128
MIN_GENERATIONS	= -256
MAX_GENERATIONS	=  256
MIN_RULE	=    0
MAX_RULE	=  255

# Characters used to print alive/dead cells.

ALIVE_CHAR	= '#'
DEAD_CHAR	= '.'

# Maximum number of bytes needs to store all generations of cells.

MAX_CELLS_BYTES	= (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE

	.data
# `cells' is used to store successive generations.  Each byte will be 1
# if the cell is alive in that generation, and 0 otherwise.

rule: .space 4
reverse: .space 4
world_size:	.space 4
n_generations: .space 4
cells:	.space MAX_CELLS_BYTES

# Some strings you'll need to use:

prompt_world_size:	.asciiz "Enter world size: "
error_world_size:	.asciiz "Invalid world size\n"
prompt_rule:		.asciiz "Enter rule: "
error_rule:			.asciiz "Invalid rule\n"
prompt_n_generations:	.asciiz "Enter how many generations: "
error_n_generations:	.asciiz "Invalid number of generations\n"

	.text

	#
	# $s0: load memory temporary or count in loop
	#
	# $s0->world_size->rule->n_generations->0->n_generations->abs(n_generations)

main:
	#建立栈
	addi $sp, $sp, -4
    sw   $fp, ($sp)
	#保存旧fp
    la   $fp, ($sp)#讲现在的栈尾sp转移给fp
    addi $sp, $sp, -4
	#保存ra地址，保证main可以正确退出
    sw   $ra, ($sp)
    addi $sp, $sp, -4
	#保存本地变量
    sw   $a0, ($sp)
    addi $sp, $sp, -4
    sw   $a1, ($sp)
    addi $sp, $sp, -4
    sw   $a3, ($sp)
    addi $sp, $sp, -4     
    sw   $s0, ($sp)
    addi $sp, $sp, -4
    sw   $s1, ($sp)
    addi $sp, $sp, -4
    sw   $s2, ($sp)
    addi $sp, $sp, -4
    sw   $s3, ($sp)
	
	la $a0, prompt_world_size;	# printf("Enter world size: ");
	li $v0, 4
	syscall
	
	li $v0, 5;					# scanf("%d", &world_size);
	syscall
	sw $v0, world_size
	
	lw $s0, world_size
	blt	$s0, MIN_WORLD_SIZE, error_size 	# if world_size < MIN_WORLD_SIZE then
	bgt	$s0, MAX_WORLD_SIZE, error_size		# if world_size > MAX_WORLD_SIZE then
	
	la $a0, prompt_rule			# printf("Enter rule: ");
	li $v0, 4
	syscall
	
	li $v0, 5;					# scanf("%d", &rule);
	syscall
	sw $v0, rule
	
	lw $s0, rule
	blt	$s0, MIN_RULE, error_rule_print 	# if rule < MIN_RULE then
	bgt	$s0, MAX_RULE, error_rule_print		# if rule > MAX_RULE then
	
	la $a0, prompt_n_generations	# printf("Enter how many generations: ");
	li $v0, 4
	syscall

	li $v0, 5;					# scanf("%d", &n_generations);
	syscall
	sw $v0, n_generations
	
	lw $s0, n_generations
	blt	$s0, MIN_GENERATIONS, error_gene	# if rule < MIN_GENERATIONS then
	bgt	$s0, MAX_GENERATIONS, error_gene	# if rule > MAX_GENERATIONS then
	
	li $a0, '\n'
	li $v0, 11
	syscall #putchar('\n');
	syscall #putchar('\n');
	syscall #putchar('\n');

	li $s0, 0
	sw $s0, reverse				# int reverse = 0;
	
	lw $s0, n_generations
	bge	$s0, 0, first_gene		# n_generations < 0
	
	li $t0, 1
	sw $t0, reverse				# reverse = 1;
	lw $t0, n_generations
	neg $t0, $t0
	sw $t0, n_generations		# n_generations = -n_generations;

	# $s0: the initial adress of cells and the adress ofcells[0][world_size / 2]
	# $s1: load world_size and caculate [world_size / 2] and change this cells
	# $s0:cells->cells[0][world_size / 2]
	# $s1:world_size->world_size / 2->[world_size / 2]-> 1	
first_gene:	
	la $s0, cells				# cells[0][0]
	lw $s1, world_size			# world_size
	
	div $s1, $s1, 2				# world_size / 2
	mul $s1, $s1, 4				# [world_size / 2]
	add $s0, $s0, $s1			# cells[0][world_size / 2]
	
	li $s1, 1
	sw $s1, ($s0)				# cells[0][world_size / 2] = 1;

	li $s0, 1					# int g = 1
	lw $s1, n_generations
	
	# Given `world_size', `which_generation', and `rule', calculate
	# a new generation according to `rule' and store it in `cells'.
	# $s0: g
	# $s1: n_generations
	# $s0: 0~n_generations
run_all_genes:
	bgt	$s0, $s1, reverse_if	# g > n_generations
	
	lw $a0, world_size
	move $a1, $s0
	lw $a2, rule
	sw   $ra, -4($sp) 
	jal run_generation			# run_generation(world_size, g, rule);
	lw   $ra, -4($sp) 
	 
	add $s0, $s0, 1				# g++
	b run_all_genes
	# $s0: g
	# $s1: n_generations
	# $s2: reverse
reverse_if:
	lw $s2, reverse
	bne	$s2, 0, reverse_loop		# if (reverse)
	li $s0, 0				# int g = 0
	lw $s1, n_generations	
print_inreverse:
	bgt	$s0, $s1, end		# while (g <= n_generations)
	lw $a0, world_size
	move $a1, $s0
	sw   $ra, -4($sp) 			#将ra保存进栈
	jal print_generation
	lw   $ra, -4($sp) 			#将ra从栈中恢复
	add $s0, 1
	b print_inreverse
	# $s0: g
	# $s1= reverse
reverse_loop:
	lw $s0, n_generations	# int x = n_generations
print_reverse:
	blt	$s0, 0, end		# while (g >= 0)
	lw $a0, world_size
	move $a1, $s0
	sw   $ra, -4($sp) 
	jal print_generation
	lw   $ra, -4($sp) 
	sub $s0, 1			# g--;
	b print_reverse

error_size:
	la $a0, error_world_size;	# printf("Invalid world size\n");
	li $v0, 4
	syscall
	b end_program
error_rule_print:
	la $a0, error_rule;			# printf("Invalid rule\n");
	li $v0, 4
	syscall
	b end_program
error_gene:
	la $a0, error_n_generations;	# printf("Invalid number of generations\n");
	li $v0, 4
	syscall

end_program:
	#恢复栈
	#恢复本地变量
	lw   $s3, ($sp)
    addi $sp, $sp, 4
    lw   $s2, ($sp)
    addi $sp, $sp, 4
    lw   $s1, ($sp)
    addi $sp, $sp, 4
    lw   $s0, ($sp)
    addi $sp, $sp, 4
    lw   $a2, ($sp)
    addi $sp, $sp, 4
    lw   $a1, ($sp)
    addi $sp, $sp, 4
    lw   $a0, ($sp)
    addi $sp, $sp, 4
    lw   $ra, ($sp)
	#恢复ra
    addi $sp, $sp, 4
	# 恢复fp
    lw   $fp, ($sp)
    addi $sp, $sp, 4
	li $v0, 1
	jr $ra
	# if your code for `main' preserves $ra by saving it on the
	# stack, and restoring it after calling `print_world' and
	# `run_generation'.  [ there are style marks for this ]
################################################################################################	
#Functions:
	# $t0: x
	# $t1: left
	# $t2: right
	# $t3: centre
	# $t4: the adress of cells
	# $t5: register to caculate the adress
	# $t7: world_size 
run_generation:
	li $t0, 0			# int x = 0;
	move $t7, $a0		
loop_run:
	bge $t0, $t7, end_run	# x < world_size
	
	li $t1, 0			# int left = 0;
	li $t2, 0			# int right = 0;
	la $t4, cells		# cells[0][0]
	
	mul $t5, $a1, 512	# [which_generation][0]
	sub $t5, $t5, 512	# [which_generation - 1][0]
	add $t4, $t5, $t4	# $t4 =$cells[which_generation - 1][0]
	
	mul $t5, $t0, 4		# [x]
	add $t4, $t4, $t5	# cells[which_generation - 1][x]
	lw	$t3, ($t4)		# int centre = cells[which_generation - 1][x];
	
	
	
	bgt $t0, 0, left	# x > 0
	# $t6: world_size - 1 and the adress of [x + 1]
right:
	sub $t6, $t7, 1
	bge $t0, $t6, convert		# x < world_size - 1
	add $t6, $t4, 4
	lw $t2, ($t6)				# right = cells[which_generation - 1][x + 1];
	# $t1,$t2,$t3:caculate set
convert:
	sll $t1, $t1, 2
	sll $t3, $t3, 1
	sll $t2, $t2, 0
	or $t1, $t1, $t2
	or $t1, $t1, $t3		# int state = left << 2 | centre << 1 | right << 0;
	li $t2, 1
	sll $t1, $t2, $t1 		# int bit = 1 << state;
	and $t1, $a2, $t1		# int set = rule & bit;

	add $t4, $t4, 512		# cells[which_generation][x]
	bne	$t1, 0, cells_1		# if (set)
cell_0:
	li $t2, 0
	sw $t2, ($t4)			# cells[which_generation][x] = 0;
	lw $t6, ($t4)
loop_run_down:
	add $t0, $t0, 1			# x++;
	b loop_run
cells_1:
	li $t2, 1				
	sw $t2, ($t4)			# cells[which_generation][x] = 1;
	b loop_run_down
	# $t6:the adress of [x - 1]
left:
	sub $t6, $t4, 4
	lw $t1, ($t6)			# left = cells[which_generation - 1][x - 1];
	b right
end_run:
	jr	$ra
	#
	# Given `world_size', and `which_generation', print out the
	# specified generation.
	#

	# $t0: x
	# $t1: world_size
	# $t2: the adress of cells
	# $t3: [which_generation]
	# $t4: [x]

print_generation:
	la $t2, cells
	mul $t3, $a1, 512 	# [which_generation]
	add $t2, $t3, $t2	# cells[which_generation][0]
	move $a0, $a1
	li $v0, 1			# printf("%d", which_generation);
	syscall
	li $a0, '\t' 		# putchar('\t');
	li $v0, 11
	syscall

	li $t0, 0			# int x = 0
	lw $t1, world_size
	
loop_print:
	bge $t0, $t1, end_print
	mul $t4, $t0, 4
	
	add $t3, $t2, $t4 #[x]
	lw $t5, ($t3)#cells[which_generation][x
	bne	$t5, 0, than
	li $a0, DEAD_CHAR		# putchar(DEAD_CHAR)
	li $v0, 11
	syscall
loop_print_down:
	add $t0, $t0, 1			# x++;
	b loop_print
	
than:
	li $a0, ALIVE_CHAR		# putchar(ALIVE_CHAR)
	li $v0, 11
	syscall
	b loop_print_down
end_print:
	li $a0, '\n'
	li $v0, 11
	syscall
	jr	$ra
end:
	li $v0, 0
	jr $ra
