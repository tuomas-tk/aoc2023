import fs from "node:fs";
import assert, { deepStrictEqual, equal } from "node:assert";

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
  console.log(initialNode, count, z, visited[instr][node]);
  assert(z.length === 1);
  return {
    length: BigInt(count - visited[instr][node]),
    zIndex: BigInt(z[0]),
    loopStart: BigInt(visited[instr][node]),
  };
};

deepStrictEqual(
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

const countUntilAllEndZ = (_map: Map, _currentNodes: string[]): number => {
  let [instructions, nodes] = _map;
  let currentNodes = _currentNodes;
  let count = 0;

  while (currentNodes.some((name) => name[2] != "Z")) {
    if (count % 100000 === 0) console.log(count);
    currentNodes = currentNodes.map((n) =>
      findNextNode(nodes, n, instructions[0])
    );
    instructions = rotateInstuctions(instructions);
    count += 1;
  }
  return count;
};

const findMatch = (loops: Loop[]): bigint => {
  const first = loops[0];
  const rest = loops.slice(1);
  let i = first.zIndex;
  console.log(rest);
  while (
    rest.some(
      ({ length, zIndex, loopStart }) =>
        (i - loopStart) % length !== zIndex - loopStart
    )
  ) {
    i = i + first.length;
  }
  return i;
};

const findPairMatch = (loopA: Loop, loopB: Loop): Loop => {
  const theGcd = gcd(loopA.length, loopB.length);
  const combinedLoopLength = (loopA.length * loopB.length) / theGcd;
  let i: bigint = loopA.zIndex;
  while (
    (i - loopB.loopStart) % loopB.length !==
    loopB.zIndex - loopB.loopStart
  ) {
    // console.log(i);
    //if (i > combinedLoopLength + loopA.loopStart + loopB.loopStart + 2n)
    //  throw "No solution found";
    i += loopA.length;
  }

  return {
    length: combinedLoopLength,
    zIndex: i,
    loopStart: 0n,
  };
};
/*
l=4, 2
gcd = 2
ll = 8

00
11
20
31
00
11
20
31
*/

deepStrictEqual(
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

const calculate2 = (input: Map): bigint => {
  const starts = input[1]
    .map(({ name }) => name)
    .filter((name) => name.endsWith("A"));
  const loops = starts.map((name) => countLoopLength(input, name));
  console.log(loops);
  // return findMatch(loops);
  // console.warn(findMatch(loops.slice(0, 3)));
  console.log(loops.map((a) => loops.map((b) => findPairMatch(a, b))));

  return loops
    .sort((a, b) => (a.loopStart > b.loopStart ? -1 : 1))
    .reduce((prev, curr) => {
      console.log("reduce", prev, curr);
      return findPairMatch(prev, curr);
    }).zIndex;
};

const input = parseInput(getInput());
console.log(input);
console.log("Part 1");
// console.log(calculate(input));
console.log("Part 2");
console.log(calculate2(input));
// 138090455 too low
// 26388042297736675409279 too high

// https://stackoverflow.com/a/17445322
function gcd(a, b) {
  if (a < 0) a = -a;
  if (b < 0) b = -b;
  if (b > a) {
    var temp = a;
    a = b;
    b = temp;
  }
  while (true) {
    if (b == 0) return a;
    a %= b;
    if (a == 0) return b;
    b %= a;
  }
}
