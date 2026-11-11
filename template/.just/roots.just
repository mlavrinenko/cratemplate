# The roots jscpd and `just _lcov-stale-reason` scan, shared so a workspace, a
# bin and a lib cannot drift apart between the two callers. A workspace keeps
# its members under crates/; a root crate keeps its sources in src/ and its
# integration tests in tests/. A generated lib has no tests/ (cargo-generate
# leaves an empty directory and a clone drops it), and jscpd exits 1 on a
# missing path, so tests joins the list only when it exists.
rust_roots := if path_exists("crates") == "true" {
    "crates"
} else if path_exists("tests") == "true" {
    "src tests"
} else {
    "src"
}
