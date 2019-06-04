<template>
    <div
        v-show="visible"
        v-bind:class="[message.message.id ? 'id-' + message.message.id : '', 'card']"
        @click="messageSelected"
        ref="logEntry"
    >
        <div
            @click="toggleDisplay()"
            v-bind:class="[{ 'bg-secondary': selected },
            isNotificationMessage(message.message) ? 'notification' : 'message',]"
            class="card-header"
            v-bind:style="message.type.startsWith('receive') ? 'text-align: right' : ''"
        >
            <template v-if="message.type === 'send-notification'">
                <font-awesome-icon icon="comment-alt"/>
                {{method}} - {{message.timestamp | moment("HH:mm:ss")}}
            </template>
            <template v-else-if="message.type === 'receive-notification'">
                {{message.timestamp | moment("HH:mm:ss")}} - {{method}}
                <font-awesome-icon icon="comment-alt" style="transform: scale(-1, 1)"/>
            </template>
            <template v-else-if="message.type === 'send-request'">
                <font-awesome-icon icon="comment"/>
                {{method}} - {{message.timestamp | moment("HH:mm:ss")}}
            </template>
            <template v-else-if="message.type === 'receive-response'">
                {{message.timestamp | moment("HH:mm:ss")}} - {{method}}
                <font-awesome-icon icon="comment" style="transform: scale(-1, 1)"/>
            </template>
        </div>
        <div class="card-body" v-if="show">
            <tree-view v-if="show" :data="message.message" :options="{ maxDepth: 1 }"></tree-view>
        </div>
    </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Emit } from 'vue-property-decorator';
import { library } from '@fortawesome/fontawesome-svg-core';
import { faCommentAlt, faComment } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
import { LSPLogMessage, isNotificationMessage } from 'vscode-jsonrpc/lib/messages';

library.add(faCommentAlt);
library.add(faComment);

@Component({
    components: {
        FontAwesomeIcon,
    }
})
export default class LogEntry extends Vue {
    show = false;
    isNotificationMessage = isNotificationMessage;
    other!: LogEntry;
    selected = false;
    method: string = "";

    @Prop(Object) private message!: LSPLogMessage;
    @Prop(Number) private index!: number;
    @Prop(Boolean) private visible!: boolean;

    @Emit()
    messageSelected(): number {
        return this.index;
    }

    setMethod(method: string): void {
        this.method = method;
    }

    setOther(entry: LogEntry): void {
        this.other = entry;
        this.other.other = this;
    }

    setSelected(selected: boolean): void {
        this.selected = selected;
        if (this.other){
            this.other.selected = selected;
        }
    }

    /**
     * Toggles the visibility of the body of the LogEntry. The body is rendered in the DOM only when visible.
     */
    toggleDisplay(): void {
        this.show = !this.show
    }
}
</script>

<style scoped lang="scss">
.card-header {
    cursor: pointer;
}

.notification {
    color: rgb(219, 143, 0);
}

.message {
    color: #3cc152;
}
</style>