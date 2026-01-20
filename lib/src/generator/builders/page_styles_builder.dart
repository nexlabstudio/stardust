import '../../config/config.dart';

/// Builds CSS styles and font imports for pages
class PageStylesBuilder {
  final StardustConfig config;

  PageStylesBuilder({required this.config});

  String buildFonts() {
    final sans = config.theme.fonts.sans;
    final mono = config.theme.fonts.mono;

    return '''
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=${sans.replaceAll(' ', '+')}:wght@400;500;600;700&family=${mono.replaceAll(' ', '+')}:wght@400;500&display=swap" rel="stylesheet">
''';
  }

  String buildStyles() {
    final primary = config.theme.colors.primary;
    final bgLight = config.theme.colors.background?.light ?? '#ffffff';
    final bgDark = config.theme.colors.background?.dark ?? '#0f172a';
    final textLight = config.theme.colors.text?.light ?? '#1e293b';
    final textDark = config.theme.colors.text?.dark ?? '#e2e8f0';
    final sans = config.theme.fonts.sans;
    final mono = config.theme.fonts.mono;
    final radius = config.theme.radius;

    return '''
  <style>
    :root {
      --color-primary: $primary;
      --color-bg: $bgLight;
      --color-bg-secondary: #f8fafc;
      --color-text: $textLight;
      --color-text-secondary: #64748b;
      --color-border: #e2e8f0;
      --font-sans: '$sans', system-ui, sans-serif;
      --font-mono: '$mono', monospace;
      --radius: $radius;
    }

    .dark {
      --color-bg: $bgDark;
      --color-bg-secondary: #1e293b;
      --color-text: $textDark;
      --color-text-secondary: #94a3b8;
      --color-border: #334155;
    }

${_buildBaseStyles()}
${_buildHeaderStyles()}
${_buildSearchStyles()}
${_buildLayoutStyles()}
${_buildProseStyles()}
${_buildCodeStyles()}
${_buildComponentStyles()}
${_buildTocStyles()}
${_buildNavigationStyles()}
${_buildFooterStyles()}
${_buildSocialStyles()}
${_buildSyntaxHighlighting()}
${_buildResponsiveStyles()}
  </style>
''';
  }

  String _buildBaseStyles() => '''
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    html {
      scroll-behavior: smooth;
    }

    body {
      font-family: var(--font-sans);
      background: var(--color-bg);
      color: var(--color-text);
      line-height: 1.7;
    }

    .layout {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }''';

  String _buildHeaderStyles() => '''
    .header {
      position: sticky;
      top: 0;
      z-index: 100;
      background: var(--color-bg);
      border-bottom: 1px solid var(--color-border);
      padding: 0 1.5rem;
    }

    .header-inner {
      max-width: 90rem;
      margin: 0 auto;
      height: 4rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .logo {
      display: flex;
      align-items: center;
      gap: 0.625rem;
      font-weight: 700;
      font-size: 1.25rem;
      color: var(--color-primary) !important;
      text-decoration: none;
      transition: all 0.2s ease;
    }

    .logo:hover {
      color: var(--color-primary) !important;
      opacity: 0.85;
      transform: translateY(-1px);
    }

    .logo-icon {
      flex-shrink: 0;
      width: 24px;
      height: 24px;
      color: var(--color-primary);
      filter: drop-shadow(0 2px 6px rgba(99, 102, 241, 0.3));
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .logo:hover .logo-icon {
      transform: rotate(12deg) scale(1.1);
      filter: drop-shadow(0 4px 12px rgba(99, 102, 241, 0.5));
    }

    .dark .logo-icon {
      filter: drop-shadow(0 2px 6px rgba(99, 102, 241, 0.4));
    }

    .dark .logo:hover .logo-icon {
      filter: drop-shadow(0 4px 12px rgba(99, 102, 241, 0.6));
    }

    .logo-image {
      height: 24px;
      width: auto;
      flex-shrink: 0;
    }

    .logo-image.logo-light {
      display: block;
    }

    .dark .logo-image.logo-light {
      display: none;
    }

    .logo-image.logo-dark {
      display: none;
    }

    .dark .logo-image.logo-dark {
      display: block;
    }

    .logo-text {
      line-height: 1;
      color: var(--color-primary) !important;
      font-weight: 700;
      letter-spacing: -0.02em;
    }

    .logo:hover .logo-text {
      color: var(--color-primary) !important;
    }

    .nav {
      display: flex;
      align-items: center;
      gap: 1.5rem;
    }

    .nav a {
      color: var(--color-text-secondary);
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 500;
      transition: color 0.15s;
    }

    .nav a:hover {
      color: var(--color-text);
    }

    .header-actions {
      display: flex;
      align-items: center;
      gap: 0.75rem;
    }

    .theme-toggle {
      padding: 0.5rem;
      background: transparent;
      border: none;
      color: var(--color-text-secondary);
      cursor: pointer;
      border-radius: var(--radius);
    }

    .theme-toggle:hover {
      background: var(--color-bg-secondary);
    }''';

