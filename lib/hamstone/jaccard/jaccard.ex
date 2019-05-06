defmodule Hamstone.Jaccard do
  @moduledoc """
  Utility library for similarity.
  """

  @stop_words [
    "the", "a", "an", "and", "or", "you", "i", "in", "on", "to", "from", "is",
    "are", "do", "that", "have", "it", "for", "not", "with", "he", "as", "at",
    "this", "but", "his", "by", "they", "we", "say", "her", "she", "or", "will",
    "my", "one", "all", "would", "there", "what", "so", "up", "out", "if",
    "about", "get", "go", "me", "can", "like", "no", "take", "good", "your",
    "them", "then", "now", "look", "also", "did", "does", "got", "had", "has",
    "make", "made", "makes", "these", "those", "here", "i've", "just", "where",
    "be", "how", "why", "many", "of"
    ]

  def jaccard_similarity(text1, text2) do
    shingles1 = find_shingles(text1)
    shingles2 = find_shingles(text2)
    union = MapSet.union(shingles1, shingles2)
    intersect = MapSet.intersection(shingles1, shingles2)
    if MapSet.size(union) == 0 do
      0
    else
      MapSet.size(intersect) / MapSet.size(union)
    end
  end

  def find_shingles(text) when is_binary(text) do
    text = String.downcase(text)
    text = String.replace(text, ~r/[\p{P}\p{S}]/, "")
    words = String.split(text, " ")
    find_shingles(words, MapSet.new())
  end

  def find_shingles([word1 | [word2 | [word3 | tail]]], shingles) do
    if Enum.member?(@stop_words, word1) do
      find_shingles([word2 | [word3 | tail]], MapSet.put(shingles, {word1, word2, word3}))
    else
      find_shingles([word2 | [word3 | tail]], shingles)
    end
  end

  def find_shingles([], shingles), do: shingles
  def find_shingles([_], shingles), do: shingles
  def find_shingles([_, _], shingles), do: shingles

  def find_shingles(text1, text2) when is_binary(text1) do
    shingles1 = find_shingles(text1)
    shingles2 = find_shingles(text2)
    intersect = MapSet.intersection(shingles1, shingles2)
    intersect
  end
end