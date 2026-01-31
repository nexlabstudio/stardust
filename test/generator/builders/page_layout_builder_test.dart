import 'package:stardust/src/config/config.dart';
import 'package:stardust/src/content/markdown_parser.dart';
import 'package:stardust/src/generator/builders/page_layout_builder.dart';
import 'package:stardust/src/models/page.dart';
import 'package:test/test.dart';

void main() {
  group('PageLayoutBuilder', () {
    late PageLayoutBuilder builder;

    group('with minimal config', () {
      setUp(() {
        const config = StardustConfig(name: 'Test Site');
        builder = PageLayoutBuilder(config: config);
      });

      test('buildHeader includes site name as logo', () {
        final result = builder.buildHeader();

        expect(result, contains('class="header"'));
        expect(result, contains('class="logo"'));
        expect(result, contains('Test Site'));
      });

      test('buildHeader includes search button when enabled', () {
        final result = builder.buildHeader();

        expect(result, contains('search-button'));
        expect(result, contains('id="search-trigger"'));
      });

      test('buildHeader includes theme toggle when dark mode enabled', () {
        final result = builder.buildHeader();

        expect(result, contains('theme-toggle'));
        expect(result, contains('id="theme-toggle"'));
      });

      test('buildFooter includes powered by message', () {
        final result = builder.buildFooter();

        expect(result, contains('class="footer"'));
        expect(result, contains('Powered by'));
        expect(result, contains('nexlabstudio/stardust'));
      });

      test('buildToc returns empty toc wrapper when disabled', () {
        const configNoToc = StardustConfig(
          name: 'Test',
          toc: TocConfig(enabled: false),
        );
        final builderNoToc = PageLayoutBuilder(config: configNoToc);

        final result = builderNoToc.buildToc([]);

        expect(result, equals('<aside class="toc"></aside>'));
      });

      test('buildToc returns empty wrapper when no entries', () {
        final result = builder.buildToc([]);

        expect(result, equals('<aside class="toc"></aside>'));
      });

      test('buildToc renders TOC entries', () {
        const entries = [
          TocEntry(level: 2, text: 'Introduction', id: 'introduction'),
          TocEntry(level: 3, text: 'Getting Started', id: 'getting-started'),
        ];

        final result = builder.buildToc(entries);

        expect(result, contains('class="toc"'));
        expect(result, contains('toc-title'));
        expect(result, contains('toc-list'));
        expect(result, contains('href="#introduction"'));
        expect(result, contains('Introduction'));
        expect(result, contains('data-level="2"'));
        expect(result, contains('href="#getting-started"'));
        expect(result, contains('data-level="3"'));
      });
    });

    group('buildHeader with navigation', () {
      test('renders nav links', () {
        const config = StardustConfig(
          name: 'Test',
          nav: [
            NavItem(label: 'Home', href: '/'),
            NavItem(label: 'Docs', href: '/docs'),
          ],
        );
        final builderWithNav = PageLayoutBuilder(config: config);

        final result = builderWithNav.buildHeader();

        expect(result, contains('class="nav"'));
        expect(result, contains('href="/"'));
        expect(result, contains('Home'));
        expect(result, contains('href="/docs"'));
        expect(result, contains('Docs'));
      });

      test('adds external attributes for external links', () {
        const config = StardustConfig(
          name: 'Test',
          nav: [
            NavItem(label: 'GitHub', href: 'https://github.com', external: true),
          ],
        );
        final builderWithExternalNav = PageLayoutBuilder(config: config);

        final result = builderWithExternalNav.buildHeader();

        expect(result, contains('target="_blank"'));
        expect(result, contains('rel="noopener"'));
      });
    });

    group('buildHeader with social links', () {
      test('renders pub.dev badge', () {
        const config = StardustConfig(
          name: 'Test',
          social: SocialConfig(pubdev: 'https://pub.dev/packages/test'),
        );
        final builderWithSocial = PageLayoutBuilder(config: config);

        final result = builderWithSocial.buildHeader();

        expect(result, contains('social-badge'));
        expect(result, contains('href="https://pub.dev/packages/test"'));
        expect(result, contains('pub.dev'));
      });

      test('renders GitHub link', () {
        const config = StardustConfig(
          name: 'Test',
          social: SocialConfig(github: 'https://github.com/user/repo'),
        );
        final builderWithSocial = PageLayoutBuilder(config: config);

        final result = builderWithSocial.buildHeader();

        expect(result, contains('social-link'));
        expect(result, contains('href="https://github.com/user/repo"'));
        expect(result, contains('aria-label="GitHub"'));
      });

      test('renders Discord link', () {
        const config = StardustConfig(
          name: 'Test',
          social: SocialConfig(discord: 'https://discord.gg/test'),
        );
        final builderWithSocial = PageLayoutBuilder(config: config);

        final result = builderWithSocial.buildHeader();

        expect(result, contains('href="https://discord.gg/test"'));
        expect(result, contains('aria-label="Discord"'));
      });
    });

    group('buildSidebar', () {
      test('renders sidebar with groups', () {
        const sidebar = [
          SidebarGroup(group: 'Getting Started', pages: [
            SidebarPage(slug: 'intro'),
            SidebarPage(slug: 'installation', label: 'Install'),
          ]),
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'basics'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/intro');

        expect(result, contains('class="sidebar"'));
        expect(result, contains('sidebar-group'));
        expect(result, contains('sidebar-group-title'));
        expect(result, contains('Getting Started'));
        expect(result, contains('Guide'));
        expect(result, contains('sidebar-links'));
        expect(result, contains('href="/intro"'));
        expect(result, contains('href="/installation"'));
        expect(result, contains('Install')); // Uses label
        expect(result, contains('href="/basics"'));
      });

      test('marks current page as active', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'page1'),
            SidebarPage(slug: 'page2'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/page1');

        expect(result, contains('sidebar-link active'));
      });

      test('marks index page as active for root path', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'index'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/');

        expect(result, contains('sidebar-link active'));
      });

      test('generates root path href for index slug', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'index', label: 'Home'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('href="/"'));
        expect(result, isNot(contains('href="/index"')));
      });

      test('converts slug to title case when no label', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'getting-started'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('Getting Started'));
      });

      test('renders emoji icon when set', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', icon: '🚀', pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('sidebar-group-icon'));
        expect(result, contains('🚀'));
      });

      test('renders Lucide icon when set', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', icon: 'rocket', pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('sidebar-group-icon'));
        expect(result, contains('data-lucide="rocket"'));
      });

      test('does not render icon when null', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, isNot(contains('sidebar-group-icon')));
      });

      test('renders collapsible group with chevron', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('data-collapsible="true"'));
        expect(result, contains('sidebar-chevron'));
      });

      test('does not render collapsible for empty group', () {
        const sidebar = [
          SidebarGroup(group: 'Empty'),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, isNot(contains('data-collapsible')));
        expect(result, isNot(contains('sidebar-chevron')));
      });

      test('adds collapsed class when collapsed is true', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', collapsed: true, pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('sidebar-group collapsed'));
      });

      test('forces expand when collapsed group contains active page', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', collapsed: true, pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/intro');

        expect(result, isNot(contains('sidebar-group collapsed')));
      });

      test('renders group label wrapper', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('sidebar-group-label'));
        expect(result, contains('Guide'));
      });
    });

    group('buildEditLink', () {
      test('returns empty when editLink not configured', () {
        final result = builder.buildEditLink(const Page(
          path: '/test',
          sourcePath: '/docs/test.md',
          title: 'Test',
          content: '',
          toc: [],
          frontmatter: {},
        ));

        expect(result, isEmpty);
      });

      test('returns empty when editLink disabled', () {
        const config = StardustConfig(
          name: 'Test',
          integrations: IntegrationsConfig(
            editLink: EditLinkConfig(
              enabled: false,
              repo: 'https://github.com/user/repo',
            ),
          ),
        );
        final builderWithEditLink = PageLayoutBuilder(config: config);

        final result = builderWithEditLink.buildEditLink(const Page(
          path: '/test',
          sourcePath: '/docs/test.md',
          title: 'Test',
          content: '',
          toc: [],
          frontmatter: {},
        ));

        expect(result, isEmpty);
      });

      test('returns empty when repo not configured', () {
        const config = StardustConfig(
          name: 'Test',
          integrations: IntegrationsConfig(
            editLink: EditLinkConfig(enabled: true),
          ),
        );
        final builderWithEditLink = PageLayoutBuilder(config: config);

        final result = builderWithEditLink.buildEditLink(const Page(
          path: '/test',
          sourcePath: '/docs/test.md',
          title: 'Test',
          content: '',
          toc: [],
          frontmatter: {},
        ));

        expect(result, isEmpty);
      });

      test('builds edit link with proper URL', () {
        const config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: 'docs/'),
          integrations: IntegrationsConfig(
            editLink: EditLinkConfig(
              enabled: true,
              repo: 'https://github.com/user/repo',
              branch: 'main',
              path: 'content',
              text: 'Edit on GitHub',
            ),
          ),
        );
        final builderWithEditLink = PageLayoutBuilder(config: config);

        final result = builderWithEditLink.buildEditLink(const Page(
          path: '/guide/intro',
          sourcePath: '/project/docs/guide/intro.md',
          title: 'Intro',
          content: '',
          toc: [],
          frontmatter: {},
        ));

        expect(result, contains('class="edit-link"'));
        expect(result, contains('Edit on GitHub'));
        expect(result, contains('target="_blank"'));
        expect(result, contains('rel="noopener"'));
      });

      test('constructs path from page path when sourcePath does not contain contentDir', () {
        const config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: 'content/'),
          integrations: IntegrationsConfig(
            editLink: EditLinkConfig(
              enabled: true,
              repo: 'https://github.com/user/repo',
              branch: 'develop',
              path: 'docs/',
            ),
          ),
        );
        final builderWithEditLink = PageLayoutBuilder(config: config);

        final result = builderWithEditLink.buildEditLink(const Page(
          path: '/guide',
          sourcePath: '/other/path/guide.md',
          title: 'Guide',
          content: '',
          toc: [],
          frontmatter: {},
        ));

        expect(result, contains('/edit/develop/docs/'));
      });

      test('strips leading slash from relativePath when present', () {
        const config = StardustConfig(
          name: 'Test',
          content: ContentConfig(dir: 'docs'),
          integrations: IntegrationsConfig(
            editLink: EditLinkConfig(
              enabled: true,
              repo: 'https://github.com/user/repo',
              branch: 'main',
              path: 'content',
            ),
          ),
        );
        final builderWithEditLink = PageLayoutBuilder(config: config);

        // sourcePath contains 'docs' followed by a path starting with '/'
        final result = builderWithEditLink.buildEditLink(const Page(
          path: '/guide/intro',
          sourcePath: '/project/docs/guide/intro.md',
          title: 'Intro',
          content: '',
          toc: [],
          frontmatter: {},
        ));

        expect(result, contains('/edit/main/content/guide/intro.md'));
        expect(result, isNot(contains('content//guide'))); // No double slash
      });
    });

    group('buildPageNav', () {
      test('renders empty nav when no prev/next', () {
        const page = Page(
          path: '/test',
          sourcePath: '/test.md',
          title: 'Test',
          content: '',
          toc: [],
          frontmatter: {},
        );

        final result = builder.buildPageNav(page);

        expect(result, contains('class="page-nav"'));
        expect(result, contains('<div></div>')); // Empty placeholders
      });

      test('renders prev link when available', () {
        const page = Page(
          path: '/page2',
          sourcePath: '/page2.md',
          title: 'Page 2',
          content: '',
          toc: [],
          frontmatter: {},
          prev: PageLink(path: '/page1', title: 'Page 1'),
        );

        final result = builder.buildPageNav(page);

        expect(result, contains('page-nav-link prev'));
        expect(result, contains('href="/page1"'));
        expect(result, contains('← Previous'));
        expect(result, contains('Page 1'));
      });

      test('renders next link when available', () {
        const page = Page(
          path: '/page1',
          sourcePath: '/page1.md',
          title: 'Page 1',
          content: '',
          toc: [],
          frontmatter: {},
          next: PageLink(path: '/page2', title: 'Page 2'),
        );

        final result = builder.buildPageNav(page);

        expect(result, contains('page-nav-link next'));
        expect(result, contains('href="/page2"'));
        expect(result, contains('Next →'));
        expect(result, contains('Page 2'));
      });

      test('renders both prev and next links', () {
        const page = Page(
          path: '/page2',
          sourcePath: '/page2.md',
          title: 'Page 2',
          content: '',
          toc: [],
          frontmatter: {},
          prev: PageLink(path: '/page1', title: 'Page 1'),
          next: PageLink(path: '/page3', title: 'Page 3'),
        );

        final result = builder.buildPageNav(page);

        expect(result, contains('prev'));
        expect(result, contains('next'));
        expect(result, contains('Page 1'));
        expect(result, contains('Page 3'));
      });
    });

    group('buildFooter with social links', () {
      test('renders social links in footer', () {
        const config = StardustConfig(
          name: 'Test',
          social: SocialConfig(
            github: 'https://github.com/test',
            twitter: 'https://twitter.com/test',
            discord: 'https://discord.gg/test',
            pubdev: 'https://pub.dev/packages/test',
          ),
        );
        final builderWithSocial = PageLayoutBuilder(config: config);

        final result = builderWithSocial.buildFooter();

        expect(result, contains('footer-social'));
        expect(result, contains('footer-social-link'));
        expect(result, contains('aria-label="GitHub"'));
        expect(result, contains('aria-label="Twitter"'));
        expect(result, contains('aria-label="Discord"'));
        expect(result, contains('aria-label="pub.dev"'));
      });

      test('returns empty social div when no links', () {
        const config = StardustConfig(name: 'Test');
        final builderNoSocial = PageLayoutBuilder(config: config);

        final result = builderNoSocial.buildFooter();

        expect(result, isNot(contains('footer-social">')));
      });
    });

    group('buildHeader with logo', () {
      test('returns empty logo when not configured', () {
        const config = StardustConfig(name: 'Test Site');
        final builderNoLogo = PageLayoutBuilder(config: config);

        final result = builderNoLogo.buildHeader();

        expect(result, isNot(contains('logo-image')));
      });

      test('renders single logo image when only single is set', () {
        const config = StardustConfig(
          name: 'Test Site',
          logo: LogoConfig(single: '/images/logo.svg'),
        );
        final builderWithLogo = PageLayoutBuilder(config: config);

        final result = builderWithLogo.buildHeader();

        expect(result, contains('logo-image'));
        expect(result, contains('src="/images/logo.svg"'));
        expect(result, contains('alt="Test Site"'));
        expect(result, isNot(contains('logo-light')));
        expect(result, isNot(contains('logo-dark')));
      });

      test('renders separate light and dark logos when both differ', () {
        const config = StardustConfig(
          name: 'Test Site',
          logo: LogoConfig(
            light: '/images/logo-light.svg',
            dark: '/images/logo-dark.svg',
          ),
        );
        final builderWithLogo = PageLayoutBuilder(config: config);

        final result = builderWithLogo.buildHeader();

        expect(result, contains('logo-image logo-light'));
        expect(result, contains('logo-image logo-dark'));
        expect(result, contains('src="/images/logo-light.svg"'));
        expect(result, contains('src="/images/logo-dark.svg"'));
      });

      test('renders single logo when light and dark are the same', () {
        const config = StardustConfig(
          name: 'Test Site',
          logo: LogoConfig(
            light: '/images/logo.svg',
            dark: '/images/logo.svg',
          ),
        );
        final builderWithLogo = PageLayoutBuilder(config: config);

        final result = builderWithLogo.buildHeader();

        expect(result, contains('logo-image'));
        expect(result, isNot(contains('logo-light')));
        expect(result, isNot(contains('logo-dark')));
      });

      test('returns empty logo when only dark is set without single', () {
        const config = StardustConfig(
          name: 'Test Site',
          logo: LogoConfig(dark: '/images/logo-dark.svg'),
        );
        final builderWithLogo = PageLayoutBuilder(config: config);

        final result = builderWithLogo.buildHeader();

        // effectiveLight is null, so no logo rendered
        expect(result, isNot(contains('logo-image')));
      });

      test('prepends basePath to logo src', () {
        const config = StardustConfig(
          name: 'Test Site',
          build: BuildConfig(basePath: '/docs'),
          logo: LogoConfig(single: '/images/logo.svg'),
        );
        final builderWithLogo = PageLayoutBuilder(config: config);

        final result = builderWithLogo.buildHeader();

        expect(result, contains('src="/docs/images/logo.svg"'));
      });
    });

    group('mobile menu', () {
      test('header includes mobile menu toggle button', () {
        final result = builder.buildHeader();

        expect(result, contains('mobile-menu-toggle'));
        expect(result, contains('id="mobile-menu-toggle"'));
        expect(result, contains('aria-label="Toggle menu"'));
      });

      test('mobile menu toggle has hamburger icon', () {
        final result = builder.buildHeader();

        expect(result, contains('<line x1="3" y1="6"'));
        expect(result, contains('<line x1="3" y1="12"'));
        expect(result, contains('<line x1="3" y1="18"'));
      });

      test('hamburger is before logo in header', () {
        final result = builder.buildHeader();

        final hamburgerIndex = result.indexOf('mobile-menu-toggle');
        final logoIndex = result.indexOf('class="logo"');
        expect(hamburgerIndex, lessThan(logoIndex));
      });

      test('sidebar contains close button', () {
        const sidebar = [
          SidebarGroup(group: 'Guide', pages: [
            SidebarPage(slug: 'intro'),
          ]),
        ];

        final result = builder.buildSidebar(sidebar, '/other');

        expect(result, contains('sidebar-close'));
        expect(result, contains('id="sidebar-close"'));
        expect(result, contains('aria-label="Close menu"'));
      });
    });

    group('footer links', () {
      test('renders footer link groups when configured', () {
        const config = StardustConfig(
          name: 'Test',
          footer: FooterConfig(links: [
            FooterLinkGroup(group: 'Product', items: [
              FooterLink(label: 'Docs', href: '/docs'),
              FooterLink(label: 'Pricing', href: '/pricing'),
            ]),
            FooterLinkGroup(group: 'Company', items: [
              FooterLink(label: 'About', href: '/about'),
            ]),
          ]),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildFooter();

        expect(result, contains('footer-links'));
        expect(result, contains('footer-link-group'));
        expect(result, contains('footer-link-group-title'));
        expect(result, contains('Product'));
        expect(result, contains('Company'));
      });

      test('renders links with correct href', () {
        const config = StardustConfig(
          name: 'Test',
          footer: FooterConfig(links: [
            FooterLinkGroup(group: 'Nav', items: [
              FooterLink(label: 'Home', href: '/'),
            ]),
          ]),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildFooter();

        expect(result, contains('href="/"'));
        expect(result, contains('Home'));
      });

      test('renders copyright when configured', () {
        const config = StardustConfig(
          name: 'Test',
          footer: FooterConfig(copyright: '© 2024 Acme'),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildFooter();

        expect(result, contains('footer-copyright'));
        expect(result, contains('© 2024 Acme'));
      });

      test('does not render footer-links when no links configured', () {
        final result = builder.buildFooter();

        expect(result, isNot(contains('footer-links')));
      });

      test('does not render copyright when not configured', () {
        final result = builder.buildFooter();

        expect(result, isNot(contains('footer-copyright')));
      });
    });

    group('announcement', () {
      test('renders announcement bar when configured', () {
        const config = StardustConfig(
          name: 'Test',
          header: HeaderConfig(
            announcement: AnnouncementConfig(text: 'Hello world'),
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('announcement'));
        expect(result, contains('Hello world'));
      });

      test('renders as link when link is set', () {
        const config = StardustConfig(
          name: 'Test',
          header: HeaderConfig(
            announcement: AnnouncementConfig(text: 'New!', link: '/blog'),
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('<a href="/blog"'));
        expect(result, contains('announcement-content'));
      });

      test('renders as span when no link', () {
        const config = StardustConfig(
          name: 'Test',
          header: HeaderConfig(
            announcement: AnnouncementConfig(text: 'Notice'),
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('<span class="announcement-content">'));
      });

      test('includes dismiss button when dismissible', () {
        const config = StardustConfig(
          name: 'Test',
          header: HeaderConfig(
            announcement: AnnouncementConfig(text: 'Hi', dismissible: true),
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('announcement-dismiss'));
      });

      test('omits dismiss button when not dismissible', () {
        const config = StardustConfig(
          name: 'Test',
          header: HeaderConfig(
            announcement: AnnouncementConfig(text: 'Hi', dismissible: false),
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, isNot(contains('announcement-dismiss')));
      });

      test('applies correct style class', () {
        const config = StardustConfig(
          name: 'Test',
          header: HeaderConfig(
            announcement: AnnouncementConfig(text: 'Warn', style: 'warning'),
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('announcement-warning'));
      });

      test('does not render announcement when not configured', () {
        final result = builder.buildHeader();

        expect(result, isNot(contains('announcement')));
      });
    });

    group('version dropdown', () {
      test('renders dropdown when versions enabled', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '2.0',
            dropdown: true,
            list: [
              VersionEntry(version: '2.0', label: 'v2.0 (Latest)', path: '/v2/'),
              VersionEntry(version: '1.0', path: '/v1/'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('version-dropdown'));
        expect(result, contains('version-dropdown-trigger'));
        expect(result, contains('version-dropdown-menu'));
      });

      test('does not render when versions not configured', () {
        final result = builder.buildHeader();

        expect(result, isNot(contains('version-dropdown')));
      });

      test('does not render when dropdown is false', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '2.0',
            dropdown: false,
            list: [
              VersionEntry(version: '2.0', path: '/v2/'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, isNot(contains('version-dropdown')));
      });

      test('shows current version label', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '2.0',
            list: [
              VersionEntry(version: '2.0', label: 'Latest', path: '/v2/'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('Latest'));
      });

      test('falls back to v{version} when no label', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '1.0',
            list: [
              VersionEntry(version: '1.0', path: '/v1/'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('v1.0'));
      });

      test('lists all versions with correct paths', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '2.0',
            list: [
              VersionEntry(version: '2.0', path: '/v2/'),
              VersionEntry(version: '1.0', path: '/v1/'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('href="/v2/"'));
        expect(result, contains('href="/v1/"'));
      });

      test('marks current version as active', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '2.0',
            list: [
              VersionEntry(version: '2.0', label: 'v2.0', path: '/v2/'),
              VersionEntry(version: '1.0', label: 'v1.0', path: '/v1/'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('version-dropdown-item active'));
      });
    });

    group('version banner', () {
      test('renders banner when current version has banner text', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '1.0',
            list: [
              VersionEntry(version: '1.0', path: '/v1/', banner: 'This is an old version.'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('version-banner'));
        expect(result, contains('This is an old version.'));
      });

      test('does not render when no banner text', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '2.0',
            list: [
              VersionEntry(version: '2.0', path: '/v2/'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, isNot(contains('version-banner')));
      });

      test('does not render when versions not configured', () {
        final result = builder.buildHeader();

        expect(result, isNot(contains('version-banner')));
      });

      test('includes dismiss button', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '1.0',
            list: [
              VersionEntry(version: '1.0', path: '/v1/', banner: 'Old version'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('version-banner-dismiss'));
      });

      test('contains data-version attribute', () {
        const config = StardustConfig(
          name: 'Test',
          versions: VersionsConfig(
            enabled: true,
            current: '1.0',
            list: [
              VersionEntry(version: '1.0', path: '/v1/', banner: 'Old version'),
            ],
          ),
        );
        final b = PageLayoutBuilder(config: config);

        final result = b.buildHeader();

        expect(result, contains('data-version="1.0"'));
      });
    });

    group('header with disabled features', () {
      test('hides search when disabled', () {
        const config = StardustConfig(
          name: 'Test',
          search: SearchConfig(enabled: false),
        );
        final builderNoSearch = PageLayoutBuilder(config: config);

        final result = builderNoSearch.buildHeader();

        expect(result, isNot(contains('search-button')));
      });

      test('hides theme toggle when dark mode disabled', () {
        const config = StardustConfig(
          name: 'Test',
          theme: ThemeConfig(darkMode: DarkModeConfig(enabled: false)),
        );
        final builderNoDarkMode = PageLayoutBuilder(config: config);

        final result = builderNoDarkMode.buildHeader();

        expect(result, isNot(contains('theme-toggle')));
      });
    });
  });
}
