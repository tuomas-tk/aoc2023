import fs from "node:fs";
import assert from "node:assert";

// PARSING

const getInput = (): string[] =>
  fs.readFileSync("./input.txt", "utf8").split("\n");

type Left = "L";
type Right = "R";
type Instruction = Left | Right;

type Node = { name: string; left: string; right: string };

type Map = [Instruction[], Node[]];

const parseInstructions = (line: string): Instruction[] =>
  line.split("").map((x) => x as Instruction);

const parseNode = (line: string): Node => ({
  name: line.substring(0, 3),
  left: line.substring(7, 10),
  right: line.substring(12, 15),
});

const parseInput = (input: string[]): Map => [
  parseInstructions(input[0]),
  input.slice(2).map(parseNode),
];

// CALCULATIONS

const instructionToAccessor = (instruction: Instruction): keyof Node => {
  switch (instruction) {
    case "L":
      return "left";
    case "R":
      return "right";
  }
};

const findNextNode = (
  nodes: Node[],
  currentNode: String,
  instruction: Instruction
): string =>
  nodes.find(({ name }) => name === currentNode)[
    instructionToAccessor(instruction)
  ];

const rotateInstuctions = (list: Instruction[]): Instruction[] =>
  list.slice(1).concat([list[0]]);

// Node has limits on recursion depth and does not support tail call optimisation 😔
const countUntilZzz = (_map: Map, _currentNode: string): number => {
  let [instructions, nodes] = _map;
  let currentNode = _currentNode;
  let count = 0;

  while (currentNode != "ZZZ") {
    currentNode = findNextNode(nodes, currentNode, instructions[0]);
    instructions = rotateInstuctions(instructions);
    count += 1;
  }
  return count;
};

const calculate = (input: Map): number => countUntilZzz(input, "AAA");

// PART 2

type Loop = { length: bigint; zIndex: bigint; loopStart: bigint };
type Name = string;

const countLoopLength = (
  [instructions, nodes]: Map,
  initialNode: string
): Loop => {
  let instr = 0;
  let node = initialNode;
  let count = 0;
  let z: number[] = [];
  let visited: Record<Name, number>[] = instructions.map(() => ({}));
  do {
    if (node[2] === "Z") z.push(count);
    visited[instr][node] = count;
    node = findNextNode(nodes, node, instructions[instr]);
    instr = (instr + 1) % instructions.length;
    count += 1;
  } while (typeof visited[instr][node] === "undefined");
  assert(z.length === 1);
  return {
    length: BigInt(count - visited[instr][node]),
    zIndex: BigInt(z[0]),
    loopStart: BigInt(visited[instr][node]),
  };
};

assert.deepStrictEqual(
  countLoopLength(
    [
      ["L"],
      [
        { name: "000", left: "111", right: "000" },
        { name: "111", left: "222", right: "000" },
        { name: "222", left: "33Z", right: "000" },
        { name: "33Z", left: "444", right: "000" },
        { name: "444", left: "111", right: "000" },
      ],
    ],
    "000"
  ),
  {
    length: 4n,
    zIndex: 3n,
    loopStart: 1n,
  }
);

// https://stackoverflow.com/a/17445322
const gcd = (a: bigint, b: bigint) => {
  if (a < 0) a = -a;
  if (b < 0) b = -b;
  if (b > a) {
    var temp = a;
    a = b;
    b = temp;
  }
  while (true) {
    if (b == 0n) return a;
    a %= b;
    if (a == 0n) return b;
    b %= a;
  }
};

const findPairMatch = (a: Loop, b: Loop): Loop => {
  const combinedLoopLength = (a.length * b.length) / gcd(a.length, b.length);

  let i: bigint = a.zIndex;
  while ((i - b.loopStart) % b.length !== b.zIndex - b.loopStart) {
    i += a.length;
  }

  return {
    length: combinedLoopLength,
    zIndex: i,
    loopStart: 0n,
  };
};

assert.deepStrictEqual(
  findPairMatch(
    { length: 3n, zIndex: 2n, loopStart: 1n },
    { length: 2n, zIndex: 3n, loopStart: 3n }
  ),
  {
    length: 6n,
    zIndex: 5n,
    loopStart: 0n,
  }
);

const calculate2 = (input: Map): bigint =>
  input[1]
    .map(({ name }) => name)
    .filter((name) => name.endsWith("A"))
    .map((name) => countLoopLength(input, name))
    .reduce(findPairMatch).zIndex;

const input = parseInput(getInput());
const part1 = calculate(input);
console.log("Part 1");
console.log(part1);
const part2 = calculate2(input);
console.log("Part 2");
console.log(part2.toString());
assert.equal(part2, 16563603485021n);
