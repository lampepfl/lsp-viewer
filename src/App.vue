<template>
    <div id="app">
        <div id="messages">
            <FileSelector v-on:submit-file="handleFileSubmission" v-on:search="handleSearch"/>
            <div class="container">
                <div v-for="log, index in logs.slice(0, displayedLogs)">
                    <LogEntry
                        v-if="log.display"
                        v-on:message-selected="updateCodeView"
                        v-bind:message="log.msg"
                        v-bind:index="index"
                        v-bind:method="getMethod(index)"
                        v-bind:selectedId="selectedId"
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
import LogEntry from './components/LogEntry.vue';
import TreeView from "vue-json-tree-view";
import jQuery from "jquery";
import FileSelector from "./components/FileSelector.vue";
import Trigger from "./components/Trigger.vue";
import Editor from "./components/Editor.vue";

import BootstrapVue from 'bootstrap-vue'
Vue.use(BootstrapVue)
import "./assets/custom.scss"
import { toHtml } from '@fortawesome/fontawesome-svg-core';

import * as msgs from "vscode-jsonrpc/lib/messages";

Vue.use(TreeView);
Vue.use(require('vue-moment'));

interface Log {
    msg: msgs.LSPLogMessage
    display: boolean
}

@Component({
    components: {
        LogEntry,
        FileSelector,
        Trigger,
        Editor,
    },
})
export default class App extends Vue {
    logs: Log[] = [];
    displayedLogs = 50;
    code = "var a = 5";
    previousCode = "";
    selectedId: string | number = -1;

    getMethod(index: number): string {
        let log = this.logs[index];
        if (!msgs.isResponseMessage(log.msg.message)) {
            return log.msg.message.method;
        }

        for (let i = index - 1; i >= 0; i--) {
            let msg = this.logs[i].msg.message;
            if (msgs.isRequestMessage(msg) && msg.id == log.msg.message.id) {
                return msg.method;
            }
        }

        return "";
    }

    handleFileSubmission(file: File): void {
        let reader = new FileReader();
        reader.addEventListener("load", event => {
            if (reader.result) {
                let lines = reader.result.toString().split(/\n/);

                this.logs = lines.filter(line => line.startsWith("[LSP"))
                    .map(line => {
                        line = line.substring(line.indexOf("{"));
                        return { msg: JSON.parse(line), display: true };
                    });
            }
        });

        reader.readAsText(file);
    }

    handleSearch(query: string): void {
        if (!query.trim()) {
            this.logs.forEach(x => x.display = true);
        } else {
            this.logs.forEach(x => x.display = JSON.stringify(x.msg).includes(query));
        }
    }

    private getUri(message: Log): string | undefined {
        if (msgs.isResponseMessage(message.msg.message)) {
            return undefined;
        }

        return message.msg.message.params.uri;
    }

    private findCodeStateAt(index: number): { content: string, index: number } | undefined {
        if (index < 0) {
            return undefined;
        }

        for (let i = index; i >= 0; i--) {
            let message = this.logs[i].msg.message;

            if (!msgs.isResponseMessage(message)) {
                if (message.method === "textDocument/didOpen") {
                    return { content: message.params.textDocument.text, index: i }
                } else if (message.method === "textDocument/didChange") {
                    return { content: message.params.contentChanges[0].text, index: i };
                }
            }
        }
    }

    updateCodeView(index: number): void {
        this.selectedId = this.logs[index].msg.message.id;

        let code = this.findCodeStateAt(index);
        if (code !== undefined) {
            this.code = code.content;

            for (let i = code.index - 1; i >= 0; i--) {
                let previousCode = this.findCodeStateAt(i);
                if (previousCode === undefined) {
                    this.previousCode = "";
                    break;
                }

                if (this.logs[previousCode.index].msg.message.params.textDocument.uri === this.logs[code.index].msg.message.params.textDocument.uri) {
                    this.previousCode = previousCode.content;
                    break;
                }
            }
        } else {
            this.code = "";
            this.previousCode = "";
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
