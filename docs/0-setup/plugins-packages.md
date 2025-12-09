# Plugins and packages

The project uses a plugin/package architecture to support multiple eBook formats and modular features.

## Packages

The project is structured into multiple Dart/Flutter packages under the `packages/` directory. Each package encapsulates specific functionality or format support.

Regular packages should not depend on the main app, they are standalone and reusable.

Example:

- `readwhere_cbr`: CBR comic format support
- `readwhere_epub`: EPUB format support

## Plugins

Plugins are packages that tie together format-specific implementations with the core app. Each plugin implements the necessary interfaces defined in the `domain` layer to provide support for a specific eBook format.

Example plugins:

- `readwhere_cbr_plugin`: Implements CBR support using `readwhere_cbr`
