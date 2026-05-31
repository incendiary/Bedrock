import pluginVue from "eslint-plugin-vue";

export default [
  ...pluginVue.configs["flat/recommended"],
  {
    rules: {
      // Relax a couple of rules that fire on stub/template components
      "vue/multi-word-component-names": "off",
    },
  },
];
