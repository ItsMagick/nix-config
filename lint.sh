#!/usr/bin/env bash

nix-shell -p fd qt6.qtdeclarative prettier taplo stylua nixfmt shfmt shellcheck --run '
{
  stage() {
    echo "-----------------------------------------"
    echo " $1"
    echo "-----------------------------------------"
  }

  stage "1/6: Formatting & Linting QML"
  fd -e qml -x qmlformat -i -n
  fd -e qml -x qmllint

  stage "2/6: Formatting CSS & Rasi"
  fd -e css -e rasi -x prettier --write --parser css

  stage "3/6: Formatting TOML"
  fd -e toml -x taplo fmt

  stage "4/6: Formatting Lua"
  fd -e lua -x stylua

  stage "5/6: Formatting Nix"
  find . -name "*.nix" -not -path "*/.git/*" -not -path "*/result*" -not -path "*/.idea/*" -exec nixfmt {} +

  stage "6/6: Formatting & Linting Shell Scripts"
  fd -e sh -x shfmt -w -i 2 -sr
  fd -e sh -x shellcheck

  stage "Done!"
} 2>&1 | tee lint-out.txt
'
