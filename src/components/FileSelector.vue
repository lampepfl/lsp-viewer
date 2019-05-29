<template>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <div class="form-row align-items-center">
            <div class="col-auto">
                <div class="custom-file">
                    <input type="file" class="custom-file-input" id="file" ref="file" v-on:change="selectFile()" />
                    <label class="custom-file-label" for="customFile">{{ file ? file.name : "Choose a log file" }}</label>
                </div>
            </div>
            <div class="col-auto">
                <button class="btn btn-outline-primary" type="submit" v-on:click="submitFile()">Load</button>
            </div>
        </div>
        <div class="ml-auto">
            <div class="input-group">
                <input ref="search" type="text" class="form-control" placeholder="Search">
                <div class="input-group-append">
                    <div class="btn btn-primary" @click="search()"><font-awesome-icon icon="search" /></div>
                </div>
            </div>
        </div>
    </nav>
</template>

<script lang="ts">
import { Component, Prop, Vue, Emit } from 'vue-property-decorator';
import { library } from '@fortawesome/fontawesome-svg-core'
import { faSearch } from '@fortawesome/free-solid-svg-icons'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'

library.add(faSearch)

@Component({components: {
    FontAwesomeIcon,
}})
export default class FileSector extends Vue {
    private file: File = null as unknown as File

    selectFile(): void {
        this.file = this.$refs.file.files[0];
    }

    @Emit()
    submitFile(): File {
            return this.file
        }

    @Emit()
    search(): string {
        return this.$refs.search.value;
    }
}
</script>