<template>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <div class="form-row align-items-center">
            <div class="col-auto">
                <div class="custom-file">
                    <input
                        type="file"
                        class="custom-file-input"
                        id="file"
                        ref="file"
                        v-on:change="selectFile()"
                    >
                    <label class="custom-file-label">{{ fileName }}</label>
                </div>
            </div>
        </div>
        <span class="ml-auto" v-if="loading">
            <font-awesome-icon icon="spinner" class="fa-pulse"/>&nbsp;Loading...
        </span>
        <div class="ml-auto">
            <div class="input-group">
                <input ref="search" type="text" class="form-control" placeholder="Search">
                <div class="input-group-append">
                    <div class="btn btn-primary" @click="search()">
                        <font-awesome-icon icon="search"/>
                    </div>
                </div>
            </div>
        </div>
    </nav>
</template>

<script lang="ts">
import { Component, Prop, Vue, Emit } from 'vue-property-decorator';
import { library } from '@fortawesome/fontawesome-svg-core'
import { faSearch, faSpinner } from '@fortawesome/free-solid-svg-icons'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'

library.add(faSearch, faSpinner)

@Component({
    components: {
        FontAwesomeIcon,
    }
})
export default class FileSector extends Vue {
    $refs!: Vue['$refs'] & { file: HTMLInputElement, search: HTMLInputElement };

    file!: File;
    fileName = "Choose a log file";
    loading = false;

    selectFile(): void {
        if (this.$refs.file.files !== null) {
            this.file = this.$refs.file.files[0];
            this.fileName = this.file.name;
        }

        this.loading = true;
        this.submitFile();
    }

    @Emit()
    submitFile(): File {
        return this.file;
    }

    @Emit()
    search(): string {
        return this.$refs.search.value;
    }

    async fetchDefaultFile() {
        let response = await fetch('/demo.log');
        let data = await response.blob();
        let metadata = {
            type: 'text/plain'
        };
        this.file = new File([data], "demo.log", metadata);

        this.submitFile();
    }

    mounted(): void {
        this.fetchDefaultFile();
    }
}
</script>

<style scoped lang="scss">
.navbar {
    position: sticky;
    top: 0;
    z-index: 1000;
}
</style>