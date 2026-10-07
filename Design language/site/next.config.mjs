import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const repoRoot = path.resolve(here, '..')

// The site is a consumer of the published package (ADR 0028). It resolves the
// library through the export map only, but it does read three repository
// sources at build time — the component inventory, the component Markdown, and
// the playground examples — all of which live above this directory. Turbopack
// is pointed at the repository root so those imports and reads resolve instead
// of being treated as an escape from the project root.
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  reactStrictMode: true,
  turbopack: {
    root: repoRoot,
  },
  images: {
    unoptimized: true,
  },
  // Static export cannot negotiate a trailing slash at request time, so pin it
  // and emit `<route>/index.html` for every route.
  trailingSlash: true,
}

export default nextConfig
