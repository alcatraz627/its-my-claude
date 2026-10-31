# README

A README is the first page a new reader or a review tool opens. Follow the
shape below and derive every word from the project's own facts. Copying
another README's text is the failure.

## Gather first

| Source | What to take from it |
|---|---|
| `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod` | Name, description, version, license, scripts, runtime version |
| CI config (`.github/workflows/`, `.gitlab-ci.yml`) | Which CI badge to use, the test command |
| `Dockerfile`, `Makefile`, `.env.example` | Setup and run commands |
| Existing `docs/` and other `.md` files | The documentation index: path, title, one-line summary each |
| Recent commits and tags | Version, what the project is currently about |

With no manifest, say so and use what the repo shows. With no git remote, skip
the badges that need one (CI status, package registry, issues).

If a README already exists, read it and ask whether to replace it or revise
it before drafting.

## The sections, in order

1. **Title and badges.** The project name, a one-line identity, and
   shields.io badges only for data that exists (runtime, version, license,
   CI). Never a badge with a placeholder value.
2. **What is this?** Two paragraphs at most: what it does for its user, then
   the one structural idea that explains it.
3. **Architecture.** One fenced box-drawing diagram of the real data flow
   (see `diagrams`), with the key invariant as a caption line ("one writer
   per queue").
4. **Quick start.** Commands that run, each with a trailing comment.
5. **By what you came to do.** A two-column table routing intents to paths
   or commands. It replaces long orientation prose.
6. **Documentation.** The docs index as a table, and the reading order.
7. **How work happens here.** Three sentences: how to propose a change, what
   must pass before merge, where decisions are recorded.
8. **Repo structure.** A fenced tree with one-phrase annotations.
9. **Contributing and license.** Link `CONTRIBUTING.md` and `LICENSE` when
   they exist.

Small projects drop sections that have nothing in them. A 200-line CLI does
not need an architecture diagram.

## Badges

```markdown
![License](https://img.shields.io/badge/license-MIT-green)
![Node](https://img.shields.io/badge/node-%3E%3D20-339933)
![CI](https://github.com/<owner>/<repo>/actions/workflows/ci.yml/badge.svg)
![npm](https://img.shields.io/npm/v/<package-name>)
```

## Callouts

GitHub callouts, used sparingly and by meaning. Budget: about one of each per
README.

| Callout | Use for |
|---|---|
| `> [!NOTE]` | The one clarification a skimmer must not miss |
| `> [!IMPORTANT]` | An invariant that corrupts data if broken |
| `> [!TIP]` | The recommended reading or usage order |
| `> [!WARNING]` | Stale material or a known trap |

A callout inside `<details>` renders as a plain quote. See
`github-markdown.md`.

## Cover image (optional)

A cover image is an SVG file in the repo (`assets/cover.svg`) referenced with
`<img src="assets/cover.svg" alt="..." width="128">`. Never paste raw `<svg>`
into the README: most renderers outside github.com strip it and show the text
nodes as loose words. To draw one, use `svg`.

## The bar

Every claim is checkable. Badges match real data, every relative link points
to a file that exists, and every quick-start command runs. In the sandbox,
check each relative link against the repo tree when the repo is available.
