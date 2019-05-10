<template>
    <div>
        <monaco-editor ref="editor" class="editor" v-model="code" language="scala"></monaco-editor>
    </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import MonacoEditor from "vue-monaco"
import * as monaco from "monaco-editor";
import { language } from "../scala";

@Component({components: {
    MonacoEditor,
}})

export default class Editor extends Vue {
    @Prop() private code!: string;
    
    mounted(): void {
        monaco.languages.register({id: "scala"});
        monaco.languages.setMonarchTokensProvider("scala", language);
    }
}
</script>

<style scoped lang="scss">
    .editor {
        width: 100%;
        height: 100%;
    }
</style>