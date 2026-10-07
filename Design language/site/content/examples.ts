import { readFile, readdir } from 'node:fs/promises'
import path from 'node:path'
import { examplesRoot } from './paths'

/**
 * Components that have no playground example, with the reason.
 *
 * This list is not a convenience for skipping work. `check-site.mjs` asserts it
 * is exactly the set of conformant components lacking an example file, so a new
 * component that arrives without a demo fails the gate until someone either
 * writes the demo or records why it cannot exist.
 */
export const componentsWithoutExample: Record<string, string> = {
  Material3Provider:
    'The provider has no isolated demonstration: it renders no markup of its own, ' +
    'and every component on this site is already inside one. The theme controls in ' +
    'the header are its live demonstration.',
}

export function exampleFileName(component: string): string {
  return `${component}.example.tsx`
}

export function exampleExportName(component: string): string {
  return `${component}Example`
}

export async function listExampleComponents(): Promise<string[]> {
  const entries = await readdir(examplesRoot)
  return entries
    .filter((entry) => entry.endsWith('.example.tsx'))
    .map((entry) => entry.replace('.example.tsx', ''))
    .sort()
}

export async function hasExample(component: string): Promise<boolean> {
  return (await listExampleComponents()).includes(component)
}

/**
 * The example's real source, shown verbatim on the component page.
 *
 * It is displayed rather than a hand-written snippet so the code a visitor
 * copies is the code that produced the demo directly above it. A snippet that
 * cannot drift is worth more than one that reads a little tidier.
 */
export async function readExampleSource(component: string): Promise<string> {
  const source = await readFile(
    path.join(examplesRoot, exampleFileName(component)),
    'utf8',
  )
  return source.trimEnd()
}
