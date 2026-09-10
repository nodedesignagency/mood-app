import hashlib, os, pathlib, sys

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "apple")
PROJ = ROOT / "Mood.xcodeproj"
(PROJ / "project.xcworkspace").mkdir(parents=True, exist_ok=True)
(PROJ / "xcshareddata" / "xcschemes").mkdir(parents=True, exist_ok=True)

T = "\t"

def oid(key):
    """Deterministic 24-hex id, so regenerating produces a stable diff."""
    return hashlib.sha1(key.encode()).hexdigest()[:24].upper()

files = sorted(
    str(p.relative_to(ROOT / "Sources")).replace("\\", "/")
    for p in (ROOT / "Sources").rglob("*.swift")
)
if not files:
    sys.exit("no Swift sources found under " + str(ROOT / "Sources"))

groups = {}
for f in files:
    groups.setdefault(os.path.dirname(f), []).append(f)

fref = {f: oid("fileref:" + f) for f in files}
bfile = {f: oid("buildfile:" + f) for f in files}
gid = {d: oid("group:" + (d or "Sources")) for d in groups}
I = {k: oid(k) for k in [
    "project", "target", "rootGroup", "productsGroup", "sourcesGroup", "appRef",
    "sourcesPhase", "frameworksPhase", "resourcesPhase",
    "projCfgList", "targetCfgList",
    "projDebug", "projRelease", "targetDebug", "targetRelease"]}

def base(f):
    return os.path.basename(f)

def sec(name, body):
    return "/* Begin %s section */\n%s/* End %s section */\n\n" % (name, body, name)

out = []
out.append("// !$*UTF8*$!\n{\n")
out.append(T + "archiveVersion = 1;\n" + T + "classes = {\n" + T + "};\n")
out.append(T + "objectVersion = 56;\n" + T + "objects = {\n\n")

body = ""
for f in files:
    body += "%s%s%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };\n" % (
        T, T, bfile[f], base(f), fref[f], base(f))
out.append(sec("PBXBuildFile", body))

body = ""
for f in files:
    body += '%s%s%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = %s; sourceTree = "<group>"; };\n' % (
        T, T, fref[f], base(f), base(f))
body += "%s%s%s /* Mood.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Mood.app; sourceTree = BUILT_PRODUCTS_DIR; };\n" % (
    T, T, I["appRef"])
out.append(sec("PBXFileReference", body))

def phase(pid, isa, label, entries=""):
    return ("%s%s%s /* %s */ = {\n" % (T, T, pid, label)
            + "%s%s%sisa = %s;\n" % (T, T, T, isa)
            + "%s%s%sbuildActionMask = 2147483647;\n" % (T, T, T)
            + "%s%s%sfiles = (\n%s%s%s%s);\n" % (T, T, T, entries, T, T, T)
            + "%s%s%srunOnlyForDeploymentPostprocessing = 0;\n" % (T, T, T)
            + "%s%s};\n" % (T, T))

out.append(sec("PBXFrameworksBuildPhase",
               phase(I["frameworksPhase"], "PBXFrameworksBuildPhase", "Frameworks")))

def children(d):
    s = ""
    for sub in sorted(x for x in groups if x and os.path.dirname(x) == d and x != d):
        s += "%s%s%s%s%s /* %s */,\n" % (T, T, T, T, gid[sub], base(sub))
    for f in groups.get(d, []):
        s += "%s%s%s%s%s /* %s */,\n" % (T, T, T, T, fref[f], base(f))
    return s

def group(gidv, name, kids, path=None, is_name=False):
    s = "%s%s%s%s = {\n" % (T, T, gidv, (" /* %s */" % name) if name else "")
    s += "%s%s%sisa = PBXGroup;\n" % (T, T, T)
    s += "%s%s%schildren = (\n%s%s%s%s);\n" % (T, T, T, kids, T, T, T)
    if path:
        s += "%s%s%spath = %s;\n" % (T, T, T, path)
    if is_name:
        s += "%s%s%sname = %s;\n" % (T, T, T, name)
    s += '%s%s%ssourceTree = "<group>";\n' % (T, T, T)
    s += "%s%s};\n" % (T, T)
    return s

root_kids = ("%s%s%s%s%s /* Sources */,\n" % (T, T, T, T, I["sourcesGroup"])
             + "%s%s%s%s%s /* Products */,\n" % (T, T, T, T, I["productsGroup"]))
body = group(I["rootGroup"], "", root_kids)
body += group(I["productsGroup"], "Products",
              "%s%s%s%s%s /* Mood.app */,\n" % (T, T, T, T, I["appRef"]), is_name=True)
body += group(I["sourcesGroup"], "Sources", children(""), path="Sources")
for d in sorted(x for x in groups if x):
    body += group(gid[d], base(d), children(d), path=base(d))
out.append(sec("PBXGroup", body))

