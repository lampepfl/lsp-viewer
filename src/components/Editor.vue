<template>
    <div>
        <nav class="navbar navbar-expand-lg navbar-light bg-light">
            <button
                class="btn btn-outline-primary"
                v-on:click="toggleDiffmode()"
                v-if="!diffMode"
            >Diff View</button>
            <button
                class="btn btn-outline-primary"
                v-on:click="toggleDiffmode()"
                v-if="diffMode"
            >Editor View</button>
        </nav>
        <div class="editor" ref="editor"></div>
        <div class="editor" ref="diffEditor"></div>
    </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Model, Watch } from 'vue-property-decorator';
import * as monaco from "monaco-editor";
import { language } from "../scala";

@Component
export default class Editor extends Vue {
    $refs!: Vue['$refs'] & { editor: HTMLElement, diffEditor: HTMLElement };

    private editor!: monaco.editor.IEditor;
    private diffEditor!: monaco.editor.IDiffEditor;
    private diffMode = false;

    @Prop() private code!: string;
    @Prop() private previousCode!: string;

    @Watch("code", { deep: true })
    onCodeChanged(val: string, oldVal: string) {
        let model = monaco.editor.createModel(this.code, "scala");

        if (this.editor) {
            this.editor.setModel(model);
        }

        if (this.diffEditor) {
            let oldModel = monaco.editor.createModel(this.previousCode, "scala");
            this.diffEditor.setModel({
                original: oldModel,
                modified: model
            });

            this.diffEditor.onDidUpdateDiff(() => {
                let lineChanges = this.diffEditor.getLineChanges();
                if (lineChanges !== null && lineChanges.length > 0) {
                    this.diffEditor.revealLineInCenter(lineChanges[0].modifiedStartLineNumber);
                }
            })
        }
    }

    mounted(): void {
        monaco.languages.register({ id: "scala" });
        monaco.languages.setMonarchTokensProvider("scala", language);
        this.editor = monaco.editor.create(this.$refs.editor, {
            value: this.code,
            language: "scala"
        });
        this.diffEditor = monaco.editor.createDiffEditor(this.$refs.diffEditor, {
            enableSplitViewResizing: false,
            renderSideBySide: false,
            ignoreTrimWhitespace: false
        });

        this.$refs.diffEditor.style.display = "none";
    }

    toggleDiffmode(): void {
        this.diffMode = !this.diffMode;
        if (this.diffMode) {
            this.$refs.diffEditor.style.display = "initial";
            this.$refs.editor.style.display = "none";
        } else {
            this.$refs.diffEditor.style.display = "none";
            this.$refs.editor.style.display = "initial";
        }
    }
}
</script>

<style scoped lang="scss">
.editor {
    width: 100%;
    height: 100%;
}
</style>