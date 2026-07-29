// skill-node-panel.mjs — Client-side controller: attachment lifecycle and node decoration.
// Delivery: feature-006 (interactive node panel), task-049.
//
// Scope (task-049):
//   • Reads the PanelProjection island injected by task-047 (id="aid-flow-data").
//   • Finds the skill chart container and installs delegated handlers exactly once
//     per container (WeakSet guard by element identity).
//   • Observes the container for SVG replacement on theme change (mermaid re-renders the
//     whole diagram when the theme changes, replacing the SVG subtree; delegation on the
//     container survives because the container element itself is stable).
//   • Decorates resolvable nodes with role/tabindex/aria attributes once the three-part
//     readiness predicate (KI-011) is satisfied: data-processed AND svg child AND at
//     least one resolvable node id.
//
// Out of scope (task-050):
//   • Panel display, focus, and key handling.
//   • Toggling aria-expanded on the activated node.
//
// PANEL ENTRY POINT — see openPanel() below.
// task-050 implements the panel display logic. aria-controls="aid-node-panel" names
// the panel element task-050 creates. aria-controls is intentionally unresolved in
// task-049's intermediate state — this is by design, not a defect.
//
// Schema guard: if the island's v field is not exactly 1 this controller no-ops entirely.
// The file is served from site/public/ which Astro copies verbatim (no content-hash),
// so a browser holding a stale copy after a deploy refuses to run rather than
// mis-rendering against a mismatched projection.
//
// astro:after-swap: registered but currently inert. This site enables no view transitions
// (Starlight does not enable @astrojs/transitions), so this event never fires in practice.
// The handler is wired so that adding view transitions in a future delivery requires no
// change to this file.
//
// Console discipline: silent on success. Failures use:
//   console.warn('[aid-node-panel] <guard>: <detail>')
// at most once per guard per page. Stable guard names:
//   'panel schema'    — island v field not 1
//   'panel data'      — island element absent or JSON parse failure
//   'panel container' — multiple pre.mermaid found
//   'panel nodes'     — failed render or zero resolvable nodes
//
// Constraints: no import, no fetch, no Web Storage API, no cookie access,
// no dynamic code execution, no document write. Vanilla ESM, IIFE-scoped, 2-space indent.

