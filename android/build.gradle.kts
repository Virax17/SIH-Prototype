allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some older plugins (e.g. vosk_flutter 0.3.48) ship an Android build.gradle
// that predates AGP's mandatory `namespace` property, and fail to configure
// under this project's AGP/Gradle version otherwise. Backfill it from the
// plugin's own AndroidManifest.xml `package` attribute — via reflection, so
// this doesn't need AGP's classes on the root script's own classpath — for
// any library subproject that didn't declare one itself.
subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        val getNamespace = androidExt.javaClass.getMethod("getNamespace")
        if (getNamespace.invoke(androidExt) != null) return@withId

        val manifestFile = file("src/main/AndroidManifest.xml")
        if (!manifestFile.exists()) return@withId
        val pkg = Regex("package=\"([^\"]+)\"").find(manifestFile.readText())?.groupValues?.get(1) ?: return@withId

        androidExt.javaClass.getMethod("setNamespace", String::class.java).invoke(androidExt, pkg)
    }
}

// Similarly, some plugins (e.g. onnxruntime 1.4.1) hardcode an old
// compileSdkVersion (33) in their own Android build.gradle, below what their
// own androidx dependencies require (34+) once resolved in this app. Bump
// any library subproject still below 34 up to this app's own compileSdk.
//
// Setting it during `plugins.withId` (right when `apply plugin:` runs) is
// too early — the plugin's own `android { compileSdkVersion N }` line later
// in that same script overwrites it back. `afterEvaluate` is the right
// window for most plugins, but a plugin with an eager native build
// (`externalNativeBuild`) can lock compileSdk even before its own
// `afterEvaluate` fires — those don't need bumping anyway (they already
// declare 34+), so skipping already-sufficient projects avoids hitting that
// lock at all; the `try/catch` is a last-resort guard, not the primary fix.
subprojects {
    val bumpCompileSdk: () -> Unit = bump@{
        val androidExt = extensions.findByName("android") ?: return@bump
        val current = try {
            androidExt.javaClass.getMethod("getCompileSdkVersion").invoke(androidExt) as? String
        } catch (_: NoSuchMethodException) {
            null
        } ?: return@bump
        val currentApiLevel = current.removePrefix("android-").toIntOrNull() ?: return@bump
        if (currentApiLevel >= 34) return@bump

        try {
            androidExt.javaClass.getMethod("setCompileSdkVersion", String::class.java).invoke(androidExt, "android-36")
        } catch (e: Exception) {
            logger.warn("Could not bump compileSdk for project '${project.name}' (was $current): ${e.cause?.message ?: e.message}")
        }
    }
    // `evaluationDependsOn(":app")` above means :app itself is typically
    // already fully evaluated by the time this per-subproject action runs
    // for it — and `afterEvaluate` throws if called on an already-evaluated
    // project — so apply immediately in that case instead of scheduling.
    if (state.executed) bumpCompileSdk() else afterEvaluate { bumpCompileSdk() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
