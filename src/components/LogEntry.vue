<template>
    <div
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
    observer!: IntersectionObserver;
    visible = false;

    @Prop(Object) private message!: LSPLogMessage;
    @Prop(Number) private index!: number;
    @Prop(String) private method!: string;
    @Prop(Boolean) private selected!: boolean;

    @Emit()
    messageSelected(): number {
        return this.index;
    }

    toggleDisplay(): void {
        this.show = !this.show
    }

    get isSelected(): boolean {
        let selected = false;
        if (!isNotificationMessage(this.message.message)) {
            selected = this.message.message.id == this.selectedId;
        }
        console.log("sdhkjsdfhkj")
        return selected;
    }
/*
    mounted(): void {
        this.observer = new IntersectionObserver(entries => {
            this.visible = entries[0].isIntersecting;
        });

        this.observer.observe(this.$refs.logEntry);
    }

    destroyed(): void {
        this.observer.disconnect()
    }*/
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