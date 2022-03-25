const loremIpsumFull =
  "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.";
const loremIpsumWords = loremIpsumFull.split(" ");

export function loremIpsum(words = 4): string {
  let remaining = words;

  let result = "";
  while (remaining >= loremIpsumWords.length) {
    result += loremIpsumFull;
    remaining -= loremIpsumWords.length;
  }
  return result + loremIpsumWords.slice(0, remaining).join(" ");
}
