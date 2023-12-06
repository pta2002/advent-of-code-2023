import gleam/io
import gleam/dict.{type Dict}
import gleam/list
import gleam/int
import nibble
import simplifile
import gleam/function

type Range {
  Range(dest: Int, source: Int, len: Int)
}

type Map {
  Map(from: String, to: String, ranges: List(Range))
}

type Almanac {
  Almanac(seeds: List(#(Int, Int)), maps: Dict(String, Map))
}

fn intersection(a: #(Int, Int), b: #(Int, Int)) -> Result(#(Int, Int), Nil) {
  let new_lower = int.max(a.0, b.0)
  let new_upper = int.min(a.1, b.1)

  case new_lower > new_upper {
    True -> Error(Nil)
    False -> Ok(#(new_lower, new_upper))
  }
}

fn find_range(ranges: List(Range), number: Int) -> List(Range) {
  case ranges {
    [] -> []
    [head, ..rest] if head.source > number -> rest
    [head, ..rest] if head.source <= number ->
      case head.source + head.len {
        end if end > number -> [head, ..rest]
        _ -> find_range(rest, number)
      }
  }
}

fn convert(ranges: List(Range), range: #(Int, Int)) -> List(#(Int, Int)) {
  let reduced_ranges =
    find_range(ranges, range.0)
    |> list.take_while(fn(r) { r.source < range.0 + range.1 })

  case reduced_ranges {
    [] -> [range]
    [head, ..rest] if head.source < range.0 -> todo
  }

  todo
}

fn convert_to(
  maps: Dict(String, Map),
  from: String,
  to: String,
  range: #(Int, Int),
) -> List(#(Int, Int)) {
  case from == to {
    True -> [range]
    False -> {
      let assert Ok(map) = dict.get(maps, from)
      let next = convert(map.ranges, range)

      next
      |> list.map(convert_to(maps, map.to, to, _))
      |> list.concat()
    }
  }
}

pub fn main() {
  let assert Ok(contents) = simplifile.read("input.txt")

  let ranges_parser =
    nibble.succeed(function.curry3(Range))
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(nibble.int())

  let seeds_pair =
    nibble.succeed(function.curry2(fn(a, b) { #(a, b) }))
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(nibble.int())

  let seeds_parser = nibble.many(seeds_pair, nibble.whitespace())

  let map_parser =
    nibble.succeed(function.curry3(Map))
    |> nibble.keep(nibble.take_until(fn(a) { a == "-" }))
    |> nibble.drop(nibble.string("-to-"))
    |> nibble.keep(nibble.take_until(fn(a) { a == " " }))
    |> nibble.drop(nibble.string(" map:"))
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(
      nibble.many(ranges_parser, nibble.whitespace())
      |> nibble.map(list.sort(_, fn(a: Range, b: Range) {
        int.compare(a.source, b.source)
      })),
    )

  let parser =
    nibble.succeed(function.curry2(Almanac))
    |> nibble.drop(nibble.string("seeds: "))
    |> nibble.keep(seeds_parser)
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(
      nibble.many(map_parser, nibble.whitespace())
      |> nibble.map(list.fold(
        _,
        dict.new(),
        fn(map, item: Map) { dict.insert(map, item.from, item) },
      )),
    )

  let assert Ok(almanac) = nibble.run(contents, parser)

  let assert Ok(part1) =
    almanac.seeds
    |> list.map(convert_to(almanac.maps, "seed", "location", _))
    |> list.concat()
    |> list.reduce(fn(a, b) {
      case a.0 < b.0 {
        True -> a
        False -> b
      }
    })

  io.print("Part 1: ")
  io.debug(part1)

  Nil
}