  String _buildSearchStyles() => '''
    /* Search trigger button */
    .search-button {
      display: flex;
      align-items: center;
      gap: 0.625rem;
      padding: 0.5rem 0.875rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      color: var(--color-text-secondary);
      font-size: 0.875rem;
      cursor: pointer;
      min-width: 220px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .search-button:hover {
      border-color: var(--color-primary);
      color: var(--color-text);
      background: color-mix(in srgb, var(--color-primary) 5%, var(--color-bg));
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }

    .search-button svg {
      opacity: 0.6;
      transition: opacity 0.2s;
    }

    .search-button:hover svg {
      opacity: 1;
    }

    .search-button kbd {
      margin-left: auto;
      padding: 0.125rem 0.5rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: 4px;
      font-size: 0.6875rem;
      font-family: var(--font-sans);
      font-weight: 500;
      letter-spacing: 0.02em;
      transition: all 0.2s;
    }

    .search-button:hover kbd {
      background: var(--color-bg);
      border-color: var(--color-primary);
      color: var(--color-primary);
    }

    /* Search modal */
    .search-modal {
      position: fixed;
      inset: 0;
      z-index: 1000;
      display: flex;
      align-items: flex-start;
      justify-content: center;
      padding: 8vh 1rem 1rem;
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.2s cubic-bezier(0.4, 0, 0.2, 1), 
                  visibility 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .search-modal.open {
      opacity: 1;
      visibility: visible;
    }

    .search-backdrop {
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.6);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      animation: fadeIn 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    @keyframes modalSlideIn {
      from {
        opacity: 0;
        transform: translateY(-20px) scale(0.96);
      }
      to {
        opacity: 1;
        transform: translateY(0) scale(1);
      }
    }

    .search-container {
      position: relative;
      width: 100%;
      max-width: 640px;
      max-height: 80vh;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 12px;
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1),
                  0 10px 10px -5px rgba(0, 0, 0, 0.04),
                  0 0 0 1px rgba(0, 0, 0, 0.05);
      overflow: hidden;
      animation: modalSlideIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      display: flex;
      flex-direction: column;
    }

    .dark .search-container {
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.4),
                  0 10px 10px -5px rgba(0, 0, 0, 0.2),
                  0 0 0 1px rgba(255, 255, 255, 0.05);
    }

    #pagefind-search {
      display: flex;
      flex-direction: column;
      height: 100%;
      overflow: hidden;
    }

    /* Pagefind UI customization */
    .pagefind-ui__form {
      position: relative;
      flex-shrink: 0;
    }

    .pagefind-ui__search-input {
      width: 100%;
      padding: 1.25rem 1.25rem 1.25rem 3rem !important;
      font-size: 1rem !important;
      font-family: var(--font-sans) !important;
      background: var(--color-bg) !important;
      border: none !important;
      border-bottom: 1px solid var(--color-border) !important;
      color: var(--color-text) !important;
      outline: none !important;
      transition: border-color 0.2s !important;
    }

    .pagefind-ui__search-input:focus {
      border-bottom-color: var(--color-primary) !important;
    }

    .pagefind-ui__search-input::placeholder {
      color: var(--color-text-secondary) !important;
      opacity: 0.6 !important;
    }

    .pagefind-ui__search-clear {
      position: absolute !important;
      top: 50% !important;
      right: 1rem !important;
      transform: translateY(-50%) !important;
      padding: 0.5rem !important;
      background: transparent !important;
      border: none !important;
      color: var(--color-text-secondary) !important;
      cursor: pointer !important;
      border-radius: 4px !important;
      transition: all 0.2s !important;
    }

    .pagefind-ui__search-clear:hover {
      background: var(--color-bg-secondary) !important;
      color: var(--color-text) !important;
    }

    .pagefind-ui__drawer {
      position: absolute !important;
      left: 1.25rem !important;
      top: 50% !important;
      transform: translateY(-50%) !important;
      color: var(--color-text-secondary) !important;
      pointer-events: none !important;
    }

    .pagefind-ui__results-area {
      margin-top: 0 !important;
      flex: 1 !important;
      overflow-y: auto !important;
      overflow-x: hidden !important;
      scrollbar-width: thin;
      scrollbar-color: var(--color-border) transparent;
    }

    .pagefind-ui__results-area::-webkit-scrollbar {
      width: 8px;
    }

    .pagefind-ui__results-area::-webkit-scrollbar-track {
      background: transparent;
    }

    .pagefind-ui__results-area::-webkit-scrollbar-thumb {
      background: var(--color-border);
      border-radius: 4px;
    }

    .pagefind-ui__results-area::-webkit-scrollbar-thumb:hover {
      background: var(--color-text-secondary);
    }

    .pagefind-ui__results {
      padding: 0.5rem !important;
      list-style: none !important;
    }

    .pagefind-ui__result {
      padding: 0 !important;
      margin-bottom: 0.25rem !important;
      border: none !important;
      background: none !important;
    }

    .pagefind-ui__result-link {
      display: block !important;
      padding: 1rem 1.25rem !important;
      text-decoration: none !important;
      border-radius: 8px !important;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1) !important;
      border: 1px solid transparent !important;
    }

    .pagefind-ui__result-link:hover {
      background: var(--color-bg-secondary) !important;
      border-color: var(--color-border) !important;
      transform: translateX(2px) !important;
    }

    .pagefind-ui__result-title {
      font-size: 0.9375rem !important;
      font-weight: 600 !important;
      color: var(--color-text) !important;
      margin-bottom: 0.375rem !important;
      line-height: 1.4 !important;
    }

    .pagefind-ui__result-excerpt {
      font-size: 0.875rem !important;
      line-height: 1.6 !important;
      color: var(--color-text-secondary) !important;
      margin: 0 !important;
    }

    .pagefind-ui__result-excerpt mark {
      background: color-mix(in srgb, var(--color-primary) 20%, transparent) !important;
      color: var(--color-primary) !important;
      font-weight: 600 !important;
      padding: 0.125rem 0.25rem !important;
      border-radius: 3px !important;
    }

    .pagefind-ui__message {
      padding: 3rem 1.25rem !important;
      text-align: center !important;
      color: var(--color-text-secondary) !important;
      font-size: 0.875rem !important;
    }

    .pagefind-ui__button {
      padding: 0.5rem 1rem !important;
      background: var(--color-primary) !important;
      color: white !important;
      border: none !important;
      border-radius: 6px !important;
      font-weight: 500 !important;
      cursor: pointer !important;
      transition: all 0.2s !important;
    }

    .pagefind-ui__button:hover {
      background: color-mix(in srgb, var(--color-primary) 90%, black) !important;
      transform: translateY(-1px) !important;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1) !important;
    }

    .pagefind-ui__result-nested {
      padding-left: 1rem !important;
      margin-top: 0.5rem !important;
      border-left: 2px solid var(--color-border) !important;
    }

    .pagefind-ui__result-tag {
      display: inline-block !important;
      padding: 0.125rem 0.5rem !important;
      background: var(--color-bg-secondary) !important;
      border: 1px solid var(--color-border) !important;
      border-radius: 4px !important;
      font-size: 0.75rem !important;
      color: var(--color-text-secondary) !important;
      margin-right: 0.375rem !important;
      margin-bottom: 0.375rem !important;
    }

    /* Loading state */
    .pagefind-ui__loading {
      padding: 2rem 1.25rem !important;
      text-align: center !important;
      color: var(--color-text-secondary) !important;
    }

    /* Empty state */
    .search-error {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 1rem;
      padding: 3rem 2rem;
      text-align: center;
      color: var(--color-text-secondary);
    }

    .search-error svg {
      opacity: 0.3;
    }

    .search-error p {
      font-size: 0.875rem;
      line-height: 1.6;
    }

    .search-error code {
      padding: 0.125rem 0.375rem;
      background: var(--color-bg-secondary);
      border-radius: 4px;
      font-family: var(--font-mono);
      font-size: 0.8125rem;
    }''';

