import gleam/io
import gleam/string_builder
import gleam/int
import gleam/float
import gleam/list
import gleam/function
import gleam/pair
import simplifile
import nibble

// Equation:
// Velocity = time
// Distance = time * (total - time)
// = time * total - time^2
// = -time² + total*time
//
// So...
// -time² + total * time > record
// -time² + total * time - record > 0
//
// a = -1, b = total, c = -record
//
// x = (-total +- sqrt(total² - 4 * record)) / -2

type Race {
  Race(total: Int, record: Int)
}

fn calculate_times(race: Race) -> #(Int, Int) {
  let assert Ok(root) =
    int.square_root(race.total * race.total - 4 * race.record)

  let total_float = int.to_float(race.total) *. -1.0

  let a = { total_float +. root } /. { -2.0 } +. 0.0001
  let b = { total_float -. root } /. { -2.0 } -. 0.0001

  #(float.round(float.ceiling(a)), float.round(float.floor(b)))
}

pub fn main() {
  // let sample = [Race(7, 9), Race(15, 40), Race(30, 200)]
  let assert Ok(contents) = simplifile.read("input.txt")

  let parse_time =
    nibble.succeed(function.identity)
    |> nibble.drop(nibble.string("Time:"))
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(nibble.many(nibble.int(), nibble.whitespace()))
    |> nibble.drop(nibble.whitespace())

  let parse_distance =
    nibble.succeed(function.identity)
    |> nibble.drop(nibble.string("Distance:"))
    |> nibble.drop(nibble.whitespace())
    |> nibble.keep(nibble.many(nibble.int(), nibble.whitespace()))
    |> nibble.drop(nibble.whitespace())

  let parser =
    nibble.succeed(function.curry2(list.zip))
    |> nibble.keep(parse_time)
    |> nibble.keep(parse_distance)
    |> nibble.map(list.map(_, fn(a: #(Int, Int)) { Race(a.0, a.1) }))

  let assert Ok(races) = nibble.run(contents, parser)

  let part1 =
    races
    |> list.map(calculate_times)
    |> list.map(fn(a) { a.1 - a.0 + 1 })
    |> list.fold(1, fn(a, b) { a * b })

  let part2 =
    races
    |> list.fold(
      #("", ""),
      fn(acc, race) {
        let #(time, distance) = acc
        #(
          time <> int.to_string(race.total),
          distance <> int.to_string(race.record),
        )
      },
    )
    |> pair.map_first(int.parse)
    |> pair.map_second(int.parse)
    |> fn(race) {
      let assert #(Ok(a), Ok(b)) = race
      Race(a, b)
    }
    |> calculate_times()
    |> fn(a: #(Int, Int)) { a.1 - a.0 + 1 }

  string_builder.new()
  |> string_builder.append("Part 1: ")
  |> string_builder.append(int.to_string(part1))
  |> string_builder.append("\nPart 2: ")
  |> string_builder.append(int.to_string(part2))
  |> string_builder.to_string()
  |> io.println()
}
