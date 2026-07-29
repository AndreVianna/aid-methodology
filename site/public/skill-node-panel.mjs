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
// Panel half (task-050):
//   • Panel display, focus and key handling — see openPanel() / closePanel().
//   • Toggling aria-expanded on the activated node.
//
// The panel is a DISCLOSURE, not a dialog: no focus trap, no overlay, no scroll
// lock. Trapping focus would cut the reader off from delivery-004's
// `## Source fragments` list further down the page, which is the comparison this
// panel exists to support. Opening moves focus to the panel; Escape and the close
// button return it to the node that opened it; Tab continues into the page.
//
// Content is written with textContent throughout and never innerHTML. The fragment
// is provenance.excerpt byte-for-byte, and re-parsing it as markup is precisely the
// reinterpretation this feature exists to avoid — the same reason it carries no
// syntax highlighting.
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

  /**
   * The panel's element id.
   *
   * Declared once and used both when creating the panel and when writing each
   * node's `aria-controls`, so the reference cannot drift from its target. Stating
   * it twice is exactly how this delivery's two shipped defects happened — a node-id
   * pattern and an island id, each written independently on two sides of a seam.
   */
  var PANEL_ID = 'aid-node-panel';

  // ── Panel state ─────────────────────────────────────────────────────────────

  /**
   * The shared panel element, created on first panel open. Null until first activation.
   * One panel per page — the controller binds to the first pre.mermaid container only.
   */
  var panelEl = null;

  /**
   * The container element the panel belongs to. Set in attachContainer.
   * Used to: (a) insert the panel as next sibling on first open;
   * (b) re-resolve the open node by data-aid-node across re-renders.
   */
  var panelContainerRef = null;

  /** Model id of the currently open node, or null when the panel is closed. */
  var openNodeId = null;

  /**
   * DOM element of the currently open node, or null. May be stale after a
   * re-render; always re-resolved via panelContainerRef before use.
   */
  var openNodeEl = null;

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
    el.setAttribute('aria-controls', PANEL_ID);
    // Composed accessible name from projection fields — not scraped from SVG text.
    // Mermaid renders node text as <tspan>s or a <foreignObject>; the computed name
    // would be unreliable and unpunctuated, so we override it with projected data.
    var ariaLabel = 'Step ' + panelNode.order + ': ' + panelNode.name;
    var extra = meaningfulLabel(panelNode.name, panelNode.label);
    if (extra) ariaLabel += ' \u2014 ' + extra;
    if (panelNode.exit !== null) {
      ariaLabel += ' (exit: ' + panelNode.exit.advanceType + ')';
    }
    el.setAttribute('aria-label', ariaLabel);
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
      // Re-apply open state after a re-render replaced the SVG subtree.
      // decorateNode always sets aria-expanded="false"; if a node was open we
      // must re-apply "true" to the newly-created element for the same model id.
      if (openNodeId !== null && panelEl && !panelEl.hidden) {
        var reopenEl = container.querySelector('[data-aid-node="' + openNodeId + '"]');
        if (reopenEl) {
          reopenEl.setAttribute('aria-expanded', 'true');
          openNodeEl = reopenEl;
        } else {
          // The open node no longer exists in the new chart — close without focusing.
          openNodeId = null;
          openNodeEl = null;
          panelEl.hidden = true;
        }
      }
    }
  }

  // ── Panel entry point ──────────────────────────────────────────────────────

  /**
   * Find the projection node for a model id, or null.
   * Linear scan: charts are ~6-20 nodes, so an index would cost more than it saves.
   */
  function findNode(projection, nodeId) {
    for (var i = 0; i < projection.nodes.length; i++) {
      if (projection.nodes[i].id === nodeId) return projection.nodes[i];
    }
    return null;
  }

  /**
   * Create the panel element once per page, in feature-006's Anatomy shape, and
   * insert it directly after the chart container so it reads in document order as
   * belonging to the chart above it.
   *
   * Built with createElement and textContent throughout — never innerHTML. The
   * fragment is `provenance.excerpt` byte-for-byte, and re-parsing it as HTML is
   * exactly the reinterpretation this whole feature exists to avoid. It is also
   * why there is no syntax highlighting here.
   *
   * Class names are fixed by the Anatomy block and are the ones
   * public/skill-node-panel.css styles; a committed guard asserts that stylesheet
   * styles no element outside that set, so a new name here would be unstyled.
   */
  function createPanel(container) {
    var panel = document.createElement('div');
    panel.className = 'aid-node-panel';
    panel.id = PANEL_ID;
    // Focusable programmatically but not in the tab sequence: opening moves focus
    // here, while Tab continues into the page rather than cycling inside a
    // non-modal region.
    panel.setAttribute('tabindex', '-1');
    panel.hidden = true;

    var bar = document.createElement('div');
    bar.className = 'aid-node-panel__bar';

    // h3: semantically under the chart's `## Flow` H2. Starlight builds its table
    // of contents from the markdown at build time, so a DOM-inserted heading
    // cannot pollute it.
    var heading = document.createElement('h3');
    heading.id = PANEL_ID + '-title';

    var order = document.createElement('span');
    order.className = 'aid-node-panel__order';
    var nameCode = document.createElement('code');
    var kind = document.createElement('span');
    kind.className = 'aid-node-panel__kind';
    var exit = document.createElement('span');
    exit.className = 'aid-node-panel__exit';

    heading.appendChild(order);
    heading.appendChild(document.createTextNode(' '));
    heading.appendChild(nameCode);
    heading.appendChild(document.createTextNode(' '));
    heading.appendChild(kind);
    heading.appendChild(document.createTextNode(' '));
    heading.appendChild(exit);

    var close = document.createElement('button');
    close.className = 'aid-node-panel__close';
    close.setAttribute('type', 'button');
    close.setAttribute('aria-label', 'Close step details');
    close.textContent = '\u00d7';
    close.addEventListener('click', function () { closePanel(true); });

    bar.appendChild(heading);
    bar.appendChild(close);

    var label = document.createElement('p');
    label.className = 'aid-node-panel__label';

    var pre = document.createElement('pre');
    pre.className = 'aid-node-panel__fragment';
    var code = document.createElement('code');
    pre.appendChild(code);

    var links = document.createElement('p');
    links.className = 'aid-node-panel__links';

    panel.appendChild(bar);
    panel.appendChild(label);
    panel.appendChild(pre);
    panel.appendChild(links);

    // Escape closes and returns focus to the node that opened the panel. Bound on
    // the panel itself as well as the container, because focus is inside the panel
    // once it opens and the keystroke would otherwise never reach the container.
    panel.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { e.preventDefault(); closePanel(true); }
    });

    if (container.parentNode) {
      container.parentNode.insertBefore(panel, container.nextSibling);
    }
    return panel;
  }

  /** Remove every child of an element without using innerHTML. */
  function clearChildren(el) {
    while (el.firstChild) el.removeChild(el.firstChild);
  }

  /**
   * Build one anchor. Text is set with textContent, so a path containing markup
   * characters cannot inject anything.
   */
  function makeLink(href, text) {
    var a = document.createElement('a');
    a.setAttribute('href', href);
    a.textContent = text;
    return a;
  }

  /**
   * The readable half of a blob URL: `canonical/…/SKILL.md#L275`.
   *
   * feature-006's Anatomy shows the source link's text as the repo-relative path
   * and anchor, not the whole URL — which matches delivery-004's list, where the
   * link reads `[Source: `canonical/…#L275`]`. A full URL as link text is both
   * unreadable and inconsistent with the list this panel is meant to be compared
   * against.
   *
   * Derived by slicing from `canonical/` rather than by stripping a known prefix,
   * so neither the blob base nor the pinned ref is restated here — those live in
   * paths.mjs, and the projection's URLs are built from them.
   */
  function sourceLabel(url) {
    var at = url.indexOf('canonical/');
    return at === -1 ? url : url.slice(at);
  }

  /**
   * The label half of a heading, or '' when the label only repeats the name.
   *
   * Same rule, and the same case-insensitive comparison, as render-mermaid.mjs's
   * nodeLabel and the fragment list's labelPart: 223 of 883 corpus entries have a
   * label identical to the node name, so without this the panel heading reads
   * `INTAKE` twice and the accessible name announces "Step 1: INTAKE — INTAKE".
   */
  function meaningfulLabel(name, label) {
    if (!label) return '';
    return label.trim().toLowerCase() === String(name).trim().toLowerCase() ? '' : label;
  }

  /**
   * Close the panel.
   *
   * `returnFocus` moves focus back to the node that opened it, which is the
   * behaviour Escape and the close button need. There is deliberately no focus
   * trap while open: the panel is non-modal, and trapping would cut the reader off
   * from delivery-004's `## Source fragments` list below — the comparison this
   * panel exists to support.
   */
  function closePanel(returnFocus) {
    if (!panelEl || panelEl.hidden) return;
    panelEl.hidden = true;
    var previous = openNodeEl;
    if (previous) previous.setAttribute('aria-expanded', 'false');
    openNodeId = null;
    openNodeEl = null;
    if (returnFocus && previous && typeof previous.focus === 'function') previous.focus();
  }

  /**
   * PANEL ENTRY POINT.
   *
   * Called when a decorated node is activated by click or Enter/Space. Re-activating
   * the node that is already open toggles the panel closed, which is the disclosure
   * pattern's expected behaviour for a control whose aria-expanded is true.
   */
  function openPanel(nodeId, nodeEl, projection) {
    var node = findNode(projection, nodeId);
    // A node decorated from this projection is always findable; guard anyway so a
    // mismatch degrades to doing nothing rather than throwing inside a listener.
    if (!node) return;

    if (openNodeId === nodeId && panelEl && !panelEl.hidden) {
      closePanel(true);
      return;
    }

    // Opening a different node: clear the previous node's expanded state first.
    if (openNodeEl && openNodeEl !== nodeEl) {
      openNodeEl.setAttribute('aria-expanded', 'false');
    }

    if (!panelEl) panelEl = createPanel(panelContainerRef || nodeEl.parentNode);

    panelEl.querySelector('.aid-node-panel__order').textContent = String(node.order);
    panelEl.querySelector('.aid-node-panel__bar h3 code').textContent = node.name;
    panelEl.querySelector('.aid-node-panel__kind').textContent = node.kind;

    // exit renders only when non-null; advanceType is a closed enum.
    var exitEl = panelEl.querySelector('.aid-node-panel__exit');
    exitEl.textContent = node.exit ? node.exit.advanceType : '';
    exitEl.hidden = !node.exit;

    var labelEl = panelEl.querySelector('.aid-node-panel__label');
    var labelText = meaningfulLabel(node.name, node.label);
    labelEl.textContent = labelText;
    labelEl.hidden = labelText === '';

    // The one assignment whose exactness is the point of the feature.
    panelEl.querySelector('.aid-node-panel__fragment code').textContent = node.fragment;

    var links = panelEl.querySelector('.aid-node-panel__links');
    clearChildren(links);
    links.appendChild(makeLink(node.source.url, 'Source: ' + sourceLabel(node.source.url)));
    if (node.detail) {
      links.appendChild(document.createTextNode(' \u00b7 '));
      links.appendChild(makeLink(node.detail.url, 'full step'));
    }
    links.appendChild(document.createTextNode(' \u00b7 '));
    // delivery-004's hook. A plain in-page anchor; nothing at the target is read.
    links.appendChild(makeLink('#fragment-' + node.id, 'show in the list below'));

    panelEl.hidden = false;
    nodeEl.setAttribute('aria-expanded', 'true');
    openNodeId = nodeId;
    openNodeEl = nodeEl;
    if (typeof panelEl.focus === 'function') panelEl.focus();
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
      // Escape closes from wherever focus is inside the chart. The panel binds its
      // own Escape handler too, because once the panel takes focus the keystroke
      // never reaches this container.
      if (k === 'Escape') { event.preventDefault(); closePanel(true); return; }
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
    // Store for panel insertion (next sibling) and open-node re-resolution across re-renders.
    panelContainerRef = container;

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
