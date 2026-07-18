# Delivery Issue Log -- delivery-002

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-016 | [HIGH] | Pre-existing test failure: test_s9_brand_contains_aid_this_machine expects 'AID' in brand div; brand HTML contains only '<strong>Home</strong>', not '<strong>AID ... this machine</strong>'; blocks build gate | Resolved (NOT a work-017 regression — validated: fails at the work-017 base; brand was "Home" pre-work-017; work-017 touched neither the brand nor test_s9). Per user decision to keep the "Home" brand, the stale test was updated (test_s9_brand_present, asserts "Home") — suite green (174/174 in test_cli_home_html.py). |
