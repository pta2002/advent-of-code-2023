import gleam/io
import simplifile.{read}
import gleam/string
import gleam/list
import gleam/result
import gleam/string_builder
import gleam/int

fn find_numbers(line: String, part1: Bool) -> List(Int) {
  let next = find_numbers(_, part1)
  case line {
    "" -> []
    "0" <> rest -> [0, ..next(rest)]
    "1" <> rest -> [1, ..next(rest)]
    "2" <> rest -> [2, ..next(rest)]
    "3" <> rest -> [3, ..next(rest)]
    "4" <> rest -> [4, ..next(rest)]
    "5" <> rest -> [5, ..next(rest)]
    "6" <> rest -> [6, ..next(rest)]
    "7" <> rest -> [7, ..next(rest)]
    "8" <> rest -> [8, ..next(rest)]
    "9" <> rest -> [9, ..next(rest)]
    _ ->
      case part1 {
        True -> next(string.drop_left(line, 1))
        False ->
          case line {
            "one" <> rest -> [1, ..next("ne" <> rest)]
            "two" <> rest -> [2, ..next("wo" <> rest)]
            "three" <> rest -> [3, ..next("hree" <> rest)]
            "four" <> rest -> [4, ..next("our" <> rest)]
            "five" <> rest -> [5, ..next("ive" <> rest)]
            "six" <> rest -> [6, ..next("ix" <> rest)]
            "seven" <> rest -> [7, ..next("even" <> rest)]
            "eight" <> rest -> [8, ..next("ight" <> rest)]
            "nine" <> rest -> [9, ..next("ine" <> rest)]
            _ -> next(string.drop_left(line, 1))
          }
      }
  }
}

pub fn main() {
  let assert Ok(contents) = read("input.txt")

  let part1 =
    string.split(contents, on: "\n")
    |> list.map(fn(x) { find_numbers(x, True) })
    |> list.map(fn(x) {
      let f =
        list.first(x)
        |> result.unwrap(0)
      let l =
        list.last(x)
        |> result.unwrap(0)

      f * 10 + l
    })
    |> list.fold(0, fn(a, b) { a + b })

  let part2 =
    string.split(contents, on: "\n")
    |> list.map(fn(x) { find_numbers(x, False) })
    |> list.map(fn(x) {
      let f =
        list.first(x)
        |> result.unwrap(0)
      let l =
        list.last(x)
        |> result.unwrap(0)

      f * 10 + l
    })
    |> list.fold(0, fn(a, b) { a + b })

  string_builder.new()
  |> string_builder.append("Part 1: ")
  |> string_builder.append(int.to_string(part1))
  |> string_builder.append("\nPart 2: ")
  |> string_builder.append(int.to_string(part2))
  |> string_builder.to_string()
  |> io.println()
}
