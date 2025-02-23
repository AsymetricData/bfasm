import gleam/io
import gleam/list
import gleam/string
import parser

pub fn main() {
  let assert Ok(tokens_instr) =
    parser.parse("++.>>>><<<<><<<<<<-----++++++.++++++++++.")
  let fasm_instr = tokens_instr |> parser.to_fasm
  fasm_instr
  |> list.map(fn(inst) { io.println(inst) })
}
