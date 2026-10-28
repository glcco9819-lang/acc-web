import { dirname } from "path";
import { fileURLToPath } from "url";

const nextConfig = {};

export default {
  ...(await import("@next/eslint-plugin-next").then((m) => m.default.flatConfig?.() ?? {})),
  ignores: ["node_modules/**", ".next/**", "out/**"],
  rules: {
    "react-hooks/set-state-in-effect": "off",
    "react-hooks/exhaustive-deps": "warn",
  },
};
