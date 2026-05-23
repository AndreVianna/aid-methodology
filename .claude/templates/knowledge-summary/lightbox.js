/* ============================================================================
 * lightbox.js — Theme toggle, Mermaid init, click-to-expand lightbox,
 *               breadcrumb scrollspy, and full a11y (focus trap, skip link).
 *
 * Used by /aid-summarize. Inline this file inside a <script> block AFTER the
 * inlined Mermaid library. Self-contained (no external deps).
 * ========================================================================== */
(function() {
	'use strict';

	const root = document.documentElement;

	/* ---------- Theme handling ---------- */
	let stored = null;
	try { stored = localStorage.getItem('kb-theme'); } catch (e) {}
	const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
	const initialTheme = stored || (prefersDark ? 'dark' : 'light');
	root.setAttribute('data-theme', initialTheme);

	function updateThemeUI(theme) {
		const icon = document.getElementById('theme-icon');
		const label = document.getElementById('theme-label');
		const btn = document.getElementById('theme-toggle');
		if (icon) icon.textContent = theme === 'dark' ? '☀' : '◐';
		if (label) label.textContent = theme === 'dark' ? 'Light' : 'Dark';
		if (btn) btn.setAttribute('aria-label',
			theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme');
	}
	updateThemeUI(initialTheme);

	function mermaidThemeFor(theme) {
		return theme === 'dark'
			? { theme: 'dark', themeVariables: {
					darkMode: true,
					background: '#111A2E',
					primaryColor: '#0D2A52',
					primaryTextColor: '#E5EAF2',
					primaryBorderColor: '#2DD4D2',
					lineColor: '#9AA5B8',
					secondaryColor: '#1E293B',
					tertiaryColor: '#081021',
					mainBkg: '#0D2A52',
					clusterBkg: '#081021',
					clusterBorder: '#2DD4D2',
					textColor: '#E5EAF2',
					nodeBorder: '#2DD4D2'
				} }
			: { theme: 'default', themeVariables: {
					primaryColor: '#F7F9FC',
					primaryTextColor: '#101828',
					primaryBorderColor: '#00A3A1',
					lineColor: '#4B5565',
					secondaryColor: '#EEF2F7',
					tertiaryColor: '#FFFFFF',
					mainBkg: '#FFFFFF',
					clusterBkg: '#F7F9FC',
					clusterBorder: '#00A3A1',
					textColor: '#101828'
				} };
	}

	/* ---------- Mermaid init ---------- */
	function initMermaid(theme) {
		if (!window.mermaid) return;
		const cfg = mermaidThemeFor(theme);
		cfg.startOnLoad = false;
		cfg.securityLevel = 'loose';
		cfg.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Inter, sans-serif';
		cfg.flowchart = { useMaxWidth: true, htmlLabels: true, curve: 'basis' };
		cfg.er = { useMaxWidth: true };
		cfg.sequence = { useMaxWidth: true };
		window.mermaid.initialize(cfg);
	}

	function renderAllDiagrams() {
		if (!window.mermaid) return;
		const blocks = document.querySelectorAll('.mermaid');
		for (let i = 0; i < blocks.length; i++) {
			const el = blocks[i];
			/* First pass: stash the raw text BEFORE Mermaid has rendered. */
			if (!el.dataset.source) {
				el.dataset.source = el.textContent;
				continue;
			}
			/* Re-render (theme toggle): restore via textContent, never innerHTML.
			   innerHTML re-parses any "<token>" in diagram text as an HTML element,
			   silently corrupting the diagram source. */
			el.textContent = el.dataset.source;
			el.removeAttribute('data-processed');
		}
		try {
			window.mermaid.run({ querySelector: '.mermaid' });
		} catch (e) {
			console.error('Mermaid render error:', e);
		}
	}

	function setTheme(theme) {
		root.setAttribute('data-theme', theme);
		try { localStorage.setItem('kb-theme', theme); } catch (e) {}
		updateThemeUI(theme);
		initMermaid(theme);
		renderAllDiagrams();
	}

	/* ---------- Lightbox state ---------- */
	const lb = {
		root: null, stage: null, inner: null, caption: null,
		scale: 1, tx: 0, ty: 0,
		dragging: false, dragStartX: 0, dragStartY: 0, dragOriginX: 0, dragOriginY: 0,
		lastFocused: null
	};

	function lbApplyTransform() {
		if (!lb.inner) return;
		lb.inner.style.transform = 'translate(' + lb.tx + 'px, ' + lb.ty + 'px) scale(' + lb.scale + ')';
	}

	function lbOpen(svg, captionText) {
		if (!lb.root || !svg) return;
		lb.lastFocused = document.activeElement;

		const clone = svg.cloneNode(true);
		/* Mermaid SVGs use inline max-width to stay small inline. Clear it so the
		   clone can expand to fill the lightbox wrapper, which carries the chrome. */
		clone.style.maxWidth = 'none';
		clone.style.maxHeight = 'none';
		clone.style.width = '100%';
		clone.style.height = '100%';
		clone.removeAttribute('width');
		clone.removeAttribute('height');
		if (!clone.getAttribute('preserveAspectRatio')) {
			clone.setAttribute('preserveAspectRatio', 'xMidYMid meet');
		}
		clone.setAttribute('role', 'img');
		if (captionText) clone.setAttribute('aria-label', captionText);

		lb.inner.innerHTML = '';
		lb.inner.appendChild(clone);
		lb.caption.textContent = captionText || '';
		lb.scale = 1; lb.tx = 0; lb.ty = 0;
		lbApplyTransform();
		lb.root.classList.add('open');
		lb.root.setAttribute('aria-hidden', 'false');
		document.body.classList.add('lb-open');

		/* Move focus into the dialog (close button is a sensible default). */
		const closeBtn = document.getElementById('lb-close');
		if (closeBtn) setTimeout(function() { closeBtn.focus(); }, 50);
	}

	function lbClose() {
		if (!lb.root) return;
		lb.root.classList.remove('open');
		lb.root.setAttribute('aria-hidden', 'true');
		document.body.classList.remove('lb-open');
		lb.inner.innerHTML = '';
		/* Restore focus to whatever opened the lightbox. */
		if (lb.lastFocused && typeof lb.lastFocused.focus === 'function') {
			try { lb.lastFocused.focus(); } catch (e) {}
		}
		lb.lastFocused = null;
	}

	function lbZoom(delta, centerX, centerY) {
		const prev = lb.scale;
		const next = Math.max(0.25, Math.min(8, prev * (delta > 0 ? 1.15 : 1 / 1.15)));
		if (next === prev) return;
		if (typeof centerX === 'number' && typeof centerY === 'number' && lb.stage) {
			const rect = lb.stage.getBoundingClientRect();
			const cx = centerX - rect.left - rect.width / 2;
			const cy = centerY - rect.top - rect.height / 2;
			const factor = next / prev;
			lb.tx = cx - (cx - lb.tx) * factor;
			lb.ty = cy - (cy - lb.ty) * factor;
		}
		lb.scale = next;
		lbApplyTransform();
	}

	function lbResetZoom() {
		lb.scale = 1; lb.tx = 0; lb.ty = 0;
		lbApplyTransform();
	}

	/* ---------- Focus trap (Tab cycles inside the dialog) ---------- */
	function getLightboxFocusables() {
		if (!lb.root) return [];
		const sel = 'button, [href], [tabindex]:not([tabindex="-1"])';
		return Array.prototype.slice.call(lb.root.querySelectorAll(sel))
			.filter(function(el) { return !el.disabled && el.offsetParent !== null; });
	}

	function trapFocusOnTab(e) {
		if (e.key !== 'Tab' || !lb.root.classList.contains('open')) return;
		const focusables = getLightboxFocusables();
		if (!focusables.length) return;
		const first = focusables[0];
		const last = focusables[focusables.length - 1];
		if (e.shiftKey && document.activeElement === first) {
			e.preventDefault();
			last.focus();
		} else if (!e.shiftKey && document.activeElement === last) {
			e.preventDefault();
			first.focus();
		}
	}

	function initLightbox() {
		lb.root    = document.getElementById('lightbox');
		lb.stage   = document.getElementById('lb-stage');
		lb.inner   = document.getElementById('lb-inner');
		lb.caption = document.getElementById('lb-caption');
		if (!lb.root) return;

		/* Make every diagram box keyboard-activatable. */
		const boxes = document.querySelectorAll('.mermaid-box');
		boxes.forEach(function(box) {
			if (!box.hasAttribute('role')) box.setAttribute('role', 'button');
			if (!box.hasAttribute('tabindex')) box.setAttribute('tabindex', '0');
			if (!box.hasAttribute('aria-label')) {
				const cap = box.querySelector('.caption');
				box.setAttribute('aria-label',
					(cap ? cap.textContent.trim() : 'Diagram') + ' — click or press Enter to expand');
			}
			const open = function(e) {
				if (e.target.closest('a, button')) return;
				const svg = box.querySelector('svg');
				const cap = box.querySelector('.caption');
				if (!svg) return;
				lbOpen(svg, cap ? cap.textContent.trim() : '');
			};
			box.addEventListener('click', open);
			box.addEventListener('keydown', function(e) {
				if (e.key === 'Enter' || e.key === ' ') {
					e.preventDefault();
					open(e);
				}
			});
		});

		/* Close handlers */
		document.getElementById('lb-close').addEventListener('click', lbClose);
		lb.root.addEventListener('click', function(e) {
			if (e.target === lb.root || e.target === lb.stage) lbClose();
		});
		document.getElementById('lb-zoom-in').addEventListener('click', function(e) {
			e.stopPropagation(); lbZoom(1);
		});
		document.getElementById('lb-zoom-out').addEventListener('click', function(e) {
			e.stopPropagation(); lbZoom(-1);
		});
		document.getElementById('lb-zoom-reset').addEventListener('click', function(e) {
			e.stopPropagation(); lbResetZoom();
		});

		/* Wheel to zoom */
		lb.stage.addEventListener('wheel', function(e) {
			if (!lb.root.classList.contains('open')) return;
			e.preventDefault();
			lbZoom(e.deltaY < 0 ? 1 : -1, e.clientX, e.clientY);
		}, { passive: false });

		/* Drag to pan */
		lb.stage.addEventListener('mousedown', function(e) {
			if (e.button !== 0) return;
			lb.dragging = true;
			lb.dragStartX = e.clientX; lb.dragStartY = e.clientY;
			lb.dragOriginX = lb.tx; lb.dragOriginY = lb.ty;
			lb.stage.classList.add('dragging');
			e.preventDefault();
		});
		window.addEventListener('mousemove', function(e) {
			if (!lb.dragging) return;
			lb.tx = lb.dragOriginX + (e.clientX - lb.dragStartX);
			lb.ty = lb.dragOriginY + (e.clientY - lb.dragStartY);
			lbApplyTransform();
		});
		window.addEventListener('mouseup', function() {
			if (!lb.dragging) return;
			lb.dragging = false;
			lb.stage.classList.remove('dragging');
		});

		/* Keyboard handlers (focus trap + commands) */
		document.addEventListener('keydown', function(e) {
			if (!lb.root.classList.contains('open')) return;
			if (e.key === 'Escape') { lbClose(); return; }
			if (e.key === '+' || e.key === '=') { lbZoom(1); return; }
			if (e.key === '-' || e.key === '_') { lbZoom(-1); return; }
			if (e.key === '0') { lbResetZoom(); return; }
			trapFocusOnTab(e);
		});
	}

	/* ---------- Breadcrumb scrollspy ---------- */
	function initScrollspy() {
		const sections = document.querySelectorAll('section.sec[data-title]');
		const crumb = document.getElementById('breadcrumb-current');
		if (!crumb || !sections.length) return;
		if (!('IntersectionObserver' in window)) {
			/* Fallback: update on scroll (less efficient). */
			window.addEventListener('scroll', function() {
				const yMid = window.scrollY + 100;
				for (let i = 0; i < sections.length; i++) {
					const r = sections[i].getBoundingClientRect();
					const top = r.top + window.scrollY;
					if (top + sections[i].offsetHeight > yMid) {
						crumb.textContent = sections[i].getAttribute('data-title');
						return;
					}
				}
			}, { passive: true });
			return;
		}
		const visible = {};
		const obs = new IntersectionObserver(function(entries) {
			entries.forEach(function(e) {
				if (e.isIntersecting) visible[e.target.id] = true;
				else delete visible[e.target.id];
			});
			for (let i = 0; i < sections.length; i++) {
				if (visible[sections[i].id]) {
					crumb.textContent = sections[i].getAttribute('data-title');
					return;
				}
			}
		}, { rootMargin: '-80px 0px -60% 0px', threshold: 0 });
		sections.forEach(function(s) { obs.observe(s); });
	}

	/* ---------- Bootstrap ---------- */
	document.addEventListener('DOMContentLoaded', function() {
		initMermaid(initialTheme);
		renderAllDiagrams();
		setTimeout(initLightbox, 50);
		initScrollspy();

		const btn = document.getElementById('theme-toggle');
		if (btn) {
			btn.addEventListener('click', function() {
				const current = root.getAttribute('data-theme');
				setTheme(current === 'dark' ? 'light' : 'dark');
			});
		}

		/* Listen to OS-level theme changes if user hasn't explicitly chosen. */
		if (window.matchMedia) {
			const mq = window.matchMedia('(prefers-color-scheme: dark)');
			const handleChange = function(e) {
				let userChose = null;
				try { userChose = localStorage.getItem('kb-theme'); } catch (_) {}
				if (!userChose) setTheme(e.matches ? 'dark' : 'light');
			};
			if (mq.addEventListener) mq.addEventListener('change', handleChange);
			else if (mq.addListener) mq.addListener(handleChange);
		}
	});
})();
