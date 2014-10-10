# Trying out Highland.js is the main reason for writing this.

_ = require 'highland'


# Brainfuck virtual machine.

class BrainfuckVM
  constructor: (@mem = [], @mp = 0, @ip = 0) ->

  execute: (instructions) ->
    instructions[@ip](@) while instructions[@ip]

  getMem: -> @mem[@mp]
  incMem: -> @mem[@mp] = (@mem[@mp] or 0) + 1
  decMem: -> @mem[@mp] = (@mem[@mp] or 0) - 1

  setIP: (ip) -> @ip = ip
  incIP: -> @ip++

  incMP: -> @mp++
  decMP: -> @mp--

# Subset of brainfuck tokens. Left out ',' operator.

DOT = '.'
ADD = '+'
SUB = '-'
LBRACK = '['
RBRACK = ']'
LT = '<'
GT = '>'
OPS = /[\.\+\-\[\]<>]/


# Token-to-instruction map e.g. '+' increments the memory register at the
# current memory pointer than increments the instruction pointer.

INSTRUCTION_MAP = {}

INSTRUCTION_MAP[DOT] = (vm) -> console.log(String.fromCharCode(vm.getMem())); vm.incIP()

INSTRUCTION_MAP[ADD] = (vm) -> vm.incMem(); vm.incIP()
INSTRUCTION_MAP[SUB] = (vm) -> vm.decMem(); vm.incIP()

INSTRUCTION_MAP[GT] = (vm) -> vm.incMP(); vm.incIP()
INSTRUCTION_MAP[LT] = (vm) -> vm.decMP(); vm.incIP()

INSTRUCTION_MAP[LBRACK] = (jump) -> (vm) -> if vm.getMem() then vm.incIP() else vm.setIP(jump+1)
INSTRUCTION_MAP[RBRACK] = (jump) -> (vm) -> vm.setIP(jump)


# Token to js-snippet map.

SNIPPET_MAP = {}
SNIPPET_MAP[DOT] = "console.log(String.fromCharCode(mem[mp]));"
SNIPPET_MAP[ADD] = "mem[mp] = (mem[mp] || 0) + 1;"
SNIPPET_MAP[SUB] = "mem[mp] = (mem[mp] || 0) - 1;"
SNIPPET_MAP[GT] = "mp++;"
SNIPPET_MAP[LT] = "mp--;"
SNIPPET_MAP[LBRACK] = "while(mem[mp]){"
SNIPPET_MAP[RBRACK] = "}"

# Splits the source strings into single characters.

splitChars = (sourceString) -> sourceString.split ''


# Filters-out comments and whitespace.

validOperators = (char) -> OPS.test char


# Loops through characters and determines the jump targets for left and right
# brackets. Returns a token {char, jump}.

tokens = (chars) ->
  jumpStack = []
  tokens = []
  for char, index in chars
    do ->
      if char is LBRACK
        jumpStack.push index
      if char is RBRACK
        jump = jumpStack.pop()
        tokens[jump].jump = index
      tokens.push {char, jump}
  tokens
    

# Given a token, return the corresponding instruction. Jump instructions are
# partially applied with the jump target.

instructions = (token) ->
  instruction = INSTRUCTION_MAP[token.char]
  instruction = instruction(token.jump) if token.jump isnt undefined
  instruction


# Given a token, return the corresponding js snippet.

snippets = (token) -> SNIPPET_MAP[token.char]

# Join all snippets with a newline.

generateJS = (code, snippet) -> "#{code}\n#{snippet}"
  

# Apply an instruction to a virtual machine. Returns a virtual machine.

execute = (instructions) ->
  vm = new BrainfuckVM()
  vm.execute(instructions)
  vm


# Group transformations together

parser = (sourceStream) ->
  sourceStream
    .flatMap splitChars
    .filter validOperators
    .collect()
    .flatMap tokens

interpreter = (tokenStream) ->
  tokenStream
    .map instructions
    .collect()
    .map execute

jsGenerator = (tokenStream) ->
  tokenStream
    .map snippets
    .reduce "var mem=[], mp=0;", generateJS

# Small brainsfuck program that initializes 2 registers and sums them: "+++>+++++[-<+>]"

add35 = ["
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
"]

helloWorld = ["++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."]

# Stream, parse and execute the source code.

source = add35

_ source
  .through parser
  # .through interpreter
  .through jsGenerator
  .apply _.log
