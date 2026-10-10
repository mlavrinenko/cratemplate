#import "@local/mindtape:0.2.0": *
#show: task.with(
  title: "Make tests/it/main.rs the template's default integration test layout",
  priority: framework("ice", confidence: 0.8, ease: 7.0, impact: 5.0),
  difficulty: 2,
  estimate: (files: 8),
  status: proposed(2026, 10, 11),
)

= Summary
Cargo builds one executable per file in `tests/`, and each one links every dependency again. The template ships one test file, `template/tests/cli.rs`, so a generated bin starts with one integration binary, but the layout invites the next: the first `tests/foo.rs` a user adds is a second binary, and the tenth is a tenth. Ship `tests/it/main.rs` as the default instead, so the whole suite stays one binary from the first commit.

Measured 2026-10-11: mindtape's 74 test files gave `target/debug/deps` 263 executables averaging 298 MB, 80 GB in all. `just cover` builds the whole set a second time, instrumented: 51 GB in one worktree, and the disk filled. canibump's 7 test files built 28 binaries of about 37 MB each with full debug info. Debug info size is handled host-wide in `~/.nix` (task `shrink-rust-dev-builds-host-wide-with-line-table-debug-info-and-weekly-unit-cleanup`). This task is the generator's half: every crate made from the template starts right, and each sibling repo's own task (blustroke, canibump, ejectest, kimmable, linecop, mmz, nix-why-build, outdatty, speconaut, vibeschema) links the files it has today.

Cargo autodiscovers `tests/it/main.rs` as the test target `it`; sibling modules are declared in it with `mod <file>;`. Shared helpers go in `tests/it/common/mod.rs`, declared once in `main.rs` as `mod common;`, and a test file reaches it with `use crate::common::...`. `include_str!`, `include_bytes!` and `#[path]` are relative to the source file, so they change on a move; `env!("CARGO_MANIFEST_DIR")` paths do not.

A lib has no `tests/` today (`cargo-generate.toml` drops `tests/cli.rs` for `crate_kind == "lib"`). The pick is to keep it that way, so a lib does not start with an empty binary, and to have its docs name the layout for the first integration test. If you would rather give a lib `tests/it/main.rs` too, it needs a body that compiles with no module (an empty file does).


= Scope
- `template/tests/cli.rs`: `git mv` to `template/tests/it/cli.rs`; add `template/tests/it/main.rs` containing `mod cli;`. The file has no `mod common`, `include_str!` or `#[path]`, so it needs no other edit.
- `template/cargo-generate.toml:61-64`: the lib branch's `ignore = ["src/main.rs", "tests/cli.rs", ...]` becomes `"tests/it/cli.rs"` plus `"tests/it/main.rs"`, and the comment above it names the new paths. A bin keeps both.
- `template/AGENTS.md:12,15` and `template/CONTRIBUTING.md:41-46`: the prose says `tests/` and `see tests/cli.rs`. It now says `tests/it/` is the one integration binary, a new file goes in as `tests/it/<name>.rs` plus `mod <name>;` in `tests/it/main.rs`, and why (one executable instead of one per file). The lib text says the same for its first integration test.
- Already correct and left alone: `template/.mmz/config.yaml:33` (`tests/**`), `template/Justfile:162` (`--exclude 'tests/**'`) and `:188` (`find src tests`), and `template/Justfile:136` and `template/CONTRIBUTING.md:86,145`, all of which cover `tests/it/`. `template/.config/nextest.toml`, `template/.cargo/mutants.toml`, `template/outdatty.yaml` and `template/Cargo.toml` name no test file and carry no `[[test]]` entry. Re-run `grep -rn "tests/\|cli.rs" --exclude-dir=target --exclude-dir=.git template` to confirm.
- `just validate bin` and `just validate lib` both pass: the bin's `just count-tests` total is unchanged, `cargo test --no-run` in a generated bin shows one integration executable, and a generated lib has none.
- `CHANGELOG.md`: an Unreleased entry for the new default layout.

