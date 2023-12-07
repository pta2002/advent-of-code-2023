import gleam/io
import gleam/dict.{type Dict}
import gleam/list
import gleam/int
import nibble
import simplifile
import gleam/function

type Range {
  Range(transform: Int, source: #(Int, Int))
}

type Map {
  Map(from: String, to: String, ranges: List(Range))
}

type Almanac {
  Almanac(seeds: List(#(Int, Int)), maps: Dict(String, Map))
}

fn convert(ranges: List(Range), range: #(Int, Int)) -> List(#(Int, Int)) {
  case ranges {
    [] -> [range]
    [Range(transform: _, source: source), ..] if source.0 > range.1 -> [range]
    [Range(transform: _, source: source), ..rest] if source.1 <= range.0 ->
      convert(rest, range)
    [Range(transform: transform, source: source), ..] if source.0 <= range.0 && source.1 >= range.1 -> {
      [#(range.0 + transform, range.1 + transform)]
    }
    [Range(transform: transform, source: source), ..rest] if source.0 <= range.0 && source.1 < range.1 -> {
      convert(rest, #(source.1, range.1))
      |> list.prepend(#(range.0 + transform, source.1 + transform))
    }
    [Range(transform: transform, source: source), ..rest] if source.0 > range.0 && source.0 < range.1 -> {
      [#(range.0, source.0), #(source.0 + transform, range.1 + transform)]
    }
  }
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
    nibble.succeed(function.curry3(fn(dest, source, len) {
      Range(transform: dest - source, source: #(source, source + len))
    }))
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(nibble.int())

  let seeds_pair =
    nibble.succeed(function.curry2(fn(a, b) { #(a, a + b) }))
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
        int.compare(a.source.0, b.source.0)
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

  let assert Ok(#(part1, _)) =
    almanac.seeds
    |> list.fold(
      [],
      fn(list, seed) {
        let #(a, b) = seed
        [#(a, a + 1), #(b - a, b - a + 1), ..list]
      },
    )
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

  let assert Ok(#(part2, _)) =
    almanac.seeds
    |> list.map(convert_to(almanac.maps, "seed", "location", _))
    |> list.concat()
    |> list.reduce(fn(a, b) {
      case a.0 < b.0 {
        True -> a
        False -> b
      }
    })

  io.print("Part 2: ")
  io.debug(part2)

  Nil
}
