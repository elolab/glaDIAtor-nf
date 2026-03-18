# Changing this documentation

The documentation is using a Markdown flavor called MyST. MyST `.md` files found in the project are processed by Sphinx generator, starting from `index.md` at the top level of the project.

Generated documentation is placed at `doc/dist` location and can be opened with a browser, for example `firefox doc/dist/index.html`

* After every commit to private [UTU repository](https://gitlab.utu.fi/elolab/gladiator-nf) the documentation is deployed to <https://elolab.utugit.fi/gladiator-nf> for a preview.
* {bdg-warning}`pending` After every commit to the `main` branch of public [Elo Lab repository](https://github.com/elolab/glaDIAtor-nf) the documentation is deployed to <https://elolab.github.io/glaDIAtor-nf>.

## Dependencies

Rendering of workflow overview requires Graphviz

::::{tab-set}
:::{tab-item} Ubuntu 24.04 LTS
```sh
sudo apt install graphviz -y
```
:::
::::

## Building

```sh
./build.sh
```

On the first run the script creates `sphinx/.venv`.

:::{hint}
_Live Server_ extension of VSCode offers a small convenience of auto-reload after changes. With _Live Server_ running, visit <http://localhost:5500/sphinx/dist>.
:::