  String _buildLayoutStyles() => '''
    .main-container {
      flex: 1;
      max-width: 90rem;
      margin: 0 auto;
      width: 100%;
      display: grid;
      grid-template-columns: 280px 1fr 220px;
      gap: 1px;
    }

    .sidebar {
      position: sticky;
      top: 4rem;
      height: calc(100vh - 4rem);
      overflow-y: auto;
      padding: 2rem 1rem;
      border-right: 1px solid var(--color-border);
    }

    .sidebar-group {
      margin-bottom: 1.5rem;
    }

    .sidebar-group-title {
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--color-text-secondary);
      margin-bottom: 0.5rem;
      padding: 0 0.75rem;
    }

    .sidebar-links {
      list-style: none;
    }

    .sidebar-link {
      display: block;
      padding: 0.375rem 0.75rem;
      color: var(--color-text-secondary);
      text-decoration: none;
      font-size: 0.875rem;
      border-radius: var(--radius);
      transition: all 0.15s;
    }

    .sidebar-link:hover {
      color: var(--color-text);
      background: var(--color-bg-secondary);
    }

    .sidebar-link.active {
      color: var(--color-primary);
      background: color-mix(in srgb, var(--color-primary) 10%, transparent);
    }

    .content {
      padding: 2rem 3rem;
      min-width: 0;
    }''';

  String _buildProseStyles() => '''
    .prose {
      max-width: 48rem;
    }

    .prose h1 {
      font-size: 2.25rem;
      font-weight: 700;
      margin-bottom: 1rem;
      letter-spacing: -0.025em;
    }

    .prose h2 {
      font-size: 1.5rem;
      font-weight: 600;
      margin-top: 2.5rem;
      margin-bottom: 1rem;
      padding-bottom: 0.5rem;
      border-bottom: 1px solid var(--color-border);
    }

    .prose h3 {
      font-size: 1.25rem;
      font-weight: 600;
      margin-top: 2rem;
      margin-bottom: 0.75rem;
    }

    .prose h4 {
      font-size: 1rem;
      font-weight: 600;
      margin-top: 1.5rem;
      margin-bottom: 0.5rem;
    }

    .prose p {
      margin-bottom: 1rem;
    }

    .prose a {
      color: var(--color-primary);
      text-decoration: underline;
      text-underline-offset: 2px;
    }

    .prose ul, .prose ol {
      margin-bottom: 1rem;
      padding-left: 1.5rem;
    }

    .prose li {
      margin-bottom: 0.25rem;
    }

    .prose blockquote {
      border-left: 3px solid var(--color-primary);
      padding-left: 1rem;
      color: var(--color-text-secondary);
      font-style: italic;
      margin: 1.5rem 0;
    }

    .prose hr {
      border: none;
      border-top: 1px solid var(--color-border);
      margin: 2rem 0;
    }

    .prose table {
      width: 100%;
      border-collapse: collapse;
      margin: 1.5rem 0;
    }

    .prose th, .prose td {
      padding: 0.75rem 1rem;
      text-align: left;
      border: 1px solid var(--color-border);
    }

    .prose th {
      background: var(--color-bg-secondary);
      font-weight: 600;
    }

    .prose img {
      max-width: 100%;
      border-radius: var(--radius);
    }''';

  String _buildCodeStyles() => '''
    .prose code {
      font-family: var(--font-mono);
      font-size: 0.875em;
      background: var(--color-bg-secondary);
      padding: 0.125rem 0.375rem;
      border-radius: 4px;
    }

    .prose pre code {
      background: none;
      padding: 0;
    }

    .code-block {
      margin: 1.5rem 0;
      background: var(--color-bg-secondary);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .code-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0.5rem 1rem;
      background: color-mix(in srgb, var(--color-bg-secondary) 50%, var(--color-bg));
      border-bottom: 1px solid var(--color-border);
    }

    .code-language {
      font-size: 0.75rem;
      font-weight: 500;
      color: var(--color-text-secondary);
      text-transform: uppercase;
    }

    .copy-button {
      padding: 0.25rem 0.5rem;
      font-size: 0.75rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 4px;
      color: var(--color-text-secondary);
      cursor: pointer;
      transition: all 0.15s;
    }

    .copy-button:hover {
      background: var(--color-bg-secondary);
      color: var(--color-text);
    }

    .code-pre {
      margin: 0;
      padding: 1rem;
      overflow-x: auto;
      font-size: 0.875rem;
      line-height: 1.6;
    }''';

