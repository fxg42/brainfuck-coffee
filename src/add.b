Small brainsfuck program that initializes 2 registers and sums them

+++     add 3 to mem0
>       go to mem1
+++++   add 5 to mem1
[       while mem1 isnt 0
  -       dec mem1
  <       goto mem0
  +       inc mem0
  >       goto mem1
]       end
<       goto mem0

vim:ft=brainfuck
