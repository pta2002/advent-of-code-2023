import gleam/io
import simplifile.{read}
import nibble
import gleam/function
import gleam/list
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string_builder

type Cube {
  Red
  Green
  Blue
}

type Play =
  List(#(Cube, Int))

type Game {
  Game(id: Int, plays: List(Play))
}

fn combine_with(a: Option(a), b: Option(a), with: fn(a, a) -> a) -> Option(a) {
  case a {
    Some(a) ->
      case b {
        Some(b) -> Some(with(a, b))
        None -> Some(a)
      }
    None -> b
  }
}

fn or_with(a: Option(a), b: a, with: fn(a, a) -> a) -> Option(a) {
  combine_with(a, Some(b), with)
}

pub fn main() {
  let assert Ok(contents) = read("input.txt")

  let color_parser =
    nibble.one_of([
      nibble.string("red")
      |> nibble.replace(Red),
      nibble.string("green")
      |> nibble.replace(Green),
      nibble.string("blue")
      |> nibble.replace(Blue),
    ])

  let balls_parser =
    nibble.succeed(function.curry2(fn(a, b) { #(b, a) }))
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.spaces())
    |> nibble.keep(color_parser)

  let play_parser = nibble.many(balls_parser, nibble.string(", "))
  let game_plays_parser = nibble.many(play_parser, nibble.string("; "))
  let game_parser =
    nibble.succeed(function.curry2(Game))
    |> nibble.drop(nibble.string("Game "))
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.string(": "))
    |> nibble.keep(game_plays_parser)

  let games_parser = nibble.many(game_parser, nibble.whitespace())

  let assert Ok(games) = nibble.run(contents, games_parser)

  let part1 =
    games
    |> list.filter(fn(game) {
      game.plays
      |> list.all(list.all(_, fn(play) {
        let #(color, n) = play
        case color {
          Red -> n <= 12
          Green -> n <= 13
          Blue -> n <= 14
        }
      }))
    })
    |> list.map(fn(game) { game.id })
    |> list.fold(0, fn(a, b) { a + b })

  let part2 =
    games
    |> list.map(fn(game) {
      #(
        game.id,
        list.map(
          game.plays,
          list.fold(
            _,
            #(None, None, None),
            fn(prev, play) {
              let #(r, g, b) = prev

              case play {
                #(Red, n) -> #(or_with(r, n, fn(r, n) { r + n }), g, b)
                #(Green, n) -> #(r, or_with(g, n, fn(g, n) { g + n }), b)
                #(Blue, n) -> #(r, g, or_with(b, n, fn(b, n) { b + n }))
              }
            },
          ),
        ),
      )
    })
    |> list.map(fn(game) {
      let #(id, rounds) = game
      #(
        id,
        list.reduce(
          rounds,
          fn(prev, round) {
            #(
              combine_with(prev.0, round.0, int.max),
              combine_with(prev.1, round.1, int.max),
              combine_with(prev.2, round.2, int.max),
            )
          },
        )
        |> fn(a) {
          let assert Ok(#(Some(r), Some(g), Some(b))) = a

          r * g * b
        },
      )
    })
    |> list.fold(0, fn(a, b) { a + b.1 })

  string_builder.new()
  |> string_builder.append("Part 1: ")
  |> string_builder.append(int.to_string(part1))
  |> string_builder.append("\nPart 2: ")
  |> string_builder.append(int.to_string(part2))
  |> string_builder.to_string()
  |> io.println()

  Nil
}