  String _buildComponentStyles() => '''
    .callout {
      margin: 1.5rem 0;
      padding: 1rem 1.25rem;
      border-radius: var(--radius);
      border-left: 4px solid var(--callout-color);
      background: color-mix(in srgb, var(--callout-color) 8%, var(--color-bg));
    }

    .callout-title {
      font-weight: 600;
      margin-bottom: 0.5rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .callout-content {
      color: var(--color-text);
    }

    .callout-content p:last-child {
      margin-bottom: 0;
    }

    .callout-info { --callout-color: #3b82f6; }
    .callout-warning { --callout-color: #f59e0b; }
    .callout-danger { --callout-color: #ef4444; }
    .callout-tip { --callout-color: #22c55e; }
    .callout-note { --callout-color: #8b5cf6; }
    .callout-success { --callout-color: #10b981; }

    .tabs,
    .code-group {
      margin: 1.5rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .tabs .tab-buttons,
    .code-group .tab-buttons {
      display: flex;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
      overflow-x: auto;
      scrollbar-width: none;
    }

    .tabs .tab-buttons::-webkit-scrollbar,
    .code-group .tab-buttons::-webkit-scrollbar {
      display: none;
    }

    .tab-button {
      padding: 0.75rem 1rem;
      background: none;
      border: none;
      font-family: var(--font-sans);
      font-size: 0.875rem;
      font-weight: 500;
      color: var(--color-text-secondary);
      cursor: pointer;
      transition: all 0.15s;
      white-space: nowrap;
      position: relative;
    }

    .tab-button:hover {
      color: var(--color-text);
      background: color-mix(in srgb, var(--color-bg-secondary) 50%, var(--color-bg));
    }

    .tab-button.active {
      color: var(--color-primary);
    }

    .tab-button.active::after {
      content: '';
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 2px;
      background: var(--color-primary);
    }

    .tab-panel {
      padding: 1rem;
    }

    .tab-panel[hidden] {
      display: none;
    }

    .code-group .tab-button {
      font-family: var(--font-mono);
      font-size: 0.8125rem;
    }

    .code-group .tab-panel {
      padding: 0;
    }

    .code-group .tab-panel .code-block {
      margin: 0;
      border: none;
      border-radius: 0;
    }

    .code-group .tab-panel pre {
      margin: 0;
    }

    .accordion {
      margin: 1rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .accordion-group .accordion {
      margin: 0;
      border-radius: 0;
      border-bottom: none;
    }

    .accordion-group .accordion:first-child {
      border-top-left-radius: var(--radius);
      border-top-right-radius: var(--radius);
    }

    .accordion-group .accordion:last-child {
      border-bottom-left-radius: var(--radius);
      border-bottom-right-radius: var(--radius);
      border-bottom: 1px solid var(--color-border);
    }

    .accordion-group {
      margin: 1.5rem 0;
      border-radius: var(--radius);
    }

    .accordion-summary {
      padding: 0.875rem 1rem;
      cursor: pointer;
      font-weight: 500;
      background: var(--color-bg-secondary);
      display: flex;
      align-items: center;
      gap: 0.5rem;
      list-style: none;
      transition: background 0.15s;
    }

    .accordion-summary::-webkit-details-marker {
      display: none;
    }

    .accordion-summary::before {
      content: '';
      width: 0.5rem;
      height: 0.5rem;
      border-right: 2px solid var(--color-text-secondary);
      border-bottom: 2px solid var(--color-text-secondary);
      transform: rotate(-45deg);
      transition: transform 0.2s;
      flex-shrink: 0;
    }

    .accordion[open] .accordion-summary::before {
      transform: rotate(45deg);
    }

    .accordion-summary:hover {
      background: color-mix(in srgb, var(--color-bg-secondary) 70%, var(--color-bg));
    }

    .accordion-icon {
      margin-right: 0.25rem;
    }

    .accordion-content {
      padding: 1rem;
      border-top: 1px solid var(--color-border);
    }

    .accordion-content p:last-child {
      margin-bottom: 0;
    }

    .steps {
      margin: 1.5rem 0;
      padding-left: 0;
    }

    .step {
      display: flex;
      position: relative;
      padding-bottom: 1.5rem;
    }

    .step:last-child {
      padding-bottom: 0;
    }

    .step:last-child .step-line {
      display: none;
    }

    .step-indicator {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-right: 1rem;
      flex-shrink: 0;
    }

    .step-number {
      width: 2rem;
      height: 2rem;
      background: var(--color-primary);
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      font-size: 0.875rem;
      flex-shrink: 0;
    }

    .step-line {
      width: 2px;
      flex: 1;
      background: var(--color-border);
      margin-top: 0.5rem;
      min-height: 1rem;
    }

    .step-body {
      flex: 1;
      padding-top: 0.25rem;
      min-width: 0;
    }

    .step-title {
      font-weight: 600;
      font-size: 1rem;
      margin: 0 0 0.5rem 0;
      color: var(--color-text);
    }

    .step-content {
      color: var(--color-text-secondary);
    }

    .step-content p:last-child {
      margin-bottom: 0;
    }

    .cards {
      display: grid;
      grid-template-columns: repeat(var(--cards-columns, 2), 1fr);
      gap: 1rem;
      margin: 1.5rem 0;
    }

    @media (max-width: 640px) {
      .cards {
        grid-template-columns: 1fr;
      }
    }

    .card {
      padding: 1.25rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      transition: all 0.2s;
    }

    .card:not(.cards .card) {
      margin: 1.5rem 0;
    }

    .card-link {
      text-decoration: none;
      color: inherit;
      display: block;
    }

    .card-link:hover {
      border-color: var(--color-primary);
      box-shadow: 0 4px 12px color-mix(in srgb, var(--color-primary) 10%, transparent);
      transform: translateY(-2px);
    }

    .card-icon {
      font-size: 1.25rem;
      margin-right: 0.5rem;
    }

    .card-title {
      font-weight: 600;
      font-size: 1rem;
      margin: 0 0 0.5rem 0;
      color: var(--color-text);
      display: flex;
      align-items: center;
    }

    .card-link:hover .card-title {
      color: var(--color-primary);
    }

    .card-content {
      color: var(--color-text-secondary);
      font-size: 0.875rem;
      line-height: 1.5;
    }

    .card-content p:last-child {
      margin-bottom: 0;
    }

    .tabs-empty,
    .code-group-empty,
    .steps-empty,
    .tiles-empty {
      padding: 2rem;
      text-align: center;
      color: var(--color-text-secondary);
      font-style: italic;
    }

    .columns {
      display: flex;
      gap: var(--columns-gap, 1rem);
      margin: 1.5rem 0;
    }

    .column {
      flex: 1;
      min-width: 0;
    }

    .column > *:first-child {
      margin-top: 0;
    }

    .column > *:last-child {
      margin-bottom: 0;
    }

    @media (max-width: 768px) {
      .columns {
        flex-direction: column;
      }
    }

    .tiles {
      display: grid;
      grid-template-columns: repeat(var(--tiles-columns, 3), 1fr);
      gap: 1rem;
      margin: 1.5rem 0;
    }

    @media (max-width: 1024px) {
      .tiles {
        grid-template-columns: repeat(2, 1fr);
      }
    }

    @media (max-width: 640px) {
      .tiles {
        grid-template-columns: 1fr;
      }
    }

    .tile {
      padding: 1.5rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      text-align: center;
      transition: all 0.2s;
    }

    .tile-link {
      text-decoration: none;
      color: inherit;
      display: block;
    }

    .tile-link:hover {
      border-color: var(--color-primary);
      box-shadow: 0 4px 12px color-mix(in srgb, var(--color-primary) 10%, transparent);
      transform: translateY(-2px);
    }

    .tile-icon {
      font-size: 2rem;
      margin-bottom: 0.75rem;
    }

    .tile-title {
      font-weight: 600;
      font-size: 0.9375rem;
      margin: 0 0 0.5rem 0;
      color: var(--color-text);
    }

    .tile-link:hover .tile-title {
      color: var(--color-primary);
    }

    .tile-content {
      color: var(--color-text-secondary);
      font-size: 0.8125rem;
      line-height: 1.5;
    }

    .tile-content p:last-child {
      margin-bottom: 0;
    }

    .panel {
      margin: 1.5rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .panel-header {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.75rem 1rem;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
    }

    .panel-icon {
      font-size: 1.125rem;
    }

    .panel-title {
      font-weight: 600;
      font-size: 0.9375rem;
    }

    .panel-content {
      padding: 1rem;
    }

    .panel-content > *:first-child {
      margin-top: 0;
    }

    .panel-content > *:last-child {
      margin-bottom: 0;
    }

    .panel-primary {
      border-color: var(--color-primary);
    }

    .panel-primary .panel-header {
      background: color-mix(in srgb, var(--color-primary) 10%, var(--color-bg));
      border-bottom-color: var(--color-primary);
    }

    .panel-success {
      border-color: #10b981;
    }

    .panel-success .panel-header {
      background: color-mix(in srgb, #10b981 10%, var(--color-bg));
      border-bottom-color: #10b981;
    }

    .panel-warning {
      border-color: #f59e0b;
    }

    .panel-warning .panel-header {
      background: color-mix(in srgb, #f59e0b 10%, var(--color-bg));
      border-bottom-color: #f59e0b;
    }

    .panel-danger {
      border-color: #ef4444;
    }

    .panel-danger .panel-header {
      background: color-mix(in srgb, #ef4444 10%, var(--color-bg));
      border-bottom-color: #ef4444;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.25rem;
      font-weight: 500;
      border-radius: 9999px;
      white-space: nowrap;
    }

    .badge-icon {
      font-size: 0.875em;
    }

    .badge-sm {
      padding: 0.125rem 0.5rem;
      font-size: 0.6875rem;
    }

    .badge-md {
      padding: 0.25rem 0.625rem;
      font-size: 0.75rem;
    }

    .badge-lg {
      padding: 0.375rem 0.75rem;
      font-size: 0.8125rem;
    }

    .badge-default {
      background: var(--color-bg-secondary);
      color: var(--color-text-secondary);
      border: 1px solid var(--color-border);
    }

    .badge-primary {
      background: color-mix(in srgb, var(--color-primary) 15%, var(--color-bg));
      color: var(--color-primary);
      border: 1px solid color-mix(in srgb, var(--color-primary) 30%, transparent);
    }

    .badge-success {
      background: color-mix(in srgb, #10b981 15%, var(--color-bg));
      color: #10b981;
      border: 1px solid color-mix(in srgb, #10b981 30%, transparent);
    }

    .badge-warning {
      background: color-mix(in srgb, #f59e0b 15%, var(--color-bg));
      color: #b45309;
      border: 1px solid color-mix(in srgb, #f59e0b 30%, transparent);
    }

    .badge-danger {
      background: color-mix(in srgb, #ef4444 15%, var(--color-bg));
      color: #dc2626;
      border: 1px solid color-mix(in srgb, #ef4444 30%, transparent);
    }

    .badge-info {
      background: color-mix(in srgb, #3b82f6 15%, var(--color-bg));
      color: #2563eb;
      border: 1px solid color-mix(in srgb, #3b82f6 30%, transparent);
    }

    .icon {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      vertical-align: middle;
    }

    .icon-emoji {
      line-height: 1;
    }

    .icon-svg svg {
      display: block;
    }

    .icon-text {
      font-family: var(--font-mono);
      font-size: 0.875em;
    }

    [data-lucide] {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      vertical-align: middle;
      stroke: currentColor;
      stroke-width: 2;
      stroke-linecap: round;
      stroke-linejoin: round;
      fill: none;
    }

    .image-component {
      margin: 1.5rem 0;
    }

    .image-component img {
      max-width: 100%;
      height: auto;
      display: block;
    }

    .image-rounded img {
      border-radius: var(--radius);
    }

    .image-bordered img {
      border: 1px solid var(--color-border);
    }

    .image-zoom-wrapper {
      position: relative;
      display: inline-block;
      cursor: zoom-in;
    }

    .image-zoom-hint {
      position: absolute;
      bottom: 0.5rem;
      right: 0.5rem;
      padding: 0.25rem;
      background: color-mix(in srgb, var(--color-bg) 80%, transparent);
      border-radius: 4px;
      opacity: 0;
      transition: opacity 0.2s;
      pointer-events: none;
    }

    .image-zoom-wrapper:hover .image-zoom-hint {
      opacity: 1;
    }

    .image-caption {
      margin-top: 0.5rem;
      font-size: 0.875rem;
      color: var(--color-text-secondary);
      text-align: center;
    }

    .image-zoom-overlay {
      position: fixed;
      inset: 0;
      z-index: 1000;
      background: color-mix(in srgb, var(--color-bg) 95%, transparent);
      backdrop-filter: blur(4px);
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: zoom-out;
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.2s, visibility 0.2s;
    }

    .image-zoom-overlay.active {
      opacity: 1;
      visibility: visible;
    }

    .image-zoom-overlay img {
      max-width: 90vw;
      max-height: 90vh;
      object-fit: contain;
      border-radius: var(--radius);
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    }

    .tree {
      margin: 1.5rem 0;
      padding: 1rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      font-family: var(--font-mono);
      font-size: 0.875rem;
    }

    .tree-root {
      list-style: none;
      padding: 0;
      margin: 0;
    }

    .tree-children {
      list-style: none;
      padding-left: 1.25rem;
      margin: 0;
      border-left: 1px dashed var(--color-border);
      margin-left: 0.5rem;
    }

    .tree-folder,
    .tree-file {
      padding: 0.25rem 0;
    }

    .tree-folder > details > summary {
      cursor: pointer;
      list-style: none;
      display: flex;
      align-items: center;
      gap: 0.375rem;
    }

    .tree-folder > details > summary::-webkit-details-marker {
      display: none;
    }

    .tree-folder > details > summary::before {
      content: '▶';
      font-size: 0.625rem;
      transition: transform 0.15s;
      color: var(--color-text-secondary);
    }

    .tree-folder > details[open] > summary::before {
      transform: rotate(90deg);
    }

    .tree-folder-name {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      font-weight: 500;
    }

    .tree-file {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      padding-left: 1rem;
    }

    .tree-icon {
      font-size: 1rem;
      line-height: 1;
    }

    .tree-file-name {
      color: var(--color-text-secondary);
    }

    .mermaid-figure {
      margin: 1.5rem 0;
    }

    .mermaid-diagram {
      padding: 1.5rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow-x: auto;
      text-align: center;
    }

    .mermaid-diagram .mermaid {
      margin: 0;
      background: none;
    }

    .mermaid-caption {
      margin-top: 0.5rem;
      font-size: 0.875rem;
      color: var(--color-text-secondary);
      text-align: center;
    }

    .tooltip {
      position: relative;
      text-decoration: underline;
      text-decoration-style: dotted;
      text-underline-offset: 2px;
      cursor: help;
    }

    .tooltip::before,
    .tooltip::after {
      position: absolute;
      opacity: 0;
      visibility: hidden;
      transition: opacity 0.15s, visibility 0.15s;
      pointer-events: none;
      z-index: 100;
    }

    .tooltip::before {
      content: attr(data-tooltip);
      padding: 0.5rem 0.75rem;
      background: var(--color-text);
      color: var(--color-bg);
      font-size: 0.8125rem;
      font-weight: 500;
      line-height: 1.4;
      border-radius: var(--radius);
      white-space: nowrap;
      max-width: 280px;
      white-space: normal;
      text-align: center;
    }

    .tooltip::after {
      content: '';
      border: 6px solid transparent;
    }

    .tooltip:hover::before,
    .tooltip:hover::after {
      opacity: 1;
      visibility: visible;
    }

    .tooltip-top::before {
      bottom: calc(100% + 8px);
      left: 50%;
      transform: translateX(-50%);
    }

    .tooltip-top::after {
      bottom: calc(100% + 2px);
      left: 50%;
      transform: translateX(-50%);
      border-top-color: var(--color-text);
    }

    .tooltip-bottom::before {
      top: calc(100% + 8px);
      left: 50%;
      transform: translateX(-50%);
    }

    .tooltip-bottom::after {
      top: calc(100% + 2px);
      left: 50%;
      transform: translateX(-50%);
      border-bottom-color: var(--color-text);
    }

    .tooltip-left::before {
      right: calc(100% + 8px);
      top: 50%;
      transform: translateY(-50%);
    }

    .tooltip-left::after {
      right: calc(100% + 2px);
      top: 50%;
      transform: translateY(-50%);
      border-left-color: var(--color-text);
    }

    .tooltip-right::before {
      left: calc(100% + 8px);
      top: 50%;
      transform: translateY(-50%);
    }

    .tooltip-right::after {
      left: calc(100% + 2px);
      top: 50%;
      transform: translateY(-50%);
      border-right-color: var(--color-text);
    }

    .embed {
      margin: 1.5rem 0;
      border-radius: var(--radius);
      overflow: hidden;
      background: var(--color-bg-secondary);
    }

    .embed iframe,
    .embed video {
      width: 100%;
      height: 100%;
      display: block;
    }

    .embed-youtube,
    .embed-vimeo {
      position: relative;
      width: 100%;
    }

    .embed-video video {
      max-width: 100%;
      height: auto;
    }

    .embed-zapp,
    .embed-stackblitz,
    .embed-codepen {
      border: 1px solid var(--color-border);
    }

    .embed-error {
      padding: 1rem;
      background: color-mix(in srgb, #ef4444 10%, var(--color-bg));
      border: 1px solid #ef4444;
      border-radius: var(--radius);
      color: #ef4444;
      font-size: 0.875rem;
      text-align: center;
    }

    @media (max-width: 640px) {
      .embed-zapp,
      .embed-stackblitz,
      .embed-codepen {
        height: 400px !important;
      }
    }

    .field {
      margin: 1rem 0;
      padding: 1rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
    }

    .field + .field {
      margin-top: 0.5rem;
    }

    .field-is-deprecated {
      opacity: 0.7;
    }

    .field-header {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
    }

    .field-name {
      font-weight: 600;
      color: var(--color-text);
      background: none;
      padding: 0;
    }

    .field-type {
      font-family: var(--font-mono);
      font-size: 0.8125rem;
      color: var(--color-primary);
    }

    .field-badge {
      font-size: 0.6875rem;
      font-weight: 600;
      text-transform: uppercase;
      padding: 0.125rem 0.375rem;
      border-radius: 4px;
    }

    .field-required {
      background: color-mix(in srgb, #ef4444 15%, var(--color-bg));
      color: #ef4444;
    }

    .field-optional {
      background: var(--color-bg);
      color: var(--color-text-secondary);
      border: 1px solid var(--color-border);
    }

    .field-nullable {
      background: color-mix(in srgb, #f59e0b 15%, var(--color-bg));
      color: #b45309;
    }

    .field-deprecated {
      background: color-mix(in srgb, #6b7280 15%, var(--color-bg));
      color: #6b7280;
      text-decoration: line-through;
    }

    .field-param-type {
      background: color-mix(in srgb, #8b5cf6 15%, var(--color-bg));
      color: #7c3aed;
    }

    .field-default {
      display: block;
      font-size: 0.8125rem;
      color: var(--color-text-secondary);
      margin-bottom: 0.5rem;
    }

    .field-default code {
      background: var(--color-bg);
      padding: 0.125rem 0.25rem;
      border-radius: 3px;
    }

    .field-description {
      font-size: 0.875rem;
      color: var(--color-text-secondary);
    }

    .field-description p:last-child {
      margin-bottom: 0;
    }

    .api-endpoint {
      margin: 1.5rem 0;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      overflow: hidden;
    }

    .api-header {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
    }

    .api-method {
      font-size: 0.75rem;
      font-weight: 700;
      padding: 0.25rem 0.5rem;
      border-radius: 4px;
      text-transform: uppercase;
    }

    .api-method-get { background: #10b981; color: white; }
    .api-method-post { background: #3b82f6; color: white; }
    .api-method-put { background: #f59e0b; color: white; }
    .api-method-patch { background: #8b5cf6; color: white; }
    .api-method-delete { background: #ef4444; color: white; }

    .api-path {
      font-family: var(--font-mono);
      font-size: 0.875rem;
      font-weight: 500;
      background: none;
      padding: 0;
    }

    .api-auth {
      margin-left: auto;
      font-size: 0.75rem;
      color: var(--color-text-secondary);
    }

    .api-title {
      padding: 0.75rem 1rem;
      font-weight: 600;
      border-bottom: 1px solid var(--color-border);
    }

    .api-content {
      padding: 1rem;
    }

    .frame {
      margin: 1.5rem 0;
      border-radius: var(--radius);
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .frame-browser {
      border: 1px solid var(--color-border);
    }

    .frame-header {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1rem;
      background: var(--color-bg-secondary);
      border-bottom: 1px solid var(--color-border);
    }

    .frame-buttons {
      display: flex;
      gap: 0.5rem;
    }

    .frame-button {
      width: 12px;
      height: 12px;
      border-radius: 50%;
    }

    .frame-close { background: #ef4444; }
    .frame-minimize { background: #f59e0b; }
    .frame-maximize { background: #22c55e; }

    .frame-url {
      flex: 1;
      padding: 0.375rem 0.75rem;
      background: var(--color-bg);
      border: 1px solid var(--color-border);
      border-radius: 4px;
      font-family: var(--font-mono);
      font-size: 0.75rem;
      color: var(--color-text-secondary);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .frame-content {
      padding: 0;
      background: var(--color-bg);
    }

    .frame-content img {
      display: block;
      width: 100%;
      height: auto;
    }

    .frame-phone {
      max-width: 375px;
      margin-left: auto;
      margin-right: auto;
      border: 8px solid #1f2937;
      border-radius: 40px;
      background: #1f2937;
    }

    .frame-phone-notch {
      width: 150px;
      height: 28px;
      margin: 0 auto 8px;
      background: #1f2937;
      border-bottom-left-radius: 16px;
      border-bottom-right-radius: 16px;
    }

    .frame-phone .frame-content {
      border-radius: 32px;
      overflow: hidden;
      aspect-ratio: 9/19.5;
    }

    .frame-phone-home {
      width: 120px;
      height: 5px;
      margin: 8px auto 0;
      background: #6b7280;
      border-radius: 3px;
    }

    .update {
      margin: 1.5rem 0;
      padding-left: 1rem;
      border-left: 3px solid var(--color-border);
    }

    .update-header {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 0.5rem;
      margin-bottom: 0.5rem;
    }

    .update-label {
      font-weight: 600;
      font-size: 0.9375rem;
    }

    .update-version {
      font-family: var(--font-mono);
      font-size: 0.8125rem;
      padding: 0.125rem 0.375rem;
      background: var(--color-bg-secondary);
      border-radius: 4px;
    }

    .update-date {
      font-size: 0.8125rem;
      color: var(--color-text-secondary);
    }

    .update-content {
      font-size: 0.9375rem;
    }

    .update-content p:last-child {
      margin-bottom: 0;
    }

    .update-feature { border-left-color: #22c55e; }
    .update-feature .update-label { color: #22c55e; }

    .update-fix { border-left-color: #3b82f6; }
    .update-fix .update-label { color: #3b82f6; }

    .update-breaking { border-left-color: #ef4444; }
    .update-breaking .update-label { color: #ef4444; }

    .update-deprecation { border-left-color: #f59e0b; }
    .update-deprecation .update-label { color: #f59e0b; }

    .update-improvement { border-left-color: #8b5cf6; }
    .update-improvement .update-label { color: #8b5cf6; }''';

