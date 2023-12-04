import gleam/dict.{Dict}
import gleam/io
import gleam/string
import gleam/iterator
import simplifile
import gleam/list
import gleam/function
import gleam/pair
import gleam/int
import gleam/set
import gleam/result
import nibble

type Pos =
  #(Int, Int)

type MapElement {
  Number(num: Int, start: Pos, end: Pos)
  Part(pos: Pos, name: String)
}

type Map =
  Dict(Pos, MapElement)

fn is_part(part: String) -> Bool {
  case part {
    "." -> False
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> False
    _ -> True
  }
}

// fn find_parts(map: Map) -> List(Pos) {
//   map
//   |> dict.filter(fn(_key, value) { is_part(value) })
//   |> dict.keys()
// }
//

fn is_digit(n: String) -> Bool {
  case n {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn parse_line(line: String, y: Int, start_x: Int) -> Map {
  case string.pop_grapheme(line) {
    Error(_) -> dict.new()
    Ok(#(".", rest)) -> parse_line(rest, y, start_x + 1)
    Ok(#(head, rest)) ->
      case head {
        "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> {
          let #(digits, rest) =
            string.to_graphemes(line)
            |> list.split_while(is_digit)
            |> pair.map_second(string.join(_, ""))

          let assert Ok(number) =
            digits
            |> string.join("")
            |> int.parse()

          parse_line(rest, y, start_x + list.length(digits))
          |> dict.merge(
            iterator.range(start_x, start_x + list.length(digits) - 1)
            |> iterator.fold(
              dict.new(),
              fn(map, x) {
                dict.insert(
                  map,
                  #(x, y),
                  Number(
                    num: number,
                    start: #(start_x, y),
                    end: #(start_x + list.length(digits), y),
                  ),
                )
              },
            ),
          )
        }

        n ->
          parse_line(rest, y, start_x + 1)
          |> dict.insert(#(start_x, y), Part(pos: #(start_x, y), name: n))
      }
  }
}

fn get_adjacent(part: MapElement, map: Map) -> List(MapElement) {
  let assert Part(name: _, pos: pos) = part

  // Get adjacent
  iterator.range(pos.0 - 1, pos.0 + 1)
  |> iterator.fold(
    set.new(),
    fn(state, x) {
      iterator.range(pos.1 - 1, pos.1 + 1)
      |> iterator.map(fn(y) { dict.get(map, #(x, y)) })
      |> iterator.to_list()
      |> result.values()
      |> set.from_list()
      |> set.union(state)
    },
  )
  |> set.to_list()
}

pub fn main() {
  let assert Ok(contents) = simplifile.read("input.txt")

  let map =
    contents
    |> string.split("\n")
    |> list.index_fold(
      dict.new(),
      fn(map, line, y) { dict.merge(map, parse_line(line, y, 0)) },
    )

  let parts =
    map
    |> dict.filter(fn(key, val) {
      case val {
        Part(_, _) -> True
        _ -> False
      }
    })
    |> dict.values()

  let part1: Int =
    parts
    |> list.map(fn(part) {
      get_adjacent(part, map)
      |> list.filter(fn(e) {
        case e {
          Part(_, _) -> False
          _ -> True
        }
      })
      |> list.map(fn(p) {
        let assert Number(num: num, start: _, end: _) = p
        num
      })
      |> list.fold(0, fn(a, b) { a + b })
    })
    |> list.fold(0, fn(a, b) { a + b })

  let part2: Int =
    parts
    |> list.filter(fn(part) {
      case part {
        Part(name: "*", pos: _) -> True
        _ -> False
      }
    })
    |> list.map(fn(part) {
      let adj =
        get_adjacent(part, map)
        |> list.filter(fn(e) {
          case e {
            Part(_, _) -> False
            _ -> True
          }
        })
        |> list.map(fn(p) {
          let assert Number(num: num, start: _, end: _) = p
          num
        })
      case adj {
        [a, b] -> a * b
        _ -> 0
      }
    })
    |> list.fold(0, fn(a, b) { a + b })

  io.print("Part 1: ")
  io.debug(part1)
  io.print("Part 2: ")
  io.debug(part2)

  Nil
}
