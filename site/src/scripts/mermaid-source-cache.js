// mermaid-source-cache.js — KI-018 workaround, injected as an inline <head> script.
//
// astro-mermaid caches each diagram's source on first render:
//
//   if (!diagram.hasAttribute('data-diagram')) {
//     diagram.setAttribute('data-diagram', diagram.textContent || '');
//   }
//   ...
//   diagram.innerHTML = svg;            // the <pre> now holds the rendered SVG
//
// The guard is not atomic across the `await mermaid.render(...)` between those lines,
// and its `initMermaid()` runs from three triggers: initial load, the `data-theme`
// MutationObserver, and `astro:after-swap`. A pass that arrives after `innerHTML = svg`
// reads `textContent` off the *rendered SVG* and caches that as the source. The next
// theme change then feeds an SVG stylesheet to the mermaid parser, and every diagram on
// the page becomes "Syntax error in text" until a reload. Measured on a broken page:
// `data-diagram` held `#mermaid-1785268632684{font-family:"trebuchet ms",…}`.
//
// The fix is to win that race: populate `data-diagram` from the real source before the
// integration can, so its guard finds the attribute present and never overwrites it.
// This must run before astro-mermaid's script, which is a deferred module — deferred
// modules execute after parsing, so an observer installed from a classic inline <head>
// script sees every `pre.mermaid` as the parser appends it and is always first.
//
// Written as a standalone IIFE, in ES5-compatible syntax, with no imports: it is read
// as text at config time and inlined, so it never goes through the bundler.
(function () {
  'use strict';

  function cacheSource(el) {
    // Only ever set it from un-rendered content. Once astro-mermaid has replaced the
    // <pre> with an <svg>, `textContent` is the SVG's stylesheet — the very value this
    // workaround exists to keep out of the attribute.
    if (!el || el.hasAttribute('data-diagram')) return;
    if (el.querySelector && el.querySelector('svg')) return;
    var src = el.textContent || '';
    if (src.indexOf('@keyframes') !== -1) return;
    el.setAttribute('data-diagram', src);
  }

  function sweep(root) {
    var scope = root && root.querySelectorAll ? root : document;
    var found = scope.querySelectorAll('pre.mermaid');
    for (var i = 0; i < found.length; i++) cacheSource(found[i]);
  }

  var observer = new MutationObserver(function (mutations) {
    for (var i = 0; i < mutations.length; i++) {
      var added = mutations[i].addedNodes;
      for (var j = 0; j < added.length; j++) {
        var node = added[j];
        // The parser reports text nodes here too, and they have neither method below.
        // This is the ONLY thing standing between them and a TypeError: the calls are
        // deliberately unguarded, so that deleting this line breaks a test rather than
        // leaving three overlapping checks where one belongs.
        if (!node || node.nodeType !== 1) continue;
        if (node.matches('pre.mermaid')) cacheSource(node);
        sweep(node);
      }
    }
  });

  observer.observe(document.documentElement, { childList: true, subtree: true });

  // Belt and braces for anything the observer could miss: a diagram already parsed
  // before this script ran, and the fresh DOM delivered by a view transition.
  document.addEventListener('DOMContentLoaded', function () { sweep(document); });
  document.addEventListener('astro:after-swap', function () { sweep(document); });
})();
