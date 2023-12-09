import gleam/io
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import gleam/iterator
import gleam/function
import nibble
import nibble/predicates
import simplifile

type Direction {
  Left
  Right
}

type Node {
  Node(label: String, next: #(String, String))
}

type Map =
  Dict(String, Node)

fn walk(map: Map, node: String, dir: Direction) -> String {
  let assert Ok(next) = case dir {
    Left ->
      dict.get(map, node)
      |> result.map(fn(n) { n.next.0 })
    Right ->
      dict.get(map, node)
      |> result.map(fn(n) { n.next.1 })
  }

  next
}

fn walk_to(
  map: Map,
  directions: List(Direction),
  start: String,
  end: fn(String) -> Bool,
) -> List(String) {
  iterator.from_list(directions)
  |> iterator.cycle()
  |> iterator.fold_until(
    from: [start],
    with: fn(steps: List(String), dir: Direction) {
      let assert [node, ..] = steps
      let next = walk(map, node, dir)
      case end(next) {
        True -> list.Stop(list.reverse([next, ..steps]))
        False -> list.Continue([next, ..steps])
      }
    },
  )
}

fn gcd(a: Int, b: Int) -> Int {
  case #(a, b) {
    #(0, _) -> b
    #(_, 0) -> a
    _ -> gcd(b, a % b)
  }
}

fn lcm(ns: List(Int)) -> Int {
  let assert Ok(n) = list.reduce(ns, fn(a, b) { a * b / gcd(a, b) })

  n
}

fn walk_pt2(map: Map, directions: List(Direction)) -> Int {
  let cycles: List(Int) =
    dict.keys(map)
    |> list.filter(string.ends_with(_, "A"))
    |> list.map(fn(node) {
      walk_to(map, directions, node, string.ends_with(_, "Z"))
      |> list.length()
      |> fn(a) { a - 1 }
    })

  lcm(cycles)
}

pub fn main() {
  let dir_parser =
    nibble.one_of([
      nibble.grapheme("L")
      |> nibble.map(function.constant(Left)),
      nibble.grapheme("R")
      |> nibble.map(function.constant(Right)),
    ])

  let string_parser = nibble.take_while(predicates.is_alphanum)

  let node_parser =
    nibble.succeed(function.curry2(Node))
    |> nibble.keep(string_parser)
    |> nibble.drop(nibble.whitespace())
    |> nibble.drop(nibble.grapheme("="))
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(
      nibble.succeed(function.curry2(fn(a, b) { #(a, b) }))
      |> nibble.drop(nibble.grapheme("("))
      |> nibble.keep(string_parser)
      |> nibble.drop(nibble.grapheme(","))
      |> nibble.drop(nibble.whitespace())
      |> nibble.keep(string_parser)
      |> nibble.drop(nibble.grapheme(")")),
    )

  let full_parser =
    nibble.succeed(function.curry2(fn(a, b) { #(a, b) }))
    |> nibble.keep(nibble.loop(
      [],
      fn(p) {
        nibble.one_of([
          nibble.succeed(list.prepend(p, _))
          |> nibble.keep(dir_parser)
          |> nibble.map(nibble.Continue),
          nibble.succeed(p)
          |> nibble.map(list.reverse)
          |> nibble.map(nibble.Break),
        ])
      },
    ))
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(
      nibble.many(node_parser, nibble.whitespace())
      |> nibble.map(list.fold(
        _,
        dict.new(),
        fn(d, n: Node) { dict.insert(d, n.label, n) },
      )),
    )

  let assert Ok(contents) = simplifile.read("input.txt")
  let assert Ok(#(directions, map)) = nibble.run(contents, full_parser)

  let part1 =
    walk_to(map, directions, "AAA", fn(a) { a == "ZZZ" })
    |> list.length()
    |> fn(a) { a - 1 }

  io.print("Part 1: ")
  io.debug(part1)

  let part2 = walk_pt2(map, directions)

  io.print("Part 2: ")
  io.debug(part2)
}
