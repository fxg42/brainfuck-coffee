# Trying out Highland.js is the main reason for writing this.

_ = require 'highland'


# Immutable brainfuck virtual machine.

class BrainfuckVM
  constructor: (@mem, @mp, @ip) ->
    # @mem: holds the program memory
    # @mp: memory pointer
    # @ip: instruction pointer

  @initial: -> new BrainfuckVM([], 0, 0)

  getMem: -> @mem[@mp]

  incMem: ->
    clone = @mem.slice(0)
    clone[@mp] = (clone[@mp] or 0) + 1
    new BrainfuckVM(clone, @mp, @ip)

  decMem: ->
    clone = @mem.slice(0)
    clone[@mp] = (clone[@mp] or 0) - 1
    new BrainfuckVM(clone, @mp, @ip)

  setIP: (ip) -> new BrainfuckVM(@mem, @mp, ip)

  incIP: -> new BrainfuckVM(@mem, @mp, @ip++)

  incMP: -> new BrainfuckVM(@mem, @mp++, @ip)

  decMP: -> new BrainfuckVM(@mem, @mp--, @ip)


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

INSTRUCTION_MAP =
  '+': (vm) -> vm.incMem().incIP()
  '-': (vm) -> vm.decMem().incIP()

  '>': (vm) -> vm.incMP().incIP()
  '<': (vm) -> vm.decMP().incIP()

  '[': (jump) -> (vm) -> if vm.getMem() then vm.incIP() else vm.setIP(jump+1)
  ']': (jump) -> (vm) -> vm.setIP(jump)


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

execute = (vm, instruction) -> instruction(vm)


# Prints out a vm.

result = (err, vm) -> console.log vm


# mem[0] = 3
# mem[1] = 5
# mem[0] = mem[0] + mem[1]

source = ["
  +++     add 3 to reg0
  >       go to reg1
  +++++   add 5 to reg1
  [       while reg1 isnt 0
    -       dec reg1
    <       goto reg0
    +       inc reg0
    >       goto reg1
  ]       end
  <       goto reg0
"]


# Stream parse and execute the source document.

_ source
  .flatMap splitChars
  .filter validOperators
  .collect()
  .flatMap syntaxNodes
  .map instructions
  .reduce BrainfuckVM.initial(), execute
  .pull result