  String _buildTocStyles() => '''
    .toc {
      position: sticky;
      top: 4rem;
      height: calc(100vh - 4rem);
      overflow-y: auto;
      padding: 2rem 1rem;
      border-left: 1px solid var(--color-border);
    }

    .toc-title {
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--color-text-secondary);
      margin-bottom: 0.75rem;
    }

    .toc-list {
      list-style: none;
    }

    .toc-link {
      display: block;
      padding: 0.25rem 0;
      color: var(--color-text-secondary);
      text-decoration: none;
      font-size: 0.8125rem;
      transition: color 0.15s;
    }

    .toc-link:hover {
      color: var(--color-text);
    }

    .toc-link.active {
      color: var(--color-primary);
    }

    .toc-link[data-level="3"] {
      padding-left: 0.75rem;
    }

    .toc-link[data-level="4"] {
      padding-left: 1.5rem;
    }''';

  String _buildNavigationStyles() => '''
    .edit-link {
      margin-top: 2rem;
      padding-top: 1.5rem;
      border-top: 1px solid var(--color-border);
    }

    .edit-link a {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      color: var(--color-text-secondary);
      font-size: 0.875rem;
      text-decoration: none;
      transition: color 0.15s;
    }

    .edit-link a:hover {
      color: var(--color-primary);
    }

    .edit-link svg {
      flex-shrink: 0;
    }

    .page-nav {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
      margin-top: 3rem;
      padding-top: 2rem;
      border-top: 1px solid var(--color-border);
    }

    .page-nav-link {
      display: flex;
      flex-direction: column;
      padding: 1rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      text-decoration: none;
      transition: border-color 0.15s;
    }

    .page-nav-link:hover {
      border-color: var(--color-primary);
    }

    .page-nav-link.next {
      text-align: right;
    }

    .page-nav-label {
      font-size: 0.75rem;
      color: var(--color-text-secondary);
      margin-bottom: 0.25rem;
    }

    .page-nav-title {
      font-weight: 500;
      color: var(--color-text);
    }''';

