import gleam/io
import gleam/list
import gleam/string
import gleam/int
import simplifile

fn diffs(ls: List(Int)) -> List(Int) {
  case ls {
    [a, b] -> [a - b]
    [a, b, ..rest] -> [a - b, ..diffs([b, ..rest])]
    _ -> panic
  }
}

fn find_next(ls: List(Int)) -> Int {
  let assert [head, ..] = ls
  case list.all(ls, fn(x) { x == 0 }) {
    True -> 0
    False -> {
      head + find_next(diffs(ls))
    }
  }
}

pub fn main() {
  let assert Ok(contents) = simplifile.read("input.txt")
  let nums =
    contents
    |> string.split("\n")
    |> list.map(fn(s) {
      string.split(s, " ")
      |> list.filter_map(int.parse)
    })
    |> list.filter(fn(a) { list.length(a) > 0 })

  let part1 =
    nums
    |> list.map(list.reverse)
    |> list.map(find_next)
    |> list.fold(0, fn(a, b) { a + b })

  io.print("Part 1: ")
  io.debug(part1)

  let part2 =
    nums
    |> list.map(find_next)
    |> list.fold(0, fn(a, b) { a + b })

  io.print("Part 2: ")
  io.debug(part2)
}
