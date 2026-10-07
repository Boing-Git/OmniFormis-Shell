/**
 * Renders Markdown that this repository authored and this build converted.
 *
 * The HTML is trusted because it is produced at build time from files in the
 * repository, never from user input or a remote source. If that ever changes,
 * this is the boundary that has to change with it.
 */
export function Prose({ html }: { html: string }) {
  return <div className="prose" dangerouslySetInnerHTML={{ __html: html }} />
}
