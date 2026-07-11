# Style Guide Registry

This is the living, tracked registry of **official, canonical style guides**
per language/platform — see `CODE_STYLE.md` for the principle this supports.

It is deliberately separate from `raw/` and `summaries/`. Those hold
copyrighted, static material (books, papers) that gets downloaded and
distilled once. Official style guides are the opposite: public web pages
maintained continuously by the platform owner. There's nothing to download
or digest — just a stable URL to cite. Recording them here, by reference,
keeps this registry current for free as the platform owner updates their own
docs.

Add a row whenever a project adopts a new language or platform. Prefer the
most authoritative source available: the language maintainer or standards
body first, the primary platform vendor second, a broadly-adopted community
guide only when neither exists.

| Language/Platform | Official Style Guide | Docstring/Comment Convention | Notes |
| --- | --- | --- | --- |
| Kotlin/Android | [developer.android.com/kotlin/style-guide](https://developer.android.com/kotlin/style-guide) | [KDoc](https://kotlinlang.org/docs/kotlin-doc.html) | Android's style guide layers Android-specific conventions on top of the general [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html). |
| Java | [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html) | [Javadoc](https://www.oracle.com/technical-resources/articles/java/javadoc-tool.html) | No single vendor-official guide exists for Java at large; Google's is the most widely adopted. |
| Python | [PEP 8](https://peps.python.org/pep-0008/) | [PEP 257](https://peps.python.org/pep-0257/) (Google or NumPy style body) | PEP 8 is maintained by the Python core team — the closest thing Python has to a vendor-official guide. |
| Swift | [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) | [Swift documentation comments](https://www.swift.org/documentation/docc/) (`///`) | Maintained by the Swift project itself. |
| JavaScript/TypeScript | [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html) | [JSDoc](https://jsdoc.app/) | No language-body-official guide exists; pick one canonical guide per project and stay consistent. |
| Go | [Effective Go](https://go.dev/doc/effective_go) + `gofmt` | [Go doc comments](https://go.dev/doc/comment) | `gofmt` makes most style debates moot — run it, don't argue about it. |
| C# | [Microsoft C# coding conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions) | XML doc comments (`///`) | |
| Rust | [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) + `rustfmt` | [rustdoc](https://doc.rust-lang.org/rustdoc/) (`///`) | |
| Shell | [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) | Comment header per script, per `shellcheck` conventions | This repository's own `scripts/*.sh` follow this guide. |
| C++ | [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html) | [Doxygen](https://www.doxygen.nl/manual/docblocks.html) (`/** ... */`) | No single vendor/standards-body guide exists; Google's is the most widely adopted outside embedded/kernel work. |
| C | [Linux kernel coding style](https://www.kernel.org/doc/html/latest/process/coding-style.html) | [Doxygen](https://www.doxygen.nl/manual/docblocks.html) (`/** ... */`) | No vendor-official guide exists for C at large; the kernel style is the most widely recognized reference. For embedded/safety-critical work, prefer the project's MISRA C guidelines instead. |

## Workflow

1. Adopting a new language/platform? Add a row here with its most
   authoritative style guide and docstring convention.
2. Prefer a URL that is unlikely to move (a language's own docs site, not a
   blog post). If a link rots, fix it in the same change that notices it.
3. Keep entries terse — one canonical link and one docstring convention per
   row. This is a pointer registry, not a summary; do not paste style guide
   content in here.
