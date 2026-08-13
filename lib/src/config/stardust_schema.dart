// GENERATED FILE — do not edit by hand.
// Source: schema/stardust.json. Regenerate with: dart run tool/embed_schema.dart

/// The stardust.yaml JSON schema, embedded so the config validator works
/// from the compiled binary without needing the schema file on disk.
const stardustSchemaJson = r'''
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://stardust.nexlab.studio/schemas/stardust.json",
  "title": "Stardust Configuration",
  "description": "Configuration schema for Stardust documentation generator",
  "type": "object",
  "required": [
    "name"
  ],
  "additionalProperties": false,
  "properties": {
    "name": {
      "type": "string",
      "description": "The name of your documentation site"
    },
    "description": {
      "type": "string",
      "description": "A brief description of your project"
    },
    "tagline": {
      "type": "string",
      "description": "A catchy tagline for your project"
    },
    "logo": {
      "oneOf": [
        {
          "type": "string",
          "description": "Path to logo file"
        },
        {
          "type": "object",
          "properties": {
            "light": {
              "type": "string",
              "description": "Logo for light mode"
            },
            "dark": {
              "type": "string",
              "description": "Logo for dark mode"
            }
          },
          "additionalProperties": false
        }
      ]
    },
    "favicon": {
      "type": "string",
      "description": "Path to favicon file"
    },
    "url": {
      "type": "string",
      "format": "uri",
      "description": "Production URL of your documentation site"
    },
    "content": {
      "type": "object",
      "description": "Content source configuration",
      "additionalProperties": false,
      "properties": {
        "dir": {
          "type": "string",
          "default": "docs/",
          "description": "Directory where markdown files live"
        },
        "index": {
          "type": "string",
          "default": "index.md",
          "description": "Landing page file"
        },
        "include": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "default": [
            "*.md",
            "**/*.md",
            "*.mdx",
            "**/*.mdx"
          ],
          "description": "Glob patterns for files to include"
        },
        "exclude": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "default": [],
          "description": "Glob patterns for files to exclude"
        }
      }
    },
    "nav": {
      "type": "array",
      "description": "Top navigation items",
      "items": {
        "$ref": "#/$defs/navItem"
      }
    },
    "sidebar": {
      "type": "array",
      "description": "Sidebar navigation structure",
      "items": {
        "$ref": "#/$defs/sidebarGroup"
      }
    },
    "toc": {
      "type": "object",
      "description": "Table of contents configuration",
      "additionalProperties": false,
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": true
        },
        "minDepth": {
          "type": "integer",
          "minimum": 1,
          "maximum": 6,
          "default": 2
        },
        "maxDepth": {
          "type": "integer",
          "minimum": 1,
          "maximum": 6,
          "default": 4
        },
        "title": {
          "type": "string",
          "default": "On this page"
        }
      }
    },
    "theme": {
      "type": "object",
      "description": "Theme configuration",
      "additionalProperties": false,
      "properties": {
        "colors": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "primary": {
              "type": "string",
              "pattern": "^#[0-9a-fA-F]{6}$"
            },
            "secondary": {
              "type": "string",
              "pattern": "^#[0-9a-fA-F]{6}$"
            },
            "accent": {
              "type": "string",
              "pattern": "^#[0-9a-fA-F]{6}$"
            },
            "background": {
              "type": "object",
              "properties": {
                "light": {
                  "type": "string"
                },
                "dark": {
                  "type": "string"
                }
              },
              "additionalProperties": false
            },
            "text": {
              "type": "object",
              "properties": {
                "light": {
                  "type": "string"
                },
                "dark": {
                  "type": "string"
                }
              },
              "additionalProperties": false
            }
          }
        },
        "darkMode": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": true
            },
            "default": {
              "type": "string",
              "enum": [
                "light",
                "dark",
                "system"
              ],
              "default": "system"
            }
          }
        },
        "fonts": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "sans": {
              "type": "string",
              "default": "Inter"
            },
            "mono": {
              "type": "string",
              "default": "JetBrains Mono"
            },
            "source": {
              "type": "string",
              "enum": [
                "google",
                "local"
              ],
              "default": "google",
              "description": "Where fonts load from. \"local\" emits no font links (air-gapped); supply @font-face via theme.custom."
            }
          }
        },
        "radius": {
          "type": "string",
          "default": "8px"
        },
        "custom": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "css": {
              "type": "string",
              "description": "Inline custom CSS styles"
            },
            "cssFile": {
              "type": "string",
              "description": "Path to a custom CSS file"
            }
          }
        },
        "tokens": {
          "type": "object",
          "description": "Design-token overrides applied in :root (light). Keys are token names without the leading -- (e.g. color-border)",
          "additionalProperties": {
            "type": "string"
          }
        },
        "tokensDark": {
          "type": "object",
          "description": "Design-token overrides applied in .dark",
          "additionalProperties": {
            "type": "string"
          }
        },
        "slots": {
          "type": "object",
          "description": "Raw HTML injected into the header, footer, and sidebar regions",
          "additionalProperties": false,
          "properties": {
            "header": {
              "type": "string"
            },
            "footer": {
              "type": "string"
            },
            "sidebar": {
              "type": "string"
            }
          }
        }
      }
    },
    "code": {
      "type": "object",
      "description": "Code block configuration",
      "additionalProperties": false,
      "properties": {
        "theme": {
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "light": {
                  "type": "string"
                },
                "dark": {
                  "type": "string"
                }
              },
              "additionalProperties": false
            }
          ],
          "default": {
            "light": "github-light",
            "dark": "github-dark"
          }
        },
        "lineNumbers": {
          "type": "boolean",
          "default": false
        },
        "copyButton": {
          "type": "boolean",
          "default": true
        },
        "wrapLongLines": {
          "type": "boolean",
          "default": false
        },
        "defaultLanguage": {
          "type": "string",
          "default": "plaintext"
        },
        "aliases": {
          "type": "object",
          "additionalProperties": {
            "type": "string"
          }
        }
      }
    },
    "components": {
      "type": "object",
      "description": "Component configuration",
      "additionalProperties": false,
      "properties": {
        "callouts": {
          "type": "object",
          "additionalProperties": {
            "$ref": "#/$defs/calloutConfig"
          }
        },
        "mermaid": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "scriptUrl": {
              "type": "string",
              "description": "Mermaid renderer script URL. Point at a self-hosted copy for air-gapped sites."
            }
          }
        }
      }
    },
    "search": {
      "type": "object",
      "description": "Search configuration",
      "additionalProperties": false,
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": true
        },
        "placeholder": {
          "type": "string",
          "default": "Search docs..."
        },
        "hotkey": {
          "type": "string",
          "default": "/"
        },
        "pageSize": {
          "type": "integer",
          "minimum": 1,
          "default": 8,
          "description": "Number of search results rendered per page (with a Load more button)."
        }
      }
    },
    "seo": {
      "type": "object",
      "description": "SEO configuration",
      "additionalProperties": false,
      "properties": {
        "titleTemplate": {
          "type": "string",
          "default": "%s"
        },
        "ogImage": {
          "type": "string"
        },
        "twitterCard": {
          "type": "string",
          "enum": [
            "summary",
            "summary_large_image"
          ],
          "default": "summary_large_image"
        },
        "twitterHandle": {
          "type": "string"
        },
        "structuredData": {
          "type": "boolean",
          "default": true
        }
      }
    },
    "social": {
      "type": "object",
      "description": "Social links",
      "additionalProperties": false,
      "properties": {
        "github": {
          "type": "string",
          "format": "uri"
        },
        "discord": {
          "type": "string",
          "format": "uri"
        },
        "twitter": {
          "type": "string",
          "format": "uri"
        },
        "youtube": {
          "type": "string",
          "format": "uri"
        },
        "linkedin": {
          "type": "string",
          "format": "uri"
        },
        "mastodon": {
          "type": "string",
          "format": "uri"
        },
        "slack": {
          "type": "string",
          "format": "uri"
        },
        "pubdev": {
          "type": "string",
          "format": "uri"
        }
      }
    },
    "header": {
      "type": "object",
      "description": "Header configuration",
      "additionalProperties": false,
      "properties": {
        "showName": {
          "type": "boolean",
          "default": true
        },
        "showSearch": {
          "type": "boolean",
          "default": true
        },
        "showThemeToggle": {
          "type": "boolean",
          "default": true
        },
        "showSocial": {
          "type": "boolean",
          "default": true
        },
        "announcement": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "text": {
              "type": "string"
            },
            "link": {
              "type": "string"
            },
            "dismissible": {
              "type": "boolean",
              "default": true
            },
            "style": {
              "type": "string",
              "enum": [
                "info",
                "warning",
                "success"
              ],
              "default": "info"
            }
          },
          "required": [
            "text"
          ]
        }
      }
    },
    "pageInfo": {
      "type": "object",
      "description": "Per-page metadata shown near the article",
      "additionalProperties": false,
      "properties": {
        "readingTime": {
          "type": "boolean",
          "default": false,
          "description": "Show estimated reading time"
        },
        "lastUpdated": {
          "type": "boolean",
          "default": false,
          "description": "Show the last-updated date from git"
        },
        "contributors": {
          "type": "boolean",
          "default": false,
          "description": "Show contributors from git"
        }
      }
    },
    "footer": {
      "type": "object",
      "description": "Footer configuration",
      "additionalProperties": false,
      "properties": {
        "copyright": {
          "type": "string"
        },
        "poweredBy": {
          "type": "boolean",
          "default": true,
          "description": "Show the \"Powered by Stardust\" footer badge"
        },
        "links": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "group": {
                "type": "string"
              },
              "items": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "label": {
                      "type": "string"
                    },
                    "href": {
                      "type": "string"
                    }
                  },
                  "required": [
                    "label",
                    "href"
                  ],
                  "additionalProperties": false
                }
              }
            },
            "required": [
              "group",
              "items"
            ]
          }
        }
      }
    },
    "versions": {
      "type": "object",
      "description": "Versioning configuration",
      "additionalProperties": false,
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "current": {
          "type": "string"
        },
        "default": {
          "type": "string"
        },
        "dropdown": {
          "type": "boolean",
          "default": true
        },
        "list": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "version": {
                "type": "string"
              },
              "label": {
                "type": "string"
              },
              "path": {
                "type": "string"
              },
              "banner": {
                "type": "string"
              },
              "sidebar": {
                "type": "array",
                "description": "Sidebar for this version, replacing the shared one. Defaults to the shared sidebar narrowed to the pages this version has",
                "items": {
                  "$ref": "#/$defs/sidebarGroup"
                }
              },
              "source": {
                "description": "Where this version's content comes from under --all-versions: a content directory, or a git ref checked out at build time. Defaults to the live content.dir",
                "oneOf": [
                  {
                    "type": "string"
                  },
                  {
                    "type": "object",
                    "additionalProperties": false,
                    "properties": {
                      "tag": {
                        "type": "string"
                      },
                      "ref": {
                        "type": "string"
                      }
                    }
                  }
                ]
              }
            },
            "required": [
              "version",
              "path"
            ]
          }
        }
      }
    },
    "i18n": {
      "type": "object",
      "description": "Internationalization configuration",
      "additionalProperties": false,
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "defaultLocale": {
          "type": "string",
          "default": "en"
        },
        "locales": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "code": {
                "type": "string"
              },
              "label": {
                "type": "string"
              },
              "dir": {
                "type": "string",
                "enum": [
                  "ltr",
                  "rtl"
                ],
                "default": "ltr"
              },
              "path": {
                "type": "string",
                "description": "URL path where this locale is deployed (e.g. /en/)"
              },
              "source": {
                "type": "string",
                "description": "Directory holding this locale's translations. Defaults to <content.dir>/<code>; untranslated pages fall back to the default locale"
              },
              "sidebar": {
                "type": "array",
                "description": "Sidebar for this locale, replacing the shared one — used to translate group titles and page labels",
                "items": {
                  "$ref": "#/$defs/sidebarGroup"
                }
              },
              "strings": {
                "$ref": "#/$defs/i18nStrings"
              }
            },
            "required": [
              "code",
              "label",
              "path"
            ]
          }
        },
        "strings": {
          "$ref": "#/$defs/i18nStrings"
        }
      }
    },
    "integrations": {
      "type": "object",
      "description": "Third-party integrations",
      "additionalProperties": false,
      "properties": {
        "editLink": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": false
            },
            "repo": {
              "type": "string",
              "format": "uri"
            },
            "branch": {
              "type": "string",
              "default": "main"
            },
            "path": {
              "type": "string",
              "default": "docs/"
            },
            "text": {
              "type": "string",
              "default": "Edit this page on GitHub"
            }
          }
        },
        "lastUpdated": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": false
            },
            "format": {
              "type": "string",
              "default": "MMM d, yyyy"
            },
            "text": {
              "type": "string",
              "default": "Last updated"
            }
          }
        },
        "analytics": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "google": {
              "type": "string",
              "description": "Google Analytics measurement ID"
            },
            "plausible": {
              "type": "string",
              "description": "Plausible domain"
            },
            "posthog": {
              "type": "object",
              "properties": {
                "key": {
                  "type": "string"
                },
                "host": {
                  "type": "string",
                  "format": "uri"
                }
              },
              "required": [
                "key"
              ],
              "additionalProperties": false
            },
            "custom": {
              "type": "array",
              "description": "Custom analytics providers",
              "items": {
                "type": "object",
                "additionalProperties": false,
                "properties": {
                  "name": {
                    "type": "string",
                    "description": "Provider name for identification"
                  },
                  "src": {
                    "type": "string",
                    "description": "External script URL"
                  },
                  "script": {
                    "type": "string",
                    "description": "Inline script content"
                  },
                  "async": {
                    "type": "boolean",
                    "default": true
                  },
                  "defer": {
                    "type": "boolean",
                    "default": false
                  }
                },
                "required": [
                  "name"
                ],
                "oneOf": [
                  {
                    "required": [
                      "src"
                    ]
                  },
                  {
                    "required": [
                      "script"
                    ]
                  }
                ]
              }
            }
          }
        },
        "comments": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "provider": {
              "type": "string",
              "enum": [
                "giscus",
                "disqus"
              ]
            },
            "giscus": {
              "type": "object",
              "properties": {
                "repo": {
                  "type": "string"
                },
                "repoId": {
                  "type": "string"
                },
                "category": {
                  "type": "string"
                },
                "categoryId": {
                  "type": "string"
                }
              },
              "additionalProperties": false
            },
            "disqus": {
              "type": "object",
              "properties": {
                "shortname": {
                  "type": "string"
                }
              },
              "additionalProperties": false
            }
          }
        }
      }
    },
    "build": {
      "type": "object",
      "description": "Build configuration",
      "additionalProperties": false,
      "properties": {
        "outDir": {
          "type": "string",
          "default": "dist/"
        },
        "cleanUrls": {
          "type": "boolean",
          "default": true
        },
        "trailingSlash": {
          "type": "boolean",
          "default": false
        },
        "sitemap": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": true
            },
            "changefreq": {
              "type": "string",
              "enum": [
                "always",
                "hourly",
                "daily",
                "weekly",
                "monthly",
                "yearly",
                "never"
              ],
              "default": "weekly"
            },
            "priority": {
              "type": "number",
              "minimum": 0,
              "maximum": 1,
              "default": 0.7
            }
          }
        },
        "robots": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": true
            },
            "allow": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "default": [
                "/"
              ]
            },
            "disallow": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "default": []
            }
          }
        },
        "llms": {
          "type": "object",
          "description": "llms.txt generation for AI crawlers",
          "additionalProperties": false,
          "properties": {
            "enabled": {
              "type": "boolean",
              "default": true
            }
          }
        },
        "assets": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "dir": {
              "type": "string",
              "default": "public/"
            },
            "images": {
              "type": "object",
              "additionalProperties": false,
              "properties": {
                "optimize": {
                  "type": "boolean",
                  "default": false
                },
                "quality": {
                  "type": "integer",
                  "minimum": 1,
                  "maximum": 100,
                  "default": 80
                },
                "formats": {
                  "type": "array",
                  "items": {
                    "type": "string",
                    "enum": [
                      "webp",
                      "avif",
                      "original"
                    ]
                  },
                  "default": [
                    "original"
                  ]
                }
              }
            }
          }
        },
        "redirects": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "from": {
                "type": "string"
              },
              "to": {
                "type": "string"
              },
              "status": {
                "type": "integer",
                "enum": [
                  301,
                  302,
                  307,
                  308
                ],
                "default": 301
              }
            },
            "required": [
              "from",
              "to"
            ]
          }
        },
        "basePath": {
          "type": "string",
          "description": "Base path prefix when the site is served from a subdirectory (e.g. /docs). Derived from url if not set."
        }
      }
    },
    "dev": {
      "type": "object",
      "description": "Development server configuration",
      "additionalProperties": false,
      "properties": {
        "port": {
          "type": "integer",
          "default": 4000
        },
        "host": {
          "type": "string",
          "default": "localhost"
        },
        "open": {
          "type": "boolean",
          "default": true
        },
        "watch": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "default": [
            "docs/",
            "public/"
          ]
        }
      }
    }
  },
  "$defs": {
    "navItem": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "label": {
          "type": "string"
        },
        "href": {
          "type": "string"
        },
        "external": {
          "type": "boolean",
          "default": false
        },
        "icon": {
          "type": "string"
        }
      },
      "required": [
        "label",
        "href"
      ]
    },
    "sidebarGroup": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "group": {
          "type": "string",
          "description": "Group title"
        },
        "icon": {
          "type": "string"
        },
        "collapsed": {
          "type": "boolean",
          "default": false
        },
        "pages": {
          "type": "array",
          "items": {
            "oneOf": [
              {
                "type": "string",
                "description": "Page slug"
              },
              {
                "type": "object",
                "additionalProperties": false,
                "properties": {
                  "slug": {
                    "type": "string"
                  },
                  "label": {
                    "type": "string"
                  },
                  "icon": {
                    "type": "string",
                    "description": "Lucide icon name or emoji shown next to the page label"
                  }
                },
                "required": [
                  "slug"
                ]
              }
            ]
          }
        },
        "autogenerate": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "dir": {
              "type": "string"
            },
            "order": {
              "type": "string",
              "enum": [
                "alphabetical",
                "filename",
                "frontmatter"
              ],
              "default": "filename"
            }
          },
          "required": [
            "dir"
          ]
        }
      },
      "required": [
        "group"
      ]
    },
    "calloutConfig": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "icon": {
          "type": "string"
        },
        "color": {
          "type": "string"
        }
      }
    },
    "i18nStrings": {
      "type": "object",
      "description": "UI string overrides. At i18n.strings these are shared fallbacks; strings on a locale override them for that locale.",
      "additionalProperties": false,
      "properties": {
        "nav.previous": {
          "type": "string",
          "default": "← Previous",
          "description": "Label above the previous page title"
        },
        "nav.next": {
          "type": "string",
          "default": "Next →",
          "description": "Label above the next page title"
        },
        "toc.title": {
          "type": "string",
          "default": "On this page",
          "description": "Locale override for the table of contents heading; falls back to toc.title"
        },
        "footer.poweredBy": {
          "type": "string",
          "default": "Powered by",
          "description": "Powered-by label in the footer"
        },
        "theme.toggle": {
          "type": "string",
          "default": "Toggle dark mode",
          "description": "Accessible label for the theme toggle"
        },
        "menu.toggle": {
          "type": "string",
          "default": "Toggle menu",
          "description": "Accessible label for the mobile menu toggle"
        },
        "menu.close": {
          "type": "string",
          "default": "Close menu",
          "description": "Accessible label for the sidebar close button"
        },
        "announcement.dismiss": {
          "type": "string",
          "default": "Dismiss announcement",
          "description": "Accessible label for the announcement dismiss button"
        },
        "version.select": {
          "type": "string",
          "default": "Select version",
          "description": "Accessible label for the version selector"
        },
        "version.dismiss": {
          "type": "string",
          "default": "Dismiss banner",
          "description": "Accessible label for the version banner dismiss button"
        },
        "search.placeholder": {
          "type": "string",
          "default": "Search docs...",
          "description": "Locale override for the search trigger, dialog, and input label; falls back to search.placeholder"
        },
        "search.noResults": {
          "type": "string",
          "default": "No results found for \"%s\"",
          "description": "No-results message; %s is replaced by the query"
        },
        "search.oneResult": {
          "type": "string",
          "default": "1 result",
          "description": "Single-result count"
        },
        "search.manyResults": {
          "type": "string",
          "default": "%s results",
          "description": "Multiple-result count; %s is replaced by the count"
        },
        "search.searching": {
          "type": "string",
          "default": "Searching...",
          "description": "Search loading status"
        },
        "search.clear": {
          "type": "string",
          "default": "Clear search",
          "description": "Accessible label for the clear-search button"
        },
        "search.more": {
          "type": "string",
          "default": "Load more results",
          "description": "Label for the load-more-results button"
        },
        "search.unavailable": {
          "type": "string",
          "default": "Search is unavailable",
          "description": "Status shown when the search index cannot be loaded"
        },
        "code.copy": {
          "type": "string",
          "default": "Copy",
          "description": "Visible label for a code block's copy button"
        },
        "code.copyLabel": {
          "type": "string",
          "default": "Copy code",
          "description": "Accessible label for a code block's copy button"
        },
        "code.copied": {
          "type": "string",
          "default": "Copied!",
          "description": "Copy success feedback"
        },
        "code.copyFailed": {
          "type": "string",
          "default": "Copy failed",
          "description": "Copy failure feedback"
        },
        "locale.select": {
          "type": "string",
          "default": "Select language",
          "description": "Accessible label for the locale selector"
        },
        "locale.untranslated": {
          "type": "string",
          "default": "This page has not been translated yet.",
          "description": "Notice on pages that fall back to the default locale"
        },
        "page.copyMarkdown": {
          "type": "string",
          "default": "Copy page as Markdown",
          "description": "Label for the copy-page-as-Markdown button"
        },
        "page.readingTime": {
          "type": "string",
          "default": "%s min read",
          "description": "Reading-time label; %s is replaced by the number of minutes"
        },
        "page.lastUpdated": {
          "type": "string",
          "default": "Last updated %s",
          "description": "Last-updated label; %s is replaced by the date"
        },
        "dartdoc.api": {
          "type": "string",
          "default": "API",
          "description": "Badge in the Stardust bar on generated dartdoc pages"
        },
        "dartdoc.backToDocs": {
          "type": "string",
          "default": "← Back to docs",
          "description": "Link back to the documentation from generated dartdoc pages"
        }
      }
    }
  }
}
''';
