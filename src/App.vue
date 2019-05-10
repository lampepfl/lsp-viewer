<template>
    <div id="app">
        <div id="messages">
            <FileSelector v-on:submit-file="handleFileSubmission" v-on:search="handleSearch"/>
            <div class="container">
                <div
                    v-for="(message, index) in logs.filter(([_, display]) => display)
                    .map(([message, _]) => message)
                    .slice(0, displayedLogs)"
                >
                    <Message
                        v-on:message-selected="updateCodeView"
                        v-bind:message="message"
                        v-bind:index="index"
                    />
                </div>
                <Trigger v-on:trigger-intersected="loadMore"/>
            </div>
        </div>
        <Editor id="code-view" v-bind:code="code" v-bind:previous-code="previousCode"/>
    </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import Message from './components/Message.vue';
import TreeView from "vue-json-tree-view";
import jQuery from "jquery";
import FileSelector from "./components/FileSelector.vue";
import Trigger from "./components/Trigger.vue";
import Editor from "./components/Editor.vue";

import BootstrapVue from 'bootstrap-vue'
Vue.use(BootstrapVue)
import "./assets/custom.scss"
import { toHtml } from '@fortawesome/fontawesome-svg-core';

Vue.use(TreeView);
Vue.use(require('vue-moment'));

@Component({
    components: {
        Message,
        FileSelector,
        Trigger,
        Editor,
    },
})

export default class App extends Vue {
    logs: (object | boolean)[][] = [];
    displayedLogs = 50;
    code = "var a = 5";
    previousCode = "";

    handleFileSubmission(file: File): void {
        let reader = new FileReader();
        reader.addEventListener("load", (event) => {
            if (reader.result) {
                let lines = reader.result.toString().split(/\n/);

                this.logs = lines.filter(line => line.startsWith("[LSP"))
                    .map(line => {
                        line = line.substring(line.indexOf("{"));
                        return [JSON.parse(line), true];
                    });
            }
        });
        reader.readAsText(file);
    }

    handleSearch(query: string): void {
        if (!query.trim()) {
            this.logs = this.logs.map(([message, _]) => [message, true]);
        } else {
            this.logs = this.logs.map(([message, _]) => [message, JSON.stringify(message).includes(query)]);
        }
    }

    updateCodeView(index: number): void {
        for (let i = index; i > 0; i--) {
            if (this.logs[i][0].message.method == "textDocument/didOpen") {
                this.code = this.logs[i][0].message.params.textDocument.text;

                for (let j = i - 1; j > 0; j--) {
                    if (this.logs[j][0].message.params.uri === this.logs[i][0].message.params.uri) {
                        if (this.logs[j][0].message.method == "textDocument/didOpen") {
                            this.previousCode = this.logs[j][0].message.params.textDocument.text;
                            break;
                        } else if (this.logs[j][0].message.method == "textDocument/didChange") {
                            this.previousCode = this.logs[j][0].message.params.contentChanges[0].text;
                            break;
                        }
                    }
                }

                break;
            } else if (this.logs[i][0].message.method == "textDocument/didChange") {
                this.code = this.logs[i][0].message.params.contentChanges[0].text;

                for (let j = i - 1; j > 0; j--) {
                    if (this.logs[j][0].message.params.uri === this.logs[i][0].message.params.uri) {
                        if (this.logs[j][0].message.method == "textDocument/didOpen") {
                            this.previousCode = this.logs[j][0].message.params.textDocument.text;
                            break;
                        } else if (this.logs[j][0].message.method == "textDocument/didChange") {
                            this.previousCode = this.logs[j][0].message.params.contentChanges[0].text;
                            break;
                        }
                    }
                }

                break;
            }
        }
    }

    loadMore(): void {
        this.displayedLogs += 50
    }
}
</script>

<style scoped lang="scss">
#app {
    overflow: hidden;
}

#messages {
    width: 50%;
    overflow: auto;
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
}

#code-view {
    width: 50%;
    overflow: hidden;
    position: absolute;
    top: 0;
    right: 0;
    bottom: 0;
}
</style>
