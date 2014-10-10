_ = require 'highland'

ADD = '+'
SUB = '-'
LBRACK = '['
RBRACK = ']'
LT = '<'
GT = '>'
OPS = /[\+\-\[\]<>]/

INSTRUCTION_MAP =
  "#{ADD}": (vm) -> vm.incMem().incIP()
  "#{SUB}": (vm) -> vm.decMem().incIP()

  "#{GT}": (vm) -> vm.incMP().incIP()
  "#{LT}": (vm) -> vm.decMP().incIP()

  "#{LBRACK}": (jump) -> (vm) -> if vm.getMem() then vm.incIP() else vm.setIP(jump+1)
  "#{LBRACK}": (jump) -> (vm) -> vm.setIP(jump)

class VirtualMachine
  constructor: (@mem, @mp, @ip) ->

  @initial: -> new VirtualMachine([], 0, 0)

  getMem: -> @mem[@mp]

  incMem: ->
    clone = @mem.slice(0)
    clone[@mp] = (clone[@mp] or 0) + 1
    new VirtualMachine(clone, @mp, @ip)

  decMem: ->
    clone = @mem.slice(0)
    clone[@mp] = (clone[@mp] or 0) - 1
    new VirtualMachine(clone, @mp, @ip)

  setIP: (ip) -> new VirtualMachine(@mem, @mp, ip)

  incIP: -> new VirtualMachine(@mem, @mp, @ip++)

  incMP: -> new VirtualMachine(@mem, @mp++, @ip)

  decMP: -> new VirtualMachine(@mem, @mp--, @ip)

splitChars = (sourceString) -> sourceString.split ''

validOperators = (char) -> OPS.test char

syntaxNodes = (chars) ->
  jumpStack = []
  operators = []
  for char, index in chars
    do ->
      if char is LBRACK
        jumpStack.push index
      if char is RBRACK
        jump = jumpStack.pop()
        operators[jump].jump = index
      operators.push {char, jump}
  operators
    
instructions = (operator) ->
  instruction = INSTRUCTION_MAP[operator.char]
  instruction = instruction(operator.jump) if operator.jump
  instruction

execute = (vm, instruction) -> instruction(vm)

result = (err, vm) -> console.log vm

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

_ source
  .flatMap splitChars
  .filter validOperators
  .collect()
  .flatMap syntaxNodes
  .map instructions
  .reduce VirtualMachine.initial(), execute
  .pull result
