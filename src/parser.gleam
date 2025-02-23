import fasm
import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string

/// Basic Brainfuck instructions
pub type Instruction {
  IncrementPointer(by: Int)
  // >
  DecrementPointer(by: Int)
  // <
  IncrementByte(by: Int)
  // +
  DecrementByte(by: Int)
  // -
  OutputByte
  // .
}

pub type ParsingError {
  EmptySource
}

/// Try to convert a String into a List of Instruction or return an error
pub fn parse(source: String) -> Result(List(Instruction), ParsingError) {
  use <- bool.guard(string.is_empty(source), Error(EmptySource))
  source |> string.to_graphemes |> parse_instruction([])
}

/// Converts Brainfuck instructions to FASM code with comments
pub fn to_fasm(instructions: List(Instruction)) -> List(String) {
  let header = [
    "section .data",
    "    tape resb 30000   ; Allocate 30,000 bytes for Brainfuck memory", "",
    "section .text", "    global _start", "", "_start:",
    "    mov rsi, tape     ; Initialize data pointer",
  ]

  let footer = [
    "", "    ; Exit program", "    mov rax, 60       ; syscall: exit",
    "    xor rdi, rdi      ; exit code 0", "    syscall",
  ]

  list.append(
    header,
    instructions
      |> optimize
      |> instructions_to_fasm([])
      |> list.reverse,
  )
  |> list.append(footer)
}

/// Combines consecutive instructions for optimization
pub fn optimize(instr: List(Instruction)) -> List(Instruction) {
  list.fold(instr, [], fn(acc, current) -> List(Instruction) {
    case acc {
      [] -> [current]
      [prev, ..next] ->
        case prev, current {
          DecrementByte(n1), DecrementByte(n2) -> [
            DecrementByte(n1 + n2),
            ..next
          ]
          IncrementByte(n1), IncrementByte(n2) -> [
            IncrementByte(n1 + n2),
            ..next
          ]
          IncrementPointer(n1), IncrementPointer(n2) -> [
            IncrementPointer(n1 + n2),
            ..next
          ]
          DecrementPointer(n1), DecrementPointer(n2) -> [
            DecrementPointer(n1 + n2),
            ..next
          ]
          _, _ -> [current, prev, ..next]
        }
    }
  })
  |> list.reverse
}

/// Converts Instructions to FASM assembly with comments
fn instructions_to_fasm(
  instructions: List(Instruction),
  output: List(String),
) -> List(String) {
  case instructions {
    [] -> output
    [head, ..tail] ->
      case head {
        DecrementByte(n) ->
          instructions_to_fasm(tail, [
            "    sub byte [rsi], "
              <> int.to_string(n)
              <> "  ; Decrease byte at pointer by "
              <> int.to_string(n),
            ..output
          ])
        IncrementByte(n) ->
          instructions_to_fasm(tail, [
            "    add byte [rsi], "
              <> int.to_string(n)
              <> "  ; Increase byte at pointer by "
              <> int.to_string(n),
            ..output
          ])
        IncrementPointer(n) ->
          instructions_to_fasm(tail, [
            "    add rsi, "
              <> int.to_string(n)
              <> "         ; Move pointer right by "
              <> int.to_string(n),
            ..output
          ])
        DecrementPointer(n) ->
          instructions_to_fasm(tail, [
            "    sub rsi, "
              <> int.to_string(n)
              <> "         ; Move pointer left by "
              <> int.to_string(n),
            ..output
          ])
        OutputByte ->
          instructions_to_fasm(tail, [
            "    ; Output the byte at pointer",
            "    mov rax, 1      ; syscall: write",
            "    mov rdi, 1      ; file descriptor: stdout",
            "    mov rdx, 1      ; length: 1 byte",
            "    mov rsi, rsi    ; buffer address",
            "    syscall",
            ..output
          ])
      }
  }
}

/// Converts Brainfuck source code into Instructions
fn parse_instruction(
  chars: List(String),
  acc: List(Instruction),
) -> Result(List(Instruction), ParsingError) {
  case chars {
    [] -> Ok(acc |> list.reverse)
    [char, ..rest] ->
      case char {
        "+" -> parse_instruction(rest, [IncrementByte(1), ..acc])
        "-" -> parse_instruction(rest, [DecrementByte(1), ..acc])
        ">" -> parse_instruction(rest, [IncrementPointer(1), ..acc])
        "<" -> parse_instruction(rest, [DecrementPointer(1), ..acc])
        "." -> parse_instruction(rest, [OutputByte, ..acc])
        c -> {
          io.debug("Unknown char " <> c)
          parse_instruction(rest, acc)
        }
      }
  }
}
