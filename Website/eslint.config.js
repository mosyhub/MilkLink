import js from "@eslint/js";
import globals from "globals";
import pluginReact from "eslint-plugin-react";


export default [
  {
    ignores: [
      "node_modules",
      "dist",
      ".expo",
      "package-lock.json",
      "eas.json",
      "react-native.config.js",
      "eslint.config.mjs",
      "tailwind.config.js",
    ],
  },
  {
    files: ["**/*.{js,jsx,mjs,cjs}"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
      globals: {
        ...globals.browser,
        ...globals.node,
        __DEV__: true,
      },
    },
    plugins: {
      js,
      react: pluginReact,
    },
    rules: {
      // JS base rules
      ...js.configs.recommended.rules,

      // React rules
      ...(pluginReact.configs.recommended?.rules ?? {}),

      // Extra rules
      "no-duplicate-imports": "error",
      "react/jsx-no-useless-fragment": "warn",

      // Optional overrides
      "react/react-in-jsx-scope": "off", // not needed in React 17+
    },
    settings: {
      react: {
        version: "detect",
      },
    },
  },
];
