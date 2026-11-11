# The roots jscpd and `just _lcov-stale-reason` scan, shared so a workspace, a
# bin and a lib cannot drift apart between the two callers. A workspace keeps
# its members under crates/; a root crate keeps its sources in src/ and its
# integration tests in tests/.
rust_roots := if path_exists("crates") == "true" { "crates" } else { "src tests" }