body = "%s%s%s /* Mood */ = {\n" % (T, T, I["target"])
body += "%s%s%sisa = PBXNativeTarget;\n" % (T, T, T)
body += '%s%s%sbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget "Mood" */;\n' % (T, T, T, I["targetCfgList"])
body += "%s%s%sbuildPhases = (\n" % (T, T, T)
for k, lbl in [("sourcesPhase", "Sources"), ("frameworksPhase", "Frameworks"), ("resourcesPhase", "Resources")]:
    body += "%s%s%s%s%s /* %s */,\n" % (T, T, T, T, I[k], lbl)
body += "%s%s%s);\n" % (T, T, T)
body += "%s%s%sbuildRules = (\n%s%s%s);\n" % (T, T, T, T, T, T)
body += "%s%s%sdependencies = (\n%s%s%s);\n" % (T, T, T, T, T, T)
body += "%s%s%sname = Mood;\n" % (T, T, T)
body += "%s%s%sproductName = Mood;\n" % (T, T, T)
body += "%s%s%sproductReference = %s /* Mood.app */;\n" % (T, T, T, I["appRef"])
body += '%s%s%sproductType = "com.apple.product-type.application";\n' % (T, T, T)
body += "%s%s};\n" % (T, T)
out.append(sec("PBXNativeTarget", body))

body = "%s%s%s /* Project object */ = {\n" % (T, T, I["project"])
body += "%s%s%sisa = PBXProject;\n" % (T, T, T)
body += "%s%s%sattributes = {\n" % (T, T, T)
body += "%s%s%s%sBuildIndependentTargetsInParallel = 1;\n" % (T, T, T, T)
body += "%s%s%s%sLastSwiftUpdateCheck = 2600;\n" % (T, T, T, T)
body += "%s%s%s%sLastUpgradeCheck = 2600;\n" % (T, T, T, T)
body += "%s%s%s%sTargetAttributes = {\n" % (T, T, T, T)
body += "%s%s%s%s%s%s = {\n" % (T, T, T, T, T, I["target"])
body += "%s%s%s%s%s%sCreatedOnToolsVersion = 26.0;\n" % (T, T, T, T, T, T)
body += "%s%s%s%s%s};\n" % (T, T, T, T, T)
body += "%s%s%s%s};\n" % (T, T, T, T)
body += "%s%s%s};\n" % (T, T, T)
body += '%s%s%sbuildConfigurationList = %s /* Build configuration list for PBXProject "Mood" */;\n' % (T, T, T, I["projCfgList"])
body += '%s%s%scompatibilityVersion = "Xcode 14.0";\n' % (T, T, T)
body += "%s%s%sdevelopmentRegion = en;\n" % (T, T, T)
body += "%s%s%shasScannedForEncodings = 0;\n" % (T, T, T)
body += "%s%s%sknownRegions = (\n%s%s%s%sen,\n%s%s%s%sBase,\n%s%s%s);\n" % (T, T, T, T, T, T, T, T, T, T, T, T, T, T)
body += "%s%s%smainGroup = %s;\n" % (T, T, T, I["rootGroup"])
body += "%s%s%sproductRefGroup = %s /* Products */;\n" % (T, T, T, I["productsGroup"])
body += '%s%s%sprojectDirPath = "";\n' % (T, T, T)
body += '%s%s%sprojectRoot = "";\n' % (T, T, T)
body += "%s%s%stargets = (\n%s%s%s%s%s /* Mood */,\n%s%s%s);\n" % (T, T, T, T, T, T, T, I["target"], T, T, T)
body += "%s%s};\n" % (T, T)
out.append(sec("PBXProject", body))

out.append(sec("PBXResourcesBuildPhase",
               phase(I["resourcesPhase"], "PBXResourcesBuildPhase", "Resources")))

entries = ""
for f in files:
    entries += "%s%s%s%s%s /* %s in Sources */,\n" % (T, T, T, T, bfile[f], base(f))
out.append(sec("PBXSourcesBuildPhase",
               phase(I["sourcesPhase"], "PBXSourcesBuildPhase", "Sources", entries)))

SHARED = [
    "ALWAYS_SEARCH_USER_PATHS = NO;",
    "CLANG_ENABLE_MODULES = YES;",
    "CLANG_ENABLE_OBJC_ARC = YES;",
    "ENABLE_STRICT_OBJC_MSGSEND = YES;",
    "GCC_NO_COMMON_BLOCKS = YES;",
    "IPHONEOS_DEPLOYMENT_TARGET = 26.0;",
    "SDKROOT = iphoneos;",
    "SWIFT_VERSION = 5.0;",
]
TARGET = [
    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS = NO;",
    "CODE_SIGN_STYLE = Automatic;",
    "CURRENT_PROJECT_VERSION = 1;",
    "ENABLE_PREVIEWS = YES;",
    "GENERATE_INFOPLIST_FILE = YES;",
    "INFOPLIST_KEY_UILaunchScreen_Generation = YES;",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;",
    "MARKETING_VERSION = 1.0;",
    "PRODUCT_BUNDLE_IDENTIFIER = com.nodedesignagency.Mood;",
    'PRODUCT_NAME = "$(TARGET_NAME)";',
    "SWIFT_EMIT_LOC_STRINGS = YES;",
    'TARGETED_DEVICE_FAMILY = "1,2";',
]

