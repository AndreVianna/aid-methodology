/* Note: this file is for reference only.
 * The actual Mermaid initialization logic — including theme variables for
 * both light and dark modes — lives inside `lightbox.js` (functions
 * `mermaidThemeFor()` and `initMermaid()`).
 *
 * Reproduced here for clarity / standalone reference.
 */

const lightTheme = {
	theme: 'default',
	themeVariables: {
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
	}
};

const darkTheme = {
	theme: 'dark',
	themeVariables: {
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
	}
};

const sharedConfig = {
	startOnLoad: false,
	securityLevel: 'loose',
	fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Inter, sans-serif',
	flowchart: { useMaxWidth: true, htmlLabels: true, curve: 'basis' },
	er: { useMaxWidth: true },
	sequence: { useMaxWidth: true }
};

/* Apply: mermaid.initialize({ ...sharedConfig, ...lightTheme }); */
