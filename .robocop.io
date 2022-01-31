StringLiterals:
  Enabled: false

SpaceAroundEqualsInParameterDefault:
  Enabled: false

HashSyntax:
  Enabled: false

LineLength:
  Enabled: true
  Max: 90

WhileUntilModifier:
  Enabled: false

IfUnlessModifier:
  Enabled: false
sudowoodo-release-bot Bump v18.0.0-nightly.20220103

Latest commit 84451e7 28 days ago

 History

 52 contributors


  

{

  "name": "electron",

  "version": "18.0.0-nightly.20220103",

  "repository": "https://github.com/electron/electron",

  "description": "Build cross platform desktop apps with JavaScript, HTML, and CSS",

  "devDependencies": {

    "@electron/docs-parser": "^0.12.3",

    "@electron/typescript-definitions": "^8.9.5",

    "@octokit/auth-app": "^2.10.0",

    "@octokit/rest": "^18.0.3",

    "@primer/octicons": "^10.0.0",

    "@types/basic-auth": "^1.1.3",

    "@types/busboy": "^0.2.3",

    "@types/chai": "^4.2.12",

    "@types/chai-as-promised": "^7.1.3",

    "@types/dirty-chai": "^2.0.2",

    "@types/express": "^4.17.7",

    "@types/fs-extra": "^9.0.1",

    "@types/klaw": "^3.0.1",

    "@types/minimist": "^1.2.0",

    "@types/mocha": "^7.0.2",

    "@types/node": "^14.6.2",

    "@types/semver": "^7.3.3",

    "@types/send": "^0.14.5",

    "@types/split": "^1.0.0",

    "@types/stream-json": "^1.5.1",

    "@types/temp": "^0.8.34",

    "@types/uuid": "^3.4.6",

    "@types/webpack": "^4.41.21",

    "@types/webpack-env": "^1.15.2",

    "@typescript-eslint/eslint-plugin": "^4.4.1",

    "@typescript-eslint/parser": "^4.4.1",

    "asar": "^3.1.0",

    "aws-sdk": "^2.814.0",

    "check-for-leaks": "^1.2.1",

    "colors": "^1.4.0",

    "dotenv-safe": "^4.0.4",

    "dugite": "^1.103.0",

    "eslint": "^7.4.0",

    "eslint-config-standard": "^14.1.1",

    "eslint-plugin-import": "^2.22.0",

    "eslint-plugin-mocha": "^7.0.1",

    "eslint-plugin-node": "^11.1.0",

    "eslint-plugin-standard": "^4.0.1",

    "eslint-plugin-typescript": "^0.14.0",

    "express": "^4.16.4",

    "folder-hash": "^2.1.1",

    "fs-extra": "^9.0.1",

    "got": "^6.3.0",

    "husky": "^6.0.0",

    "klaw": "^3.0.0",

    "lint": "^1.1.2",

    "lint-staged": "^10.2.11",

    "markdownlint": "^0.21.1",

    "markdownlint-cli": "^0.25.0",

    "minimist": "^1.2.5",

    "null-loader": "^4.0.0",

    "pre-flight": "^1.1.0",

    "remark-cli": "^10.0.0",

    "remark-preset-lint-markdown-style-guide": "^4.0.0",

    "semver": "^5.6.0",

    "shx": "^0.3.2",

    "standard-markdown": "^6.0.0",

    "stream-json": "^1.7.1",

    "tap-xunit": "^2.4.1",

    "temp": "^0.8.3",

    "timers-browserify": "1.4.2",

    "ts-loader": "^8.0.2",

    "ts-node": "6.2.0",

    "typescript": "^4.1.3",

    "webpack": "^4.43.0",

    "webpack-cli": "^3.3.12",

    "wrapper-webpack-plugin": "^2.1.0"

  },

  "private": true,

  "scripts": {

    "asar": "asar",

    "generate-version-json": "node script/generate-version-json.js",

    "lint": "node ./script/lint.js && npm run lint:clang-format && npm run lint:docs",

    "lint:js": "node ./script/lint.js --js",

    "lint:clang-format": "python script/run-clang-format.py -r -c shell/ || (echo \"\\nCode not formatted correctly.\" && exit 1)",

    "lint:clang-tidy": "ts-node ./script/run-clang-tidy.ts",

    "lint:cpp": "node ./script/lint.js --cc",

    "lint:objc": "node ./script/lint.js --objc",

    "lint:py": "node ./script/lint.js --py",

    "lint:gn": "node ./script/lint.js --gn",

    "lint:docs": "remark docs -qf && npm run lint:js-in-markdown && npm run create-typescript-definitions && npm run lint:docs-relative-links && npm run lint:markdownlint",

    "lint:docs-relative-links": "python ./script/check-relative-doc-links.py",

    "lint:markdownlint": "markdownlint \"*.md\" \"docs/**/*.md\"",

    "lint:js-in-markdown": "standard-markdown docs",

    "create-api-json": "electron-docs-parser --dir=./",

    "create-typescript-definitions": "npm run create-api-json && electron-typescript-definitions --api=electron-api.json && node spec/ts-smoke/runner.js",

    "gn-typescript-definitions": "npm run create-typescript-definitions && shx cp electron.d.ts",

    "pre-flight": "pre-flight",

    "gn-check": "node ./script/gn-check.js",

    "precommit": "lint-staged",

    "preinstall": "node -e 'process.exit(0)'",

    "prepack": "check-for-leaks",

    "prepare": "husky install",

    "repl": "node ./script/start.js --interactive",

    "start": "node ./script/start.js",

    "test": "node ./script/spec-runner.js",

    "tsc": "tsc",

    "webpack": "webpack"

  },

  "license": "MIT",

  "author": "Electron Community",

  "keywords": [

    "electron"

  ],

  "lint-staged": {

    "*.{js,ts}": [

      "node script/lint.js --js --fix --only --"

    ],

    "*.{js,ts,d.ts}": [

      "ts-node script/gen-filenames.ts"

    ],

    "*.{cc,mm,c,h}": [

      "python script/run-clang-format.py -r -c --fix"

    ],

    "*.md": [

      "npm run lint:docs"

    ],

    "*.{gn,gni}": [

      "npm run gn-check",

      "python script/run-gn-format.py"

    ],

    "*.py": [

      "node script/lint.js --py --fix --only --"

    ],

    "docs/api/**/*.md": [

      "ts-node script/gen-filenames.ts",

      "markdownlint --config .markdownlint.autofix.json --fix",

      "git add filenames.auto.gni"

    ],

    "{*.patch,.patches}": [

      "node script/lint.js --patches --only --",

      "ts-node script/check-patch-diff.ts"

    ],

    "DEPS": [

      "node script/gen-hunspell-filenames.js"

    ]

  }

}

© 2022 GitHub, Inc.
