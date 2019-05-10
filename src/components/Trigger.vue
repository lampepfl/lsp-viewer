<template>
    <span ref="trigger"/>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';

@Component
export default class Trigger extends Vue {    
    observer: IntersectionObserver = null as unknown as IntersectionObserver

    mounted(): void {
        this.observer = new IntersectionObserver(entries => {
            this.handleIntersect(entries[0])
        })

        this.observer.observe(this.$refs.trigger)
    }

    destroyed(): void {
        this.observer.disconnect()
    }

    handleIntersect(entry: IntersectionObserverEntry): void {
        if (entry.isIntersecting) {
            this.$emit("trigger-intersected")
        }
    }
}
</script>