  String _buildFooterStyles() => '''
    .footer {
      border-top: 1px solid var(--color-border);
      padding: 1.5rem 2rem;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.75rem;
      color: var(--color-text-secondary);
      font-size: 0.875rem;
    }

    .footer-social {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }

    .footer-social-link {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 32px;
      height: 32px;
      color: var(--color-text-secondary);
      border-radius: var(--radius);
      transition: all 0.15s;
    }

    .footer-social-link:hover {
      color: var(--color-text);
      background: var(--color-bg-secondary);
    }

    .footer-powered {
      display: flex;
      align-items: center;
      gap: 0.375rem;
      font-size: 0.8125rem;
    }

    .footer-hex {
      color: var(--color-primary);
    }

    .footer-powered a {
      color: var(--color-text);
      text-decoration: none;
      font-weight: 500;
    }

    .footer-powered a:hover {
      color: var(--color-primary);
    }''';

  String _buildSocialStyles() => '''
    .social-link {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      color: var(--color-text-secondary);
      border-radius: var(--radius);
      transition: all 0.15s;
    }

    .social-link:hover {
      color: var(--color-text);
      background: var(--color-bg-secondary);
    }

    .social-badge {
      display: inline-flex;
      align-items: center;
      gap: 0.375rem;
      padding: 0.375rem 0.75rem;
      background: var(--color-bg-secondary);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      color: var(--color-text-secondary);
      font-size: 0.8125rem;
      font-weight: 500;
      text-decoration: none;
      transition: all 0.15s;
    }

    .social-badge:hover {
      color: var(--color-text);
      border-color: var(--color-primary);
    }

    .social-badge svg {
      fill: #0175C2;
    }''';

