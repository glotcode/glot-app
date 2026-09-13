import gleam/dict
import gleam/int
import gleam/list
import gleam/string

pub const token_limit = 16_384

pub const candidate_limit = 200

pub type Fingerprint {
  Fingerprint(
    token_count: Int,
    trigram_hashes: List(Int),
    signature: List(Int),
    bands: List(String),
  )
}

pub fn fingerprint(tokens: List(String)) -> Fingerprint {
  let tokens = list.take(tokens, token_limit)
  let hashes =
    tokens
    |> list.window(3)
    |> list.map(fn(words) { hash(string.join(words, " ")) })
    |> list.fold(dict.new(), fn(acc, hash) { dict.insert(acc, hash, Nil) })
    |> dict.keys
    |> list.sort(int.compare)
  let #(_, permutations) =
    list.fold(list.repeat(Nil, 64), #(104_729, []), fn(state, _) {
      let a = { state.0 * 48_271 } % prime
      let b = { a * 48_271 } % prime
      #(b, [#(a, b), ..state.1])
    })
  let signature =
    permutations
    |> list.reverse
    |> list.map(fn(permutation) {
      // Fixed affine permutations modulo a prime; no runtime random seed.
      let #(a, b) = permutation
      list.fold(hashes, prime, fn(minimum, value) {
        int.min(minimum, { a * value + b } % prime)
      })
    })
  let bands =
    signature
    |> list.sized_chunk(4)
    |> list.index_map(fn(values, index) {
      int.to_string(index)
      <> ":"
      <> string.join(list.map(values, int.to_string), ":")
    })
  Fingerprint(list.length(tokens), hashes, signature, bands)
}

const prime = 2_147_483_647

/// Explicit stable hash; never use VM hash functions for persisted fingerprints.
pub fn hash(value: String) -> Int {
  value
  |> string.to_utf_codepoints
  |> list.fold(0, fn(acc, point) {
    { acc * 31 + string.utf_codepoint_to_int(point) + 1 } % prime
  })
}

pub fn jaccard(left: Fingerprint, right: Fingerprint) -> Float {
  let right_set =
    list.fold(right.trigram_hashes, dict.new(), fn(acc, value) {
      dict.insert(acc, value, Nil)
    })
  let intersection =
    list.count(left.trigram_hashes, fn(value) { dict.has_key(right_set, value) })
  let union =
    list.length(left.trigram_hashes)
    + list.length(right.trigram_hashes)
    - intersection
  case union {
    0 -> 0.0
    _ -> int.to_float(intersection) /. int.to_float(union)
  }
}

pub fn is_neighbor(left: Fingerprint, right: Fingerprint) -> Bool {
  left.token_count >= 20
  && right.token_count >= 20
  && jaccard(left, right) >=. 0.8
}