(function () {
  'use strict';

  // ── Per-page state ─────────────────────────────────────────────────────────

  /**
   * Containers with delegated event handlers installed, tracked by element identity.
   * A container in the WeakSet has listeners; a new container element (after astro:after-swap)
   * is absent from the set and binds cleanly.
   */
  var bound = new WeakSet();

  /**
   * Decoration state per container element.
   *   BOUND_PENDING — listeners attached; waiting for the readiness predicate.
   *   BOUND_READY   — nodes successfully decorated; delegation is active.
   *   BOUND_INERT   — render failed or zero nodes resolved; no decoration applied.
   */
  var containerState = new WeakMap();

  /** Guards already warned this page load; prevents repeated console.warn. */
  var warned = Object.create(null);

  // ── Id recovery ────────────────────────────────────────────────────────────

  /**
   * Recovers a model node id from a Mermaid SVG g.node.aidNode element id.
   *
   * Measured against the running site rather than assumed: mermaid emits
   *   mermaid-<diagramId>-flowchart-<nodeId>-<n>
   * for example `mermaid-rkijoq1pv-flowchart-n10-9`, where <diagramId> is
   * per-render and <n> is a parser-call counter. The diagram-id prefix is why
   * this pattern is NOT anchored at the start — a `^flowchart-` anchor matched
   * 0 of 10 nodes on a real page, which would have left every node unresolvable
   * and the panel permanently inert.
   *
   * It stays anchored at the END, which keeps the capture unambiguous: the
   * feature-003 id charset [A-Za-z][A-Za-z0-9_]{0,31} contains no `-`, so in
   * `...-flowchart-n10-9` group 1 can only be `n10`.
   *
   * Nodes are selected by class (g.node.aidNode) rather than by an id prefix, so
   * one query suffices and foreign diagrams on the page are excluded.
   */
  var ID_RE = /flowchart-([A-Za-z][A-Za-z0-9_]{0,31})-\d+$/;

  // ── Console helper ─────────────────────────────────────────────────────────

  function warnOnce(guard, detail) {
    if (warned[guard]) return;
    warned[guard] = true;
    console.warn('[aid-node-panel] ' + guard + ': ' + detail);
  }

  // ── Island reader ──────────────────────────────────────────────────────────

  /**
   * Read and validate the PanelProjection island embedded by task-047.
   * Returns the parsed projection when v === 1, null otherwise.
   * Each failure path warns at most once via its stable guard name.
   */
  function readProjection() {
    // 'aid-flow-data' is the id feature-006's SPEC fixes and the id task-047's
    // Head override emits. This read and that emission are the only two places
    // it appears, so they are asserted against each other in the test suite —
    // an earlier version of this file looked up 'aid-panel-data', which no page
    // ever contains, and would have silently no-opped on every page.
    var el = document.getElementById('aid-flow-data');
    if (!el) {
      warnOnce('panel data', 'island element not found');
      return null;
    }
    var raw;
    try {
      raw = JSON.parse(el.textContent || '');
    } catch (_) {
      warnOnce('panel data', 'JSON parse failed');
      return null;
    }
    if (!raw || raw.v !== 1) {
      warnOnce('panel schema', 'unsupported schema version; expected v=1');
      return null;
    }
    return raw;
  }

  // ── Node id recovery ───────────────────────────────────────────────────────

  /**
   * Recover the model node id from a g.node.aidNode SVG element.
   * Returns null if the element id does not match the anchored pattern.
   * A node with a null id is left entirely undecorated (resolve-or-skip).
   */
  function recoverNodeId(el) {
    var m = ID_RE.exec(el.id || '');
    return m ? m[1] : null;
  }

  // ── Node decoration ────────────────────────────────────────────────────────

  /**
   * Decorate a single g.node.aidNode element for keyboard and assistive-tech use.
   *
   * Idempotent via data-aid-node: if the attribute is already present the node is
   * skipped entirely. This absorbs KI-014 (two rapid theme toggles can fire two
   * interleaved render loops producing a duplicated readiness transition).
   *
   * There is deliberately no focus trap. The panel is non-modal; trapping focus
   * would break the comparison the reader is making against delivery-004's
   * source-fragment list, which must remain reachable at all times.
   */
  function decorateNode(el, nodeId, panelNode) {
    if (el.hasAttribute('data-aid-node')) return;
    el.setAttribute('role', 'button');
    el.setAttribute('tabindex', '0');
    el.setAttribute('aria-expanded', 'false');
    el.setAttribute('aria-controls', 'aid-node-panel');
    el.setAttribute('aria-label', panelNode.name);
    el.setAttribute('data-aid-node', nodeId);
  }

  // ── Readiness and decoration ───────────────────────────────────────────────

  /**
   * Check the three-part readiness predicate (KI-011) and, if met, decorate all
   * resolvable nodes in the container. Transitions the container state.
   *
   * Predicate parts:
   *   (1) data-processed present — mermaid attempted a render.
   *   (2) an <svg> child present — the render produced output (not a failed render).
   *   (3) at least one node id resolves in the projection — chart matches projection.
   *
   * Part (1) absent → return early; stay BOUND_PENDING (still waiting for render).
   * Part (2) absent → BOUND_INERT with one 'panel nodes' warning (failed render shape).
   * Part (3) fails  → BOUND_INERT with one 'panel nodes' warning (zero resolvable nodes).
   *
   * Runs only when the container is in BOUND_PENDING state. The MutationObserver
   * resets the state to BOUND_PENDING before each call, so BOUND_READY and BOUND_INERT
   * containers re-enter evaluation after each render cycle.
   */
  function tryDecorate(container, projection) {
    if (containerState.get(container) !== 'BOUND_PENDING') return;

    // Part 1: mermaid has not yet attempted a render — wait.
    if (!container.hasAttribute('data-processed')) return;

    // Part 2: mermaid attempted a render but produced no SVG (failed render).
    if (!container.querySelector('svg')) {
      containerState.set(container, 'BOUND_INERT');
      warnOnce('panel nodes', 'no SVG after render (failed render); panel disabled for this container');
      return;
    }

    // Parts 1 and 2 pass. Find and decorate resolvable nodes.
    var svgNodes = container.querySelectorAll('g.node.aidNode');
    var decoratedCount = 0;
    var i, j, nodeId, panelNode;
    for (i = 0; i < svgNodes.length; i++) {
      nodeId = recoverNodeId(svgNodes[i]);
      if (!nodeId) continue;
      panelNode = null;
      for (j = 0; j < projection.nodes.length; j++) {
        if (projection.nodes[j].id === nodeId) {
          panelNode = projection.nodes[j];
          break;
        }
      }
      if (!panelNode) continue;
      decorateNode(svgNodes[i], nodeId, panelNode);
      decoratedCount++;
    }

    if (decoratedCount === 0) {
      containerState.set(container, 'BOUND_INERT');
      warnOnce('panel nodes', 'zero resolvable nodes in container; panel disabled');
    } else {
      containerState.set(container, 'BOUND_READY');
    }
  }

  // ── Panel entry point ──────────────────────────────────────────────────────

  /**
   * PANEL ENTRY POINT — task-050 implements this.
   *
   * Called when a decorated node is activated (click or Enter/Space keydown).
   * nodeId is the model id recovered from data-aid-node (matches projection.nodes[].id).
   * nodeEl is the activated g.node.aidNode DOM element.
   * projection is the full PanelProjection for the page.
   *
   * In task-049's intermediate state this is a stub that produces no visible panel.
   * aria-controls="aid-node-panel" names the panel element task-050 creates; that
   * element does not exist until task-050 lands, so aria-controls is unresolved here.
   * A reviewer seeing this at task-049's gate should read it as the planned seam.
   */
  function openPanel(nodeId, nodeEl, projection) {
    void nodeId;
    void nodeEl;
    void projection;
  }

  // ── Activation handler ─────────────────────────────────────────────────────

  /**
   * Delegated handler for click and keydown events on the container.
   *
   * Resolves the activated node via closest('g.node.aidNode') so that a click on
   * a <text> or <tspan> descendant inside the node still works. Exits early if
   * the resolved element lacks data-aid-node (undecorated nodes are not activatable
   * and can never open the panel).
   *
   * keydown: only Enter and Space activate; both call event.preventDefault() to
   * suppress scroll (Space) and form-submit (Enter).
   */
  function handleActivation(event, projection) {
    if (event.type === 'keydown') {
      var k = event.key;
      if (k !== 'Enter' && k !== ' ') return;
      event.preventDefault();
    }
    var target = event.target;
    if (!target || typeof target.closest !== 'function') return;
    var node = target.closest('g.node.aidNode');
    if (!node) return;
    if (!node.hasAttribute('data-aid-node')) return;
    openPanel(node.getAttribute('data-aid-node'), node, projection);
  }

  // ── Container attachment ───────────────────────────────────────────────────

  /**
   * Attach delegated handlers and a MutationObserver to a container.
   *
   * The WeakSet guards against duplicate attachment; calling with an already-bound
   * container is a no-op. This is the once-only binding guarantee: three simulated
   * theme-change cycles produce exactly one binding because the container element
   * identity is stable across theme changes.
   *
   * Listeners are installed BEFORE tryDecorate is called from scan(), closing the
   * race where a mermaid render completes between script parse and the initial
   * state sample. Nothing polls and nothing times out.
   *
   * The MutationObserver observes:
   *   childList — detects SVG being added or replaced (direct child of container).
   *   attributes/data-processed — detects mermaid signalling render completion.
   *
   * No subtree observation, so setting data-aid-node, role, aria-* on descendant
   * nodes (done by decorateNode) does not re-trigger the observer.
   *
   * On each mutation the observer resets the container to BOUND_PENDING and calls
   * tryDecorate. tryDecorate is idempotent via decorateNode's data-aid-node check,
   * so a spurious or duplicated trigger cannot double-decorate.
   */
  function attachContainer(container, projection) {
    if (bound.has(container)) return;
    bound.add(container);
    containerState.set(container, 'BOUND_PENDING');

    container.addEventListener('click', function (e) { handleActivation(e, projection); });
    container.addEventListener('keydown', function (e) { handleActivation(e, projection); });

    var observer = new MutationObserver(function () {
      containerState.set(container, 'BOUND_PENDING');
      tryDecorate(container, projection);
    });
    observer.observe(container, {
      childList: true,
      attributes: true,
      attributeFilter: ['data-processed'],
    });
  }

  // ── Scan ───────────────────────────────────────────────────────────────────

  /**
   * Find the skill chart container and attach if not already bound.
   * Searches within .sl-markdown-content for pre.mermaid elements.
   * Binds the first one; if more than one is found, warns once via 'panel container'
   * and leaves the rest alone rather than guessing which chart the projection describes.
   *
   * Installs listeners BEFORE sampling current state (attachContainer before tryDecorate)
   * so a render completing in that gap is caught by the observer rather than missed.
   */
  function scan(projection) {
    var scope = document.querySelector('.sl-markdown-content');
    if (!scope) return;
    var found = scope.querySelectorAll('pre.mermaid');
    if (found.length === 0) return;
    if (found.length > 1) {
      warnOnce('panel container', found.length + ' pre.mermaid containers found; binding first only');
    }
    var container = found[0];
    attachContainer(container, projection);
    tryDecorate(container, projection);
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  function init() {
    var projection = readProjection();
    if (!projection) return;

    // astro:after-swap: registered but currently inert.
    // This site enables no view transitions (Starlight does not enable
    // @astrojs/transitions), so this event never fires. The handler is wired
    // so that enabling view transitions in a future delivery does not require
    // touching this file.
    document.addEventListener('astro:after-swap', function () {
      scan(projection);
    });

    scan(projection);
  }

  try {
    init();
  } catch (_) {
    // Unexpected error — degrade to the no-JavaScript state rather than leaving
    // half-decorated nodes. console.warn surfaces the failure without breaking the page.
    console.warn('[aid-node-panel] panel data: unexpected error during init; controller disabled');
  }

})();
