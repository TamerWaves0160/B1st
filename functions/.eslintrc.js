/* eslint-env node */
module.exports = {
  root: true,
  parser: "@typescript-eslint/parser",
  parserOptions: { ecmaVersion: 2020, sourceType: "module" },
  env: { node: true, es6: true },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "google"
  ],
  ignorePatterns: ["lib/**", "dist/**"],
  rules: {
    "require-jsdoc": "off",
    "valid-jsdoc": "off",
    "max-len": ["error", { code: 120, ignoreUrls: true, ignoreStrings: true, ignoreTemplateLiterals: true }],
    "object-curly-spacing": ["error", "never"],
    "@typescript-eslint/no-explicit-any": "off"
  }
};