def cfg(cid, name, settings):
    s = "%s%s%s /* %s */ = {\n" % (T, T, cid, name)
    s += "%s%s%sisa = XCBuildConfiguration;\n" % (T, T, T)
    s += "%s%s%sbuildSettings = {\n" % (T, T, T)
    for line in settings:
        s += "%s%s%s%s%s\n" % (T, T, T, T, line)
    s += "%s%s%s};\n" % (T, T, T)
    s += "%s%s%sname = %s;\n" % (T, T, T, name)
    s += "%s%s};\n" % (T, T)
    return s

body = cfg(I["projDebug"], "Debug", SHARED + [
    "ONLY_ACTIVE_ARCH = YES;",
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";',
    'SWIFT_OPTIMIZATION_LEVEL = "-Onone";'])
body += cfg(I["projRelease"], "Release", SHARED + ["SWIFT_COMPILATION_MODE = wholemodule;"])
body += cfg(I["targetDebug"], "Debug", TARGET)
body += cfg(I["targetRelease"], "Release", TARGET)
out.append(sec("XCBuildConfiguration", body))

def cfglist(lid, dbg, rel, label):
    s = "%s%s%s /* Build configuration list for %s */ = {\n" % (T, T, lid, label)
    s += "%s%s%sisa = XCConfigurationList;\n" % (T, T, T)
    s += "%s%s%sbuildConfigurations = (\n" % (T, T, T)
    s += "%s%s%s%s%s /* Debug */,\n" % (T, T, T, T, dbg)
    s += "%s%s%s%s%s /* Release */,\n" % (T, T, T, T, rel)
    s += "%s%s%s);\n" % (T, T, T)
    s += "%s%s%sdefaultConfigurationIsVisible = 0;\n" % (T, T, T)
    s += "%s%s%sdefaultConfigurationName = Release;\n" % (T, T, T)
    s += "%s%s};\n" % (T, T)
    return s

body = cfglist(I["projCfgList"], I["projDebug"], I["projRelease"], 'PBXProject "Mood"')
body += cfglist(I["targetCfgList"], I["targetDebug"], I["targetRelease"], 'PBXNativeTarget "Mood"')
out.append(sec("XCConfigurationList", body))

out.append(T + "};\n")
out.append(T + "rootObject = " + I["project"] + " /* Project object */;\n}\n")
(PROJ / "project.pbxproj").write_text("".join(out))

(PROJ / "project.xcworkspace" / "contents.xcworkspacedata").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n<Workspace\n   version = "1.0">\n'
    '   <FileRef\n      location = "self:">\n   </FileRef>\n</Workspace>\n')

ref = ('            <BuildableReference\n'
       '               BuildableIdentifier = "primary"\n'
       '               BlueprintIdentifier = "%s"\n'
       '               BuildableName = "Mood.app"\n'
       '               BlueprintName = "Mood"\n'
       '               ReferencedContainer = "container:Mood.xcodeproj">\n'
       '            </BuildableReference>\n') % I["target"]
scheme = ('<?xml version="1.0" encoding="UTF-8"?>\n'
          '<Scheme LastUpgradeVersion = "2600" version = "1.7">\n'
          '   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">\n'
          '      <BuildActionEntries>\n'
          '         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" '
          'buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">\n'
          + ref +
          '         </BuildActionEntry>\n      </BuildActionEntries>\n   </BuildAction>\n'
          '   <LaunchAction buildConfiguration = "Debug" launchStyle = "0" '
          'useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" '
          'debugDocumentVersioning = "YES" allowLocationSimulation = "YES">\n'
          '      <BuildableProductRunnable runnableDebuggingMode = "0">\n'
          + ref +
          '      </BuildableProductRunnable>\n   </LaunchAction>\n'
          '   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES">\n'
          '      <BuildableProductRunnable runnableDebuggingMode = "0">\n'
          + ref +
          '      </BuildableProductRunnable>\n   </ProfileAction>\n'
          '   <AnalyzeAction buildConfiguration = "Debug"></AnalyzeAction>\n'
          '   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">'
          '</ArchiveAction>\n</Scheme>\n')
(PROJ / "xcshareddata" / "xcschemes" / "Mood.xcscheme").write_text(scheme)

print("generated Mood.xcodeproj with %d sources:" % len(files))
for f in files:
    print("   ", f)
