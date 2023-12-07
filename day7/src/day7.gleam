import gleam/io
import gleam/order.{type Order}
import gleam/int
import gleam/list
import gleam/function
import gleam/dict
import gleam/result
import gleam/string
import gleam/string_builder
import simplifile

type HandCategory {
  FiveOfAKind
  FourOfAKind
  FullHouse
  ThreeOfAKind
  TwoPair
  OnePair
  HighCard
}

type Card =
  String

type Hand =
  List(Card)

type Bid {
  Bid(hand: Hand, bid: Int)
}

fn compare_hand_cat(a: HandCategory, b: HandCategory) -> Order {
  let hand_to_int = fn(h) {
    case h {
      HighCard -> 0
      OnePair -> 1
      TwoPair -> 2
      ThreeOfAKind -> 3
      FullHouse -> 4
      FourOfAKind -> 5
      FiveOfAKind -> 6
    }
  }

  int.compare(hand_to_int(a), hand_to_int(b))
}

fn compare_card(a: Card, b: Card, part2: Bool) -> Order {
  let card_to_int = fn(h) {
    case h {
      "2" -> 1
      "3" -> 2
      "4" -> 3
      "5" -> 4
      "6" -> 5
      "7" -> 6
      "8" -> 7
      "9" -> 8
      "T" -> 9
      "J" if part2 == False -> 10
      "J" if part2 -> 0
      "Q" -> 11
      "K" -> 12
      "A" -> 13
      _ -> panic
    }
  }

  int.compare(card_to_int(a), card_to_int(b))
}

fn categorize(hand: Hand) -> HandCategory {
  let grouped: dict.Dict(Card, List(Card)) =
    list.group(hand, by: function.identity)

  case
    dict.keys(grouped)
    |> list.length()
  {
    1 -> FiveOfAKind
    // Four of a kind, or full house
    2 ->
      case
        dict.values(grouped)
        |> list.map(list.length(_))
        |> list.sort(by: int.compare)
      {
        [1, 4] -> FourOfAKind
        [2, 3] -> FullHouse
      }
    // Three of a kind, or two pair
    3 ->
      case
        dict.values(grouped)
        |> list.map(list.length(_))
        |> list.sort(by: int.compare)
      {
        [1, 1, 3] -> ThreeOfAKind
        [1, 2, 2] -> TwoPair
      }
    4 -> OnePair
    5 -> HighCard
  }
}

fn categorize2(hand: Hand) -> HandCategory {
  let grouped: dict.Dict(Card, List(Card)) =
    list.group(hand, by: function.identity)

  let jokers =
    dict.get(grouped, "J")
    |> result.unwrap([])

  let no_jokers = dict.delete(grouped, "J")

  case
    dict.keys(no_jokers)
    |> list.length()
  {
    0 | 1 -> FiveOfAKind
    // Four of a kind, or full house
    2 ->
      case
        dict.values(no_jokers)
        |> list.map(list.length(_))
        |> list.sort(by: int.compare)
      {
        [1, _] -> FourOfAKind
        [2, _] -> FullHouse
      }
    // Three of a kind, or two pair
    3 ->
      case
        dict.values(no_jokers)
        |> list.map(list.length(_))
        |> list.sort(by: int.compare)
      {
        [1, 1, _] -> ThreeOfAKind
        [1, 2, _] -> TwoPair
      }
    4 -> OnePair
    5 -> HighCard
  }
}

fn compare_hand(a: Hand, b: Hand, part2: Bool) -> Order {
  let cat = case part2 {
    True -> categorize2
    False -> categorize
  }

  let a_cat = cat(a)
  let b_cat = cat(b)

  case compare_hand_cat(a_cat, b_cat) {
    order.Eq -> {
      list.zip(a, b)
      |> list.map(fn(a) { compare_card(a.0, a.1, part2) })
      |> list.find(fn(a) { a != order.Eq })
      |> result.unwrap(order.Eq)
    }
    o -> o
  }
}

pub fn main() {
  let assert Ok(contents) = simplifile.read("input.txt")

  let game =
    contents
    |> string.split("\n")
    |> list.filter(fn(a) { a != "" })
    |> list.map(fn(line) {
      line
      |> string.split(" ")
      |> fn(l) {
        let assert [a, b] = l
        let assert Ok(i) = int.parse(b)
        Bid(string.to_graphemes(a), i)
      }
    })

  let part1 =
    game
    |> list.sort(by: fn(a, b) { compare_hand(a.hand, b.hand, False) })
    |> list.index_map(fn(i, h) { { i + 1 } * h.bid })
    |> list.fold(0, fn(a, b) { a + b })

  let part2 =
    game
    |> list.sort(by: fn(a, b) { compare_hand(a.hand, b.hand, True) })
    |> list.index_map(fn(i, h) { { i + 1 } * h.bid })
    |> list.fold(0, fn(a, b) { a + b })

  string_builder.new()
  |> string_builder.append("Part 1: ")
  |> string_builder.append(int.to_string(part1))
  |> string_builder.append("\nPart 2: ")
  |> string_builder.append(int.to_string(part2))
  |> string_builder.to_string()
  |> io.println()
}
