<template>
    <div v-bind:class="['id-' + message.message.id, 'card']" @click="highlight">
        <div class="card-header" @click="toggleDisplay()">{{message.type}} - {{message.timestamp | moment("D/M/Y HH:mm:ss")}}</div>
        <div class="card-body" v-if="show">
            <tree-view v-if="show" :data=message.message :options="{ maxDepth: 1 }"></tree-view>
        </div>
    </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class Message extends Vue {
    show = false

    @Prop(Object) private message!: object;
    @Prop(Number) private index!: number;

    toggleDisplay(): void {
        this.show = !this.show
    }

    highlight(event: Event & { currentTarget: HTMLElement }): void {
        for (let el of document.getElementsByClassName(event.currentTarget.className) as HTMLCollectionOf<HTMLElement>) {
            if (el != event.target) {
                if (el.style.color === "red") {
                    el.style.color = "black"
                } else {
                    el.style.color = "red"
                }
            }
        }

        this.$emit("message-selected", this.index)
    }
}
</script>

<style scoped lang="scss">
  
</style>