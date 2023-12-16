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

type Loop = { length: number; zIndex: number };
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
  return { length: count - visited[instr][node] + 1, zIndex: z[0] };
};

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

const findMatch = (loops: Loop[]): number => {
  const first = loops[0];
  const rest = loops.slice(1);
  let i = first.zIndex;
  console.log(rest);
  while (rest.some(({ length, zIndex }) => i % length !== zIndex)) {
    i += first.length;
  }
  return i;
};

const findPairMatch = (loopA: Loop, loopB: Loop): Loop => {
  const zIndexDiff = loopB.zIndex - loopA.zIndex;
  const loopDiff = loopB.length - loopA.length;

  const combinedLoopLength = loopA.length * loopB.length;
  let i = loopA.zIndex;
  while (i % loopB.length !== loopB.zIndex) {
    // console.log(i);
    if (i > combinedLoopLength) throw "No solution found";
    i += loopA.length;
  }

  return {
    length: combinedLoopLength,
    zIndex: i,
  };
};

const calculate2 = (input: Map): number => {
  const starts = input[1]
    .map(({ name }) => name)
    .filter((name) => name.endsWith("A"));
  const loops = starts.map((name) => countLoopLength(input, name));
  console.log(loops);
  // return findMatch(loops);
  console.warn(findMatch(loops.slice(0, 3)));
  console.log(
    loops.reduce((prev, curr) => {
      console.log("reduce", prev, curr);
      return findPairMatch(prev, curr);
    })
  );
  return 0;
};

const input = parseInput(getInput());
console.log(input);
console.log("Part 1");
// console.log(calculate(input));
console.log("Part 2");
console.log(calculate2(input));
// 138090455 too low
