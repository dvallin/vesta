module.exports = {
  env: {
    browser: true,
  },
  globals: {
    process: true,
    module: true,
  },
  root: true,
  extends: [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended",
    "plugin:unicorn/recommended",
  ],
  parser: "@babel/eslint-parser",
  parserOptions: {
    ecmaVersion: 6,
    requireConfigFile: false,
    sourceType: "module",
    ecmaFeatures: {
      jsx: true,
      experimentalObjectRestSpread: true,
    },
  },
  rules: {
    "react/no-unknown-property": ["error", { ignore: ["class"] }],
    "react/prefer-stateless-function": 1,
    "react/display-name": 0,
    "react/prop-types": 0,
    "react-hooks/exhaustive-deps": 2,
    "react/react-in-jsx-scope": 0, // Since React 17 using JSX doesn't require React to be imported.
    curly: "error",
    "unicorn/prevent-abbreviations": 0,
  },
  settings: {
    react: {
      version: "detect",
    },
  },
  overrides: [
    {
      files: ["*.ts", "*.tsx"],
      parser: "@typescript-eslint/parser",
      plugins: ["@typescript-eslint"],
      parserOptions: {
        project: "./tsconfig.json",
      },
      extends: [
        "plugin:@typescript-eslint/eslint-recommended",
        "plugin:@typescript-eslint/recommended",
        "plugin:@typescript-eslint/recommended-requiring-type-checking",
      ],
      rules: {
        "@typescript-eslint/no-unused-vars": [
          "error",
          { argsIgnorePattern: "^_" },
        ],
        "@typescript-eslint/explicit-module-boundary-types": 0,
        "@typescript-eslint/explicit-function-return-type": 0,
        "@typescript-eslint/no-explicit-any": 2,
        "@typescript-eslint/no-non-null-assertion": 2,
      },
    },
  ],
};
