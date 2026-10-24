# Bounded Codex guard proposal

Delivery-003 remains open. The complete recipe candidate is source `67a7882c` and
resync `34f54b726`; final local validation is running against that identity.

The latest default-profile focused batch was judged 3/3, but its actual traces show
two incomplete routes and one forbidden retry plus a record/display mismatch.
The same-source Astra comparison also failed. Neither comparison establishes a
missing source rule, a low-effort cause or a categorical host instruction conflict.
Evidence and limits are in `delivery-003-gate.md` and
`.aid/.temp/runner-codex-checks/delivery-003-host-contract-notes.md`.

## Decision required

Q183 approved a Claude Code hook. Q189 selected more wording rounds rather than
hook investment. Adding a Codex guard now therefore needs a new owner decision;
the existing permission to correct source defects does not settle that change.

Authorize a bounded Codex-native guard feasibility pass, followed by implementation
only where an actual host test demonstrates the required behavior. This is a scope
decision, not an exception to the existing thirty-run acceptance requirement.

## Proposed work

1. In a disposable project using the exact Linux CLI and default model profile,
   test native hook loading, trust, event payloads and failure behavior. Test an
   explicit pre-tool denial and end-of-turn continuation separately. Do not change
   user configuration, bypass trust or infer enforcement from a feature flag.
2. Determine whether supported events can prevent an attempted record creation
   without its required folder, prevent continuation after a failed record write,
   and detect a displayed question that differs materially from its saved record.
   Report unsupported properties explicitly. No hook may create missing records,
   repair a failed write, rewrite tool arguments or silently retry for the agent.
3. Implement only demonstrated checks through namespaced runtime scripts and
   lifecycle-managed installation/removal, with the existing content-isolation
   contract preserved. An unsupported property stops that part of the proposal;
   it is not replaced by extra test-runner coaching.
4. Independently verify the change, resync, and rerun the unchanged strict ten
   samples three times each. Preserve every original event and visible message;
   a later correction does not erase an earlier violation. Repeat affected final
   validation on the resulting candidate before any maintainer push.

## Capability limits

The [official hooks contract](https://learn.chatgpt.com/docs/hooks) describes
pre-tool denial for supported local tools. Stop requests continuation; it does not
establish that an earlier message was withheld. Hook errors can leave calls
unblocked, some tool paths opt out, and transcript format is not a stable API.
Consequently this proposal promises a measured feasibility result, not complete
enforcement or compatibility with the existing Claude message-withdrawal behavior.

If declined, retain the current source and failed behavioral findings and leave
delivery-003 open. Neither choice marks the gate passed or authorizes push/merge.
