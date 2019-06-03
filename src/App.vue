<template>
    <div id="app">
        <div id="messages">
            <FileSelector v-on:submit-file="handleFileSubmission" v-on:search="handleSearch"/>
            <div class="container">
                <div v-for="(log, index) in logs" v-bind:key="index + fileName" ref="logDOM">
                    <LogEntry
                        ref="log"
                        v-on:message-selected="handleMessageSelected"
                        v-bind:visible="log.display"
                        v-bind:message="log.msg"
                        v-bind:index="index"
                    />
                </div>
            </div>
        </div>
        <Editor
            id="code-view"
            v-bind:code="code"
            v-bind:previous-code="previousCode"
            v-bind:uri="uri"
        />
    </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';

import LogEntry from './components/LogEntry.vue';
//@ts-ignore
import TreeView from "vue-json-tree-view";
import FileSelector from "./components/FileSelector.vue";
import Editor from "./components/Editor.vue";

import BootstrapVue from 'bootstrap-vue'
Vue.use(BootstrapVue)
import "./assets/custom.scss"

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
        Editor,
    }
})
export default class App extends Vue {
    $refs!: Vue['$refs'] & { log: LogEntry[], logDOM: HTMLElement[] };

    fileName!: string;
    logs: ReadonlyArray<Log> = [];

    code = "";
    previousCode = "";
    uri = "";

    selected!: LogEntry;
    selectedIndex!: number;

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
        this.fileName = file.name;
        let reader = new FileReader();
        let logs: Log[];

        reader.addEventListener("load", event => {
            if (reader.result) {
                let lines = reader.result.toString().split(/\n/);

                logs = lines.filter(line => line.startsWith("[LSP"))
                    .map(line => {
                        line = line.substring(line.indexOf("{"));
                        return { msg: JSON.parse(line), display: true };
                    });
            }
        });

        reader.addEventListener("loadend", event => {
            this.logs = Object.freeze(logs);
            this.code = "";
            this.previousCode = "";
            this.uri = "";

            this.$nextTick(() => {
                for (let i = 0; i < this.logs.length; i++) {
                    this.$refs.log[i].setMethod(this.getMethod(i));

                    let message = this.logs[i].msg.message;
                    if (msgs.isRequestMessage(message) && !msgs.isNotificationMessage(message)) {
                        this.$refs.log[this.findResponse(i)].setOther(this.$refs.log[i]);
                    }
                }
            });
        });

        reader.readAsText(file);
    }

    handleSearch(query: string): void {
        let logs: Log[];
        if (!query.trim()) {
            logs = this.logs.map(x => {
                x.display = true;
                return x;
            });
        } else {
            logs = this.logs.map(x => {
                x.display = JSON.stringify(x.msg).includes(query);
                return x;
            });
        }

        this.logs = Object.freeze(logs);
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

    findResponse(index: number): number {
        let request = this.logs[index].msg.message as msgs.RequestMessage;
        for (let i = index; i < this.logs.length; i++) {
            let response = this.logs[i].msg.message;
            if (msgs.isResponseMessage(response) && !msgs.isNotificationMessage(response) && request.id == response.id) {
                return i;
            }
        }

        return -1;
    }

    findRequest(index: number): number {
        let response = this.logs[index].msg.message as msgs.ResponseMessage;
        for (let i = index; i >= 0; i--) {
            let request = this.logs[i].msg.message;
            if (msgs.isRequestMessage(request) && request.id == response.id) {
                return i;
            }
        }

        return -1;
    }

    handleMessageSelected(index: number): void {
        this.selectedIndex = index;
        if (this.selected === undefined) {
            this.selected = this.$refs.log[index];
            this.selected.setSelected(true);
        } else {
            this.selected.setSelected(false);
            this.selected = this.$refs.log[index];
            this.selected.setSelected(true);
        }

        this.updateCodeView(index);
    }

    updateCodeView(index: number): void {
        let code = this.findCodeStateAt(index);
        if (code !== undefined) {
            this.code = code.content;

            let current = this.logs[code.index].msg.message;
            if (!msgs.isResponseMessage(current)) {
                this.uri = current.params.textDocument.uri;
            }

            for (let i = code.index - 1; i >= 0; i--) {
                let previousCode = this.findCodeStateAt(i);
                if (previousCode === undefined) {
                    this.previousCode = "";
                    break;
                }

                let previous = this.logs[previousCode.index].msg.message;
                if (!msgs.isResponseMessage(current) && !msgs.isResponseMessage(previous)) {
                    if (previous.params.textDocument.uri === current.params.textDocument.uri) {
                        this.previousCode = previousCode.content;
                        break;
                    }
                }
            }
        } else {
            this.code = "";
            this.previousCode = "";
            this.uri = "";
        }
    }

    created(): void {
        window.addEventListener('keyup', this.onKey)
    }

    onKey(event: KeyboardEvent): void {
        let nextIndex = -1;
        switch (event.code) {
            case "ArrowLeft":
                for (let i = this.selectedIndex - 1; i >= 0; i--) {
                    if (this.logs[i].display) {
                        nextIndex = i;
                        break;
                    }
                }

                if (this.selectedIndex !== undefined && nextIndex > 0) {

                    this.$refs.log[nextIndex].show = true;
                    this.handleMessageSelected(nextIndex);

                    this.$refs.logDOM[this.selectedIndex].scrollIntoView({ behavior: "smooth", block: "center", inline: "start" });
                }
                break;
            case "ArrowRight":
                for (let i = this.selectedIndex + 1; i < this.logs.length; i++) {
                    if (this.logs[i].display) {
                        nextIndex = i;
                        break;
                    }
                }

                if (this.selectedIndex !== undefined && nextIndex > 0) {
                    this.$refs.log[nextIndex].show = true;
                    this.handleMessageSelected(nextIndex);

                    this.$refs.logDOM[this.selectedIndex].scrollIntoView({ behavior: "smooth", block: "center", inline: "start" });
                }
                break;
        }
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
