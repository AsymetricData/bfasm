import gleam/int

pub fn increment(register: String, by: Int) -> String {
  "add " <> register <> ", " <> int.to_string(by)
}

pub fn increment_byte(register: String, by: Int) -> String {
  increment("byte [" <> register <> "]", by)
}

pub fn decrement(register: String, by: Int) -> String {
  "sub " <> register <> ", " <> int.to_string(by)
}

pub fn decrement_byte(register: String, by: Int) -> String {
  decrement("byte [" <> register <> "]", by)
}
