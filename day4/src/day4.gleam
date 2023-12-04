import gleam/io
import gleam/set.{Set}
import nibble
import gleam/function
import gleam/list
import gleam/int
import simplifile
import gleam/dict

type ScratchCard {
  ScratchCard(number: Int, winning: Set(Int), numbers: Set(Int))
}

fn find_wins(card: ScratchCard) -> Set(Int) {
  set.intersection(card.winning, card.numbers)
}

fn to_counts(cards: List(#(Int, Int))) -> List(Int) {
  case cards {
    [#(n, wins), ..rest] -> {
      // Add wins to the rest

      let #(a, b) = list.split(rest, wins)

      list.concat([list.map(a, fn(x) { #(x.0 + n, x.1) }), b])
      |> to_counts()
      |> list.prepend(n)
    }
    [] -> []
  }
}

pub fn main() {
  let number_set =
    nibble.many(nibble.int(), nibble.whitespace())
    |> nibble.map(set.from_list)

  let scratch_parser =
    nibble.succeed(function.curry3(ScratchCard))
    |> nibble.drop(nibble.string("Card"))
    |> nibble.drop(nibble.spaces())
    |> nibble.keep(nibble.int())
    |> nibble.drop(nibble.grapheme(":"))
    |> nibble.drop(nibble.spaces())
    |> nibble.keep(number_set)
    |> nibble.drop(nibble.spaces())
    |> nibble.drop(nibble.grapheme("|"))
    |> nibble.drop(nibble.spaces())
    |> nibble.keep(number_set)

  let parser = nibble.many(scratch_parser, nibble.whitespace())

  let assert Ok(contents) = simplifile.read("input.txt")
  let assert Ok(scratch_cards) = nibble.run(contents, parser)

  let part1 =
    scratch_cards
    |> list.map(find_wins)
    |> list.map(set.size)
    |> list.map(fn(x) { int.bitwise_shift_left(1, x) / 2 })
    |> list.fold(0, fn(a, b) { a + b })

  io.print("Part 1: ")
  io.debug(part1)

  let part2 =
    scratch_cards
    |> list.map(fn(x) {
      #(
        1,
        find_wins(x)
        |> set.size(),
      )
    })
    |> to_counts()
    |> list.fold(0, fn(a, b) { a + b })

  io.print("Part 2: ")
  io.debug(part2)
}
