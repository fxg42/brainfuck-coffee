# Trying out Highland.js is the main reason for writing this.

_ = require 'highland'


# Immutable brainfuck virtual machine.

class BrainfuckVM
  constructor: (@mem = [], @mp = 0, @ip = 0) ->
  execute: (instructions) -> instructions[@ip](@) while instructions[@ip]
  getMem: -> @mem[@mp]
  incMem: -> @mem[@mp] = (@mem[@mp] or 0) + 1
  decMem: -> @mem[@mp] = (@mem[@mp] or 0) - 1
  setIP: (ip) -> @ip = ip
  incIP: -> @ip++
  incMP: -> @mp++
  decMP: -> @mp--

# Subset of brainfuck tokens. Left out: IO operators.

ADD = '+'
SUB = '-'
LBRACK = '['
RBRACK = ']'
LT = '<'
GT = '>'
OPS = /[\+\-\[\]<>]/


# Token-to-instruction map e.g. '+' increments the memory register at the
# current memory pointer than increments the instruction pointer.

INSTRUCTION_MAP = {}

INSTRUCTION_MAP[ADD] = (vm) -> vm.incMem(); vm.incIP()

INSTRUCTION_MAP[SUB] = (vm) -> vm.decMem(); vm.incIP()

INSTRUCTION_MAP[GT] = (vm) -> vm.incMP(); vm.incIP()
INSTRUCTION_MAP[LT] = (vm) -> vm.decMP(); vm.incIP()

INSTRUCTION_MAP[LBRACK] = (jump) -> (vm) -> if vm.getMem() then vm.incIP() else vm.setIP(jump+1)
INSTRUCTION_MAP[RBRACK] = (jump) -> (vm) -> vm.setIP(jump)


# Splits the source strings into single characters.

splitChars = (sourceString) -> sourceString.split ''


# Filters-out comments and whitespace.

validOperators = (char) -> OPS.test char


# Loops through characters and determines the jump targets for left and right
# brackets. Returns a syntax node {char, jump}.

syntaxNodes = (chars) ->
  jumpStack = []
  nodes = []
  for char, index in chars
    do ->
      if char is LBRACK
        jumpStack.push index
      if char is RBRACK
        jump = jumpStack.pop()
        nodes[jump].jump = index
      nodes.push {char, jump}
  nodes
    

# Given a syntaxNode, return the corresponding instruction. Jump instructions
# are partially applied with the jump target.

instructions = (syntaxNode) ->
  instruction = INSTRUCTION_MAP[syntaxNode.char]
  instruction = instruction(syntaxNode.jump) if syntaxNode.jump isnt undefined
  instruction


# Apply an instruction to a virtual machine. Returns a virtual machine.

execute = (instructions) ->
  vm = new BrainfuckVM()
  vm.execute(instructions)
  console.log vm


# Group transformations together

parser = (s) ->
  s.flatMap splitChars
   .filter validOperators
   .collect()
   .flatMap syntaxNodes

interpreter = (s) ->
  s.map instructions
   .toArray execute

# Prints out a vm.

result = (err, vm) -> console.log vm


# Small brainsfuck program that initializes 2 registers and sums them: "+++>+++++[-<+>]"

source = ["
  +++     add 3 to mem0
  >       go to mem1
  +++++   add 5 to mem1
  [       while mem1 isnt 0
    -       dec mem1
    <       goto mem0
    +       inc mem0
    >       goto mem1
  ]       end
"]

# Stream, parse and execute the source code.

_ source
  .through parser
  .through interpreter