  String _buildSyntaxHighlighting() => '''
    .hljs-comment, .hljs-quote { color: #6e7781; }
    .hljs-keyword, .hljs-selector-tag { color: #cf222e; }
    .hljs-string, .hljs-attr { color: #0a3069; }
    .hljs-number, .hljs-literal { color: #0550ae; }
    .hljs-variable, .hljs-template-variable { color: #953800; }
    .hljs-title, .hljs-section { color: #8250df; }
    .hljs-type, .hljs-built_in { color: #0550ae; }
    .hljs-name, .hljs-selector-id, .hljs-selector-class { color: #116329; }
    .hljs-addition { color: #116329; background: #dafbe1; }
    .hljs-deletion { color: #82071e; background: #ffebe9; }

    .dark .hljs-comment, .dark .hljs-quote { color: #8b949e; }
    .dark .hljs-keyword, .dark .hljs-selector-tag { color: #ff7b72; }
    .dark .hljs-string, .dark .hljs-attr { color: #a5d6ff; }
    .dark .hljs-number, .dark .hljs-literal { color: #79c0ff; }
    .dark .hljs-variable, .dark .hljs-template-variable { color: #ffa657; }
    .dark .hljs-title, .dark .hljs-section { color: #d2a8ff; }
    .dark .hljs-type, .dark .hljs-built_in { color: #79c0ff; }
    .dark .hljs-name, .dark .hljs-selector-id, .dark .hljs-selector-class { color: #7ee787; }''';

  String _buildResponsiveStyles() => '''
    @media (max-width: 1280px) {
      .main-container {
        grid-template-columns: 260px 1fr;
      }
      .toc {
        display: none;
      }
    }

    @media (max-width: 768px) {
      .main-container {
        grid-template-columns: 1fr;
      }
      .sidebar {
        display: none;
      }
      .content {
        padding: 1.5rem;
      }
      .search-button {
        min-width: auto;
        padding: 0.5rem 0.625rem;
        gap: 0.5rem;
      }
      .search-button span {
        display: none;
      }
      .search-modal {
        padding-top: 5vh;
      }
      .search-container {
        width: 95%;
        max-height: 80vh;
      }
    }''';
}
